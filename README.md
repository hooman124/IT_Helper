# IT Helper — GitHub Build Edition

اپ فارسی IT Helper برای عیب‌یابی مرحله‌به‌مرحله کامپیوتر و شبکه.

## ساخت APK با GitHub

1. همه فایل‌های این پوشه را داخل یک GitHub Repository قرار دهید.
2. یک بار روی **Actions** و سپس **Build Android APK** بروید.
3. روی **Run workflow** بزنید؛ یا یک Commit/Push به شاخه `main` انجام دهید.
4. پس از پایان Build، از بخش **Artifacts** فایل `it-helper-release-apk` را دانلود کنید.

### نکته
پروژه عمداً پوشه `android/` را داخل سورس نگه نمی‌دارد. Workflow در GitHub Runner با دستور `flutter create --platforms=android` پروژه Android را می‌سازد و سپس APK Release را تولید می‌کند.

این Build برای تست/انتشار اولیه مناسب است. برای انتشار رسمی در مارکت‌ها، امضای Release با keystore اختصاصی خودتان باید جداگانه تنظیم شود.
