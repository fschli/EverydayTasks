import 'package:flutter/material.dart';
import 'package:personaltasklogger/db/repository/TaskEventRepository.dart';
import 'package:personaltasklogger/util/dates.dart';

import '../model/Severity.dart';
import '../model/TaskEvent.dart';

class TaskEventsList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return TaskEventsListState();
  }
}

class TaskEventsListState extends State<TaskEventsList> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TaskEvent>>(
      future: TaskEventRepository.getAll(), // _loadTaskEvents(),
      initialData: [],
      builder: (context, snapshot) {
        return _buildList(context, snapshot);
      },
    );
  }

  Widget _buildList(
      BuildContext context, AsyncSnapshot<List<TaskEvent>> snapshot) {
    if (!snapshot.hasData) {
      return Center(
          child: Text("Nothing to show, create a new event log first."));
    }
    var taskEvents = snapshot.data!;
    // var taskEvents = _loadTaskEvents();

    DateTime? dateHeading = null;
    List<Widget> rows = List.empty(growable: true);
    for (var i = 0; i < taskEvents.length; i++) {
      var taskEvent = taskEvents[i];
      var taskEventDate = truncToDate(taskEvent.startedAt);
      DateTime? usedDateHeading = null;

      if (dateHeading == null) {
        dateHeading = truncToDate(taskEvent.startedAt);
        usedDateHeading = dateHeading;
      } else if (taskEventDate.isBefore(dateHeading)) {
        usedDateHeading = taskEventDate;
      }
      dateHeading = taskEventDate;
      rows.add(_buildRow(taskEvent, usedDateHeading));
    }

    return ListView(
      children: rows,
    );
  }

  Widget _buildRow(TaskEvent taskEvent, DateTime? dateHeading) {
    List<Widget> expansionWidgets = _createExpansionWidgets(taskEvent);

    var listTile = ListTile(
      title: dateHeading != null
          ? Text(
              formatToDateOrWord(dateHeading),
              style: TextStyle(color: Colors.grey, fontSize: 10.0),
            )
          : null,
      subtitle: Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          title: Text(taskEvent.name),
          subtitle: Text(taskEvent.originTaskGroup ?? ""),
          //          backgroundColor: Colors.lime,
          children: expansionWidgets,
        ),
      ),
    );

    if (dateHeading != null) {
      return Column(
        children: [const Divider(), listTile],
      );
    } else {
      return listTile;
    }
  }

  List<Widget> _createExpansionWidgets(TaskEvent taskEvent) {
    var expansionWidgets = <Widget>[];

    if (taskEvent.description != null && taskEvent.description!.isNotEmpty) {
      expansionWidgets.add(Padding(
        padding: EdgeInsets.all(4.0),
        child: Text(taskEvent.description!),
      ));
    }

    expansionWidgets.addAll([
      Padding(
        padding: EdgeInsets.all(4.0),
        child: Text(
            formatToDateTimeRange(taskEvent.startedAt, taskEvent.finishedAt)),
      ),
      Padding(
        padding: EdgeInsets.all(4.0),
        child: severityToIcon(taskEvent.severity),
      ),
      Divider(),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ButtonBar(
            alignment: MainAxisAlignment.start,
            children: [
              TextButton(
                onPressed: () {},
                child: Icon(taskEvent.favorite
                    ? Icons.favorite
                    : Icons.favorite_border),
              ),
            ],
          ),
          ButtonBar(
            alignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  // Perform some action
                },
                child: const Text("Change"),
              ),
              TextButton(
                onPressed: () {
                  // Perform some action
                },
                child: const Icon(Icons.delete),
              ),
            ],
          ),
        ],
      ),
    ]);
    return expansionWidgets;
  }

  Future<List<TaskEvent>> _loadTaskEvents() async {
    var taskEvents = [
      TaskEvent(
          1,
          "Wash up",
          "Washing all up",
          "Household/Daily",
          null,
          DateTime(2021, 5, 12, 17, 30),
          DateTime(2021, 5, 12, 17, 45),
          Severity.MEDIUM,
          false),
      TaskEvent(
          2,
          "Clean kitchen",
          "Clean all in kitchen",
          "Household/Weekly",
          null,
          DateTime(2021, 5, 12, 20, 30),
          DateTime(2021, 5, 12, 21, 00),
          Severity.MEDIUM,
          false),
      TaskEvent(
          3,
          "Bring kid to daycare",
          "",
          "Care/Daily",
          null,
          DateTime(2021, 5, 11, 08, 05),
          DateTime(2021, 5, 11, 08, 20),
          Severity.EASY,
          true),
      TaskEvent(
          4,
          "Cook lunch",
          "Pasta",
          "Cooking",
          null,
          DateTime.now().subtract(Duration(minutes: 10)),
          DateTime.now(),
          Severity.HARD,
          false),
      TaskEvent(
          6,
          "Repair closet",
          "Pasta",
          "Repair",
          null,
          DateTime.now().subtract(Duration(minutes: 10, days: 1)),
          DateTime.now().subtract(Duration(days: 1)),
          Severity.HARD,
          false),
      TaskEvent(
          7,
          "Build bathroom",
          "Assemble Ikea bathroom furniture",
          "Construct/Assembe",
          null,
          DateTime(2020, 12, 1, 09, 30),
          DateTime(2020, 12, 1, 14, 20),
          Severity.HARD,
          true),
    ];

    // return descending sorted list
    return taskEvents..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }

  Widget severityToIcon(Severity severity) {
    List<Icon> icons = List.generate(
        severity.index + 1, (index) => Icon(Icons.fitness_center_outlined));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: icons,
    );
  }
}
