import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Выбор фото из галереи и сохранение копии в папке приложения.
class PhotoService {
  final ImagePicker _picker = ImagePicker();

  /// Возвращает путь к сохранённому файлу или null (отмена / веб-версия).
  Future<String?> pickPhoto() async {
    if (kIsWeb) return null;

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1400,
      imageQuality: 80,
    );
    if (picked == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/photos');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    final path = '${folder.path}/${DateTime.now().microsecondsSinceEpoch}.jpg';
    await File(picked.path).copy(path);
    return path;
  }
}
