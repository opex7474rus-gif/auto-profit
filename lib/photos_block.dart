import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'car.dart';
import 'utils.dart';
import 'widgets_ui.dart';

class PhotosBlock extends StatelessWidget {
  final Car car;
  final VoidCallback onChanged;

  const PhotosBlock({super.key, required this.car, required this.onChanged});

  Future<void> _addPhoto(BuildContext context) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Из галереи'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Сделать фото'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1600,
    );
    if (picked == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(dir.path, 'photos'));
    if (!await photosDir.exists()) await photosDir.create(recursive: true);
    final newPath = p.join(
      photosDir.path,
      'photo_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await File(picked.path).copy(newPath);
    car.photos.add('local:$newPath');
    onChanged();
  }

  Future<void> _removePhoto(int index) async {
    final path = car.photos[index];
    if (!isCloudUrl(path)) {
      try {
        final f = File(localPathOf(path));
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    car.photos.removeAt(index);
    onChanged();
  }

  void _openPhoto(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: InteractiveViewer(
          child: isCloudUrl(path)
              ? Image.network(path)
              : Image.file(File(localPathOf(path))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PaddedCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_library_outlined, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Фотографии',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _addPhoto(context),
                icon: const Icon(Icons.add_a_photo_outlined),
              ),
            ],
          ),
          if (car.photos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Фото пока нет',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            SizedBox(
              height: 108,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: car.photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final path = car.photos[index];
                  return Stack(
                    children: [
                      InkWell(
                        onTap: () => _openPhoto(context, path),
                        borderRadius: BorderRadius.circular(12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 108,
                            height: 108,
                            child: isCloudUrl(path)
                                ? Image.network(
                                    path,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.black12,
                                      child: const Icon(
                                          Icons.broken_image_outlined),
                                    ),
                                  )
                                : (File(localPathOf(path)).existsSync()
                                    ? Image.file(
                                        File(localPathOf(path)),
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: Colors.black12,
                                        child: const Icon(
                                            Icons.broken_image_outlined),
                                      )),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Material(
                          color: Colors.black54,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: () => _removePhoto(index),
                            customBorder: const CircleBorder(),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
