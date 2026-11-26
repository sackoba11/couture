import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/navigation_service.dart';
import '../../../../core/utils/utils.dart';
import '../../../../data/models/client/client.dart';
import '../../../../data/models/measurement_sheet/measurement_sheet.dart';
import '../../../../data/repositories/couture_repository/couture_repository.dart';
import '../../../../routes/app_routes.dart';

class ClientController extends GetxController {
  final currentClient = Rxn<Client>();
  final newClient = Rxn<Client>();
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController notesController;
  final clients = RxList<ClientOverview>([]);
  final sheets = RxList<MeasurementSheet>([]);
  final currentSheet = Rxn<MeasurementSheet>();
  final saving = false.obs;
  final isLoading = false.obs;
  final isRefreshing = false.obs;

  final isEditing = false.obs;
  final CoutureRepository _repository = CoutureRepository.instance;

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController(text: currentClient.value?.fullName);
    phoneController = TextEditingController(text: currentClient.value?.phone);
    notesController = TextEditingController(text: currentClient.value?.notes);
    initData();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void initData() async {
    isLoading.value = true;
    await getClients();
    if (currentClient.value != null) {
      sheets.value = await _repository.sheetsForClient(currentClient.value!.id);
    }
    isLoading.value = false;
  }

  Future<void> getClients() async {
    clients.value = await _repository.clients();
  }

  Future<void> save({required BuildContext context}) async {
    if (!formKey.currentState!.validate() || saving.value) return;
    saving.value = true;

    final now = DateTime.now();
    final existing = newClient.value;
    final client = Client(
      id: existing?.id ?? Utils.newId('client'),
      fullName: nameController.text.trim(),
      phone: phoneController.text.trim(),
      notes: notesController.text.trim(),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      await _repository.saveClient(client);
      await refreshClient(clientId: client.id);
      await getClients();
      isEditing.value = false;
      newClient.value = null;
      saving.value = false;
      NavigationService.pop();
    } catch (error) {
      saving.value = false;
      if (context.mounted) {
        Utils.getSnackBar(
          context: context,
          child: Text('Enregistrement impossible : $error'),
        );
      }
    }
  }

  Future<void> refreshClient({required String clientId}) async {
    isRefreshing.value = true;
    final updated = await _repository.client(clientId);
    currentClient.value = updated;
    sheets.value = await _repository.sheetsForClient(clientId);
    isRefreshing.value = false;
  }

  Future<void> editClient() async {
    newClient.value = currentClient.value;
    isEditing.value = true;
    NavigationService.push(AppRoutes.clientForm);
  }

  Future<void> createClient() async {
    newClient.value = null;
    isEditing.value = false;
    NavigationService.push(AppRoutes.clientForm);
  }

  Future<void> deleteClient({required BuildContext context}) async {
    final confirmed = await Utils.getDialog(
      context: context,
      title: 'Supprimer ce client ?',
      content:
          'Toutes les fiches et photos de ${currentClient.value?.fullName} seront définitivement supprimées.',
      buttonText: 'Supprimer',
    );
    if (confirmed != true) return;

    await _repository.deleteClient(currentClient.value!.id);
    await getClients();
    NavigationService.pop();
  }
}
