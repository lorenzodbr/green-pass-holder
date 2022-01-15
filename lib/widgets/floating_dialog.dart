import 'package:flutter/material.dart';

class FloatingDialog {
  static void showMyDialog(
      BuildContext context, String title, String body, String dismiss,
      {Function? callback}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(body),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(dismiss),
              onPressed: () {
                Navigator.of(context).pop(); //ritorno alla pagina precedente
                if (callback != null) {
                  callback();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
