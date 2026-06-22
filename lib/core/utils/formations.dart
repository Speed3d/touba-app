/// 📝 HINT AR: التشكيلات الثابتة (الخطط) لكرة القدم الشعبية حسب عدد اللاعبين.
/// الصيغة دائماً **GK-DEF-MID-FWD** (الحارس أولاً). مجموع الأرقام = عدد اللاعبين.
/// الكابتن يختار واحدة لفريقه (تُحفظ في `teams.formation`)، وتُرسم على الملعب.
library;

/// خيارات التشكيلة لكل عدد لاعبين (يشمل الحارس).
const Map<int, List<String>> kFormationOptions = {
  6: ['1-2-2-1', '1-3-1-1', '1-2-1-2'],
  8: ['1-3-3-1', '1-2-3-2', '1-3-2-2'],
  11: ['1-4-3-3', '1-4-4-2', '1-3-5-2'],
};

/// أعداد اللاعبين المدعومة (تطابق `tournament.playerFormat`).
const List<int> kPlayerFormats = [6, 8, 11];

/// يفكّ الصيغة «1-2-2-1» إلى [1, 2, 2, 1].
List<int> parseFormation(String label) =>
    label.split('-').map((e) => int.tryParse(e.trim()) ?? 0).toList();

/// مجموع لاعبي التشكيلة (يشمل الحارس).
int formationTotal(String label) =>
    parseFormation(label).fold(0, (a, b) => a + b);

/// التشكيلة الافتراضية لعدد لاعبين معيّن.
String defaultFormationFor(int format) =>
    (kFormationOptions[format] ?? const ['1-2-2-1']).first;

/// خانة في التشكيلة على الملعب: الخط + إحداثيات نسبية (x,y من 0..1).
/// y=1 أسفل (مرمى الفريق، حيث الحارس) و y=0 أعلى (هجوم).
class FormationSlot {
  final String line; // gk | def | mid | fwd
  final double x;
  final double y;
  const FormationSlot(this.line, this.x, this.y);
}

// 📝 HINT AR: ارتفاع كل خط على الملعب العمودي — الحارس داخل منطقة الجزاء أسفل.
const Map<String, double> _lineY = {
  'gk': 0.90, // داخل صندوق الجزاء السفلي
  'def': 0.69,
  'mid': 0.46,
  'fwd': 0.21,
};
const List<String> _lineOrder = ['gk', 'def', 'mid', 'fwd'];

/// يبني خانات التشكيلة من الصيغة — يوزّع كل خط أفقياً بالتساوي: x = (i+1)/(n+1).
List<FormationSlot> formationSlots(String label) {
  final counts = parseFormation(label);
  final slots = <FormationSlot>[];
  for (var li = 0; li < counts.length && li < _lineOrder.length; li++) {
    final line = _lineOrder[li];
    final n = counts[li];
    final y = _lineY[line]!;
    for (var i = 0; i < n; i++) {
      slots.add(FormationSlot(line, (i + 1) / (n + 1), y));
    }
  }
  return slots;
}
