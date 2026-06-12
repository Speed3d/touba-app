package com.craftsmaniraq.craftsman_iraq

import io.flutter.embedding.android.FlutterFragmentActivity

// يجب استخدام FlutterFragmentActivity وليس FlutterActivity
// مكتبة local_auth (للبصمة) تحتاج FragmentActivity لعرض حوار المصادقة
// استخدام FlutterActivity يجعل زر البصمة يظهر لكن لا يستجيب للضغط
class MainActivity : FlutterFragmentActivity()
