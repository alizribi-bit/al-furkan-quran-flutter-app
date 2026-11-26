import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../core/theme/zen_theme.dart';
import '../core/mutun/mutun_data.dart';

class MutunScreen extends StatefulWidget {
  const MutunScreen({super.key});

  @override
  State<MutunScreen> createState() => _MutunScreenState();
}

class _MutunScreenState extends State<MutunScreen> {
  static const List<double> _speedOptions = [0.75, 1.0, 1.25, 1.5];

  MatnId _selectedMatnId = MatnId.tuhfat;
  int _selectedChapterIdx = 0;
  bool _showAllInDiwan = false;
  MutunDisplayMode _displayMode = MutunDisplayMode.diwan;
  MutunMaskLevel _maskLevel = MutunMaskLevel.secondHemistich;
  bool _showFirstWordCue = true;
  double _fontSize = 22.0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final Map<MatnId, String> _selectedVoiceByMatn = {
    MatnId.tuhfat: MutunRepository.books[MatnId.tuhfat]!.voices.first.id,
    MatnId.shatibiyyah:
        MutunRepository.books[MatnId.shatibiyyah]!.voices.first.id,
  };

  // Mastery tracking persisted in Hive box
  final Set<String> _masteredKeys = {};
  Box<dynamic>? _mutunBox;

  // Temporary 2.6s peek state for cloze memorization
  final Set<int> _peekedLines = {};
  final Map<int, Timer> _peekTimers = {};

  // Audio player state (just_audio)
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _isLooping = true;
  double _playbackSpeed = 1.0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _loadedUrl;
  String? _audioError;

  MatnBook get _book => MutunRepository.books[_selectedMatnId]!;

  MatnChapter get _currentChapter =>
      _book.chapters[_selectedChapterIdx.clamp(0, _book.chapters.length - 1)];

  MatnVoice get _currentVoice {
    final id = _selectedVoiceByMatn[_selectedMatnId];
    return _book.voices.firstWhere(
      (v) => v.id == id,
      orElse: () => _book.voices.first,
    );
  }

  String get _activeAudioUrl => _currentVoice.resolveUrl(_currentChapter.id);

  @override
  void initState() {
    super.initState();
    _initHiveMastery();
    _initAudioListeners();
  }

  Future<void> _initHiveMastery() async {
    try {
      final box = await Hive.openBox('itqan_mutun_mastery');
      if (!mounted) return;
      final saved = box.get('mastered_keys');
      setState(() {
        _mutunBox = box;
        if (saved is List) {
          _masteredKeys.addAll(saved.map((e) => e.toString()));
        }
      });
    } catch (_) {
      // Fallback to in-memory mastery if Hive box is unavailable
    }
  }

  void _initAudioListeners() {
    _player.setLoopMode(LoopMode.one);
    _playerStateSub = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing;
        _isBuffering =
            state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering;
        if (state.processingState == ProcessingState.completed && !_isLooping) {
          _isPlaying = false;
        }
      });
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
    for (final timer in _peekTimers.values) {
      timer.cancel();
    }
    _peekTimers.clear();
    _searchController.dispose();
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _switchMatn(MatnId nextId) async {
    if (nextId == _selectedMatnId) return;
    await _player.stop();
    setState(() {
      _selectedMatnId = nextId;
      _selectedChapterIdx = 0;
      _showAllInDiwan = false;
      _searchQuery = '';
      _searchController.clear();
      _peekedLines.clear();
      _position = Duration.zero;
      _duration = Duration.zero;
      _loadedUrl = null;
      _audioError = null;
    });
  }

  Future<void> _selectChapter(int index) async {
    final wasPlaying = _isPlaying;
    setState(() {
      _selectedChapterIdx = index;
      _showAllInDiwan = false;
      _audioError = null;
    });

    if (_currentVoice.isChapterized) {
      await _loadAndOptionallyPlay(_activeAudioUrl, autoPlay: wasPlaying);
    }
  }

  Future<void> _selectVoice(MatnVoice voice) async {
    final wasPlaying = _isPlaying;
    setState(() {
      _selectedVoiceByMatn[_selectedMatnId] = voice.id;
      _audioError = null;
    });
    await _loadAndOptionallyPlay(_activeAudioUrl, autoPlay: wasPlaying);
  }

  Future<void> _loadAndOptionallyPlay(String url, {required bool autoPlay}) async {
    if (url.isEmpty) return;
    setState(() {
      _isBuffering = true;
      _audioError = null;
    });
    try {
      await _player.stop();
      await _player.setUrl(url);
      await _player.setSpeed(_playbackSpeed);
      await _player.setLoopMode(_isLooping ? LoopMode.one : LoopMode.off);
      _loadedUrl = url;
      if (autoPlay) {
        await _player.play();
      }
      if (mounted) {
        setState(() => _isBuffering = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isBuffering = false;
          _isPlaying = false;
          _audioError = 'تعذر تحميل الصوت حالياً، يرجى التحقق من الاتصال أو اختيار قارئ آخر.';
        });
      }
    }
  }

  Future<void> _togglePlayPause() async {
    final url = _activeAudioUrl;
    if (url.isEmpty) return;

    if (_isPlaying) {
      await _player.pause();
      return;
    }

    if (_loadedUrl != url) {
      await _loadAndOptionallyPlay(url, autoPlay: true);
    } else {
      try {
        await _player.play();
      } catch (_) {
        await _loadAndOptionallyPlay(url, autoPlay: true);
      }
    }
  }

  Future<void> _seekBy(int deltaSeconds) async {
    if (_duration.inMilliseconds <= 0) return;
    final nextMs = (_position.inMilliseconds + deltaSeconds * 1000)
        .clamp(0, _duration.inMilliseconds);
    await _player.seek(Duration(milliseconds: nextMs));
  }

  Future<void> _toggleLoop() async {
    final next = !_isLooping;
    setState(() => _isLooping = next);
    await _player.setLoopMode(next ? LoopMode.one : LoopMode.off);
  }

  Future<void> _cycleSpeed() async {
    final idx = _speedOptions.indexOf(_playbackSpeed);
    final next = _speedOptions[(idx + 1) % _speedOptions.length];
    setState(() => _playbackSpeed = next);
    await _player.setSpeed(next);
  }

  void _triggerPeek(int lineNumber) {
    _peekTimers[lineNumber]?.cancel();
    setState(() => _peekedLines.add(lineNumber));
    _peekTimers[lineNumber] = Timer(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      setState(() => _peekedLines.remove(lineNumber));
    });
  }

  void _toggleMastered(int lineNumber) {
    final key = '${_selectedMatnId.name}_$lineNumber';
    setState(() {
      if (_masteredKeys.contains(key)) {
        _masteredKeys.remove(key);
      } else {
        _masteredKeys.add(key);
      }
    });
    _mutunBox?.put('mastered_keys', _masteredKeys.toList());
  }

  bool _isMastered(int lineNumber) =>
      _masteredKeys.contains('${_selectedMatnId.name}_$lineNumber');

  int get _masteredCountForBook {
    int count = 0;
    for (final ch in _book.chapters) {
      for (final line in ch.lines) {
        if (_isMastered(line.number)) count++;
      }
    }
    return count;
  }

  List<MatnChapter> get _visibleChapters {
    final q = _searchQuery.trim();
    if (q.isNotEmpty) {
      final matches = <MatnChapter>[];
      for (final ch in _book.chapters) {
        final filtered = ch.lines
            .where((l) =>
                l.first.contains(q) ||
                l.second.contains(q) ||
                l.note.contains(q) ||
                (l.tag != null && l.tag!.contains(q)) ||
                ch.title.contains(q))
            .toList();
        if (filtered.isNotEmpty) {
          matches.add(MatnChapter(
            id: ch.id,
            index: ch.index,
            title: ch.title,
            subtitle: ch.subtitle,
            summary: ch.summary,
            lines: filtered,
          ));
        }
      }
      return matches;
    }

    if (_displayMode == MutunDisplayMode.diwan && _showAllInDiwan) {
      return _book.chapters;
    }
    return [_currentChapter];
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$mins:$secs';
    }
    return '$mins:$secs';
  }

  void _openVoicePickerSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sage = isDark ? ZenTheme.darkSage : ZenTheme.lightSage;
    final gold = isDark ? const Color(0xFFD9B664) : const Color(0xFFA57E2B);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF161F1B) : const Color(0xFFFFFDF8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: DraggableScrollableSheet(
            initialChildSize: 0.65,
            maxChildSize: 0.88,
            minChildSize: 0.4,
            expand: false,
            builder: (_, scrollCtrl) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'اختر القارئ — ${_book.title}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تسجيلات صوتية موثقة (مقسَّمة بالأبواب أو متصلة كاملة)',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollCtrl,
                        itemCount: _book.voices.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, idx) {
                          final voice = _book.voices[idx];
                          final selected = voice.id == _currentVoice.id;
                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              Navigator.pop(ctx);
                              _selectVoice(voice);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: selected
                                    ? sage.withValues(alpha: 0.12)
                                    : (isDark
                                        ? const Color(0xFF121916)
                                        : const Color(0xFFFAF6EE)),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected
                                      ? sage
                                      : (isDark
                                          ? const Color(0xFF24322B)
                                          : const Color(0xFFE7DEC9)),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          voice.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          voice.title,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: gold,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          voice.style,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? Colors.white60
                                                : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (selected)
                                    Icon(Icons.check_circle, color: sage),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _openShatibiyyahSymbolsSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = isDark ? const Color(0xFFD9B664) : const Color(0xFFA57E2B);
    String filter = 'all';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF161F1B) : const Color(0xFFFFFDF8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final symbols = filter == 'all'
                ? MutunRepository.shatibiyyahSymbols
                : MutunRepository.shatibiyyahSymbols
                    .where((s) => s.type == filter)
                    .toList();

            return Directionality(
              textDirection: TextDirection.rtl,
              child: DraggableScrollableSheet(
                initialChildSize: 0.72,
                maxChildSize: 0.92,
                minChildSize: 0.45,
                expand: false,
                builder: (_, scrollCtrl) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white24 : Colors.black12,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'دليل رموز الإمام الشاطبي للقراء السبعة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'قاعدة أبج دهز حطي كلم نصع فضق رست · الرموز الحرفية والكلمية',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final opt in const [
                                ('all', 'الكل'),
                                ('individual', 'القراء السبعة'),
                                ('group', 'الرموز الحرفية'),
                                ('word', 'الرموز الكلمية'),
                              ])
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: ChoiceChip(
                                    label: Text(opt.$2, style: const TextStyle(fontSize: 12)),
                                    selected: filter == opt.$1,
                                    selectedColor: gold,
                                    labelStyle: TextStyle(
                                      color: filter == opt.$1 ? Colors.white : null,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    onSelected: (_) =>
                                        setModalState(() => filter = opt.$1),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.separated(
                            controller: scrollCtrl,
                            itemCount: symbols.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, idx) {
                              final sym = symbols[idx];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF121916)
                                      : const Color(0xFFFAF6EE),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF24322B)
                                        : const Color(0xFFE7DEC9),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      constraints: const BoxConstraints(minWidth: 64),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: gold.withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        sym.code,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: gold,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sym.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            sym.details,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
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
            'المتون العلمية',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            if (_selectedMatnId == MatnId.shatibiyyah)
              TextButton.icon(
                onPressed: _openShatibiyyahSymbolsSheet,
                icon: Icon(Icons.explore_outlined, size: 18, color: gold),
                label: Text(
                  'رموز الشاطبية',
                  style: TextStyle(
                    color: gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            IconButton(
              tooltip: 'تصغير الخط',
              onPressed: () =>
                  setState(() => _fontSize = (_fontSize - 2).clamp(17.0, 30.0)),
              icon: const Icon(Icons.text_decrease, size: 20),
            ),
            IconButton(
              tooltip: 'تكبير الخط',
              onPressed: () =>
                  setState(() => _fontSize = (_fontSize + 2).clamp(17.0, 30.0)),
              icon: const Icon(Icons.text_increase, size: 20),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                children: [
                  // 1. Matn Switcher (Tuhfat al-Atfal / Al-Shatibiyyah)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        for (final id in MatnId.values)
                          Expanded(
                            child: _buildMatnSwitchTile(
                              MutunRepository.books[id]!,
                              selected: _selectedMatnId == id,
                              paper: paper,
                              border: border,
                              gold: gold,
                              isDark: isDark,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Metadata summary row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '${_book.author} · ${_book.totalLinesLabel}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'المحفوظ: ${toArabicIndic(_masteredCountForBook)} / ${toArabicIndic(_book.totalLines)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: sage,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 2. Three Visual Display Modes Switcher
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        _buildModeTab(
                          mode: MutunDisplayMode.diwan,
                          label: 'الديوان الشعري',
                          icon: Icons.menu_book_outlined,
                          sage: sage,
                          isDark: isDark,
                        ),
                        _buildModeTab(
                          mode: MutunDisplayMode.study,
                          label: 'الدراسة والشرح',
                          icon: Icons.school_outlined,
                          sage: sage,
                          isDark: isDark,
                        ),
                        _buildModeTab(
                          mode: MutunDisplayMode.memorize,
                          label: 'الحفظ والتسميع',
                          icon: Icons.visibility_off_outlined,
                          sage: sage,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),

                  // Mode-specific sub-controls
                  if (_displayMode == MutunDisplayMode.memorize) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final opt in const [
                          (MutunMaskLevel.secondHemistich, 'إخفاء العجز'),
                          (MutunMaskLevel.fullLine, 'إخفاء البيت كاملاً'),
                          (MutunMaskLevel.visible, 'مكشوف'),
                        ])
                          ChoiceChip(
                            label: Text(opt.$2, style: const TextStyle(fontSize: 12)),
                            selected: _maskLevel == opt.$1,
                            selectedColor: sage.withValues(alpha: 0.2),
                            onSelected: (_) => setState(() => _maskLevel = opt.$1),
                          ),
                        if (_maskLevel == MutunMaskLevel.fullLine)
                          FilterChip(
                            label: const Text('إظهار الكلمة الأولى',
                                style: TextStyle(fontSize: 12)),
                            selected: _showFirstWordCue,
                            selectedColor: sage.withValues(alpha: 0.2),
                            onSelected: (v) =>
                                setState(() => _showFirstWordCue = v),
                          ),
                      ],
                    ),
                  ],

                  if (_displayMode == MutunDisplayMode.study) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'ابحث في أبيات أو شرح ${_book.title}...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: paper,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
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
                  ],

                  const SizedBox(height: 12),

                  // 3. Horizontal Chapters Strip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'أبواب ${_book.title} (${toArabicIndic(_book.chapters.length)})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      if (_displayMode == MutunDisplayMode.diwan &&
                          _searchQuery.isEmpty)
                        GestureDetector(
                          onTap: () =>
                              setState(() => _showAllInDiwan = !_showAllInDiwan),
                          child: Text(
                            _showAllInDiwan
                                ? 'عرض الباب المحدد فقط'
                                : 'عرض المتن كاملاً',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sage,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _book.chapters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, idx) {
                        final ch = _book.chapters[idx];
                        final active =
                            idx == _selectedChapterIdx && !_showAllInDiwan;
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _selectChapter(idx),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: active ? sage : paper,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: active ? sage : border,
                              ),
                            ),
                            child: Text(
                              '${toArabicIndic(ch.index)}. ${ch.title}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? (isDark
                                        ? const Color(0xFF111614)
                                        : Colors.white)
                                    : null,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 4. Main Manuscript / Study / Memorize Folio
                  if (_visibleChapters.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: paper,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: border),
                      ),
                      child: const Center(
                        child: Text('لا توجد أبيات مطابقة لعبارة البحث'),
                      ),
                    )
                  else
                    for (final chapter in _visibleChapters) ...[
                      _buildChapterFolio(
                        chapter: chapter,
                        paper: paper,
                        border: border,
                        sage: sage,
                        gold: gold,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                    ],
                ],
              ),
            ),

            // 5. Sticky Multi-Voice Audio Player Dock
            _buildAudioDock(
              paper: paper,
              border: border,
              sage: sage,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatnSwitchTile(
    MatnBook item, {
    required bool selected,
    required Color paper,
    required Color border,
    required Color gold,
    required bool isDark,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _switchMatn(item.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? paper : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: selected ? Border.all(color: border) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: selected
                          ? null
                          : (isDark ? Colors.white60 : Colors.black54),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  item.discipline,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? gold
                        : (isDark ? Colors.white38 : Colors.black38),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              item.author,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab({
    required MutunDisplayMode mode,
    required String label,
    required IconData icon,
    required Color sage,
    required bool isDark,
  }) {
    final active = _displayMode == mode;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _displayMode = mode),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: active ? sage : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: active
                    ? (isDark ? const Color(0xFF111614) : Colors.white)
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
              const SizedBox(width: 4),
              Flexible(
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChapterFolio({
    required MatnChapter chapter,
    required Color paper,
    required Color border,
    required Color sage,
    required Color gold,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Chapter header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1B2621)
                  : const Color(0xFFFAF5EA),
              border: Border(bottom: BorderSide(color: border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الباب ${toArabicIndic(chapter.index)} · ${chapter.subtitle}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: gold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            chapter.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_showAllInDiwan && _searchQuery.isEmpty) ...[
                      IconButton(
                        onPressed: _selectedChapterIdx > 0
                            ? () => _selectChapter(_selectedChapterIdx - 1)
                            : null,
                        icon: const Icon(Icons.chevron_right, size: 22),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        onPressed: _selectedChapterIdx < _book.chapters.length - 1
                            ? () => _selectChapter(_selectedChapterIdx + 1)
                            : null,
                        icon: const Icon(Icons.chevron_left, size: 22),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ],
                ),
                if (_displayMode == MutunDisplayMode.study) ...[
                  const SizedBox(height: 6),
                  Text(
                    chapter.summary,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Display Mode Body
          if (_displayMode == MutunDisplayMode.diwan)
            _buildDiwanBody(chapter, border, gold, isDark)
          else if (_displayMode == MutunDisplayMode.study)
            _buildStudyBody(chapter, border, sage, gold, isDark)
          else
            _buildMemorizeBody(chapter, border, sage, gold, isDark),
        ],
      ),
    );
  }

  Widget _buildDiwanBody(
    MatnChapter chapter,
    Color border,
    Color gold,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: gold.withValues(alpha: 0.35)),
          color: isDark ? const Color(0xFF141C18) : const Color(0xFFFFFDF8),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 520;
            return Column(
              children: [
                for (int i = 0; i < chapter.lines.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 18,
                      color: border.withValues(alpha: 0.55),
                    ),
                  _buildDiwanLine(chapter.lines[i], isWide, gold),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDiwanLine(MatnLine line, bool isWide, Color gold) {
    final verseStyle = TextStyle(
      fontFamily: 'KFGQPCUthmanic',
      fontSize: _fontSize,
      height: 1.95,
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '﴿${toArabicIndic(line.number)}﴾',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: gold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              line.first,
              textAlign: TextAlign.right,
              style: verseStyle,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('❖', style: TextStyle(fontSize: 10, color: gold)),
          ),
          Expanded(
            child: Text(
              line.second,
              textAlign: TextAlign.left,
              style: verseStyle,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          line.first,
          textAlign: TextAlign.center,
          style: verseStyle,
        ),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: line.second, style: verseStyle),
              TextSpan(
                text: '  ﴿${toArabicIndic(line.number)}﴾',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: gold,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStudyBody(
    MatnChapter chapter,
    Color border,
    Color sage,
    Color gold,
    bool isDark,
  ) {
    return Column(
      children: [
        for (int i = 0; i < chapter.lines.length; i++) ...[
          if (i > 0) Divider(height: 1, color: border.withValues(alpha: 0.6)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'البيت ${toArabicIndic(chapter.lines[i].number)}${chapter.lines[i].tag != null ? ' · ${chapter.lines[i].tag}' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: gold,
                      ),
                    ),
                    InkWell(
                      onTap: () => _toggleMastered(chapter.lines[i].number),
                      child: Row(
                        children: [
                          Icon(
                            _isMastered(chapter.lines[i].number)
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            size: 18,
                            color: _isMastered(chapter.lines[i].number)
                                ? sage
                                : (isDark ? Colors.white38 : Colors.black38),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isMastered(chapter.lines[i].number)
                                ? 'محفوظ'
                                : 'حفظت البيت',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: _isMastered(chapter.lines[i].number)
                                  ? sage
                                  : (isDark ? Colors.white54 : Colors.black45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  chapter.lines[i].first,
                  style: TextStyle(
                    fontFamily: 'KFGQPCUthmanic',
                    fontSize: _fontSize,
                    height: 1.9,
                  ),
                ),
                Text(
                  chapter.lines[i].second,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontFamily: 'KFGQPCUthmanic',
                    fontSize: _fontSize,
                    height: 1.9,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF121A17)
                        : const Color(0xFFFAF6EE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border.withValues(alpha: 0.7)),
                  ),
                  child: Text(
                    chapter.lines[i].note,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.55,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMemorizeBody(
    MatnChapter chapter,
    Color border,
    Color sage,
    Color gold,
    bool isDark,
  ) {
    return Column(
      children: [
        for (int i = 0; i < chapter.lines.length; i++) ...[
          if (i > 0) Divider(height: 1, color: border.withValues(alpha: 0.6)),
          _buildMemorizeLineTile(chapter.lines[i], border, sage, gold, isDark),
        ],
      ],
    );
  }

  Widget _buildMemorizeLineTile(
    MatnLine line,
    Color border,
    Color sage,
    Color gold,
    bool isDark,
  ) {
    final isPeeked = _peekedLines.contains(line.number);
    final mastered = _isMastered(line.number);
    final hideFirst = _maskLevel == MutunMaskLevel.fullLine && !isPeeked;
    final hideSecond = (_maskLevel == MutunMaskLevel.secondHemistich ||
            _maskLevel == MutunMaskLevel.fullLine) &&
        !isPeeked;
    final firstWord = line.first.split(' ').first;

    return Container(
      color: mastered ? sage.withValues(alpha: 0.06) : null,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '﴿${toArabicIndic(line.number)}﴾${line.tag != null ? ' · ${line.tag}' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: gold,
                ),
              ),
              Row(
                children: [
                  if (hideFirst || hideSecond)
                    TextButton.icon(
                      onPressed: () => _triggerPeek(line.number),
                      icon: Icon(Icons.visibility_outlined, size: 16, color: sage),
                      label: Text(
                        'كشف مؤقت',
                        style: TextStyle(fontSize: 11.5, color: sage),
                      ),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _toggleMastered(line.number),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: mastered ? sage : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: mastered ? Colors.transparent : border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            mastered
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            size: 14,
                            color: mastered
                                ? (isDark
                                    ? const Color(0xFF111614)
                                    : Colors.white)
                                : (isDark ? Colors.white60 : Colors.black54),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            mastered ? 'أتقنته' : 'تم الحفظ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: mastered
                                  ? (isDark
                                      ? const Color(0xFF111614)
                                      : Colors.white)
                                  : (isDark ? Colors.white70 : Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: (hideFirst || hideSecond)
                ? () => _triggerPeek(line.number)
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hideFirst)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1D2823)
                          : const Color(0xFFF1EBE0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: border),
                    ),
                    child: Text(
                      _showFirstWordCue
                          ? '$firstWord  ······'
                          : 'اضغط لكشف الصدر',
                      style: TextStyle(
                        fontFamily: _showFirstWordCue ? 'KFGQPCUthmanic' : 'Cairo',
                        fontSize: _showFirstWordCue ? (_fontSize - 2) : 13,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  )
                else
                  Text(
                    line.first,
                    style: TextStyle(
                      fontFamily: 'KFGQPCUthmanic',
                      fontSize: _fontSize,
                      height: 1.9,
                    ),
                  ),
                const SizedBox(height: 8),
                if (hideSecond)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1D2823)
                          : const Color(0xFFF1EBE0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: border),
                    ),
                    child: Text(
                      'اضغط لكشف الشطر الثاني (العجز)',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  )
                else
                  Text(
                    line.second,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontFamily: 'KFGQPCUthmanic',
                      fontSize: _fontSize,
                      height: 1.9,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioDock({
    required Color paper,
    required Color border,
    required Color sage,
    required bool isDark,
  }) {
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
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _openVoicePickerSheet,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E2A25)
                          : const Color(0xFFF4EFE4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.volume_up_outlined, size: 18, color: sage),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentVoice.name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _currentVoice.isChapterized
                                    ? 'باب: ${_currentChapter.title}'
                                    : _currentVoice.title,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'تغيير (${toArabicIndic(_book.voices.length)})',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: sage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _cycleSpeed,
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E2A25)
                        : const Color(0xFFF4EFE4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: border),
                  ),
                  child: Text(
                    '${_playbackSpeed}×',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: sage,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _toggleLoop,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _isLooping
                        ? sage
                        : (isDark
                            ? const Color(0xFF1E2A25)
                            : const Color(0xFFF4EFE4)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isLooping ? Colors.transparent : border,
                    ),
                  ),
                  child: Icon(
                    Icons.repeat,
                    size: 18,
                    color: _isLooping
                        ? (isDark ? const Color(0xFF111614) : Colors.white)
                        : (isDark ? Colors.white60 : Colors.black54),
                  ),
                ),
              ),
            ],
          ),
          if (_audioError != null) ...[
            const SizedBox(height: 6),
            Text(
              _audioError!,
              style: const TextStyle(fontSize: 11, color: Colors.redAccent),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              IconButton(
                onPressed: () => _seekBy(-5),
                icon: const Icon(Icons.replay_5, size: 20),
                visualDensity: VisualDensity.compact,
              ),
              SizedBox(
                width: 44,
                height: 44,
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
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark
                                ? const Color(0xFF111614)
                                : Colors.white,
                          ),
                        )
                      : Icon(_isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 24),
                ),
              ),
              IconButton(
                onPressed: () => _seekBy(5),
                icon: const Icon(Icons.forward_5, size: 20),
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
                            _formatDuration(_position),
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                          Text(
                            _duration.inMilliseconds > 0
                                ? _formatDuration(_duration)
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
