import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../core/theme/zen_theme.dart';
import '../core/audio/audio_player_service.dart';
import '../core/audio/reciters_data.dart';
import '../core/quran/surah_data.dart';
import '../widgets/mushaf_book_page.dart';

enum MaskingMode { visible, blurred, hidden }

/// ZenHifzScreen (also exported as ZenHifzView)
/// Distraction-free active memorization screen powered by AudioPlayerService with just_audio.
class ZenHifzScreen extends StatefulWidget {
  final Function(bool isFocusMode) onFocusModeChanged;

  const ZenHifzScreen({super.key, required this.onFocusModeChanged});

  @override
  State<ZenHifzScreen> createState() => _ZenHifzScreenState();
}

/// Backward compatibility alias
typedef ZenHifzView = ZenHifzScreen;

class _ZenHifzScreenState extends State<ZenHifzScreen> {
  final AudioPlayerService _audioPlayer = AudioPlayerService();
  StreamSubscription<HifzSessionState>? _sessionSub;

  MaskingMode _maskingMode = MaskingMode.visible;
  bool _showFirstWordCue = false;
  double _fontSize = 28.0;
  bool _isFocusMode = false;
  final Set<int> _peekedAyahs = {};

  // Current session config
  int _surah = 1;
  int _startAyah = 1;
  int _endAyah = 7;
  String _riwayah = 'hafs'; // 'hafs', 'qalun', 'warsh', 'duri'
  HifzRepetitionMode _repetitionMode = HifzRepetitionMode.goldenLoop;
  int _blockRepeat = 4;
  int _singleRepeat = 5;
  int _linkGroupRepeat = 2;
  int _pauseDelaySeconds = 4;
  double _playbackSpeed = 1.0;

  // Selected Reciter & Favorites
  late HifzReciter _selectedReciter;
  Set<String> _favoriteReciterIds = {};

  // Loaded verses from dynamic JSON
  List<Map<String, dynamic>> _loadedVerses = [];
  bool _isLoadingVerses = false;

  // State from AudioPlayerService
  HifzSessionState _sessionState = const HifzSessionState();
  final Map<int, Timer> _peekTimers = {};

  @override
  void initState() {
    super.initState();
    _loadFavoriteReciters();
    _selectedReciter = QuranRecitersData.getDefault(_riwayah);
    _loadVerses();

    // Subscribe to AudioPlayerService events to track loop counting and delay
    _sessionSub = _audioPlayer.sessionStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _sessionState = state;
        if (state.status == HifzPlaybackStatus.testing) {
          // In Phase D (Active Recall Test), auto-mask the text to stimulate memory
          _maskingMode = MaskingMode.hidden;
        } else if (state.status == HifzPlaybackStatus.completed) {
          _isFocusMode = false;
          widget.onFocusModeChanged(false);
          _maskingMode = MaskingMode.visible;
          _showCompletionSnackbar();
        }
      });
    });
  }

  void _loadFavoriteReciters() {
    try {
      if (Hive.isBoxOpen('hifz_box')) {
        final saved = Hive.box('hifz_box').get('favorite_reciters');
        if (saved is List) {
          _favoriteReciterIds = saved.map((e) => e.toString()).toSet();
        }
      }
    } catch (_) {}
  }

  void _toggleFavoriteReciter(String reciterId) {
    setState(() {
      if (_favoriteReciterIds.contains(reciterId)) {
        _favoriteReciterIds.remove(reciterId);
      } else {
        _favoriteReciterIds.add(reciterId);
      }
    });
    try {
      if (Hive.isBoxOpen('hifz_box')) {
        Hive.box('hifz_box').put('favorite_reciters', _favoriteReciterIds.toList());
      }
    } catch (_) {}
  }

  void _switchRiwayah(String newRiwayah) {
    setState(() {
      _riwayah = newRiwayah;
      if (_selectedReciter.riwayah != newRiwayah) {
        _selectedReciter = QuranRecitersData.getDefault(newRiwayah);
      }
    });
    _loadVerses();
  }

  Future<void> _loadVerses() async {
    setState(() => _isLoadingVerses = true);
    try {
      final verses = await QuranScriptService.getVersesForSurah(
        surahNumber: _surah,
        riwayah: _riwayah,
      );
      if (mounted) {
        setState(() {
          _loadedVerses = verses;
          if (verses.isNotEmpty) {
            final maxAyah = verses.length;
            if (_endAyah > maxAyah) _endAyah = maxAyah;
            if (_startAyah > _endAyah) _startAyah = 1;
          }
          _isLoadingVerses = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingVerses = false);
      }
    }
  }

  @override
  void dispose() {
    for (final timer in _peekTimers.values) {
      timer.cancel();
    }
    _peekTimers.clear();
    _sessionSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _showCompletionSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'ما شاء الله تبارك الله! اكتملت الجلسة وأتقنت المقطع بنجاح',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        backgroundColor: ZenTheme.lightSage,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _toggleMaskingMode() {
    setState(() {
      for (final timer in _peekTimers.values) {
        timer.cancel();
      }
      _peekTimers.clear();
      _peekedAyahs.clear();

      if (_maskingMode == MaskingMode.visible) {
        _maskingMode = MaskingMode.blurred;
      } else if (_maskingMode == MaskingMode.blurred) {
        _maskingMode = MaskingMode.hidden;
      } else {
        _maskingMode = MaskingMode.visible;
      }
    });
  }

  void _peekAyah(int ayahNum) {
    if (_maskingMode == MaskingMode.visible) return;

    _peekTimers[ayahNum]?.cancel();

    setState(() {
      _peekedAyahs.add(ayahNum);
    });

    _peekTimers[ayahNum] = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _peekedAyahs.remove(ayahNum);
          _peekTimers.remove(ayahNum);
        });
      }
    });
  }

  void _startSession() {
    setState(() {
      _isFocusMode = true;
    });
    widget.onFocusModeChanged(true);

    _audioPlayer.prepareAndPlay(
      HifzVerseConfig(
        surah: _surah,
        startAyah: _startAyah,
        endAyah: _endAyah,
        repetitionMode: _repetitionMode,
        blockRepeatCount: _blockRepeat,
        singleRepeatCount: _singleRepeat,
        linkGroupRepeat: _linkGroupRepeat,
        pauseDelaySeconds: _pauseDelaySeconds,
        playbackSpeed: _playbackSpeed,
        reciterCdnPattern: _selectedReciter.cdnPattern,
        audioMode: _selectedReciter.audioMode,
        mp3QuranReadId: _selectedReciter.mp3QuranReadId,
      ),
    );
  }

  void _cyclePlaybackSpeed() {
    const speeds = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    final currentIdx = speeds.indexOf(_playbackSpeed);
    final nextSpeed = speeds[(currentIdx + 1) % speeds.length];
    setState(() {
      _playbackSpeed = nextSpeed;
    });
    _audioPlayer.setSpeed(nextSpeed);
  }

  void _pauseSession() {
    _audioPlayer.pause();
  }

  void _resumeSession() {
    _audioPlayer.resume();
  }

  void _stopSession() {
    setState(() {
      _isFocusMode = false;
      _maskingMode = MaskingMode.visible;
    });
    widget.onFocusModeChanged(false);
    _audioPlayer.stop();
  }

  // Helper dialog to enter custom number directly
  Future<int?> _showDirectNumberDialog({
    required BuildContext context,
    required String title,
    required int currentValue,
    required int min,
    required int max,
  }) async {
    final controller = TextEditingController(text: currentValue.toString());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sageColor = isDark ? ZenTheme.darkSage : ZenTheme.lightSage;

    return showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('أدخل رقماً بين $min و $max', style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: sageColor, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: sageColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final val = int.tryParse(controller.text);
                if (val != null) {
                  Navigator.pop(ctx, val.clamp(min, max));
                } else {
                  Navigator.pop(ctx);
                }
              },
              child: const Text('تأكيد'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPhaseStepItem({
    required String letter,
    required String title,
    required String subtitle,
    required bool isActive,
    required bool isCompleted,
    required Color sageColor,
    required Color textColor,
  }) {
    const successColor = Color(0xFF2E7D32);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? sageColor.withValues(alpha: 0.15)
              : isCompleted
              ? successColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? sageColor
                : isCompleted
                ? successColor.withValues(alpha: 0.5)
                : Colors.grey.withValues(alpha: 0.2),
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isCompleted
                    ? successColor
                    : isActive
                    ? sageColor
                    : Colors.grey.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Text(
                        letter,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.white : textColor,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 9, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  /// 200+ Live Reciter Explorer Bottom Sheet (Riwayah + Hadr/Murattal/Muallim/Favorites + Scope)
  void _openReciterPickerModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? ZenTheme.darkAmberText : ZenTheme.lightText;
    final sageColor = isDark ? ZenTheme.darkSage : ZenTheme.lightSage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? ZenTheme.darkSurface : ZenTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        String activeRiwayah = _riwayah;
        String activeStyle = 'all'; // 'all', 'hadr', 'murattal', 'muallim', 'favorites'
        String activeScope = 'all'; // 'all', 'ayah', 'surah'
        String searchQuery = '';
        bool isLoadingCatalog = true;
        bool startedFetch = false;

        return StatefulBuilder(
          builder: (context, setPickerState) {
            if (!startedFetch) {
              startedFetch = true;
              QuranRecitersData.loadFullCatalog().then((_) {
                if (context.mounted) {
                  setPickerState(() => isLoadingCatalog = false);
                }
              });
            }

            final allCatalog = QuranRecitersData.all;
            int countRiwayah(String rId) => rId == 'all'
                ? allCatalog.length
                : allCatalog.where((r) => r.riwayah == rId).length;

            final filteredReciters = allCatalog.where((r) {
              if (activeRiwayah != 'all' && r.riwayah != activeRiwayah) return false;
              if (activeStyle == 'favorites') {
                if (!_favoriteReciterIds.contains(r.id)) return false;
              } else if (activeStyle != 'all' && r.styleCategory != activeStyle) {
                return false;
              }
              if (activeScope == 'ayah' && r.audioMode == 'surah_stream') return false;
              if (activeScope == 'surah' && r.audioMode != 'surah_stream') return false;
              if (searchQuery.trim().isNotEmpty) {
                final q = searchQuery.trim().toLowerCase();
                if (!r.nameAr.toLowerCase().contains(q) &&
                    !r.nameEn.toLowerCase().contains(q) &&
                    !r.style.toLowerCase().contains(q)) {
                  return false;
                }
              }
              return true;
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.86,
              padding: const EdgeInsets.only(top: 18, left: 16, right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'مكتبة القراء الكبرى (${allCatalog.length})',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                if (isLoadingCatalog) ...[
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: sageColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'حدر سريع للتكرار (1.5×) • مرتل • معلم • ٤ روايات أصيلة',
                              style: TextStyle(
                                fontSize: 11,
                                color: sageColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Search Bar
                  TextField(
                    onChanged: (val) => setPickerState(() => searchQuery = val),
                    style: TextStyle(color: textColor, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'ابحث باسم الشيخ (مثلاً: الشريم، ياسر سلامة، الحصري، الكزابري)...',
                      hintStyle: const TextStyle(fontSize: 12),
                      prefixIcon: Icon(Icons.search, color: sageColor, size: 20),
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Row 1: Riwayah Filter Chips with Live Counts
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        {'id': 'all', 'label': 'الكل (${countRiwayah('all')})'},
                        {'id': 'hafs', 'label': 'حفص (${countRiwayah('hafs')})'},
                        {'id': 'warsh', 'label': 'ورش (${countRiwayah('warsh')})'},
                        {'id': 'qalun', 'label': 'قالون (${countRiwayah('qalun')})'},
                        {'id': 'duri', 'label': 'الدوري (${countRiwayah('duri')})'},
                      ].map((chip) {
                        final id = chip['id']!;
                        final label = chip['label']!;
                        final isSel = activeRiwayah == id;
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: InkWell(
                            onTap: () => setPickerState(() => activeRiwayah = id),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? sageColor
                                    : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSel ? sageColor : Colors.transparent),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSel ? Colors.white : textColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Row 2: Style Filter Tabs (Hadr / Murattal / Muallim / Favorites)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        {'id': 'all', 'label': 'جميع الأنماط'},
                        {'id': 'hadr', 'label': '⚡ حدر سريع (1.5×)'},
                        {'id': 'murattal', 'label': 'مرتل متوازن'},
                        {'id': 'muallim', 'label': 'معلم للتحفيظ'},
                        {'id': 'favorites', 'label': '★ مفضلتي (${_favoriteReciterIds.length})'},
                      ].map((tab) {
                        final id = tab['id']!;
                        final isSel = activeStyle == id;
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: InkWell(
                            onTap: () => setPickerState(() => activeStyle = id),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? Colors.amber.withValues(alpha: 0.22)
                                    : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSel ? Colors.amber : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                tab['label']!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSel
                                      ? (isDark ? Colors.amber[300] : Colors.amber[900])
                                      : textColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Row 3: Audio Scope Filter (All | Ayah-by-Ayah | Full Surah)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'النتائج: ${filteredReciters.length} قارئ',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600),
                        ),
                      ),
                      ...[
                        {'id': 'all', 'label': 'الكل'},
                        {'id': 'ayah', 'label': 'آية بآية'},
                        {'id': 'surah', 'label': 'سورة كاملة'},
                      ].map((scope) {
                        final id = scope['id']!;
                        final isSel = activeScope == id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: InkWell(
                            onTap: () => setPickerState(() => activeScope = id),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? sageColor.withValues(alpha: 0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSel
                                      ? sageColor
                                      : Colors.grey.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                scope['label']!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSel ? sageColor : textColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Expanded(
                    child: filteredReciters.isEmpty
                        ? Center(
                            child: Text(
                              'لا يوجد قارئ مطابق لهذا الفلتر حالياً',
                              style: TextStyle(color: Colors.grey[500], fontSize: 14),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredReciters.length,
                            separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                            itemBuilder: (context, idx) {
                              final reciter = filteredReciters[idx];
                              final isSelected = reciter.id == _selectedReciter.id;
                              final isFav = _favoriteReciterIds.contains(reciter.id);
                              final isAyahMode = reciter.audioMode != 'surah_stream';

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedReciter = reciter;
                                    _riwayah = reciter.riwayah;
                                  });
                                  _loadVerses();
                                  Navigator.pop(context);
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? sageColor.withValues(alpha: 0.15)
                                        : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04)),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? sageColor : Colors.transparent,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: isSelected
                                            ? sageColor
                                            : (isDark ? Colors.white12 : Colors.black12),
                                        child: Icon(
                                          isAyahMode ? Icons.record_voice_over : Icons.library_music,
                                          color: isSelected ? Colors.white : sageColor,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Wrap(
                                              spacing: 5,
                                              runSpacing: 4,
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              children: [
                                                Text(
                                                  reciter.nameAr,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: textColor,
                                                  ),
                                                ),
                                                if (reciter.fastFriendly || reciter.styleCategory == 'hadr')
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                    decoration: BoxDecoration(
                                                      color: Colors.amber.withValues(alpha: 0.2),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      'حدر سريع',
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        color: isDark ? Colors.amber[300] : Colors.amber[900],
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                  decoration: BoxDecoration(
                                                    color: isAyahMode
                                                        ? sageColor.withValues(alpha: 0.18)
                                                        : Colors.blueGrey.withValues(alpha: 0.18),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    reciter.audioMode == 'ayah_timed'
                                                        ? 'آية بآية • بدون فجوات'
                                                        : (reciter.audioMode == 'ayah_direct'
                                                            ? 'آية بآية'
                                                            : 'سورة كاملة'),
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      color: isAyahMode ? sageColor : Colors.blueGrey[300],
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              reciter.pedagogicalNote ?? reciter.style,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          isFav ? Icons.star : Icons.star_border,
                                          color: isFav ? Colors.amber : Colors.grey,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          _toggleFavoriteReciter(reciter.id);
                                          setPickerState(() {});
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      ),
                                      if (isSelected)
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: sageColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.check, color: Colors.white, size: 14),
                                        ),
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
        );
      },
    );
  }

  /// Modal to choose Surah
  void _openSurahPickerModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? ZenTheme.darkAmberText : ZenTheme.lightText;
    final sageColor = isDark ? ZenTheme.darkSage : ZenTheme.lightSage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? ZenTheme.darkSurface : ZenTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setPickerState) {
            final filteredSurahs = QuranSurahs.list.where((s) {
              if (searchQuery.trim().isEmpty) return true;
              final q = searchQuery.trim().toLowerCase();
              return s.nameAr.contains(q) ||
                  s.nameEn.toLowerCase().contains(q) ||
                  s.number.toString().contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'اختر السورة الكريمة (114 سورة)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (val) => setPickerState(() => searchQuery = val),
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'ابحث باسم السورة أو رقمها...',
                      prefixIcon: Icon(Icons.search, color: sageColor),
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredSurahs.length,
                      itemBuilder: (context, idx) {
                        final s = filteredSurahs[idx];
                        final isSelected = s.number == _surah;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? sageColor.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? sageColor : Colors.transparent,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: isSelected
                                  ? sageColor
                                  : (isDark ? Colors.white12 : Colors.black12),
                              child: Text(
                                '${s.number}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : textColor,
                                ),
                              ),
                            ),
                            title: Text(
                              'سورة ${s.nameAr}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: textColor,
                              ),
                            ),
                            subtitle: Text(
                              '${s.nameEn} • ${s.versesCount} آية • ${s.revelationType == 'Meccan' ? 'مكية' : 'مدنية'}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_circle, color: sageColor, size: 24)
                                : null,
                            onTap: () {
                              Navigator.pop(context);
                              setState(() {
                                _surah = s.number;
                                _startAyah = 1;
                                _endAyah = s.versesCount >= 7 ? 7 : s.versesCount;
                              });
                              _loadVerses();
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Big, touch-friendly Stepper with Direct Input button
  Widget _buildFriendlyNumberStepper({
    required BuildContext context,
    required String title,
    required String unit,
    required int value,
    required int min,
    required int max,
    required List<int> presets,
    required Function(int) onChanged,
    required bool isDark,
    required Color textColor,
    required Color sageColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            Text(
              '$value $unit',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: sageColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Big Stepper Controls: [ - ]  [ Tap to Enter / Current ]  [ + ]
        Row(
          children: [
            // Minus Button
            InkWell(
              onTap: value > min ? () => onChanged(value - 1) : null,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 52,
                height: 50,
                decoration: BoxDecoration(
                  color: value > min
                      ? (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.07))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: value > min ? sageColor.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  Icons.remove,
                  color: value > min ? sageColor : Colors.grey,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Middle Number Display (Tappable to type directly)
            Expanded(
              child: InkWell(
                onTap: () async {
                  final result = await _showDirectNumberDialog(
                    context: context,
                    title: title,
                    currentValue: value,
                    min: min,
                    max: max,
                  );
                  if (result != null) onChanged(result);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: sageColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: sageColor.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$value $unit',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.edit, size: 16, color: sageColor),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Plus Button
            InkWell(
              onTap: value < max ? () => onChanged(value + 1) : null,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 52,
                height: 50,
                decoration: BoxDecoration(
                  color: value < max
                      ? (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.07))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: value < max ? sageColor.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  Icons.add,
                  color: value < max ? sageColor : Colors.grey,
                  size: 24,
                ),
              ),
            ),
          ],
        ),

        // Quick Preset Chips (Big touch targets)
        if (presets.isNotEmpty) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: presets.map((p) {
                final isSelected = p == value;
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: InkWell(
                    onTap: () => onChanged(p),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? sageColor
                            : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? sageColor : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        '$p',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : textColor,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  void _openSetupModalSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? ZenTheme.darkAmberText : ZenTheme.lightText;
    final sageColor = isDark ? ZenTheme.darkSage : ZenTheme.lightSage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? ZenTheme.darkSurface : ZenTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final currentSurahInfo = QuranSurahs.getByNumber(_surah);
            final maxAyah = _loadedVerses.isNotEmpty
                ? _loadedVerses.length
                : currentSurahInfo.versesCount;

            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'إعدادات جلسة التكرار المتقن',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 24),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 1. SURAH CARD (Big & Clear)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: sageColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'السورة الكريمة المختارة',
                                style: TextStyle(fontSize: 12, color: sageColor, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${currentSurahInfo.number}. سورة ${currentSurahInfo.nameAr}',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                '${currentSurahInfo.versesCount} آية • ${currentSurahInfo.revelationType == 'Meccan' ? 'مكية' : 'مدنية'}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _openSurahPickerModal();
                          },
                          icon: const Icon(Icons.menu_book, size: 18),
                          label: const Text('تغيير السورة', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: sageColor.withValues(alpha: 0.2),
                            foregroundColor: sageColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. RECITER CARD (الشيخ أو القارئ - Big & Clear)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: sageColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'الشيخ والقارئ المعتمد',
                                style: TextStyle(fontSize: 12, color: sageColor, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedReciter.nameAr,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              if (_selectedReciter.pedagogicalNote != null)
                                Text(
                                  _selectedReciter.pedagogicalNote!,
                                  style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _openReciterPickerModal();
                          },
                          icon: const Icon(Icons.record_voice_over, size: 18),
                          label: const Text('تغيير القارئ', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: sageColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. RIWAYAH BUTTONS (حفص | قالون | ورش | الدوري)
                  Text(
                    'الرواية القرآنية ومصحف التلاوة',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        {'id': 'hafs', 'name': 'حفص عن عاصم'},
                        {'id': 'qalun', 'name': 'قالون عن نافع'},
                        {'id': 'warsh', 'name': 'ورش عن نافع'},
                        {'id': 'duri', 'name': 'الدوري عن أبي عمرو'},
                      ].map((item) {
                        final id = item['id']!;
                        final name = item['name']!;
                        final isSelected = _riwayah == id;
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: InkWell(
                            onTap: () {
                              setSheetState(() => _riwayah = id);
                              setState(() {
                                _riwayah = id;
                                _selectedReciter = QuranRecitersData.getDefault(id);
                              });
                              _loadVerses();
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? sageColor
                                    : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? sageColor : Colors.transparent,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : textColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. AYAH RANGE: FROM & TO WITH FRIENDLY STEPPERS
                  Text(
                    'نطاق الآيات المراد حفظها في الجلسة',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // FROM AYAH
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('من الآية', style: TextStyle(fontSize: 12, color: sageColor, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    color: _startAyah > 1 ? sageColor : Colors.grey,
                                    onPressed: _startAyah > 1
                                        ? () {
                                            setSheetState(() => _startAyah -= 1);
                                            setState(() => _startAyah -= 1);
                                          }
                                        : null,
                                  ),
                                  InkWell(
                                    onTap: () async {
                                      final res = await _showDirectNumberDialog(
                                        context: context,
                                        title: 'من الآية رقم',
                                        currentValue: _startAyah,
                                        min: 1,
                                        max: _endAyah,
                                      );
                                      if (res != null) {
                                        setSheetState(() => _startAyah = res);
                                        setState(() => _startAyah = res);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: sageColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$_startAyah',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    color: _startAyah < _endAyah ? sageColor : Colors.grey,
                                    onPressed: _startAyah < _endAyah
                                        ? () {
                                            setSheetState(() => _startAyah += 1);
                                            setState(() => _startAyah += 1);
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // TO AYAH
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('إلى الآية', style: TextStyle(fontSize: 12, color: sageColor, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    color: _endAyah > _startAyah ? sageColor : Colors.grey,
                                    onPressed: _endAyah > _startAyah
                                        ? () {
                                            setSheetState(() => _endAyah -= 1);
                                            setState(() => _endAyah -= 1);
                                          }
                                        : null,
                                  ),
                                  InkWell(
                                    onTap: () async {
                                      final res = await _showDirectNumberDialog(
                                        context: context,
                                        title: 'إلى الآية رقم',
                                        currentValue: _endAyah,
                                        min: _startAyah,
                                        max: maxAyah,
                                      );
                                      if (res != null) {
                                        setSheetState(() => _endAyah = res);
                                        setState(() => _endAyah = res);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: sageColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$_endAyah',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    color: _endAyah < maxAyah ? sageColor : Colors.grey,
                                    onPressed: _endAyah < maxAyah
                                        ? () {
                                            setSheetState(() => _endAyah += 1);
                                            setState(() => _endAyah += 1);
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 5. 3-WAY REPETITION METHOD SELECTOR (Golden Loop | Combined Block | Verse by Verse)
                  Text(
                    'طريقة ومنهجية التكرار والحفظ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Option 1: THE GOLDEN LOOP (Recommended)
                  InkWell(
                    onTap: () {
                      setSheetState(() => _repetitionMode = HifzRepetitionMode.goldenLoop);
                      setState(() => _repetitionMode = HifzRepetitionMode.goldenLoop);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _repetitionMode == HifzRepetitionMode.goldenLoop
                            ? sageColor.withValues(alpha: 0.15)
                            : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _repetitionMode == HifzRepetitionMode.goldenLoop ? sageColor : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _repetitionMode == HifzRepetitionMode.goldenLoop ? sageColor : Colors.grey.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'الحلقة الذهبية المتقنة (The Golden Loop)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text('موصى به', style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '[أ] إتقان الآية منفردة → [ب] الربط التراكمي → [ج] تثبيت المقطع مجمعاً → [د] التسميع الذاتي',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _repetitionMode == HifzRepetitionMode.goldenLoop ? sageColor : Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Option 2 & 3: Combined Block & Verse by Verse
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setSheetState(() => _repetitionMode = HifzRepetitionMode.combinedBlock);
                            setState(() => _repetitionMode = HifzRepetitionMode.combinedBlock);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: _repetitionMode == HifzRepetitionMode.combinedBlock
                                  ? sageColor
                                  : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _repetitionMode == HifzRepetitionMode.combinedBlock
                                    ? sageColor
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                Icon(
                                  Icons.layers,
                                  color: _repetitionMode == HifzRepetitionMode.combinedBlock ? Colors.white : sageColor,
                                  size: 20,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'المقطع مجمعاً',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _repetitionMode == HifzRepetitionMode.combinedBlock
                                        ? Colors.white
                                        : textColor,
                                  ),
                                ),
                                Text(
                                  'تلاوة متصلة',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _repetitionMode == HifzRepetitionMode.combinedBlock
                                        ? Colors.white70
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setSheetState(() => _repetitionMode = HifzRepetitionMode.verseByVerse);
                            setState(() => _repetitionMode = HifzRepetitionMode.verseByVerse);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: _repetitionMode == HifzRepetitionMode.verseByVerse
                                  ? sageColor
                                  : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _repetitionMode == HifzRepetitionMode.verseByVerse
                                    ? sageColor
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                Icon(
                                  Icons.repeat,
                                  color: _repetitionMode == HifzRepetitionMode.verseByVerse ? Colors.white : sageColor,
                                  size: 20,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'آية بآية (بسيط)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _repetitionMode == HifzRepetitionMode.verseByVerse
                                        ? Colors.white
                                        : textColor,
                                  ),
                                ),
                                Text(
                                  'تكرار فردي',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _repetitionMode == HifzRepetitionMode.verseByVerse
                                        ? Colors.white70
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 6. FRIENDLY REPETITION COUNTERS (WITH BIG STEPPERS & QUICK CHIPS)
                  if (_repetitionMode == HifzRepetitionMode.goldenLoop) ...[
                    _buildFriendlyNumberStepper(
                      context: context,
                      title: '[أ] عدد تكرارات الآية الواحدة',
                      unit: 'مرات',
                      value: _singleRepeat,
                      min: 1,
                      max: 20,
                      presets: [3, 5, 7, 10],
                      onChanged: (v) {
                        setSheetState(() => _singleRepeat = v);
                        setState(() => _singleRepeat = v);
                      },
                      isDark: isDark,
                      textColor: textColor,
                      sageColor: sageColor,
                    ),
                    const SizedBox(height: 14),
                    _buildFriendlyNumberStepper(
                      context: context,
                      title: '[ب] عدد تكرارات الربط التراكمي',
                      unit: 'مرات',
                      value: _linkGroupRepeat,
                      min: 1,
                      max: 10,
                      presets: [1, 2, 3, 5],
                      onChanged: (v) {
                        setSheetState(() => _linkGroupRepeat = v);
                        setState(() => _linkGroupRepeat = v);
                      },
                      isDark: isDark,
                      textColor: textColor,
                      sageColor: sageColor,
                    ),
                    const SizedBox(height: 14),
                    _buildFriendlyNumberStepper(
                      context: context,
                      title: '[ج] تكرار تثبيت المقطع مجمعاً',
                      unit: 'مرات',
                      value: _blockRepeat,
                      min: 1,
                      max: 20,
                      presets: [2, 3, 4, 5, 7],
                      onChanged: (v) {
                        setSheetState(() => _blockRepeat = v);
                        setState(() => _blockRepeat = v);
                      },
                      isDark: isDark,
                      textColor: textColor,
                      sageColor: sageColor,
                    ),
                  ] else if (_repetitionMode == HifzRepetitionMode.combinedBlock) ...[
                    _buildFriendlyNumberStepper(
                      context: context,
                      title: 'عدد مرات تكرار المقطع كاملاً',
                      unit: 'مرات',
                      value: _blockRepeat,
                      min: 1,
                      max: 50,
                      presets: [3, 5, 7, 10, 15, 20],
                      onChanged: (v) {
                        setSheetState(() => _blockRepeat = v);
                        setState(() => _blockRepeat = v);
                      },
                      isDark: isDark,
                      textColor: textColor,
                      sageColor: sageColor,
                    ),
                  ] else ...[
                    _buildFriendlyNumberStepper(
                      context: context,
                      title: 'تكرار كل آية منفردة',
                      unit: 'مرات',
                      value: _singleRepeat,
                      min: 1,
                      max: 50,
                      presets: [3, 5, 7, 10, 15, 20],
                      onChanged: (v) {
                        setSheetState(() => _singleRepeat = v);
                        setState(() => _singleRepeat = v);
                      },
                      isDark: isDark,
                      textColor: textColor,
                      sageColor: sageColor,
                    ),
                  ],
                  const SizedBox(height: 16),

                  // 7. PAUSE DELAY (مهلة الصمت والترديد)
                  _buildFriendlyNumberStepper(
                    context: context,
                    title: 'مهلة الصمت للترديد الذاتي من الذاكرة',
                    unit: 'ثوانٍ',
                    value: _pauseDelaySeconds,
                    min: 0,
                    max: 30,
                    presets: [0, 2, 4, 6, 8, 10],
                    onChanged: (v) {
                      setSheetState(() => _pauseDelaySeconds = v);
                      setState(() => _pauseDelaySeconds = v);
                    },
                    isDark: isDark,
                    textColor: textColor,
                    sageColor: sageColor,
                  ),
                  const SizedBox(height: 18),

                  // 8. PLAYBACK SPEED (سرعة الصوت — حتى 2.0× للتحفيظ السريع)
                  Text(
                    'سرعة التلاوة والصوت (${_playbackSpeed}x)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [0.75, 1.0, 1.25, 1.5, 1.75, 2.0].map((speed) {
                      final isSelected = _playbackSpeed == speed;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.5),
                          child: InkWell(
                            onTap: () {
                              setSheetState(() => _playbackSpeed = speed);
                              setState(() => _playbackSpeed = speed);
                              _audioPlayer.setSpeed(speed);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? sageColor
                                    : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? sageColor : Colors.transparent,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${speed}x',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : textColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // 9. GIANT START BUTTON
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _startSession();
                    },
                    icon: const Icon(Icons.play_arrow, size: 24),
                    label: const Text(
                      'حفظ الإعدادات وبدء التكرار الآن',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sageColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 3,
                    ),
                  ),
                ],
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
    final textColor = isDark ? ZenTheme.darkAmberText : ZenTheme.lightText;
    final sageColor = isDark ? ZenTheme.darkSage : ZenTheme.lightSage;

    final isPlaying = _sessionState.isPlaying;
    final isPaused = _sessionState.isPaused;
    final isDelaying = _sessionState.isDelaying;
    final isTesting = _sessionState.isTesting;
    final currentAyah = _sessionState.currentAyah;
    final currentLoop = _sessionState.currentLoop;
    final totalLoops = _sessionState.totalLoops;

    final currentSurahInfo = QuranSurahs.getByNumber(_surah);

    // Display verses: either loaded from JSON or fallback
    final displayedAyahs = _loadedVerses.isNotEmpty
        ? _loadedVerses.where((a) {
            final num = a['num'] as int;
            return num >= _startAyah && num <= _endAyah;
          }).toList()
        : [
            {'num': 1, 'text': 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ'},
            {'num': 2, 'text': 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ'},
            {'num': 3, 'text': 'ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ'},
            {'num': 4, 'text': 'مَـٰلِكِ يَوْمِ ٱلدِّينِ'},
            {'num': 5, 'text': 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ'},
            {'num': 6, 'text': 'ٱهْدِنَا ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ'},
            {'num': 7, 'text': 'صِرَٰطَ ٱلَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ ٱلْمَغْضُوبِ عَلَيْهِمْ وَلَا ٱلضَّآلِّينَ'},
          ];

    return Scaffold(
      body: Stack(
        children: [
          // Main Verses Scroll Area
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              children: [
                if (!_isFocusMode) ...[
                  // App Brand Banner (Itqan Quran)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, top: 4),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/app_icon.png',
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: sageColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.menu_book, color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إتقان • القرآن الكريم',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            Text(
                              'الحلقة الذهبية للحفظ والتكرار المتقن',
                              style: TextStyle(
                                fontSize: 11,
                                color: sageColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Header Row: Surah & Reciter Quick Selectors
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? ZenTheme.darkSurface : ZenTheme.lightSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sageColor.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Tap to change Surah
                            InkWell(
                              onTap: _openSurahPickerModal,
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                child: Row(
                                  children: [
                                    Text(
                                      'سورة ${currentSurahInfo.nameAr}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.keyboard_arrow_down, color: sageColor, size: 22),
                                  ],
                                ),
                              ),
                            ),

                            // Tune / Settings Button
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: sageColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.tune, color: sageColor, size: 20),
                              ),
                              tooltip: 'إعدادات الجلسة وتحديد الآيات',
                              onPressed: _openSetupModalSheet,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Subtitle with Reciter Explorer & Ayah Range
                        Row(
                          children: [
                            // Reciter chip (tap to open 200+ Reciter Explorer)
                            Flexible(
                              child: InkWell(
                                onTap: _openReciterPickerModal,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: sageColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: sageColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _selectedReciter.audioMode == 'surah_stream'
                                            ? Icons.library_music
                                            : Icons.record_voice_over,
                                        size: 14,
                                        color: sageColor,
                                      ),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          _selectedReciter.nameAr,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: sageColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Icon(Icons.arrow_drop_down, size: 16, color: sageColor),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Ayah Range & Mode Chip
                            Text(
                              'الآيات $_startAyah-$_endAyah',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey[400] : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Instant 4-Riwayah Authentic KFGQPC Mushaf Switcher
                        Row(
                          children: [
                            {'id': 'hafs', 'label': 'حفص'},
                            {'id': 'warsh', 'label': 'ورش'},
                            {'id': 'qalun', 'label': 'قالون'},
                            {'id': 'duri', 'label': 'الدوري'},
                          ].map((item) {
                            final id = item['id']!;
                            final isSel = _riwayah == id;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                                child: InkWell(
                                  onTap: () => _switchRiwayah(id),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 7),
                                    decoration: BoxDecoration(
                                      color: isSel
                                          ? sageColor
                                          : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04)),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSel ? sageColor : Colors.transparent,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      item['label']!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSel ? Colors.white : textColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),

                        // Instant Fast-Hifz Speed Strip (1.0x -> 2.0x)
                        Row(
                          children: [
                            Icon(Icons.speed, size: 15, color: sageColor),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Row(
                                children: [1.0, 1.25, 1.5, 1.75, 2.0].map((spd) {
                                  final isSel = _playbackSpeed == spd;
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2),
                                      child: InkWell(
                                        onTap: () {
                                          setState(() => _playbackSpeed = spd);
                                          _audioPlayer.setSpeed(spd);
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isSel
                                                ? sageColor.withValues(alpha: 0.22)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isSel
                                                  ? sageColor
                                                  : Colors.grey.withValues(alpha: 0.25),
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '${spd}×',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isSel ? sageColor : textColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 4-PHASE GOLDEN LOOP PROGRESS STEPPER
                if (_repetitionMode == HifzRepetitionMode.goldenLoop)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? ZenTheme.darkSurface : ZenTheme.lightSurface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: sageColor.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.layers, size: 16, color: sageColor),
                                const SizedBox(width: 6),
                                Text(
                                  'محرك الحلقة الذهبية (٤ مراحل)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            if (isPlaying || isPaused || isTesting)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: sageColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _sessionState.phase == GoldenLoopPhase.phaseAMastery
                                      ? 'المرحلة أ: تثبيت فردي'
                                      : _sessionState.phase == GoldenLoopPhase.phaseBChainLink
                                      ? 'المرحلة ب: ربط تراكمي'
                                      : _sessionState.phase == GoldenLoopPhase.phaseCConsolidation
                                      ? 'المرحلة جـ: دمج نهائي'
                                      : 'المرحلة د: تسميع نشط',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: sageColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildPhaseStepItem(
                              letter: 'أ',
                              title: 'التثبيت',
                              subtitle: '$_singleRepeat× آية',
                              isActive: _sessionState.phase == GoldenLoopPhase.phaseAMastery,
                              isCompleted: _sessionState.phase == GoldenLoopPhase.phaseBChainLink ||
                                  _sessionState.phase == GoldenLoopPhase.phaseCConsolidation ||
                                  isTesting,
                              sageColor: sageColor,
                              textColor: textColor,
                            ),
                            const SizedBox(width: 6),
                            _buildPhaseStepItem(
                              letter: 'ب',
                              title: 'الربط',
                              subtitle: '$_linkGroupRepeat× تراكمي',
                              isActive: _sessionState.phase == GoldenLoopPhase.phaseBChainLink,
                              isCompleted: _sessionState.phase == GoldenLoopPhase.phaseCConsolidation || isTesting,
                              sageColor: sageColor,
                              textColor: textColor,
                            ),
                            const SizedBox(width: 6),
                            _buildPhaseStepItem(
                              letter: 'جـ',
                              title: 'الدمج',
                              subtitle: '$_blockRepeat× كامل',
                              isActive: _sessionState.phase == GoldenLoopPhase.phaseCConsolidation,
                              isCompleted: isTesting,
                              sageColor: sageColor,
                              textColor: textColor,
                            ),
                            const SizedBox(width: 6),
                            _buildPhaseStepItem(
                              letter: 'د',
                              title: 'التسميع',
                              subtitle: 'استرجاع غيباً',
                              isActive: isTesting || _sessionState.phase == GoldenLoopPhase.phaseDActiveTest,
                              isCompleted: false,
                              sageColor: sageColor,
                              textColor: textColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // PHASE D ACTIVE TEST BANNER
                if (isTesting)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.amber, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified, color: Colors.amber, size: 22),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'المرحلة (د): التسميع الذاتي والاسترجاع النشط',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.amber),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'اكتمل الاستماع والربط! الآن اقرأ المقطع كاملاً ($_startAyah - $_endAyah) من ذاكرتك الخالصة دون مساعدة.',
                          style: TextStyle(fontSize: 12, color: textColor),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            _audioPlayer.completeActiveTest();
                            _showCompletionSnackbar();
                          },
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('أتممت التسميع بنجاح ✓', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_isLoadingVerses)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  if (_maskingMode != MaskingMode.visible)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: () => setState(
                              () => _showFirstWordCue = !_showFirstWordCue,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _showFirstWordCue
                                    ? sageColor.withValues(alpha: 0.16)
                                    : (isDark
                                        ? ZenTheme.darkSurface
                                        : ZenTheme.lightSurface),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _showFirstWordCue
                                      ? sageColor
                                      : sageColor.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _showFirstWordCue
                                        ? Icons.visibility
                                        : Icons.visibility_outlined,
                                    size: 16,
                                    color: sageColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _showFirstWordCue
                                        ? 'مفتاح بداية الآية: مفعل'
                                        : 'إظهار بداية كل آية',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _showFirstWordCue
                                          ? sageColor
                                          : textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  MushafBookPage(
                    surahNumber: _surah,
                    surahNameAr: currentSurahInfo.nameAr,
                    startAyah: _startAyah,
                    endAyah: _endAyah,
                    riwayah: _riwayah,
                    ayahs: displayedAyahs,
                    fontSize: _fontSize,
                    maskingTier: _maskingMode == MaskingMode.visible
                        ? 0
                        : (_maskingMode == MaskingMode.blurred ? 1 : 2),
                    showFirstWordCue: _showFirstWordCue,
                    peekedAyahs: _peekedAyahs,
                    isPlaybackActive: isPlaying || isPaused,
                    currentAyahNumber: currentAyah,
                    activePhase: _sessionState.phase,
                    activeChainEndAyah:
                        (_startAyah + _sessionState.chainStep).clamp(_startAyah, _endAyah),
                    onAyahTap: _peekAyah,
                  ),
                ],
                const SizedBox(height: 120), // Spacing for floating control pill
              ],
            ),
          ),

          // Floating Translucent Bottom Control Pill
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: (isDark ? ZenTheme.darkSurface : ZenTheme.lightSurface)
                        .withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: sageColor.withValues(alpha: 0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Status and Loop Counter
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isPlaying || isPaused
                                  ? (_sessionState.phaseLabel.isNotEmpty
                                      ? _sessionState.phaseLabel
                                      : 'آية $currentAyah • تكرار $currentLoop/$totalLoops')
                                  : (isTesting
                                      ? 'المرحلة (د): التسميع الذاتي'
                                      : '${currentSurahInfo.nameAr} ($_startAyah - $_endAyah)'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isTesting ? Colors.amber : textColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isDelaying)
                              Text(
                                'ردد بصوتك الآن...',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: sageColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Masking Eye Toggle
                      IconButton(
                        icon: Icon(
                          _maskingMode == MaskingMode.visible
                              ? Icons.visibility
                              : (_maskingMode == MaskingMode.blurred
                                  ? Icons.blur_on
                                  : Icons.visibility_off),
                          color: sageColor,
                        ),
                        onPressed: _toggleMaskingMode,
                        tooltip: 'تبديل وضع الإخفاء',
                      ),

                      // Live Voice Speed Toggle
                      InkWell(
                        onTap: _cyclePlaybackSpeed,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: sageColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: sageColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${_playbackSpeed}x',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: sageColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Audio Controls
                      if (isPlaying) ...[
                        IconButton(
                          icon: const Icon(Icons.pause, color: Colors.amber, size: 26),
                          onPressed: _pauseSession,
                          tooltip: 'إيقاف مؤقت',
                        ),
                        IconButton(
                          icon: const Icon(Icons.stop, color: Colors.redAccent, size: 26),
                          onPressed: _stopSession,
                          tooltip: 'إنهاء الجلسة',
                        ),
                      ] else if (isPaused) ...[
                        IconButton(
                          icon: Icon(Icons.play_arrow, color: sageColor, size: 28),
                          onPressed: _resumeSession,
                          tooltip: 'متابعة التكرار',
                        ),
                        IconButton(
                          icon: const Icon(Icons.stop, color: Colors.redAccent, size: 26),
                          onPressed: _stopSession,
                          tooltip: 'إنهاء الجلسة',
                        ),
                      ] else if (isTesting) ...[
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.amber, size: 28),
                          onPressed: () {
                            _audioPlayer.completeActiveTest();
                            _showCompletionSnackbar();
                          },
                          tooltip: 'إتمام التسميع',
                        ),
                      ] else
                        ElevatedButton.icon(
                          onPressed: _startSession,
                          icon: const Icon(Icons.play_arrow, size: 20),
                          label: const Text('بدء التكرار', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: sageColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
