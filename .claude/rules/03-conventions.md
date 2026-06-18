# قاعدة: اصطلاحات الكود

## اللغة والنصوص
- نصوص الواجهة: **عربية بلهجة عراقية** (مثل «هلا بيك»، «سجّل فريقك»).
- التعليقات التوضيحية المهمة تبدأ بـ `// 📝 HINT AR:` ثم شرح بالعربية (نمط متبع في كل المشروع).

## البنية
- ملف لكل شاشة/Cubit/Model، أسماء `snake_case.dart`.
- **Cubit لكل وحدة** (`auth/`, `team/`, `tournament/`...) مع ملف `*_state.dart` منفصل يستخدم `Equatable`.
- **Repository** يلفّ كل وصول لـ Firestore/Storage (لا وصول مباشر من الواجهة). تُحقن عبر `MultiRepositoryProvider` في `main.dart`.
- **Model** يحوي `fromJson`/`toJson` + `copyWith` + يرث `Equatable`. تُصدَّر كلها من `lib/data/models/models.dart` (barrel).

## الثيم والألوان
- استخدم `Theme.of(context)` ورموز `lib/app/theme/` — لا ألوان hardcoded.
- استبدل `withOpacity()` المهجور بـ `.withValues(alpha:)`، و`DropdownButtonFormField.value` بـ `initialValue`.

## الجودة قبل أي commit
- `flutter analyze lib` يجب أن يبقى **نظيفاً** (ملاحظات `craftsman_backup` مستثناة ولا تُحتسب).
- لا تترك استيرادات غير مستخدمة ولا كوداً ميتاً.

## Cloud Functions
- JavaScript، صياغة **v2 فقط**، ESLint نظيف (الـ `predeploy` يشغّل `eslint .`).
- منطقة `europe-west1` عبر `setGlobalOptions`.
