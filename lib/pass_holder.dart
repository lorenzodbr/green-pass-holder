import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PassHolder extends StatefulWidget {
  final String qrData;

  PassHolder(this.qrData);

  @override
  _PassHolderState createState() => _PassHolderState();
}

class _PassHolderState extends State<PassHolder> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(15, 15, 15, 30),
      child: QrImage(
        data: widget.qrData,
        version: QrVersions.auto,
      ),
    );
  }
}
