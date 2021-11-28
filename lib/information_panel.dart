import 'package:flutter/material.dart';
import 'package:dart_base45/dart_base45.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:cbor/cbor.dart';
import 'package:green_pass_holder/floating_dialog.dart';

//ignore: must_be_immutable
class InformationPanel extends StatefulWidget {
  final String qrData;

  late final String _raw;
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
  final RECOVERY_CERT_START_DAY = "recovery_cert_start_day";
  final RECOVERY_CERT_END_DAY = "recovery_cert_end_day";
  final MOLECULAR_TEST_START_HOUR = "molecular_test_start_hours";
  final MOLECULAR_TEST_END_HOUR = "molecular_test_end_hours";
  final RAPID_TEST_START_HOUR = "rapid_test_start_hours";
  final RAPID_TEST_END_HOUR = "rapid_test_end_hours";
  final VACCINE_START_DAY_NOT_COMPLETE = "vaccine_start_day_not_complete";
  final VACCINE_END_DAY_NOT_COMPLETE = "vaccine_end_day_not_complete";
  final VACCINE_START_DAY_COMPLETE = "vaccine_start_day_complete";
  final VACCINE_END_DAY_COMPLETE = "vaccine_end_day_complete";
  final String prefix = "HC1:";
  final String urlRules = "https://get.dgc.gov.it/v1/dgc/settings";
  final String TRUST_LIST_URL =
      'https://raw.githubusercontent.com/bcsongor/covid-pass-verifier/35336fd3c0ff969b5b4784d7763c64ead6305615/src/data/certificates.json'; //get from https://github.com/ministero-salute/dcc-utils/blob/master/examples/verify_signature_from_list.js

  final String NOT_DETECTED = "260415000";
  final String NOT_VALID_YET = "Not valid yet";
  final String VALID = "Valid";
  final String NOT_VALID = "Not valid";
  final String NOT_GREEN_PASS = "Not a green pass";
  final String PARTIALLY_VALID =
      "Valid only in Italy"; //values get from https://github.com/eu-digital-green-certificates/dgca-app-core-android/blob/b9ba5b3bc7b8f1c510a79d07bbaecae8a6edfd74/decoder/src/main/java/dgca/verifier/app/decoder/model/Test.kt
  final String DETECTED = "260373001";

  final String TEST_RAPID = "LP217198-3";
  final String TEST_MOLECULAR = "LP6464-4";

  InformationPanel(this.qrData);

  @override
  State<InformationPanel> createState() => _InformationPanelState();
}

class _InformationPanelState extends State<InformationPanel> {
  @override
  Widget build(BuildContext context) {
    if (widget.qrData != "") {
      try {
        decodeQRData();
      } catch (ex) {}
    } else {
      widget._raw = "";
      FloatingDialog.showMyDialog(
        context,
        'Errore',
        'Nessuna informazione da visualizzare.',
        'OK',
      );
    }

    return _buildForm();
  }

  String decodeQRData() {
    try {
      widget._raw = widget.qrData;
      Uint8List decodedBase45 =
          Base45.decode(widget._raw.substring(widget.prefix.length));
      List<int> inflated = ZLibDecoder().decodeBytes(decodedBase45);
      Cbor cbor = Cbor();
      cbor.decodeFromList(inflated);
      List<dynamic>? rawDecodification = cbor.getDecodedData();
      cbor.clearDecodeStack();

      cbor.decodeFromList(rawDecodification![0][2]);

      Map decodedData = Map<dynamic, dynamic>.from(cbor.getDecodedData()![0]);

      widget.expiration = DateTime.fromMillisecondsSinceEpoch(
          decodedData[4] * 1000); //is timestamp

      widget.payload = Map<String, dynamic>.from(decodedData[-260][1]);

      if (widget.payload.containsKey("r")) {
        widget.ci = widget.payload["r"].first["ci"];
        widget.isSuperGreenPass =
            true; //viene definito SuperGreenpass il pass che certifica Guarigione (r) o Vaccinazione (v)
      }
      if (widget.payload.containsKey("v")) {
        widget.vaccineType = widget.payload["v"].first["mp"];
        widget.doseNumber = widget.payload["v"].first["dn"];
        widget.dateOfVaccination = widget.payload["v"].first["dt"];
        widget.totalSeriesOfDoses = widget.payload["v"].first["sd"];
        widget.ci = widget.payload["v"].first["ci"];
        widget.isSuperGreenPass =
            true; //viene definito SuperGreenpass il pass che certifica Guarigione (r) o Vaccinazione (v)
      }
      if (widget.payload.containsKey("t")) {
        widget.ci = widget.payload["t"].first["ci"];
        widget.isSuperGreenPass =
            false; //viene definito SuperGreenpass il pass che certifica Guarigione (r) o Vaccinazione (v)
      }

      widget.version = widget.payload["ver"];
      widget.dob = widget.payload["dob"];
      widget.name = widget.payload["nam"]["gn"];
      widget.surname = widget.payload["nam"]["fn"];

      return widget._raw;
    } catch (ex) {
      throw new Exception();
    }
  }

  Widget _buildForm() {
    return Container(
      margin: EdgeInsets.all(20),
      child: ListView(
        children: <Widget>[
          new TextFormField(
            decoration: new InputDecoration(
              labelText: 'Nome',
            ),
            readOnly: true,
            initialValue: widget.name,
          ),
          new TextFormField(
            decoration: new InputDecoration(
              labelText: 'Cognome',
            ),
            readOnly: true,
            initialValue: widget.surname,
          ),
          new TextFormField(
            decoration: new InputDecoration(
              labelText: 'Super Green Pass?',
            ),
            readOnly: true,
            initialValue: widget.isSuperGreenPass ? "Sì" : "No",
          ),
          new TextFormField(
            decoration: new InputDecoration(
              labelText: 'Versione Green Pass',
            ),
            readOnly: true,
            initialValue: widget.version,
          ),
          new TextFormField(
            decoration: new InputDecoration(
              labelText: 'Data di nascita',
            ),
            readOnly: true,
            initialValue: widget.dob,
          ),
          new TextFormField(
            decoration: new InputDecoration(
              labelText: 'Tipo di vaccino',
            ),
            readOnly: true,
            initialValue: widget.vaccineType,
          ),
          new TextFormField(
            decoration: new InputDecoration(
              labelText: 'Numero di dosi effettuate/Numero di dosi totali',
            ),
            readOnly: true,
            initialValue: widget.doseNumber.toString() +
                "/" +
                widget.totalSeriesOfDoses.toString(),
          ),
          new TextFormField(
            decoration: new InputDecoration(
              labelText: 'Data di vaccinazione',
            ),
            readOnly: true,
            initialValue: widget.dateOfVaccination,
          ),
          new TextFormField(
            decoration: new InputDecoration(
              labelText: 'Codice Univoco',
            ),
            readOnly: true,
            initialValue: widget.ci,
            maxLines: null,
          ),
          new TextFormField(
            decoration: new InputDecoration(
              labelText: 'Data di fine validità',
            ),
            readOnly: true,
            initialValue: DateFormat('yyyy-MM-dd').format(widget.expiration),
          ),
        ],
      ),
    );
  }
}
