import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'car.dart';
import 'models.dart';
import 'storage.dart';
import 'utils.dart';
import 'widgets_ui.dart';

class DocumentsBlock extends StatelessWidget {
  final Car car;
  final VoidCallback onChanged;

  const DocumentsBlock({
    super.key,
    required this.car,
    required this.onChanged,
  });

  IconData _icon(String type) {
    if (type == 'image') return Icons.image_outlined;
    if (type == 'pdf') return Icons.picture_as_pdf_outlined;
    return Icons.description_outlined;
  }

  Future<void> _pick(BuildContext context, String source) async {
    String name = '';
    String type = 'other';
    List<int>? bytes;
    String? mobilePath;

    if (source == 'camera' || source == 'gallery') {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source == 'camera'
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 2000,
      );
      if (picked == null) return;
      name = picked.name;
      type = 'image';
      if (kIsWeb) {
        bytes = await picked.readAsBytes();
      } else {
        mobilePath = picked.path;
      }
    } else {
      final result = await FilePicker.platform.pickFiles(
        withData: kIsWeb,
      );
      if (result == null) return;
      final file = result.files.single;
      name = file.name;
      final ext = p.extension(name).toLowerCase();
      if (ext == '.pdf') {
        type = 'pdf';
      } else if ([
        '.jpg',
        '.jpeg',
        '.png',
        '.gif',
        '.webp',
        '.heic'
      ].contains(ext)) {
        type = 'image';
      } else {
        type = 'other';
      }
      if (kIsWeb) {
        bytes = file.bytes;
      } else {
        mobilePath = file.path;
      }
    }

    if (kIsWeb) {
      // На web — сразу загружаем в облако
      if (bytes == null) return;
      final url = await Storage.uploadBytes(
        bucket: 'documents',
        bytes: bytes,
        filename: name,
      );
      if (url == null) return;
      car.attachments.add(
        Attachment(
          id: newId(),
          name: name,
          path: url,
          type: type,
          addedAt: todayIso(),
        ),
      );
    } else {
      // На мобильных — сохраняем локально
      if (mobilePath == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final docsDir = Directory(p.join(dir.path, 'documents'));
      if (!await docsDir.exists()) {
        await docsDir.create(recursive: true);
      }
      final newPath = p.join(
        docsDir.path,
        'doc_${DateTime.now().microsecondsSinceEpoch}'
        '${p.extension(mobilePath)}',
      );
      await File(mobilePath).copy(newPath);
      car.attachments.add(
        Attachment(
          id: newId(),
          name: name,
          path: 'local:$newPath',
          type: type,
          addedAt: todayIso(),
        ),
      );
    }
    onChanged();
  }

  Future<void> _open(BuildContext context, Attachment a) async {
    final path = a.path;

    if (isCloudUrl(path)) {
      if (kIsWeb) {
        final uri = Uri.parse(path);
        await launchUrl(uri, webOnlyWindowName: '_blank');
        return;
      }
      if (a.type == 'image') {
        if (!context.mounted) return;
        await showDialog(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(12),
            child: InteractiveViewer(child: Image.network(path)),
          ),
        );
        return;
      }
      final uri = Uri.parse(path);
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
      return;
    }

    if (kIsWeb) return;

    final file = File(localPathOf(path));
    if (!await file.exists()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Файл не найден')),
      );
      return;
    }
    if (a.type == 'image') {
      if (!context.mounted) return;
      await showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: InteractiveViewer(child: Image.file(file)),
        ),
      );
    } else {
      try {
        await OpenFilex.open(file.path);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось открыть: $e')),
        );
      }
    }
  }

  Future<void> _remove(Attachment a) async {
    if (!isCloudUrl(a.path) && !kIsWeb) {
      try {
        final f = File(localPathOf(a.path));
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    car.attachments.removeWhere((x) => x.id == a.id);
    onChanged();
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
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
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Сфотографировать'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pick(context, 'camera');
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Из галереи'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(context, 'gallery');
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Выбрать файл (PDF, DOCX…)'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(context, 'files');
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PaddedCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_outlined, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Документы',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _showAddMenu(context),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          if (car.attachments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Документов пока нет',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...car.attachments.map(
              (a) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary
                        .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _icon(a.type),
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
                title: Text(
                  a.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  a.addedAt,
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _remove(a),
                ),
                onTap: () => _open(context, a),
              ),
            ),
        ],
      ),
    );
  }
}
