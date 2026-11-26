import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../core/theme/zen_theme.dart';
import '../core/anashid/anashid_data.dart';
import '../core/mutun/mutun_data.dart' show toArabicIndic;

enum _AnashidTab { curated, collections, search, favorites }

class AnashidScreen extends StatefulWidget {
  const AnashidScreen({super.key});

  @override
  State<AnashidScreen> createState() => _AnashidScreenState();
}

class _AnashidScreenState extends State<AnashidScreen> {
  static const List<int> _sleepOptionsMin = [0, 15, 30, 60];
  static const List<String> _quickSearchTerms = [
    'القرآن',
    'مشاري العفاسي',
    'محمد المقيط',
    'أبو عبد الملك',
    'رمضان',
    'الزهد',
  ];

  _AnashidTab _activeTab = _AnashidTab.curated;
  String _selectedCategory = 'all';
  String _localFilter = '';
  final TextEditingController _localFilterCtrl = TextEditingController();

  // Open collections state
  VocalCollection? _activeCollection;
  List<NasheedTrack> _collectionTracks = [];
  bool _isLoadingCollection = false;
  String? _collectionError;
  String _collectionFilter = '';
  final TextEditingController _collectionFilterCtrl = TextEditingController();

  // Live Archive.org Search state
  final TextEditingController _searchCtrl = TextEditingController();
  List<ArchiveSearchItem> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;
  ArchiveSearchItem? _selectedSearchItem;
  List<NasheedTrack> _searchItemTracks = [];
  bool _isLoadingSearchTracks = false;

  // Favorites persisted via Hive
  List<NasheedTrack> _favorites = [];
  Box<dynamic>? _favBox;

  // Audio player state (just_audio)
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  List<NasheedTrack> _queue = AnashidRepository.curatedTracks;
  NasheedTrack? _currentTrack = AnashidRepository.curatedTracks.first;
  String? _loadedUrl;
  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _repeatOne = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _audioError;

  // Sleep timer
  int _sleepMinutes = 0;
  int _sleepRemainingSec = 0;
  Timer? _sleepTimer;

  @override
  void initState() {
    super.initState();
    _initFavoritesBox();
    _initAudioListeners();
  }

  Future<void> _initFavoritesBox() async {
    try {
      final box = await Hive.openBox('itqan_anashid_box');
      if (!mounted) return;
      final raw = box.get('favorites_json');
      final loaded = <NasheedTrack>[];
      if (raw is String && raw.isNotEmpty) {
        final decoded = json.decode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              loaded.add(
                  NasheedTrack.fromJson(Map<String, dynamic>.from(item)));
            }
          }
        }
      }
      setState(() {
        _favBox = box;
        _favorites = loaded;
      });
    } catch (_) {
      // Fallback gracefully if Hive box is unavailable
    }
  }

  void _saveFavorites() {
    try {
      final encoded =
          json.encode(_favorites.map((t) => t.toJson()).toList());
      _favBox?.put('favorites_json', encoded);
    } catch (_) {}
  }

  void _initAudioListeners() {
    _playerStateSub = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing;
        _isBuffering =
            state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering;
      });
      if (state.processingState == ProcessingState.completed) {
        if (!_repeatOne) {
          _playAdjacent(1);
        }
      }
    });

    _positionSub = _player.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() => _position = pos);
    });

    _durationSub = _player.durationStream.listen((dur) {
      if (!mounted) return;
      setState(() => _duration = dur ?? Duration.zero);
    });
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _localFilterCtrl.dispose();
    _collectionFilterCtrl.dispose();
    _searchCtrl.dispose();
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  bool _isFavorite(String id) => _favorites.any((t) => t.id == id);

  void _toggleFavorite(NasheedTrack track) {
    setState(() {
      if (_isFavorite(track.id)) {
        _favorites.removeWhere((t) => t.id == track.id);
      } else {
        _favorites.insert(0, track);
      }
    });
    _saveFavorites();
  }

  Future<void> _playTrackFromList(
      NasheedTrack track, List<NasheedTrack> list) async {
    setState(() {
      _queue = list;
      _audioError = null;
    });

    if (_currentTrack?.id == track.id && _loadedUrl == track.audioUrl) {
      if (_isPlaying) {
        await _player.pause();
      } else {
        await _player.play();
      }
      return;
    }

    setState(() {
      _currentTrack = track;
      _position = Duration.zero;
      _duration = track.durationSec != null
          ? Duration(seconds: track.durationSec!)
          : Duration.zero;
      _isBuffering = true;
    });

    try {
      await _player.stop();
      await _player.setUrl(track.audioUrl);
      await _player.setLoopMode(_repeatOne ? LoopMode.one : LoopMode.off);
      _loadedUrl = track.audioUrl;
      await _player.play();
    } catch (_) {
      if (mounted) {
        setState(() {
          _isBuffering = false;
          _isPlaying = false;
          _audioError = 'تعذر بث هذا النشيد حالياً، يرجى اختيار نشيد آخر.';
        });
      }
    }
  }

  Future<void> _togglePlayPause() async {
    final track = _currentTrack;
    if (track == null) return;
    if (_isPlaying) {
      await _player.pause();
      return;
    }
    if (_loadedUrl != track.audioUrl) {
      await _playTrackFromList(track, _queue);
    } else {
      await _player.play();
    }
  }

  Future<void> _playAdjacent(int delta) async {
    if (_currentTrack == null || _queue.isEmpty) return;
    final idx = _queue.indexWhere((t) => t.id == _currentTrack!.id);
    if (idx < 0) return;
    final nextIdx = (idx + delta + _queue.length) % _queue.length;
    await _playTrackFromList(_queue[nextIdx], _queue);
  }

  Future<void> _toggleRepeat() async {
    final next = !_repeatOne;
    setState(() => _repeatOne = next);
    await _player.setLoopMode(next ? LoopMode.one : LoopMode.off);
  }

  void _cycleSleepTimer() {
    _sleepTimer?.cancel();
    final idx = _sleepOptionsMin.indexOf(_sleepMinutes);
    final nextMin = _sleepOptionsMin[(idx + 1) % _sleepOptionsMin.length];
    setState(() {
      _sleepMinutes = nextMin;
      _sleepRemainingSec = nextMin * 60;
    });

    if (nextMin > 0) {
      _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_sleepRemainingSec <= 1) {
          timer.cancel();
          _player.pause();
          setState(() {
            _sleepMinutes = 0;
            _sleepRemainingSec = 0;
          });
        } else {
          setState(() => _sleepRemainingSec--);
        }
      });
    }
  }

  Future<void> _openCollection(VocalCollection col) async {
    setState(() {
      _activeCollection = col;
      _collectionTracks = [];
      _collectionFilter = '';
      _collectionFilterCtrl.clear();
      _collectionError = null;
      _isLoadingCollection = true;
    });
    try {
      final tracks = await AnashidRepository.fetchCollectionTracks(
        archiveId: col.archiveId,
        defaultArtist: col.defaultArtist,
        defaultCategory: col.defaultCategory,
        limit: 80,
      );
      if (mounted) {
        setState(() {
          _collectionTracks = tracks;
          _isLoadingCollection = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingCollection = false;
          _collectionError =
              'تعذر الاتصال بمكتبة Internet Archive حالياً، يرجى المحاولة مجدداً.';
        });
      }
    }
  }

  Future<void> _runSearch([String? overrideQuery]) async {
    final q = (overrideQuery ?? _searchCtrl.text).trim();
    if (q.isEmpty) return;
    if (overrideQuery != null) _searchCtrl.text = q;
    setState(() {
      _selectedSearchItem = null;
      _searchItemTracks = [];
      _searchError = null;
      _isSearching = true;
    });
    try {
      final results = await AnashidRepository.searchVocalAnashid(q);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
          if (results.isEmpty) {
            _searchError = 'لم يُعثر على نتائج صوتية بدون إيقاع مطابقة لهذا البحث.';
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchError = 'تعذر الاتصال بخدمة البحث المفتوحة حالياً.';
        });
      }
    }
  }

  Future<void> _openSearchItem(ArchiveSearchItem item) async {
    setState(() {
      _selectedSearchItem = item;
      _searchItemTracks = [];
      _isLoadingSearchTracks = true;
    });
    try {
      final tracks = await AnashidRepository.fetchCollectionTracks(
        archiveId: item.archiveId,
        defaultArtist: item.creator,
        limit: 40,
      );
      if (mounted) {
        setState(() {
          _searchItemTracks = tracks;
          _isLoadingSearchTracks = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingSearchTracks = false);
      }
    }
  }

  String _formatSecs(int secs) {
    if (secs <= 0) return '00:00';
    final mins = (secs ~/ 60).toString().padLeft(2, '0');
    final rem = (secs % 60).toString().padLeft(2, '0');
    return '$mins:$rem';
  }

  List<NasheedTrack> get _filteredCurated {
    final q = _localFilter.trim();
    return AnashidRepository.curatedTracks.where((t) {
      final catOk =
          _selectedCategory == 'all' || t.category == _selectedCategory;
      final qOk = q.isEmpty || t.title.contains(q) || t.artist.contains(q);
      return catOk && qOk;
    }).toList();
  }

  List<NasheedTrack> get _filteredCollectionTracks {
    final q = _collectionFilter.trim();
    if (q.isEmpty) return _collectionTracks;
    return _collectionTracks
        .where((t) => t.title.contains(q) || t.artist.contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sage = isDark ? ZenTheme.darkSage : ZenTheme.lightSage;
    final gold = isDark ? const Color(0xFFD9B664) : const Color(0xFFA57E2B);
    final paper = isDark ? const Color(0xFF161F1B) : const Color(0xFFFFFDF8);
    final border = isDark ? const Color(0xFF27362E) : const Color(0xFFDDD0B8);
    final surface = isDark ? const Color(0xFF19221E) : const Color(0xFFEFE9DD);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'مكتبة الأناشيد الصوتية',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Center(
                child: Text(
                  'بدون إيقاع ولا موسيقى',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: gold,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // 4-Segment Mode Switcher
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    _buildSegmentTab(
                        _AnashidTab.curated, 'المختارات', sage, isDark),
                    _buildSegmentTab(
                        _AnashidTab.collections, 'الموسوعات', sage, isDark),
                    _buildSegmentTab(
                        _AnashidTab.search, 'بحث مفتوح', sage, isDark),
                    _buildSegmentTab(
                      _AnashidTab.favorites,
                      'المفضلة (${toArabicIndic(_favorites.length)})',
                      sage,
                      isDark,
                    ),
                  ],
                ),
              ),
            ),

            // Active Tab Body
            Expanded(
              child: switch (_activeTab) {
                _AnashidTab.curated =>
                  _buildCuratedTab(paper, border, sage, gold, isDark),
                _AnashidTab.collections =>
                  _buildCollectionsTab(paper, border, sage, gold, isDark),
                _AnashidTab.search =>
                  _buildSearchTab(paper, border, sage, gold, isDark),
                _AnashidTab.favorites =>
                  _buildFavoritesTab(paper, border, sage, gold, isDark),
              },
            ),

            // Sticky Player Dock
            if (_currentTrack != null)
              _buildPlayerDock(paper, border, sage, gold, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentTab(
    _AnashidTab tab,
    String label,
    Color sage,
    bool isDark,
  ) {
    final active = _activeTab == tab;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _activeTab = tab),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? sage : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: active
                  ? (isDark ? const Color(0xFF111614) : Colors.white)
                  : (isDark ? Colors.white70 : Colors.black54),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildCuratedTab(
    Color paper,
    Color border,
    Color sage,
    Color gold,
    bool isDark,
  ) {
    final tracks = _filteredCurated;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: AnashidRepository.categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, idx) {
              final cat = AnashidRepository.categories[idx];
              final active = _selectedCategory == cat.$1;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _selectedCategory = cat.$1),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: active ? sage : paper,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: active ? sage : border),
                  ),
                  child: Text(
                    cat.$2,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active
                          ? (isDark ? const Color(0xFF111614) : Colors.white)
                          : null,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _localFilterCtrl,
          onChanged: (v) => setState(() => _localFilter = v),
          decoration: InputDecoration(
            hintText: 'تصفية سريعة في المختارات...',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _localFilter.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _localFilterCtrl.clear();
                      setState(() => _localFilter = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: paper,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: border),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildTrackListCard(tracks, paper, border, sage, gold, isDark),
      ],
    );
  }

  Widget _buildCollectionsTab(
    Color paper,
    Color border,
    Color sage,
    Color gold,
    bool isDark,
  ) {
    if (_activeCollection == null) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
        itemCount: AnashidRepository.openCollections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, idx) {
          final col = AnashidRepository.openCollections[idx];
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openCollection(col),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: paper,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          col.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          col.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${col.trackCountLabel} · Internet Archive API',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_left),
                ],
              ),
            ),
          );
        },
      );
    }

    final tracks = _filteredCollectionTracks;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Row(
          children: [
            TextButton.icon(
              onPressed: () => setState(() => _activeCollection = null),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('كل الموسوعات'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _activeCollection!.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (_collectionTracks.isNotEmpty) ...[
          const SizedBox(height: 6),
          TextField(
            controller: _collectionFilterCtrl,
            onChanged: (v) => setState(() => _collectionFilter = v),
            decoration: InputDecoration(
              hintText: 'تصفية داخل هذه الموسوعة...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: paper,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: border),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (_isLoadingCollection)
          const Padding(
            padding: EdgeInsets.all(36),
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('جاري جلب الأناشيد من Internet Archive...'),
              ],
            ),
          )
        else if (_collectionError != null)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _collectionError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          )
        else
          _buildTrackListCard(tracks, paper, border, sage, gold, isDark),
      ],
    );
  }

  Widget _buildSearchTab(
    Color paper,
    Color border,
    Color sage,
    Color gold,
    bool isDark,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _runSearch(),
                decoration: InputDecoration(
                  hintText: 'ابحث عن منشد أو نشيد بدون إيقاع...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: paper,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: border),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: _isSearching ? null : () => _runSearch(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: sage,
                  foregroundColor:
                      isDark ? const Color(0xFF111614) : Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('بحث',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final term in _quickSearchTerms)
              ActionChip(
                label: Text(term, style: const TextStyle(fontSize: 12)),
                onPressed: () => _runSearch(term),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_selectedSearchItem != null) ...[
          Row(
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _selectedSearchItem = null),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('نتائج البحث'),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _selectedSearchItem!.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (_isLoadingSearchTracks)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            _buildTrackListCard(
                _searchItemTracks, paper, border, sage, gold, isDark),
        ] else ...[
          if (_searchError != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                _searchError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
          for (final item in _searchResults) ...[
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _openSearchItem(item),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: paper,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13.5),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.creator,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_left),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }

  Widget _buildFavoritesTab(
    Color paper,
    Color border,
    Color sage,
    Color gold,
    bool isDark,
  ) {
    if (_favorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_border,
                  size: 36, color: isDark ? Colors.white38 : Colors.black26),
              const SizedBox(height: 10),
              const Text(
                'قائمة المفضلة فارغة حالياً',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                'اضغط على القلب بجانب أي نشيد لحفظه والعودة إليه سريعاً.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
      children: [
        _buildTrackListCard(_favorites, paper, border, sage, gold, isDark),
      ],
    );
  }

  Widget _buildTrackListCard(
    List<NasheedTrack> tracks,
    Color paper,
    Color border,
    Color sage,
    Color gold,
    bool isDark,
  ) {
    if (tracks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: paper,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        child: const Center(child: Text('لا توجد أناشيد مطابقة')),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < tracks.length; i++) ...[
            if (i > 0) Divider(height: 1, color: border.withValues(alpha: 0.55)),
            _buildTrackRow(tracks[i], tracks, i, sage, gold, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildTrackRow(
    NasheedTrack track,
    List<NasheedTrack> sourceList,
    int index,
    Color sage,
    Color gold,
    bool isDark,
  ) {
    final isActive = _currentTrack?.id == track.id;
    final isFav = _isFavorite(track.id);

    return InkWell(
      onTap: () => _playTrackFromList(track, sourceList),
      child: Container(
        color: isActive ? sage.withValues(alpha: 0.1) : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? sage : sage.withValues(alpha: 0.14),
              ),
              child: isActive && _isBuffering
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? const Color(0xFF111614) : Colors.white,
                      ),
                    )
                  : Icon(
                      isActive && _isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 20,
                      color: isActive
                          ? (isDark ? const Color(0xFF111614) : Colors.white)
                          : sage,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${toArabicIndic(index + 1)}. ',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: gold,
                          ),
                        ),
                        TextSpan(
                          text: track.title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: isActive ? sage : null,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.artist,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (track.durationSec != null)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  _formatSecs(track.durationSec!),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ),
            IconButton(
              onPressed: () => _toggleFavorite(track),
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                size: 20,
                color: isFav
                    ? Colors.redAccent
                    : (isDark ? Colors.white38 : Colors.black38),
              ),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerDock(
    Color paper,
    Color border,
    Color sage,
    Color gold,
    bool isDark,
  ) {
    final track = _currentTrack!;
    final maxMs = _duration.inMilliseconds > 0
        ? _duration.inMilliseconds.toDouble()
        : 1.0;
    final posMs = _position.inMilliseconds.toDouble().clamp(0.0, maxMs);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: paper,
        border: Border(top: BorderSide(color: border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.volume_up_outlined, size: 18, color: sage),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      track.artist,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _cycleSleepTimer,
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: _sleepRemainingSec > 0
                        ? gold
                        : (isDark
                            ? const Color(0xFF1E2A25)
                            : const Color(0xFFF4EFE4)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          _sleepRemainingSec > 0 ? Colors.transparent : border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.bedtime_outlined,
                        size: 14,
                        color: _sleepRemainingSec > 0 ? Colors.white : null,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _sleepRemainingSec > 0
                            ? _formatSecs(_sleepRemainingSec)
                            : 'مؤقت',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _sleepRemainingSec > 0 ? Colors.white : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _toggleRepeat,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _repeatOne
                        ? sage
                        : (isDark
                            ? const Color(0xFF1E2A25)
                            : const Color(0xFFF4EFE4)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _repeatOne ? Colors.transparent : border),
                  ),
                  child: Icon(
                    _repeatOne ? Icons.repeat_one : Icons.repeat,
                    size: 17,
                    color: _repeatOne
                        ? (isDark ? const Color(0xFF111614) : Colors.white)
                        : null,
                  ),
                ),
              ),
            ],
          ),
          if (_audioError != null) ...[
            const SizedBox(height: 4),
            Text(
              _audioError!,
              style: const TextStyle(fontSize: 11, color: Colors.redAccent),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              IconButton(
                onPressed: () => _playAdjacent(-1),
                icon: const Icon(Icons.skip_next, size: 22),
                visualDensity: VisualDensity.compact,
              ),
              SizedBox(
                width: 42,
                height: 42,
                child: ElevatedButton(
                  onPressed: _togglePlayPause,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: sage,
                    foregroundColor:
                        isDark ? const Color(0xFF111614) : Colors.white,
                    shape: const CircleBorder(),
                    padding: EdgeInsets.zero,
                    elevation: 0,
                  ),
                  child: _isBuffering
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark
                                ? const Color(0xFF111614)
                                : Colors.white,
                          ),
                        )
                      : Icon(_isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 22),
                ),
              ),
              IconButton(
                onPressed: () => _playAdjacent(1),
                icon: const Icon(Icons.skip_previous, size: 22),
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 12),
                        activeTrackColor: sage,
                        thumbColor: sage,
                      ),
                      child: Slider(
                        value: posMs,
                        min: 0,
                        max: maxMs,
                        onChanged: (v) =>
                            _player.seek(Duration(milliseconds: v.round())),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatSecs(_position.inSeconds),
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                          Text(
                            _duration.inSeconds > 0
                                ? _formatSecs(_duration.inSeconds)
                                : '--:--',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
