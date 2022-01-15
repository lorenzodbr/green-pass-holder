import 'package:flutter/material.dart';
import 'package:dart_base45/dart_base45.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:cbor/cbor.dart';

class InformationPanel extends StatelessWidget {
  final String qrData;

  String _raw = "";
  late final List<int> inflated;
  late final Map payload;
  String name = "-";
  bool isSuperGreenPass = false;

  String surname = "-";
  String version = "-";
  String dob = "-";

  String vaccineType = "-";
  int doseNumber = 0;
  int totalSeriesOfDoses = 0;
  String dateOfVaccination = "-";
  String ci = "-";
  DateTime expiration = new DateTime.utc(1900, 1, 1);

  static const APP_MIN_VERSION = "android";
  static const RECOVERY_CERT_START_DAY = "recovery_cert_start_day";
  static const RECOVERY_CERT_END_DAY = "recovery_cert_end_day";
  static const MOLECULAR_TEST_START_HOUR = "molecular_test_start_hours";
  static const MOLECULAR_TEST_END_HOUR = "molecular_test_end_hours";
  static const RAPID_TEST_START_HOUR = "rapid_test_start_hours";
  static const RAPID_TEST_END_HOUR = "rapid_test_end_hours";
  static const VACCINE_START_DAY_NOT_COMPLETE =
      "vaccine_start_day_not_complete";
  static const VACCINE_END_DAY_NOT_COMPLETE = "vaccine_end_day_not_complete";
  static const VACCINE_START_DAY_COMPLETE = "vaccine_start_day_complete";
  static const VACCINE_END_DAY_COMPLETE = "vaccine_end_day_complete";
  static const String prefix = "HC1:";
  static const String urlRules = "https://get.dgc.gov.it/v1/dgc/settings";
  static const String TRUST_LIST_URL =
      'https://raw.githubusercontent.com/bcsongor/covid-pass-verifier/35336fd3c0ff969b5b4784d7763c64ead6305615/src/data/certificates.json'; //get from https://github.com/ministero-salute/dcc-utils/blob/master/examples/verify_signature_from_list.js

  static const String NOT_DETECTED = "260415000";
  static const String NOT_VALID_YET = "Not valid yet";
  static const String VALID = "Valid";
  static const String NOT_VALID = "Not valid";
  static const String NOT_GREEN_PASS = "Not a green pass";
  static const String PARTIALLY_VALID =
      "Valid only in Italy"; //values get from https://github.com/eu-digital-green-certificates/dgca-app-core-android/blob/b9ba5b3bc7b8f1c510a79d07bbaecae8a6edfd74/decoder/src/main/java/dgca/verifier/app/decoder/model/Test.kt
  static const String DETECTED = "260373001";

  static const String TEST_RAPID = "LP217198-3";
  static const String TEST_MOLECULAR = "LP6464-4";

  InformationPanel(this.qrData) {
    if (qrData != "" && _raw == "") {
      try {
        decodeQRData();
      } catch (ex) {
        _raw = "";
      }
    } else {
      _raw = "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("Informazioni"),
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          )),
      body: Container(
        margin: EdgeInsets.all(20),
        child: ListView(
          children: <Widget>[
            new TextFormField(
              decoration: new InputDecoration(
                labelText: 'Nome',
              ),
              readOnly: true,
              initialValue: name,
            ),
            new TextFormField(
              decoration: new InputDecoration(
                labelText: 'Cognome',
              ),
              readOnly: true,
              initialValue: surname,
            ),
            new TextFormField(
              decoration: new InputDecoration(
                labelText: 'Super Green Pass?',
              ),
              readOnly: true,
              initialValue: isSuperGreenPass ? "Sì" : "No",
            ),
            new TextFormField(
              decoration: new InputDecoration(
                labelText: 'Versione Green Pass',
              ),
              readOnly: true,
              initialValue: version,
            ),
            new TextFormField(
              decoration: new InputDecoration(
                labelText: 'Data di nascita',
              ),
              readOnly: true,
              initialValue: dob,
            ),
            new TextFormField(
              decoration: new InputDecoration(
                labelText: 'Tipo di vaccino',
              ),
              readOnly: true,
              initialValue: vaccineType,
            ),
            new TextFormField(
              decoration: new InputDecoration(
                labelText: 'Numero di dosi effettuate/Numero di dosi totali',
              ),
              readOnly: true,
              initialValue:
                  doseNumber.toString() + "/" + totalSeriesOfDoses.toString(),
            ),
            new TextFormField(
              decoration: new InputDecoration(
                labelText: 'Data di vaccinazione',
              ),
              readOnly: true,
              initialValue: dateOfVaccination,
            ),
            new TextFormField(
              decoration: new InputDecoration(
                labelText: 'Codice Univoco',
              ),
              readOnly: true,
              initialValue: ci,
              maxLines: null,
            ),
            new TextFormField(
              decoration: new InputDecoration(
                labelText: 'Data di fine validità',
              ),
              readOnly: true,
              initialValue: DateFormat('yyyy-MM-dd').format(expiration),
            ),
          ],
        ),
      ),
    );
  }

  String decodeQRData() {
    try {
      _raw = qrData;
      Uint8List decodedBase45 = Base45.decode(_raw.substring(prefix.length));
      List<int> inflated = ZLibDecoder().decodeBytes(decodedBase45);
      Cbor cbor = Cbor();
      cbor.decodeFromList(inflated);
      List<dynamic>? rawDecodification = cbor.getDecodedData();
      cbor.clearDecodeStack();

      cbor.decodeFromList(rawDecodification![0][2]);

      Map decodedData = Map<dynamic, dynamic>.from(cbor.getDecodedData()![0]);

      expiration = DateTime.fromMillisecondsSinceEpoch(
          decodedData[4] * 1000); //is timestamp

      payload = Map<String, dynamic>.from(decodedData[-260][1]);

      if (payload.containsKey("r")) {
        ci = payload["r"].first["ci"];
        isSuperGreenPass =
            true; //viene definito SuperGreenpass il pass che certifica Guarigione (r) o Vaccinazione (v)
      }
      if (payload.containsKey("v")) {
        vaccineType = payload["v"].first["mp"];
        doseNumber = payload["v"].first["dn"];
        dateOfVaccination = payload["v"].first["dt"];
        totalSeriesOfDoses = payload["v"].first["sd"];
        ci = payload["v"].first["ci"];
        isSuperGreenPass =
            true; //viene definito SuperGreenpass il pass che certifica Guarigione (r) o Vaccinazione (v)
      }
      if (payload.containsKey("t")) {
        ci = payload["t"].first["ci"];
        isSuperGreenPass =
            false; //viene definito SuperGreenpass il pass che certifica Guarigione (r) o Vaccinazione (v)
      }

      version = payload["ver"];
      dob = payload["dob"];
      name = payload["nam"]["gn"];
      surname = payload["nam"]["fn"];

      return _raw;
    } catch (ex) {
      throw new Exception();
    }
  }

  Widget _buildForm() {
    return Container();
  }
}
