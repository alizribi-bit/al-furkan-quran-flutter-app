import { HifzReciter, Riwayah } from '../types/hifz';

export interface VerifiedReciter extends HifzReciter {
  tempo: 'slow' | 'medium' | 'fast';
  bitrate?: number;
  recommendedForHifz: boolean;
  pedagogicalNote?: string;
}

export const HIFZ_RECITERS: VerifiedReciter[] = [
  // =========================================================================
  // 1. HAFS 'AN 'ASIM (حفص عن عاصم)
  // =========================================================================
  {
    id: 'husary_muallim',
    nameAr: 'محمود خليل الحصري (المعلم)',
    nameEn: 'Mahmoud Khalil Al-Husary (Teacher)',
    riwayah: 'hafs',
    style: 'معلم مع الوقف المتقن',
    tempo: 'slow',
    bitrate: 128,
    cdnPattern: 'https://everyayah.com/data/Husary_Muallim_128kbps/{surah:03d}{ayah:03d}.mp3',
    recommendedForHifz: true,
    pedagogicalNote: 'المعيار الذهبي للتحفيظ وضبط مخارج الحروف وأحكام الوقف والابتداء',
  },
  {
    id: 'husary_murattal',
    nameAr: 'محمود خليل الحصري (مرتل)',
    nameEn: 'Mahmoud Khalil Al-Husary (Murattal)',
    riwayah: 'hafs',
    style: 'مرتل متمكن',
    tempo: 'slow',
    bitrate: 128,
    cdnPattern: 'https://everyayah.com/data/Husary_128kbps/{surah:03d}{ayah:03d}.mp3',
    recommendedForHifz: true,
    pedagogicalNote: 'تلاوة متزنة هادئة لترسيخ الذاكرة الصوتية في مراحل الربط',
  },
  {
    id: 'minshawy_teacher',
    nameAr: 'محمد صديق المنشاوي (المعلم)',
    nameEn: 'Mohamed Siddiq Al-Minshawi (Teacher)',
    riwayah: 'hafs',
    style: 'معلم بنبرة خاشعة',
    tempo: 'slow',
    bitrate: 128,
    cdnPattern: 'https://everyayah.com/data/Minshawy_Teacher_128kbps/{surah:03d}{ayah:03d}.mp3',
    recommendedForHifz: true,
    pedagogicalNote: 'نبرة خاشعة ونطق بلوري فائق الإتقان مناسب جداً للمبتدئين',
  },
  {
    id: 'minshawy_murattal',
    nameAr: 'محمد صديق المنشاوي (مرتل)',
    nameEn: 'Mohamed Siddiq Al-Minshawi (Murattal)',
    riwayah: 'hafs',
    style: 'مرتل خاشع ومؤثر',
    tempo: 'medium',
    bitrate: 128,
    cdnPattern: 'https://everyayah.com/data/Minshawy_Murattal_128kbps/{surah:03d}{ayah:03d}.mp3',
    recommendedForHifz: true,
    pedagogicalNote: 'تلاوة حزينة مؤثرة تزيد من التركيز واستقرار الآيات',
  },
  {
    id: 'alafasy',
    nameAr: 'مشاري راشد العفاسي',
    nameEn: 'Mishary Rashid Alafasy',
    riwayah: 'hafs',
    style: 'مرتل واضح وعذب',
    tempo: 'medium',
    bitrate: 128,
    cdnPattern: 'https://everyayah.com/data/Alafasy_128kbps/{surah:03d}{ayah:03d}.mp3',
    recommendedForHifz: true,
    pedagogicalNote: 'إيقاع نغمي عذب وواضح يسهل تذكره في المراجعة السريعة',
  },
  {
    id: 'abdulbasit_murattal',
    nameAr: 'عبد الباسط عبد الصمد (مرتل)',
    nameEn: 'Abdul Basit Abdus Samad (Murattal)',
    riwayah: 'hafs',
    style: 'مرتل بنبرة بديعة',
    tempo: 'medium',
    bitrate: 192,
    cdnPattern: 'https://everyayah.com/data/Abdul_Basit_Murattal_192kbps/{surah:03d}{ayah:03d}.mp3',
    recommendedForHifz: true,
    pedagogicalNote: 'وضوح صوتي متميز ونَفَس طويل يساعد في استيعاب نهايات الآيات',
  },
  {
    id: 'hudhaify_hafs',
    nameAr: 'علي بن عبد الرحمن الحذيفي',
    nameEn: 'Ali Al-Hudhaify',
    riwayah: 'hafs',
    style: 'مرتل متقن للمخارج',
    tempo: 'slow',
    bitrate: 128,
    cdnPattern: 'https://everyayah.com/data/Hudhaify_128kbps/{surah:03d}{ayah:03d}.mp3',
    recommendedForHifz: true,
    pedagogicalNote: 'تلاوة رصينة محكمة بدون تكلف، ممتازة لمطابقة الحركات وتفخيم الحروف',
  },
  {
    id: 'basfar',
    nameAr: 'عبد الله بصفر (المعلم)',
    nameEn: 'Abdullah Basfar',
    riwayah: 'hafs',
    style: 'معلم بوضوح عالي',
    tempo: 'slow',
    bitrate: 192,
    cdnPattern: 'https://everyayah.com/data/Abdullah_Basfar_192kbps/{surah:03d}{ayah:03d}.mp3',
    recommendedForHifz: true,
    pedagogicalNote: 'دقة عالية في المخارج والتجويد وصوت نقي',
  },
  {
    id: 'ayman_sowaid',
    nameAr: 'أيمن سويد (تجويد تعليمي)',
    nameEn: 'Ayman Sowaid',
    riwayah: 'hafs',
    style: 'تجويد تعليمي دقيق',
    tempo: 'slow',
    bitrate: 64,
    cdnPattern: 'https://everyayah.com/data/Ayman_Sowaid_64kbps/{surah:03d}{ayah:03d}.mp3',
    recommendedForHifz: true,
    pedagogicalNote: 'تفكيك تعليمي فائق الدقة لأحكام التجويد والغنن والمدود',
  },
  {
    id: 'ayyub',
    nameAr: 'محمد أيوب',
    nameEn: 'Muhammad Ayyub',
    riwayah: 'hafs',
    style: 'مرتل حجازي عذب',
    tempo: 'medium',
    bitrate: 128,
    cdnPattern: 'https://everyayah.com/data/Muhammad_Ayyoub_128kbps/{surah:03d}{ayah:03d}.mp3',
    recommendedForHifz: true,
    pedagogicalNote: 'تلاوة حجازية سلسة تساعد على ترابط المقاطع الطويلة',
  },
  {
    id: 'shatri',
    nameAr: 'أبو بكر الشاطري',
    nameEn: 'Abu Bakr Al-Shatri',
    riwayah: 'hafs',
    style: 'مرتل هادئ ومريح',
    tempo: 'medium',
    bitrate: 128,
    cdnPattern: 'https://everyayah.com/data/Abu_Bakr_Ash-Shaatree_128kbps/{surah:03d}{ayah:03d}.mp3',
    recommendedForHifz: true,
    pedagogicalNote: 'ترتيل عصري هادئ ومريح للجلسات الممتدة',
  },
  {
    id: 'maher',
    nameAr: 'ماهر المعيقلي',
    nameEn: 'Maher Al-Muaiqly',
    riwayah: 'hafs',
    style: 'مرتل واضح ومحبوب',
    tempo: 'medium',
    bitrate: 128,
    cdnPattern: 'https://everyayah.com/data/MaherAlMuaiqly128kbps/{surah:03d}{ayah:03d}.mp3',
    recommendedForHifz: true,
    pedagogicalNote: 'صوت واضح وتدفق نغمي محبب للأذن',
  },
  {
    id: 'ghamadi',
    nameAr: 'سعد الغامدي',
    nameEn: 'Saad Al-Ghamdi',
    riwayah: 'hafs',
    style: 'مرتل سلس وسريع',
    tempo: 'medium',
    bitrate: 40,
    cdnPattern: 'https://everyayah.com/data/Ghamadi_40kbps/{surah:03d}{ayah:03d}.mp3',
    recommendedForHifz: true,
    pedagogicalNote: 'سريع وسلس مناسب لمراجعة المحفوظ وتثبيته',
  },

  // =========================================================================
  // 2. WARSH 'AN NAFI' (ورش عن نافع)
  // =========================================================================
  {
    id: 'dosary_warsh',
    nameAr: 'إبراهيم الدوسري (ورش)',
    nameEn: 'Ibrahim Al-Dosary (Warsh)',
    riwayah: 'warsh',
    style: 'رواية ورش عن نافع بإتقان',
    tempo: 'medium',
    bitrate: 128,
    cdnPattern: 'https://everyayah.com/data/warsh/warsh_ibrahim_aldosary_128kbps/{surah:03d}{ayah:03d}.mp3',
    recommendedForHifz: true,
    pedagogicalNote: 'المرجع الأول لرواية ورش، بأداء منهجي وإظهار دقيق لتقليل الألف والترقيق',
  },
  {
    id: 'husary_warsh',
    nameAr: 'محمود خليل الحصري (ورش)',
    nameEn: 'Mahmoud Khalil Al-Husary (Warsh)',
    riwayah: 'warsh',
    style: 'تحقيق ورش من طريق الأزرق',
    tempo: 'slow',
    bitrate: 128,
    cdnPattern: 'https://verse.mp3quran.net/arabic/husary_warsh/{surah:03d}{ayah:03d}.mp3',
    recommendedForHifz: true,
    pedagogicalNote: 'التلاوة المرجعية المتقنة لرواية ورش من طريق الأزرق برزانة المشايخ الكبار',
  },
  {
    id: 'yassin_warsh',
    nameAr: 'ياسين الجزائري (ورش)',
    nameEn: 'Yassin Al-Jazaery (Warsh)',
    riwayah: 'warsh',
    style: 'تلاوة مغاربية أصيلة',
    tempo: 'medium',
    bitrate: 64,
    cdnPattern: 'https://everyayah.com/data/warsh/warsh_yassin_al_jazaery_64kbps/{surah:03d}{ayah:03d}.mp3',
    recommendedForHifz: true,
    pedagogicalNote: 'التلاوة المغاربية الأصيلة بأسلوب جزائري عذب ومنضبط',
  },
  {
    id: 'abdulbasit_warsh',
    nameAr: 'عبد الباسط عبد الصمد (ورش)',
    nameEn: 'Abdul Basit Abdus Samad (Warsh)',
    riwayah: 'warsh',
    style: 'رواية ورش بصوت خاشع',
    tempo: 'medium',
    bitrate: 128,
    cdnPattern: 'https://everyayah.com/data/warsh/warsh_Abdul_Basit_128kbps/{surah:03d}{ayah:03d}.mp3',
    recommendedForHifz: true,
    pedagogicalNote: 'تلاوة نادرة خاشعة برواية ورش بصوت الشيخ عبد الباسط المميز',
  },

  // =========================================================================
  // 3. QALUN 'AN NAFI' (قالون عن نافع)
  // =========================================================================
  {
    id: 'hudhaify_qalun',
    nameAr: 'علي بن عبد الرحمن الحذيفي (قالون)',
    nameEn: 'Ali Al-Hudhaify (Qalun)',
    riwayah: 'qalun',
    style: 'رواية قالون عن نافع برزانة',
    tempo: 'slow',
    bitrate: 128,
    cdnPattern: 'https://verse.mp3quran.net/arabic/hudhaify_qalun/{surah:03d}{ayah:03d}.mp3',
    recommendedForHifz: true,
    pedagogicalNote: 'مرجع أصيل لرواية قالون مع إسكان وصلة ميم الجمع بوضوح ناصع',
  },
  {
    id: 'husary_qalun',
    nameAr: 'محمود خليل الحصري (قالون)',
    nameEn: 'Mahmoud Khalil Al-Husary (Qalun)',
    riwayah: 'qalun',
    style: 'رواية قالون بتدقيق المشايخ',
    tempo: 'slow',
    bitrate: 128,
    cdnPattern: 'https://verse.mp3quran.net/arabic/husary_qalun/{surah:03d}{ayah:03d}.mp3',
    recommendedForHifz: true,
    pedagogicalNote: 'تحقيق وتدقيق مشايخ المقارئ المصرية لرواية قالون عن نافع',
  },
  {
    id: 'dokali_qalun',
    nameAr: 'محمد العالم الدوكالي (قالون)',
    nameEn: 'Muhammad Al-Dokali (Qalun)',
    riwayah: 'qalun',
    style: 'رواية قالون تلاوة ليبية أصيلة',
    tempo: 'medium',
    bitrate: 128,
    cdnPattern: 'https://verse.mp3quran.net/arabic/dokali/{surah:03d}{ayah:03d}.mp3',
    recommendedForHifz: true,
    pedagogicalNote: 'التلاوة الليبية الشهيرة برواية قالون واسعة الانتشار في شمال إفريقيا',
  },

  // =========================================================================
  // 4. AL-DURI 'AN ABI 'AMR (الدوري عن أبي عمرو)
  // =========================================================================
  {
    id: 'husary_duri',
    nameAr: 'محمود خليل الحصري (الدوري عن أبي عمرو)',
    nameEn: 'Mahmoud Khalil Al-Husary (Al-Duri)',
    riwayah: 'duri',
    style: 'رواية الدوري مع الإدغام الكبير والإمالة',
    tempo: 'slow',
    bitrate: 128,
    cdnPattern: 'https://verse.mp3quran.net/arabic/husary_duri/{surah:03d}{ayah:03d}.mp3',
    recommendedForHifz: true,
    pedagogicalNote: 'التلاوة المرجعية النادرة لرواية الدوري مع الإدغام الكبير والإمالة',
  },
];

export function getRecitersByRiwayah(riwayah: Riwayah): VerifiedReciter[] {
  return HIFZ_RECITERS.filter((r) => r.riwayah === riwayah);
}

export function buildAudioUrl(reciter: VerifiedReciter, surah: number, ayah: number): string {
  const surahPadded = String(surah).padStart(3, '0');
  const ayahPadded = String(ayah).padStart(3, '0');
  return reciter.cdnPattern
    .replace('{surah:03d}', surahPadded)
    .replace('{ayah:03d}', ayahPadded);
}

export function getFallbackAudioUrl(surah: number, ayah: number): string {
  const surahPadded = String(surah).padStart(3, '0');
  const ayahPadded = String(ayah).padStart(3, '0');
  return `https://everyayah.com/data/Husary_Muallim_128kbps/${surahPadded}${ayahPadded}.mp3`;
}
