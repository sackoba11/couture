import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_router.dart';

class NavigationService {
  static GoRouter get router => appRouter;

  /// Contexte du navigateur go_router pour afficher dialogs/sheets hors-arbre
  /// (callbacks système) sur la bonne pile de navigation.
  static BuildContext? get dialogContext =>
      router.routerDelegate.navigatorKey.currentContext;

  static void go(String location, {Object? extra}) {
    router.go(location, extra: extra);
  }

  static void push(String location, {Object? extra}) {
    router.push(location, extra: extra);
  }

  static void pop() {
    router.pop();
  }
}
