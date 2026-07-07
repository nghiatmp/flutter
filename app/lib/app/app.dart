import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/providers/settings_provider.dart';
import 'chucker_bug_button.dart';
import 'router.dart';
import 'theme.dart';

class StudyFlutterApp extends ConsumerWidget {
  const StudyFlutterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// Đọc router từ Riverpod để router có thể tự phản ứng theo auth state.
    /// Khi trạng thái đăng nhập đổi, router sẽ kiểm tra redirect lại.
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(settingsProvider);

    /// MaterialApp.router dùng cho app có route phức tạp hơn home screen đơn giản.
    /// Ở đây go_router quản lý các màn: splash, đăng ký, đăng nhập, quản lý.
    return MaterialApp.router(
      title: 'Study Flutter',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      darkTheme: buildAppTheme(brightness: Brightness.dark),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      routerConfig: router,

      /// Nút nổi hình con bọ (Chucker) để xem lịch sử request/response
      /// ngay trong app khi debug.
      builder: kDebugMode
          ? (context, child) => Stack(
              children: [
                Positioned.fill(child: child ?? const SizedBox.shrink()),
                const ChuckerBugButton(),
              ],
            )
          : null,
    );
  }
}
