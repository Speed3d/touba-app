/// 📝 HINT AR: توليد جداول البطولات (الوجبة 7).
/// • الدوري: Round-Robin (طريقة الدائرة) — لعدد فردي يُضاف فريق راحة (Bye).
/// • الإقصائي: شجرة كاملة بروابط ترقية (homeFeedKey/awayFeedKey) + دعم Bye
///   لأقوى المتصدّرين (عدد غير قوّة 2). الفائز يصعد للخانة التالية عبر CF.
/// • المجموعات: دوري لكل مجموعة موسوم بـ groupName؛ توليد الإقصائي بعد اكتمال
///   المجموعات يتم في Cloud Function (generateKnockoutFromGroups).
class Fixture {
  final int round;
  final String homeId; // قد يكون '' لخانة TBD في الإقصائي
  final String awayId;
  final String stage; // league | group | knockout
  final String? groupName; // للمجموعات
  final int bracketRound; // ترتيب دور الإقصائي (1=الأول ... النهائي)
  final String key; // معرّف محلّي للربط (الإقصائي)
  final String? homeFeedKey; // مفتاح المباراة التي يملأ فائزها الخانة المضيفة
  final String? awayFeedKey;

  const Fixture(
    this.round,
    this.homeId,
    this.awayId, {
    this.stage = 'league',
    this.groupName,
    this.bracketRound = 0,
    this.key = '',
    this.homeFeedKey,
    this.awayFeedKey,
  });
}

class FixturesService {
  static const String bye = '__BYE__';

  // ==========================================
  // Round-Robin (الدوري)
  // ==========================================
  static List<Fixture> roundRobin(List<String> teamIds,
      {bool isHomeAndAway = false}) {
    final teams = List<String>.from(teamIds);
    if (teams.length < 2) return [];
    if (teams.length.isOdd) teams.add(bye); // فريق راحة

    final n = teams.length;
    final rounds = n - 1;
    final half = n ~/ 2;
    final fixtures = <Fixture>[];
    final arr = List<String>.from(teams);

    for (int r = 0; r < rounds; r++) {
      for (int i = 0; i < half; i++) {
        final a = arr[i];
        final b = arr[n - 1 - i];
        if (a == bye || b == bye) continue;
        // تبديل الأرضية بين الجولات لعدالة المضيف/الضيف
        if (r.isEven) {
          fixtures.add(Fixture(r + 1, a, b));
        } else {
          fixtures.add(Fixture(r + 1, b, a));
        }
      }
      // تدوير الدائرة: تثبيت العنصر الأول وتدوير الباقي
      final movable = arr.sublist(1);
      movable.insert(0, movable.removeLast());
      for (int i = 1; i < n; i++) {
        arr[i] = movable[i - 1];
      }
    }

    if (isHomeAndAway) {
      final firstLeg = List<Fixture>.from(fixtures);
      for (final f in firstLeg) {
        fixtures.add(Fixture(f.round + rounds, f.awayId, f.homeId));
      }
    }
    return fixtures;
  }

  // ==========================================
  // Knockout (خروج المغلوب) — شجرة بروابط ترقية + Bye
  // ==========================================
  // 📝 HINT AR: قرعة عشوائية ثم بناء شجرة كاملة. الجولة الأولى تحوي المباريات
  // الحقيقية فقط (الفرق التي بلا راحة)؛ من حصل على راحة يصعد مباشرةً ويُملأ في
  // خانة جولته التالية. الجولات اللاحقة خاناتها TBD مرتبطة بـ feedKey.
  static List<Fixture> knockout(List<String> teamIds,
      {bool isHomeAndAway = false, String generationMode = 'full_tree'}) {
    final teams = List<String>.from(teamIds)..shuffle();
    return buildBracket(teams);
  }

  // 📝 HINT AR: ترتيب البذور القياسي (1 يقابل الأخير، 2 يقابل ما قبله...).
  static List<int> _seedOrder(int size) {
    var order = <int>[1];
    while (order.length < size) {
      final n = order.length * 2;
      final next = <int>[];
      for (final s in order) {
        next.add(s);
        next.add(n + 1 - s);
      }
      order = next;
    }
    return order;
  }

  // 📝 HINT AR: يبني شجرة إقصائية من قائمة فرق مرتّبة بالبذور (الأقوى أولاً).
  // لا يخلط — الترتيب يحكم التزاوج (مهم لتزاوج المجموعات القياسي A1×B2).
  static List<Fixture> buildBracket(List<String> seeds) {
    final n = seeds.length;
    if (n < 2) return [];
    var p = 1;
    while (p < n) {
      p *= 2; // أصغر قوّة 2 ≥ n
    }
    final order = _seedOrder(p); // أرقام بذور 1..p بطول p
    String teamOf(int seed) => seed <= n ? seeds[seed - 1] : bye;

    final fixtures = <Fixture>[];
    var counter = 0;
    String newKey(int round) => 'K${round}_${counter++}';

    // ── الجولة الأولى: تنتج «صاعدين» للجولة الثانية ──
    var advancers = <_Slot>[];
    var round = 1;
    counter = 0;
    for (int i = 0; i < p; i += 2) {
      final a = teamOf(order[i]);
      final b = teamOf(order[i + 1]);
      final aBye = a == bye;
      final bBye = b == bye;
      if (aBye && bBye) {
        continue; // لا يحدث مع تزاوج البذور الصحيح
      } else if (aBye) {
        advancers.add(_Slot.team(b)); // b يصعد بالراحة
      } else if (bBye) {
        advancers.add(_Slot.team(a));
      } else {
        final key = newKey(round);
        fixtures.add(Fixture(round, a, b,
            stage: 'knockout', bracketRound: round, key: key));
        advancers.add(_Slot.feed(key));
      }
    }

    // ── الجولات اللاحقة ──
    while (advancers.length > 1) {
      round++;
      counter = 0;
      final next = <_Slot>[];
      for (int i = 0; i < advancers.length; i += 2) {
        final s1 = advancers[i];
        final s2 = advancers[i + 1];
        final key = newKey(round);
        fixtures.add(Fixture(
          round,
          s1.teamId ?? '', // فريق محسوم (من راحة) أو '' لـ TBD
          s2.teamId ?? '',
          stage: 'knockout',
          bracketRound: round,
          key: key,
          homeFeedKey: s1.feedKey,
          awayFeedKey: s2.feedKey,
        ));
        next.add(_Slot.feed(key));
      }
      advancers = next;
    }
    return fixtures;
  }

  // ==========================================
  // Groups (المجموعات)
  // ==========================================
  // 📝 HINT AR: توزيع الفرق على المجموعات (قرعة عشوائية) — يُحفظ في tournament.groups
  // ليُعرض في التفاصيل. أسماء المجموعات A, B, C...
  static Map<String, List<String>> assignGroups(
      List<String> teamIds, int numberOfGroups) {
    final count = numberOfGroups < 1 ? 1 : numberOfGroups;
    final teams = List<String>.from(teamIds)..shuffle();
    final result = <String, List<String>>{};
    for (var i = 0; i < count; i++) {
      result[String.fromCharCode(65 + i)] = <String>[];
    }
    final keys = result.keys.toList();
    for (var i = 0; i < teams.length; i++) {
      result[keys[i % count]]!.add(teams[i]);
    }
    return result;
  }

  // 📝 HINT AR: دوري كل مجموعة موسوم بـ groupName (مرحلة المجموعات).
  static List<Fixture> groupFixtures(Map<String, List<String>> groups,
      {bool isHomeAndAway = false}) {
    final fixtures = <Fixture>[];
    for (final entry in groups.entries) {
      final rr = roundRobin(entry.value, isHomeAndAway: isHomeAndAway);
      for (final f in rr) {
        fixtures.add(Fixture(f.round, f.homeId, f.awayId,
            stage: 'group', groupName: entry.key));
      }
    }
    fixtures.sort((a, b) => a.round.compareTo(b.round));
    return fixtures;
  }
}

// 📝 HINT AR: خانة في الشجرة — إمّا فريق محسوم (من راحة) أو فائز مباراة (feed).
class _Slot {
  final String? teamId;
  final String? feedKey;
  const _Slot.team(this.teamId) : feedKey = null;
  const _Slot.feed(this.feedKey) : teamId = null;
}
