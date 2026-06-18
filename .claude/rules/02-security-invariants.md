# قاعدة: ثوابت الأمان (Server-Enforced)

> المبدأ: **لا نثق بالواجهة أبداً.** كل قاعدة تُفرض في Security Rules أو Cloud Functions. الواجهة للراحة فقط.

## جدار المصداقية — حقول لا تُكتب من العميل إطلاقاً
هذه الحقول يكتبها **النظام (Cloud Functions / Admin SDK) حصراً**، وقواعد Firestore تمنع العميل من لمسها:
- `teams`: `stats`, `ratingPoints`, `badges`, `captainId`
- `players`: `careerStats`, `claimedByUid`
- `tournaments`: `standings`, `organizerUid`
- `matches`: `statsApplied`, `appliedSnapshot`
- `users`: `role`, `adminPermissions`, `linkedPlayerId`

> عند تعديل أي Model، تأكّد أن `toJson()` **لا يرسل** هذه الحقول من العميل في مسارات التحديث، وإلا سترفضها القاعدة.

## ملكية الكتابة (مختصر)
- **الفريق:** الكابتن يكتب البيانات التعريفية فقط.
- **اللاعب:** الكابتن يكتب الحقول الكروية؛ اللاعب صاحب السجل (بعد المطالبة) يكتب حقوله الشخصية فقط؛ الإحصائيات من CF.
- **البطولة/المباراة:** المنظّم (أو الأدمن) فقط. تأكيد النتيجة = تغيير `resultConfirmed` (يُشغّل المحرّك الذرّي).
- **الصلاحيات الحسّاسة** (`organizer`/`referee`/`admin`) تُمنح عبر Cloud Function `grantCapability` (Custom Claims) — لا تُضبط يدوياً.

## فصل المهام (الحكّام — م3)
الحكم لا يؤكّد النتيجة إطلاقاً (التأكيد للمنظّم)، ولا يُعيَّن لمباراة فريقه.

## المعالجة الذرّية للنتيجة
أي تحديث للإحصائيات داخل **معاملة واحدة** + **Idempotency** (`statsApplied`) + **تراجع-ثم-تطبيق** (`appliedSnapshot`) عند تعديل نتيجة مؤكّدة. لا تكسر هذا في `functions/index.js`.

## مرجع
القواعد الكاملة: `firestore.rules`, `storage.rules`, و`docs/تصميم_الأساس.md` القسم 6.
