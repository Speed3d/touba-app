/// 📝 HINT AR: توليد جدول مباريات الدوري (Round-Robin) بطريقة الدائرة (Circle Method).
/// لعدد فردي من الفرق نضيف فريقاً وهمياً (Bye) فيستريح فريق كل جولة.
/// عدد المباريات (ذهاب فقط) = n×(n−1)/2.
class Fixture {
  final int round;
  final String homeId;
  final String awayId;
  const Fixture(this.round, this.homeId, this.awayId);
}

class FixturesService {
  static const String _bye = '__BYE__';

  static List<Fixture> roundRobin(List<String> teamIds, {bool isHomeAndAway = false}) {
    final teams = List<String>.from(teamIds);
    if (teams.length < 2) return [];
    if (teams.length.isOdd) teams.add(_bye); // فريق راحة

    final n = teams.length;
    final rounds = n - 1;
    final half = n ~/ 2;
    final fixtures = <Fixture>[];
    final arr = List<String>.from(teams);

    for (int r = 0; r < rounds; r++) {
      for (int i = 0; i < half; i++) {
        final a = arr[i];
        final b = arr[n - 1 - i];
        if (a == _bye || b == _bye) continue;
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
  // Knockout (خروج المغلوب)
  // ==========================================

  static List<Fixture> knockout(List<String> teamIds, {bool isHomeAndAway = false, String generationMode = 'full_tree'}) {
    final teams = List<String>.from(teamIds);
    teams.shuffle(); // قرعة عشوائية
    final fixtures = <Fixture>[];
    int matchIndex = 1;
    int currentRound = 1;

    // توليد الجولة الأولى
    final firstRoundMatches = <int>[];
    for (int i = 0; i < teams.length; i += 2) {
      if (i + 1 < teams.length) {
        fixtures.add(Fixture(currentRound, teams[i], teams[i + 1]));
        if (isHomeAndAway) {
          fixtures.add(Fixture(currentRound + 1, teams[i + 1], teams[i]));
        }
        firstRoundMatches.add(matchIndex);
        matchIndex++;
      } else {
        // فريق فردي حصل على Bye (تأهل تلقائي) - في التطبيقات المتقدمة نتعامل معها بشكل أفضل، هنا نتركه للمنظم.
      }
    }

    // توليد بقية الشجرة (TBD)
    if (generationMode == 'full_tree') {
      int nextRoundStartOffset = isHomeAndAway ? 2 : 1;
      List<int> previousRoundMatchIndices = List.from(firstRoundMatches);
      
      while (previousRoundMatchIndices.length > 1) {
        currentRound += nextRoundStartOffset;
        final currentRoundIndices = <int>[];
        
        for (int i = 0; i < previousRoundMatchIndices.length; i += 2) {
          if (i + 1 < previousRoundMatchIndices.length) {
            final m1 = previousRoundMatchIndices[i];
            final m2 = previousRoundMatchIndices[i + 1];
            fixtures.add(Fixture(currentRound, 'TBD: الفائز من م$m1', 'TBD: الفائز من م$m2'));
            if (isHomeAndAway && previousRoundMatchIndices.length > 2) { // قد لا نريد ذهاب وإياب في النهائي
              fixtures.add(Fixture(currentRound + 1, 'TBD: الفائز من م$m2', 'TBD: الفائز من م$m1'));
            }
            currentRoundIndices.add(matchIndex);
            matchIndex++;
          }
        }
        previousRoundMatchIndices = currentRoundIndices;
      }
    }

    return fixtures;
  }

  // ==========================================
  // Groups (المجموعات)
  // ==========================================

  static List<Fixture> groups(List<String> teamIds, {int numberOfGroups = 2, bool isHomeAndAway = false}) {
    if (numberOfGroups < 1) numberOfGroups = 1;
    final teams = List<String>.from(teamIds);
    teams.shuffle(); // قرعة عشوائية للمجموعات
    
    final groups = List.generate(numberOfGroups, (_) => <String>[]);
    for (int i = 0; i < teams.length; i++) {
      groups[i % numberOfGroups].add(teams[i]);
    }

    final fixtures = <Fixture>[];
    for (int g = 0; g < groups.length; g++) {
      final groupFixtures = roundRobin(groups[g], isHomeAndAway: isHomeAndAway);
      // يمكن إضافة معرف المجموعة لاحقاً، حالياً نعتمد على جولات متزامنة
      fixtures.addAll(groupFixtures);
    }
    
    // ترتيب المباريات حسب الجولة لتبدو متناسقة
    fixtures.sort((a, b) => a.round.compareTo(b.round));
    return fixtures;
  }
}
