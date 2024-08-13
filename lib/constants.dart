import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Constants{
   static void toastMessage(
      {required BuildContext context, required String msg,  Color? bgColor,  Color? textColor}) {
    Fluttertoast.showToast(
      msg: msg,
      backgroundColor: bgColor,textColor: textColor
    );
  }

  static void showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: const CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }

  static void hideLoading(BuildContext context) {
    Navigator.of(context).pop();
  }
}