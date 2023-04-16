import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/widget_keys.dart';

class UserImagePicker extends StatefulWidget {
  final Function pickedImageFn;

  UserImagePicker(this.pickedImageFn);
  @override
  State<UserImagePicker> createState() => _UserImagePickerState();
}

class _UserImagePickerState extends State<UserImagePicker> {
  //creating an instance of the image picker using image_picker  api
  final _pick = ImagePicker();
  //defining picked image file
  File? _pickedImage;

  Future<void> _addImage() async {
    final imageFile = await _pick.pickImage(
        source: ImageSource.camera, maxWidth: 150, imageQuality: 50);
    //updating image file with selected camera image
    setState(() {
      _pickedImage = File(imageFile!.path);
    });
    //executing auth card pick image function to store picked image in firebasestore
    widget.pickedImageFn(_pickedImage);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          key: WidgetKey.avatarPreview,
          radius: 40,
          backgroundColor: Colors.grey,
          backgroundImage:
              _pickedImage != null ? FileImage(_pickedImage!) : null,
        ),
        TextButton.icon(
          key: WidgetKey.textIconButton,
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
