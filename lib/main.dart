import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'app/core/data/sharedPre.dart';
import 'app/core/theme/light_theme.dart';
import 'app/core/theme/dark_theme.dart';
import 'app/routes/app_pages.dart';
import 'app/services/auth_service.dart';
import 'generated/locales.g.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedpreferenceUtil.init();
  HttpOverrides.global = MyHttpOverrides();
  await Get.putAsync(() => AuthService().init());

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  runApp(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: "Trend Mart",
          initialRoute: AppPages.INITIAL,
          debugShowCheckedModeBanner: false,
          getPages: AppPages.routes,
          theme: LightTheme.themeData,
          darkTheme: DarkTheme.themeData,
          themeMode: ThemeMode.light,
          translationsKeys: AppTranslation.translations,
          locale: const Locale('en', 'US'),
          fallbackLocale: const Locale('en', 'US'),
          builder: (context, widget) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
              child: widget!,
            );
          },
        );
      },
    ),
  );
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
