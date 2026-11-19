# Soundify

اپلیکیشن استریم آنلاین موسیقی با Flutter برای پلتفرم Android، متصل به API اختصاصی درس.

- آدرس پایه API: `https://soundify.easyfound.ir/api/v1`
- مستندات API: `https://soundify.easyfound.ir/docs`
- مخزن پروژه: `https://github.com/M-H-Boroumandnia/soundify`

## پیش‌نیازها

| ابزار | نسخه |
| --- | --- |
| Flutter SDK | 3.50 (کانال stable، Dart 3.14 یا بالاتر) |
| JDK | 17 یا بالاتر (تست‌شده با 21) |
| Android SDK | API 36، Build Tools و Platform Tools |
| دستگاه / شبیه‌ساز | Android 7.0 (API 24) یا بالاتر |

برای تست ورود بیومتریک باید روی دستگاه اثر انگشت یا قفل چهره ثبت شده باشد.

## راهنمای اجرا

```bash
flutter pub get
flutter run
```

ساخت نسخه ریلیز (خروجی بهینه برای گوشی‌های arm64-v8a):

```bash
flutter build apk --release --target-platform android-arm64
```

فایل خروجی: `build/app/outputs/flutter-apk/app-release.apk`

برای اجرا روی شبیه‌ساز x86_64 نسخه بدون محدودیت معماری ساخته شود:

```bash
flutter build apk --release
```

## ساختار پروژه

```
lib/
  main.dart                  راه‌اندازی سرویس‌ها و تزریق وابستگی‌ها
  app.dart                   MaterialApp، تم تاریک، RTL و مدیریت خروج از نشست
  core/
    config.dart              تنظیمات ثابت (Base URL، تایم‌اوت، Debounce)
    network/                 ApiClient (Dio)، AuthInterceptor و مدیریت خطا
    storage/                 TokenStorage (حافظه امن) و AppPrefs
    security/                سرویس بیومتریک و بررسی امنیت دستگاه
    utils/                   اعتبارسنجی فرم، Debouncer و فرمت زمان
  data/
    models/                  Track، Playlist، AppUser، AuthTokens، Paginated
    repositories/            AuthRepository و MusicRepository
  state/                     Providerها: Auth، Favorites، Playlists، Player، PagedTracks
  ui/
    screens/                 Splash، Onboarding، Auth، Home، Search، Library، Player، Profile
    widgets/                 MiniPlayer، TrackTile، حالت‌های Loading/Empty/Error و ...
```

## پیاده‌سازی نیازمندی‌ها

### احراز هویت و امنیت
- ثبت‌نام و ورود با اعتبارسنجی ایمیل، نام کاربری و رمز عبور (حداقل ۸ کاراکتر شامل حرف و عدد).
- ورود با کد یک‌بار مصرف (OTP) با شمارش معکوس ارسال مجدد بر اساس مقدار `resend_after` سرور. سرور در پاسخ `/auth/otp/verify/` فقط حساب را تأیید می‌کند و توکن برنمی‌گرداند؛ بنابراین پس از ثبت‌نام یا ورود با حساب تأییدنشده، برنامه بلافاصله پس از تأیید کد با همان ایمیل و رمز عبور وارد می‌شود. در صورت نبود رمز، کاربر با ایمیل پرشده به صفحه ورود بازمی‌گردد.
- فراموشی رمز عبور در دو مرحله: دریافت کد و ثبت رمز جدید.
- ذخیره Access Token و Refresh Token فقط در `flutter_secure_storage` (Android Keystore). در SharedPreferences فقط وضعیت مشاهده Onboarding و فعال بودن بیومتریک ذخیره می‌شود.
- `AuthInterceptor` از نوع `QueuedInterceptor`: با خطای 401 توکن را با `/auth/token/refresh/` تمدید و درخواست را دوباره ارسال می‌کند. درخواست‌های هم‌زمان در صف می‌مانند تا فقط یک بار تمدید انجام شود. فقط در صورت نامعتبر بودن Refresh Token کاربر به صفحه ورود هدایت می‌شود.
- ورود بیومتریک با `local_auth`: پس از فعال‌سازی در پروفایل، در اجرای بعدی یا پس از خروج، ورود با اثر انگشت یا چهره انجام می‌شود. گزینه «خروج و حذف اطلاعات» توکن‌ها را کامل پاک می‌کند.
- بررسی Root، شبیه‌ساز و حالت توسعه‌دهنده با `safe_device`؛ نمایش در صفحه پروفایل و هشدار هنگام ورود.
- غیرفعال بودن `allowBackup` و ترافیک غیر HTTPS.

### ارتباط با وب‌سرویس
- کلاس `ApiClient` مبتنی بر Dio با Base URL، تایم‌اوت اتصال و دریافت، و تبدیل خطاها به `ApiException` با پیام فارسی.
- دریافت آهنگ‌های منتخب و لیست کل آهنگ‌ها با صفحه‌بندی (Infinite Scroll) شامل عنوان، خواننده، آلبوم، کاور و مدت زمان.
- جست‌وجوی زنده با Debounce (۴۵۰ میلی‌ثانیه) و لغو درخواست قبلی با `CancelToken`.
- CRUD پلی‌لیست: مشاهده، ایجاد، ویرایش نام و توضیحات (`PATCH /playlists/:id/`)، حذف، افزودن و حذف آهنگ.
- لایک و آنلایک با به‌روزرسانی خوش‌بینانه (Optimistic Update) و بازگشت در صورت خطا.
- نمایش حالت‌های Loading، Empty و Error با دکمه تلاش مجدد در همه صفحات.

### پخش موسیقی
- استریم مستقیم از `stream_url` سرور با پشتیبانی HTTP 206 Partial Content (Seek بدون دانلود کامل فایل).
- دکمه‌های Play/Pause/Next/Previous، اسلایدر Seek با نمایش زمان گذشته، زمان کل و مقدار بافر شده، تکرار و پخش تصادفی.
- انتقال خودکار به آهنگ بعدی پس از پایان آهنگ (صف پخش).
- مینی‌پلیر در پایین همه صفحات تب‌ها (Navigator تودرتو برای هر تب).
- پخش در پس‌زمینه و صفحه خاموش با `just_audio_background`.
- نوتیفیکیشن و صفحه قفل با کاور، نام خواننده و عنوان، و کنترل پخش و جابجایی آهنگ.
- پلیر تمام‌صفحه با کاور، ویژوالایزر متحرک و اکولایزر واقعی Android (`AndroidEqualizer`) با پیش‌تنظیم‌های تخت، تقویت بیس، وکال، تقویت زیر و راک.

### رابط کاربری
- Splash Screen با لوگو، Onboarding سه‌مرحله‌ای که فقط در اولین اجرا نمایش داده می‌شود.
- صفحات خانه (منتخب‌ها و دسته‌بندی خوانندگان)، جست‌وجو، کتابخانه (تب پلی‌لیست‌ها و علاقه‌مندی‌ها)، پلیر و پروفایل با تنظیمات امنیتی.
- چیدمان کامل راست‌چین (RTL) با فونت وزیرمتن (همراه برنامه در `assets/fonts`، بدون نیاز به دانلود) و حالت تاریک.

### مدیریت وضعیت
- `provider` با `ChangeNotifier` برای هر بخش و تفکیک لایه‌های data، state و ui.

## کتابخانه‌های استفاده‌شده

| کتابخانه | کاربرد |
| --- | --- |
| dio | کلاینت HTTP، اینترسپتورها و تایم‌اوت |
| flutter_secure_storage | ذخیره امن توکن‌ها |
| local_auth | ورود با اثر انگشت و تشخیص چهره |
| safe_device | تشخیص Root و شبیه‌ساز |
| shared_preferences | ذخیره وضعیت Onboarding و تنظیم بیومتریک |
| just_audio | پخش استریم و اکولایزر |
| just_audio_background | پخش پس‌زمینه و کنترل نوتیفیکیشن |
| audio_session | مدیریت فوکوس صوتی |
| provider | مدیریت وضعیت |
| cached_network_image | کش تصاویر کاور |
| smooth_page_indicator | نشانگر اسلایدر Onboarding |
| material_ui، flutter_localizations | ویجت‌های Material و بومی‌سازی فارسی |
