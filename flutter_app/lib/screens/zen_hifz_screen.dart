import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/zen_theme.dart';
import '../core/audio/audio_player_service.dart';
import '../core/audio/reciters_data.dart';
import '../core/quran/surah_data.dart';

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

  // Selected Reciter
  late HifzReciter _selectedReciter;

  // Loaded verses from dynamic JSON
  List<Map<String, dynamic>> _loadedVerses = [];
  bool _isLoadingVerses = false;

  // State from AudioPlayerService
  HifzSessionState _sessionState = const HifzSessionState();
  final Map<int, Timer> _peekTimers = {};

  @override
  void initState() {
    super.initState();
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

  Future<void> _loadVerses() async {
    setState(() => _isLoadingVerses = true);
    try {
      final verses = await QuranScriptService.getVersesForSurah(
        surahNumber: _surah,
        riwayah: _riwayah == 'duri' ? 'hafs' : _riwayah,
      );
      if (mounted) {
        setState(() {
          _loadedVerses = verses;
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
      ),
    );
  }

  void _cyclePlaybackSpeed() {
    final speeds = [0.75, 1.0, 1.25, 1.5];
    final nextIndex = (speeds.indexOf(_playbackSpeed) + 1) % speeds.length;
    final nextSpeed = speeds[nextIndex];
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

  /// Modal to choose Reciter (الشيخ / القارئ المعتمد) with filters & pedagogical notes
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
        String activeFilter = _riwayah;
        return StatefulBuilder(
          builder: (context, setPickerState) {
            final reciters = activeFilter == 'all'
                ? QuranRecitersData.all
                : QuranRecitersData.getByRiwayah(activeFilter);

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'اختيار الشيخ والقارئ المعتمد',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'قراء متقنون موثوقو الروايات من السحابة الصوتية المباشرة',
                            style: TextStyle(fontSize: 12, color: sageColor, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Riwayah Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        {'id': 'all', 'label': 'جميع القراء (${QuranRecitersData.all.length})'},
                        {'id': 'hafs', 'label': 'حفص عن عاصم'},
                        {'id': 'warsh', 'label': 'ورش عن نافع'},
                        {'id': 'qalun', 'label': 'قالون عن نافع'},
                        {'id': 'duri', 'label': 'الدوري عن أبي عمرو'},
                      ].map((chip) {
                        final id = chip['id']!;
                        final label = chip['label']!;
                        final isSel = activeFilter == id;
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: InkWell(
                            onTap: () => setPickerState(() => activeFilter = id),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSel ? sageColor : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
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
                  const SizedBox(height: 14),

                  Expanded(
                    child: ListView.separated(
                      itemCount: reciters.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final reciter = reciters[idx];
                        final isSelected = reciter.id == _selectedReciter.id;

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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                  radius: 22,
                                  backgroundColor: isSelected
                                      ? sageColor
                                      : (isDark ? Colors.white12 : Colors.black12),
                                  child: Icon(
                                    Icons.record_voice_over,
                                    color: isSelected ? Colors.white : sageColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            reciter.nameAr,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          if (reciter.tempo == 'slow')
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: sageColor.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text('متأنٍّ', style: TextStyle(fontSize: 10, color: sageColor, fontWeight: FontWeight.bold)),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      if (reciter.pedagogicalNote != null)
                                        Text(
                                          reciter.pedagogicalNote!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: sageColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check, color: Colors.white, size: 16),
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
            final maxAyah = currentSurahInfo.versesCount;

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

                  // 8. PLAYBACK SPEED (سرعة الصوت)
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
                    children: [0.75, 1.0, 1.25, 1.5].map((speed) {
                      final isSelected = _playbackSpeed == speed;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () {
                              setSheetState(() => _playbackSpeed = speed);
                              setState(() => _playbackSpeed = speed);
                              _audioPlayer.setSpeed(speed);
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                                '${speed}x',
                                style: TextStyle(
                                  fontSize: 14,
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

                        // Subtitle with Reciter & Riwayah Bar
                        Row(
                          children: [
                            // Reciter chip (tap to switch Sheikh)
                            InkWell(
                              onTap: _openReciterPickerModal,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: sageColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.record_voice_over, size: 14, color: sageColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      _selectedReciter.nameAr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: sageColor,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(Icons.arrow_drop_down, size: 16, color: sageColor),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Ayah Range & Mode Chip
                            Expanded(
                              child: Text(
                                'الآيات $_startAyah-$_endAyah • ${_repetitionMode == HifzRepetitionMode.goldenLoop ? 'الحلقة الذهبية (أ-د)' : (_repetitionMode == HifzRepetitionMode.combinedBlock ? 'مجمع' : 'فردي')}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

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
                else
                  // Verses list
                  ...displayedAyahs.map((ayah) {
                    final ayahNum = ayah['num'] as int;
                    final isCurrent = (isPlaying || isPaused) && currentAyah == ayahNum;
                    final isPeeked = _peekedAyahs.contains(ayahNum);

                    Widget verseContent;
                    if (_maskingMode == MaskingMode.hidden && !isPeeked && !isCurrent) {
                      verseContent = const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          '••••••••••••••••••••••••••••••••',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            letterSpacing: 4,
                            fontSize: 20,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    } else if (_maskingMode == MaskingMode.blurred && !isCurrent && !isPeeked) {
                      verseContent = ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                        child: Text(
                          ayah['text'] as String,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: _fontSize,
                            height: 2.1,
                            color: textColor,
                          ),
                        ),
                      );
                    } else {
                      verseContent = Text(
                        ayah['text'] as String,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: _fontSize,
                          height: 2.1,
                          color: isCurrent
                              ? sageColor
                              : (isPeeked ? (isDark ? ZenTheme.darkSage : ZenTheme.lightSage) : textColor),
                          fontWeight: (isCurrent || isPeeked) ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }

                    return GestureDetector(
                      onTap: () => _peekAyah(ayahNum),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? sageColor.withValues(alpha: 0.12)
                              : (isPeeked
                                  ? sageColor.withValues(alpha: 0.15)
                                  : (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02))),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isCurrent
                                ? sageColor
                                : (isPeeked ? sageColor : Colors.transparent),
                            width: (isCurrent || isPeeked) ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: isCurrent
                                      ? sageColor
                                      : (isPeeked ? sageColor : (isDark ? Colors.white12 : Colors.black12)),
                                  child: Text(
                                    '$ayahNum',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: (isCurrent || isPeeked) ? Colors.white : textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (isCurrent && isDelaying)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: sageColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'مهلة الترديد: ${_sessionState.delayRemainingSeconds}ث',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: sageColor,
                                      ),
                                    ),
                                  )
                                else if (_maskingMode != MaskingMode.visible)
                                  Text(
                                    isPeeked ? 'كشف مؤقت (2.5ث)' : 'انقر للكشف',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isPeeked ? sageColor : Colors.grey,
                                      fontWeight: isPeeked ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            verseContent,
                          ],
                        ),
                      ),
                    );
                  }),
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
