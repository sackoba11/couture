import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_router.dart';
import '../widgets/widget_class.dart';

class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  void goTo(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  DateTime? _lastBackPress;

  bool _handlePop(StatefulNavigationShell shell) {
    final navigator = NavKeys.byIndex(shell.currentIndex).currentState;
    // final size = MediaQuery.sizeOf(context);

    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return false;
    }

    /// 2️⃣ Revenir à Home
    if (shell.currentIndex != 0) {
      shell.goBranch(0, initialLocation: true);
      return false;
    }

    /// 3️⃣ Double back pour quitter
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      // Fluttertoast.showToast(
      //         msg: "Appuyez encore pour quitter",
      //         gravity: ToastGravity.TOP,
      //       );
      // ScaffoldMessenger.of(context).showSnackBar(CustomSnackBar(size: size));
      return false;
    }

    /// 4️⃣ Quitter l’app
    SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) =>
          _handlePop(widget.navigationShell),
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: goTo,
          destinations: bottomNavItems
              .map((item) => buildDestination(item))
              .toList(),
        ),
      ),
    );
  }
}
