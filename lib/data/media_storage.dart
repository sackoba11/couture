import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Gère les photos prises par le tailleur, stockées dans le dossier
/// privé de l'application (aucune connexion requise).
class MediaStorage {
  MediaStorage._();

  static Directory? _root;

  static Future<Directory> root() async {
    final cached = _root;
    if (cached != null) return cached;
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(documents.path, 'media'));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return _root = directory;
  }

  /// Copie une photo dans le dossier privé et renvoie son chemin relatif.
  static Future<String> importImage(XFile image, String sheetId) async {
    final rootDirectory = await root();
    final folder = Directory(p.join(rootDirectory.path, sheetId));
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    final extension = p.extension(image.path).isEmpty
        ? '.jpg'
        : p.extension(image.path).toLowerCase();
    final fileName =
        '${DateTime.now().microsecondsSinceEpoch}_${image.name.hashCode.abs()}$extension';
    final destination = File(p.join(folder.path, fileName));
    await File(image.path).copy(destination.path);
    return '$sheetId/$fileName';
  }

  static Future<File> file(String relativePath) async {
    final rootDirectory = await root();
    return File(p.joinAll([rootDirectory.path, ...relativePath.split('/')]));
  }

  static Future<void> deletePhoto(String relativePath) async {
    try {
      final target = await file(relativePath);
      if (await target.exists()) {
        await target.delete();
      }
    } on FileSystemException {
      // La photo a déjà été supprimée : rien à faire.
    }
  }

  static Future<void> deleteSheetFolder(String sheetId) async {
    try {
      final rootDirectory = await root();
      final folder = Directory(p.join(rootDirectory.path, sheetId));
      if (await folder.exists()) {
        await folder.delete(recursive: true);
      }
    } on FileSystemException {
      // Dossier déjà absent.
    }
  }
}
