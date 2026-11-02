/// Production-Ready Reciter Catalog derived from comprehensive research.
/// Covers Hafs, Warsh, Qalun, and Al-Duri across EveryAyah and MP3Quran CDN endpoints.
class HifzReciter {
  final String id;
  final String nameAr;
  final String nameEn;
  final String riwayah; // 'hafs', 'warsh', 'qalun', 'duri'
  final String style;   // 'muallim', 'murattal', 'mujawwad', 'hadr'
  final String tempo;   // 'slow', 'medium', 'fast'
  final int? bitrate;
  final String cdnPattern;
  final bool recommendedForHifz;
  final String? pedagogicalNote;

  const HifzReciter({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.riwayah,
    required this.style,
    required this.tempo,
    this.bitrate,
    required this.cdnPattern,
    this.recommendedForHifz = true,
    this.pedagogicalNote,
  });
}

class QuranRecitersData {
  static const List<HifzReciter> all = [
    // =========================================================================
    // 1. HAFS 'AN 'ASIM (حفص عن عاصم)
    // =========================================================================
    HifzReciter(
      id: 'husary_muallim',
      nameAr: 'محمود خليل الحصري (المعلم)',
      nameEn: 'Mahmoud Khalil Al-Husary (Teacher)',
      riwayah: 'hafs',
      style: 'muallim',
      tempo: 'slow',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/Husary_Muallim_128kbps/{surah:03d}{ayah:03d}.mp3',
      recommendedForHifz: true,
      pedagogicalNote: 'المعيار الذهبي للتحفيظ وضبط مخارج الحروف وأحكام الوقف والابتداء',
    ),
    HifzReciter(
      id: 'husary_murattal',
      nameAr: 'محمود خليل الحصري (مرتل)',
      nameEn: 'Mahmoud Khalil Al-Husary (Murattal)',
      riwayah: 'hafs',
      style: 'murattal',
      tempo: 'slow',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/Husary_128kbps/{surah:03d}{ayah:03d}.mp3',
      recommendedForHifz: true,
      pedagogicalNote: 'تلاوة متزنة هادئة لترسيخ الذاكرة الصوتية في مراحل الربط',
    ),
    HifzReciter(
      id: 'minshawy_teacher',
      nameAr: 'محمد صديق المنشاوي (المعلم)',
      nameEn: 'Mohamed Siddiq Al-Minshawi (Teacher)',
      riwayah: 'hafs',
      style: 'muallim',
      tempo: 'slow',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/Minshawy_Teacher_128kbps/{surah:03d}{ayah:03d}.mp3',
      recommendedForHifz: true,
      pedagogicalNote: 'نبرة خاشعة ونطق بلوري فائق الإتقان مناسب جداً للمبتدئين',
    ),
    HifzReciter(
      id: 'minshawy_murattal',
      nameAr: 'محمد صديق المنشاوي (مرتل)',
      nameEn: 'Mohamed Siddiq Al-Minshawi (Murattal)',
      riwayah: 'hafs',
      style: 'murattal',
      tempo: 'medium',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/Minshawy_Murattal_128kbps/{surah:03d}{ayah:03d}.mp3',
      recommendedForHifz: true,
      pedagogicalNote: 'تلاوة حزينة مؤثرة تزيد من التركيز واستقرار الآيات',
    ),
    HifzReciter(
      id: 'alafasy',
      nameAr: 'مشاري راشد العفاسي',
      nameEn: 'Mishary Rashid Alafasy',
      riwayah: 'hafs',
      style: 'murattal',
      tempo: 'medium',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/Alafasy_128kbps/{surah:03d}{ayah:03d}.mp3',
      recommendedForHifz: true,
      pedagogicalNote: 'إيقاع نغمي عذب وواضح يسهل تذكره في المراجعة السريعة',
    ),
    HifzReciter(
      id: 'abdulbasit_murattal',
      nameAr: 'عبد الباسط عبد الصمد (مرتل)',
      nameEn: 'Abdul Basit Abdus Samad (Murattal)',
      riwayah: 'hafs',
      style: 'murattal',
      tempo: 'medium',
      bitrate: 192,
      cdnPattern: 'https://everyayah.com/data/Abdul_Basit_Murattal_192kbps/{surah:03d}{ayah:03d}.mp3',
      recommendedForHifz: true,
      pedagogicalNote: 'وضوح صوتي متميز ونَفَس طويل يساعد في استيعاب نهايات الآيات',
    ),
    HifzReciter(
      id: 'hudhaify_hafs',
      nameAr: 'علي بن عبد الرحمن الحذيفي',
      nameEn: 'Ali Al-Hudhaify',
      riwayah: 'hafs',
      style: 'murattal',
      tempo: 'slow',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/Hudhaify_128kbps/{surah:03d}{ayah:03d}.mp3',
      recommendedForHifz: true,
      pedagogicalNote: 'تلاوة رصينة محكمة بدون تكلف، ممتازة لمطابقة الحركات وتفخيم الحروف',
    ),
    HifzReciter(
      id: 'basfar',
      nameAr: 'عبد الله بصفر (المعلم)',
      nameEn: 'Abdullah Basfar',
      riwayah: 'hafs',
      style: 'muallim',
      tempo: 'slow',
      bitrate: 192,
      cdnPattern: 'https://everyayah.com/data/Abdullah_Basfar_192kbps/{surah:03d}{ayah:03d}.mp3',
      recommendedForHifz: true,
      pedagogicalNote: 'دقة عالية في المخارج والتجويد وصوت نقي',
    ),
    HifzReciter(
      id: 'ayman_sowaid',
      nameAr: 'أيمن سويد (تجويد تعليمي)',
      nameEn: 'Ayman Sowaid',
      riwayah: 'hafs',
      style: 'muallim',
      tempo: 'slow',
      bitrate: 64,
      cdnPattern: 'https://everyayah.com/data/Ayman_Sowaid_64kbps/{surah:03d}{ayah:03d}.mp3',
      recommendedForHifz: true,
      pedagogicalNote: 'تفكيك تعليمي فائق الدقة لأحكام التجويد والغنن والمدود',
    ),
    HifzReciter(
      id: 'ayyub',
      nameAr: 'محمد أيوب',
      nameEn: 'Muhammad Ayyub',
      riwayah: 'hafs',
      style: 'murattal',
      tempo: 'medium',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/Muhammad_Ayyoub_128kbps/{surah:03d}{ayah:03d}.mp3',
      recommendedForHifz: true,
      pedagogicalNote: 'تلاوة حجازية سلسة تساعد على ترابط المقاطع الطويلة',
    ),
    HifzReciter(
      id: 'shatri',
      nameAr: 'أبو بكر الشاطري',
      nameEn: 'Abu Bakr Al-Shatri',
      riwayah: 'hafs',
      style: 'murattal',
      tempo: 'medium',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/Abu_Bakr_Ash-Shaatree_128kbps/{surah:03d}{ayah:03d}.mp3',
      recommendedForHifz: true,
      pedagogicalNote: 'ترتيل عصري هادئ ومريح للجلسات الممتدة',
    ),
    HifzReciter(
      id: 'maher',
      nameAr: 'ماهر المعيقلي',
      nameEn: 'Maher Al-Muaiqly',
      riwayah: 'hafs',
      style: 'murattal',
      tempo: 'medium',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/MaherAlMuaiqly128kbps/{surah:03d}{ayah:03d}.mp3',
      recommendedForHifz: true,
      pedagogicalNote: 'صوت واضح وتدفق نغمي محبب للأذن',
    ),
    HifzReciter(
      id: 'ghamadi',
      nameAr: 'سعد الغامدي',
      nameEn: 'Saad Al-Ghamdi',
      riwayah: 'hafs',
      style: 'murattal',
      tempo: 'medium',
      bitrate: 40,
      cdnPattern: 'https://everyayah.com/data/Ghamadi_40kbps/{surah:03d}{ayah:03d}.mp3',
      recommendedForHifz: true,
      pedagogicalNote: 'سريع وسلس مناسب لمراجعة المحفوظ وتثبيته',
    ),
    HifzReciter(
      id: 'ibrahim_akhdar',
      nameAr: 'إبراهيم الأخضر',
      nameEn: 'Ibrahim Al-Akhdar',
      riwayah: 'hafs',
      style: 'murattal',
      tempo: 'slow',
      bitrate: 64,
      cdnPattern: 'https://everyayah.com/data/Ibrahim_Akhdar_64kbps/{surah:03d}{ayah:03d}.mp3',
      recommendedForHifz: true,
      pedagogicalNote: 'شيخ قراء المدينة المنورة بأسلوب هادئ ومتقن',
    ),
    HifzReciter(
      id: 'sudais',
      nameAr: 'عبد الرحمن السديس',
      nameEn: 'Abdul Rahman Al-Sudais',
      riwayah: 'hafs',
      style: 'murattal',
      tempo: 'fast',
      bitrate: 192,
      cdnPattern: 'https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/{surah:03d}{ayah:03d}.mp3',
      recommendedForHifz: false,
      pedagogicalNote: 'وتيرة حدر سريعة موجهة للمراجعة المسرعة فقط',
    ),
    HifzReciter(
      id: 'shuraim',
      nameAr: 'سعود الشريم',
      nameEn: 'Saud Al-Shuraim',
      riwayah: 'hafs',
      style: 'hadr',
      tempo: 'fast',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/Shuraym_128kbps/{surah:03d}{ayah:03d}.mp3',
      recommendedForHifz: false,
      pedagogicalNote: 'قراءة حدر سريعة تناسب دورات الحفظ التراكمي ومراجعة الأجزاء',
    ),

    // =========================================================================
    // 2. WARSH 'AN NAFI' (ورش عن نافع)
    // =========================================================================
    HifzReciter(
      id: 'dosary_warsh',
      nameAr: 'إبراهيم الدوسري (ورش)',
      nameEn: 'Ibrahim Al-Dosary (Warsh)',
      riwayah: 'warsh',
      style: 'murattal',
      tempo: 'medium',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/warsh/warsh_ibrahim_aldosary_128kbps/{surah:03d}{ayah:03d}.mp3',
      recommendedForHifz: true,
      pedagogicalNote: 'المرجع الأول لرواية ورش، بأداء منهجي وإظهار دقيق لتقليل الألف والترقيق',
    ),
    HifzReciter(
      id: 'husary_warsh',
      nameAr: 'محمود خليل الحصري (ورش)',
      nameEn: 'Mahmoud Khalil Al-Husary (Warsh)',
      riwayah: 'warsh',
      style: 'murattal',
      tempo: 'slow',
      bitrate: 128,
      cdnPattern: 'https://verse.mp3quran.net/arabic/husary_warsh/{surah:03d}{ayah:03d}.mp3',
      recommendedForHifz: true,
      pedagogicalNote: 'التلاوة المرجعية المتقنة لرواية ورش من طريق الأزرق برزانة المشايخ الكبار',
    ),
    HifzReciter(
      id: 'yassin_warsh',
      nameAr: 'ياسين الجزائري (ورش)',
      nameEn: 'Yassin Al-Jazaery (Warsh)',
      riwayah: 'warsh',
      style: 'murattal',
      tempo: 'medium',
      bitrate: 64,
      cdnPattern: 'https://everyayah.com/data/warsh/warsh_yassin_al_jazaery_64kbps/{surah:03d}{ayah:03d}.mp3',
      recommendedForHifz: true,
      pedagogicalNote: 'التلاوة المغاربية الأصيلة بأسلوب جزائري عذب ومنضبط',
    ),
    HifzReciter(
      id: 'abdulbasit_warsh',
      nameAr: 'عبد الباسط عبد الصمد (ورش)',
      nameEn: 'Abdul Basit Abdus Samad (Warsh)',
      riwayah: 'warsh',
      style: 'murattal',
      tempo: 'medium',
      bitrate: 128,
      cdnPattern: 'https://everyayah.com/data/warsh/warsh_Abdul_Basit_128kbps/{surah:03d}{ayah:03d}.mp3',
      recommendedForHifz: true,
      pedagogicalNote: 'تلاوة نادرة خاشعة برواية ورش بصوت الشيخ عبد الباسط المميز',
    ),

    // =========================================================================
    // 3. QALUN 'AN NAFI' (قالون عن نافع)
    // =========================================================================
    HifzReciter(
      id: 'hudhaify_qalun',
      nameAr: 'علي بن عبد الرحمن الحذيفي (قالون)',
      nameEn: 'Ali Al-Hudhaify (Qalun)',
      riwayah: 'qalun',
      style: 'murattal',
      tempo: 'slow',
      bitrate: 128,
      cdnPattern: 'https://verse.mp3quran.net/arabic/hudhaify_qalun/{surah:03d}{ayah:03d}.mp3',
      recommendedForHifz: true,
      pedagogicalNote: 'مرجع أصيل لرواية قالون مع إسكان وصلة ميم الجمع بوضوح ناصع',
    ),
    HifzReciter(
      id: 'husary_qalun',
      nameAr: 'محمود خليل الحصري (قالون)',
      nameEn: 'Mahmoud Khalil Al-Husary (Qalun)',
      riwayah: 'qalun',
      style: 'murattal',
      tempo: 'slow',
      bitrate: 128,
      cdnPattern: 'https://verse.mp3quran.net/arabic/husary_qalun/{surah:03d}{ayah:03d}.mp3',
      recommendedForHifz: true,
      pedagogicalNote: 'تحقيق وتدقيق مشايخ المقارئ المصرية لرواية قالون عن نافع',
    ),
    HifzReciter(
      id: 'dokali_qalun',
      nameAr: 'محمد العالم الدوكالي (قالون)',
      nameEn: 'Muhammad Al-Dokali (Qalun)',
      riwayah: 'qalun',
      style: 'murattal',
      tempo: 'medium',
      bitrate: 128,
      cdnPattern: 'https://verse.mp3quran.net/arabic/dokali/{surah:03d}{ayah:03d}.mp3',
      recommendedForHifz: true,
      pedagogicalNote: 'التلاوة الليبية الشهيرة برواية قالون واسعة الانتشار في شمال إفريقيا',
    ),

    // =========================================================================
    // 4. AL-DURI 'AN ABI 'AMR (الدوري عن أبي عمرو)
    // =========================================================================
    HifzReciter(
      id: 'husary_duri',
      nameAr: 'محمود خليل الحصري (الدوري عن أبي عمرو)',
      nameEn: 'Mahmoud Khalil Al-Husary (Al-Duri)',
      riwayah: 'duri',
      style: 'murattal',
      tempo: 'slow',
      bitrate: 128,
      cdnPattern: 'https://verse.mp3quran.net/arabic/husary_duri/{surah:03d}{ayah:03d}.mp3',
      recommendedForHifz: true,
      pedagogicalNote: 'التلاوة المرجعية النادرة لرواية الدوري مع الإدغام الكبير والإمالة',
    ),
  ];

  static List<HifzReciter> getByRiwayah(String riwayah) {
    return all.where((r) => r.riwayah == riwayah).toList();
  }

  static HifzReciter getDefault(String riwayah) {
    final list = getByRiwayah(riwayah);
    return list.isNotEmpty ? list.first : all.first;
  }
}
