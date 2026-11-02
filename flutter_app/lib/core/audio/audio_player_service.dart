import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'silent_wav_generator.dart';

enum GoldenLoopPhase {
  idle,
  phaseAMastery,      // Phase A: Individual Verse Mastery (آية بآية)
  phaseBChainLink,    // Phase B: Cumulative Chain Linking (الربط التراكمي)
  phaseCConsolidation,// Phase C: Full Block Consolidation (تثبيت المقطع مجمعاً)
  phaseDActiveTest,   // Phase D: Silent Active Recall Test (التسميع الذاتي)
}

/// Tag attached to each item in the AudioSource playlist for precise progress tracking
class AyahPlaybackTag {
  final int surah;
  final int ayah;
  final int loopIndex;
  final int totalLoops;
  final bool isSilence;
  final GoldenLoopPhase phase;
  final String phaseLabel;
  final int chainStep;
  final int totalChainSteps;

  const AyahPlaybackTag({
    required this.surah,
    required this.ayah,
    required this.loopIndex,
    required this.totalLoops,
    required this.isSilence,
    this.phase = GoldenLoopPhase.phaseAMastery,
    this.phaseLabel = '',
    this.chainStep = 1,
    this.totalChainSteps = 1,
  });

  @override
  String toString() {
    return 'Tag(surah: $surah, ayah: $ayah, loop: $loopIndex/$totalLoops, silence: $isSilence, phase: $phase)';
  }
}

enum HifzRepetitionMode {
  goldenLoop,   // The complete 4-phase pedagogical loop (A + B + C + D)
  combinedBlock,// Continuous repetition of the full block
  verseByVerse, // Simple repeat per verse
}

/// Repetition configuration for Zen Hifz memorization session
class HifzVerseConfig {
  final int surah;
  final int startAyah;
  final int endAyah;
  final HifzRepetitionMode repetitionMode; // goldenLoop, combinedBlock, or verseByVerse
  final int blockRepeatCount; // M: loops for combined block consolidation
  final int singleRepeatCount;// N: repeats per individual verse
  final int linkGroupRepeat;  // L: repeats for chain linking steps
  final int pauseDelaySeconds;// X: silence duration for user to recite from memory
  final double playbackSpeed; // 0.75, 1.0, 1.25, 1.5
  final String reciterCdnPattern;
  final String fallbackCdnPattern;

  HifzVerseConfig({
    required this.surah,
    required this.startAyah,
    required this.endAyah,
    this.repetitionMode = HifzRepetitionMode.goldenLoop,
    this.blockRepeatCount = 4,
    this.singleRepeatCount = 5,
    this.linkGroupRepeat = 2,
    this.pauseDelaySeconds = 4,
    this.playbackSpeed = 1.0,
    this.reciterCdnPattern =
        'https://everyayah.com/data/Husary_Muallim_128kbps/{surah:03d}{ayah:03d}.mp3',
    this.fallbackCdnPattern =
        'https://everyayah.com/data/Alafasy_128kbps/{surah:03d}{ayah:03d}.mp3',
  });
}

enum HifzPlaybackStatus {
  idle,
  preparing,
  playing,
  paused,
  delaying,
  testing, // Phase D active testing mode
  completed,
  error,
}

class HifzSessionState {
  final HifzPlaybackStatus status;
  final int currentSurah;
  final int currentAyah;
  final int currentLoop;
  final int totalLoops;
  final GoldenLoopPhase phase;
  final String phaseLabel;
  final int chainStep;
  final int totalChainSteps;
  final bool isDelaying;
  final int delayRemainingSeconds;
  final String? errorMessage;

  const HifzSessionState({
    this.status = HifzPlaybackStatus.idle,
    this.currentSurah = 1,
    this.currentAyah = 1,
    this.currentLoop = 1,
    this.totalLoops = 5,
    this.phase = GoldenLoopPhase.idle,
    this.phaseLabel = '',
    this.chainStep = 1,
    this.totalChainSteps = 1,
    this.isDelaying = false,
    this.delayRemainingSeconds = 0,
    this.errorMessage,
  });

  bool get isPlaying =>
      status == HifzPlaybackStatus.playing || status == HifzPlaybackStatus.delaying;
  bool get isPaused => status == HifzPlaybackStatus.paused;
  bool get isIdle => status == HifzPlaybackStatus.idle;
  bool get isTesting => status == HifzPlaybackStatus.testing;

  HifzSessionState copyWith({
    HifzPlaybackStatus? status,
    int? currentSurah,
    int? currentAyah,
    int? currentLoop,
    int? totalLoops,
    GoldenLoopPhase? phase,
    String? phaseLabel,
    int? chainStep,
    int? totalChainSteps,
    bool? isDelaying,
    int? delayRemainingSeconds,
    String? errorMessage,
  }) {
    return HifzSessionState(
      status: status ?? this.status,
      currentSurah: currentSurah ?? this.currentSurah,
      currentAyah: currentAyah ?? this.currentAyah,
      currentLoop: currentLoop ?? this.currentLoop,
      totalLoops: totalLoops ?? this.totalLoops,
      phase: phase ?? this.phase,
      phaseLabel: phaseLabel ?? this.phaseLabel,
      chainStep: chainStep ?? this.chainStep,
      totalChainSteps: totalChainSteps ?? this.totalChainSteps,
      isDelaying: isDelaying ?? this.isDelaying,
      delayRemainingSeconds: delayRemainingSeconds ?? this.delayRemainingSeconds,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// AudioPlayerService: Core just_audio engine powering gapless repetition,
/// link verse loops, and configurable pause delays for Zen Hifz memorization.
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  final _stateController = StreamController<HifzSessionState>.broadcast();
  Stream<HifzSessionState> get sessionStateStream => _stateController.stream;

  HifzSessionState _currentState = const HifzSessionState();
  HifzSessionState get currentState => _currentState;

  StreamSubscription<SequenceState?>? _sequenceSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  Timer? _delayCountdownTimer;
  HifzVerseConfig? _activeConfig;

  AudioPlayerService() {
    _initListeners();
  }

  void _emitState(HifzSessionState newState) {
    _currentState = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  void _initListeners() {
    // Listen to current sequence item change
    _sequenceSubscription = _player.sequenceStateStream.listen((seqState) {
      if (seqState == null) return;
      final currentSource = seqState.currentSource;
      if (currentSource == null) return;

      final tag = currentSource.tag;
      if (tag is AyahPlaybackTag) {
        _handleTagTransition(tag);
      }
    });

    // Listen to playback state changes
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _stopDelayTimer();
        // If golden loop mode, transition to Phase D (active test) before completion
        if (_activeConfig?.repetitionMode == HifzRepetitionMode.goldenLoop) {
          _emitState(_currentState.copyWith(
            status: HifzPlaybackStatus.testing,
            phase: GoldenLoopPhase.phaseDActiveTest,
            phaseLabel: 'المرحلة (د): التسميع والاسترجاع الذاتي',
            isDelaying: false,
          ));
        } else {
          _emitState(_currentState.copyWith(
            status: HifzPlaybackStatus.completed,
            isDelaying: false,
          ));
        }
      } else if (state.processingState == ProcessingState.ready) {
        if (state.playing) {
          if (!_currentState.isDelaying && _currentState.status != HifzPlaybackStatus.testing) {
            _emitState(_currentState.copyWith(status: HifzPlaybackStatus.playing));
          }
        } else {
          if (_currentState.status != HifzPlaybackStatus.testing) {
            _emitState(_currentState.copyWith(status: HifzPlaybackStatus.paused));
          }
        }
      }
    });
  }

  void _handleTagTransition(AyahPlaybackTag tag) {
    if (tag.isSilence) {
      _startDelayTimer();
      _emitState(_currentState.copyWith(
        status: HifzPlaybackStatus.delaying,
        currentSurah: tag.surah,
        currentAyah: tag.ayah,
        currentLoop: tag.loopIndex,
        totalLoops: tag.totalLoops,
        phase: tag.phase,
        phaseLabel: tag.phaseLabel,
        chainStep: tag.chainStep,
        totalChainSteps: tag.totalChainSteps,
        isDelaying: true,
      ));
    } else {
      _stopDelayTimer();
      _emitState(_currentState.copyWith(
        status: HifzPlaybackStatus.playing,
        currentSurah: tag.surah,
        currentAyah: tag.ayah,
        currentLoop: tag.loopIndex,
        totalLoops: tag.totalLoops,
        phase: tag.phase,
        phaseLabel: tag.phaseLabel,
        chainStep: tag.chainStep,
        totalChainSteps: tag.totalChainSteps,
        isDelaying: false,
        delayRemainingSeconds: 0,
      ));
    }
  }

  void _startDelayTimer() {
    _stopDelayTimer();
    int remaining = _activeConfig?.pauseDelaySeconds ?? 4;
    _delayCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remaining > 0) {
        remaining--;
        _emitState(_currentState.copyWith(delayRemainingSeconds: remaining));
      } else {
        _stopDelayTimer();
      }
    });
  }

  void _stopDelayTimer() {
    _delayCountdownTimer?.cancel();
    _delayCountdownTimer = null;
  }

  String _formatUrl(String pattern, int surah, int ayah) {
    final sStr = surah.toString().padLeft(3, '0');
    final aStr = ayah.toString().padLeft(3, '0');
    return pattern.replaceAll('{surah:03d}', sStr).replaceAll('{ayah:03d}', aStr);
  }

  /// Builds a gapless sequence respecting the selected repetition mode
  Future<void> prepareAndPlay(HifzVerseConfig config) async {
    try {
      _activeConfig = config;
      _stopDelayTimer();
      _emitState(_currentState.copyWith(
        status: HifzPlaybackStatus.preparing,
        currentSurah: config.surah,
        currentAyah: config.startAyah,
        currentLoop: 1,
        totalLoops: config.singleRepeatCount,
        phase: config.repetitionMode == HifzRepetitionMode.goldenLoop
            ? GoldenLoopPhase.phaseAMastery
            : GoldenLoopPhase.phaseCConsolidation,
        phaseLabel: config.repetitionMode == HifzRepetitionMode.goldenLoop
            ? 'المرحلة (أ): إتقان الآية منفردة'
            : (config.repetitionMode == HifzRepetitionMode.combinedBlock
                ? 'تكرار المقطع مجمعاً'
                : 'تكرار آية بآية'),
      ));

      final sources = <AudioSource>[];

      // Prepare silent audio file if pause delay is configured
      AudioSource? silentSource;
      if (config.pauseDelaySeconds > 0) {
        final silentFile = await SilentWavGenerator.createSilentWav(
          durationSeconds: config.pauseDelaySeconds,
        );
        silentSource = AudioSource.file(silentFile.path);
      }

      if (config.repetitionMode == HifzRepetitionMode.goldenLoop) {
        // =====================================================================
        // THE GOLDEN LOOP PEDAGOGICAL SPECIFICATION (الحلقة الذهبية المتقنة)
        // =====================================================================

        // --- PHASE A: INDIVIDUAL VERSE MASTERY (إتقان الآيات منفردة) ---
        for (int a = config.startAyah; a <= config.endAyah; a++) {
          final url = _formatUrl(config.reciterCdnPattern, config.surah, a);
          for (int loop = 1; loop <= config.singleRepeatCount; loop++) {
            sources.add(AudioSource.uri(
              Uri.parse(url),
              tag: AyahPlaybackTag(
                surah: config.surah,
                ayah: a,
                loopIndex: loop,
                totalLoops: config.singleRepeatCount,
                isSilence: false,
                phase: GoldenLoopPhase.phaseAMastery,
                phaseLabel: 'المرحلة (أ): إتقان الآية $a منفردة',
              ),
            ));

            if (silentSource != null) {
              sources.add(AudioSource.uri(
                (silentSource as UriAudioSource).uri,
                tag: AyahPlaybackTag(
                  surah: config.surah,
                  ayah: a,
                  loopIndex: loop,
                  totalLoops: config.singleRepeatCount,
                  isSilence: true,
                  phase: GoldenLoopPhase.phaseAMastery,
                  phaseLabel: 'المرحلة (أ): ردد الآية $a من الذاكرة',
                ),
              ));
            }
          }
        }

        // --- PHASE B: CUMULATIVE CHAIN LINKING (الربط التراكمي العثماني) ---
        if (config.endAyah > config.startAyah && config.linkGroupRepeat > 0) {
          final totalSteps = config.endAyah - config.startAyah;
          int stepCount = 0;

          for (int endChain = config.startAyah + 1; endChain <= config.endAyah; endChain++) {
            stepCount++;
            for (int lLoop = 1; lLoop <= config.linkGroupRepeat; lLoop++) {
              for (int a = config.startAyah; a <= endChain; a++) {
                final url = _formatUrl(config.reciterCdnPattern, config.surah, a);
                sources.add(AudioSource.uri(
                  Uri.parse(url),
                  tag: AyahPlaybackTag(
                    surah: config.surah,
                    ayah: a,
                    loopIndex: lLoop,
                    totalLoops: config.linkGroupRepeat,
                    isSilence: false,
                    phase: GoldenLoopPhase.phaseBChainLink,
                    phaseLabel: 'المرحلة (ب): الربط التراكمي (${config.startAyah} إلى $endChain)',
                    chainStep: stepCount,
                    totalChainSteps: totalSteps,
                  ),
                ));
              }

              // Silence gap after chain link
              if (silentSource != null) {
                sources.add(AudioSource.uri(
                  (silentSource as UriAudioSource).uri,
                  tag: AyahPlaybackTag(
                    surah: config.surah,
                    ayah: endChain,
                    loopIndex: lLoop,
                    totalLoops: config.linkGroupRepeat,
                    isSilence: true,
                    phase: GoldenLoopPhase.phaseBChainLink,
                    phaseLabel: 'المرحلة (ب): ردد السلسلة (${config.startAyah} - $endChain)',
                    chainStep: stepCount,
                    totalChainSteps: totalSteps,
                  ),
                ));
              }
            }
          }
        }

        // --- PHASE C: FULL BLOCK CONSOLIDATION (تثبيت المقطع كاملاً مجمعاً) ---
        for (int bLoop = 1; bLoop <= config.blockRepeatCount; bLoop++) {
          for (int a = config.startAyah; a <= config.endAyah; a++) {
            final url = _formatUrl(config.reciterCdnPattern, config.surah, a);
            sources.add(AudioSource.uri(
              Uri.parse(url),
              tag: AyahPlaybackTag(
                surah: config.surah,
                ayah: a,
                loopIndex: bLoop,
                totalLoops: config.blockRepeatCount,
                isSilence: false,
                phase: GoldenLoopPhase.phaseCConsolidation,
                phaseLabel: 'المرحلة (ج): تثبيت المقطع مجمعاً بالكامل',
              ),
            ));
          }

          if (silentSource != null) {
            sources.add(AudioSource.uri(
              (silentSource as UriAudioSource).uri,
              tag: AyahPlaybackTag(
                surah: config.surah,
                ayah: config.endAyah,
                loopIndex: bLoop,
                totalLoops: config.blockRepeatCount,
                isSilence: true,
                phase: GoldenLoopPhase.phaseCConsolidation,
                phaseLabel: 'المرحلة (ج): ردد المقطع كاملاً بصوتك',
              ),
            ));
          }
        }
      } else if (config.repetitionMode == HifzRepetitionMode.combinedBlock) {
        // Simple Combined block mode
        for (int bLoop = 1; bLoop <= config.blockRepeatCount; bLoop++) {
          for (int a = config.startAyah; a <= config.endAyah; a++) {
            final url = _formatUrl(config.reciterCdnPattern, config.surah, a);
            sources.add(AudioSource.uri(
              Uri.parse(url),
              tag: AyahPlaybackTag(
                surah: config.surah,
                ayah: a,
                loopIndex: bLoop,
                totalLoops: config.blockRepeatCount,
                isSilence: false,
                phase: GoldenLoopPhase.phaseCConsolidation,
                phaseLabel: 'تكرار المقطع مجمعاً',
              ),
            ));
          }

          if (silentSource != null) {
            sources.add(AudioSource.uri(
              (silentSource as UriAudioSource).uri,
              tag: AyahPlaybackTag(
                surah: config.surah,
                ayah: config.endAyah,
                loopIndex: bLoop,
                totalLoops: config.blockRepeatCount,
                isSilence: true,
                phase: GoldenLoopPhase.phaseCConsolidation,
                phaseLabel: 'ردد المقطع مجمعاً بصوتك',
              ),
            ));
          }
        }
      } else {
        // Simple Single Verses Repetition (N times each)
        for (int a = config.startAyah; a <= config.endAyah; a++) {
          final primaryUrl = _formatUrl(config.reciterCdnPattern, config.surah, a);
          for (int loop = 1; loop <= config.singleRepeatCount; loop++) {
            sources.add(AudioSource.uri(
              Uri.parse(primaryUrl),
              tag: AyahPlaybackTag(
                surah: config.surah,
                ayah: a,
                loopIndex: loop,
                totalLoops: config.singleRepeatCount,
                isSilence: false,
                phase: GoldenLoopPhase.phaseAMastery,
                phaseLabel: 'تكرار الآية $a',
              ),
            ));

            if (silentSource != null) {
              sources.add(AudioSource.uri(
                (silentSource as UriAudioSource).uri,
                tag: AyahPlaybackTag(
                  surah: config.surah,
                  ayah: a,
                  loopIndex: loop,
                  totalLoops: config.singleRepeatCount,
                  isSilence: true,
                  phase: GoldenLoopPhase.phaseAMastery,
                  phaseLabel: 'مهلة الترديد للآية $a',
                ),
              ));
            }
          }
        }
      }

      final playlist = ConcatenatingAudioSource(
        useLazyPreparation: true,
        children: sources,
      );

      await _player.setAudioSource(playlist, preload: true);
      await _player.setSpeed(config.playbackSpeed);

      // CRITICAL: Prevent UI freeze by avoiding direct await on player.play()
      unawaited(_player.play());
    } catch (e) {
      if (kDebugMode) {
        print('AudioPlayerService error preparing session: $e');
      }
      _emitState(_currentState.copyWith(
        status: HifzPlaybackStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> setSpeed(double speed) async {
    try {
      await _player.setSpeed(speed);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating speed: $e');
      }
    }
  }

  Future<void> pause() async {
    _stopDelayTimer();
    await _player.pause();
    _emitState(_currentState.copyWith(status: HifzPlaybackStatus.paused));
  }

  Future<void> resume() async {
    unawaited(_player.play());
  }

  Future<void> stop() async {
    _stopDelayTimer();
    await _player.stop();
    _emitState(_currentState.copyWith(
      status: HifzPlaybackStatus.idle,
      isDelaying: false,
      phase: GoldenLoopPhase.idle,
      phaseLabel: '',
    ));
  }

  void completeActiveTest() {
    _emitState(_currentState.copyWith(
      status: HifzPlaybackStatus.completed,
      phase: GoldenLoopPhase.idle,
      phaseLabel: 'ما شاء الله! اكتمل الحفظ والتسميع بنجاح',
    ));
  }

  void dispose() {
    _stopDelayTimer();
    _sequenceSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _stateController.close();
    _player.dispose();
  }
}
