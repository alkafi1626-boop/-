# আমার পরিকল্পনা V3

লগইন ছাড়াই সরাসরি চালু হওয়া বাংলা পরিকল্পনা অ্যাপ।

## V3 ফিচার
- বাংলা UI
- English + বাংলা + Hijri তারিখ
- দৈনিক কাজ
- কাজ সম্পাদনা/মুছে ফেলা/সম্পন্ন
- সময় ও অগ্রাধিকার
- পুনরাবৃত্তি: একবার, প্রতিদিন, প্রতি সপ্তাহে, প্রতি মাসে
- রিমাইন্ডার সেটিং সংরক্ষণ
- মাসিক লক্ষ্য
- ক্যালেন্ডার
- অগ্রগতি
- ডার্ক মোড
- SharedPreferences-এ স্থানীয় ডেটা

## Android/Web
`flutter pub get`
`flutter run`
`flutter run -d chrome`
Android APK: `flutter build apk --release`
Web: `flutter build web`

## গুরুত্বপূর্ণ
এই পরিবেশে Flutter SDK/Android toolchain নেই, তাই এখানে APK compile করা হয়নি।
রিমাইন্ডার UI/ডেটা মডেল প্রস্তুত; প্রকৃত Android notification চালাতে পরের build-এ `flutter_local_notifications` এবং Android permission/configuration যোগ করতে হবে।
