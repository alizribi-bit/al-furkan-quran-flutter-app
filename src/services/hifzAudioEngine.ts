import { HifzSessionConfig, HifzPlaybackState, GoldenLoopPhase } from '../types/hifz';
import { HIFZ_RECITERS, buildAudioUrl, getFallbackAudioUrl } from '../data/hifzReciters';

export type HifzStateCallback = (state: HifzPlaybackState) => void;
export type HifzCompleteCallback = () => void;
export type HifzErrorCallback = (error: string) => void;

export interface PlaylistItem {
  surah: number;
  ayah: number;
  type: 'single' | 'link' | 'block';
  phase: GoldenLoopPhase;
  loopIndex: number;
  totalLoops: number;
  description: string;
  isEndOfPassage: boolean;
  activeSpan?: number[];
}

export class HifzAudioEngine {
  private audio: HTMLAudioElement | null = null;
  private config: HifzSessionConfig | null = null;
  private isRunning: boolean = false;
  private isPaused: boolean = false;
  private isTestingPhaseD: boolean = false;
  private playlist: PlaylistItem[] = [];
  private currentIndex: number = 0;
  private silenceTimer: ReturnType<typeof setInterval> | null = null;
  private onStateChange: HifzStateCallback | null = null;
  private onComplete: HifzCompleteCallback | null = null;
  private onError: HifzErrorCallback | null = null;
  private isFallbackAttempted: boolean = false;

  constructor() {
    if (typeof window !== 'undefined') {
      this.initAudioElement();
    }
  }

  private initAudioElement() {
    if (!this.audio) {
      this.audio = new Audio();
    }
    this.audio.preload = 'auto';
    this.audio.onended = () => this.handleAudioEnded();
    this.audio.onerror = (e) => this.handleAudioError(e);
  }

  private resetAudioElement() {
    if (!this.audio) return;
    this.audio.onended = null;
    this.audio.onerror = null;
    this.audio.pause();
    this.audio.currentTime = 0;
    this.audio.removeAttribute('src');
    this.audio.load();

    this.audio.onended = () => this.handleAudioEnded();
    this.audio.onerror = (e) => this.handleAudioError(e);
  }

  public setCallbacks(
    onStateChange: HifzStateCallback,
    onComplete: HifzCompleteCallback,
    onError: HifzErrorCallback
  ) {
    this.onStateChange = onStateChange;
    this.onComplete = onComplete;
    this.onError = onError;
  }

  public startSession(config: HifzSessionConfig, startAtPhase?: GoldenLoopPhase) {
    this.stopSession();
    this.config = config;
    this.isRunning = true;
    this.isPaused = false;
    this.isFallbackAttempted = false;
    this.isTestingPhaseD = false;
    this.buildPlaylist();

    if (startAtPhase === 'phase_d_active_test') {
      this.enterPhaseD();
      return;
    }

    if (this.playlist.length === 0) {
      this.onError?.('قائمة التكرار فارغة');
      return;
    }

    if (startAtPhase) {
      const targetIdx = this.playlist.findIndex((item) => item.phase === startAtPhase);
      this.currentIndex = targetIdx !== -1 ? targetIdx : 0;
    } else {
      this.currentIndex = 0;
    }

    this.playCurrentItem();
  }

  public jumpToPhase(phase: GoldenLoopPhase) {
    if (!this.isRunning && this.config) {
      this.startSession(this.config, phase);
      return;
    }
    if (!this.config) return;

    if (phase === 'phase_d_active_test') {
      this.enterPhaseD();
      return;
    }

    this.isTestingPhaseD = false;
    if (this.silenceTimer) {
      clearInterval(this.silenceTimer);
      this.silenceTimer = null;
    }

    const targetIdx = this.playlist.findIndex((item) => item.phase === phase);
    if (targetIdx !== -1) {
      this.currentIndex = targetIdx;
      this.playCurrentItem();
    }
  }

  public enterPhaseD() {
    if (!this.config) return;
    this.resetAudioElement();
    if (this.silenceTimer) {
      clearInterval(this.silenceTimer);
      this.silenceTimer = null;
    }
    this.isTestingPhaseD = true;

    this.onStateChange?.({
      isActive: true,
      isPaused: false,
      isFocusMode: true,
      currentAyahNumber: this.config.startAyah,
      currentLoopIndex: 1,
      totalLoopsForCurrentStage: 1,
      currentStageDescription: 'المرحلة (د): اختبار الاسترجاع النشط والتسميع الذاتي غيباً',
      isSilencePause: false,
      silenceRemainingSeconds: 0,
      currentPhase: 'phase_d_active_test',
      isTestingPhaseD: true,
      phaseProgress: {
        phaseACompleted: true,
        phaseBCompleted: true,
        phaseCCompleted: true,
        phaseDCompleted: false,
        currentPhaseNumber: 4,
        overallProgressPercent: 95,
      },
    });
  }

  public completeActiveTest(passed: boolean) {
    if (passed) {
      this.isRunning = false;
      this.isTestingPhaseD = false;
      this.stopSession();
      this.onComplete?.();
    } else {
      // Re-consolidate passage starting from Phase C
      this.jumpToPhase('phase_c_consolidation');
    }
  }

  public pause() {
    if (!this.isRunning || this.isPaused) return;
    this.isPaused = true;
    if (this.audio) {
      this.audio.pause();
    }
    if (this.silenceTimer) {
      clearInterval(this.silenceTimer);
      this.silenceTimer = null;
    }
    this.emitState(false, 0);
  }

  public resume() {
    if (!this.isRunning || !this.isPaused) return;
    this.isPaused = false;
    if (this.audio && this.audio.getAttribute('src')) {
      const p = this.audio.play();
      if (p !== undefined) {
        p.catch((err) => {
          if (err?.name === 'AbortError') return;
          console.warn('Resume notice:', err);
        });
      }
    } else {
      this.playCurrentItem();
    }
    this.emitState(false, 0);
  }

  public setPlaybackRate(rate: number) {
    if (this.config) {
      this.config.playbackRate = rate;
    }
    if (this.audio) {
      this.audio.playbackRate = rate;
      this.audio.defaultPlaybackRate = rate;
    }
  }

  public stopSession() {
    this.isRunning = false;
    this.isPaused = false;
    this.isTestingPhaseD = false;
    this.isFallbackAttempted = false;
    this.resetAudioElement();

    if (this.silenceTimer) {
      clearInterval(this.silenceTimer);
      this.silenceTimer = null;
    }
    this.playlist = [];
    this.currentIndex = 0;

    this.onStateChange?.({
      isActive: false,
      isPaused: false,
      isFocusMode: false,
      currentAyahNumber: 1,
      currentLoopIndex: 0,
      totalLoopsForCurrentStage: 0,
      currentStageDescription: '',
      isSilencePause: false,
      silenceRemainingSeconds: 0,
      currentPhase: undefined,
      isTestingPhaseD: false,
    });
  }

  private buildPlaylist() {
    if (!this.config) return;
    const {
      surahNumber,
      startAyah,
      endAyah,
      repetitionMode,
      blockRepeatCount,
      singleRepeatCount,
      linkGroupSize,
      linkGroupRepeatCount,
    } = this.config;

    this.playlist = [];
    const verses: number[] = [];
    for (let a = startAyah; a <= endAyah; a++) {
      verses.push(a);
    }
    if (verses.length === 0) return;

    // Mode 1: The Golden Loop (Phase A Mastery -> Phase B Chain Link -> Phase C Consolidation -> Phase D Active Test)
    if (repetitionMode === 'golden_loop') {
      const singleLoops = Math.max(1, singleRepeatCount || 5);
      const chainLoops = Math.max(1, linkGroupRepeatCount || 2);
      const blockLoops = Math.max(1, blockRepeatCount || 3);

      // Phase A: Individual Verse Mastery (التثبيت الفردي)
      for (const v of verses) {
        for (let r = 1; r <= singleLoops; r++) {
          this.playlist.push({
            surah: surahNumber,
            ayah: v,
            type: 'single',
            phase: 'phase_a_mastery',
            loopIndex: r,
            totalLoops: singleLoops,
            description: `المرحلة (أ): إتقان الآية ${v} • تكرار ${r} من ${singleLoops}`,
            isEndOfPassage: true,
            activeSpan: [v],
          });
        }
      }

      // Phase B: Cumulative Chain Linking (الربط التراكمي العثماني)
      if (verses.length > 1) {
        for (let endIdx = 1; endIdx < verses.length; endIdx++) {
          const chainVerses = verses.slice(0, endIdx + 1);
          const chainLabel = `${chainVerses[0]} إلى ${chainVerses[chainVerses.length - 1]}`;

          for (let lr = 1; lr <= chainLoops; lr++) {
            chainVerses.forEach((cv, cIdx) => {
              const isEndOfChain = cIdx === chainVerses.length - 1;
              this.playlist.push({
                surah: surahNumber,
                ayah: cv,
                type: 'link',
                phase: 'phase_b_chain_link',
                loopIndex: lr,
                totalLoops: chainLoops,
                description: `المرحلة (ب): الربط التراكمي (${chainLabel}) • دورة ${lr} من ${chainLoops} • آية ${cv}`,
                isEndOfPassage: isEndOfChain,
                activeSpan: chainVerses,
              });
            });
          }
        }
      }

      // Phase C: Full Block Consolidation (تثبيت المقطع كاملاً مجمعاً)
      const blockLabel = `${startAyah}-${endAyah}`;
      for (let br = 1; br <= blockLoops; br++) {
        verses.forEach((bv, bIdx) => {
          const isEndOfBlock = bIdx === verses.length - 1;
          this.playlist.push({
            surah: surahNumber,
            ayah: bv,
            type: 'block',
            phase: 'phase_c_consolidation',
            loopIndex: br,
            totalLoops: blockLoops,
            description: `المرحلة (جـ): تثبيت المقطع مجمعاً (${blockLabel}) • دورة ${br} من ${blockLoops} • آية ${bv}`,
            isEndOfPassage: isEndOfBlock,
            activeSpan: verses,
          });
        });
      }
    } else if (repetitionMode === 'combined_block') {
      const loops = Math.max(1, blockRepeatCount || singleRepeatCount || 5);
      const blockLabel = `${startAyah}-${endAyah}`;

      for (let r = 1; r <= loops; r++) {
        verses.forEach((v, idx) => {
          const isEndOfBlock = idx === verses.length - 1;
          this.playlist.push({
            surah: surahNumber,
            ayah: v,
            type: 'block',
            phase: 'phase_c_consolidation',
            loopIndex: r,
            totalLoops: loops,
            description: `المقطع المجمع (${blockLabel}) • دورة ${r} من ${loops} • آية ${v}`,
            isEndOfPassage: isEndOfBlock,
            activeSpan: verses,
          });
        });
      }
    } else {
      // Mode 3: Simple Verse-by-Verse
      for (const v of verses) {
        for (let r = 1; r <= singleRepeatCount; r++) {
          this.playlist.push({
            surah: surahNumber,
            ayah: v,
            type: 'single',
            phase: 'phase_a_mastery',
            loopIndex: r,
            totalLoops: singleRepeatCount,
            description: `آية ${v} • تكرار ${r} من ${singleRepeatCount}`,
            isEndOfPassage: true,
            activeSpan: [v],
          });
        }
      }

      if (verses.length > 1 && linkGroupRepeatCount > 0) {
        const gSize = Math.max(2, linkGroupSize);
        for (let i = 0; i < verses.length; i += gSize) {
          const group = verses.slice(i, i + gSize);
          if (group.length > 1) {
            const groupLabel = `${group[0]} - ${group[group.length - 1]}`;
            for (let lr = 1; lr <= linkGroupRepeatCount; lr++) {
              group.forEach((gv, gIdx) => {
                const isEndOfGroup = gIdx === group.length - 1;
                this.playlist.push({
                  surah: surahNumber,
                  ayah: gv,
                  type: 'link',
                  phase: 'phase_b_chain_link',
                  loopIndex: lr,
                  totalLoops: linkGroupRepeatCount,
                  description: `ربط الآيات (${groupLabel}) • دورة ${lr} من ${linkGroupRepeatCount} • آية ${gv}`,
                  isEndOfPassage: isEndOfGroup,
                  activeSpan: group,
                });
              });
            }
          }
        }
      }
    }
  }

  private playCurrentItem(isFallback: boolean = false) {
    if (!this.isRunning || !this.config) return;
    if (this.currentIndex >= this.playlist.length) {
      if (this.config.repetitionMode === 'golden_loop' && !this.isTestingPhaseD) {
        this.enterPhaseD();
        return;
      }
      this.isRunning = false;
      this.stopSession();
      this.onComplete?.();
      return;
    }

    const item = this.playlist[this.currentIndex];
    const reciter =
      HIFZ_RECITERS.find((r) => r.id === this.config?.reciterId) || HIFZ_RECITERS[0];

    const audioUrl = isFallback
      ? getFallbackAudioUrl(item.surah, item.ayah)
      : buildAudioUrl(reciter, item.surah, item.ayah);

    if (this.audio) {
      this.audio.src = audioUrl;
      const rate = this.config?.playbackRate || 1.0;
      this.audio.playbackRate = rate;
      this.audio.defaultPlaybackRate = rate;
      const playPromise = this.audio.play();

      if (playPromise !== undefined) {
        playPromise
          .then(() => {
            if (this.isRunning) {
              this.emitState(false, 0);
            }
          })
          .catch((err) => {
            if (err?.name === 'AbortError') return;
            console.warn('Playback notice:', err?.message || err);

            if (!isFallback) {
              this.isFallbackAttempted = true;
              this.playCurrentItem(true);
            } else {
              this.handleAudioEnded();
            }
          });
      }
    }
  }

  private handleAudioEnded() {
    if (!this.isRunning || !this.config) return;
    this.isFallbackAttempted = false;

    const currentItem = this.playlist[this.currentIndex];
    const delay = this.config.pauseDelaySeconds;

    // Apply recitation pause only if at the end of the passage/block
    if (currentItem?.isEndOfPassage && delay > 0) {
      this.startSilenceCountdown(delay, () => {
        this.currentIndex++;
        this.playCurrentItem();
      });
    } else {
      this.currentIndex++;
      this.playCurrentItem();
    }
  }

  private startSilenceCountdown(seconds: number, onDone: () => void) {
    let remaining = seconds;
    this.emitState(true, remaining);

    if (this.silenceTimer) {
      clearInterval(this.silenceTimer);
    }

    this.silenceTimer = setInterval(() => {
      if (this.isPaused) return;
      remaining -= 1;
      if (remaining <= 0) {
        if (this.silenceTimer) {
          clearInterval(this.silenceTimer);
          this.silenceTimer = null;
        }
        this.emitState(false, 0);
        onDone();
      } else {
        this.emitState(true, remaining);
      }
    }, 1000);
  }

  private handleAudioError(e: string | Event) {
    if (!this.isRunning || !this.audio || !this.audio.getAttribute('src')) {
      return;
    }

    if (this.audio.error && this.audio.error.code === 1) {
      return;
    }

    console.warn('Audio notice:', e);

    if (!this.isFallbackAttempted && this.config) {
      this.isFallbackAttempted = true;
      this.playCurrentItem(true);
      return;
    }

    setTimeout(() => {
      if (this.isRunning) {
        this.currentIndex++;
        this.isFallbackAttempted = false;
        this.playCurrentItem();
      }
    }, 1000);
  }

  private emitState(isSilence: boolean, silenceRemaining: number) {
    if (!this.isRunning || !this.config) return;

    if (this.isTestingPhaseD) {
      this.onStateChange?.({
        isActive: true,
        isPaused: this.isPaused,
        isFocusMode: true,
        currentAyahNumber: this.config.startAyah,
        currentLoopIndex: 1,
        totalLoopsForCurrentStage: 1,
        currentStageDescription: 'المرحلة (د): اختبار الاسترجاع النشط والتسميع الذاتي غيباً',
        isSilencePause: false,
        silenceRemainingSeconds: 0,
        currentPhase: 'phase_d_active_test',
        isTestingPhaseD: true,
        phaseProgress: {
          phaseACompleted: true,
          phaseBCompleted: true,
          phaseCCompleted: true,
          phaseDCompleted: false,
          currentPhaseNumber: 4,
          overallProgressPercent: 95,
        },
      });
      return;
    }

    const currentItem = this.playlist[this.currentIndex];
    if (!currentItem) return;

    const isGolden = this.config.repetitionMode === 'golden_loop';
    let currentPhaseNumber = 1;
    if (currentItem.phase === 'phase_b_chain_link') currentPhaseNumber = 2;
    else if (currentItem.phase === 'phase_c_consolidation') currentPhaseNumber = 3;
    else if (currentItem.phase === 'phase_d_active_test') currentPhaseNumber = 4;

    const phaseACompleted = currentPhaseNumber > 1;
    const phaseBCompleted = currentPhaseNumber > 2;
    const phaseCCompleted = currentPhaseNumber > 3;

    const totalSteps = this.playlist.length + (isGolden ? 1 : 0);
    const overallProgressPercent = Math.min(
      95,
      Math.max(5, Math.round(((this.currentIndex + 1) / totalSteps) * 100))
    );

    this.onStateChange?.({
      isActive: true,
      isPaused: this.isPaused,
      isFocusMode: true,
      currentAyahNumber: currentItem.ayah,
      currentLoopIndex: currentItem.loopIndex,
      totalLoopsForCurrentStage: currentItem.totalLoops,
      currentStageDescription: currentItem.description,
      isSilencePause: isSilence,
      silenceRemainingSeconds: silenceRemaining,
      currentPhase: currentItem.phase,
      isTestingPhaseD: false,
      phaseProgress: {
        phaseACompleted,
        phaseBCompleted,
        phaseCCompleted,
        phaseDCompleted: false,
        currentPhaseNumber,
        activeVersesSpan: currentItem.activeSpan,
        overallProgressPercent,
      },
    });
  }
}

export const hifzAudioEngine = new HifzAudioEngine();
