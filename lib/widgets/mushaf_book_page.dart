import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../core/theme/zen_theme.dart';
import '../core/audio/audio_player_service.dart';

/// Authentic Flowing Mushaf Book Page Widget for Flutter
/// Renders ayahs as continuous justified Uthmanic prose inside a double-rule
/// manuscript frame with ornate Arabic-Indic verse medallions ﴿١﴾, spatial
/// 3-tier masking, First-Word cueing, and 2.5s tap-to-peek per ayah.
class MushafBookPage extends StatefulWidget {
  final int surahNumber;
  final String surahNameAr;
  final int startAyah;
  final int endAyah;
  final String riwayah;
  final List<Map<String, dynamic>> ayahs;
  final double fontSize;
  final int maskingTier; // 0 = visible, 1 = blurred, 2 = hidden
  final bool showFirstWordCue;
  final Set<int> peekedAyahs;
  final bool isPlaybackActive;
  final int currentAyahNumber;
  final GoldenLoopPhase activePhase;
  final int activeChainEndAyah;
  final void Function(int ayahNum) onAyahTap;

  const MushafBookPage({
    super.key,
    required this.surahNumber,
    required this.surahNameAr,
    required this.startAyah,
    required this.endAyah,
    required this.riwayah,
    required this.ayahs,
    required this.fontSize,
    required this.maskingTier,
    required this.showFirstWordCue,
    required this.peekedAyahs,
    required this.isPlaybackActive,
    required this.currentAyahNumber,
    required this.activePhase,
    required this.activeChainEndAyah,
    required this.onAyahTap,
  });

  static String toArabicIndic(int number) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().replaceAllMapped(
          RegExp(r'\d'),
          (m) => digits[int.parse(m.group(0)!)],
        );
  }

  @override
  State<MushafBookPage> createState() => _MushafBookPageState();
}

class _MushafBookPageState extends State<MushafBookPage> {
  final List<TapGestureRecognizer> _recognizers = [];

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  String _riwayahLabel(String code) {
    switch (code) {
      case 'warsh':
        return 'رواية ورش عن نافع';
      case 'qalun':
        return 'رواية قالون عن نافع';
      case 'duri':
        return 'رواية الدوري عن أبي عمرو';
      default:
        return 'رواية حفص عن عاصم';
    }
  }

  (String, String) _splitFirstWord(String text) {
    final trimmed = text.trim();
    final idx = trimmed.indexOf(' ');
    if (idx == -1) return (trimmed, '');
    return (trimmed.substring(0, idx), trimmed.substring(idx));
  }

  @override
  Widget build(BuildContext context) {
    // Recreate tap recognizers cleanly for current build pass
    _disposeRecognizers();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? const Color(0xFF161F1B) : const Color(0xFFFFFDF8);
    final outerBorder =
        isDark ? const Color(0xFF26342D) : const Color(0xFFDFD5C3);
    final goldFrame = isDark
        ? const Color(0xFFC8A24A).withValues(alpha: 0.32)
        : const Color(0xFFC8A24A).withValues(alpha: 0.48);
    final goldText = isDark ? const Color(0xFFD9B664) : const Color(0xFFA57E2B);
    final sageColor = isDark ? ZenTheme.darkSage : ZenTheme.lightSage;
    final inkColor = isDark ? const Color(0xFFEDE2CC) : const Color(0xFF1D221F);
    final mutedMeta =
        isDark ? const Color(0xFF93A49C) : const Color(0xFF6B756E);
    final dividerColor =
        isDark ? const Color(0xFF24322B) : const Color(0xFFE8E0D0);

    final showBasmalah = widget.surahNumber != 1 &&
        widget.surahNumber != 9 &&
        widget.startAyah == 1;

    final List<InlineSpan> spans = [];

    for (final ayah in widget.ayahs) {
      final ayahNum = ayah['num'] as int;
      final ayahText = (ayah['text'] as String).trim();

      final isCurrent =
          widget.isPlaybackActive && widget.currentAyahNumber == ayahNum;
      final isPeeked = widget.peekedAyahs.contains(ayahNum);
      final isInActiveChain = widget.isPlaybackActive &&
          widget.activePhase == GoldenLoopPhase.phaseBChainLink &&
          ayahNum >= widget.startAyah &&
          ayahNum <= widget.activeChainEndAyah;

      final isRevealed = widget.maskingTier == 0 || isCurrent || isPeeked;
      final isBlurred = widget.maskingTier == 1 && !isRevealed;
      final isHidden = widget.maskingTier == 2 && !isRevealed;

      TapGestureRecognizer? recognizer;
      if (widget.maskingTier != 0) {
        recognizer = TapGestureRecognizer()
          ..onTap = () => widget.onAyahTap(ayahNum);
        _recognizers.add(recognizer);
      }

      final baseStyle = TextStyle(
        fontFamily: 'KFGQPCUthmanic',
        fontSize: widget.fontSize,
        height: 2.28,
        color: isCurrent
            ? (isDark ? const Color(0xFFFFF8EA) : const Color(0xFF12261D))
            : isPeeked
                ? (isDark ? const Color(0xFFE1F7EC) : const Color(0xFF153528))
                : inkColor,
        backgroundColor: isCurrent
            ? sageColor.withValues(alpha: isDark ? 0.24 : 0.16)
            : isPeeked
                ? const Color(0xFF2E7D32).withValues(alpha: isDark ? 0.22 : 0.14)
                : null,
        decoration: isInActiveChain && !isCurrent
            ? TextDecoration.underline
            : TextDecoration.none,
        decorationColor: goldText.withValues(alpha: 0.75),
        decorationThickness: 1.6,
      );

      if (isHidden) {
        final (firstWord, rest) = _splitFirstWord(ayahText);
        if (widget.showFirstWordCue && firstWord.isNotEmpty) {
          spans.add(
            TextSpan(
              text: firstWord,
              recognizer: recognizer,
              style: baseStyle.copyWith(color: sageColor),
            ),
          );
          if (rest.isNotEmpty) {
            spans.add(
              TextSpan(
                text: rest,
                recognizer: recognizer,
                style: baseStyle.copyWith(
                  color: Colors.transparent,
                  backgroundColor: isDark
                      ? const Color(0xFF223029).withValues(alpha: 0.85)
                      : const Color(0xFFEAE2D3).withValues(alpha: 0.8),
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.dotted,
                  decorationColor: isDark
                      ? const Color(0xFF3A4D43)
                      : const Color(0xFFB8A98E),
                ),
              ),
            );
          }
        } else {
          spans.add(
            TextSpan(
              text: ayahText,
              recognizer: recognizer,
              style: baseStyle.copyWith(
                color: Colors.transparent,
                backgroundColor: isDark
                    ? const Color(0xFF223029).withValues(alpha: 0.85)
                    : const Color(0xFFEAE2D3).withValues(alpha: 0.8),
                decoration: TextDecoration.underline,
                decorationStyle: TextDecorationStyle.dotted,
                decorationColor: isDark
                    ? const Color(0xFF3A4D43)
                    : const Color(0xFFB8A98E),
              ),
            ),
          );
        }
      } else if (isBlurred) {
        final blurPaint = Paint()
          ..color = inkColor.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.5);

        final (firstWord, rest) = _splitFirstWord(ayahText);
        if (widget.showFirstWordCue && firstWord.isNotEmpty) {
          spans.add(
            TextSpan(
              text: firstWord,
              recognizer: recognizer,
              style: baseStyle.copyWith(color: sageColor),
            ),
          );
          if (rest.isNotEmpty) {
            spans.add(
              TextSpan(
                text: rest,
                recognizer: recognizer,
                style: baseStyle.copyWith(color: null, foreground: blurPaint),
              ),
            );
          }
        } else {
          spans.add(
            TextSpan(
              text: ayahText,
              recognizer: recognizer,
              style: baseStyle.copyWith(color: null, foreground: blurPaint),
            ),
          );
        }
      } else {
        spans.add(
          TextSpan(
            text: ayahText,
            recognizer: recognizer,
            style: baseStyle,
          ),
        );
      }

      // Inline Ornate Verse-End Medallion ﴿١﴾ (Always Crisp & Anchored)
      spans.add(
        TextSpan(
          text: ' ﴿${MushafBookPage.toArabicIndic(ayahNum)}﴾ ',
          recognizer: recognizer,
          style: TextStyle(
            fontFamily: 'KFGQPCUthmanic',
            fontSize: (widget.fontSize * 0.82).clamp(18.0, 36.0),
            height: 2.28,
            fontWeight:
                (isCurrent || isPeeked) ? FontWeight.bold : FontWeight.normal,
            color: isCurrent
                ? sageColor
                : isPeeked
                    ? const Color(0xFF2E7D32)
                    : goldText,
            backgroundColor: isCurrent
                ? sageColor.withValues(alpha: isDark ? 0.24 : 0.16)
                : isPeeked
                    ? const Color(0xFF2E7D32)
                        .withValues(alpha: isDark ? 0.22 : 0.14)
                    : null,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: pageBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: outerBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: goldFrame, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Running Mushaf Page Header (Clean Unboxed Metadata)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'سورة ${widget.surahNameAr}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: inkColor,
                  ),
                ),
                Text(
                  '${_riwayahLabel(widget.riwayah)} · ${MushafBookPage.toArabicIndic(widget.startAyah)}–${MushafBookPage.toArabicIndic(widget.endAyah)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: mutedMeta,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(height: 1, color: dividerColor),
            const SizedBox(height: 16),

            // Ornamental Surah Title Cartouche
            Center(
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1C2822)
                      : const Color(0xFFF7F1E3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: goldFrame, width: 1),
                ),
                child: Text(
                  'سُورَةُ ${widget.surahNameAr}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'KFGQPCUthmanic',
                    fontSize: 24,
                    color: inkColor,
                    height: 1.5,
                  ),
                ),
              ),
            ),

            if (showBasmalah) ...[
              const SizedBox(height: 14),
              Text(
                'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'KFGQPCUthmanic',
                  fontSize: 22,
                  color: inkColor.withValues(alpha: 0.9),
                  height: 1.7,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Continuous Justified Mushaf Prose
            Directionality(
              textDirection: TextDirection.rtl,
              child: RichText(
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
                text: TextSpan(children: spans),
              ),
            ),

            const SizedBox(height: 18),
            Divider(height: 1, color: dividerColor),
            const SizedBox(height: 10),

            // Running Mushaf Page Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'مقطع الحفظ: ${MushafBookPage.toArabicIndic(widget.startAyah)} – ${MushafBookPage.toArabicIndic(widget.endAyah)}',
                  style: TextStyle(fontSize: 11, color: mutedMeta),
                ),
                Text(
                  widget.maskingTier != 0
                      ? 'انقر على الآية للتلصص المؤقت (٢.٥ث)'
                      : 'تخطيط المصحف المتصل',
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.maskingTier != 0 ? sageColor : mutedMeta,
                    fontWeight: widget.maskingTier != 0
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
