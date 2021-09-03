import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_qr_reader/flutter_qr_reader.dart';

import 'pass_holder.dart';
import 'floating_dialog.dart';

//import 'dart:io';

final _appTitle = 'Green Pass';
enum qrStates { f, t, loading }

qrStates hasQrBeenSet = qrStates.loading;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _appTitle,
      theme: ThemeData(
        primarySwatch: Colors.grey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getQr(),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_appTitle),
            actions: hasQrBeenSet == qrStates.t
                ? [IconButton(icon: Icon(Icons.folder_open), onPressed: setQr)]
                : null,
            backgroundColor: Colors.white,
          ),
          body: Center(
              child: Column(
            children: [
              buildPassHolder(snapshot.data ?? ''),
            ],
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
          )),
        );
      },
    );
  }

  Widget buildPassHolder(String qrData) {
    if (hasQrBeenSet == qrStates.t) {
      return PassHolder(qrData);
    } else if (hasQrBeenSet == qrStates.f) {
      return ElevatedButton(
        onPressed: setQr,
        child: Text('Seleziona QR Code',
            style: TextStyle(
              fontSize: 18,
            )),
      );
    } else {
      return Text('Caricamento...',
          style: TextStyle(
            fontSize: 18,
          ));
    }
  }

  void qrBeenSet() {
    setState(() {
      hasQrBeenSet = qrStates.t;
    });
  }

  Future<String> getQr() async {
    final prefs = await SharedPreferences.getInstance();

    String qr = prefs.getString('qr') ?? '';

    if (qr != '') {
      setState(() {
        hasQrBeenSet = qrStates.t;
      });
    } else {
      setState(() {
        hasQrBeenSet = qrStates.f;
      });
    }

    return qr;
  }

  void setQr() async {
    final ImagePicker _picker = ImagePicker();

    XFile imageXFile =
        await _picker.pickImage(source: ImageSource.gallery) ?? XFile('');

    String path = imageXFile.path;

    print(path);

    if (path != '') {
      String qr = await FlutterQrReader.imgScan(path);

      if (qr != '') {
        print('qr:' + qr);

        final prefs = await SharedPreferences.getInstance();

        prefs.setString('qr', qr);

        qrBeenSet();

        FloatingDialog.showMyDialog(context, 'Operazione eseguita',
            'QR Code aggiunto correttamente', 'OK');
      } else {
        FloatingDialog.showMyDialog(
            context,
            'Errore',
            'Impossibile aggiungere questo QR Code. Provare con un altro',
            'Capito');
      }
    }
  }
}
