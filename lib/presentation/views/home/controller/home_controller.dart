import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/models/client/client.dart';
import '../../../../data/repositories/couture_repository/couture_repository.dart';

class HomeController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  final CoutureRepository repository = CoutureRepository.instance;

  late Future<List<ClientOverview>> clients;
  late Future<List<DeliveryOverview>> deliveries;
  Timer? debounce;
  String query = '';

  @override
  void onInit() {
    super.onInit();
    clients = repository.clients();
    deliveries = repository.upcomingDeliveries();
  }

  @override
  void dispose() {
    debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void reload({String? queryText}) {
    if (queryText != null) query = queryText;
    clients = repository.clients(query: query);
    deliveries = repository.upcomingDeliveries();
  }

  void onSearchChanged(String value) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 250), () {
      reload(queryText: value);
    });
  }
}
