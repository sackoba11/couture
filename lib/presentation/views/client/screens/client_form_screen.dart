import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../widgets/section_card.dart';
import '../controller/client_controller.dart';

class ClientFormScreen extends GetView<ClientController> {
  const ClientFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (controller.isEditing.value && controller.newClient.value != null) {
      controller.nameController.text = controller.newClient.value!.fullName;
      controller.phoneController.text = controller.newClient.value!.phone;
      controller.notesController.text = controller.newClient.value!.notes;
    } else {
      controller.nameController.text = "";
      controller.phoneController.text = "";
      controller.notesController.text = "";
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.isEditing.value ? 'Modifier le client' : 'Nouveau client',
        ),
      ),
      body: Form(
        key: controller.formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SectionCard(
              title: 'Informations',
              icon: Icons.person_outline,
              child: Column(
                children: [
                  TextFormField(
                    controller: controller.nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofocus: !controller.isEditing.value,
                    decoration: const InputDecoration(
                      labelText: 'Nom complet *',
                      hintText: 'Ex. Awa Diop',
                      prefixIcon: Icon(Icons.badge_outlined, size: 20),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 2) {
                        return 'Entrez le nom du client';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: controller.phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9+\s().-]'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Téléphone',
                      hintText: 'Ex. 77 123 45 67',
                      prefixIcon: Icon(Icons.phone_outlined, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SectionCard(
              title: 'Notes',
              icon: Icons.notes,
              child: TextFormField(
                controller: controller.notesController,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Préférences, morphologie, rendez-vous, retouches…',
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
        () => SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: controller.saving.value
                ? null
                : () => controller.save(context: context),
            icon: controller.saving.value
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check),
            label: Text(
              controller.saving.value ? 'Enregistrement…' : 'Enregistrer',
            ),
          ),
        ),
      ),
    );
  }
}
