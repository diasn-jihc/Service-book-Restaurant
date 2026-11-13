import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/photo_service.dart';
import '../utils/actions.dart';
import 'restaurant_image.dart';

const maxPhotos = 6;

/// Ряд фото с кнопкой «добавить» и удалением по крестику.
class PhotoPickerRow extends StatelessWidget {
  const PhotoPickerRow({
    super.key,
    required this.photos,
    required this.onChanged,
  });

  final List<String> photos;
  final void Function(List<String> photos) onChanged;

  Future<void> _add(BuildContext context) async {
    final service = context.read<PhotoService>();
    final path = await service.pickPhoto();
    if (!context.mounted) return;
    if (path == null) {
      showMessage(context,
          'Фото не добавлено (в веб-версии выбор фото недоступен)');
      return;
    }
    onChanged([...photos, path]);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < photos.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Stack(
                children: [
                  PhotoThumb(path: photos[i]),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () {
                        final copy = [...photos]..removeAt(i);
                        onChanged(copy);
                      },
                      child: const CircleAvatar(
                        radius: 11,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (photos.length < maxPhotos)
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _add(context),
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white38),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined),
                    SizedBox(height: 4),
                    Text('Фото', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
