---
description: نشر قواعد/فهارس/تخزين طوبة (والدوال عند الطلب) على touba-3ds
---

انشر تغييرات Firebase لمشروع طوبة (`touba-3ds`) بأمان:

1. تأكّد أن المشروع الصحيح مُحدَّد: `firebase use touba-3ds`.
2. إن كان التغيير في `firestore.rules` / `firestore.indexes.json` / `storage.rules`:
   ```
   firebase deploy --only firestore:rules,firestore:indexes,storage
   ```
3. إن كان التغيير في `functions/index.js` (تتطلّب Blaze، واسأل المستخدم قبل النشر):
   ```
   cd functions && npm install && cd ..
   firebase deploy --only functions
   ```
   - إن فشل أول نشر للجيل الثاني برسالة Eventarc/Cloud Build → انتظر 3-5 دقائق وأعد المحاولة (سلوك معتاد).
4. بعد النشر، تحقّق من Firebase Console وحدّث «سجل حالة النشر» في `docs/دليل_النشر.md`.

الوسيطة الاختيارية `$ARGUMENTS` تحدّد ما يُنشر (rules / functions / all).
