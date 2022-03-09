import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';

class DurationPicker extends StatefulWidget {
  late final int _initialHours;
  late final int _initialMinutes;
  final ValueChanged<Duration> onChanged;

  DurationPicker({
    Duration? initialDuration,
    required this.onChanged
  }) {
    this._initialHours = initialDuration?.inHours ?? 0;
    this._initialMinutes = (initialDuration?.inMinutes ?? 0) % 60;
  }
  
  @override
  _DurationPickerState createState() {
    return _DurationPickerState();
  }

}

class _DurationPickerState extends State<DurationPicker> {
  int _hours = 0;
  int _minutes = 0;

  @override
  void initState() {
    super.initState();
    _hours = widget._initialHours;
    _minutes = widget._initialMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final hoursPicker = NumberPicker(
      value: _hours,
      minValue: 0,
      maxValue: 10, //TODO control this from outside
      onChanged: (value) => setState(() { 
        _hours = value;
        widget.onChanged(_getSelectedDuration());
      }),
    );
    final minutesPicker = NumberPicker(
      value: _minutes,
      minValue: 0,
      maxValue: 59,
      onChanged: (value) => setState(() { 
        _minutes = value;
        widget.onChanged(_getSelectedDuration());
      }),
    );
    //scaffold the full homepage
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Column(
          children: [
            Text("Hours"),
            hoursPicker
          ],
        ),
        Column(
          children: [
            Text("Minutes"),
            minutesPicker,
          ],
        ),
      ],
    );
  }

  Duration _getSelectedDuration() {
      return Duration(hours: _hours, minutes: _minutes);
  }
}