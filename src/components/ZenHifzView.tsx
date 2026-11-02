import React, { useState, useEffect, useRef, useCallback } from 'react';
import {
  Eye,
  EyeOff,
  Sparkles,
  Play,
  Pause,
  Square,
  ZoomIn,
  ZoomOut,
  ChevronRight,
  ChevronLeft,
  Mic,
  MicOff,
  Maximize2,
  Minimize2,
  CheckCircle2,
  Info,
  RotateCcw,
  Volume2,
  Award,
  Layers,
  ArrowRight,
  ShieldCheck,
} from 'lucide-react';
import { Ayah } from '../types/quran';
import {
  HifzSessionConfig,
  HifzPlaybackState,
  MaskingMode,
  GoldenLoopPhase,
} from '../types/hifz';
import { getSurahAyahs } from '../services/quranService';
import { SURAH_LIST } from '../data/surahList';
import { hifzAudioEngine } from '../services/hifzAudioEngine';

interface ZenHifzViewProps {
  sessionConfig: HifzSessionConfig;
  onUpdateConfig: (newConfig: HifzSessionConfig) => void;
  onOpenSetup: () => void;
  onOpenSurahPicker: () => void;
  isFocusModeActive: boolean;
  setIsFocusModeActive: (active: boolean) => void;
}

interface PhaseMeta {
  id: GoldenLoopPhase;
  letter: string;
  number: number;
  titleAr: string;
  titleEn: string;
  descriptionAr: string;
}

const GOLDEN_PHASES: PhaseMeta[] = [
  {
    id: 'phase_a_mastery',
    letter: 'أ',
    number: 1,
    titleAr: 'التثبيت الفردي',
    titleEn: 'Individual Mastery',
    descriptionAr: 'تكرار كل آية منفردة مع مهلة الترديد الذاتي النشط',
  },
  {
    id: 'phase_b_chain_link',
    letter: 'ب',
    number: 2,
    titleAr: 'الربط التراكمي',
    titleEn: 'Chain Linking',
    descriptionAr: 'ربط الآيات تصاعدياً (١←٢ ثم ١←٣) لتمتين الانتقالات',
  },
  {
    id: 'phase_c_consolidation',
    letter: 'جـ',
    number: 3,
    titleAr: 'الإحكام والدمج',
    titleEn: 'Consolidation',
    descriptionAr: 'تلاوة المقطع مجمعاً كاملاً لترسيخ السياق في الذاكرة',
  },
  {
    id: 'phase_d_active_test',
    letter: 'د',
    number: 4,
    titleAr: 'التسميع النشط',
    titleEn: 'Active Recall',
    descriptionAr: 'استرجاع ذاتي بدون صوت مع حجب النص (اللوح الرقمي)',
  },
];

export const ZenHifzView: React.FC<ZenHifzViewProps> = ({
  sessionConfig,
  onUpdateConfig,
  onOpenSetup,
  onOpenSurahPicker,
  isFocusModeActive,
  setIsFocusModeActive,
}) => {
  const [ayahs, setAyahs] = useState<Ayah[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [playbackState, setPlaybackState] = useState<HifzPlaybackState>({
    isActive: false,
    isPaused: false,
    isFocusMode: false,
    currentAyahNumber: sessionConfig.startAyah,
    currentLoopIndex: 0,
    totalLoopsForCurrentStage: 0,
    currentStageDescription: '',
    isSilencePause: false,
    silenceRemainingSeconds: 0,
    currentPhase: undefined,
    isTestingPhaseD: false,
  });

  // Tap-to-peek state (verses temporarily revealed during masking)
  const [peekedAyahs, setPeekedAyahs] = useState<Record<number, boolean>>({});
  const peekTimeoutsRef = useRef<Map<number, NodeJS.Timeout>>(new Map());

  // Self-recitation voice recording states for Phase D
  const [isRecording, setIsRecording] = useState<boolean>(false);
  const [recordingSeconds, setRecordingSeconds] = useState<number>(0);
  const [recordedAudioUrl, setRecordedAudioUrl] = useState<string | null>(null);
  const [showCelebration, setShowCelebration] = useState<boolean>(false);
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const audioChunksRef = useRef<Blob[]>([]);
  const recordingTimerRef = useRef<NodeJS.Timeout | null>(null);

  const currentSurahMeta =
    SURAH_LIST.find((s) => s.number === sessionConfig.surahNumber) || SURAH_LIST[0];

  // Clean up peek timers and recording on unmount
  useEffect(() => {
    return () => {
      peekTimeoutsRef.current.forEach((t) => clearTimeout(t));
      peekTimeoutsRef.current.clear();
      if (recordingTimerRef.current) clearInterval(recordingTimerRef.current);
      if (mediaRecorderRef.current && mediaRecorderRef.current.state === 'recording') {
        mediaRecorderRef.current.stop();
      }
    };
  }, []);

  // Load Ayahs according to Riwayah
  useEffect(() => {
    let isMounted = true;
    setLoading(true);
    getSurahAyahs(sessionConfig.surahNumber, sessionConfig.riwayah).then((data) => {
      if (isMounted) {
        setAyahs(data);
        setLoading(false);
      }
    });
    return () => {
      isMounted = false;
    };
  }, [sessionConfig.surahNumber, sessionConfig.riwayah]);

  // Connect Audio Engine Callbacks
  useEffect(() => {
    hifzAudioEngine.setCallbacks(
      (newState) => {
        setPlaybackState(newState);
        setIsFocusModeActive(newState.isFocusMode && newState.isActive);

        // When automatically entering Phase D, encourage active masking if visible
        if (newState.isTestingPhaseD && sessionConfig.maskingMode === 'visible') {
          onUpdateConfig({
            ...sessionConfig,
            maskingMode: 'blurred',
          });
        }
      },
      () => {
        setIsFocusModeActive(false);
      },
      (error) => {
        console.warn('Hifz audio engine error:', error);
      }
    );

    return () => {
      hifzAudioEngine.stopSession();
    };
  }, [setIsFocusModeActive, sessionConfig, onUpdateConfig]);

  // Target Ayahs
  const targetAyahs = ayahs.filter(
    (a) =>
      a.numberInSurah >= sessionConfig.startAyah &&
      a.numberInSurah <= sessionConfig.endAyah
  );

  // Masking Mode Switcher
  const handleSetMaskingMode = useCallback(
    (mode: MaskingMode) => {
      peekTimeoutsRef.current.forEach((t) => clearTimeout(t));
      peekTimeoutsRef.current.clear();
      setPeekedAyahs({});

      onUpdateConfig({
        ...sessionConfig,
        maskingMode: mode,
      });
    },
    [sessionConfig, onUpdateConfig]
  );

  const cycleMaskingMode = useCallback(() => {
    const modes: MaskingMode[] = ['visible', 'blurred', 'hidden'];
    const nextIndex = (modes.indexOf(sessionConfig.maskingMode) + 1) % modes.length;
    handleSetMaskingMode(modes[nextIndex]);
  }, [sessionConfig.maskingMode, handleSetMaskingMode]);

  // Tap-to-peek handler: triggers 2.5s temporary reveal
  const handleAyahTap = useCallback(
    (ayahNumber: number) => {
      if (sessionConfig.maskingMode === 'visible') return;

      const existingTimeout = peekTimeoutsRef.current.get(ayahNumber);
      if (existingTimeout) clearTimeout(existingTimeout);

      setPeekedAyahs((prev) => ({ ...prev, [ayahNumber]: true }));

      const timeout = setTimeout(() => {
        setPeekedAyahs((prev) => {
          const next = { ...prev };
          delete next[ayahNumber];
          return next;
        });
        peekTimeoutsRef.current.delete(ayahNumber);
      }, 2500);

      peekTimeoutsRef.current.set(ayahNumber, timeout);
    },
    [sessionConfig.maskingMode]
  );

  // Playback controls
  const handleStartPlayback = (phase?: GoldenLoopPhase) => {
    setShowCelebration(false);
    hifzAudioEngine.startSession(sessionConfig, phase);
    setIsFocusModeActive(true);
  };

  const handlePausePlayback = () => {
    hifzAudioEngine.pause();
  };

  const handleResumePlayback = () => {
    hifzAudioEngine.resume();
  };

  const handleStopPlayback = () => {
    hifzAudioEngine.stopSession();
    setIsFocusModeActive(false);
  };

  const handleJumpToPhase = (phase: GoldenLoopPhase) => {
    setShowCelebration(false);
    if (!playbackState.isActive) {
      handleStartPlayback(phase);
    } else {
      hifzAudioEngine.jumpToPhase(phase);
    }
  };

  const cyclePlaybackSpeed = useCallback(() => {
    const speeds = [0.75, 1.0, 1.25, 1.5];
    const currentRate = sessionConfig.playbackRate || 1.0;
    const nextIndex = (speeds.indexOf(currentRate) + 1) % speeds.length;
    const nextRate = speeds[nextIndex];

    hifzAudioEngine.setPlaybackRate(nextRate);
    onUpdateConfig({
      ...sessionConfig,
      playbackRate: nextRate,
    });
  }, [sessionConfig, onUpdateConfig]);

  // Font Size adjustments
  const handleFontSizeChange = (delta: number) => {
    const newSize = Math.max(22, Math.min(46, sessionConfig.fontSize + delta));
    onUpdateConfig({ ...sessionConfig, fontSize: newSize });
  };

  // Navigate to previous/next batch of verses
  const handleShiftRange = (direction: 'next' | 'prev') => {
    const span = sessionConfig.endAyah - sessionConfig.startAyah + 1;
    const max = currentSurahMeta.versesCount;

    if (direction === 'next') {
      const newStart = Math.min(max, sessionConfig.endAyah + 1);
      const newEnd = Math.min(max, newStart + span - 1);
      onUpdateConfig({ ...sessionConfig, startAyah: newStart, endAyah: newEnd });
    } else {
      const newEnd = Math.max(1, sessionConfig.startAyah - 1);
      const newStart = Math.max(1, newEnd - span + 1);
      onUpdateConfig({ ...sessionConfig, startAyah: newStart, endAyah: newEnd });
    }
  };

  // Phase D Audio Recording Handlers (Self-evaluation)
  const startRecording = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      audioChunksRef.current = [];
      const recorder = new MediaRecorder(stream);

      recorder.ondataavailable = (e) => {
        if (e.data && e.data.size > 0) {
          audioChunksRef.current.push(e.data);
        }
      };

      recorder.onstop = () => {
        const audioBlob = new Blob(audioChunksRef.current, { type: 'audio/webm' });
        const url = URL.createObjectURL(audioBlob);
        setRecordedAudioUrl(url);
        stream.getTracks().forEach((track) => track.stop());
      };

      recorder.start(250);
      mediaRecorderRef.current = recorder;
      setIsRecording(true);
      setRecordingSeconds(0);

      recordingTimerRef.current = setInterval(() => {
        setRecordingSeconds((prev) => prev + 1);
      }, 1000);
    } catch (err) {
      console.warn('Microphone permission not granted or unsupported:', err);
    }
  };

  const stopRecording = () => {
    if (mediaRecorderRef.current && mediaRecorderRef.current.state === 'recording') {
      mediaRecorderRef.current.stop();
    }
    setIsRecording(false);
    if (recordingTimerRef.current) {
      clearInterval(recordingTimerRef.current);
      recordingTimerRef.current = null;
    }
  };

  const handleCompleteActiveTest = (passed: boolean) => {
    if (passed) {
      setShowCelebration(true);
      hifzAudioEngine.completeActiveTest(true);
    } else {
      hifzAudioEngine.completeActiveTest(false);
    }
  };

  // Active phase determination
  const isGoldenLoopMode = sessionConfig.repetitionMode === 'golden_loop';
  const activePhase = playbackState.currentPhase || 'phase_a_mastery';
  const progressPercent = playbackState.phaseProgress?.overallProgressPercent || 0;

  return (
    <div
      dir="rtl"
      className="relative min-h-[calc(100vh-4rem)] flex flex-col justify-between pb-32 pt-3 px-3 sm:px-6 max-w-4xl mx-auto transition-all"
    >
      {/* Top Quick Control Bar */}
      {!isFocusModeActive && (
        <div className="flex flex-wrap items-center justify-between gap-2 py-2 border-b border-[#E8E2D7]/60 dark:border-[#222B27]/60 mb-4 text-xs text-[#6F7B75] dark:text-[#8D9F96]">
          {/* Verses Range Shift Navigation */}
          <div className="flex items-center gap-1.5">
            <button
              onClick={() => handleShiftRange('prev')}
              disabled={sessionConfig.startAyah <= 1}
              className="p-1.5 rounded-lg hover:bg-[#F2ECE1] dark:hover:bg-[#1E2521] disabled:opacity-30 transition-all flex items-center gap-1"
            >
              <ChevronRight className="w-4 h-4" />
              <span className="hidden sm:inline">المقطع السابق</span>
            </button>
            <span className="text-[#A2B0A8] dark:text-[#4F5F57]">•</span>
            <button
              onClick={() => handleShiftRange('next')}
              disabled={sessionConfig.endAyah >= currentSurahMeta.versesCount}
              className="p-1.5 rounded-lg hover:bg-[#F2ECE1] dark:hover:bg-[#1E2521] disabled:opacity-30 transition-all flex items-center gap-1"
            >
              <span className="hidden sm:inline">المقطع التالي</span>
              <ChevronLeft className="w-4 h-4" />
            </button>
          </div>

          <div className="flex items-center gap-2">
            {/* Font size stepper */}
            <div className="flex items-center bg-[#F2ECE1] dark:bg-[#1C2520] rounded-lg p-0.5 border border-[#E2D9CC] dark:border-[#28352E]">
              <button
                onClick={() => handleFontSizeChange(-2)}
                className="p-1 hover:bg-[#E2D9CC] dark:hover:bg-[#28352E] rounded-md transition-colors"
                title="تصغير الخط"
              >
                <ZoomOut className="w-3.5 h-3.5" />
              </button>
              <span className="px-1.5 font-mono text-[11px] font-bold">
                {sessionConfig.fontSize}
              </span>
              <button
                onClick={() => handleFontSizeChange(2)}
                className="p-1 hover:bg-[#E2D9CC] dark:hover:bg-[#28352E] rounded-md transition-colors"
                title="تكبير الخط"
              >
                <ZoomIn className="w-3.5 h-3.5" />
              </button>
            </div>

            {/* 3-Tier Masking Segmented Control */}
            <div className="flex items-center bg-[#F2ECE1] dark:bg-[#1C2520] rounded-xl p-0.5 border border-[#E2D9CC] dark:border-[#28352E]">
              <button
                onClick={() => handleSetMaskingMode('visible')}
                className={`px-2.5 py-1 rounded-lg text-xs font-semibold transition-all flex items-center gap-1 ${
                  sessionConfig.maskingMode === 'visible'
                    ? 'bg-[#4A6B5D] text-white shadow-xs'
                    : 'text-[#6F7B75] dark:text-[#8D9F96] hover:text-[#1E201D] dark:hover:text-[#E6D5B8]'
                }`}
                title="عرض النص القرآني كاملاً"
              >
                <Eye className="w-3.5 h-3.5" />
                <span>ظاهر</span>
              </button>

              <button
                onClick={() => handleSetMaskingMode('blurred')}
                className={`px-2.5 py-1 rounded-lg text-xs font-semibold transition-all flex items-center gap-1 ${
                  sessionConfig.maskingMode === 'blurred'
                    ? 'bg-[#4A6B5D] text-white shadow-xs'
                    : 'text-[#6F7B75] dark:text-[#8D9F96] hover:text-[#1E201D] dark:hover:text-[#E6D5B8]'
                }`}
                title="تمويه النص القرآني مع إمكانية النقر للكشف"
              >
                <EyeOff className="w-3.5 h-3.5" />
                <span>مموه</span>
              </button>

              <button
                onClick={() => handleSetMaskingMode('hidden')}
                className={`px-2.5 py-1 rounded-lg text-xs font-semibold transition-all flex items-center gap-1 ${
                  sessionConfig.maskingMode === 'hidden'
                    ? 'bg-[#4A6B5D] text-white shadow-xs'
                    : 'text-[#6F7B75] dark:text-[#8D9F96] hover:text-[#1E201D] dark:hover:text-[#E6D5B8]'
                }`}
                title="إخفاء النص تماماً بالنقاط مع التلصص بالنقر"
              >
                <span className="font-mono text-sm leading-none">•</span>
                <span>مخفي</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Surah Header */}
      <div className="text-center my-2 space-y-1">
        <h1 className="text-xl sm:text-2xl font-bold font-cairo text-[#1E201D] dark:text-[#E6D5B8]">
          سورة {currentSurahMeta.nameAr}
        </h1>
        <div className="flex flex-wrap items-center justify-center gap-1.5 text-xs text-[#7F8D87] dark:text-[#8D9F96] font-mono">
          <span>الآيات {sessionConfig.startAyah} - {sessionConfig.endAyah}</span>
          <span>•</span>
          <span className="px-2 py-0.5 rounded-full bg-[#4A6B5D]/10 dark:bg-[#7FA695]/15 text-[#4A6B5D] dark:text-[#7FA695] font-semibold text-[11px]">
            {sessionConfig.riwayah === 'hafs'
              ? 'مصحف حفص عن عاصم'
              : sessionConfig.riwayah === 'qalun'
              ? 'مصحف قالون عن نافع'
              : sessionConfig.riwayah === 'warsh'
              ? 'مصحف ورش عن نافع'
              : 'مصحف الدوري عن أبي عمرو'}
          </span>
          <span>•</span>
          <span className="px-2 py-0.5 rounded-full bg-amber-500/10 text-amber-700 dark:text-amber-300 font-semibold text-[11px] flex items-center gap-1">
            <Sparkles className="w-3 h-3" />
            <span>
              {isGoldenLoopMode
                ? 'الحلقة الذهبية المتقنة (٤ مراحل)'
                : sessionConfig.repetitionMode === 'combined_block'
                ? `تكرار مجمع (${sessionConfig.blockRepeatCount || 5}×)`
                : `تكرار فردي (${sessionConfig.singleRepeatCount}×)`}
            </span>
          </span>
        </div>

        {sessionConfig.surahNumber !== 1 &&
          sessionConfig.surahNumber !== 9 &&
          sessionConfig.startAyah === 1 && (
            <p className="font-amiri text-lg text-[#5A6861] dark:text-[#A7BAAE] pt-1">
              بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ
            </p>
          )}
      </div>

      {/* 4-PHASE GOLDEN LOOP PROGRESS STEPPER (VISUAL ENGINE) */}
      {isGoldenLoopMode && (
        <section aria-label="مراحل الحلقة الذهبية للحفظ" className="my-4">
          <div className="bg-[#FBF8F3] dark:bg-[#151D19] rounded-2xl p-3 sm:p-4 border border-[#E4DCCF] dark:border-[#26332C] shadow-xs transition-all">
            {/* Header info */}
            <div className="flex items-center justify-between gap-2 mb-3">
              <div className="flex items-center gap-1.5 text-xs font-bold text-[#1E201D] dark:text-[#E6D5B8]">
                <Layers className="w-4 h-4 text-[#4A6B5D] dark:text-[#7FA695]" />
                <span>محرك الحلقة الذهبية المتقنة (The Golden Loop)</span>
              </div>

              {playbackState.isActive && (
                <div className="flex items-center gap-2">
                  <span className="text-[11px] font-bold text-[#4A6B5D] dark:text-[#7FA695]">
                    {progressPercent}% إنجاز
                  </span>
                  <div className="w-16 sm:w-24 h-1.5 rounded-full bg-[#E8E2D7] dark:bg-[#202A25] overflow-hidden">
                    <div
                      className="h-full bg-[#4A6B5D] dark:bg-[#7FA695] transition-all duration-500 rounded-full"
                      style={{ width: `${progressPercent}%` }}
                    />
                  </div>
                </div>
              )}
            </div>

            {/* Stepper Cards */}
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-2 sm:gap-2.5">
              {GOLDEN_PHASES.map((p) => {
                const isCurrent = playbackState.isActive && activePhase === p.id;
                const isCompleted =
                  (p.number === 1 && Boolean(playbackState.phaseProgress?.phaseACompleted)) ||
                  (p.number === 2 && Boolean(playbackState.phaseProgress?.phaseBCompleted)) ||
                  (p.number === 3 && Boolean(playbackState.phaseProgress?.phaseCCompleted)) ||
                  (p.number === 4 && Boolean(playbackState.phaseProgress?.phaseDCompleted));

                return (
                  <button
                    key={p.id}
                    onClick={() => handleJumpToPhase(p.id)}
                    className={`relative text-right p-2.5 sm:p-3 rounded-xl border transition-all text-xs flex flex-col justify-between select-none ${
                      isCurrent
                        ? 'bg-[#4A6B5D]/10 dark:bg-[#7FA695]/15 border-[#4A6B5D] dark:border-[#7FA695] shadow-xs ring-1 ring-[#4A6B5D]/30'
                        : isCompleted
                        ? 'bg-emerald-500/5 dark:bg-emerald-500/10 border-emerald-500/40 hover:border-emerald-500'
                        : 'bg-[#F2ECE1]/60 dark:bg-[#1A231F] border-[#E2D9CC] dark:border-[#28352E] hover:border-[#C4B7A3]'
                    }`}
                    title={`انقر للانتقال مباشرة إلى: ${p.titleAr}`}
                  >
                    {/* Top Row: Letter badge & Status */}
                    <div className="flex items-center justify-between mb-1">
                      <span
                        className={`w-6 h-6 rounded-lg flex items-center justify-center font-bold text-xs ${
                          isCurrent
                            ? 'bg-[#4A6B5D] dark:bg-[#7FA695] text-white shadow-xs animate-pulse'
                            : isCompleted
                            ? 'bg-emerald-600 text-white'
                            : 'bg-[#E5DCD0] dark:bg-[#27322C] text-[#63726A] dark:text-[#8E9F97]'
                        }`}
                      >
                        {isCompleted ? <CheckCircle2 className="w-3.5 h-3.5" /> : p.letter}
                      </span>

                      {isCurrent ? (
                        <span className="text-[10px] font-bold text-[#4A6B5D] dark:text-[#7FA695] flex items-center gap-1">
                          <span className="w-1.5 h-1.5 rounded-full bg-[#4A6B5D] dark:bg-[#7FA695] animate-ping" />
                          <span>نشط</span>
                        </span>
                      ) : isCompleted ? (
                        <span className="text-[10px] font-semibold text-emerald-600 dark:text-emerald-400">
                          مكتمل
                        </span>
                      ) : (
                        <span className="text-[10px] text-[#8C9B93] dark:text-[#6F7F77]">
                          المرحلة {p.number}
                        </span>
                      )}
                    </div>

                    {/* Phase title & subtitle */}
                    <div>
                      <p className="font-bold text-[#1E201D] dark:text-[#E6D5B8] text-[13px] leading-tight">
                        {p.titleAr}
                      </p>
                      <p className="text-[10px] text-[#6F7B75] dark:text-[#8D9F96] mt-0.5 line-clamp-1">
                        {p.number === 1
                          ? `${sessionConfig.singleRepeatCount}× لكل آية`
                          : p.number === 2
                          ? `${sessionConfig.linkGroupRepeatCount || 2}× ربط تراكمي`
                          : p.number === 3
                          ? `${sessionConfig.blockRepeatCount || 4}× للمقطع كاملاً`
                          : 'استرجاع ذاتي'}
                      </p>
                    </div>

                    {/* Active phase cycle badge */}
                    {isCurrent && (
                      <div className="mt-2 pt-1 border-t border-[#4A6B5D]/20 dark:border-[#7FA695]/20 flex items-center justify-between text-[10px] font-bold text-[#4A6B5D] dark:text-[#7FA695]">
                        <span>دورة {playbackState.currentLoopIndex} من {playbackState.totalLoopsForCurrentStage}</span>
                        {playbackState.isSilencePause && (
                          <span className="text-amber-600 dark:text-amber-400 animate-pulse">
                            ترديد {playbackState.silenceRemainingSeconds}ث
                          </span>
                        )}
                      </div>
                    )}
                  </button>
                );
              })}
            </div>
          </div>
        </section>
      )}

      {/* PHASE D: ACTIVE RECALL TEST CONSOLE (DISPLAYED WHEN IN PHASE D) */}
      {(playbackState.isTestingPhaseD || activePhase === 'phase_d_active_test') && (
        <section aria-label="اختبار التسميع والاسترجاع النشط" className="my-4 animate-in fade-in duration-300">
          <div className="bg-gradient-to-br from-amber-500/10 via-[#FBF8F3] to-[#4A6B5D]/10 dark:from-amber-500/15 dark:via-[#141C18] dark:to-[#7FA695]/15 border-2 border-[#D4AF37]/50 rounded-2xl p-4 sm:p-6 shadow-md text-[#1E201D] dark:text-[#E6D5B8]">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-4 border-b border-[#E8E2D7] dark:border-[#222E27] pb-3">
              <div className="flex items-center gap-2.5">
                <div className="w-9 h-9 rounded-xl bg-amber-500/20 text-amber-700 dark:text-amber-300 flex items-center justify-center font-bold">
                  <Award className="w-5 h-5" />
                </div>
                <div>
                  <h2 className="font-bold text-sm sm:text-base leading-tight">
                    المرحلة (د): اختبار الاسترجاع النشط والتسميع الذاتي غيباً
                  </h2>
                  <p className="text-xs text-[#6F7B75] dark:text-[#8D9F96] mt-0.5">
                    وفق منهجية اللوح الشنقيطي: أوقفنا الصوت القرآني لتتلو المقطع الآن كاملاً من حفظك المتقن.
                  </p>
                </div>
              </div>

              {/* Masking tier selector inside test console */}
              <div className="flex items-center gap-1 bg-[#F2ECE1] dark:bg-[#1E2723] p-1 rounded-xl text-xs border border-[#E2D9CC] dark:border-[#2C3B34]">
                <button
                  onClick={() => handleSetMaskingMode('hidden')}
                  className={`px-2 py-1 rounded-lg font-bold transition-all ${
                    sessionConfig.maskingMode === 'hidden'
                      ? 'bg-[#4A6B5D] text-white'
                      : 'text-[#6F7B75] dark:text-[#8D9F96]'
                  }`}
                >
                  إخفاء كامل (نقاط)
                </button>
                <button
                  onClick={() => handleSetMaskingMode('blurred')}
                  className={`px-2 py-1 rounded-lg font-bold transition-all ${
                    sessionConfig.maskingMode === 'blurred'
                      ? 'bg-[#4A6B5D] text-white'
                      : 'text-[#6F7B75] dark:text-[#8D9F96]'
                  }`}
                >
                  تمويه ضبابي
                </button>
                <button
                  onClick={() => handleSetMaskingMode('visible')}
                  className={`px-2 py-1 rounded-lg font-bold transition-all ${
                    sessionConfig.maskingMode === 'visible'
                      ? 'bg-[#4A6B5D] text-white'
                      : 'text-[#6F7B75] dark:text-[#8D9F96]'
                  }`}
                >
                  كشف النص
                </button>
              </div>
            </div>

            {/* Voice recording for self-assessment */}
            <div className="bg-[#FAF6EE] dark:bg-[#18211D] rounded-xl p-3 border border-[#E6DEC $\d] dark:border-[#25322B] flex flex-wrap items-center justify-between gap-3 mb-4">
              <div className="flex items-center gap-2">
                <button
                  onClick={isRecording ? stopRecording : startRecording}
                  className={`flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-bold transition-all shadow-xs ${
                    isRecording
                      ? 'bg-rose-600 text-white animate-pulse'
                      : 'bg-[#4A6B5D] text-white hover:bg-[#3E5C4F]'
                  }`}
                >
                  {isRecording ? (
                    <>
                      <MicOff className="w-4 h-4" />
                      <span>إيقاف التسجيل ({recordingSeconds} ث)</span>
                    </>
                  ) : (
                    <>
                      <Mic className="w-4 h-4" />
                      <span>تسجيل صوتك للتسميع</span>
                    </>
                  )}
                </button>

                {isRecording && (
                  <span className="text-xs text-rose-600 dark:text-rose-400 font-mono animate-pulse">
                    جاري التقاط صوتك المبارك...
                  </span>
                )}
              </div>

              {recordedAudioUrl && !isRecording && (
                <div className="flex items-center gap-2">
                  <Volume2 className="w-4 h-4 text-[#4A6B5D] dark:text-[#7FA695]" />
                  <span className="text-xs font-medium">استمع لتسميعك:</span>
                  <audio src={recordedAudioUrl} controls className="h-8 max-w-[200px]" />
                </div>
              )}
            </div>

            {/* Test validation action buttons */}
            <div className="flex flex-wrap items-center justify-between gap-2 pt-2">
              <button
                onClick={() => handleCompleteActiveTest(true)}
                className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs sm:text-sm font-bold shadow-md transition-transform active:scale-95"
              >
                <CheckCircle2 className="w-4 h-4" />
                <span>أتممت التسميع بنجاح ١٠٠% (تأكيد الحفظ)</span>
              </button>

              <div className="flex items-center gap-1.5">
                <button
                  onClick={() => handleJumpToPhase('phase_c_consolidation')}
                  className="flex items-center gap-1 px-3 py-2 rounded-xl bg-[#F2ECE1] dark:bg-[#1E2723] hover:bg-[#EAE2D4] dark:hover:bg-[#28352F] text-xs font-semibold text-[#5A6861] dark:text-[#A7BAAE] transition-all border border-[#E2D9CC] dark:border-[#2C3B34]"
                  title="إعادة الاستماع للمقطع كاملاً"
                >
                  <RotateCcw className="w-3.5 h-3.5" />
                  <span>إعادة الدمج (المرحلة جـ)</span>
                </button>
                <button
                  onClick={() => handleJumpToPhase('phase_a_mastery')}
                  className="flex items-center gap-1 px-3 py-2 rounded-xl bg-[#F2ECE1] dark:bg-[#1E2723] hover:bg-[#EAE2D4] dark:hover:bg-[#28352F] text-xs font-semibold text-[#5A6861] dark:text-[#A7BAAE] transition-all border border-[#E2D9CC] dark:border-[#2C3B34]"
                  title="إعادة تثبيت الآيات آية بآية"
                >
                  <RotateCcw className="w-3.5 h-3.5" />
                  <span>إعادة التثبيت (المرحلة أ)</span>
                </button>
              </div>
            </div>
          </div>
        </section>
      )}

      {/* Celebration Banner upon passing test */}
      {showCelebration && (
        <section aria-label="تهنئة إتمام الحفظ" className="my-4 animate-in slide-in-from-top-4 duration-300">
          <div className="p-4 rounded-2xl bg-gradient-to-r from-emerald-600 to-teal-700 text-white shadow-lg flex items-center justify-between gap-3">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-white/20 flex items-center justify-center">
                <ShieldCheck className="w-6 h-6" />
              </div>
              <div>
                <p className="font-bold text-sm sm:text-base">
                  مبارك! تم إتقان حفظ الآيات ({sessionConfig.startAyah} - {sessionConfig.endAyah}) بالحلقة الذهبية
                </p>
                <p className="text-xs text-emerald-100">
                  تم التثبيت الفردي، والربط التراكمي، والإحكام المجمع، والتسميع الذاتي غيباً بنجاح.
                </p>
              </div>
            </div>
            <button
              onClick={() => handleShiftRange('next')}
              className="px-3.5 py-2 rounded-xl bg-white text-emerald-800 text-xs font-bold hover:bg-emerald-50 transition-all flex items-center gap-1 shrink-0"
            >
              <span>المقطع التالي</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </button>
          </div>
        </section>
      )}

      {/* Target Ayahs Mushaf Container */}
      <div className="my-auto py-2 space-y-4 sm:space-y-5">
        {loading ? (
          <div className="py-20 text-center text-sm text-[#7F8D87] dark:text-[#8D9F96] animate-pulse">
            جاري تحضير آيات الحفظ المباركة برسم المصحف العثماني...
          </div>
        ) : targetAyahs.length === 0 ? (
          <div className="py-20 text-center text-sm text-[#7F8D87] dark:text-[#8D9F96]">
            لا توجد آيات في هذا النطاق المختار.
          </div>
        ) : (
          targetAyahs.map((ayah) => {
            const isPlayingThisAyah =
              playbackState.isActive &&
              playbackState.currentAyahNumber === ayah.numberInSurah;
            const isMaskedHidden = sessionConfig.maskingMode === 'hidden';
            const isMaskedBlurred = sessionConfig.maskingMode === 'blurred';
            const isPeeked = Boolean(peekedAyahs[ayah.numberInSurah]);

            // Phase B Chain span membership
            const isInActiveChain =
              activePhase === 'phase_b_chain_link' &&
              Boolean(playbackState.phaseProgress?.activeVersesSpan?.includes(ayah.numberInSurah));

            // Revelation status
            const isFullyRevealed =
              sessionConfig.maskingMode === 'visible' || isPlayingThisAyah || isPeeked;

            return (
              <div
                key={ayah.numberInSurah}
                id={`zen-ayah-${ayah.numberInSurah}`}
                onClick={() => handleAyahTap(ayah.numberInSurah)}
                className={`relative p-5 sm:p-6 rounded-2xl transition-all duration-300 select-none border cursor-pointer ${
                  isPlayingThisAyah
                    ? 'bg-[#4A6B5D]/10 dark:bg-[#7FA695]/15 border-[#4A6B5D] dark:border-[#7FA695] shadow-xs'
                    : isPeeked
                    ? 'bg-emerald-500/10 dark:bg-emerald-500/15 border-emerald-500 shadow-sm'
                    : isInActiveChain
                    ? 'bg-amber-500/5 dark:bg-amber-500/10 border-amber-500/40'
                    : 'bg-[#FBF8F3] dark:bg-[#151C18]/60 border-transparent hover:border-[#E2D9CC] dark:hover:border-[#222E27]'
                } active:scale-[0.99]`}
              >
                {/* Header Row: Ayah Number + Phase Context */}
                <div className="flex items-center justify-between mb-3">
                  <div className="flex items-center gap-2">
                    <span
                      className={`inline-flex items-center justify-center w-7 h-7 rounded-full text-xs font-bold font-mono transition-colors ${
                        isPlayingThisAyah
                          ? 'bg-[#4A6B5D] text-white'
                          : isPeeked
                          ? 'bg-emerald-600 text-white'
                          : 'bg-[#F2ECE1] dark:bg-[#1E2722] text-[#5A6861] dark:text-[#A7BAAE]'
                      }`}
                    >
                      {ayah.numberInSurah}
                    </span>

                    {isPlayingThisAyah && (
                      <span className="text-[10px] font-bold text-[#4A6B5D] dark:text-[#7FA695] flex items-center gap-1">
                        <span className="w-2 h-2 rounded-full bg-[#4A6B5D] dark:bg-[#7FA695] animate-ping" />
                        <span>يتلى الآن</span>
                      </span>
                    )}

                    {isInActiveChain && !isPlayingThisAyah && (
                      <span className="text-[10px] font-bold text-amber-700 dark:text-amber-400 bg-amber-500/10 px-2 py-0.5 rounded-md">
                        سلسلة الربط التراكمي
                      </span>
                    )}
                  </div>

                  {/* Tap-to-peek feedback tag */}
                  {sessionConfig.maskingMode !== 'visible' && (
                    <div>
                      {isPeeked ? (
                        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[10px] font-bold bg-emerald-600 text-white animate-pulse">
                          <CheckCircle2 className="w-3 h-3" />
                          <span>كشف مؤقت (2.5ث)</span>
                        </span>
                      ) : !isPlayingThisAyah ? (
                        <span className="text-[10px] text-[#8C9B93] dark:text-[#6E8077] hover:text-[#4A6B5D] dark:hover:text-[#7FA695] transition-colors">
                          انقر للكشف
                        </span>
                      ) : null}
                    </div>
                  )}
                </div>

                {/* Arabic Quranic Verse Content */}
                <div
                  style={{
                    fontSize: `${sessionConfig.fontSize}px`,
                    lineHeight: '2.1',
                  }}
                  className="font-amiri text-right transition-all duration-300"
                >
                  {isMaskedHidden && !isFullyRevealed ? (
                    <div className="tracking-widest text-[#8F9E96] dark:text-[#5B6D64] select-none py-3 text-center text-xl sm:text-2xl">
                      ••••••••••••••••••••••••••••••••••••
                    </div>
                  ) : (
                    <span
                      className={`transition-all duration-300 inline-block w-full ${
                        isPlayingThisAyah
                          ? 'text-[#1E201D] dark:text-[#F3E7D3] font-semibold'
                          : isPeeked
                          ? 'text-emerald-900 dark:text-emerald-200 font-medium'
                          : 'text-[#2D332F] dark:text-[#E6D5B8]'
                      } ${
                        isMaskedBlurred && !isFullyRevealed
                          ? 'filter blur-[8px] opacity-70 select-none'
                          : 'filter-none opacity-100'
                      }`}
                    >
                      {ayah.textUthmani}
                    </span>
                  )}
                </div>
              </div>
            );
          })
        )}
      </div>

      {/* Floating Translucent Zen Bottom Pill */}
      <div className="fixed bottom-6 left-3 right-3 z-40 max-w-xl mx-auto">
        <div className="backdrop-blur-md bg-[#FBF8F3]/95 dark:bg-[#151B18]/95 border border-[#4A6B5D]/30 dark:border-[#7FA695]/30 rounded-2xl p-3 shadow-xl flex items-center justify-between gap-3 text-[#1E201D] dark:text-[#E6D5B8]">
          {/* Status & Loop Counter */}
          <div className="flex-1 min-w-0 pr-1">
            {playbackState.isActive ? (
              <div className="space-y-0.5">
                <p className="text-xs font-bold text-[#4A6B5D] dark:text-[#7FA695] truncate">
                  {playbackState.currentStageDescription || 'جلسة التكرار جارية'}
                </p>
                {playbackState.isSilencePause ? (
                  <p className="text-[11px] font-medium text-amber-600 dark:text-amber-400 flex items-center gap-1 animate-pulse">
                    <Mic className="w-3 h-3" />
                    <span>ردد بصوتك الآن ({playbackState.silenceRemainingSeconds} ث)</span>
                  </p>
                ) : (
                  <p className="text-[10px] text-[#76857E] dark:text-[#8D9F96]">
                    استمع بخشوع وأنصت لتتقن مخارج الحروف
                  </p>
                )}
              </div>
            ) : (
              <div>
                <p className="text-xs font-bold truncate">
                  سورة {currentSurahMeta.nameAr} ({sessionConfig.startAyah}-{sessionConfig.endAyah})
                </p>
                <p className="text-[10px] text-[#76857E] dark:text-[#8D9F96]">
                  {isGoldenLoopMode ? 'محرك الحلقة الذهبية جاهز' : 'جاهز للتكرار'} •{' '}
                  {sessionConfig.maskingMode === 'visible'
                    ? 'ظاهر'
                    : sessionConfig.maskingMode === 'blurred'
                    ? 'مموه'
                    : 'مخفي'}
                </p>
              </div>
            )}
          </div>

          {/* Right Action Icons */}
          <div className="flex items-center gap-1.5 shrink-0">
            {/* 3-Tier Eye toggle button */}
            <button
              onClick={cycleMaskingMode}
              className={`p-2 rounded-xl transition-all relative ${
                sessionConfig.maskingMode === 'visible'
                  ? 'bg-[#F2ECE1] dark:bg-[#1F2924] text-[#4A6B5D] dark:text-[#7FA695]'
                  : sessionConfig.maskingMode === 'blurred'
                  ? 'bg-amber-100 dark:bg-amber-950/40 text-amber-600 dark:text-amber-400'
                  : 'bg-rose-100 dark:bg-rose-950/40 text-rose-600 dark:text-rose-400'
              }`}
              title={`وضع الحجب: ${
                sessionConfig.maskingMode === 'visible'
                  ? 'ظاهر (انقر للتبديل)'
                  : sessionConfig.maskingMode === 'blurred'
                  ? 'مموه (انقر للتبديل)'
                  : 'مخفي (انقر للتبديل)'
              }`}
            >
              {sessionConfig.maskingMode === 'visible' ? (
                <Eye className="w-4 h-4" />
              ) : sessionConfig.maskingMode === 'blurred' ? (
                <EyeOff className="w-4 h-4" />
              ) : (
                <EyeOff className="w-4 h-4 text-rose-500" />
              )}
            </button>

            {/* Voice Playback Speed Button */}
            <button
              onClick={cyclePlaybackSpeed}
              className="px-2 py-1.5 rounded-xl text-xs font-mono font-bold bg-[#F2ECE1] dark:bg-[#1F2924] text-[#4A6B5D] dark:text-[#7FA695] border border-[#E2D9CC] dark:border-[#2A3730] hover:bg-[#E5DCD0] dark:hover:bg-[#28362F] transition-all flex items-center justify-center min-w-[38px]"
              title={`سرعة الصوت الحالية: ${sessionConfig.playbackRate || 1.0}×`}
            >
              {sessionConfig.playbackRate || 1.0}×
            </button>

            {/* Play / Pause / Stop buttons */}
            {playbackState.isActive ? (
              <>
                <button
                  onClick={playbackState.isPaused ? handleResumePlayback : handlePausePlayback}
                  className="p-2 rounded-xl bg-[#4A6B5D] text-white hover:bg-[#3D5A4E] transition-transform active:scale-95"
                  title={playbackState.isPaused ? 'استئناف' : 'إيقاف مؤقت'}
                >
                  {playbackState.isPaused ? (
                    <Play className="w-4 h-4 fill-current" />
                  ) : (
                    <Pause className="w-4 h-4 fill-current" />
                  )}
                </button>
                <button
                  onClick={handleStopPlayback}
                  className="p-2 rounded-xl bg-[#F2ECE1] dark:bg-[#1F2924] text-rose-500 hover:bg-rose-100 dark:hover:bg-rose-950/40 transition-colors"
                  title="إنهاء الجلسة والخروج من التركيز"
                >
                  <Square className="w-4 h-4 fill-current" />
                </button>
              </>
            ) : (
              <button
                onClick={() => handleStartPlayback()}
                className="flex items-center gap-1.5 px-3 py-2 rounded-xl bg-[#4A6B5D] text-white text-xs font-bold hover:bg-[#3D5A4E] shadow-sm transition-transform active:scale-95"
              >
                <Play className="w-4 h-4 fill-current" />
                <span>بدء الحلقة</span>
              </button>
            )}

            {/* Focus mode toggle */}
            <button
              onClick={() => setIsFocusModeActive(!isFocusModeActive)}
              className="p-2 rounded-xl bg-[#F2ECE1] dark:bg-[#1F2924] text-[#76857E] dark:text-[#8D9F96] hover:bg-[#E5DCD0] dark:hover:bg-[#28362F] transition-colors"
              title={isFocusModeActive ? 'إلغاء وضع ملء الشاشة' : 'تفعيل التركيز الكامل'}
            >
              {isFocusModeActive ? (
                <Minimize2 className="w-4 h-4" />
              ) : (
                <Maximize2 className="w-4 h-4" />
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
