import 'package:flutter/material.dart';

class BottomNavItem {
  const BottomNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final Widget icon;
  final Widget selectedIcon;
}

const List<BottomNavItem> bottomNavItems = [
  BottomNavItem(
    label: 'Clients',
    icon: Icon(Icons.people_outline, fontWeight: FontWeight.bold),
    selectedIcon: Icon(fontWeight: FontWeight.bold, Icons.people_rounded),
  ),
  BottomNavItem(
    label: 'Patrons',
    icon: Icon(Icons.content_cut_outlined, fontWeight: FontWeight.bold),
    selectedIcon: Icon(fontWeight: FontWeight.bold, Icons.content_cut_outlined),
  ),
];

NavigationDestination buildDestination(BottomNavItem item) {
  return NavigationDestination(
    label: item.label,
    icon: item.icon,
    selectedIcon: item.selectedIcon,
  );
}
