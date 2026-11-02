export type Riwayah = 'hafs' | 'qalun' | 'warsh' | 'duri';
export type MaskingMode = 'visible' | 'blurred' | 'hidden';
export type RepetitionMode = 'golden_loop' | 'combined_block' | 'verse_by_verse';
export type GoldenLoopPhase =
  | 'phase_a_mastery'
  | 'phase_b_chain_link'
  | 'phase_c_consolidation'
  | 'phase_d_active_test';

export interface HifzReciter {
  id: string;
  nameAr: string;
  nameEn: string;
  riwayah: Riwayah;
  style: string;
  cdnPattern: string; // URL template or subfolder
  isFullSurahSliced?: boolean;
  timingUrl?: string;
}

export interface HifzSessionConfig {
  surahNumber: number;
  startAyah: number;
  endAyah: number;
  repetitionMode: RepetitionMode; // 'verse_by_verse' | 'combined_block'
  blockRepeatCount: number;       // Number of times to loop the entire combined block
  singleRepeatCount: number; // N
  linkGroupSize: number;     // G
  linkGroupRepeatCount: number; // M
  pauseDelaySeconds: number; // X
  riwayah: Riwayah;
  reciterId: string;
  maskingMode: MaskingMode;
  fontSize: number;
  playbackRate: number; // 0.75, 1.0, 1.25, 1.5
}

export interface HifzPlaybackState {
  isActive: boolean;
  isPaused: boolean;
  isFocusMode: boolean; // Auto-hides UI navigation
  currentAyahNumber: number;
  currentLoopIndex: number;
  totalLoopsForCurrentStage: number;
  currentStageDescription: string; // e.g. "المرحلة (أ): إتقان الآية 1 • تكرار 2 من 5"
  isSilencePause: boolean;
  silenceRemainingSeconds: number;
  currentPhase?: GoldenLoopPhase;
  isTestingPhaseD?: boolean;
  phaseProgress?: {
    phaseACompleted: boolean;
    phaseBCompleted: boolean;
    phaseCCompleted: boolean;
    phaseDCompleted: boolean;
    currentPhaseNumber: number; // 1: A, 2: B, 3: C, 4: D
    activeVersesSpan?: number[]; // e.g. [1, 2, 3] for Phase B chaining or [1, 2, 3, 4] for Phase C
    overallProgressPercent: number; // 0 to 100
  };
}

export interface HalaqaParticipant {
  id: string;
  name: string;
  isSpeaking: boolean;
  isMuted: boolean;
  isCurrentTurn: boolean;
}

export interface HalaqaRoomState {
  roomId: string;
  isConnected: boolean;
  isAudioMuted: boolean;
  activeSurah: number;
  activeStartAyah: number;
  activeEndAyah: number;
  activeRiwayah: Riwayah;
  currentTurnSpeakerId: string;
  participants: HalaqaParticipant[];
}

export interface PrayerAlarmItem {
  id: string;
  prayerNameAr: string;
  prayerNameEn: string;
  time: string;
  timestamp: Date;
  isAlarmEnabled: boolean;
  targetVersesDescription: string;
  escalationIds: number[]; // 101, 102, 103, 104
}
