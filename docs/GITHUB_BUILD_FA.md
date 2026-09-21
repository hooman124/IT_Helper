# راهنمای Build در GitHub

## روش پیشنهادی

فایل‌های پروژه را در Repository قرار دهید. فایل زیر از قبل آماده است:

`.github/workflows/build-apk.yml`

پس از Push به `main`، GitHub Actions به صورت خودکار:

- Java 17 را آماده می‌کند
- Flutter stable را نصب می‌کند
- پروژه Android را تولید می‌کند
- در صورت وجود Secret های امضا، Release را با keystore واقعی امضا می‌کند
- وابستگی‌ها را نصب می‌کند
- `flutter analyze` را اجرا می‌کند
- APK و AAB نسخه Release می‌سازد
- هر دو را به عنوان Artifact ذخیره می‌کند

خروجی:

- `build/app/outputs/flutter-apk/app-release.apk` (برای تست/نصب مستقیم)
- `build/app/outputs/bundle/release/app-release.aab` (برای بارگذاری در کافه‌بازار)

## امضای Release با keystore واقعی (اختیاری ولی برای انتشار نهایی لازم است)

به‌طور پیش‌فرض، اگر Secret تنظیم نکنید، ساخت با کلید Debug فلاتر امضا می‌شود؛ این برای تست نصب روی گوشی مشکلی ندارد ولی برای انتشار رسمی در کافه‌بازار مناسب نیست، چون:
- امضای Debug دائمی و اختصاصی شما نیست
- برای هر آپدیت بعدی باید همان امضا حفظ شود؛ در غیر این صورت کافه‌بازار آپدیت را رد می‌کند

برای امضای واقعی:

1. یک‌بار روی سیستم خودتان keystore بسازید:
   ```
   keytool -genkey -v -keystore release-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias ithelper
   ```
2. فایل `release-keystore.jks` را به Base64 تبدیل کنید و در Secret به نام `KEYSTORE_BASE64` مخزن GitHub قرار دهید (Settings → Secrets and variables → Actions):
   ```
   base64 -w 0 release-keystore.jks
   ```
3. سه Secret دیگر هم اضافه کنید: `KEYSTORE_PASSWORD`، `KEY_ALIAS` (مثلاً `ithelper`)، `KEY_PASSWORD`.
4. فایل `release-keystore.jks` را جایی امن نگه دارید (خارج از Git) — اگر گم شود، دیگر نمی‌توانید همان برنامه را آپدیت کنید.
5. از این پس هر Build، APK/AAB را با همین کلید امضا می‌کند.
