import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

final messengerkey = GlobalKey<ScaffoldMessengerState>();
//this need to be ref in mainpage material page

class Utils {
  static showSnackBar(String? text) {
    if (text == null) return;
   
    final snackBar = SnackBar(content: Text(text, style: const TextStyle(color: Colors.red),),backgroundColor: Colors.white, );
    messengerkey.currentState?..removeCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
  pickMyImage(ImageSource source)async{
    final ImagePicker imagePicker=ImagePicker();
    XFile? file=await imagePicker.pickImage(source: source);
    if(file!=null){
      return await file.readAsBytes();
    }else{
      print('No image selected');
    }
  }
}
