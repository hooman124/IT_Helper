# ساخت نسخه انتشار

1. Flutter SDK را نصب کنید.
2. داخل پوشه پروژه اجرا کنید:

flutter pub get
flutter analyze
flutter test

3. برای خروجی انتشار:

flutter build appbundle --release

فایل نهایی در مسیر زیر قرار می‌گیرد:

build/app/outputs/bundle/release/app-release.aab

برای انتشار واقعی، برنامه باید با keystore متعلق به توسعه‌دهنده امضا شود. کلید امضا را امن و خارج از پروژه نگه دارید.
