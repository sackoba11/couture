import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/couture_repository.dart';
import '../models/client.dart';
import '../utils/ids.dart';
import '../widgets/section_card.dart';

/// Création ou modification d'un client.
class ClientFormScreen extends StatefulWidget {
  const ClientFormScreen({super.key, this.client});

  final Client? client;

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _notesController;
  bool _saving = false;

  bool get _isEditing => widget.client != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client?.fullName);
    _phoneController = TextEditingController(text: widget.client?.phone);
    _notesController = TextEditingController(text: widget.client?.notes);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);

    final now = DateTime.now();
    final existing = widget.client;
    final client = Client(
      id: existing?.id ?? newId('client'),
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      notes: _notesController.text.trim(),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      await CoutureRepository.instance.saveClient(client);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enregistrement impossible : $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier le client' : 'Nouveau client'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SectionCard(
              title: 'Informations',
              icon: Icons.person_outline,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofocus: !_isEditing,
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
                    controller: _phoneController,
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
                controller: _notesController,
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
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check),
          label: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
        ),
      ),
    );
  }
}
