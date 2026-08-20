/// 📝 HINT AR: بيانات المحافظات والمناطق العراقية — Fallback ثابت بثلاث لغات
/// هذا الملف هو الطبقة الاحتياطية (Hardcoded Fallback) من نظام Hybrid:
///   - المستوى 1: هذا الملف — يعمل بدون إنترنت وبدون أي تكلفة
///   - المستوى 2: Firestore — المصدر الرسمي الذي يديره الأدمن
///   - المستوى 3: Remote Config — للتصحيحات العاجلة بدون تحديث
library;

// ============================================================
//  نموذج بسيط للاستخدام الداخلي في هذا الملف فقط
// ============================================================

/// 📝 HINT AR: يمثل منطقة واحدة داخل محافظة
/// [key] المفتاح الفريد — يُستخدم للبحث والفلترة (لا يتغير بتغيير اللغة)
/// [nameAr] الاسم بالعربية
/// [nameEn] الاسم بالإنجليزية
/// [nameKu] الاسم بالكردية السوراني
class IraqDistrict {
  final String key;
  final String nameAr;
  final String nameEn;
  final String nameKu;

  const IraqDistrict({
    required this.key,
    required this.nameAr,
    required this.nameEn,
    required this.nameKu,
  });

  /// 📝 HINT AR: جلب اسم المنطقة وفق لغة التطبيق
  String localizedName(String langCode) {
    if (langCode == 'ku') {
      return nameKu.isNotEmpty ? nameKu : (nameAr.isNotEmpty ? nameAr : nameEn);
    }
    if (langCode == 'en') {
      return nameEn.isNotEmpty ? nameEn : nameAr;
    }
    return nameAr.isNotEmpty ? nameAr : nameEn;
  }
}

/// 📝 HINT AR: يمثل محافظة واحدة مع قائمة مناطقها
/// [key] نفس cityId في Firestore — الربط الأساسي
class IraqGovernorate {
  final String key;
  final String nameAr;
  final String nameEn;
  final String nameKu;
  final List<IraqDistrict> districts;

  const IraqGovernorate({
    required this.key,
    required this.nameAr,
    required this.nameEn,
    required this.nameKu,
    required this.districts,
  });

  /// 📝 HINT AR: جلب اسم المحافظة وفق لغة التطبيق
  String localizedName(String langCode) {
    if (langCode == 'ku') {
      return nameKu.isNotEmpty ? nameKu : (nameAr.isNotEmpty ? nameAr : nameEn);
    }
    if (langCode == 'en') {
      return nameEn.isNotEmpty ? nameEn : nameAr;
    }
    return nameAr.isNotEmpty ? nameAr : nameEn;
  }
}

// ============================================================
//  الدوال المساعدة للوصول للبيانات
// ============================================================

class IraqRegions {
  IraqRegions._();

  /// 📝 HINT AR: جلب مناطق محافظة بمفتاحها الثابت (للتوافق الداخلي)
  static List<IraqDistrict> getDistrictsByCityKey(String cityKey) {
    try {
      return _governorates.firstWhere((g) => g.key == cityKey).districts;
    } catch (_) {
      return [];
    }
  }

  /// 📝 HINT AR: جلب مناطق محافظة بالاسم العربي
  static List<IraqDistrict> getDistrictsByCityNameAr(String nameAr) {
    if (nameAr.isEmpty) return [];
    try {
      return _governorates
          .firstWhere((g) => g.nameAr.trim() == nameAr.trim())
          .districts;
    } catch (_) {
      return [];
    }
  }

  /// 📝 HINT AR: جلب مناطق محافظة بالاسم الإنجليزي
  static List<IraqDistrict> getDistrictsByCityNameEn(String nameEn) {
    if (nameEn.isEmpty) return [];
    try {
      return _governorates
          .firstWhere((g) =>
              g.nameEn.toLowerCase().trim() == nameEn.toLowerCase().trim())
          .districts;
    } catch (_) {
      return [];
    }
  }

  /// 📝 HINT AR: جلب مناطق بأي مصدر ممكن — يجرب المفتاح ثم الاسم العربي ثم الإنجليزي
  static List<IraqDistrict> getDistrictsFuzzy({
    String key = '',
    String nameAr = '',
    String nameEn = '',
  }) {
    List<IraqDistrict> result = [];
    if (key.isNotEmpty) result = getDistrictsByCityKey(key);
    if (result.isEmpty && nameAr.isNotEmpty) {
      result = getDistrictsByCityNameAr(nameAr);
    }
    if (result.isEmpty && nameEn.isNotEmpty) {
      result = getDistrictsByCityNameEn(nameEn);
    }
    return result;
  }

  /// 📝 HINT AR: جلب منطقة واحدة بمفتاحها
  static IraqDistrict? getDistrict(String cityKey, String districtKey) {
    final districts = getDistrictsByCityKey(cityKey);
    try {
      return districts.firstWhere((d) => d.key == districtKey);
    } catch (_) {
      return null;
    }
  }

  /// 📝 HINT AR: جلب كل المحافظات (للاستخدام عند غياب Firestore)
  static List<IraqGovernorate> get all => _governorates;

  // ============================================================
  //  بيانات المحافظات الـ 18 مع مناطقها (عربي + إنجليزي + كردي سوراني)
  // ============================================================

  static const List<IraqGovernorate> _governorates = [
    // ===== 1. بغداد =====
    IraqGovernorate(
      key: 'baghdad',
      nameAr: 'بغداد',
      nameEn: 'Baghdad',
      nameKu: 'بەغدا',
      districts: [
        IraqDistrict(key: 'krada', nameAr: 'الكرادة', nameEn: 'Krada', nameKu: 'کەرادە'),
        IraqDistrict(key: 'mansour', nameAr: 'المنصور', nameEn: 'Mansour', nameKu: 'مەنسوور'),
        IraqDistrict(key: 'kadhimia', nameAr: 'الكاظمية', nameEn: 'Kadhimia', nameKu: 'کازمیە'),
        IraqDistrict(key: 'adhamia', nameAr: 'الأعظمية', nameEn: 'Adhamia', nameKu: 'ئەعزەمیە'),
        IraqDistrict(key: 'new_baghdad', nameAr: 'بغداد الجديدة', nameEn: 'New Baghdad', nameKu: 'بەغدای نوێ'),
        IraqDistrict(key: 'dora', nameAr: 'الدورة', nameEn: 'Dora', nameKu: 'دەورە'),
        IraqDistrict(key: 'saydia', nameAr: 'السيدية', nameEn: 'Saydia', nameKu: 'سەیدیە'),
        IraqDistrict(key: 'ameria', nameAr: 'العامرية', nameEn: 'Ameria', nameKu: 'عامریە'),
        IraqDistrict(key: 'ghazalia', nameAr: 'الغزالية', nameEn: 'Ghazalia', nameKu: 'غەزالیە'),
        IraqDistrict(key: 'jadriya', nameAr: 'الجادرية', nameEn: 'Jadriya', nameKu: 'جادریە'),
        IraqDistrict(key: 'zafaraniya', nameAr: 'الزعفرانية', nameEn: 'Zafaraniya', nameKu: 'زەعفەرانیە'),
        IraqDistrict(key: 'shaab', nameAr: 'الشعب', nameEn: 'Shaab', nameKu: 'شەعب'),
        IraqDistrict(key: 'washash', nameAr: 'الوشاش', nameEn: 'Washash', nameKu: 'وەشاش'),
        IraqDistrict(key: 'zayona', nameAr: 'زيونة', nameEn: 'Zayona', nameKu: 'زەیونە'),
        IraqDistrict(key: 'mashtal', nameAr: 'المشتل', nameEn: 'Mashtal', nameKu: 'مەشتەل'),
        IraqDistrict(key: 'palestine_st', nameAr: 'شارع فلسطين', nameEn: 'Palestine Street', nameKu: 'شەقامی فەلەستین'),
        IraqDistrict(key: 'sinaa', nameAr: 'الصناعة', nameEn: 'Sinaa', nameKu: 'سەناعە'),
        IraqDistrict(key: 'university', nameAr: 'حي الجامعة', nameEn: 'University District', nameKu: 'گەڕەکی زانکۆ'),
        IraqDistrict(key: 'baiyaa', nameAr: 'البياع', nameEn: 'Baiyaa', nameKu: 'بەییاع'),
        IraqDistrict(key: 'jihad', nameAr: 'الجهاد', nameEn: 'Jihad', nameKu: 'جیهاد'),
        IraqDistrict(key: 'shuala', nameAr: 'الشعلة', nameEn: 'Shuala', nameKu: 'شوعلە'),
        IraqDistrict(key: 'huriya', nameAr: 'الحرية', nameEn: 'Huriya', nameKu: 'حوریە'),
        IraqDistrict(key: 'sadr_city', nameAr: 'مدينة الصدر', nameEn: 'Sadr City', nameKu: 'مەدینەی سەدر'),
        IraqDistrict(key: 'abu_ghraib', nameAr: 'أبو غريب', nameEn: 'Abu Ghraib', nameKu: 'ئەبوو غرێب'),
        IraqDistrict(key: 'taji', nameAr: 'التاجي', nameEn: 'Taji', nameKu: 'تاجی'),
        IraqDistrict(key: 'mahmudiya', nameAr: 'المحمودية', nameEn: 'Mahmudiya', nameKu: 'مەحموودیە'),
        IraqDistrict(key: 'nahrawan', nameAr: 'النهروان', nameEn: 'Nahrawan', nameKu: 'نەهرەوان'),
        IraqDistrict(key: 'tobchi', nameAr: 'طوبچي', nameEn: 'Tobchi', nameKu: 'تۆپچی'),
        IraqDistrict(key: 'iskan', nameAr: 'الإسكان', nameEn: 'Iskan', nameKu: 'ئیسکان'),
        IraqDistrict(key: 'diyala_bridge', nameAr: 'جسر ديالى', nameEn: 'Diyala Bridge', nameKu: 'پردی دیالە'),
        IraqDistrict(key: 'aamel', nameAr: 'العامل', nameEn: 'Aamel', nameKu: 'عامل'),
        IraqDistrict(key: 'harthiya', nameAr: 'الحارثية', nameEn: 'Harthiya', nameKu: 'حارسیە'),
        IraqDistrict(key: 'qadisiya', nameAr: 'القادسية', nameEn: 'Qadisiya', nameKu: 'قادسیە'),
        IraqDistrict(key: 'yarmouk', nameAr: 'اليرموك', nameEn: 'Yarmouk', nameKu: 'یەرمووک'),
        IraqDistrict(key: 'maalif', nameAr: 'المعلف', nameEn: 'Maalif', nameKu: 'مەعلەف'),
        IraqDistrict(key: 'shurta', nameAr: 'الشرطة', nameEn: 'Shurta', nameKu: 'شوڕتە'),
        IraqDistrict(key: 'bab_moatham', nameAr: 'باب المعظم', nameEn: 'Bab Moatham', nameKu: 'بابولموعەزەم'),
        IraqDistrict(key: 'rahmaniya', nameAr: 'الرحمانية', nameEn: 'Rahmaniya', nameKu: 'ڕەحمانیە'),
        IraqDistrict(key: 'bab_alsharqi', nameAr: 'الباب الشرقي', nameEn: 'Bab Al-Sharqi', nameKu: 'بابی ڕۆژهەڵات'),
        IraqDistrict(key: 'sinak', nameAr: 'السنك', nameEn: 'Sinak', nameKu: 'سنەک'),
        IraqDistrict(key: 'shorja', nameAr: 'الشورجة', nameEn: 'Shorja', nameKu: 'شۆرجە'),
        IraqDistrict(key: 'bab_alsheikh', nameAr: 'باب الشيخ', nameEn: 'Bab Al-Sheikh', nameKu: 'بابولشێخ'),
        IraqDistrict(key: 'fadhil', nameAr: 'الفضل', nameEn: 'Fadhil', nameKu: 'فەزڵ'),
        IraqDistrict(key: 'sadria', nameAr: 'الصدرية', nameEn: 'Sadria', nameKu: 'سەدریە'),
        IraqDistrict(key: 'sheikh_omar', nameAr: 'الشيخ عمر', nameEn: 'Sheikh Omar', nameKu: 'شێخ عومەر'),
        IraqDistrict(key: 'maidain', nameAr: 'الميدان', nameEn: 'Maidan', nameKu: 'مەیدان'),
        IraqDistrict(key: 'abbakhana', nameAr: 'العباخانة', nameEn: 'Abbakhana', nameKu: 'عەباخانە'),
        IraqDistrict(key: 'raghiba_khatoun', nameAr: 'راغبة خاتون', nameEn: 'Raghiba Khatoun', nameKu: 'ڕاغیبە خاتوون'),
        IraqDistrict(key: 'kasra', nameAr: 'الكسرة', nameEn: 'Kasra', nameKu: 'کەسرە'),
        IraqDistrict(key: 'salikh', nameAr: 'الصليخ', nameEn: 'Salikh', nameKu: 'سلێخ'),
        IraqDistrict(key: 'kariyat', nameAr: 'الكريعات', nameEn: 'Kariyat', nameKu: 'کریعات'),
        IraqDistrict(key: 'safeena', nameAr: 'السفينة', nameEn: 'Safeena', nameKu: 'سەفینە'),
        IraqDistrict(key: 'ras_alhawash', nameAr: 'رأس الحواش', nameEn: 'Ras Al-Hawash', nameKu: 'ڕەئسولحەواش'),
        IraqDistrict(key: 'baladiyat', nameAr: 'البلديات', nameEn: 'Baladiyat', nameKu: 'بەلەدیات'),
        IraqDistrict(key: 'ghadeer', nameAr: 'الغدير', nameEn: 'Ghadeer', nameKu: 'غەدیر'),
        IraqDistrict(key: 'ameen', nameAr: 'الأمين', nameEn: 'Ameen', nameKu: 'ئەمین'),
        IraqDistrict(key: 'obaidi', nameAr: 'العبيدي', nameEn: 'Obaidi', nameKu: 'عوبەیدی'),
        IraqDistrict(key: 'salhiya', nameAr: 'الصالحية', nameEn: 'Salhiya', nameKu: 'ساڵحیە'),
        IraqDistrict(key: 'atifiya', nameAr: 'العطيفية', nameEn: 'Atifiya', nameKu: 'عوتەیفیە'),
        IraqDistrict(key: 'allawi', nameAr: 'العلاوي', nameEn: 'Allawi', nameKu: 'عەلاوی'),
        IraqDistrict(key: 'karadat_maryam', nameAr: 'كرادة مريم', nameEn: 'Karadat Maryam', nameKu: 'کەرادەی مەریەم'),
        IraqDistrict(key: 'dawoodi', nameAr: 'الداودي', nameEn: 'Dawoodi', nameKu: 'داوودی'),
        IraqDistrict(key: 'adl', nameAr: 'حي العدل', nameEn: 'Al-Adl', nameKu: 'گەڕەکی عەدل'),
        IraqDistrict(key: 'seha', nameAr: 'حي الصحة', nameEn: 'Seha', nameKu: 'گەڕەکی سیحە'),
        IraqDistrict(key: 'alam', nameAr: 'حي الإعلام', nameEn: 'Alam', nameKu: 'گەڕەکی ئیعلام'),
        IraqDistrict(key: 'khadra', nameAr: 'حي الخضراء', nameEn: 'Khadra', nameKu: 'گەڕەکی خەزرا'),
        IraqDistrict(key: 'awr', nameAr: 'حي أور', nameEn: 'Awr', nameKu: 'گەڕەکی ئوور'),
        IraqDistrict(key: 'sabe_qusur', nameAr: 'سبع قصور', nameEn: 'sabe qusur', nameKu: 'سەبع قوسوور'),
        IraqDistrict(key: 'alhusaynia', nameAr: 'الحسينية', nameEn: 'alhusaynia', nameKu: 'حوسێنیە'),
        IraqDistrict(key: 'nissan_9', nameAr: '9 نيسان', nameEn: '9 Nissan', nameKu: '٩ی نیسان'),
        IraqDistrict(key: 'abu_disheer', nameAr: 'أبو دشير', nameEn: 'Abu Disheer', nameKu: 'ئەبوو دشیر'),
        IraqDistrict(key: 'abu_nuwas', nameAr: 'أبو نؤاس', nameEn: 'Abu Nuwas', nameKu: 'ئەبوو نەواس'),
        IraqDistrict(key: 'athuriyeen', nameAr: 'الآثوريين', nameEn: 'Athuriyeen', nameKu: 'ئاشوورییەکان'),
        IraqDistrict(key: 'atibaa', nameAr: 'الأطباء', nameEn: 'Atibaa', nameKu: 'ئەتیببا'),
        IraqDistrict(key: 'amana', nameAr: 'الأمانة', nameEn: 'Amana', nameKu: 'ئەمانە'),
        IraqDistrict(key: 'bataween', nameAr: 'البتاوين', nameEn: 'Bataween', nameKu: 'بەتاوین'),
        IraqDistrict(key: 'basateen', nameAr: 'البساتين', nameEn: 'Basateen', nameKu: 'بەسەتین'),
        IraqDistrict(key: 'bakriya', nameAr: 'البكرية', nameEn: 'Bakriya', nameKu: 'بەکریە'),
        IraqDistrict(key: 'bunouk', nameAr: 'البنوك', nameEn: 'Bunouk', nameKu: 'بنووک'),
        IraqDistrict(key: 'tajat', nameAr: 'التاجات', nameEn: 'Tajat', nameKu: 'تاجات'),
        IraqDistrict(key: 'turath', nameAr: 'التراث', nameEn: 'Turath', nameKu: 'تووراس'),
        IraqDistrict(key: 'thaalba', nameAr: 'الثعالبة', nameEn: 'Thaalba', nameKu: 'سەعالەبە'),
        IraqDistrict(key: 'habibiya', nameAr: 'الحبيبية', nameEn: 'Habibiya', nameKu: 'حەبیبیە'),
        IraqDistrict(key: 'dulaie', nameAr: 'الدولعي', nameEn: 'Dulaie', nameKu: 'دۆلەعی'),
        IraqDistrict(key: 'rashidiya', nameAr: 'الراشدية', nameEn: 'Rashidiya', nameKu: 'ڕاشیدیە'),
        IraqDistrict(key: 'radhwaniya', nameAr: 'الرضوانية', nameEn: 'Radhwaniya', nameKu: 'ڕەزsurfaceوانیە'),
        IraqDistrict(key: 'shaljiya', nameAr: 'الشالجية', nameEn: 'Shaljiya', nameKu: 'شالچیە'),
        IraqDistrict(key: 'tarmiya', nameAr: 'الطارمية', nameEn: 'Tarmiya', nameKu: 'تارمیە'),
        IraqDistrict(key: 'talibiya', nameAr: 'الطالبية', nameEn: 'Talibiya', nameKu: 'تالیبیە'),
        IraqDistrict(key: 'kamaliya', nameAr: 'الكمالية', nameEn: 'Kamaliya', nameKu: 'کەمالیە'),
        IraqDistrict(key: 'mamoun', nameAr: 'المأمون', nameEn: 'Mamoun', nameKu: 'مەئموون'),
        IraqDistrict(key: 'madaen', nameAr: 'المدائن', nameEn: 'Madaen', nameKu: 'مەدائین'),
        IraqDistrict(key: 'mustansiriya', nameAr: 'المستنصرية', nameEn: 'Mustansiriya', nameKu: 'مستەنسریە'),
        IraqDistrict(key: 'mechanic', nameAr: 'الميكانيك', nameEn: 'Mechanic', nameKu: 'میکانیک'),
        IraqDistrict(key: 'nahdha', nameAr: 'النهضة', nameEn: 'Nahdha', nameKu: 'نەهزە'),
        IraqDistrict(key: 'waziriya', nameAr: 'الوزيرية', nameEn: 'Waziriya', nameKu: 'وەزیریە'),
        IraqDistrict(key: 'yousifiya', nameAr: 'اليوسفية', nameEn: 'Yousifiya', nameKu: 'یووسفیە'),
        IraqDistrict(key: 'bismayah', nameAr: 'بسماية', nameEn: 'Bismayah', nameKu: 'ببسمایە'),
        IraqDistrict(key: 'jamila', nameAr: 'جميلة', nameEn: 'Jamila', nameKu: 'جەمیلە'),
        IraqDistrict(key: 'latifiya', nameAr: 'اللطيفية', nameEn: 'Latifiya', nameKu: 'لەتیفیە'),
        IraqDistrict(key: 'qahira', nameAr: 'حي القاهرة', nameEn: 'Hay Al-Qahira', nameKu: 'گەڕەکی قاهیرە'),
        IraqDistrict(key: 'tunis', nameAr: 'حي تونس', nameEn: 'Hay Tunis', nameKu: 'گەڕەکی توونس'),
        IraqDistrict(key: 'furat', nameAr: 'حي الفرات', nameEn: 'Hay Al-Furat', nameKu: 'گەڕەکی فوڕات'),
        IraqDistrict(key: 'sabaa_abkar', nameAr: 'سبع أبكار', nameEn: 'Sabaa Abkar', nameKu: 'سەبع ئەبکار'),
        IraqDistrict(key: 'bob_alsham', nameAr: 'بوب الشام', nameEn: 'Bob Al-Sham', nameKu: 'بۆب ئەلشام'),
        IraqDistrict(key: 'camp_sarah', nameAr: 'كمب سارة', nameEn: 'Camp Sarah', nameKu: 'کەمپی سارە'),
        IraqDistrict(key: 'wahda', nameAr: 'حي الوحدة', nameEn: 'Hay Al-Wahda', nameKu: 'گەڕەکی وەحدە'),
        IraqDistrict(key: 'swaib', nameAr: 'سويب', nameEn: 'Swaib', nameKu: 'سوێب'),
        IraqDistrict(key: 'muntadhar', nameAr: 'حي المنتظر', nameEn: 'Hay Al-Muntadhar', nameKu: 'گەڕەکی مونتەزەر'),
        IraqDistrict(key: 'tariq', nameAr: 'حي طارق', nameEn: 'Hay Tariq', nameKu: 'گەڕەکی تاریق'),
        IraqDistrict(key: 'fahhama', nameAr: 'الفحامة', nameEn: 'Fahhama', nameKu: 'فەحامە'),
        IraqDistrict(key: 'other_baghdad', nameAr: 'مناطق أخرى - بغداد', nameEn: 'Other - Baghdad', nameKu: 'ناوچەکانی تر - بەغدا'),
      ],
    ),

    // ===== 2. البصرة =====
    IraqGovernorate(
      key: 'basra',
      nameAr: 'البصرة',
      nameEn: 'Basra',
      nameKu: 'بەسرە',
      districts: [
        IraqDistrict(key: 'basra_old', nameAr: 'البصرة القديمة', nameEn: 'Old Basra', nameKu: 'بەسرەی کۆن'),
        IraqDistrict(key: 'zubayr', nameAr: 'الزبير', nameEn: 'Zubayr', nameKu: 'زوبەیر'),
        IraqDistrict(key: 'abu_khaseeb', nameAr: 'أبو الخصيب', nameEn: 'Abu Khaseeb', nameKu: 'ئەبوولخەسیب'),
        IraqDistrict(key: 'faw', nameAr: 'الفاو', nameEn: 'Faw', nameKu: 'فاو'),
        IraqDistrict(key: 'qurna', nameAr: 'القرنة', nameEn: 'Qurna', nameKu: 'قوڕنە'),
        IraqDistrict(key: 'shatt_arab', nameAr: 'شط العرب', nameEn: 'Shatt Al-Arab', nameKu: 'شەتولعەرەب'),
        IraqDistrict(key: 'jazaer', nameAr: 'الجزائر', nameEn: 'Jazaer', nameKu: 'جەزائیر'),
        IraqDistrict(key: 'mdina_basra', nameAr: 'مدينة البصرة', nameEn: 'Basra City', nameKu: 'شاری بەسرە'),
        IraqDistrict(key: 'corniche', nameAr: 'الكورنيش', nameEn: 'Corniche', nameKu: 'کۆڕنیش'),
        IraqDistrict(key: 'ashar', nameAr: 'العشار', nameEn: 'Ashar', nameKu: 'عوشار'),
        IraqDistrict(key: 'muqal', nameAr: 'المقال', nameEn: 'Muqal', nameKu: 'مەعقەل'),
        IraqDistrict(key: 'brayhah', nameAr: 'البريهة', nameEn: 'Brayhah', nameKu: 'بڕەیهە'),
        IraqDistrict(key: 'hartha', nameAr: 'الحارثة', nameEn: 'Hartha', nameKu: 'حارسە'),
        IraqDistrict(key: 'mdaina', nameAr: 'المدينة', nameEn: 'Al-Madina', nameKu: 'مەدینە'),
        IraqDistrict(key: 'other_basra', nameAr: 'مناطق أخرى - البصرة', nameEn: 'Other - Basra', nameKu: 'ناوچەکانی تر - بەسرە'),
      ],
    ),

    // ===== 3. نينوى (الموصل) =====
    IraqGovernorate(
      key: 'nineveh',
      nameAr: 'نينوى',
      nameEn: 'Nineveh',
      nameKu: 'نەینەوا',
      districts: [
        IraqDistrict(key: 'mosul_left', nameAr: 'الجانب الأيسر', nameEn: 'Left Side', nameKu: 'بەشی چەپ (مووسڵ)'),
        IraqDistrict(key: 'mosul_right', nameAr: 'الجانب الأيمن', nameEn: 'Right Side', nameKu: 'بەشی ڕاست (مووسڵ)'),
        IraqDistrict(key: 'bartella', nameAr: 'برطلة', nameEn: 'Bartella', nameKu: 'بەرتلە'),
        IraqDistrict(key: 'hamdaniya', nameAr: 'الحمدانية', nameEn: 'Hamdaniya', nameKu: 'حەمدانیە'),
        IraqDistrict(key: 'sinjar', nameAr: 'سنجار', nameEn: 'Sinjar', nameKu: 'شنگال'),
        IraqDistrict(key: 'tal_afar', nameAr: 'تلعفر', nameEn: 'Tal Afar', nameKu: 'تەلەعفەر'),
        IraqDistrict(key: 'bashiqa', nameAr: 'بعشيقة', nameEn: 'Baashiqa', nameKu: 'بەعشیقە'),
        IraqDistrict(key: 'qayyara', nameAr: 'القيارة', nameEn: 'Qayyara', nameKu: 'گەیارە'),
        IraqDistrict(key: 'tilkaif', nameAr: 'تلكيف', nameEn: 'Tilkaif', nameKu: 'تلکێف'),
        IraqDistrict(key: 'rabea', nameAr: 'ربيعة', nameEn: 'Rabea', nameKu: 'ڕەبیعە'),
        IraqDistrict(key: 'other_nineveh', nameAr: 'مناطق أخرى - نينوى', nameEn: 'Other - Nineveh', nameKu: 'ناوچەکانی تر - نەینەوا'),
      ],
    ),

    // ===== 4. أربيل =====
    IraqGovernorate(
      key: 'erbil',
      nameAr: 'أربيل',
      nameEn: 'Erbil',
      nameKu: 'هەولێر',
      districts: [
        IraqDistrict(key: 'erbil_center', nameAr: 'مركز أربيل', nameEn: 'Erbil Center', nameKu: 'ناوەندی هەولێر'),
        IraqDistrict(key: 'ankawa', nameAr: 'عنكاوا', nameEn: 'Ankawa', nameKu: 'عەنکاوە'),
        IraqDistrict(key: 'shaqlawa', nameAr: 'شقلاوة', nameEn: 'Shaqlawa', nameKu: 'شەقڵاوە'),
        IraqDistrict(key: 'soran', nameAr: 'سوران', nameEn: 'Soran', nameKu: 'سۆران'),
        IraqDistrict(key: 'makhmour', nameAr: 'مخمور', nameEn: 'Makhmour', nameKu: 'مەخموور'),
        IraqDistrict(key: 'mergasur', nameAr: 'مرگسور', nameEn: 'Mergasur', nameKu: 'مێرگەسۆر'),
        IraqDistrict(key: 'khabat', nameAr: 'خبات', nameEn: 'Khabat', nameKu: 'خەبات'),
        IraqDistrict(key: 'koya', nameAr: 'كويسنجق', nameEn: 'Koya', nameKu: 'کۆیە'),
        IraqDistrict(key: 'other_erbil', nameAr: 'مناطق أخرى - أربيل', nameEn: 'Other - Erbil', nameKu: 'ناوچەکانی تر - هەولێر'),
      ],
    ),

    // ===== 5. السليمانية =====
    IraqGovernorate(
      key: 'sulaymaniyah',
      nameAr: 'السليمانية',
      nameEn: 'Sulaymaniyah',
      nameKu: 'سلێمانی',
      districts: [
        IraqDistrict(key: 'suly_center', nameAr: 'مركز السليمانية', nameEn: 'Sulaymaniyah Center', nameKu: 'ناوەندی سلێمانی'),
        IraqDistrict(key: 'chamchamal', nameAr: 'چمچمال', nameEn: 'Chamchamal', nameKu: 'چەمچەماڵ'),
        IraqDistrict(key: 'ranya', nameAr: 'رانية', nameEn: 'Ranya', nameKu: 'ڕانیە'),
        IraqDistrict(key: 'penjwin', nameAr: 'پنجوين', nameEn: 'Penjwin', nameKu: 'پێنجوێن'),
        IraqDistrict(key: 'halabja', nameAr: 'حلبجة', nameEn: 'Halabja', nameKu: 'هەڵەبجە'),
        IraqDistrict(key: 'darbandikhan', nameAr: 'دربندیخان', nameEn: 'Darbandikhan', nameKu: 'دەربەندیخان'),
        IraqDistrict(key: 'kalar', nameAr: 'كلار', nameEn: 'Kalar', nameKu: 'کەلار'),
        IraqDistrict(key: 'other_suly', nameAr: 'مناطق أخرى - السليمانية', nameEn: 'Other - Sulaymaniyah', nameKu: 'ناوچەکانی تر - سلێمانی'),
      ],
    ),

    // ===== 6. ديالى =====
    IraqGovernorate(
      key: 'diyala',
      nameAr: 'ديالى',
      nameEn: 'Diyala',
      nameKu: 'دیالە',
      districts: [
        IraqDistrict(key: 'baquba', nameAr: 'بعقوبة', nameEn: 'Baquba', nameKu: 'بەعقووبە'),
        IraqDistrict(key: 'khalis', nameAr: 'الخالص', nameEn: 'Khalis', nameKu: 'خاڵس'),
        IraqDistrict(key: 'muqdadiya', nameAr: 'المقدادية', nameEn: 'Muqdadiya', nameKu: 'میقدادیە'),
        IraqDistrict(key: 'khanaqin', nameAr: 'خانقين', nameEn: 'Khanaqin', nameKu: 'خانەقین'),
        IraqDistrict(key: 'mandali', nameAr: 'منذلي', nameEn: 'Mandali', nameKu: 'مەندەلی'),
        IraqDistrict(key: 'balad_ruz', nameAr: 'بلد روز', nameEn: 'Balad Ruz', nameKu: 'بەلەدەرووز'),
        IraqDistrict(key: 'qara_tapa', nameAr: 'قرة تبة', nameEn: 'Qara Tapa', nameKu: 'قەرەتەپە'),
        IraqDistrict(key: 'other_diyala', nameAr: 'مناطق أخرى - ديالى', nameEn: 'Other - Diyala', nameKu: 'ناوچەکانی تر - دیالە'),
      ],
    ),

    // ===== 7. الأنبار =====
    IraqGovernorate(
      key: 'anbar',
      nameAr: 'الأنبار',
      nameEn: 'Anbar',
      nameKu: 'ئەنبار',
      districts: [
        IraqDistrict(key: 'ramadi', nameAr: 'الرمادي', nameEn: 'Ramadi', nameKu: 'ڕەمادی'),
        IraqDistrict(key: 'falluja', nameAr: 'الفلوجة', nameEn: 'Falluja', nameKu: 'فەلووجە'),
        IraqDistrict(key: 'haditha', nameAr: 'حديثة', nameEn: 'Haditha', nameKu: 'حەدیسە'),
        IraqDistrict(key: 'heet', nameAr: 'هيت', nameEn: 'Heet', nameKu: 'هیت'),
        IraqDistrict(key: 'rutba', nameAr: 'الرطبة', nameEn: 'Rutba', nameKu: 'ڕوتبە'),
        IraqDistrict(key: 'qaim', nameAr: 'القائم', nameEn: 'Al-Qaim', nameKu: 'قائیم'),
        IraqDistrict(key: 'anah', nameAr: 'عانة', nameEn: 'Anah', nameKu: 'عانە'),
        IraqDistrict(key: 'rawa', nameAr: 'راوة', nameEn: 'Rawa', nameKu: 'ڕاوە'),
        IraqDistrict(key: 'other_anbar', nameAr: 'مناطق أخرى - الأنبار', nameEn: 'Other - Anbar', nameKu: 'ناوچەکانی تر - ئەنبار'),
      ],
    ),

    // ===== 8. صلاح الدين =====
    IraqGovernorate(
      key: 'saladin',
      nameAr: 'صلاح الدين',
      nameEn: 'Saladin',
      nameKu: 'سەڵاحەددین',
      districts: [
        IraqDistrict(key: 'tikrit', nameAr: 'تكريت', nameEn: 'Tikrit', nameKu: 'تکریت'),
        IraqDistrict(key: 'samarra', nameAr: 'سامراء', nameEn: 'Samarra', nameKu: 'سامەڕا'),
        IraqDistrict(key: 'baiji', nameAr: 'بيجي', nameEn: 'Baiji', nameKu: 'بێجی'),
        IraqDistrict(key: 'shirqat', nameAr: 'الشرقاط', nameEn: 'Shirqat', nameKu: 'شەرقات'),
        IraqDistrict(key: 'dujail', nameAr: 'الدجيل', nameEn: 'Dujail', nameKu: 'دوجەیل'),
        IraqDistrict(key: 'tuz', nameAr: 'طوز خورماتو', nameEn: 'Tuz Khurmatu', nameKu: 'دووزخورماتوو'),
        IraqDistrict(key: 'duluiya', nameAr: 'الدلوية', nameEn: 'Duluiya', nameKu: 'زلووعیە'),
        IraqDistrict(key: 'other_saladin', nameAr: 'مناطق أخرى - صلاح الدين', nameEn: 'Other - Saladin', nameKu: 'ناوچەکانی تر - سەڵاحەددین'),
      ],
    ),

    // ===== 9. كركوك =====
    IraqGovernorate(
      key: 'kirkuk',
      nameAr: 'كركوك',
      nameEn: 'Kirkuk',
      nameKu: 'کەرکووک',
      districts: [
        IraqDistrict(key: 'kirkuk_center', nameAr: 'مركز كركوك', nameEn: 'Kirkuk Center', nameKu: 'ناوەندی کەرکووک'),
        IraqDistrict(key: 'daquq', nameAr: 'داقوق', nameEn: 'Daquq', nameKu: 'داقووق'),
        IraqDistrict(key: 'hawija', nameAr: 'الحويجة', nameEn: 'Hawija', nameKu: 'حەویجە'),
        IraqDistrict(key: 'dibis', nameAr: 'دبس', nameEn: 'Dibis', nameKu: 'دووبز'),
        IraqDistrict(key: 'other_kirkuk', nameAr: 'مناطق أخرى - كركوك', nameEn: 'Other - Kirkuk', nameKu: 'ناوچەکانی تر - کەرکووک'),
      ],
    ),

    // ===== 10. دهوك =====
    IraqGovernorate(
      key: 'duhok',
      nameAr: 'دهوك',
      nameEn: 'Duhok',
      nameKu: 'دهۆک',
      districts: [
        IraqDistrict(key: 'duhok_center', nameAr: 'مركز دهوك', nameEn: 'Duhok Center', nameKu: 'ناوەندی دهۆک'),
        IraqDistrict(key: 'zakho', nameAr: 'زاخو', nameEn: 'Zakho', nameKu: 'زاخۆ'),
        IraqDistrict(key: 'amadiya', nameAr: 'العمادية', nameEn: 'Amadiya', nameKu: 'ئامێدی'),
        IraqDistrict(key: 'sumel', nameAr: 'سميل', nameEn: 'Sumel', nameKu: 'سێمێل'),
        IraqDistrict(key: 'shekhan', nameAr: 'الشيخان', nameEn: 'Shekhan', nameKu: 'شێخان'),
        IraqDistrict(key: 'other_duhok', nameAr: 'مناطق أخرى - دهوك', nameEn: 'Other - Duhok', nameKu: 'ناوچەکانی تر - دهۆک'),
      ],
    ),

    // ===== 11. واسط =====
    IraqGovernorate(
      key: 'wasit',
      nameAr: 'واسط',
      nameEn: 'Wasit',
      nameKu: 'واست',
      districts: [
        IraqDistrict(key: 'kut', nameAr: 'الكوت', nameEn: 'Kut', nameKu: 'کووت'),
        IraqDistrict(key: 'numaniya', nameAr: 'النعمانية', nameEn: 'Numaniya', nameKu: 'نوعمانیە'),
        IraqDistrict(key: 'hay', nameAr: 'الحي', nameEn: 'Hay', nameKu: 'حەی'),
        IraqDistrict(key: 'badra', nameAr: 'بدرة', nameEn: 'Badra', nameKu: 'بەدرە'),
        IraqDistrict(key: 'jassan', nameAr: 'جصان', nameEn: 'Jassan', nameKu: 'جەسان'),
        IraqDistrict(key: 'other_wasit', nameAr: 'مناطق أخرى - واسط', nameEn: 'Other - Wasit', nameKu: 'ناوچەکانی تر - واست'),
      ],
    ),

    // ===== 12. ميسان =====
    IraqGovernorate(
      key: 'maysan',
      nameAr: 'ميسان',
      nameEn: 'Maysan',
      nameKu: 'مەیسان',
      districts: [
        IraqDistrict(key: 'amara', nameAr: 'العمارة', nameEn: 'Amara', nameKu: 'عەمارە'),
        IraqDistrict(key: 'ali_gharbi', nameAr: 'علي الغربي', nameEn: 'Ali Al-Gharbi', nameKu: 'عەلی غەربی'),
        IraqDistrict(key: 'qalat_salih', nameAr: 'قلعة صالح', nameEn: 'Qalat Salih', nameKu: 'قەڵای ساڵح'),
        IraqDistrict(key: 'maymuna', nameAr: 'الميمونة', nameEn: 'Maymuna', nameKu: 'مەیموونة'),
        IraqDistrict(key: 'other_maysan', nameAr: 'مناطق أخرى - ميسان', nameEn: 'Other - Maysan', nameKu: 'ناوچەکانی تر - مەیسان'),
      ],
    ),

    // ===== 13. ذي قار =====
    IraqGovernorate(
      key: 'dhi_qar',
      nameAr: 'ذي قار',
      nameEn: 'Dhi Qar',
      nameKu: 'زیقار',
      districts: [
        IraqDistrict(key: 'nasiriyah', nameAr: 'الناصرية', nameEn: 'Nasiriyah', nameKu: 'ناسڕیە'),
        IraqDistrict(key: 'suq_shuyukh', nameAr: 'سوق الشيوخ', nameEn: 'Suq Al-Shuyukh', nameKu: 'سووقولشیووخ'),
        IraqDistrict(key: 'shatra', nameAr: 'الشطرة', nameEn: 'Shatra', nameKu: 'شەترە'),
        IraqDistrict(key: 'refai', nameAr: 'الرفاعي', nameEn: 'Rifai', nameKu: 'ڕیفاعی'),
        IraqDistrict(key: 'chibayish', nameAr: 'الجبايش', nameEn: 'Chibayish', nameKu: 'جباییش'),
        IraqDistrict(key: 'qurna_dhiqar', nameAr: 'القرنة', nameEn: 'Qurna', nameKu: 'قوڕنە'),
        IraqDistrict(key: 'other_dhiqar', nameAr: 'مناطق أخرى - ذي قار', nameEn: 'Other - Dhi Qar', nameKu: 'ناوچەکانی تر - زیقار'),
      ],
    ),

    // ===== 14. المثنى =====
    IraqGovernorate(
      key: 'muthanna',
      nameAr: 'المثنى',
      nameEn: 'Muthanna',
      nameKu: 'موسەننا',
      districts: [
        IraqDistrict(key: 'samawa', nameAr: 'السماوة', nameEn: 'Samawa', nameKu: 'سەماوە'),
        IraqDistrict(key: 'rumaitha', nameAr: 'الرميثة', nameEn: 'Rumaitha', nameKu: 'ڕومەیسە'),
        IraqDistrict(key: 'khidir', nameAr: 'الخضر', nameEn: 'Khidir', nameKu: 'خدر'),
        IraqDistrict(key: 'other_muthanna', nameAr: 'مناطق أخرى - المثنى', nameEn: 'Other - Muthanna', nameKu: 'ناوچەکانی تر - موسەننا'),
      ],
    ),

    // ===== 15. القادسية =====
    IraqGovernorate(
      key: 'qadisiyyah',
      nameAr: 'القادسية',
      nameEn: 'Qadisiyyah',
      nameKu: 'قادسیە',
      districts: [
        IraqDistrict(key: 'diwaniya', nameAr: 'الديوانية', nameEn: 'Diwaniya', nameKu: 'دیوانیە'),
        IraqDistrict(key: 'afak', nameAr: 'عفك', nameEn: 'Afak', nameKu: 'عەفەک'),
        IraqDistrict(key: 'shamiya', nameAr: 'الشامية', nameEn: 'Shamiya', nameKu: 'شامیە'),
        IraqDistrict(key: 'hamza', nameAr: 'الحمزة', nameEn: 'Hamza', nameKu: 'حەمزە'),
        IraqDistrict(key: 'other_qadisiyyah', nameAr: 'مناطق أخرى - القادسية', nameEn: 'Other - Qadisiyyah', nameKu: 'ناوچەکانی تر - قادسیە'),
      ],
    ),

    // ===== 16. بابل =====
    IraqGovernorate(
      key: 'babylon',
      nameAr: 'بابل',
      nameEn: 'Babylon',
      nameKu: 'بابل',
      districts: [
        IraqDistrict(key: 'hilla', nameAr: 'الحلة', nameEn: 'Hilla', nameKu: 'حللە'),
        IraqDistrict(key: 'mahawil', nameAr: 'المحاويل', nameEn: 'Mahawil', nameKu: 'مەحاویل'),
        IraqDistrict(key: 'musayab', nameAr: 'المسيب', nameEn: 'Musayab', nameKu: 'موسەییب'),
        IraqDistrict(key: 'hashimiya', nameAr: 'الهاشمية', nameEn: 'Hashimiya', nameKu: 'هاشمیە'),
        IraqDistrict(key: 'qasim', nameAr: 'القاسم', nameEn: 'Qasim', nameKu: 'قاسم'),
        IraqDistrict(key: 'iskandriya', nameAr: 'ناحية الإسكندرية', nameEn: 'Iskandriya', nameKu: 'ئەسکەندەریە'),
        IraqDistrict(key: 'other_babylon', nameAr: 'مناطق أخرى - بابل', nameEn: 'Other - Babylon', nameKu: 'ناوچەکانی تر - بابل'),
      ],
    ),

    // ===== 17. كربلاء =====
    IraqGovernorate(
      key: 'karbala',
      nameAr: 'كربلاء',
      nameEn: 'Karbala',
      nameKu: 'کەربەلا',
      districts: [
        IraqDistrict(key: 'karbala_center', nameAr: 'مركز كربلاء', nameEn: 'Karbala Center', nameKu: 'ناوەندی کەربەلا'),
        IraqDistrict(key: 'ain_tamur', nameAr: 'عين التمر', nameEn: 'Ain Tamur', nameKu: 'عەینوولتەمەر'),
        IraqDistrict(key: 'hindiya', nameAr: 'الهندية', nameEn: 'Hindiya', nameKu: 'هیندیە'),
        IraqDistrict(key: 'other_karbala', nameAr: 'مناطق أخرى - كربلاء', nameEn: 'Other - Karbala', nameKu: 'ناوچەکانی تر - کەربەلا'),
      ],
    ),

    // ===== 18. النجف =====
    IraqGovernorate(
      key: 'najaf',
      nameAr: 'النجف',
      nameEn: 'Najaf',
      nameKu: 'نەجەف',
      districts: [
        IraqDistrict(key: 'najaf_center', nameAr: 'مركز النجف', nameEn: 'Najaf Center', nameKu: 'ناوەندی نەجەف'),
        IraqDistrict(key: 'kufa', nameAr: 'الكوفة', nameEn: 'Kufa', nameKu: 'کووفە'),
        IraqDistrict(key: 'manathira', nameAr: 'المناذرة', nameEn: 'Manathira', nameKu: 'مەنازیرە'),
        IraqDistrict(key: 'abbasiya', nameAr: 'العباسية', nameEn: 'Abbasiya', nameKu: 'عەبباسیە'),
        IraqDistrict(key: 'other_najaf', nameAr: 'مناطق أخرى - النجف', nameEn: 'Other - Najaf', nameKu: 'ناوچەکانی تر - نەجەف'),
      ],
    ),
  ];
}
