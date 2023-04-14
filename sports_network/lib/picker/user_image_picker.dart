import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UserImagePicker extends StatefulWidget {
  final Function pickedImageFn;

  UserImagePicker(this.pickedImageFn);
  @override
  State<UserImagePicker> createState() => _UserImagePickerState();
}

class _UserImagePickerState extends State<UserImagePicker> {
  final _pick = ImagePicker();
  late File _pickedImage;

  Future<void> _addImage() async {
    final imageFile = await _pick.pickImage(
        source: ImageSource.camera, maxWidth: 150, imageQuality: 50);

    setState(() {
      _pickedImage = File(imageFile!.path);
    });

    widget.pickedImageFn(_pickedImage);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey,
          backgroundImage:
              _pickedImage != null ? FileImage(_pickedImage) : null,
        ),
        TextButton.icon(
          icon: const Icon(Icons.image),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
          label: const Text('add image'),
          onPressed: _addImage,
        ),
      ],
    );
  }
}
