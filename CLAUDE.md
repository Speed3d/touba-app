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

## 🔴 أول ما تفعله في كل جلسة
اقرأ **[`docs/الحالة_الحالية.md`](docs/الحالة_الحالية.md)** — الذاكرة المشتركة بين ويندوز والماك.
فيها: أين وصلنا · ما هو منشور · الخطوة التالية المتّفق عليها · المعلّقات.
> الذاكرة المحليّة (`~/.claude/.../memory/`) **لا تنتقل بين الأجهزة** — لا تعتمد عليها وحدها.
> **قبل كل commit:** شغّل `/handoff` ليُحدَّث الملف بحقائق مفحوصة.

## القواعد الذهبية
1. **ترشيد الاستهلاك أولاً** — تفاصيل في `.claude/rules/01-cost-rationing.md`. باختصار: cache-first للصور، تجميع مسبق للإحصائيات، `limit()`/pagination على كل استعلام، `snapshots()` فقط للمباراة الجارية.
2. **الأمان من الخادم لا الواجهة** — تفاصيل في `.claude/rules/02-security-invariants.md`. باختصار: `stats / careerStats / standings / ratingPoints / resultConfirmed / statsApplied` **لا تُكتب من العميل إطلاقاً** — من Cloud Functions حصراً.
3. **مصدر حقيقة واحد للحالة:** المستندات الحيّة في `docs/`:
   - [`docs/الحالة_الحالية.md`](docs/الحالة_الحالية.md) — **الحالة الآن** (يُحدَّث بـ `/handoff` قبل كل رفع).
   - [`docs/تحليل_المشروع_الشامل.md`](docs/تحليل_المشروع_الشامل.md) — حالة الكود الفعلية + الأخطاء + خطة الإصلاح.
   - [`docs/تصميم_الأساس.md`](docs/تصميم_الأساس.md) — المخطط الهندسي المعتمد (سكيمة، أدوار، قواعد، فهارس، دوال، خوارزميات).
   - راجعها/حدّثها في كل جلسة، وزِد سطراً في سجل الإصدارات عند أي تغيير جوهري.
4. **الواجهة متعدّدة اللغات** — 3 لغات (`ar` قالب · `en` · `ku` سوراني) في `lib/l10n/*.arb`.
   أي نصّ جديد يظهر للمستخدم **يجب** أن يُضاف كمفتاح في **الملفات الثلاثة** ويُستدعى عبر
   `AppLocalizations.of(context)!.key` — لا نصوص مكتوبة يدوياً في الواجهة.

## ⛔ ممنوعات
- **لا تحذف مجلد `craftsman_backup/`** — مرجع مقصود من المالك للأفكار، يُحذف فقط بعد اكتمال طوبة. مستثنى أصلاً من المحلّل.
- لا تُدخِل نصوصاً عربية فصحى رسمية في الواجهة — استخدم اللهجة العراقية.
- لا تُنشئ تمثيلاً ثانياً للاعب على `users` (أُزيلت الازدواجية — اللاعب في `players` فقط).

## 💻🍎 سير العمل عبر جهازين (ويندوز ↔ ماك)
المشروع يُطوَّر من جهازين. `craftsman_backup` **submodule** — لا يصل بـ `git pull` وحده.

**قبل الرفع:**
```bash
# 1) شغّل /handoff لتحديث docs/الحالة_الحالية.md بحقائق مفحوصة
git add -A && git commit -m "..." && git push
```

**بعد السحب على الجهاز الآخر:**
```bash
git pull
git submodule update --init --recursive   # يجلب craftsman_backup
flutter pub get
```

> ملفات Firebase (`google-services.json` · `GoogleService-Info.plist` · `firebase.json` · `.firebaserc`)
> **مُستثناة من git بقرار المالك** — تُنقل يدوياً. تفاصيل: [`docs/دليل_الإعداد_على_الماك.md`](docs/دليل_الإعداد_على_الماك.md).

## الأوامر السريعة
```bash
flutter analyze lib                 # يجب أن يبقى نظيفاً (تجاهل ملاحظات craftsman_backup)
flutter pub get
flutter gen-l10n                    # توليد الترجمات بعد تعديل ملفات .arb
firebase deploy --only firestore:rules,firestore:indexes,storage
firebase deploy --only functions    # يتطلّب Blaze + منطقة europe-west1
```
دليل النشر الكامل: [`docs/دليل_النشر.md`](docs/دليل_النشر.md). أمر مختصر: `/deploy`.
تحديث الذاكرة المشتركة قبل الرفع: `/handoff`.

## اصطلاحات الكود
انظر `.claude/rules/03-conventions.md`. باختصار: تعليقات `📝 HINT AR:` للشرح بالعربية، أسماء ملفات `snake_case`، Cubit لكل وحدة، Repository يلفّ Firestore، Models بـ `fromJson/toJson` + `Equatable`.
