import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/navigation_service.dart';
import '../../../../core/utils/utils.dart';
import '../../../../data/models/client/client.dart';
import '../../../../data/models/measurement_sheet/measurement_sheet.dart';
import '../../../../data/repositories/couture_repository/couture_repository.dart';

class ClientController extends GetxController {
  final currentClient = Rxn<Client>();
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController notesController;
  late Future<List<MeasurementSheet>> sheets;
  final saving = false.obs;

  bool get isEditing => currentClient.value != null;
  final CoutureRepository _repository = CoutureRepository.instance;

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController(text: currentClient.value?.fullName);
    phoneController = TextEditingController(text: currentClient.value?.phone);
    notesController = TextEditingController(text: currentClient.value?.notes);
    sheets = _repository.sheetsForClient(currentClient.value!.id);
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> save({required BuildContext context}) async {
    if (!formKey.currentState!.validate() || saving.value) return;
    saving.value = true;

    final now = DateTime.now();
    final existing = currentClient.value;
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
}
