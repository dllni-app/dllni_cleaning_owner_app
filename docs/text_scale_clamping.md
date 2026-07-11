# حدّ تكبير النص (Text Scale Clamping) في Flutter

دليل سريع لتطبيق حل مشكلة كسر التصميم عند تكبير خط النظام (Accessibility / Display Size) على أجهزة Android و iOS.

---

## المشكلة

عندما يفعّل المستخدم **تكبير الخط** أو **حجم العرض** من إعدادات الجهاز، Flutter يمرّر القيمة عبر `MediaQuery.textScaler`. إذا كان التطبيق مبني بـ:

- ارتفاعات ثابتة (`height: 48`)
- `Row` بدون `Flexible` / `Expanded`
- نصوص بدون `maxLines` أو `overflow`

…فالتصميم ينكسر: overflow أصفر/أسود، أزرار مقطوعة، AppBar مزدحم.

---

## الحل الموصى به

**Clamp** (تحديد نطاق) لتكبير النص على مستوى التطبيق:

| القيمة | المعنى |
|--------|--------|
| `minScaleFactor: 1.0` | لا تصغّر النص تحت الحجم الافتراضي |
| `maxScaleFactor: 1.2` | اسمح بتكبير معتدل (20%) — مناسب لمعظم التطبيقات |
| `maxScaleFactor: 1.3` | بديل إذا أردت وصولية أعلى مع مخاطرة layout أكبر |

> **تجنّب** فرض `textScaleFactor: 1.0` ثابت — يعطّل إعدادات إمكانية الوصول وقد يسبب ملاحظات على المتاجر.

---

## التطبيق على `MaterialApp`

### 1) أضف `builder` داخل `MaterialApp`

```dart
MaterialApp(
  // ... باقي الإعدادات (title, theme, routes, ...)
  builder: (context, child) {
    final mediaQuery = MediaQuery.of(context);
    final clampedScaler = mediaQuery.textScaler.clamp(
      minScaleFactor: 1.0,
      maxScaleFactor: 1.2,
    );

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: clampedScaler),
      child: child ?? const SizedBox.shrink(),
    );
  },
)
```

### 2) إذا كان التطبيق يستخدم `MaterialApp.router`

نفس الفكرة — `builder` متاح على `MaterialApp.router` أيضاً:

```dart
MaterialApp.router(
  routerConfig: _router,
  builder: (context, child) {
    final mediaQuery = MediaQuery.of(context);
    final clampedScaler = mediaQuery.textScaler.clamp(
      minScaleFactor: 1.0,
      maxScaleFactor: 1.2,
    );

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: clampedScaler),
      child: child ?? const SizedBox.shrink(),
    );
  },
)
```

### 3) إذا كان عندك `builder` موجود مسبقاً (مثل Toast / EasyLocalization)

**ادمج** الـ clamp داخل الـ builder الحالي — لا تضف `builder` ثاني:

```dart
builder: (context, child) {
  final mediaQuery = MediaQuery.of(context);
  final clampedScaler = mediaQuery.textScaler.clamp(
    minScaleFactor: 1.0,
    maxScaleFactor: 1.2,
  );

  return MediaQuery(
    data: mediaQuery.copyWith(textScaler: clampedScaler),
    child: ToastificationWrapper( // أو أي wrapper موجود
      child: child ?? const SizedBox.shrink(),
    ),
  );
},
```

---

## Widget قابل لإعادة الاستخدام (اختياري)

إذا أردت تطبيق الحد على جزء من الشجرة فقط (شاشة واحدة مثلاً):

```dart
class ClampedTextScale extends StatelessWidget {
  const ClampedTextScale({
    super.key,
    required this.child,
    this.minScaleFactor = 1.0,
    this.maxScaleFactor = 1.2,
  });

  final Widget child;
  final double minScaleFactor;
  final double maxScaleFactor;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final clampedScaler = mediaQuery.textScaler.clamp(
      minScaleFactor: minScaleFactor,
      maxScaleFactor: maxScaleFactor,
    );

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: clampedScaler),
      child: child,
    );
  }
}
```

الاستخدام:

```dart
ClampedTextScale(
  child: MyScreen(),
)
```

---

## ملاحظات إصدار Flutter

| Flutter | الـ API |
|---------|---------|
| **3.16+** | `MediaQuery.textScaler` + `textScaler.clamp()` |
| **قديم** | `MediaQuery.textScaleFactor` (deprecated) |

للإصدارات القديمة:

```dart
// legacy — لا تستخدم في مشاريع جديدة
final scale = mediaQuery.textScaleFactor.clamp(1.0, 1.2);
return MediaQuery(
  data: mediaQuery.copyWith(textScaleFactor: scale),
  child: child!,
);
```

---

## اختبار الحل

1. **Android:** الإعدادات → العرض → حجم الخط / حجم العرض → Large أو Largest
2. **iOS:** الإعدادات → إمكانية الوصول → العرض والنص → Larger Text
3. افتح الشاشات الحساسة: Login، AppBar، Cards، BottomNavigation، Dialogs
4. تأكد أنه **لا overflow** وأن النص **مقروء**

---

## تحسينات layout إضافية (مكمّلة للـ clamp)

الـ clamp يحمي التطبيق عموماً، لكن بعض الشاشات قد تحتاج تعديل:

```dart
// نص طويل داخل Row
Flexible(
  child: Text(
    title,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
  ),
)

// زر بارتفاع يتكيّف
SizedBox(
  width: double.infinity,
  child: FilledButton(
    onPressed: onPressed,
    child: Text(label),
  ),
)

// تجنّب height ثابت للكروت التي تحتوي نصاً متغيراً
// سيّء:  height: 80
// أفضل: padding + constraints أو IntrinsicHeight عند الحاجة
```

---

## اختيار `maxScaleFactor` المناسب

| القيمة | متى تستخدمها |
|--------|----------------|
| `1.1` | تصميم ضيق جداً (جداول، dashboards) |
| `1.2` | **افتراضي موصى به** — توازن بين UX و layout |
| `1.3` | تطبيقات كثيرة النصوص وفئة مستخدمين كبار |
| بدون clamp | فقط إذا كل الشاشات responsive بالكامل |

---

## Checklist سريع للمشروع الجديد

- [ ] إضافة `builder` على `MaterialApp` / `MaterialApp.router`
- [ ] ضبط `maxScaleFactor` (ابدأ بـ `1.2`)
- [ ] اختبار على جهاز حقيقي بتكبير خط كبير
- [ ] مراجعة الشاشات التي فيها overflow
- [ ] (اختياري) استخراج `ClampedTextScale` widget مشترك

---

## مرجع التطبيق في هذا المشروع

الملف: `lib/app.dart` — داخل `MaterialApp.builder`.

```dart
builder: (context, child) {
  final mediaQuery = MediaQuery.of(context);
  final clampedScaler = mediaQuery.textScaler.clamp(
    minScaleFactor: 1.0,
    maxScaleFactor: 1.2,
  );
  return MediaQuery(
    data: mediaQuery.copyWith(textScaler: clampedScaler),
    child: child ?? const SizedBox.shrink(),
  );
},
```

---

*آخر تحديث: يوليو 2026*
