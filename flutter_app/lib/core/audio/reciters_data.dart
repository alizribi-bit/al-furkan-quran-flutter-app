class HifzReciter {
  final String id;
  final String nameAr;
  final String nameEn;
  final String riwayah; // 'hafs', 'warsh', 'qalun'
  final String style;
  final String cdnPattern;

  const HifzReciter({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.riwayah,
    required this.style,
    required this.cdnPattern,
  });
}

class QuranRecitersData {
  static const List<HifzReciter> all = [
    // --- HAFS ---
    HifzReciter(
      id: 'husary_muallim',
      nameAr: 'محمود خليل الحصري (المعلم)',
      nameEn: 'Al-Husary (Muallim)',
      riwayah: 'hafs',
      style: 'معلم مع الوقف المتقن',
      cdnPattern: 'https://everyayah.com/data/Husary_Muallim_128kbps/{surah:03d}{ayah:03d}.mp3',
    ),
    HifzReciter(
      id: 'minshawy',
      nameAr: 'محمد صديق المنشاوي (مرتل)',
      nameEn: 'Al-Minshawy (Murattal)',
      riwayah: 'hafs',
      style: 'مرتل خاشع ومؤثر',
      cdnPattern: 'https://everyayah.com/data/Minshawy_Murattal_128kbps/{surah:03d}{ayah:03d}.mp3',
    ),
    HifzReciter(
      id: 'alafasy',
      nameAr: 'مشاري راشد العفاسي',
      nameEn: 'Mishary Rashid Alafasy',
      riwayah: 'hafs',
      style: 'مرتل واضح وعذب',
      cdnPattern: 'https://everyayah.com/data/Alafasy_128kbps/{surah:03d}{ayah:03d}.mp3',
    ),
    HifzReciter(
      id: 'abdul_basit',
      nameAr: 'عبد الباسط عبد الصمد (مرتل)',
      nameEn: 'Abdul Basit Murattal',
      riwayah: 'hafs',
      style: 'مرتل بنبرة بديعة',
      cdnPattern: 'https://everyayah.com/data/Abdul_Basit_Murattal_192kbps/{surah:03d}{ayah:03d}.mp3',
    ),
    HifzReciter(
      id: 'husary_murattal',
      nameAr: 'محمود خليل الحصري (مرتل)',
      nameEn: 'Al-Husary (Murattal)',
      riwayah: 'hafs',
      style: 'مرتل متمكن ومخارج دقيقة',
      cdnPattern: 'https://everyayah.com/data/Husary_128kbps/{surah:03d}{ayah:03d}.mp3',
    ),
    HifzReciter(
      id: 'ghamadi',
      nameAr: 'سعد الغامدي',
      nameEn: 'Saad Al-Ghamadi',
      riwayah: 'hafs',
      style: 'مرتل سريع وواضح',
      cdnPattern: 'https://everyayah.com/data/Ghamadi_40kbps/{surah:03d}{ayah:03d}.mp3',
    ),
    HifzReciter(
      id: 'ayman_sowaid',
      nameAr: 'أيمن سويد (تجويد تعليمي)',
      nameEn: 'Ayman Sowaid',
      riwayah: 'hafs',
      style: 'تجويد تعليمي بمخارج الحروف',
      cdnPattern: 'https://everyayah.com/data/Ayman_Sowaid_64kbps/{surah:03d}{ayah:03d}.mp3',
    ),

    // --- WARSH ---
    HifzReciter(
      id: 'warsh_ibrahim_aldosary',
      nameAr: 'إبراهيم الدوسري (ورش)',
      nameEn: 'Ibrahim Al-Dosary (Warsh)',
      riwayah: 'warsh',
      style: 'رواية ورش عن نافع بإتقان',
      cdnPattern: 'https://everyayah.com/data/warsh/warsh_ibrahim_aldosary_128kbps/{surah:03d}{ayah:03d}.mp3',
    ),
    HifzReciter(
      id: 'warsh_abdul_basit',
      nameAr: 'عبد الباسط عبد الصمد (ورش)',
      nameEn: 'Abdul Basit (Warsh)',
      riwayah: 'warsh',
      style: 'رواية ورش بصوت خاشع',
      cdnPattern: 'https://everyayah.com/data/warsh/warsh_Abdul_Basit_128kbps/{surah:03d}{ayah:03d}.mp3',
    ),
    HifzReciter(
      id: 'warsh_yassin_al_jazaery',
      nameAr: 'ياسين الجزائري (ورش)',
      nameEn: 'Yassin Al-Jazaery (Warsh)',
      riwayah: 'warsh',
      style: 'رواية ورش بالطريقة المغاربية',
      cdnPattern: 'https://everyayah.com/data/warsh/warsh_yassin_al_jazaery_64kbps/{surah:03d}{ayah:03d}.mp3',
    ),

    // --- QALUN ---
    HifzReciter(
      id: 'qalun_ali_hudhaifi',
      nameAr: 'علي بن عبد الرحمن الحذيفي (قالون)',
      nameEn: 'Ali Al-Hudhaify (Qalun)',
      riwayah: 'qalun',
      style: 'رواية قالون عن نافع برزانة',
      cdnPattern: 'https://everyayah.com/data/Hudhaify_128kbps/{surah:03d}{ayah:03d}.mp3',
    ),
    HifzReciter(
      id: 'qalun_husary',
      nameAr: 'محمود خليل الحصري (قالون)',
      nameEn: 'Al-Husary (Qalun)',
      riwayah: 'qalun',
      style: 'رواية قالون بتدقيق المشايخ',
      cdnPattern: 'https://everyayah.com/data/Husary_128kbps/{surah:03d}{ayah:03d}.mp3',
    ),
    HifzReciter(
      id: 'qalun_dokali',
      nameAr: 'محمد العالم الدوكالي (قالون)',
      nameEn: 'Muhammad Al-Dokali (Qalun)',
      riwayah: 'qalun',
      style: 'رواية قالون تلاوة ليبية أصيلة',
      cdnPattern: 'https://everyayah.com/data/Hudhaify_128kbps/{surah:03d}{ayah:03d}.mp3',
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
