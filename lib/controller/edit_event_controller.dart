import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditEventController extends GetxController {
  List<File> listOfImage = [];
  List<String> listOfImageUrl = [];
  bool isLoading = false;

  updateLoading(bool value) {
    isLoading = value;
    update();
  }

  /// UPLOAD IMAGE TO FIREBASE
  Future<String?> uploadFile({File? file, String? filename, String? dir, required BuildContext context}) async {
    print("File path:$file");
    try {
      var response = await FirebaseStorage.instance.ref("Event/$dir/$filename").putFile(file!);
      var result = await response.storage.ref("Event/$dir/$filename").getDownloadURL();
      return result;
    } catch (e) {
      print("ERROR===>>$e");
    }

    return null;
  }

  /// MULTIPLE IMAGE PICKER
  pickImages(String eventName, String docId, {required BuildContext context}) async {
    updateLoading(true);

    FilePickerResult? selectedImages = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'webp', 'jpeg'],
    );

    if (selectedImages != null) {
      try {
        listOfImageUrl.clear();

        selectedImages.files.forEach((element) async {
          listOfImage.add(File(element.path!));
        });
        print('selectedImages  image of  ${selectedImages}');
        for (int i = 0; i < listOfImage.length; i++) {
          var maxFileSizeInBytes = 2 * 1048576;
          var imagePath = await listOfImage[i].readAsBytes();

          var fileSize = imagePath.length; // Get the file size in bytes
          if (fileSize <= maxFileSizeInBytes) {
            String? url = await uploadFile(
              file: listOfImage[i],
              filename: listOfImage[i].toString().split('/').last.toString(),
              dir: eventName.toString(),
              context: context,
            );

            FirebaseFirestore.instance.collection('Events').doc('${docId}').collection('Eventimage').add(
                {'image': url, 'time': DateTime.now(), 'name': listOfImage[i].toString().split('/').last.toString()});
          } else {
            updateLoading(false);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please select less than 2 MB image'),
              ),
            );
            break;
          }
        }

        clearAll();
      } catch (e) {
        print('UPLOAD ERROR:- $e');
        updateLoading(false);
      }
    }

    updateLoading(false);
    update();
  }

  /// SINGLE IMAGE PICKER
  File? image;

  pickImage(int index, String fileName, String eventName, String eventId, String docId,
      {required BuildContext context}) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'webp', 'jpeg'],
    );
    if (result == null) {
      print("No file selected");
    } else {
      /// return 0  catch error
      /// return 1  Done
      /// return 2  Image size error
      updateLoading(true);

      image = File(result.files.single.path!);
      print("File path:$image");
      var maxFileSizeInBytes = 2 * 1048576;
      var imagePath = await image!.readAsBytes();

      var fileSize = imagePath.length;

      // if (fileSize <= maxFileSizeInBytes) {
      try {
        String? url = await uploadFile(filename: fileName, file: image, dir: eventName.toString(), context: context);
        FirebaseFirestore.instance
            .collection('Events')
            .doc('${docId}')
            .collection('Eventimage')
            .doc(eventId)
            .update({'image': url, 'time': DateTime.now(), 'name': image.toString().split('/').last.toString()});
        // return 1;
      } catch (e) {
        updateLoading(false);
        print('----ERORORO---$e');
        // return 0;
      }
      // } else {
      // File is too large, ask user to upload a smaller file, or compress the file/image
      // updateLoading(false);
      // debugPrint("2 mB moreeeeee");
      // return 2;
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Please select less than 2 MB image'),
      //   ),
      // );
      // }
      update();
      updateLoading(false);

      print('Audio pick= = ${result.files.single.name}');
    }
    update();
  }

  /// DELETE IMAGE
  removeImage(String docId, String eventId) async {
    FirebaseFirestore.instance.collection('Events').doc(eventId).collection('Eventimage').doc(docId).delete();
    update();
  }

  /// DELETE COLLECTION
  deleteCollection(String eventId) async {
    var data = FirebaseFirestore.instance.collection('Events').doc(eventId).collection('Eventimage');
    var info = await data.get();
    info.docs.forEach((element) {
      FirebaseFirestore.instance.collection('Events').doc(eventId).collection('Eventimage').doc(element.id).delete();
    });
    FirebaseFirestore.instance.collection('Events').doc(eventId).delete();
    Get.back();
    Get.back();
  }

  /// CLEAAR ALL
  clearAll() {
    listOfImageUrl.clear();
    listOfImage.clear();
    image = null;

    update();
  }
}
