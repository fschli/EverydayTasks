import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:personaltasklogger/ui/DurationPicker.dart';

void showConfirmationDialog(BuildContext context, String title, String message,
    {Function()? okPressed, Function()? cancelPressed}) {
  Widget cancelButton = TextButton(
    child: Text("Cancel"),
    onPressed:  cancelPressed,
  );
  Widget okButton = TextButton(
    child: Text("Ok"),
    onPressed:  okPressed,
  );

  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: Text(message),
    actions: [
      cancelButton,
      okButton,
    ],
  );  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

/// Returns if a duration was chosen
Future<bool?> showDurationPickerDialog(BuildContext context, Function(Duration) _selectedDuration,
    [Duration? initialDuration]) {

  final durationPicker = DurationPicker(initialDuration, _selectedDuration);

  Dialog dialog = Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), //this right here
    child: Container(
      height: 300.0,
      width: 300.0,

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          durationPicker,
          SizedBox(height: 20.0,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
            TextButton(
              child: Text("Cancel"),
              onPressed:  () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text("Ok"),
              onPressed:  () => Navigator.of(context).pop(true),
            )
            ],)
        ],
      ),
    ),
  );

  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return dialog;
    },
  );
}