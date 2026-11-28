import 'dart:convert';
import 'dart:io';

/// Production-Ready Dual-Tier Reciter Catalog for Itqan Quran (Flutter).
/// Covers Hafs, Warsh, Qalun, and Al-Duri across:
/// - Tier 1A: Verified EveryAyah direct ayah-by-ayah reciters (HTTP 200)
/// - Tier 1B: MP3Quran v3 millisecond-timed zero-gap reciters (HTTP 200)
/// - Tier 2: Live MP3Quran v3 catalog (199+ complete 114-surah reciters)
class HifzReciter {
  final String id;
  final String nameAr;
  final String nameEn;
  final String riwayah; // 'hafs', 'warsh', 'qalun', 'duri'
  final String style; // Display subtitle
  final String styleCategory; // 'hadr', 'murattal', 'muallim'
  final String audioMode; // 'ayah_direct', 'ayah_timed', 'surah_stream'
  final String tempo; // 'slow', 'medium', 'fast'
  final int? bitrate;
  final String cdnPattern;
  final int? mp3QuranReadId;
  final bool recommendedForHifz;
  final bool fastFriendly;
  final String? pedagogicalNote;

  const HifzReciter({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.riwayah,
    required this.style,
    required this.styleCategory,
    required this.audioMode,
    required this.tempo,
    this.bitrate,
    required this.cdnPattern,
    this.mp3QuranReadId,
    this.recommendedForHifz = true,
    this.fastFriendly = false,
    this.pedagogicalNote,
  });
}

class QuranRecitersData {
  static const List<String> _fastReciterKeywords = [
    'الشريم',
    'السديس',
    'الغامدي',
    'ياسر سلامة',
    'فارس عباد',
    'علي جابر',
    'صلاح البدير',
    'الجهني',
    'سهل ياسين',
    'العلاقمي',
    'الحواشي',
    'المحيسني',
    'الكلباني',
    'اللحيدان',
    'خالد المهنا',
    'نبيل الرفاعي',
    'أحمد العجمي',
    'المعيقلي',
    'القطامي',
    'ياسر الدوسري',
    'خالد الجليل',
    'إدريس أبكر',
  ];

  static const List<HifzReciter> curatedCore = [
    // =========================================================================
    // 1. HAFS — HADR / FAST (حدر سريع ومثالي للتكرار السريع 1.25× - 1.75×)
    // =========================================================================
    HifzReciter(
      id: 'yaser_salamah_hadr',
      nameAr: 'ياسر سلامة (المصحف الحدر)',
      nameEn: 'Yaser Salamah (Fast Hadr)',
      riwayah: 'hafs',
      style: 'حدر سريع منضبط للتكرار',
      styleCategory: 'hadr',
      audioMode: 'ayah_direct',
      tempo: 'fast',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/Yaser_Salamah_128kbps/{surah:03d}{ayah:03d}.mp3',
      fastFriendly: true,
      pedagogicalNote: 'أشهر مصحف حدر منضبط الأحكام؛ مثالي للتكرار المكثف حتى 1.5×',
    ),
    HifzReciter(
      id: 'shuraim',
      nameAr: 'سعود الشريم',
      nameEn: 'Saud Al-Shuraim',
      riwayah: 'hafs',
      style: 'حدر سريع واضح المخارج',
      styleCategory: 'hadr',
      audioMode: 'ayah_direct',
      tempo: 'fast',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/Saood_ash-Shuraym_128kbps/{surah:03d}{ayah:03d}.mp3',
      fastFriendly: true,
      pedagogicalNote: 'وتيرة حدر متماسكة ومخارج واضحة جداً عند تسريع التلاوة إلى 1.5×',
    ),
    HifzReciter(
      id: 'sudais',
      nameAr: 'عبد الرحمن السديس',
      nameEn: 'Abdul Rahman Al-Sudais',
      riwayah: 'hafs',
      style: 'حدر سريع للحفظ التراكمي',
      styleCategory: 'hadr',
      audioMode: 'ayah_direct',
      tempo: 'fast',
      bitrate: 192,
      cdnPattern: 'https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/{surah:03d}{ayah:03d}.mp3',
      fastFriendly: true,
      pedagogicalNote: 'قراءة حدر رشيقة ممتازة لمضاعفة التكرارات والمراجعة السريعة',
    ),
    HifzReciter(
      id: 'ghamadi',
      nameAr: 'سعد الغامدي',
      nameEn: 'Saad Al-Ghamdi',
      riwayah: 'hafs',
      style: 'حدر سلس وخفيف البيانات',
      styleCategory: 'hadr',
      audioMode: 'ayah_direct',
      tempo: 'fast',
      bitrate: 40,
      cdnPattern: 'https://everyayah.com/data/Ghamadi_40kbps/{surah:03d}{ayah:03d}.mp3',
      fastFriendly: true,
      pedagogicalNote: 'سلس وسريع وخفيف البيانات؛ مفضل لمراجعة الأجزاء بسرعة 1.5×',
    ),
    HifzReciter(
      id: 'fares_abbad',
      nameAr: 'فارس عباد',
      nameEn: 'Fares Abbad',
      riwayah: 'hafs',
      style: 'حدر سريع بنبرة متماسكة',
      styleCategory: 'hadr',
      audioMode: 'ayah_direct',
      tempo: 'fast',
      bitrate: 64,
      cdnPattern: 'https://everyayah.com/data/Fares_Abbad_64kbps/{surah:03d}{ayah:03d}.mp3',
      fastFriendly: true,
      pedagogicalNote: 'تدفق سريع ومنسجم يسهل تكرار الصفحة عشرات المرات دون إرهاق',
    ),
    HifzReciter(
      id: 'ali_jaber',
      nameAr: 'علي جابر',
      nameEn: 'Ali Jaber',
      riwayah: 'hafs',
      style: 'حدر حجازي رصين',
      styleCategory: 'hadr',
      audioMode: 'ayah_direct',
      tempo: 'fast',
      bitrate: 64,
      cdnPattern: 'https://everyayah.com/data/Ali_Jaber_64kbps/{surah:03d}{ayah:03d}.mp3',
      fastFriendly: true,
      pedagogicalNote: 'إيقاع ثابت ووقفات واضحة لتثبيت المتشابهات بسرعة',
    ),
    HifzReciter(
      id: 'salah_al_budair',
      nameAr: 'صلاح البدير',
      nameEn: 'Salah Al-Budair',
      riwayah: 'hafs',
      style: 'حدر متزن وواضح',
      styleCategory: 'hadr',
      audioMode: 'ayah_direct',
      tempo: 'fast',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/Salah_Al_Budair_128kbps/{surah:03d}{ayah:03d}.mp3',
      fastFriendly: true,
      pedagogicalNote: 'تلاوة إمام المسجد النبوي بنبرة حازمة سريعة ممتازة للمراجعة',
    ),
    HifzReciter(
      id: 'juhaynee',
      nameAr: 'عبد الله عواد الجهني',
      nameEn: 'Abdullah Al-Juhaynee',
      riwayah: 'hafs',
      style: 'حدر سريع وقوي النبرة',
      styleCategory: 'hadr',
      audioMode: 'ayah_direct',
      tempo: 'fast',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/Abdullaah_3awwaad_Al-Juhaynee_128kbps/{surah:03d}{ayah:03d}.mp3',
      fastFriendly: true,
      pedagogicalNote: 'قراءة سريعة واضحة تحافظ على صفاء الحروف عند تسريع الصوت',
    ),
    HifzReciter(
      id: 'sahl_yassin',
      nameAr: 'سهل ياسين',
      nameEn: 'Sahl Yassin',
      riwayah: 'hafs',
      style: 'حدر خفيف وهادئ',
      styleCategory: 'hadr',
      audioMode: 'ayah_direct',
      tempo: 'fast',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/Sahl_Yassin_128kbps/{surah:03d}{ayah:03d}.mp3',
      fastFriendly: true,
      pedagogicalNote: 'سرعة طبيعية مريحة للسمع تساعد في تثبيت الورد اليومي بسرعة',
    ),
    HifzReciter(
      id: 'akram_alaqimy',
      nameAr: 'أكرم العلاقمي',
      nameEn: 'Akram Al-Alaqimy',
      riwayah: 'hafs',
      style: 'حدر تعليمي متقن',
      styleCategory: 'hadr',
      audioMode: 'ayah_direct',
      tempo: 'fast',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/Akram_AlAlaqimy_128kbps/{surah:03d}{ayah:03d}.mp3',
      fastFriendly: true,
      pedagogicalNote: 'أداء سريع متزن يجمع بين دقة المخارج وسرعة الإنجاز',
    ),
    HifzReciter(
      id: 'mp3q_timed_13_zain_ahmad',
      nameAr: 'الزين محمد أحمد',
      nameEn: 'Al-Zain Muhammad Ahmad',
      riwayah: 'hafs',
      style: 'حدر سوداني سلس · بدون فجوات',
      styleCategory: 'hadr',
      audioMode: 'ayah_timed',
      mp3QuranReadId: 13,
      tempo: 'fast',
      cdnPattern: 'https://cdn.mp3quran.net/audio/alzain-mohammad/r1/{surah:03d}.mp3',
      fastFriendly: true,
      pedagogicalNote: 'إيقاع سوداني منتظم بتوقيت آيات دقيق بدون تقطع عند 1.5×',
    ),

    // =========================================================================
    // 2. HAFS — MUALLIM (المصحف المعلم)
    // =========================================================================
    HifzReciter(
      id: 'husary_muallim',
      nameAr: 'محمود خليل الحصري (المعلم)',
      nameEn: 'Mahmoud Khalil Al-Husary (Teacher)',
      riwayah: 'hafs',
      style: 'معلم مع الوقف المتقن',
      styleCategory: 'muallim',
      audioMode: 'ayah_direct',
      tempo: 'slow',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/Husary_Muallim_128kbps/{surah:03d}{ayah:03d}.mp3',
      pedagogicalNote: 'المعيار الذهبي للتحفيظ وضبط مخارج الحروف وأحكام الوقف',
    ),
    HifzReciter(
      id: 'minshawy_teacher',
      nameAr: 'محمد صديق المنشاوي (المعلم)',
      nameEn: 'Mohamed Siddiq Al-Minshawi (Teacher)',
      riwayah: 'hafs',
      style: 'معلم بنبرة خاشعة',
      styleCategory: 'muallim',
      audioMode: 'ayah_direct',
      tempo: 'slow',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/Minshawy_Teacher_128kbps/{surah:03d}{ayah:03d}.mp3',
      pedagogicalNote: 'نبرة خاشعة ونطق بلوري فائق الإتقان للتأسيس والتلقين',
    ),
    HifzReciter(
      id: 'ayman_sowaid',
      nameAr: 'أيمن رشدي سويد (تجويد تعليمي)',
      nameEn: 'Ayman Sowaid',
      riwayah: 'hafs',
      style: 'معلم وتجويد تعليمي دقيق',
      styleCategory: 'muallim',
      audioMode: 'ayah_direct',
      tempo: 'slow',
      bitrate: 64,
      cdnPattern: 'https://everyayah.com/data/Ayman_Sowaid_64kbps/{surah:03d}{ayah:03d}.mp3',
      pedagogicalNote: 'تفكيك تعليمي فائق الدقة لأحكام التجويد والغنن والمدود',
    ),
    HifzReciter(
      id: 'basfar',
      nameAr: 'عبد الله بصفر (المعلم)',
      nameEn: 'Abdullah Basfar',
      riwayah: 'hafs',
      style: 'معلم بوضوح عالٍ',
      styleCategory: 'muallim',
      audioMode: 'ayah_direct',
      tempo: 'slow',
      bitrate: 192,
      cdnPattern: 'https://everyayah.com/data/Abdullah_Basfar_192kbps/{surah:03d}{ayah:03d}.mp3',
      pedagogicalNote: 'دقة عالية في المخارج والتجويد وصوت نقي جداً',
    ),
    HifzReciter(
      id: 'khalefa_tunaiji',
      nameAr: 'خليفة الطنيجي',
      nameEn: 'Khalefa Al-Tunaiji',
      riwayah: 'hafs',
      style: 'معلم ومرتل تعليمي واضح',
      styleCategory: 'muallim',
      audioMode: 'ayah_direct',
      tempo: 'medium',
      bitrate: 64,
      cdnPattern: 'https://everyayah.com/data/khalefa_al_tunaiji_64kbps/{surah:03d}{ayah:03d}.mp3',
      fastFriendly: true,
      pedagogicalNote: 'أسلوب تعليمي محبب يسهل الحفظ والتكرار حتى بسرعة 1.5×',
    ),

    // =========================================================================
    // 3. HAFS — MURATTAL (المصحف المرتل المتنوع)
    // =========================================================================
    HifzReciter(
      id: 'alafasy',
      nameAr: 'مشاري راشد العفاسي',
      nameEn: 'Mishary Rashid Alafasy',
      riwayah: 'hafs',
      style: 'مرتل واضح وعذب',
      styleCategory: 'murattal',
      audioMode: 'ayah_direct',
      tempo: 'medium',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/Alafasy_128kbps/{surah:03d}{ayah:03d}.mp3',
      fastFriendly: true,
      pedagogicalNote: 'إيقاع نغمي عذب وواضح يسهل تذكره في الحفظ والمراجعة',
    ),
    HifzReciter(
      id: 'maher',
      nameAr: 'ماهر المعيقلي',
      nameEn: 'Maher Al-Muaiqly',
      riwayah: 'hafs',
      style: 'مرتل واضح ومحبوب',
      styleCategory: 'murattal',
      audioMode: 'ayah_direct',
      tempo: 'medium',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/MaherAlMuaiqly128kbps/{surah:03d}{ayah:03d}.mp3',
      fastFriendly: true,
      pedagogicalNote: 'صوت واضح وتدفق نغمي منسجم رائع للتكرار بسرعة 1.25× و 1.5×',
    ),
    HifzReciter(
      id: 'yasser_dussary',
      nameAr: 'ياسر الدوسري',
      nameEn: 'Yasser Al-Dosari',
      riwayah: 'hafs',
      style: 'مرتل مؤثر وعذب',
      styleCategory: 'murattal',
      audioMode: 'ayah_direct',
      tempo: 'medium',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/Yasser_Ad-Dussary_128kbps/{surah:03d}{ayah:03d}.mp3',
      fastFriendly: true,
      pedagogicalNote: 'تلاوة إمام الحرم المكي بأسلوب خاشع ووضوح عالٍ',
    ),
    HifzReciter(
      id: 'nasser_alqatami',
      nameAr: 'ناصر القطامي',
      nameEn: 'Nasser Al-Qatami',
      riwayah: 'hafs',
      style: 'مرتل خاشع وسلس',
      styleCategory: 'murattal',
      audioMode: 'ayah_direct',
      tempo: 'medium',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/Nasser_Alqatami_128kbps/{surah:03d}{ayah:03d}.mp3',
      fastFriendly: true,
      pedagogicalNote: 'إيقاع متوازن يجمع بين التأثر القلبي وسهولة الترديد',
    ),
    HifzReciter(
      id: 'ahmed_ajamy',
      nameAr: 'أحمد بن علي العجمي',
      nameEn: 'Ahmed Al-Ajamy',
      riwayah: 'hafs',
      style: 'مرتل ندي ومنسجم',
      styleCategory: 'murattal',
      audioMode: 'ayah_direct',
      tempo: 'medium',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/ahmed_ibn_ali_al_ajamy_128kbps/{surah:03d}{ayah:03d}.mp3',
      fastFriendly: true,
      pedagogicalNote: 'تلاوة محبوبة ومرنة جداً عند التسريع إلى 1.5×',
    ),
    HifzReciter(
      id: 'husary_murattal',
      nameAr: 'محمود خليل الحصري (مرتل)',
      nameEn: 'Mahmoud Khalil Al-Husary (Murattal)',
      riwayah: 'hafs',
      style: 'مرتل متمكن',
      styleCategory: 'murattal',
      audioMode: 'ayah_direct',
      tempo: 'slow',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/Husary_128kbps/{surah:03d}{ayah:03d}.mp3',
      pedagogicalNote: 'تلاوة متزنة هادئة لترسيخ الذاكرة الصوتية في مراحل الربط',
    ),
    HifzReciter(
      id: 'minshawy_murattal',
      nameAr: 'محمد صديق المنشاوي (مرتل)',
      nameEn: 'Mohamed Siddiq Al-Minshawi (Murattal)',
      riwayah: 'hafs',
      style: 'مرتل خاشع ومؤثر',
      styleCategory: 'murattal',
      audioMode: 'ayah_direct',
      tempo: 'medium',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/Minshawy_Murattal_128kbps/{surah:03d}{ayah:03d}.mp3',
      pedagogicalNote: 'تلاوة مؤثرة تزيد من التركيز واستقرار الآيات',
    ),
    HifzReciter(
      id: 'abdulbasit_murattal',
      nameAr: 'عبد الباسط عبد الصمد (مرتل)',
      nameEn: 'Abdul Basit (Murattal)',
      riwayah: 'hafs',
      style: 'مرتل بنبرة بديعة',
      styleCategory: 'murattal',
      audioMode: 'ayah_direct',
      tempo: 'medium',
      bitrate: 192,
      cdnPattern: 'https://everyayah.com/data/Abdul_Basit_Murattal_192kbps/{surah:03d}{ayah:03d}.mp3',
      pedagogicalNote: 'وضوح صوتي متميز ونَفَس طويل يساعد في استيعاب نهايات الآيات',
    ),
    HifzReciter(
      id: 'hudhaify_hafs',
      nameAr: 'علي بن عبد الرحمن الحذيفي',
      nameEn: 'Ali Al-Hudhaify',
      riwayah: 'hafs',
      style: 'مرتل متقن للمخارج',
      styleCategory: 'murattal',
      audioMode: 'ayah_direct',
      tempo: 'slow',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/Hudhaify_128kbps/{surah:03d}{ayah:03d}.mp3',
      pedagogicalNote: 'تلاوة رصينة محكمة لمطابقة الحركات وتفخيم الحروف',
    ),
    HifzReciter(
      id: 'ayyub',
      nameAr: 'محمد أيوب',
      nameEn: 'Muhammad Ayyub',
      riwayah: 'hafs',
      style: 'مرتل حجازي عذب',
      styleCategory: 'murattal',
      audioMode: 'ayah_direct',
      tempo: 'medium',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/Muhammad_Ayyoub_128kbps/{surah:03d}{ayah:03d}.mp3',
      pedagogicalNote: 'تلاوة حجازية سلسة تساعد على ترابط المقاطع الطويلة',
    ),
    HifzReciter(
      id: 'shatri',
      nameAr: 'أبو بكر الشاطري',
      nameEn: 'Abu Bakr Al-Shatri',
      riwayah: 'hafs',
      style: 'مرتل هادئ ومريح',
      styleCategory: 'murattal',
      audioMode: 'ayah_direct',
      tempo: 'medium',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/Abu_Bakr_Ash-Shaatree_128kbps/{surah:03d}{ayah:03d}.mp3',
      pedagogicalNote: 'ترتيل عصري هادئ ومريح للجلسات الممتدة',
    ),
    HifzReciter(
      id: 'khalid_qahtani',
      nameAr: 'خالد القحطاني',
      nameEn: 'Khalid Al-Qahtani',
      riwayah: 'hafs',
      style: 'مرتل نقي وواضح',
      styleCategory: 'murattal',
      audioMode: 'ayah_direct',
      tempo: 'medium',
      bitrate: 192,
      cdnPattern: 'https://everyayah.com/data/Khaalid_Abdullaah_al-Qahtaanee_192kbps/{surah:03d}{ayah:03d}.mp3',
      pedagogicalNote: 'صوت شجي واضح ومخارج متقنة للحفظ اليومي',
    ),
    HifzReciter(
      id: 'hani_rifai',
      nameAr: 'هاني الرفاعي',
      nameEn: 'Hani Al-Rifai',
      riwayah: 'hafs',
      style: 'مرتل خاشع',
      styleCategory: 'murattal',
      audioMode: 'ayah_direct',
      tempo: 'medium',
      bitrate: 192,
      cdnPattern: 'https://everyayah.com/data/Hani_Rifai_192kbps/{surah:03d}{ayah:03d}.mp3',
      pedagogicalNote: 'نبرة روحانية مؤثرة تساعد على التدبر أثناء الحفظ',
    ),
    HifzReciter(
      id: 'muhammad_jibreel',
      nameAr: 'محمد جبريل',
      nameEn: 'Muhammad Jibreel',
      riwayah: 'hafs',
      style: 'مرتل مصري متقن',
      styleCategory: 'murattal',
      audioMode: 'ayah_direct',
      tempo: 'medium',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/Muhammad_Jibreel_128kbps/{surah:03d}{ayah:03d}.mp3',
      pedagogicalNote: 'أداء مصري متمكن وضبط ممتاز للمدود',
    ),
    HifzReciter(
      id: 'salah_bukhatir',
      nameAr: 'صلاح بو خاطر',
      nameEn: 'Salah Bukhatir',
      riwayah: 'hafs',
      style: 'مرتل هادئ وعذب',
      styleCategory: 'murattal',
      audioMode: 'ayah_direct',
      tempo: 'medium',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/Salaah_AbdulRahman_Bukhatir_128kbps/{surah:03d}{ayah:03d}.mp3',
      pedagogicalNote: 'تلاوة مريحة للأذن ومناسبة للمراجعة الطويلة',
    ),
    HifzReciter(
      id: 'abdullah_matroud',
      nameAr: 'عبد الله مطرود',
      nameEn: 'Abdullah Matroud',
      riwayah: 'hafs',
      style: 'مرتل واضح وسلس',
      styleCategory: 'murattal',
      audioMode: 'ayah_direct',
      tempo: 'medium',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/Abdullah_Matroud_128kbps/{surah:03d}{ayah:03d}.mp3',
      pedagogicalNote: 'وضوح فائق وإيقاع ثابت يساعد على سرعة الاستظهار',
    ),
    HifzReciter(
      id: 'muhsin_qasim',
      nameAr: 'عبد المحسن القاسم',
      nameEn: 'Abdul Muhsin Al-Qasim',
      riwayah: 'hafs',
      style: 'مرتل مدني رصين',
      styleCategory: 'murattal',
      audioMode: 'ayah_direct',
      tempo: 'medium',
      bitrate: 192,
      cdnPattern: 'https://everyayah.com/data/Muhsin_Al_Qasim_192kbps/{surah:03d}{ayah:03d}.mp3',
      pedagogicalNote: 'إمام المسجد النبوي بقراءة متزنة تناسب التحفيظ المنضبط',
    ),
    HifzReciter(
      id: 'ibrahim_akhdar',
      nameAr: 'إبراهيم الأخضر',
      nameEn: 'Ibrahim Al-Akhdar',
      riwayah: 'hafs',
      style: 'مرتل مدني متأنٍّ',
      styleCategory: 'murattal',
      audioMode: 'ayah_direct',
      tempo: 'slow',
      bitrate: 64,
      cdnPattern: 'https://everyayah.com/data/Ibrahim_Akhdar_64kbps/{surah:03d}{ayah:03d}.mp3',
      pedagogicalNote: 'شيخ قراء المدينة المنورة بأسلوب متأنٍّ دقيق',
    ),
    HifzReciter(
      id: 'mp3q_timed_12_idris_abkar',
      nameAr: 'إدريس أبكر',
      nameEn: 'Idris Abkar',
      riwayah: 'hafs',
      style: 'مرتل خاشع · بدون فجوات',
      styleCategory: 'murattal',
      audioMode: 'ayah_timed',
      mp3QuranReadId: 12,
      tempo: 'medium',
      cdnPattern: 'https://cdn.mp3quran.net/audio/idris-abkar/r1/{surah:03d}.mp3',
      fastFriendly: true,
      pedagogicalNote: 'توقيت دقيق بالملي ثانية على ملف متصل — مثالي عند 1.5×',
    ),
    HifzReciter(
      id: 'mp3q_timed_20_khalid_jalil',
      nameAr: 'خالد الجليل',
      nameEn: 'Khalid Al-Jalil',
      riwayah: 'hafs',
      style: 'مرتل مؤثر · بدون فجوات',
      styleCategory: 'murattal',
      audioMode: 'ayah_timed',
      mp3QuranReadId: 20,
      tempo: 'medium',
      cdnPattern: 'https://cdn.mp3quran.net/audio/khalid-jalil/r1/{surah:03d}.mp3',
      fastFriendly: true,
      pedagogicalNote: 'قراءة خاشعة بتوقيت آيات دقيق للحلقة الذهبية',
    ),

    // =========================================================================
    // 4. WARSH 'AN NAFI' (ورش عن نافع — 10 قراء معتمدين)
    // =========================================================================
    HifzReciter(
      id: 'kazabri_warsh',
      nameAr: 'عمر القزابري (ورش)',
      nameEn: 'Omar Al-Kazabri (Warsh)',
      riwayah: 'warsh',
      style: 'ورش مغربي · آية بآية بدون فجوات',
      styleCategory: 'murattal',
      audioMode: 'ayah_timed',
      mp3QuranReadId: 80,
      tempo: 'medium',
      cdnPattern: 'https://cdn.mp3quran.net/audio/omar-kazabri/r1/{surah:03d}.mp3',
      fastFriendly: true,
      pedagogicalNote: 'أشهر تلاوة مغربية برواية ورش بتوقيت آيات دقيق للحلقة الذهبية',
    ),
    HifzReciter(
      id: 'kouchi_warsh',
      nameAr: 'العيون الكوشي (ورش)',
      nameEn: 'Laayoun Al-Kouchi (Warsh)',
      riwayah: 'warsh',
      style: 'ورش مغربي عذب · بدون فجوات',
      styleCategory: 'murattal',
      audioMode: 'ayah_timed',
      mp3QuranReadId: 16,
      tempo: 'medium',
      cdnPattern: 'https://cdn.mp3quran.net/audio/laayoun-kouchi/r1/{surah:03d}.mp3',
      fastFriendly: true,
      pedagogicalNote: 'تلاوة مغربية محبوبة بإيقاع منضبط يدعم الحلقة الذهبية كاملة',
    ),
    HifzReciter(
      id: 'dosary_warsh',
      nameAr: 'إبراهيم الدوسري (ورش)',
      nameEn: 'Ibrahim Al-Dosary (Warsh)',
      riwayah: 'warsh',
      style: 'ورش حدر سريع · آية بآية',
      styleCategory: 'hadr',
      audioMode: 'ayah_direct',
      tempo: 'fast',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/warsh/warsh_ibrahim_aldosary_128kbps/{surah:03d}{ayah:03d}.mp3',
      fastFriendly: true,
      pedagogicalNote: 'أداء منهجي واضح ممتاز لتكرار رواية ورش بسرعة 1.5×',
    ),
    HifzReciter(
      id: 'yassin_warsh',
      nameAr: 'ياسين الجزائري (ورش)',
      nameEn: 'Yassin Al-Jazaery (Warsh)',
      riwayah: 'warsh',
      style: 'تلاوة مغاربية أصيلة · آية بآية',
      styleCategory: 'murattal',
      audioMode: 'ayah_direct',
      tempo: 'medium',
      bitrate: 64,
      cdnPattern: 'https://everyayah.com/data/warsh/warsh_yassin_al_jazaery_64kbps/{surah:03d}{ayah:03d}.mp3',
      fastFriendly: true,
      pedagogicalNote: 'التلاوة الجزائرية الأصيلة بأسلوب عذب ومنضبط',
    ),
    HifzReciter(
      id: 'husary_warsh',
      nameAr: 'محمود خليل الحصري (ورش)',
      nameEn: 'Mahmoud Khalil Al-Husary (Warsh)',
      riwayah: 'warsh',
      style: 'معلم وتحقيق ورش · بدون فجوات',
      styleCategory: 'muallim',
      audioMode: 'ayah_timed',
      mp3QuranReadId: 120,
      tempo: 'slow',
      cdnPattern: 'https://cdn.mp3quran.net/audio/mahmoud-husary/r3/{surah:03d}.mp3',
      pedagogicalNote: 'المرجع التعليمي الأوثق لرواية ورش من طريق الأزرق',
    ),
    HifzReciter(
      id: 'abdulbasit_warsh',
      nameAr: 'عبد الباسط عبد الصمد (ورش)',
      nameEn: 'Abdul Basit (Warsh)',
      riwayah: 'warsh',
      style: 'مرتل خاشع برواية ورش · آية بآية',
      styleCategory: 'murattal',
      audioMode: 'ayah_direct',
      tempo: 'medium',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/warsh/warsh_Abdul_Basit_128kbps/{surah:03d}{ayah:03d}.mp3',
      pedagogicalNote: 'تلاوة نادرة خاشعة برواية ورش بصوت الشيخ عبد الباسط',
    ),
    HifzReciter(
      id: 'muhammad_saayed_warsh',
      nameAr: 'محمد سايد (ورش)',
      nameEn: 'Muhammad Saayed (Warsh)',
      riwayah: 'warsh',
      style: 'ورش حدر مغربي · بدون فجوات',
      styleCategory: 'hadr',
      audioMode: 'ayah_timed',
      mp3QuranReadId: 134,
      tempo: 'fast',
      cdnPattern: 'https://cdn.mp3quran.net/audio/muhammad-saayed/r1/{surah:03d}.mp3',
      fastFriendly: true,
      pedagogicalNote: 'وتيرة سريعة سلسة برواية ورش تناسب المراجعة المكثفة',
    ),
    HifzReciter(
      id: 'rachid_belalia_warsh',
      nameAr: 'رشيد بلعالية (ورش)',
      nameEn: 'Rachid Belalia (Warsh)',
      riwayah: 'warsh',
      style: 'ورش جزائري حدر · سورة كاملة',
      styleCategory: 'hadr',
      audioMode: 'surah_stream',
      tempo: 'fast',
      cdnPattern: 'https://cdn.mp3quran.net/audio/rachid-belalia/r1/{surah:03d}.mp3',
      fastFriendly: true,
      pedagogicalNote: 'تلاوة متصلة سريعة وواضحة لمراجعة السور الكاملة برواية ورش',
    ),
    HifzReciter(
      id: 'benkirane_warsh',
      nameAr: 'عبد المجيب بنكيران (ورش)',
      nameEn: 'Abdelmoujib Benkirane (Warsh)',
      riwayah: 'warsh',
      style: 'ورش مغربي · سورة كاملة',
      styleCategory: 'murattal',
      audioMode: 'surah_stream',
      tempo: 'medium',
      cdnPattern: 'https://cdn.mp3quran.net/audio/abdelmoujib-benkirane/r1/{surah:03d}.mp3',
      pedagogicalNote: 'قراءة مغربية هادئة للمراجعة المتصلة',
    ),

    // =========================================================================
    // 5. QALUN 'AN NAFI' (قالون عن نافع — 9 قراء معتمدين)
    // =========================================================================
    HifzReciter(
      id: 'dokali_qalun',
      nameAr: 'الدوكالي محمد العالم (قالون)',
      nameEn: 'Muhammad Al-Dokali (Qalun)',
      riwayah: 'qalun',
      style: 'قالون ليبي سريع · بدون فجوات',
      styleCategory: 'hadr',
      audioMode: 'ayah_timed',
      mp3QuranReadId: 208,
      tempo: 'fast',
      cdnPattern: 'https://cdn.mp3quran.net/audio/dokali-alim/r1/{surah:03d}.mp3',
      fastFriendly: true,
      pedagogicalNote: 'أشهر تلاوة ليبية برواية قالون بإيقاع سلس مثالي للتكرار 1.5×',
    ),
    HifzReciter(
      id: 'hudhaify_qalun',
      nameAr: 'علي بن عبد الرحمن الحذيفي (قالون)',
      nameEn: 'Ali Al-Hudhaify (Qalun)',
      riwayah: 'qalun',
      style: 'معلم قالون · آية بآية بدون فجوات',
      styleCategory: 'muallim',
      audioMode: 'ayah_timed',
      mp3QuranReadId: 75,
      tempo: 'slow',
      cdnPattern: 'https://cdn.mp3quran.net/audio/ali-hudhaifi/r2/{surah:03d}.mp3',
      pedagogicalNote: 'مرجع أصيل لرواية قالون بتوقيت دقيق يدعم الحلقة الذهبية',
    ),
    HifzReciter(
      id: 'husary_qalun',
      nameAr: 'محمود خليل الحصري (قالون)',
      nameEn: 'Mahmoud Khalil Al-Husary (Qalun)',
      riwayah: 'qalun',
      style: 'معلم وتحقيق قالون · بدون فجوات',
      styleCategory: 'muallim',
      audioMode: 'ayah_timed',
      mp3QuranReadId: 270,
      tempo: 'slow',
      cdnPattern: 'https://cdn.mp3quran.net/audio/mahmoud-husary/r5/{surah:03d}.mp3',
      pedagogicalNote: 'تدقيق مشايخ المقارئ لرواية قالون عن نافع',
    ),
    HifzReciter(
      id: 'tareq_daawob_qalun',
      nameAr: 'طارق عبد الغني دعوب (قالون)',
      nameEn: 'Tareq Daawob (Qalun)',
      riwayah: 'qalun',
      style: 'قالون حدر سريع · سورة كاملة',
      styleCategory: 'hadr',
      audioMode: 'surah_stream',
      tempo: 'fast',
      cdnPattern: 'https://cdn.mp3quran.net/audio/tareq-daawob/r1/{surah:03d}.mp3',
      fastFriendly: true,
      pedagogicalNote: 'قراءة ليبية سريعة ومتقنة لمراجعة السور الكاملة برواية قالون',
    ),
    HifzReciter(
      id: 'marwan_akri_qalun',
      nameAr: 'مروان العكري (قالون)',
      nameEn: 'Marwan Al-Akri (Qalun)',
      riwayah: 'qalun',
      style: 'قالون تونسي عذب · سورة كاملة',
      styleCategory: 'murattal',
      audioMode: 'surah_stream',
      tempo: 'medium',
      cdnPattern: 'https://cdn.mp3quran.net/audio/marwan-akri/r1/{surah:03d}.mp3',
      fastFriendly: true,
      pedagogicalNote: 'تلاوة تونسية عذبة برواية قالون للمراجعة المتصلة',
    ),
    HifzReciter(
      id: 'qeniwa_qalun',
      nameAr: 'محمد الأمين قنيوة (قالون)',
      nameEn: 'Muhammad Qeniwa (Qalun)',
      riwayah: 'qalun',
      style: 'قالون خاشع · سورة كاملة',
      styleCategory: 'murattal',
      audioMode: 'surah_stream',
      tempo: 'medium',
      cdnPattern: 'https://cdn.mp3quran.net/audio/muhammad-qeniwa/r1/{surah:03d}.mp3',
      pedagogicalNote: 'من أعذب التلاوات برواية قالون عن نافع',
    ),
    HifzReciter(
      id: 'abusnaina_qalun',
      nameAr: 'محمد أبو سنينة (قالون)',
      nameEn: 'Muhammad Abu Snaina (Qalun)',
      riwayah: 'qalun',
      style: 'قالون حدر وسلس · سورة كاملة',
      styleCategory: 'hadr',
      audioMode: 'surah_stream',
      tempo: 'fast',
      cdnPattern: 'https://cdn.mp3quran.net/audio/muhammad-abusnaina/r1/{surah:03d}.mp3',
      fastFriendly: true,
      pedagogicalNote: 'تلاوة سريعة ومنتظمة لمراجعة الورد اليومي برواية قالون',
    ),
    HifzReciter(
      id: 'tarabulsi_qalun',
      nameAr: 'أحمد الطرابلسي (قالون)',
      nameEn: 'Ahmad Al-Tarabulsi (Qalun)',
      riwayah: 'qalun',
      style: 'قالون متقن · سورة كاملة',
      styleCategory: 'murattal',
      audioMode: 'surah_stream',
      tempo: 'medium',
      cdnPattern: 'https://cdn.mp3quran.net/audio/ahmad-tarabulsi/r1/{surah:03d}.mp3',
      pedagogicalNote: 'قراءة واضحة ومريحة للسمع برواية قالون',
    ),

    // =========================================================================
    // 6. AL-DURI 'AN ABI 'AMR (الدوري عن أبي عمرو — 6 قراء معتمدين)
    // =========================================================================
    HifzReciter(
      id: 'husary_duri',
      nameAr: 'محمود خليل الحصري (الدوري)',
      nameEn: 'Mahmoud Khalil Al-Husary (Al-Duri)',
      riwayah: 'duri',
      style: 'معلم الدوري · آية بآية بدون فجوات',
      styleCategory: 'muallim',
      audioMode: 'ayah_timed',
      mp3QuranReadId: 269,
      tempo: 'slow',
      cdnPattern: 'https://cdn.mp3quran.net/audio/mahmoud-husary/r4/{surah:03d}.mp3',
      pedagogicalNote: 'المرجع التعليمي الموثق لرواية الدوري عن أبي عمرو (يدعم الحلقة الذهبية)',
    ),
    HifzReciter(
      id: 'noreen_duri',
      nameAr: 'نورين محمد صديق (الدوري)',
      nameEn: 'Noreen Muhammad Siddiq (Al-Duri)',
      riwayah: 'duri',
      style: 'الدوري السوداني العذب · سورة كاملة',
      styleCategory: 'murattal',
      audioMode: 'surah_stream',
      tempo: 'medium',
      cdnPattern: 'https://cdn.mp3quran.net/audio/noreen-siddiq/r1/{surah:03d}.mp3',
      fastFriendly: true,
      pedagogicalNote: 'من أشهر وأعذب تلاوات رواية الدوري عن أبي عمرو',
    ),
    HifzReciter(
      id: 'fateh_zubair_duri',
      nameAr: 'الفاتح محمد الزبير (الدوري)',
      nameEn: 'Al-Fateh Al-Zubair (Al-Duri)',
      riwayah: 'duri',
      style: 'الدوري حدر وسريع · سورة كاملة',
      styleCategory: 'hadr',
      audioMode: 'surah_stream',
      tempo: 'fast',
      cdnPattern: 'https://cdn.mp3quran.net/audio/fateh-zubair/r1/{surah:03d}.mp3',
      fastFriendly: true,
      pedagogicalNote: 'تلاوة سودانية سلسة وسريعة ممتازة لمراجعة رواية الدوري عند 1.5×',
    ),
    HifzReciter(
      id: 'muftah_saltani_duri',
      nameAr: 'مفتاح السلطني (الدوري)',
      nameEn: 'Muftah Al-Saltani (Al-Duri)',
      riwayah: 'duri',
      style: 'الدوري متقن · سورة كاملة',
      styleCategory: 'murattal',
      audioMode: 'surah_stream',
      tempo: 'medium',
      cdnPattern: 'https://cdn.mp3quran.net/audio/muftah-saltani/r1/{surah:03d}.mp3',
      pedagogicalNote: 'أداء متقن لإمالة وأحكام الدوري عن أبي عمرو',
    ),
    HifzReciter(
      id: 'deeban_duri',
      nameAr: 'أحمد ديبان (الدوري)',
      nameEn: 'Ahmad Deeban (Al-Duri)',
      riwayah: 'duri',
      style: 'الدوري متزن · سورة كاملة',
      styleCategory: 'murattal',
      audioMode: 'surah_stream',
      tempo: 'medium',
      cdnPattern: 'https://cdn.mp3quran.net/audio/ahmad-deeban/r6/{surah:03d}.mp3',
      pedagogicalNote: 'تلاوة واضحة ومضبوطة لرواية الدوري',
    ),
    HifzReciter(
      id: 'saber_duri',
      nameAr: 'صابر عبد الحكم (الدوري - التوسط)',
      nameEn: 'Saber Abdulhakam (Al-Duri)',
      riwayah: 'duri',
      style: 'الدوري معلم بالتوسط · سورة كاملة',
      styleCategory: 'muallim',
      audioMode: 'surah_stream',
      tempo: 'slow',
      cdnPattern: 'https://cdn.mp3quran.net/audio/saber-abdulhakam/r4/{surah:03d}.mp3',
      pedagogicalNote: 'مصحف متقن بتوسط المنفصل لرواية الدوري عن أبي عمرو',
    ),
  ];

  static List<HifzReciter> _mergedCatalog = List<HifzReciter>.from(curatedCore);
  static bool _isLiveLoaded = false;

  static List<HifzReciter> get all => _mergedCatalog;

  static List<HifzReciter> getByRiwayah(String riwayah) {
    return _mergedCatalog.where((r) => r.riwayah == riwayah).toList();
  }

  static HifzReciter getDefault(String riwayah) {
    final list = getByRiwayah(riwayah);
    return list.isNotEmpty ? list.first : curatedCore.first;
  }

  static String? _mapRiwayah(String moshafName) {
    if (moshafName.contains('ورش')) return 'warsh';
    if (moshafName.contains('قالون')) return 'qalun';
    if (moshafName.contains('الدوري عن أبي عمرو')) return 'duri';
    if (moshafName.contains('حفص')) return 'hafs';
    return null;
  }

  static Future<String?> _httpGetText(String url) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.userAgentHeader, 'ItqanQuran/1.0');
      final response = await request.close();
      if (response.statusCode != 200) return null;
      return await response.transform(utf8.decoder).join();
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  /// Fetches & merges the complete 199+ reciter MP3Quran v3 directory + ayat_timing IDs
  static Future<List<HifzReciter>> loadFullCatalog() async {
    if (_isLiveLoaded) return _mergedCatalog;
    try {
      final results = await Future.wait([
        _httpGetText('https://www.mp3quran.net/api/v3/reciters?language=ar'),
        _httpGetText('https://www.mp3quran.net/api/v3/ayat_timing/reads'),
      ]);

      final recJsonStr = results[0];
      final timingJsonStr = results[1];
      if (recJsonStr == null) return _mergedCatalog;

      final Map<String, int> timedByFolder = {};
      if (timingJsonStr != null) {
        final timingList = jsonDecode(timingJsonStr);
        if (timingList is List) {
          for (final item in timingList) {
            if (item is Map && item['folder_url'] != null) {
              final count = int.tryParse(item['soar_count']?.toString() ?? '0') ?? 0;
              if (count >= 114) {
                final folder = item['folder_url'].toString().replaceAll(RegExp(r'/+$'), '');
                final id = int.tryParse(item['id']?.toString() ?? '');
                if (id != null) timedByFolder[folder] = id;
              }
            }
          }
        }
      }

      final existingServers = curatedCore
          .map((r) => r.cdnPattern.replaceAll('{surah:03d}.mp3', '').replaceAll(RegExp(r'/+$'), ''))
          .toSet();
      final existingNames = curatedCore
          .map((r) => "${r.riwayah}:${r.nameAr.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim()}")
          .toSet();

      final decoded = jsonDecode(recJsonStr);
      final recitersList = (decoded is Map ? decoded['reciters'] : null) as List? ?? [];
      final List<HifzReciter> extras = [];

      for (final rec in recitersList) {
        if (rec is! Map) continue;
        final recId = rec['id']?.toString() ?? '';
        final recName = rec['name']?.toString().trim() ?? '';
        final moshafs = rec['moshaf'] as List? ?? [];

        for (final m in moshafs) {
          if (m is! Map) continue;
          final total = int.tryParse(m['surah_total']?.toString() ?? '0') ?? 0;
          final serverRaw = m['server']?.toString() ?? '';
          final mName = m['name']?.toString() ?? '';
          if (total < 114 || serverRaw.isEmpty) continue;

          final riwayah = _mapRiwayah(mName);
          if (riwayah == null) continue;

          final server = serverRaw.replaceAll(RegExp(r'/+$'), '');
          if (existingServers.contains(server)) continue;

          final timedId = timedByFolder[server];
          final audioMode = timedId != null ? 'ayah_timed' : 'surah_stream';
          final isMuallim = mName.contains('معلم') || mName.contains('المعلم');
          final isFast = !isMuallim &&
              (mName.contains('حدر') ||
                  _fastReciterKeywords.any((kw) => recName.contains(kw)));

          final cleanNameKey = '$riwayah:$recName';
          if (audioMode == 'surah_stream' &&
              existingNames.contains(cleanNameKey) &&
              !isMuallim) {
            continue;
          }

          extras.add(
            HifzReciter(
              id: 'mp3q_${recId}_${m['id']}',
              nameAr: recName,
              nameEn: recName,
              riwayah: riwayah,
              style: timedId != null
                  ? '$mName · آية بآية بدون فجوات'
                  : '$mName · سورة كاملة',
              styleCategory: isMuallim ? 'muallim' : (isFast ? 'hadr' : 'murattal'),
              audioMode: audioMode,
              mp3QuranReadId: timedId,
              tempo: isMuallim ? 'slow' : (isFast ? 'fast' : 'medium'),
              cdnPattern: '$server/{surah:03d}.mp3',
              recommendedForHifz: timedId != null || isFast,
              fastFriendly: isFast,
              pedagogicalNote: timedId != null
                  ? 'مصحف كامل (١١٤ سورة) بتوقيت آيات دقيق للحلقة الذهبية'
                  : 'مصحف كامل (١١٤ سورة) للمراجعة المتصلة السريعة حتى 2.0×',
            ),
          );
        }
      }

      _mergedCatalog = [...curatedCore, ...extras];
      _isLiveLoaded = true;
    } catch (_) {}
    return _mergedCatalog;
  }
}
