import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerRow extends StatefulWidget {
  final void Function(List<File> files) onChanged;
  const ImagePickerRow({super.key, required this.onChanged});

  @override
  State<ImagePickerRow> createState() => _ImagePickerRowState();
}

class _ImagePickerRowState extends State<ImagePickerRow> {
  final _picker = ImagePicker();
  final List<File> _files = [];

  Future<void> _pick(ImageSource source) async {
    final x = await _picker.pickImage(source: source, maxWidth: 1440);
    if (x != null) {
      setState(() => _files.add(File(x.path)));
      widget.onChanged(_files);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._files.map((f) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(f, width: 80, height: 80, fit: BoxFit.cover),
                )),
            OutlinedButton.icon(
              icon: const Icon(Icons.photo_camera),
              label: Text(AppLocalizations.of(context)!.camera),
              onPressed: () => _pick(ImageSource.camera),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: Text(AppLocalizations.of(context)!.gallery),
              onPressed: () => _pick(ImageSource.gallery),
            ),
          ],
        ),
      ],
    );
  }
}
