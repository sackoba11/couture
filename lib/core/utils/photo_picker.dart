import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Demande à l'utilisateur l'origine de la photo (appareil ou galerie).
Future<ImageSource?> showPhotoSourceSheet(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                child: Text(
                  'Ajouter une photo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Prendre une photo'),
                subtitle: const Text('Appareil photo du téléphone'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choisir dans la galerie'),
                subtitle: const Text('Sélectionner une image existante'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Ouvre la galerie ou l'appareil photo et renvoie l'image choisie.
Future<XFile?> pickImageFrom(BuildContext context) async {
  final source = await showPhotoSourceSheet(context);
  if (source == null || !context.mounted) return null;
  try {
    return await ImagePicker().pickImage(
      source: source,
      maxWidth: 1800,
      imageQuality: 85,
    );
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible d\'ouvrir l\'appareil photo. '
            'Vérifiez les autorisations.',
          ),
        ),
      );
    }
    return null;
  }
}
