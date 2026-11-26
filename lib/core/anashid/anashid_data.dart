import 'dart:convert';
import 'dart:io';

class NasheedTrack {
  final String id;
  final String title;
  final String artist;
  final String category; // quran_munajat | zuhd | prophetic | hope | children
  final int? durationSec;
  final String audioUrl;
  final String archiveId;

  const NasheedTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.category,
    this.durationSec,
    required this.audioUrl,
    required this.archiveId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'category': category,
        'durationSec': durationSec,
        'audioUrl': audioUrl,
        'archiveId': archiveId,
      };

  factory NasheedTrack.fromJson(Map<String, dynamic> json) => NasheedTrack(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        artist: json['artist']?.toString() ?? '',
        category: json['category']?.toString() ?? 'zuhd',
        durationSec: json['durationSec'] is int
            ? json['durationSec'] as int
            : int.tryParse(json['durationSec']?.toString() ?? ''),
        audioUrl: json['audioUrl']?.toString() ?? '',
        archiveId: json['archiveId']?.toString() ?? '',
      );
}

class VocalCollection {
  final String id;
  final String archiveId;
  final String title;
  final String subtitle;
  final String trackCountLabel;
  final String defaultArtist;
  final String defaultCategory;

  const VocalCollection({
    required this.id,
    required this.archiveId,
    required this.title,
    required this.subtitle,
    required this.trackCountLabel,
    required this.defaultArtist,
    required this.defaultCategory,
  });
}

class ArchiveSearchItem {
  final String archiveId;
  final String title;
  final String creator;

  const ArchiveSearchItem({
    required this.archiveId,
    required this.title,
    required this.creator,
  });
}

String _iaUrl(String identifier, String filename) {
  return 'https://archive.org/download/${Uri.encodeComponent(identifier)}/${Uri.encodeComponent(filename)}';
}

class AnashidRepository {
  static const List<(String, String)> categories = [
    ('all', 'الكل'),
    ('quran_munajat', 'القرآن والمناجاة'),
    ('zuhd', 'الزهد والرقائق'),
    ('prophetic', 'مدح النبي ﷺ'),
    ('hope', 'الأمل والهمة'),
    ('children', 'للأطفال والأسرة'),
  ];

  static final List<NasheedTrack> curatedTracks = [
    // 1. القرآن والمناجاة
    NasheedTrack(
      id: 'cur_kitab_allah',
      title: 'كتاب الله',
      artist: 'مجموعة منشدين · بدون إيقاع',
      category: 'quran_munajat',
      durationSec: 317,
      archiveId: '1272-song-without-rhythm-and-music',
      audioUrl: _iaUrl('1272-song-without-rhythm-and-music', 'Nasheed07.mp3'),
    ),
    NasheedTrack(
      id: 'cur_rabah',
      title: 'رباه',
      artist: 'إنشاد صوتي خالص',
      category: 'quran_munajat',
      durationSec: 228,
      archiveId: '1272-song-without-rhythm-and-music',
      audioUrl: _iaUrl('1272-song-without-rhythm-and-music', 'Nasheed03.mp3'),
    ),
    NasheedTrack(
      id: 'cur_uhibbuka_rabbi',
      title: 'أحبك ربي',
      artist: 'أبو عبد الملك',
      category: 'quran_munajat',
      durationSec: 403,
      archiveId: 'Islamic_Tape-126_uP_bY_mUSLEm',
      audioUrl: _iaUrl('Islamic_Tape-126_uP_bY_mUSLEm', '005_uP_bY_mUSLEm.Ettounssi.mp3'),
    ),
    NasheedTrack(
      id: 'cur_anta_rabbi',
      title: 'أنت ربي',
      artist: 'أبو عبد الملك',
      category: 'quran_munajat',
      durationSec: 376,
      archiveId: 'Islamic_Tape-126_uP_bY_mUSLEm',
      audioUrl: _iaUrl('Islamic_Tape-126_uP_bY_mUSLEm', '013_uP_bY_mUSLEm.Ettounssi.mp3'),
    ),
    NasheedTrack(
      id: 'cur_labbayka_ilahi',
      title: 'لبيك إلهي وحنيني',
      artist: 'إنشاد صوتي خالص',
      category: 'quran_munajat',
      durationSec: 183,
      archiveId: '1272-song-without-rhythm-and-music',
      audioUrl: _iaUrl('1272-song-without-rhythm-and-music', 'Nasheed08.mp3'),
    ),
    NasheedTrack(
      id: 'cur_duaa_mesud',
      title: 'دعاء',
      artist: 'مسعود كرتس · بدون موسيقى',
      category: 'quran_munajat',
      durationSec: 273,
      archiveId: 'Mesud',
      audioUrl: _iaUrl('Mesud', 'duaa (1).mp3'),
    ),
    NasheedTrack(
      id: 'cur_yaman_bihali',
      title: 'يا من بحالي عليم',
      artist: 'مسعود كرتس · بدون موسيقى',
      category: 'quran_munajat',
      durationSec: 162,
      archiveId: 'Mesud',
      audioUrl: _iaUrl('Mesud', 'ya-man_bi-hali (1).mp3'),
    ),

    // 2. الزهد والرقائق
    NasheedTrack(
      id: 'cur_laysa_algharib',
      title: 'ليس الغريب',
      artist: 'قصيدة زهد · بدون إيقاع',
      category: 'zuhd',
      durationSec: 678,
      archiveId: '1272-song-without-rhythm-and-music',
      audioUrl: _iaUrl('1272-song-without-rhythm-and-music', 'Nasheed10.mp3'),
    ),
    NasheedTrack(
      id: 'cur_bakat_ayni',
      title: 'بكت عيني',
      artist: 'إنشاد صوتي خالص',
      category: 'zuhd',
      durationSec: 214,
      archiveId: '1272-song-without-rhythm-and-music',
      audioUrl: _iaUrl('1272-song-without-rhythm-and-music', 'Nasheed01.mp3'),
    ),
    NasheedTrack(
      id: 'cur_tazakar',
      title: 'تذكّر',
      artist: 'إنشاد صوتي خالص',
      category: 'zuhd',
      durationSec: 241,
      archiveId: '1272-song-without-rhythm-and-music',
      audioUrl: _iaUrl('1272-song-without-rhythm-and-music', 'Nasheed02.mp3'),
    ),
    NasheedTrack(
      id: 'cur_mawlay_muqit',
      title: 'مولاي قد نامت عيون',
      artist: 'محمد المقيط · بدون إيقاع',
      category: 'zuhd',
      durationSec: 184,
      archiveId: 'facebook..hzatni',
      audioUrl: _iaUrl('facebook..hzatni', 'mokit.mp3'),
    ),
    NasheedTrack(
      id: 'cur_ishq_aljannah',
      title: 'عشق الجنة',
      artist: 'إنشاد صوتي خالص',
      category: 'zuhd',
      durationSec: 439,
      archiveId: '1272-song-without-rhythm-and-music',
      audioUrl: _iaUrl('1272-song-without-rhythm-and-music', 'Nasheed1000.mp3'),
    ),
    NasheedTrack(
      id: 'cur_atayto_bizanbi',
      title: 'أتيت بذنبي',
      artist: 'مسعود كرتس · بدون موسيقى',
      category: 'zuhd',
      durationSec: 310,
      archiveId: 'Mesud',
      audioUrl: _iaUrl('Mesud', 'atayto_bi_zanbi (1).mp3'),
    ),
    NasheedTrack(
      id: 'cur_aljannah_abdulmalik',
      title: 'الجنّـة',
      artist: 'أبو عبد الملك',
      category: 'zuhd',
      durationSec: 245,
      archiveId: 'Islamic_Tape-126_uP_bY_mUSLEm',
      audioUrl: _iaUrl('Islamic_Tape-126_uP_bY_mUSLEm', '001_uP_bY_mUSLEm.Ettounssi.mp3'),
    ),

    // 3. مدح النبي ﷺ
    NasheedTrack(
      id: 'cur_adnani',
      title: 'عدناني',
      artist: 'مسعود كرتس · بدون موسيقى',
      category: 'prophetic',
      durationSec: 222,
      archiveId: 'Mesud',
      audioUrl: _iaUrl('Mesud', 'Adnani (1).mp3'),
    ),
    NasheedTrack(
      id: 'cur_ghar_hiraa',
      title: 'غار حراء',
      artist: 'مسعود كرتس · بدون موسيقى',
      category: 'prophetic',
      durationSec: 245,
      archiveId: 'Mesud',
      audioUrl: _iaUrl('Mesud', 'ghar_hiraa (1).mp3'),
    ),
    NasheedTrack(
      id: 'cur_assalat_wassalam',
      title: 'الصلاة والسلام',
      artist: 'مسعود كرتس · بدون موسيقى',
      category: 'prophetic',
      durationSec: 250,
      archiveId: 'Mesud',
      audioUrl: _iaUrl('Mesud', 'assalat_wassalam (1).mp3'),
    ),
    NasheedTrack(
      id: 'cur_rohi_fidak',
      title: 'روحي فداك',
      artist: 'مسعود كرتس · بدون موسيقى',
      category: 'prophetic',
      durationSec: 245,
      archiveId: 'Mesud',
      audioUrl: _iaUrl('Mesud', 'rohi_fidak (1).mp3'),
    ),
    NasheedTrack(
      id: 'cur_raqqat_aynai',
      title: 'رقت عيناي شوقاً (السلام عليك)',
      artist: 'ماهر زين · نسخة صوتية فقط',
      category: 'prophetic',
      durationSec: 182,
      archiveId: 'Maher_Zean_www.suratmp3.com',
      audioUrl: _iaUrl('Maher_Zean_www.suratmp3.com', 'Assalamu_alaika.mp3'),
    ),
    NasheedTrack(
      id: 'cur_mawlaya_salli',
      title: 'مولاي صلِّ وسلم',
      artist: 'ماهر زين · نسخة صوتية فقط',
      category: 'prophetic',
      durationSec: 270,
      archiveId: 'Maher_Zean_www.suratmp3.com',
      audioUrl: _iaUrl('Maher_Zean_www.suratmp3.com', 'Mawlaya.mp3'),
    ),

    // 4. الأمل والهمة
    NasheedTrack(
      id: 'cur_alhamdolillah',
      title: 'الحمد لله',
      artist: 'مسعود كرتس · بدون موسيقى',
      category: 'hope',
      durationSec: 218,
      archiveId: 'Mesud',
      audioUrl: _iaUrl('Mesud', 'alhamdolillah (1).mp3'),
    ),
    NasheedTrack(
      id: 'cur_tabssam',
      title: 'تبسّم',
      artist: 'مسعود كرتس · بدون موسيقى',
      category: 'hope',
      durationSec: 229,
      archiveId: 'Mesud',
      audioUrl: _iaUrl('Mesud', 'tabssam (1).mp3'),
    ),
    NasheedTrack(
      id: 'cur_aqd_alazm',
      title: 'عقد العزم',
      artist: 'إنشاد صوتي خالص',
      category: 'hope',
      durationSec: 201,
      archiveId: '1272-song-without-rhythm-and-music',
      audioUrl: _iaUrl('1272-song-without-rhythm-and-music', 'Nasheed1002.mp3'),
    ),
    NasheedTrack(
      id: 'cur_insha_allah',
      title: 'إن شاء الله',
      artist: 'ماهر زين · نسخة صوتية فقط',
      category: 'hope',
      durationSec: 307,
      archiveId: 'Maher_Zean_www.suratmp3.com',
      audioUrl: _iaUrl('Maher_Zean_www.suratmp3.com', ' Insha_Allah.mp3'),
    ),
    NasheedTrack(
      id: 'cur_istayqiz',
      title: 'استيقظ',
      artist: 'ماهر زين · نسخة صوتية فقط',
      category: 'hope',
      durationSec: 233,
      archiveId: 'Maher_Zean_www.suratmp3.com',
      audioUrl: _iaUrl('Maher_Zean_www.suratmp3.com', 'MaherZain-Istay9ez-VocalsOnly.mp3'),
    ),
    NasheedTrack(
      id: 'cur_masha_allah',
      title: 'ما شاء الله',
      artist: 'ماهر زين · نسخة صوتية فقط',
      category: 'hope',
      durationSec: 212,
      archiveId: 'Maher_Zean_www.suratmp3.com',
      audioUrl: _iaUrl('Maher_Zean_www.suratmp3.com', 'Masha_Allah.mp3'),
    ),

    // 5. للأطفال والأسرة
    NasheedTrack(
      id: 'cur_ahlan_ramadan',
      title: 'أهلاً رمضان',
      artist: 'أناشيد الأطفال · بدون موسيقى',
      category: 'children',
      durationSec: 127,
      archiveId: 'AnashidAtfal-QN',
      audioUrl: _iaUrl('AnashidAtfal-QN', '1-أهلا رمضان.mp3'),
    ),
    NasheedTrack(
      id: 'cur_ila_alsalah',
      title: 'إلى الصلاة',
      artist: 'أناشيد الأطفال · بدون موسيقى',
      category: 'children',
      durationSec: 69,
      archiveId: 'AnashidAtfal-QN',
      audioUrl: _iaUrl('AnashidAtfal-QN', '2-.mp3'),
    ),
    NasheedTrack(
      id: 'cur_shahr_alrahman',
      title: 'شهر الرحمن والغفران',
      artist: 'أناشيد الأطفال · بدون موسيقى',
      category: 'children',
      durationSec: 94,
      archiveId: 'AnashidAtfal-QN',
      audioUrl: _iaUrl('AnashidAtfal-QN', '3-.mp3'),
    ),
    NasheedTrack(
      id: 'cur_halla_alkhayr',
      title: 'هل هلال الخير',
      artist: 'أناشيد الأطفال · بدون موسيقى',
      category: 'children',
      durationSec: 118,
      archiveId: 'AnashidAtfal-QN',
      audioUrl: _iaUrl('AnashidAtfal-QN', '4-.mp3'),
    ),
  ];

  static const List<VocalCollection> openCollections = [
    VocalCollection(
      id: 'col_1272',
      archiveId: '1272-song-without-rhythm-and-music',
      title: 'موسوعة ١٢٧٢ أنشودة بدون إيقاع ولا موسيقى',
      subtitle: 'أضخم مكتبة صوتية خالصة من الأناشيد والقصائد الإسلامية',
      trackCountLabel: '١٬٢٧٢ نشيداً',
      defaultArtist: 'موسوعة الأناشيد · بدون إيقاع',
      defaultCategory: 'zuhd',
    ),
    VocalCollection(
      id: 'col_abu_abdulmalik',
      archiveId: 'Islamic_Tape-126_uP_bY_mUSLEm',
      title: 'ديوان المنشد أبو عبد الملك',
      subtitle: 'كلاسيكيات الإنشاد الإسلامي الهادف بصوت نقي بدون موسيقى',
      trackCountLabel: '١٤١ نشيداً',
      defaultArtist: 'أبو عبد الملك',
      defaultCategory: 'zuhd',
    ),
    VocalCollection(
      id: 'col_mesud',
      archiveId: 'Mesud',
      title: 'مختارات مسعود كرتس (بدون موسيقى)',
      subtitle: 'مدائح نبوية ومناجاة هادئة بنسخة صوتية خالصة',
      trackCountLabel: '١١ نشيداً',
      defaultArtist: 'مسعود كرتس · بدون موسيقى',
      defaultCategory: 'prophetic',
    ),
    VocalCollection(
      id: 'col_maher_vocals',
      archiveId: 'Maher_Zean_www.suratmp3.com',
      title: 'ماهر زين — النسخ الصوتية فقط',
      subtitle: 'مجموعة أناشيد ماهر زين بدون موسيقى (Vocals Only)',
      trackCountLabel: '٢٤ نشيداً',
      defaultArtist: 'ماهر زين · بدون موسيقى',
      defaultCategory: 'hope',
    ),
    VocalCollection(
      id: 'col_666',
      archiveId: '666-song-without-rhythm-and-music',
      title: 'مجموعة ٦٦٦ أنشودة بدون إيقاع',
      subtitle: 'مختارات متنوعة خالية تماماً من المعازف والإيقاع',
      trackCountLabel: '٦٦٦ نشيداً',
      defaultArtist: 'مجموعة منشدين · بدون إيقاع',
      defaultCategory: 'hope',
    ),
  ];

  static bool _looksLikeMojibake(String text) {
    if (text.trim().isEmpty) return true;
    int latinExt = 0;
    for (final rune in text.runes) {
      if (rune >= 0x00C0 && rune <= 0x00FF) latinExt++;
    }
    return latinExt >= 2;
  }

  static String _cleanTitle(String? rawTitle, String filename) {
    final candidate = (rawTitle ?? '').trim();
    if (candidate.isNotEmpty && !_looksLikeMojibake(candidate)) {
      final stripped =
          candidate.replaceFirst(RegExp(r'^\d+[-_.\s]+'), '').trim();
      return stripped.isNotEmpty ? stripped : candidate;
    }
    final fromFile = filename
        .replaceAll(RegExp(r'\.mp3$', caseSensitive: false), '')
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(
            RegExp(r'uP bY mUSLEm|Ettounssi|\(\d+\)', caseSensitive: false), '')
        .trim();
    if (fromFile.isNotEmpty && !_looksLikeMojibake(fromFile)) {
      return fromFile;
    }
    return filename.replaceAll(RegExp(r'\.mp3$', caseSensitive: false), '');
  }

  static int? _parseDuration(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.round();
    final str = raw.toString().trim();
    if (str.isEmpty) return null;
    if (str.contains(':')) {
      final parts = str.split(':').map((e) => int.tryParse(e)).toList();
      if (parts.every((e) => e != null)) {
        if (parts.length == 2) return parts[0]! * 60 + parts[1]!;
        if (parts.length == 3) {
          return parts[0]! * 3600 + parts[1]! * 60 + parts[2]!;
        }
      }
    }
    return double.tryParse(str)?.round();
  }

  static Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 12);
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, 'ItqanQuranApp/1.0');
      final response = await request.close();
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}');
      }
      final body = await response.transform(utf8.decoder).join();
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } finally {
      client.close(force: true);
    }
  }

  static Future<List<NasheedTrack>> fetchCollectionTracks({
    required String archiveId,
    String defaultArtist = 'مكتبة الأرشيف · بدون إيقاع',
    String defaultCategory = 'zuhd',
    int limit = 80,
  }) async {
    final uri = Uri.parse(
        'https://archive.org/metadata/${Uri.encodeComponent(archiveId)}');
    final data = await _getJson(uri);
    final files = data['files'];
    if (files is! List) return [];

    final tracks = <NasheedTrack>[];
    for (final item in files) {
      if (tracks.length >= limit) break;
      if (item is! Map) continue;
      final name = item['name']?.toString() ?? '';
      if (!name.toLowerCase().endsWith('.mp3')) continue;
      if (name.toLowerCase().contains('_vbr.mp3')) continue;

      final title = _cleanTitle(item['title']?.toString(), name);
      if (title.isEmpty || _looksLikeMojibake(title)) continue;

      final rawArtist = (item['artist']?.toString() ?? '').trim();
      final artist = (rawArtist.isNotEmpty &&
              !_looksLikeMojibake(rawArtist) &&
              !rawArtist.contains('@') &&
              !rawArtist.toLowerCase().contains('www.') &&
              rawArtist != 'Chanters Group')
          ? rawArtist
          : defaultArtist;

      tracks.add(NasheedTrack(
        id: '${archiveId}_$name',
        title: title,
        artist: artist,
        category: defaultCategory,
        durationSec: _parseDuration(item['length']),
        archiveId: archiveId,
        audioUrl: _iaUrl(archiveId, name),
      ));
    }
    return tracks;
  }

  static Future<List<ArchiveSearchItem>> searchVocalAnashid(
      String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];
    final lucene =
        'mediatype:audio AND ("بدون إيقاع" OR "بدون موسيقى") AND ($clean)';
    final uri = Uri.parse(
      'https://archive.org/advancedsearch.php?q=${Uri.encodeQueryComponent(lucene)}&fl[]=identifier,title,creator&rows=18&output=json',
    );
    final data = await _getJson(uri);
    final response = data['response'];
    if (response is! Map || response['docs'] is! List) return [];

    final results = <ArchiveSearchItem>[];
    for (final doc in response['docs'] as List) {
      if (doc is! Map) continue;
      final id = doc['identifier']?.toString();
      if (id == null || id.isEmpty) continue;
      final creatorRaw = doc['creator'];
      final creator = creatorRaw is List && creatorRaw.isNotEmpty
          ? creatorRaw.first.toString()
          : (creatorRaw?.toString() ?? 'مكتبة الأرشيف · بدون إيقاع');
      results.add(ArchiveSearchItem(
        archiveId: id,
        title: doc['title']?.toString() ?? id,
        creator: creator.isEmpty ? 'مكتبة الأرشيف · بدون إيقاع' : creator,
      ));
    }
    return results;
  }
}
