import 'package:flutter/material.dart';
import 'package:green_pass_holder/pages/information_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_qr_reader/flutter_qr_reader.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

import 'widgets/pass_holder.dart';
import 'widgets/floating_dialog.dart';

final _appTitle = 'Green Pass';
enum qrStates { f, t, loading }
enum authStates { f, t }

bool pickerOpened = false;
bool hasAlreadyLaunched = false;

qrStates hasQrBeenSet = qrStates.loading;
authStates hasAuthenticated = authStates.f;

late Widget _infoPage;

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
      locale: Locale("it-IT"),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print(state);
    switch (state) {
      case AppLifecycleState.resumed:
        if (hasAuthenticated == authStates.f && !pickerOpened) {
          authenticate();
        }

        if (pickerOpened) {
          pickerOpened = false;

          setState(() {
            hasAuthenticated = authStates.t;
          });
        }

        break;
      case AppLifecycleState.inactive:
        setState(() {
          hasAuthenticated = authStates.f;
        });
        break;
      case AppLifecycleState.paused:
        setState(() {
          hasAuthenticated = authStates.f;
        });
        break;
      case AppLifecycleState.detached:
        setState(() {
          hasAuthenticated = authStates.f;
        });
        break;
    }
  }

  @override
  void initState() {
    print("è stato già lanciato? -> " + hasAlreadyLaunched.toString());
    if (!hasAlreadyLaunched) {
      print("Inizio la creazione della pagina in background...");
      Future.microtask(() async {
        _infoPage = new InformationPage(await _fetchQrDataFromCache());
        print("Ho terminato la creazione della pagina in background...");
      });

      hasAlreadyLaunched = true;
    }

    FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);

    //fisso la rotazione dello schermo in verticale
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    super.initState();

    WidgetsBinding.instance!.addObserver(this);

    SchedulerBinding.instance!.addPostFrameCallback((_) async {
      authenticate();
    });
  }

  void authenticate() async {
    var localAuth = LocalAuthentication();
    try {
      bool didAuthenticate = await localAuth.authenticate(
          localizedReason: 'Autenticati per accedere all\'app');

      if (didAuthenticate) {
        setState(() {
          hasAuthenticated = authStates.t;
        });
      } else {
        SystemNavigator.pop();
      }
    } catch (ex) {
      FloatingDialog.showMyDialog(
          context,
          'Errore',
          'Nessun sistema di autenticazione (PIN o impronta) valido rilevato. Prima di poter utilizzare l\'app, impostane uno.',
          'OK', callback: () {
        SystemNavigator.pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getQr(),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_appTitle),
            actions: hasQrBeenSet == qrStates.t
                ? [
                    IconButton(
                        icon: Icon(Icons.folder_open), onPressed: _setQr),
                    IconButton(
                        icon: Icon(Icons.info_outline), onPressed: _showInfo)
                  ]
                : null,
            backgroundColor: Colors.white,
          ),
          body: Center(
              child: Column(
            children: [
              hasAuthenticated == authStates.t || pickerOpened
                  ? _buildPassHolder(snapshot.data ?? '')
                  : Container(
                      child: _buildLoadingCircle(),
                    ),
            ],
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
          )),
        );
      },
    );
  }

  Widget _buildPassHolder(String qrData) {
    if (hasQrBeenSet == qrStates.t) {
      return PassHolder(qrData);
    } else if (hasQrBeenSet == qrStates.f) {
      return ElevatedButton(
        onPressed: _setQr,
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

  void _qrBeenSet(String qr) {
    setState(() {
      hasQrBeenSet = qrStates.t;
    });

    Future.microtask(() async {
      print("creo un nuovo oggetto infopage...");
      _infoPage = new InformationPage(qr);
    });
  }

  Future<String> _getQr() async {
    String qr = await _fetchQrDataFromCache();

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

  void _setQr() async {
    pickerOpened = true;

    final ImagePicker _picker = ImagePicker();

    XFile imageXFile =
        await _picker.pickImage(source: ImageSource.gallery) ?? XFile('');

    String path = imageXFile.path;

    if (path != '') {
      String qr = await FlutterQrReader.imgScan(path);

      if (qr != '') {
        setState(() {
          hasQrBeenSet = qrStates.loading;
        });

        final prefs = await SharedPreferences.getInstance();

        prefs.setString('qr', qr);

        _qrBeenSet(qr);

        FloatingDialog.showMyDialog(context, 'Operazione eseguita',
            'QR Code aggiunto correttamente.', 'OK');
      } else {
        FloatingDialog.showMyDialog(
            context, 'Errore', 'Impossibile impostare questo QR Code.', 'OK');
      }
    }
  }

  void _showInfo() {
    print("apro la pagina delle informazioni");

    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return _infoPage;
    }));
  }

  Widget _buildLoadingCircle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          child: CircularProgressIndicator(),
          height: 70,
          width: 70,
        ),
      ],
    );
  }

  Future<String> _fetchQrDataFromCache() async {
    final prefs = await SharedPreferences.getInstance();

    String qr = prefs.getString('qr') ?? '';

    return qr;
  }

  @override
  dispose() {
    FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    WidgetsBinding.instance!.removeObserver(this);

    super.dispose();
  }
}
