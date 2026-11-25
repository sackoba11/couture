import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/navigation_service.dart';
import '../../../../data/models/client/client.dart';
import '../../../../data/repositories/couture_repository/couture_repository.dart';
import '../../../../routes/app_routes.dart';
import '../../../widgets/client_picker.dart';

class HomeController extends GetxController {
  final CoutureRepository repository = CoutureRepository.instance;

  final searchController = TextEditingController();
  final clients = RxList<ClientOverview>([]);
  final deliveries = RxList<DeliveryOverview>([]);
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  Timer? debounce;
  String query = '';

  @override
  void onInit() {
    super.onInit();
    initData();
  }

  @override
  void dispose() {
    debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void initData() async {
    isLoading.value = true;
    clients.value = await repository.clients();
    deliveries.value = await repository.upcomingDeliveries();
    isLoading.value = false;
  }

  Future<void> refreshData({String? queryText}) async {
    isRefreshing.value = true;
    if (queryText != null) query = queryText;
    clients.value = await repository.clients(query: query);
    deliveries.value = await repository.upcomingDeliveries();
    isRefreshing.value = false;
  }

  void onSearchChanged(String value) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 250), () {
      refreshData(queryText: value);
    });
  }

  Future<void> createSheet({required BuildContext context}) async {
    final client = await showClientPicker(context);
    if (client == null) return;
    NavigationService.push(AppRoutes.sheetForm);
    // final sheetId = await Navigator.of(context).push<String>(
    //   PageRouteBuilder<String>(
    //     pageBuilder: (context, animation, secondaryAnimation) =>
    //         SheetFormScreen(),
    //     transitionsBuilder: (context, animation, secondaryAnimation, child) {
    //       return FadeTransition(opacity: animation, child: child);
    //     },
    //     transitionDuration: const Duration(milliseconds: 250),
    //   ),
    // );
    // if (!mounted) return;
    // if (sheetId != null) {
    //   await Navigator.of(context).push(
    //     PageRouteBuilder(
    //       pageBuilder: (context, animation, secondaryAnimation) =>
    //           SheetSummaryScreen(),
    //       transitionsBuilder: (context, animation, secondaryAnimation, child) {
    //         return FadeTransition(opacity: animation, child: child);
    //       },
    //       transitionDuration: const Duration(milliseconds: 250),
    //     ),
    //   );
    // }
    // if (mounted) _reload();
  }
}
