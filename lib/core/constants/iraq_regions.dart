/// 📝 HINT AR: بيانات المحافظات والمناطق العراقية — Fallback ثابت
/// هذا الملف هو الطبقة الاحتياطية (Hardcoded Fallback) من نظام Hybrid:
///   - المستوى 1: هذا الملف — يعمل بدون إنترنت وبدون أي تكلفة
///   - المستوى 2: Firestore — المصدر الرسمي الذي يديره الأدمن
///   - المستوى 3: Remote Config — للتصحيحات العاجلة بدون تحديث
///
/// تحديث هذا الملف: فقط عند إصدار تحديث جديد للتطبيق
/// تحديث Firestore: فوري وينعكس على الجميع بدون تحديث
library;

// ============================================================
//  نموذج بسيط للاستخدام الداخلي في هذا الملف فقط
// ============================================================

/// 📝 HINT AR: يمثل منطقة واحدة داخل محافظة
/// [key] المفتاح الفريد — يُستخدم للبحث والفلترة (لا يتغير بتغيير اللغة)
/// [nameAr] الاسم بالعربية
/// [nameEn] الاسم بالإنجليزية
class IraqDistrict {
  final String key;
  final String nameAr;
  final String nameEn;

  const IraqDistrict({
    required this.key,
    required this.nameAr,
    required this.nameEn,
  });
}

/// 📝 HINT AR: يمثل محافظة واحدة مع قائمة مناطقها
/// [key] نفس cityId في Firestore — الربط الأساسي
class IraqGovernorate {
  final String key;
  final String nameAr;
  final String nameEn;
  final List<IraqDistrict> districts;

  const IraqGovernorate({
    required this.key,
    required this.nameAr,
    required this.nameEn,
    required this.districts,
  });
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

  /// 📝 HINT AR: جلب مناطق محافظة بالاسم العربي — يُستخدم عندما يكون cityId هو UUID من Firestore
  /// المطابقة مرنة: تقبل الاسم بدقة أو مع فوارق في المسافات
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

  /// 📝 HINT AR: جلب مناطق محافظة بالاسم الإنجليزي (للغة الإنجليزية)
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
  /// هذه هي الدالة الشاملة التي تضمن إيجاد البيانات بغض النظر عن طريقة البحث
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
  //  بيانات المحافظات الـ 18 مع مناطقها
  // ============================================================

  static const List<IraqGovernorate> _governorates = [
    // ===== 1. بغداد =====
    IraqGovernorate(
      key: 'baghdad',
      nameAr: 'بغداد',
      nameEn: 'Baghdad',
      districts: [
        IraqDistrict(key: 'krada', nameAr: 'الكرادة', nameEn: 'Krada'),
        IraqDistrict(key: 'mansour', nameAr: 'المنصور', nameEn: 'Mansour'),
        IraqDistrict(key: 'kadhimia', nameAr: 'الكاظمية', nameEn: 'Kadhimia'),
        IraqDistrict(key: 'adhamia', nameAr: 'الأعظمية', nameEn: 'Adhamia'),
        IraqDistrict(
            key: 'new_baghdad', nameAr: 'بغداد الجديدة', nameEn: 'New Baghdad'),
        IraqDistrict(key: 'dora', nameAr: 'الدورة', nameEn: 'Dora'),
        IraqDistrict(key: 'saydia', nameAr: 'السيدية', nameEn: 'Saydia'),
        IraqDistrict(key: 'ameria', nameAr: 'العامرية', nameEn: 'Ameria'),
        IraqDistrict(key: 'ghazalia', nameAr: 'الغزالية', nameEn: 'Ghazalia'),
        IraqDistrict(key: 'jadriya', nameAr: 'الجادرية', nameEn: 'Jadriya'),
        IraqDistrict(
            key: 'zafaraniya', nameAr: 'الزعفرانية', nameEn: 'Zafaraniya'),
        IraqDistrict(key: 'shaab', nameAr: 'الشعب', nameEn: 'Shaab'),
        IraqDistrict(key: 'washash', nameAr: 'الوشاش', nameEn: 'Washash'),
        IraqDistrict(key: 'zayona', nameAr: 'زيونة', nameEn: 'Zayona'),
        IraqDistrict(key: 'mashtal', nameAr: 'المشتل', nameEn: 'Mashtal'),
        IraqDistrict(
            key: 'palestine_st',
            nameAr: 'شارع فلسطين',
            nameEn: 'Palestine Street'),
        IraqDistrict(key: 'sinaa', nameAr: 'الصناعة', nameEn: 'Sinaa'),
        IraqDistrict(
            key: 'university',
            nameAr: 'حي الجامعة',
            nameEn: 'University District'),
        IraqDistrict(key: 'baiyaa', nameAr: 'البياع', nameEn: 'Baiyaa'),
        IraqDistrict(key: 'jihad', nameAr: 'الجهاد', nameEn: 'Jihad'),
        IraqDistrict(key: 'shuala', nameAr: 'الشعلة', nameEn: 'Shuala'),
        IraqDistrict(key: 'huriya', nameAr: 'الحرية', nameEn: 'Huriya'),
        IraqDistrict(
            key: 'sadr_city', nameAr: 'مدينة الصدر', nameEn: 'Sadr City'),
        IraqDistrict(
            key: 'abu_ghraib', nameAr: 'أبو غريب', nameEn: 'Abu Ghraib'),
        IraqDistrict(key: 'taji', nameAr: 'التاجي', nameEn: 'Taji'),
        IraqDistrict(
            key: 'mahmudiya', nameAr: 'المحمودية', nameEn: 'Mahmudiya'),
        IraqDistrict(key: 'nahrawan', nameAr: 'النهروان', nameEn: 'Nahrawan'),
        IraqDistrict(key: 'tobchi', nameAr: 'طوبچي', nameEn: 'Tobchi'),
        IraqDistrict(key: 'iskan', nameAr: 'الإسكان', nameEn: 'Iskan'),
        IraqDistrict(
            key: 'diyala_bridge', nameAr: 'جسر ديالى', nameEn: 'Diyala Bridge'),
        IraqDistrict(key: 'aamel', nameAr: 'العامل', nameEn: 'Aamel'),
        IraqDistrict(key: 'harthiya', nameAr: 'الحارثية', nameEn: 'Harthiya'),
        IraqDistrict(key: 'qadisiya', nameAr: 'القادسية', nameEn: 'Qadisiya'),
        IraqDistrict(key: 'yarmouk', nameAr: 'اليرموك', nameEn: 'Yarmouk'),
        IraqDistrict(key: 'maalif', nameAr: 'المعلف', nameEn: 'Maalif'),
        IraqDistrict(key: 'shurta', nameAr: 'الشرطة', nameEn: 'Shurta'),
        IraqDistrict(
            key: 'bab_moatham', nameAr: 'باب المعظم', nameEn: 'Bab Moatham'),
        IraqDistrict(
            key: 'rahmaniya', nameAr: 'الرحمانية', nameEn: 'Rahmaniya'),
        IraqDistrict(
            key: 'bab_alsharqi',
            nameAr: 'الباب الشرقي',
            nameEn: 'Bab Al-Sharqi'),
        IraqDistrict(key: 'sinak', nameAr: 'السنك', nameEn: 'Sinak'),
        IraqDistrict(key: 'shorja', nameAr: 'الشورجة', nameEn: 'Shorja'),
        IraqDistrict(
            key: 'bab_alsheikh', nameAr: 'باب الشيخ', nameEn: 'Bab Al-Sheikh'),
        IraqDistrict(key: 'fadhil', nameAr: 'الفضل', nameEn: 'Fadhil'),
        IraqDistrict(key: 'sadria', nameAr: 'الصدرية', nameEn: 'Sadria'),
        IraqDistrict(
            key: 'sheikh_omar', nameAr: 'الشيخ عمر', nameEn: 'Sheikh Omar'),
        IraqDistrict(key: 'maidain', nameAr: 'الميدان', nameEn: 'Maidan'),
        IraqDistrict(
            key: 'abbakhana', nameAr: 'العباخانة', nameEn: 'Abbakhana'),
        IraqDistrict(
            key: 'raghiba_khatoun',
            nameAr: 'راغبة خاتون',
            nameEn: 'Raghiba Khatoun'),
        IraqDistrict(key: 'kasra', nameAr: 'الكسرة', nameEn: 'Kasra'),
        IraqDistrict(key: 'salikh', nameAr: 'الصليخ', nameEn: 'Salikh'),
        IraqDistrict(key: 'kariyat', nameAr: 'الكريعات', nameEn: 'Kariyat'),
        IraqDistrict(key: 'safeena', nameAr: 'السفينة', nameEn: 'Safeena'),
        IraqDistrict(
            key: 'ras_alhawash', nameAr: 'رأس الحواش', nameEn: 'Ras Al-Hawash'),
        IraqDistrict(key: 'baladiyat', nameAr: 'البلديات', nameEn: 'Baladiyat'),
        IraqDistrict(key: 'ghadeer', nameAr: 'الغدير', nameEn: 'Ghadeer'),
        IraqDistrict(key: 'ameen', nameAr: 'الأمين', nameEn: 'Ameen'),
        IraqDistrict(key: 'obaidi', nameAr: 'العبيدي', nameEn: 'Obaidi'),
        IraqDistrict(key: 'salhiya', nameAr: 'الصالحية', nameEn: 'Salhiya'),
        IraqDistrict(key: 'atifiya', nameAr: 'العطيفية', nameEn: 'Atifiya'),
        IraqDistrict(key: 'allawi', nameAr: 'العلاوي', nameEn: 'Allawi'),
        IraqDistrict(
            key: 'karadat_maryam',
            nameAr: 'كرادة مريم',
            nameEn: 'Karadat Maryam'),
        IraqDistrict(key: 'dawoodi', nameAr: 'الداودي', nameEn: 'Dawoodi'),
        IraqDistrict(key: 'adl', nameAr: 'حي العدل', nameEn: 'Al-Adl'),
        IraqDistrict(key: 'seha', nameAr: 'حي الصحة', nameEn: 'Seha'),
        IraqDistrict(key: 'alam', nameAr: 'حي الإعلام', nameEn: 'Alam'),
        IraqDistrict(key: 'khadra', nameAr: 'حي الخضراء', nameEn: 'Khadra'),
        IraqDistrict(key: 'awr', nameAr: 'حي أور', nameEn: 'Awr'),
        IraqDistrict(
            key: 'sabe_qusur', nameAr: 'سبع قصور', nameEn: 'sabe qusur'),
        IraqDistrict(
            key: 'alhusaynia', nameAr: 'الحسينية', nameEn: 'alhusaynia'),
        IraqDistrict(key: 'nissan_9', nameAr: '9 نيسان', nameEn: '9 Nissan'),
        IraqDistrict(
            key: 'abu_disheer', nameAr: 'أبو دشير', nameEn: 'Abu Disheer'),
        IraqDistrict(key: 'abu_nuwas', nameAr: 'أبو نؤاس', nameEn: 'Abu Nuwas'),
        IraqDistrict(
            key: 'athuriyeen', nameAr: 'الآثوريين', nameEn: 'Athuriyeen'),
        IraqDistrict(key: 'atibaa', nameAr: 'الأطباء', nameEn: 'Atibaa'),
        IraqDistrict(key: 'amana', nameAr: 'الأمانة', nameEn: 'Amana'),
        IraqDistrict(key: 'bataween', nameAr: 'البتاوين', nameEn: 'Bataween'),
        IraqDistrict(key: 'basateen', nameAr: 'البساتين', nameEn: 'Basateen'),
        IraqDistrict(key: 'bakriya', nameAr: 'البكرية', nameEn: 'Bakriya'),
        IraqDistrict(key: 'bunouk', nameAr: 'البنوك', nameEn: 'Bunouk'),
        IraqDistrict(key: 'tajat', nameAr: 'التاجات', nameEn: 'Tajat'),
        IraqDistrict(key: 'turath', nameAr: 'التراث', nameEn: 'Turath'),
        IraqDistrict(key: 'thaalba', nameAr: 'الثعالبة', nameEn: 'Thaalba'),
        IraqDistrict(key: 'habibiya', nameAr: 'الحبيبية', nameEn: 'Habibiya'),
        IraqDistrict(key: 'dulaie', nameAr: 'الدولعي', nameEn: 'Dulaie'),
        IraqDistrict(key: 'rashidiya', nameAr: 'الراشدية', nameEn: 'Rashidiya'),
        IraqDistrict(
            key: 'radhwaniya', nameAr: 'الرضوانية', nameEn: 'Radhwaniya'),
        IraqDistrict(key: 'shaljiya', nameAr: 'الشالجية', nameEn: 'Shaljiya'),
        IraqDistrict(key: 'tarmiya', nameAr: 'الطارمية', nameEn: 'Tarmiya'),
        IraqDistrict(key: 'talibiya', nameAr: 'الطالبية', nameEn: 'Talibiya'),
        IraqDistrict(key: 'kamaliya', nameAr: 'الكمالية', nameEn: 'Kamaliya'),
        IraqDistrict(key: 'mamoun', nameAr: 'المأمون', nameEn: 'Mamoun'),
        IraqDistrict(key: 'madaen', nameAr: 'المدائن', nameEn: 'Madaen'),
        IraqDistrict(
            key: 'mustansiriya', nameAr: 'المستنصرية', nameEn: 'Mustansiriya'),
        IraqDistrict(key: 'mechanic', nameAr: 'الميكانيك', nameEn: 'Mechanic'),
        IraqDistrict(key: 'nahdha', nameAr: 'النهضة', nameEn: 'Nahdha'),
        IraqDistrict(key: 'waziriya', nameAr: 'الوزيرية', nameEn: 'Waziriya'),
        IraqDistrict(key: 'yousifiya', nameAr: 'اليوسفية', nameEn: 'Yousifiya'),
        IraqDistrict(key: 'bismayah', nameAr: 'بسماية', nameEn: 'Bismayah'),
        IraqDistrict(key: 'jamila', nameAr: 'جميلة', nameEn: 'Jamila'),
        IraqDistrict(key: 'latifiya', nameAr: 'اللطيفية', nameEn: 'Latifiya'),
        IraqDistrict(
            key: 'qahira', nameAr: 'حي القاهرة', nameEn: 'Hay Al-Qahira'),
        IraqDistrict(key: 'tunis', nameAr: 'حي تونس', nameEn: 'Hay Tunis'),
        IraqDistrict(key: 'furat', nameAr: 'حي الفرات', nameEn: 'Hay Al-Furat'),
        IraqDistrict(
            key: 'sabaa_abkar', nameAr: 'سبع أبكار', nameEn: 'Sabaa Abkar'),
        IraqDistrict(
            key: 'bob_alsham', nameAr: 'بوب الشام', nameEn: 'Bob Al-Sham'),
        IraqDistrict(
            key: 'camp_sarah', nameAr: 'كمب سارة', nameEn: 'Camp Sarah'),
        IraqDistrict(key: 'wahda', nameAr: 'حي الوحدة', nameEn: 'Hay Al-Wahda'),
        IraqDistrict(key: 'swaib', nameAr: 'سويب', nameEn: 'Swaib'),
        IraqDistrict(
            key: 'muntadhar', nameAr: 'حي المنتظر', nameEn: 'Hay Al-Muntadhar'),
        IraqDistrict(key: 'tariq', nameAr: 'حي طارق', nameEn: 'Hay Tariq'),
        IraqDistrict(key: 'fahhama', nameAr: 'الفحامة', nameEn: 'Fahhama'),
        IraqDistrict(
            key: 'other_baghdad',
            nameAr: 'مناطق أخرى - بغداد',
            nameEn: 'Other - Baghdad'),
      ],
    ),

    // ===== 2. البصرة =====
    IraqGovernorate(
      key: 'basra',
      nameAr: 'البصرة',
      nameEn: 'Basra',
      districts: [
        IraqDistrict(
            key: 'basra_old', nameAr: 'البصرة القديمة', nameEn: 'Old Basra'),
        IraqDistrict(key: 'zubayr', nameAr: 'الزبير', nameEn: 'Zubayr'),
        IraqDistrict(
            key: 'abu_khaseeb', nameAr: 'أبو الخصيب', nameEn: 'Abu Khaseeb'),
        IraqDistrict(key: 'faw', nameAr: 'الفاو', nameEn: 'Faw'),
        IraqDistrict(key: 'qurna', nameAr: 'القرنة', nameEn: 'Qurna'),
        IraqDistrict(
            key: 'shatt_arab', nameAr: 'شط العرب', nameEn: 'Shatt Al-Arab'),
        IraqDistrict(key: 'jazaer', nameAr: 'الجزائر', nameEn: 'Jazaer'),
        IraqDistrict(
            key: 'mdina_basra', nameAr: 'مدينة البصرة', nameEn: 'Basra City'),
        IraqDistrict(key: 'corniche', nameAr: 'الكورنيش', nameEn: 'Corniche'),
        IraqDistrict(key: 'ashar', nameAr: 'العشار', nameEn: 'Ashar'),
        IraqDistrict(key: 'muqal', nameAr: 'المقال', nameEn: 'Muqal'),
        IraqDistrict(key: 'brayhah', nameAr: 'البريهة', nameEn: 'Brayhah'),
        IraqDistrict(key: 'hartha', nameAr: 'الحارثة', nameEn: 'Hartha'),
        IraqDistrict(key: 'mdaina', nameAr: 'المدينة', nameEn: 'Al-Madina'),
        IraqDistrict(
            key: 'other_basra',
            nameAr: 'مناطق أخرى - البصرة',
            nameEn: 'Other - Basra'),
      ],
    ),

    // ===== 3. نينوى (الموصل) =====
    IraqGovernorate(
      key: 'nineveh',
      nameAr: 'نينوى',
      nameEn: 'Nineveh',
      districts: [
        IraqDistrict(
            key: 'mosul_left', nameAr: 'الجانب الأيسر', nameEn: 'Left Side'),
        IraqDistrict(
            key: 'mosul_right', nameAr: 'الجانب الأيمن', nameEn: 'Right Side'),
        IraqDistrict(key: 'bartella', nameAr: 'برطلة', nameEn: 'Bartella'),
        IraqDistrict(
            key: 'hamdaniya', nameAr: 'الحمدانية', nameEn: 'Hamdaniya'),
        IraqDistrict(key: 'sinjar', nameAr: 'سنجار', nameEn: 'Sinjar'),
        IraqDistrict(key: 'tal_afar', nameAr: 'تلعفر', nameEn: 'Tal Afar'),
        IraqDistrict(key: 'bashiqa', nameAr: 'بعشيقة', nameEn: 'Baashiqa'),
        IraqDistrict(key: 'qayyara', nameAr: 'القيارة', nameEn: 'Qayyara'),
        IraqDistrict(key: 'tilkaif', nameAr: 'تلكيف', nameEn: 'Tilkaif'),
        IraqDistrict(key: 'rabea', nameAr: 'ربيعة', nameEn: 'Rabea'),
        IraqDistrict(
            key: 'other_nineveh',
            nameAr: 'مناطق أخرى - نينوى',
            nameEn: 'Other - Nineveh'),
      ],
    ),

    // ===== 4. أربيل =====
    IraqGovernorate(
      key: 'erbil',
      nameAr: 'أربيل',
      nameEn: 'Erbil',
      districts: [
        IraqDistrict(
            key: 'erbil_center', nameAr: 'مركز أربيل', nameEn: 'Erbil Center'),
        IraqDistrict(key: 'ankawa', nameAr: 'عنكاوا', nameEn: 'Ankawa'),
        IraqDistrict(key: 'shaqlawa', nameAr: 'شقلاوة', nameEn: 'Shaqlawa'),
        IraqDistrict(key: 'soran', nameAr: 'سوران', nameEn: 'Soran'),
        IraqDistrict(key: 'makhmour', nameAr: 'مخمور', nameEn: 'Makhmour'),
        IraqDistrict(key: 'mergasur', nameAr: 'مرگسور', nameEn: 'Mergasur'),
        IraqDistrict(key: 'khabat', nameAr: 'خبات', nameEn: 'Khabat'),
        IraqDistrict(key: 'koya', nameAr: 'كويسنجق', nameEn: 'Koya'),
        IraqDistrict(
            key: 'other_erbil',
            nameAr: 'مناطق أخرى - أربيل',
            nameEn: 'Other - Erbil'),
      ],
    ),

    // ===== 5. السليمانية =====
    IraqGovernorate(
      key: 'sulaymaniyah',
      nameAr: 'السليمانية',
      nameEn: 'Sulaymaniyah',
      districts: [
        IraqDistrict(
            key: 'suly_center',
            nameAr: 'مركز السليمانية',
            nameEn: 'Sulaymaniyah Center'),
        IraqDistrict(key: 'chamchamal', nameAr: 'چمچمال', nameEn: 'Chamchamal'),
        IraqDistrict(key: 'ranya', nameAr: 'رانية', nameEn: 'Ranya'),
        IraqDistrict(key: 'penjwin', nameAr: 'پنجوين', nameEn: 'Penjwin'),
        IraqDistrict(key: 'halabja', nameAr: 'حلبجة', nameEn: 'Halabja'),
        IraqDistrict(
            key: 'darbandikhan', nameAr: 'دربندیخان', nameEn: 'Darbandikhan'),
        IraqDistrict(key: 'kalar', nameAr: 'كلار', nameEn: 'Kalar'),
        IraqDistrict(
            key: 'other_suly',
            nameAr: 'مناطق أخرى - السليمانية',
            nameEn: 'Other - Sulaymaniyah'),
      ],
    ),

    // ===== 6. ديالى =====
    IraqGovernorate(
      key: 'diyala',
      nameAr: 'ديالى',
      nameEn: 'Diyala',
      districts: [
        IraqDistrict(key: 'baquba', nameAr: 'بعقوبة', nameEn: 'Baquba'),
        IraqDistrict(key: 'khalis', nameAr: 'الخالص', nameEn: 'Khalis'),
        IraqDistrict(
            key: 'muqdadiya', nameAr: 'المقدادية', nameEn: 'Muqdadiya'),
        IraqDistrict(key: 'khanaqin', nameAr: 'خانقين', nameEn: 'Khanaqin'),
        IraqDistrict(key: 'mandali', nameAr: 'منذلي', nameEn: 'Mandali'),
        IraqDistrict(key: 'balad_ruz', nameAr: 'بلد روز', nameEn: 'Balad Ruz'),
        IraqDistrict(key: 'qara_tapa', nameAr: 'قرة تبة', nameEn: 'Qara Tapa'),
        IraqDistrict(
            key: 'other_diyala',
            nameAr: 'مناطق أخرى - ديالى',
            nameEn: 'Other - Diyala'),
      ],
    ),

    // ===== 7. الأنبار =====
    IraqGovernorate(
      key: 'anbar',
      nameAr: 'الأنبار',
      nameEn: 'Anbar',
      districts: [
        IraqDistrict(key: 'ramadi', nameAr: 'الرمادي', nameEn: 'Ramadi'),
        IraqDistrict(key: 'falluja', nameAr: 'الفلوجة', nameEn: 'Falluja'),
        IraqDistrict(key: 'haditha', nameAr: 'حديثة', nameEn: 'Haditha'),
        IraqDistrict(key: 'heet', nameAr: 'هيت', nameEn: 'Heet'),
        IraqDistrict(key: 'rutba', nameAr: 'الرطبة', nameEn: 'Rutba'),
        IraqDistrict(key: 'qaim', nameAr: 'القائم', nameEn: 'Al-Qaim'),
        IraqDistrict(key: 'anah', nameAr: 'عانة', nameEn: 'Anah'),
        IraqDistrict(key: 'rawa', nameAr: 'راوة', nameEn: 'Rawa'),
        IraqDistrict(
            key: 'other_anbar',
            nameAr: 'مناطق أخرى - الأنبار',
            nameEn: 'Other - Anbar'),
      ],
    ),

    // ===== 8. صلاح الدين =====
    IraqGovernorate(
      key: 'saladin',
      nameAr: 'صلاح الدين',
      nameEn: 'Saladin',
      districts: [
        IraqDistrict(key: 'tikrit', nameAr: 'تكريت', nameEn: 'Tikrit'),
        IraqDistrict(key: 'samarra', nameAr: 'سامراء', nameEn: 'Samarra'),
        IraqDistrict(key: 'baiji', nameAr: 'بيجي', nameEn: 'Baiji'),
        IraqDistrict(key: 'shirqat', nameAr: 'الشرقاط', nameEn: 'Shirqat'),
        IraqDistrict(key: 'dujail', nameAr: 'الدجيل', nameEn: 'Dujail'),
        IraqDistrict(key: 'tuz', nameAr: 'طوز خورماتو', nameEn: 'Tuz Khurmatu'),
        IraqDistrict(key: 'duluiya', nameAr: 'الدلوية', nameEn: 'Duluiya'),
        IraqDistrict(
            key: 'other_saladin',
            nameAr: 'مناطق أخرى - صلاح الدين',
            nameEn: 'Other - Saladin'),
      ],
    ),

    // ===== 9. كركوك =====
    IraqGovernorate(
      key: 'kirkuk',
      nameAr: 'كركوك',
      nameEn: 'Kirkuk',
      districts: [
        IraqDistrict(
            key: 'kirkuk_center',
            nameAr: 'مركز كركوك',
            nameEn: 'Kirkuk Center'),
        IraqDistrict(key: 'daquq', nameAr: 'داقوق', nameEn: 'Daquq'),
        IraqDistrict(key: 'hawija', nameAr: 'الحويجة', nameEn: 'Hawija'),
        IraqDistrict(key: 'dibis', nameAr: 'دبس', nameEn: 'Dibis'),
        IraqDistrict(
            key: 'other_kirkuk',
            nameAr: 'مناطق أخرى - كركوك',
            nameEn: 'Other - Kirkuk'),
      ],
    ),

    // ===== 10. دهوك =====
    IraqGovernorate(
      key: 'duhok',
      nameAr: 'دهوك',
      nameEn: 'Duhok',
      districts: [
        IraqDistrict(
            key: 'duhok_center', nameAr: 'مركز دهوك', nameEn: 'Duhok Center'),
        IraqDistrict(key: 'zakho', nameAr: 'زاخو', nameEn: 'Zakho'),
        IraqDistrict(key: 'amadiya', nameAr: 'العمادية', nameEn: 'Amadiya'),
        IraqDistrict(key: 'sumel', nameAr: 'سميل', nameEn: 'Sumel'),
        IraqDistrict(key: 'shekhan', nameAr: 'الشيخان', nameEn: 'Shekhan'),
        IraqDistrict(
            key: 'other_duhok',
            nameAr: 'مناطق أخرى - دهوك',
            nameEn: 'Other - Duhok'),
      ],
    ),

    // ===== 11. واسط =====
    IraqGovernorate(
      key: 'wasit',
      nameAr: 'واسط',
      nameEn: 'Wasit',
      districts: [
        IraqDistrict(key: 'kut', nameAr: 'الكوت', nameEn: 'Kut'),
        IraqDistrict(key: 'numaniya', nameAr: 'النعمانية', nameEn: 'Numaniya'),
        IraqDistrict(key: 'hay', nameAr: 'الحي', nameEn: 'Hay'),
        IraqDistrict(key: 'badra', nameAr: 'بدرة', nameEn: 'Badra'),
        IraqDistrict(key: 'jassan', nameAr: 'جصان', nameEn: 'Jassan'),
        IraqDistrict(
            key: 'other_wasit',
            nameAr: 'مناطق أخرى - واسط',
            nameEn: 'Other - Wasit'),
      ],
    ),

    // ===== 12. ميسان =====
    IraqGovernorate(
      key: 'maysan',
      nameAr: 'ميسان',
      nameEn: 'Maysan',
      districts: [
        IraqDistrict(key: 'amara', nameAr: 'العمارة', nameEn: 'Amara'),
        IraqDistrict(
            key: 'ali_gharbi', nameAr: 'علي الغربي', nameEn: 'Ali Al-Gharbi'),
        IraqDistrict(
            key: 'qalat_salih', nameAr: 'قلعة صالح', nameEn: 'Qalat Salih'),
        IraqDistrict(key: 'maymuna', nameAr: 'الميمونة', nameEn: 'Maymuna'),
        IraqDistrict(
            key: 'other_maysan',
            nameAr: 'مناطق أخرى - ميسان',
            nameEn: 'Other - Maysan'),
      ],
    ),

    // ===== 13. ذي قار =====
    IraqGovernorate(
      key: 'dhi_qar',
      nameAr: 'ذي قار',
      nameEn: 'Dhi Qar',
      districts: [
        IraqDistrict(key: 'nasiriyah', nameAr: 'الناصرية', nameEn: 'Nasiriyah'),
        IraqDistrict(
            key: 'suq_shuyukh', nameAr: 'سوق الشيوخ', nameEn: 'Suq Al-Shuyukh'),
        IraqDistrict(key: 'shatra', nameAr: 'الشطرة', nameEn: 'Shatra'),
        IraqDistrict(key: 'refai', nameAr: 'الرفاعي', nameEn: 'Rifai'),
        IraqDistrict(key: 'chibayish', nameAr: 'الجبايش', nameEn: 'Chibayish'),
        IraqDistrict(key: 'qurna_dhiqar', nameAr: 'القرنة', nameEn: 'Qurna'),
        IraqDistrict(
            key: 'other_dhiqar',
            nameAr: 'مناطق أخرى - ذي قار',
            nameEn: 'Other - Dhi Qar'),
      ],
    ),

    // ===== 14. المثنى =====
    IraqGovernorate(
      key: 'muthanna',
      nameAr: 'المثنى',
      nameEn: 'Muthanna',
      districts: [
        IraqDistrict(key: 'samawa', nameAr: 'السماوة', nameEn: 'Samawa'),
        IraqDistrict(key: 'rumaitha', nameAr: 'الرميثة', nameEn: 'Rumaitha'),
        IraqDistrict(key: 'khidir', nameAr: 'الخضر', nameEn: 'Khidir'),
        IraqDistrict(
            key: 'other_muthanna',
            nameAr: 'مناطق أخرى - المثنى',
            nameEn: 'Other - Muthanna'),
      ],
    ),

    // ===== 15. القادسية =====
    IraqGovernorate(
      key: 'qadisiyyah',
      nameAr: 'القادسية',
      nameEn: 'Qadisiyyah',
      districts: [
        IraqDistrict(key: 'diwaniya', nameAr: 'الديوانية', nameEn: 'Diwaniya'),
        IraqDistrict(key: 'afak', nameAr: 'عفك', nameEn: 'Afak'),
        IraqDistrict(key: 'shamiya', nameAr: 'الشامية', nameEn: 'Shamiya'),
        IraqDistrict(key: 'hamza', nameAr: 'الحمزة', nameEn: 'Hamza'),
        IraqDistrict(
            key: 'other_qadisiyyah',
            nameAr: 'مناطق أخرى - القادسية',
            nameEn: 'Other - Qadisiyyah'),
      ],
    ),

    // ===== 16. بابل =====
    IraqGovernorate(
      key: 'babylon',
      nameAr: 'بابل',
      nameEn: 'Babylon',
      districts: [
        IraqDistrict(key: 'hilla', nameAr: 'الحلة', nameEn: 'Hilla'),
        IraqDistrict(key: 'mahawil', nameAr: 'المحاويل', nameEn: 'Mahawil'),
        IraqDistrict(key: 'musayab', nameAr: 'المسيب', nameEn: 'Musayab'),
        IraqDistrict(key: 'hashimiya', nameAr: 'الهاشمية', nameEn: 'Hashimiya'),
        IraqDistrict(key: 'qasim', nameAr: 'القاسم', nameEn: 'Qasim'),
        IraqDistrict(
            key: 'iskandriya',
            nameAr: 'ناحية الإسكندرية',
            nameEn: 'Iskandriya'),
        IraqDistrict(
            key: 'other_babylon',
            nameAr: 'مناطق أخرى - بابل',
            nameEn: 'Other - Babylon'),
      ],
    ),

    // ===== 17. كربلاء =====
    IraqGovernorate(
      key: 'karbala',
      nameAr: 'كربلاء',
      nameEn: 'Karbala',
      districts: [
        IraqDistrict(
            key: 'karbala_center',
            nameAr: 'مركز كربلاء',
            nameEn: 'Karbala Center'),
        IraqDistrict(
            key: 'ain_tamur', nameAr: 'عين التمر', nameEn: 'Ain Tamur'),
        IraqDistrict(key: 'hindiya', nameAr: 'الهندية', nameEn: 'Hindiya'),
        IraqDistrict(
            key: 'other_karbala',
            nameAr: 'مناطق أخرى - كربلاء',
            nameEn: 'Other - Karbala'),
      ],
    ),

    // ===== 18. النجف =====
    IraqGovernorate(
      key: 'najaf',
      nameAr: 'النجف',
      nameEn: 'Najaf',
      districts: [
        IraqDistrict(
            key: 'najaf_center', nameAr: 'مركز النجف', nameEn: 'Najaf Center'),
        IraqDistrict(key: 'kufa', nameAr: 'الكوفة', nameEn: 'Kufa'),
        IraqDistrict(key: 'manathira', nameAr: 'المناذرة', nameEn: 'Manathira'),
        IraqDistrict(key: 'abbasiya', nameAr: 'العباسية', nameEn: 'Abbasiya'),
        IraqDistrict(
            key: 'other_najaf',
            nameAr: 'مناطق أخرى - النجف',
            nameEn: 'Other - Najaf'),
      ],
    ),
  ];
}
