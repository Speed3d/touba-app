# 🟢 طوبة (Touba) — دليل المشروع لـ Claude

> هذا الملف يُحمَّل تلقائياً كل جلسة. القواعد هنا **مُلزِمة**. التفاصيل الموسّعة في `.claude/rules/`.

## ما هو المشروع
«طوبة» = تطبيق **Flutter + Firebase** لكرة القدم الشعبية/الهواة في العراق. مبني فوق هيكل تطبيق سابق منشور («حرفي العراق» / craftsman_iraq) عبر إعادة استخدام المستودع — لذا قد تبقى بقايا من القديم، وهي مصدر معظم المخاطر.

- المالك: **سنان** — اللهجة في كل نصوص الواجهة: **عراقية**.
- إدارة الحالة: **Bloc/Cubit** (لا Provider/Riverpod/setState للمنطق).
- المعمارية: طبقات (Clean-ish): `data/models` ← `data/repositories` ← `data/services` ← `presentation/cubits` ← `presentation/screens`.

## الثوابت التقنية (لا تُغيَّر دون إذن صريح)
| البند | القيمة النهائية |
|---|---|
| معرّف الحزمة | `com.speed3d.touba` |
| مشروع Firebase | `touba-3ds` (رقم `868610876965`) |
| منطقة الدوال | `europe-west1` |
| firebase-functions | v2 (الجيل الثاني) — **ممنوع** صياغة v1 |
| المباريات | مجموعة **top-level** `matches` (ليست subcollection) |
| نموذج اللاعب | **هجين**: سجل `players` يديره الكابتن + ربط بحساب `users` عبر `claimedByUid` |

## القواعد الذهبية
1. **ترشيد الاستهلاك أولاً** — تفاصيل في `.claude/rules/01-cost-rationing.md`. باختصار: cache-first للصور، تجميع مسبق للإحصائيات، `limit()`/pagination على كل استعلام، `snapshots()` فقط للمباراة الجارية.
2. **الأمان من الخادم لا الواجهة** — تفاصيل في `.claude/rules/02-security-invariants.md`. باختصار: `stats / careerStats / standings / ratingPoints / resultConfirmed / statsApplied` **لا تُكتب من العميل إطلاقاً** — من Cloud Functions حصراً.
3. **مصدر حقيقة واحد للحالة:** المستندان الحيّان في `docs/`:
   - [`docs/تحليل_المشروع_الشامل.md`](docs/تحليل_المشروع_الشامل.md) — حالة الكود الفعلية + الأخطاء + خطة الإصلاح.
   - [`docs/تصميم_الأساس.md`](docs/تصميم_الأساس.md) — المخطط الهندسي المعتمد (سكيمة، أدوار، قواعد، فهارس، دوال، خوارزميات).
   - راجعهما/حدّثهما في كل جلسة، وزِد سطراً في سجل الإصدارات عند أي تغيير جوهري.

## ⛔ ممنوعات
- **لا تحذف مجلد `craftsman_backup/`** — مرجع مقصود من المالك للأفكار، يُحذف فقط بعد اكتمال طوبة. مستثنى أصلاً من المحلّل.
- لا تُدخِل نصوصاً عربية فصحى رسمية في الواجهة — استخدم اللهجة العراقية.
- لا تُنشئ تمثيلاً ثانياً للاعب على `users` (أُزيلت الازدواجية — اللاعب في `players` فقط).

## الأوامر السريعة
```bash
flutter analyze lib                 # يجب أن يبقى نظيفاً (تجاهل ملاحظات craftsman_backup)
flutter pub get
firebase deploy --only firestore:rules,firestore:indexes,storage
firebase deploy --only functions    # يتطلّب Blaze + منطقة europe-west1
```
دليل النشر الكامل: [`docs/دليل_النشر.md`](docs/دليل_النشر.md). أمر مختصر: `/deploy`.

## اصطلاحات الكود
انظر `.claude/rules/03-conventions.md`. باختصار: تعليقات `📝 HINT AR:` للشرح بالعربية، أسماء ملفات `snake_case`، Cubit لكل وحدة، Repository يلفّ Firestore، Models بـ `fromJson/toJson` + `Equatable`.
