import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/views/app_shell/screen/main_shell.dart';
import '../presentation/views/client/screens/client_detail_screen.dart';
import '../presentation/views/client/screens/client_form_screen.dart';
import '../presentation/views/home/screen/home_screen.dart';
import '../presentation/views/pattern/screens/patterns_screen.dart';
import '../presentation/views/sheet/screens/sheet_form_screen.dart';
import '../presentation/views/sheet/screens/sheet_summary_screen.dart';
import 'app_routes.dart';

final Tween<Offset> _slideTween = Tween(
  begin: const Offset(1.0, 0.0),
  end: Offset.zero,
);
final Tween<double> _fadeTween = Tween(begin: 0.0, end: 1.0);
const Curve _pageCurve = Curves.easeInOut;
const Duration _defaultTransitionDuration = Duration(milliseconds: 250);

CustomTransitionPage buildSlideFadePage({
  required GoRouterState state,
  required Widget child,
  Duration? duration,
}) {
  final dur = duration ?? _defaultTransitionDuration;
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: dur,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: _pageCurve);
      final offsetAnim = _slideTween.animate(curved);
      final fadeAnim = _fadeTween.animate(curved);
      return SlideTransition(
        position: offsetAnim,
        child: FadeTransition(opacity: fadeAnim, child: child),
      );
    },
  );
}

CustomTransitionPage<void> _buildFadePage({
  required GoRouterState state,
  required Widget child,
  Duration duration = const Duration(milliseconds: 250),
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      );
    },
  );
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

class NavKeys {
  static final home = GlobalKey<NavigatorState>();
  static final pattern = GlobalKey<NavigatorState>();

  static GlobalKey<NavigatorState> byIndex(int index) {
    return [home, pattern][index];
  }
}

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.clientForm,
      pageBuilder: (context, state) =>
          _buildFadePage(state: state, child: ClientFormScreen()),
    ),
    GoRoute(
      path: AppRoutes.clientDetails,
      pageBuilder: (context, state) =>
          _buildFadePage(state: state, child: ClientDetailScreen()),
    ),
    GoRoute(
      path: AppRoutes.sheetSummary,
      pageBuilder: (context, state) =>
          _buildFadePage(state: state, child: SheetSummaryScreen()),
    ),
    GoRoute(
      path: AppRoutes.sheetForm,
      pageBuilder: (context, state) =>
          _buildFadePage(state: state, child: SheetFormScreen()),
    ),

    // Navigation bar
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: [
        /// ===== ACCUEIL STACK =====
        StatefulShellBranch(
          navigatorKey: NavKeys.home,
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (_, _) => const HomeScreen(),
            ),
          ],
        ),

        /// ===== Soins =====
        StatefulShellBranch(
          navigatorKey: NavKeys.pattern,
          routes: [
            GoRoute(
              path: AppRoutes.pattern,
              builder: (_, _) => const PatternsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
