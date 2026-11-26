// Generated Surah metadata and script loader
import 'dart:convert';
import 'package:flutter/services.dart';

class SurahInfo {
  final int number;
  final String nameAr;
  final String nameEn;
  final String nameTranslation;
  final int versesCount;
  final String revelationType;

  const SurahInfo({
    required this.number,
    required this.nameAr,
    required this.nameEn,
    required this.nameTranslation,
    required this.versesCount,
    required this.revelationType,
  });
}

class QuranSurahs {
  static const List<SurahInfo> list = [
    SurahInfo(number: 1, nameAr: 'الفَاتِحَة', nameEn: 'Al-Fatihah', nameTranslation: 'The Opening', versesCount: 7, revelationType: 'Meccan'),
    SurahInfo(number: 2, nameAr: 'البَقَرَة', nameEn: 'Al-Baqarah', nameTranslation: 'The Cow', versesCount: 286, revelationType: 'Medinan'),
    SurahInfo(number: 3, nameAr: 'آلِ عِمْرَان', nameEn: 'Ali \'Imran', nameTranslation: 'Family of Imran', versesCount: 200, revelationType: 'Medinan'),
    SurahInfo(number: 4, nameAr: 'النِّسَاء', nameEn: 'An-Nisa', nameTranslation: 'The Women', versesCount: 176, revelationType: 'Medinan'),
    SurahInfo(number: 5, nameAr: 'المَائِدَة', nameEn: 'Al-Ma\'idah', nameTranslation: 'The Table Spread', versesCount: 120, revelationType: 'Medinan'),
    SurahInfo(number: 6, nameAr: 'الأَنْعَام', nameEn: 'Al-An\'am', nameTranslation: 'The Cattle', versesCount: 165, revelationType: 'Meccan'),
    SurahInfo(number: 7, nameAr: 'الأَعْرَاف', nameEn: 'Al-A\'raf', nameTranslation: 'The Heights', versesCount: 206, revelationType: 'Meccan'),
    SurahInfo(number: 8, nameAr: 'الأَنْفَال', nameEn: 'Al-Anfal', nameTranslation: 'The Spoils of War', versesCount: 75, revelationType: 'Medinan'),
    SurahInfo(number: 9, nameAr: 'التَّوْبَة', nameEn: 'At-Tawbah', nameTranslation: 'The Repentance', versesCount: 129, revelationType: 'Medinan'),
    SurahInfo(number: 10, nameAr: 'يُونُس', nameEn: 'Yunus', nameTranslation: 'Jonah', versesCount: 109, revelationType: 'Meccan'),
    SurahInfo(number: 11, nameAr: 'هُود', nameEn: 'Hud', nameTranslation: 'Hud', versesCount: 123, revelationType: 'Meccan'),
    SurahInfo(number: 12, nameAr: 'يُوسُف', nameEn: 'Yusuf', nameTranslation: 'Joseph', versesCount: 111, revelationType: 'Meccan'),
    SurahInfo(number: 13, nameAr: 'الرَّعْد', nameEn: 'Ar-Ra\'d', nameTranslation: 'The Thunder', versesCount: 43, revelationType: 'Medinan'),
    SurahInfo(number: 14, nameAr: 'إِبْرَاهِيم', nameEn: 'Ibrahim', nameTranslation: 'Abraham', versesCount: 52, revelationType: 'Meccan'),
    SurahInfo(number: 15, nameAr: 'الحِجْر', nameEn: 'Al-Hijr', nameTranslation: 'The Rocky Tract', versesCount: 99, revelationType: 'Meccan'),
    SurahInfo(number: 16, nameAr: 'النَّحْل', nameEn: 'An-Nahl', nameTranslation: 'The Bee', versesCount: 128, revelationType: 'Meccan'),
    SurahInfo(number: 17, nameAr: 'الإِسْرَاء', nameEn: 'Al-Isra', nameTranslation: 'The Night Journey', versesCount: 111, revelationType: 'Meccan'),
    SurahInfo(number: 18, nameAr: 'الكَهْف', nameEn: 'Al-Kahf', nameTranslation: 'The Cave', versesCount: 110, revelationType: 'Meccan'),
    SurahInfo(number: 19, nameAr: 'مَرْيَم', nameEn: 'Maryam', nameTranslation: 'Mary', versesCount: 98, revelationType: 'Meccan'),
    SurahInfo(number: 20, nameAr: 'طه', nameEn: 'Taha', nameTranslation: 'Ta-Ha', versesCount: 135, revelationType: 'Meccan'),
    SurahInfo(number: 21, nameAr: 'الأَنْبِيَاء', nameEn: 'Al-Anbiya', nameTranslation: 'The Prophets', versesCount: 112, revelationType: 'Meccan'),
    SurahInfo(number: 22, nameAr: 'الحَجّ', nameEn: 'Al-Hajj', nameTranslation: 'The Pilgrimage', versesCount: 78, revelationType: 'Medinan'),
    SurahInfo(number: 23, nameAr: 'المُؤْمِنُون', nameEn: 'Al-Mu\'minun', nameTranslation: 'The Believers', versesCount: 118, revelationType: 'Meccan'),
    SurahInfo(number: 24, nameAr: 'النُّور', nameEn: 'An-Nur', nameTranslation: 'The Light', versesCount: 64, revelationType: 'Medinan'),
    SurahInfo(number: 25, nameAr: 'الفُرْقَان', nameEn: 'Al-Furqan', nameTranslation: 'The Criterion', versesCount: 77, revelationType: 'Meccan'),
    SurahInfo(number: 26, nameAr: 'الشُّعَرَاء', nameEn: 'Ash-Shu\'ara', nameTranslation: 'The Poets', versesCount: 227, revelationType: 'Meccan'),
    SurahInfo(number: 27, nameAr: 'النَّمْل', nameEn: 'An-Naml', nameTranslation: 'The Ant', versesCount: 93, revelationType: 'Meccan'),
    SurahInfo(number: 28, nameAr: 'القَصَص', nameEn: 'Al-Qasas', nameTranslation: 'The Stories', versesCount: 88, revelationType: 'Meccan'),
    SurahInfo(number: 29, nameAr: 'العَنْكَبُوت', nameEn: 'Al-\'Ankabut', nameTranslation: 'The Spider', versesCount: 69, revelationType: 'Meccan'),
    SurahInfo(number: 30, nameAr: 'الرُّوم', nameEn: 'Ar-Rum', nameTranslation: 'The Romans', versesCount: 60, revelationType: 'Meccan'),
    SurahInfo(number: 31, nameAr: 'لُقْمَان', nameEn: 'Luqman', nameTranslation: 'Luqman', versesCount: 34, revelationType: 'Meccan'),
    SurahInfo(number: 32, nameAr: 'السَّجْدَة', nameEn: 'As-Sajdah', nameTranslation: 'The Prostration', versesCount: 30, revelationType: 'Meccan'),
    SurahInfo(number: 33, nameAr: 'الأَحْزَاب', nameEn: 'Al-Ahzab', nameTranslation: 'The Combined Forces', versesCount: 73, revelationType: 'Medinan'),
    SurahInfo(number: 34, nameAr: 'سَبَأ', nameEn: 'Saba', nameTranslation: 'Sheba', versesCount: 54, revelationType: 'Meccan'),
    SurahInfo(number: 35, nameAr: 'فَاطِر', nameEn: 'Fatir', nameTranslation: 'The Originator', versesCount: 45, revelationType: 'Meccan'),
    SurahInfo(number: 36, nameAr: 'يس', nameEn: 'Ya-Sin', nameTranslation: 'Ya-Sin', versesCount: 83, revelationType: 'Meccan'),
    SurahInfo(number: 37, nameAr: 'الصَّافَّات', nameEn: 'As-Saffat', nameTranslation: 'Those Ranged in Ranks', versesCount: 182, revelationType: 'Meccan'),
    SurahInfo(number: 38, nameAr: 'ص', nameEn: 'Sad', nameTranslation: 'Sad', versesCount: 88, revelationType: 'Meccan'),
    SurahInfo(number: 39, nameAr: 'الزُّمَر', nameEn: 'Az-Zumar', nameTranslation: 'The Groups', versesCount: 75, revelationType: 'Meccan'),
    SurahInfo(number: 40, nameAr: 'غَافِر', nameEn: 'Ghafir', nameTranslation: 'The Forgiver', versesCount: 85, revelationType: 'Meccan'),
    SurahInfo(number: 41, nameAr: 'فُصِّلَت', nameEn: 'Fussilat', nameTranslation: 'Explained in Detail', versesCount: 54, revelationType: 'Meccan'),
    SurahInfo(number: 42, nameAr: 'الشُّورَى', nameEn: 'Ash-Shura', nameTranslation: 'The Consultation', versesCount: 53, revelationType: 'Meccan'),
    SurahInfo(number: 43, nameAr: 'الزُّخْرُف', nameEn: 'Az-Zukhruf', nameTranslation: 'The Ornaments of Gold', versesCount: 89, revelationType: 'Meccan'),
    SurahInfo(number: 44, nameAr: 'الدُّخَان', nameEn: 'Ad-Dukhan', nameTranslation: 'The Smoke', versesCount: 59, revelationType: 'Meccan'),
    SurahInfo(number: 45, nameAr: 'الجَاثِيَة', nameEn: 'Al-Jathiyah', nameTranslation: 'The Crouching', versesCount: 37, revelationType: 'Meccan'),
    SurahInfo(number: 46, nameAr: 'الأَحْقَاف', nameEn: 'Al-Ahqaf', nameTranslation: 'The Wind-Curved Sandhills', versesCount: 35, revelationType: 'Meccan'),
    SurahInfo(number: 47, nameAr: 'مُحَمَّد', nameEn: 'Muhammad', nameTranslation: 'Muhammad', versesCount: 38, revelationType: 'Medinan'),
    SurahInfo(number: 48, nameAr: 'الفَتْح', nameEn: 'Al-Fath', nameTranslation: 'The Victory', versesCount: 29, revelationType: 'Medinan'),
    SurahInfo(number: 49, nameAr: 'الحُجُرَات', nameEn: 'Al-Hujurat', nameTranslation: 'The Rooms', versesCount: 18, revelationType: 'Medinan'),
    SurahInfo(number: 50, nameAr: 'ق', nameEn: 'Qaf', nameTranslation: 'Qaf', versesCount: 45, revelationType: 'Meccan'),
    SurahInfo(number: 51, nameAr: 'الذَّارِيَات', nameEn: 'Adh-Dhariyat', nameTranslation: 'The Winnowing Winds', versesCount: 60, revelationType: 'Meccan'),
    SurahInfo(number: 52, nameAr: 'الطُّور', nameEn: 'At-Tur', nameTranslation: 'The Mount', versesCount: 49, revelationType: 'Meccan'),
    SurahInfo(number: 53, nameAr: 'النَّجْم', nameEn: 'An-Najm', nameTranslation: 'The Star', versesCount: 62, revelationType: 'Meccan'),
    SurahInfo(number: 54, nameAr: 'القَمَر', nameEn: 'Al-Qamar', nameTranslation: 'The Moon', versesCount: 55, revelationType: 'Meccan'),
    SurahInfo(number: 55, nameAr: 'الرَّحْمَٰن', nameEn: 'Ar-Rahman', nameTranslation: 'The Beneficent', versesCount: 78, revelationType: 'Medinan'),
    SurahInfo(number: 56, nameAr: 'الوَاقِعَة', nameEn: 'Al-Waqi\'ah', nameTranslation: 'The Inevitable', versesCount: 96, revelationType: 'Meccan'),
    SurahInfo(number: 57, nameAr: 'الحَدِيد', nameEn: 'Al-Hadid', nameTranslation: 'The Iron', versesCount: 29, revelationType: 'Medinan'),
    SurahInfo(number: 58, nameAr: 'المُجَادِلَة', nameEn: 'Al-Mujadila', nameTranslation: 'The Pleading Woman', versesCount: 22, revelationType: 'Medinan'),
    SurahInfo(number: 59, nameAr: 'الحَشْر', nameEn: 'Al-Hashr', nameTranslation: 'The Exile', versesCount: 24, revelationType: 'Medinan'),
    SurahInfo(number: 60, nameAr: 'المُمْتَحَنَة', nameEn: 'Al-Mumtahanah', nameTranslation: 'She that is to be examined', versesCount: 13, revelationType: 'Medinan'),
    SurahInfo(number: 61, nameAr: 'الصَّفّ', nameEn: 'As-Saf', nameTranslation: 'The Ranks', versesCount: 14, revelationType: 'Medinan'),
    SurahInfo(number: 62, nameAr: 'الجُمُعَة', nameEn: 'Al-Jumu\'ah', nameTranslation: 'The Congregation', versesCount: 11, revelationType: 'Medinan'),
    SurahInfo(number: 63, nameAr: 'المُنَافِقُون', nameEn: 'Al-Munafiqun', nameTranslation: 'The Hypocrites', versesCount: 11, revelationType: 'Medinan'),
    SurahInfo(number: 64, nameAr: 'التَّغَابُن', nameEn: 'At-Taghabun', nameTranslation: 'The Mutual Disillusion', versesCount: 18, revelationType: 'Medinan'),
    SurahInfo(number: 65, nameAr: 'الطَّلَاق', nameEn: 'At-Talaq', nameTranslation: 'The Divorce', versesCount: 12, revelationType: 'Medinan'),
    SurahInfo(number: 66, nameAr: 'التَّحْرِيم', nameEn: 'At-Tahrim', nameTranslation: 'The Prohibition', versesCount: 12, revelationType: 'Medinan'),
    SurahInfo(number: 67, nameAr: 'المُلْك', nameEn: 'Al-Mulk', nameTranslation: 'The Sovereignty', versesCount: 30, revelationType: 'Meccan'),
    SurahInfo(number: 68, nameAr: 'القَلَم', nameEn: 'Al-Qalam', nameTranslation: 'The Pen', versesCount: 52, revelationType: 'Meccan'),
    SurahInfo(number: 69, nameAr: 'الحَاقَّة', nameEn: 'Al-Haqqah', nameTranslation: 'The Reality', versesCount: 52, revelationType: 'Meccan'),
    SurahInfo(number: 70, nameAr: 'المَعَارِج', nameEn: 'Al-Ma\'arij', nameTranslation: 'The Ascending Stairways', versesCount: 44, revelationType: 'Meccan'),
    SurahInfo(number: 71, nameAr: 'نُوح', nameEn: 'Nuh', nameTranslation: 'Noah', versesCount: 28, revelationType: 'Meccan'),
    SurahInfo(number: 72, nameAr: 'الجِنّ', nameEn: 'Al-Jinn', nameTranslation: 'The Jinn', versesCount: 28, revelationType: 'Meccan'),
    SurahInfo(number: 73, nameAr: 'المُزَّمِّل', nameEn: 'Al-Muzzammil', nameTranslation: 'The Enshrouded One', versesCount: 20, revelationType: 'Meccan'),
    SurahInfo(number: 74, nameAr: 'المُدَّثِّر', nameEn: 'Al-Muddaththir', nameTranslation: 'The Cloaked One', versesCount: 56, revelationType: 'Meccan'),
    SurahInfo(number: 75, nameAr: 'القِيَامَة', nameEn: 'Al-Qiyamah', nameTranslation: 'The Resurrection', versesCount: 40, revelationType: 'Meccan'),
    SurahInfo(number: 76, nameAr: 'الإِنْسَان', nameEn: 'Al-Insan', nameTranslation: 'Man', versesCount: 31, revelationType: 'Medinan'),
    SurahInfo(number: 77, nameAr: 'المُرْسَلَات', nameEn: 'Al-Mursalat', nameTranslation: 'The Emissaries', versesCount: 50, revelationType: 'Meccan'),
    SurahInfo(number: 78, nameAr: 'النَّبَأ', nameEn: 'An-Naba', nameTranslation: 'The Tidings', versesCount: 40, revelationType: 'Meccan'),
    SurahInfo(number: 79, nameAr: 'النَّازِعَات', nameEn: 'An-Nazi\'at', nameTranslation: 'Those who drag forth', versesCount: 46, revelationType: 'Meccan'),
    SurahInfo(number: 80, nameAr: 'عَبَسَ', nameEn: '\'Abasa', nameTranslation: 'He Frowned', versesCount: 42, revelationType: 'Meccan'),
    SurahInfo(number: 81, nameAr: 'التَّكْوِير', nameEn: 'At-Takwir', nameTranslation: 'The Overthrowing', versesCount: 29, revelationType: 'Meccan'),
    SurahInfo(number: 82, nameAr: 'الانْفِطَار', nameEn: 'Al-Infitar', nameTranslation: 'The Cleaving', versesCount: 19, revelationType: 'Meccan'),
    SurahInfo(number: 83, nameAr: 'المُطَفِّفِين', nameEn: 'Al-Mutaffifin', nameTranslation: 'The Defrauding', versesCount: 36, revelationType: 'Meccan'),
    SurahInfo(number: 84, nameAr: 'الانْشِقَاق', nameEn: 'Al-Inshiqaq', nameTranslation: 'The Splitting Open', versesCount: 25, revelationType: 'Meccan'),
    SurahInfo(number: 85, nameAr: 'البُرُوج', nameEn: 'Al-Buruj', nameTranslation: 'The Mansions of the Stars', versesCount: 22, revelationType: 'Meccan'),
    SurahInfo(number: 86, nameAr: 'الطَّارِق', nameEn: 'At-Tariq', nameTranslation: 'The Morning Star', versesCount: 17, revelationType: 'Meccan'),
    SurahInfo(number: 87, nameAr: 'الأَعْلَىٰ', nameEn: 'Al-A\'la', nameTranslation: 'The Most High', versesCount: 19, revelationType: 'Meccan'),
    SurahInfo(number: 88, nameAr: 'الغَاشِيَة', nameEn: 'Al-Ghashiyah', nameTranslation: 'The Overwhelming', versesCount: 26, revelationType: 'Meccan'),
    SurahInfo(number: 89, nameAr: 'الفَجْر', nameEn: 'Al-Fajr', nameTranslation: 'The Dawn', versesCount: 30, revelationType: 'Meccan'),
    SurahInfo(number: 90, nameAr: 'البَلَد', nameEn: 'Al-Balad', nameTranslation: 'The City', versesCount: 20, revelationType: 'Meccan'),
    SurahInfo(number: 91, nameAr: 'الشَّمْس', nameEn: 'Ash-Shams', nameTranslation: 'The Sun', versesCount: 15, revelationType: 'Meccan'),
    SurahInfo(number: 92, nameAr: 'اللَّيْل', nameEn: 'Al-Layl', nameTranslation: 'The Night', versesCount: 21, revelationType: 'Meccan'),
    SurahInfo(number: 93, nameAr: 'الضُّحَىٰ', nameEn: 'Ad-Duha', nameTranslation: 'The Morning Hours', versesCount: 11, revelationType: 'Meccan'),
    SurahInfo(number: 94, nameAr: 'الشَّرْح', nameEn: 'Ash-Sharh', nameTranslation: 'The Relief', versesCount: 8, revelationType: 'Meccan'),
    SurahInfo(number: 95, nameAr: 'التِّين', nameEn: 'At-Tin', nameTranslation: 'The Fig', versesCount: 8, revelationType: 'Meccan'),
    SurahInfo(number: 96, nameAr: 'العَلَق', nameEn: 'Al-\'Alaq', nameTranslation: 'The Clot', versesCount: 19, revelationType: 'Meccan'),
    SurahInfo(number: 97, nameAr: 'القَدْر', nameEn: 'Al-Qadr', nameTranslation: 'The Power', versesCount: 5, revelationType: 'Meccan'),
    SurahInfo(number: 98, nameAr: 'البَيِّنَة', nameEn: 'Al-Bayyinah', nameTranslation: 'The Clear Proof', versesCount: 8, revelationType: 'Medinan'),
    SurahInfo(number: 99, nameAr: 'الزَّلْزَلَة', nameEn: 'Az-Zalzalah', nameTranslation: 'The Earthquake', versesCount: 8, revelationType: 'Medinan'),
    SurahInfo(number: 100, nameAr: 'العَادِيَات', nameEn: 'Al-\'Adiyat', nameTranslation: 'The Courser', versesCount: 11, revelationType: 'Meccan'),
    SurahInfo(number: 101, nameAr: 'القَارِعَة', nameEn: 'Al-Qari\'ah', nameTranslation: 'The Calamity', versesCount: 11, revelationType: 'Meccan'),
    SurahInfo(number: 102, nameAr: 'التَّكَاثُر', nameEn: 'At-Takathur', nameTranslation: 'The Rivalry in World Increase', versesCount: 8, revelationType: 'Meccan'),
    SurahInfo(number: 103, nameAr: 'العَصْر', nameEn: 'Al-\'Asr', nameTranslation: 'The Declining Day', versesCount: 3, revelationType: 'Meccan'),
    SurahInfo(number: 104, nameAr: 'الهُمَزَة', nameEn: 'Al-Humazah', nameTranslation: 'The Traducer', versesCount: 9, revelationType: 'Meccan'),
    SurahInfo(number: 105, nameAr: 'الفِيل', nameEn: 'Al-Fil', nameTranslation: 'The Elephant', versesCount: 5, revelationType: 'Meccan'),
    SurahInfo(number: 106, nameAr: 'قُرَيْش', nameEn: 'Quraysh', nameTranslation: 'Quraysh', versesCount: 4, revelationType: 'Meccan'),
    SurahInfo(number: 107, nameAr: 'المَاعُون', nameEn: 'Al-Ma\'un', nameTranslation: 'The Small Kindnesses', versesCount: 7, revelationType: 'Meccan'),
    SurahInfo(number: 108, nameAr: 'الكَوْثَر', nameEn: 'Al-Kawthar', nameTranslation: 'The Abundance', versesCount: 3, revelationType: 'Meccan'),
    SurahInfo(number: 109, nameAr: 'الكَافِرُون', nameEn: 'Al-Kafirun', nameTranslation: 'The Disbelievers', versesCount: 6, revelationType: 'Meccan'),
    SurahInfo(number: 110, nameAr: 'النَّصْر', nameEn: 'An-Nasr', nameTranslation: 'The Divine Support', versesCount: 3, revelationType: 'Medinan'),
    SurahInfo(number: 111, nameAr: 'المَسَد', nameEn: 'Al-Masad', nameTranslation: 'The Palm Fiber', versesCount: 5, revelationType: 'Meccan'),
    SurahInfo(number: 112, nameAr: 'الإِخْلَاص', nameEn: 'Al-Ikhlas', nameTranslation: 'The Sincerity', versesCount: 4, revelationType: 'Meccan'),
    SurahInfo(number: 113, nameAr: 'الفَلَق', nameEn: 'Al-Falaq', nameTranslation: 'The Daybreak', versesCount: 5, revelationType: 'Meccan'),
    SurahInfo(number: 114, nameAr: 'النَّاس', nameEn: 'An-Nas', nameTranslation: 'Mankind', versesCount: 6, revelationType: 'Meccan'),
  ];

  static SurahInfo getByNumber(int num) {
    return list.firstWhere(
      (s) => s.number == num,
      orElse: () => list.first,
    );
  }
}

class QuranScriptService {
  static final Map<String, Map<String, dynamic>> _cache = {};

  static Future<List<Map<String, dynamic>>> getVersesForSurah({
    required int surahNumber,
    required String riwayah, // 'hafs', 'warsh', 'qalun'
  }) async {
    String filename;
    if (riwayah == 'warsh') {
      filename = 'assets/quran_script/Warsh.json';
    } else if (riwayah == 'qalun') {
      filename = 'assets/quran_script/Qalun.json';
    } else {
      filename = 'assets/quran_script/Uthmani.json';
    }

    if (!_cache.containsKey(filename)) {
      final jsonStr = await rootBundle.loadString(filename);
      _cache[filename] = jsonDecode(jsonStr) as Map<String, dynamic>;
    }

    final data = _cache[filename]!;
    final surahKey = surahNumber.toString();
    final surahMap = data[surahKey] as Map<String, dynamic>? ?? {};

    final List<Map<String, dynamic>> verses = [];
    final ayahKeys = surahMap.keys.map((k) => int.tryParse(k) ?? 0).where((n) => n > 0).toList()..sort();

    for (final num in ayahKeys) {
      final words = surahMap[num.toString()];
      String text = '';
      if (words is List) {
        text = words.join(' ');
      } else if (words is String) {
        text = words;
      }
      verses.add({'num': num, 'text': text});
    }

    return verses;
  }
}
