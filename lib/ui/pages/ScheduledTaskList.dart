import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:personaltasklogger/db/repository/ChronologicalPaging.dart';
import 'package:personaltasklogger/db/repository/ScheduledTaskEventRepository.dart';
import 'package:personaltasklogger/db/repository/ScheduledTaskRepository.dart';
import 'package:personaltasklogger/db/repository/TaskEventRepository.dart';
import 'package:personaltasklogger/model/ScheduledTask.dart';
import 'package:personaltasklogger/model/ScheduledTaskEvent.dart';
import 'package:personaltasklogger/model/TaskEvent.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/model/TaskTemplate.dart';
import 'package:personaltasklogger/model/TaskTemplateVariant.dart';
import 'package:personaltasklogger/model/Template.dart';
import 'package:personaltasklogger/service/LocalNotificationService.dart';
import 'package:personaltasklogger/ui/PersonalTaskLoggerScaffold.dart';
import 'package:personaltasklogger/ui/dialogs.dart';
import 'package:personaltasklogger/ui/forms/ScheduledTaskForm.dart';
import 'package:personaltasklogger/ui/forms/TaskEventForm.dart';
import 'package:personaltasklogger/ui/pages/PageScaffold.dart';
import 'package:personaltasklogger/util/dates.dart';

import '../utils.dart';

class ScheduledTaskList extends StatefulWidget implements PageScaffold {

  _ScheduledTaskListState? _state;
  PagesHolder _pagesHolder;

  ScheduledTaskList(this._pagesHolder);

  @override
  State<StatefulWidget> createState() {
    _state = _ScheduledTaskListState();
    return _state!;
  }

  @override
  Widget getTitle() {
    return Text('Schedules');
  }

  @override
  Icon getIcon() {
    return Icon(Icons.next_plan_outlined);
  }

  @override
  List<Widget>? getActions(BuildContext context) {
    return null;
  }

  @override
  void handleFABPressed(BuildContext context) {
    _state?._onFABPressed();
  }

  void updateScheduledTask(ScheduledTask scheduledTask) {
    _state?.updateScheduledTask(scheduledTask);
  }

  @override
  bool withSearchBar() {
    return false;
  }

  @override
  void searchQueryUpdated(String? searchQuery) {
  }

  @override
  String getKey() {
    return "ScheduledTasks";
  }
}

class _ScheduledTaskListState extends State<ScheduledTaskList> with AutomaticKeepAliveClientMixin<ScheduledTaskList> {
  List<ScheduledTask> _scheduledTasks = [];
  int _selectedTile = -1;
  final _notificationService = LocalNotificationService();
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(Duration(seconds: 20), (timer) {
      setState(() {
        // update all
        _scheduledTasks..sort();
        debugPrint(".. ST timer refresh #${_timer.tick} ..");
      });
    });

    _notificationService.addHandler(handleNotificationClicked);

    final paging = ChronologicalPaging(ChronologicalPaging.maxDateTime, ChronologicalPaging.maxId, 100);
    ScheduledTaskRepository.getAllPaged(paging).then((scheduledTasks) {
      setState(() {
        _scheduledTasks = scheduledTasks;
        _scheduledTasks..sort();

        // refresh scheduled notifications. Could be lost if phone was reseted.
        _scheduledTasks.forEach((scheduledTask) => _rescheduleNotification(scheduledTask));

        _notificationService.handleAppLaunchNotification();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildList();
  }
  
  @override
  void deactivate() {
    _notificationService.removeHandler(handleNotificationClicked);
    _timer.cancel();
    super.deactivate();
  }

  void updateScheduledTask(ScheduledTask scheduledTask) {
    debugPrint("received scheduledTaskId:" + scheduledTask.id.toString());
    setState(() {
      final found = _scheduledTasks.firstWhereOrNull((element) => element.id == scheduledTask.id);
      debugPrint("found in list: " + found.toString());
      if (found != null) {
        var index = _scheduledTasks.indexOf(found);
        debugPrint("index in list: " + index.toString());
        if (index != -1) {
          _scheduledTasks.removeAt(index);
          _scheduledTasks.insert(index, scheduledTask);
          debugPrint("exchanged: " + scheduledTask.lastScheduledEventOn.toString());
          _scheduledTasks..sort();
        }
      }
    });
  }

  Widget _buildList() {
    return Padding(
        padding: EdgeInsets.all(8.0),
        child: ListView.builder(
            itemCount: _scheduledTasks.length,
            itemBuilder: (context, index) {
              var scheduledTask = _scheduledTasks[index];
              var taskGroup = findPredefinedTaskGroupById(scheduledTask.taskGroupId);
              return _buildRow(index, scheduledTask, taskGroup);
            }),
    );
  }

  handleNotificationClicked(String receiverKey, String id) {
    if (receiverKey == widget.getKey()) {
      setState(() {
        final clickedScheduledTask = _scheduledTasks.firstWhere((scheduledTask) => scheduledTask.id.toString() == id);
        _selectedTile = _scheduledTasks.indexOf(clickedScheduledTask);
      });
    }
  }

  Widget _buildRow(int index, ScheduledTask scheduledTask, TaskGroup taskGroup) {
    final expansionWidgets = _createExpansionWidgets(scheduledTask);
    return Padding(
        padding: EdgeInsets.all(4.0),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile( //better use ExpansionPanel?
            key: GlobalKey(),
            // this makes updating all tiles if state changed
            title: Text(kReleaseMode ? scheduledTask.title : "${scheduledTask.title} (id=${scheduledTask.id})"),
            subtitle: Column(
              children: [
                taskGroup.getTaskGroupRepresentation(useIconColor: true),
                Visibility(
                  visible: scheduledTask.active,
                  child: LinearProgressIndicator(
                    value: scheduledTask.isNextScheduleOverdue(true) ? null : scheduledTask.getNextRepetitionIndicatorValue(),
                    color: scheduledTask.isNextScheduleOverdue(false)
                        ? Colors.red[500]
                        : (scheduledTask.isNextScheduleReached()
                          ? Color(0xFF770C0C)
                          : null),
                    backgroundColor: scheduledTask.isNextScheduleOverdue(true) ? Colors.red[300] : null,
                  ),
                ),
              ],
            ),
            children: expansionWidgets,
            collapsedBackgroundColor: getTaskGroupColor(scheduledTask.taskGroupId, true),
            backgroundColor: getTaskGroupColor(scheduledTask.taskGroupId, false),
            initiallyExpanded: index == _selectedTile,
            onExpansionChanged: ((expanded) {
              setState(() {
                _selectedTile = expanded ? index : -1;
              });
            }),
          )
        ),
    );
  }

  List<Widget> _createExpansionWidgets(ScheduledTask scheduledTask) {
    var expansionWidgets = <Widget>[];

    if (scheduledTask.description != null && scheduledTask.description!.isNotEmpty) {
      expansionWidgets.add(Padding(
        padding: EdgeInsets.all(4.0),
        child: Text(scheduledTask.description!),
      ));
    }
    expansionWidgets.addAll([
      Padding(
        padding: EdgeInsets.all(4.0),
        child: Text(getDetailsMessage(scheduledTask)),
      ),
      Divider(),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Visibility(
            visible: scheduledTask.active,
            child: ButtonBar(
              alignment: MainAxisAlignment.start,
              buttonPadding: EdgeInsets.symmetric(horizontal: 0.0),
              children: [
                TextButton(
                  child: Icon(Icons.check),
                  onPressed: () async {
                    TaskEvent? newTaskEvent = await Navigator.push(context, MaterialPageRoute(builder: (context) {
                      final templateId = scheduledTask.templateId;
                      TaskGroup? taskGroup;
                      Template? template;
                      String title = scheduledTask.title;
                      if (templateId != null) {
                        if (templateId.isVariant) {
                          template = findPredefinedTaskTemplateVariantById(templateId.id);
                        }
                        else {
                          template = findPredefinedTaskTemplateById(templateId.id);
                        }
                      }
                      else {
                        taskGroup = findPredefinedTaskGroupById(
                            scheduledTask.taskGroupId);
                      }
                    //  scheduledTask.templateId
                      return TaskEventForm(
                          formTitle: "Create new event from schedule",
                          taskGroup: taskGroup,
                          template: template,
                          title: title);
                    }));

                    if (newTaskEvent != null) {
                      TaskEventRepository.insert(newTaskEvent).then((newTaskEvent) {
                        ScaffoldMessenger.of(super.context).showSnackBar(
                            SnackBar(content: Text('New task event with name \'${newTaskEvent.title}\' created')));
                        widget._pagesHolder.taskEventList?.addTaskEvent(newTaskEvent);

                        scheduledTask.executeSchedule(null);
                        ScheduledTaskRepository.update(scheduledTask).then((changedScheduledTask) {
                          _updateScheduledTask(scheduledTask, changedScheduledTask);
                        });

                        final scheduledTaskEvent = ScheduledTaskEvent.fromEvent(newTaskEvent, scheduledTask);
                        ScheduledTaskEventRepository.insert(scheduledTaskEvent);
                      });
                    }
                  },
                ),
                TextButton(
                  child: Icon(Icons.replay),
                  onPressed: () {
                    showConfirmationDialog(
                      context,
                      "Reset schedule",
                      "Are you sure to reset \'${scheduledTask.title}\' ? This will reset the progress to the beginning.",
                      okPressed: () {
                        scheduledTask.executeSchedule(null);
                        ScheduledTaskRepository.update(scheduledTask).then((changedScheduledTask) {
                          ScaffoldMessenger.of(super.context).showSnackBar(
                              SnackBar(content: Text('Schedule with name \'${changedScheduledTask.title}\' reset done')));
                          _updateScheduledTask(scheduledTask, changedScheduledTask);
                        });
                        Navigator.pop(context);// dismiss dialog, should be moved in Dialogs.dart somehow
                      },
                      cancelPressed: () =>
                          Navigator.pop(context), // dismiss dialog, should be moved in Dialogs.dart somehow
                    );
                  },
                ),
              ],
            ),
          ),
          TextButton(
            child: const Icon(Icons.checklist),
            onPressed: () {
              ScheduledTaskEventRepository
                  .getByScheduledTaskIdPaged(scheduledTask.id, ChronologicalPaging.start(100))
                  .then((scheduledTaskEvents) {
                    if (scheduledTaskEvents.isNotEmpty) {
                      final lastEvent = scheduledTaskEvents.last;
                      final receiverKey = widget._pagesHolder.taskEventList?.getKey();
                      PersonalTaskLoggerScaffoldState? root = context.findAncestorStateOfType();
                      if (receiverKey != null && root != null) {
                        root.sendEvent(receiverKey, lastEvent.taskEventId.toString());
                        widget._pagesHolder.taskEventList?.filterByTaskEventIds(
                            scheduledTaskEvents.map((e) => e.taskEventId));
                      }
                    }
                    else {
                      ScaffoldMessenger.of(super.context).showSnackBar(
                          SnackBar(content: Text('No events for that schedule found')));
                    }
              });
            },
          ),
          ButtonBar(
            alignment: MainAxisAlignment.end,
            buttonPadding: EdgeInsets.symmetric(horizontal: 0.0),
            children: [
              TextButton(
                onPressed: () async {
                  ScheduledTask? changedScheduledTask = await Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return ScheduledTaskForm(
                        formTitle: "Change scheduledTask \'${scheduledTask.title}\'",
                        scheduledTask: scheduledTask,
                        taskGroup: findPredefinedTaskGroupById(scheduledTask.taskGroupId),
                    );
                  }));

                  if (changedScheduledTask != null) {
                    ScheduledTaskRepository.update(changedScheduledTask).then((changedScheduledTask) {
                      ScaffoldMessenger.of(super.context).showSnackBar(
                          SnackBar(content: Text('Schedule with name \'${changedScheduledTask.title}\' updated')));
                      _updateScheduledTask(scheduledTask, changedScheduledTask);
                    });
                  }
                },
                child: const Icon(Icons.edit),
              ),
              TextButton(
                onPressed: () {
                  showConfirmationDialog(
                    context,
                    "Delete Schedule",
                    "Are you sure to delete \'${scheduledTask.title}\' ?",
                    okPressed: () {
                      ScheduledTaskRepository.delete(scheduledTask).then(
                            (_) {
                              ScheduledTaskEventRepository
                                  .getByScheduledTaskIdPaged(scheduledTask.id!, ChronologicalPaging.start(100))
                                  .then((scheduledTaskEvents) {
                                scheduledTaskEvents.forEach((scheduledTaskEvent) {
                                  ScheduledTaskEventRepository.delete(scheduledTaskEvent);
                                });
                              });

                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('Schedule \'${scheduledTask.title}\' deleted')));
                            _removeScheduledTask(scheduledTask);
                        },
                      );
                      Navigator.pop(context); // dismiss dialog, should be moved in Dialogs.dart somehow
                    },
                    cancelPressed: () =>
                        Navigator.pop(context), // dismiss dialog, should be moved in Dialogs.dart somehow
                  );
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


  String getDetailsMessage(ScheduledTask scheduledTask) {
    var debug = kReleaseMode ? "" : "last:${scheduledTask.lastScheduledEventOn}, next:${scheduledTask.getNextSchedule()}, ratio: ${scheduledTask.getNextRepetitionIndicatorValue()}\n";
    final nextSchedule = scheduledTask.getNextSchedule()!;

    if (scheduledTask.active && scheduledTask.lastScheduledEventOn != null) {
      var msg = "";
      if (scheduledTask.isNextScheduleOverdue(false)) {
        msg = debug +
            "Overdue ${formatToDateOrWord(
            scheduledTask.getNextSchedule()!, true).toLowerCase()} "
            "for ${formatDuration(scheduledTask.getMissingDuration()!, true)} !";
      }
      else if (truncToSeconds(nextSchedule) == truncToSeconds(DateTime.now())) {
        msg = debug +
            "Due now!";
      }
      else {
        msg = debug +
            "Due ${formatToDateOrWord(nextSchedule, true)
                .toLowerCase()} "
                "in ${formatDuration(scheduledTask.getMissingDuration()!)} "
                "${scheduledTask.schedule.toStartAtAsString().toLowerCase()}";
      }

      return "$msg"
          "\n\n"
          "Scheduled from ${formatToDateOrWord(
          scheduledTask.lastScheduledEventOn!).toLowerCase()}";
    }
    else {
      return debug +
          "- currently inactive -";
    }
  }


  void _addScheduledTask(ScheduledTask scheduledTask) {
    setState(() {
      _scheduledTasks.add(scheduledTask);
      _scheduledTasks..sort();
      _selectedTile = _scheduledTasks.indexOf(scheduledTask);
      _rescheduleNotification(scheduledTask);

    });

  }

  void _updateScheduledTask(ScheduledTask origin, ScheduledTask updated) {
    setState(() {
      final index = _scheduledTasks.indexOf(origin);
      if (index != -1) {
        _scheduledTasks.removeAt(index);
        _scheduledTasks.insert(index, updated);
      }
      _scheduledTasks..sort();
      _selectedTile = _scheduledTasks.indexOf(updated);
      _rescheduleNotification(updated);

    });

  }

  void _removeScheduledTask(ScheduledTask scheduledTask) {
    setState(() {
      _scheduledTasks.remove(scheduledTask);
      _selectedTile = -1;
      _cancelNotification(scheduledTask);

    });

  }


  void _onFABPressed() {
    Object? selectedTemplateItem;

    showTemplateDialog(context, "Select a task to be scheduled",
        selectedItem: (selectedItem) {
          setState(() {
            selectedTemplateItem = selectedItem;
          });
        },
        okPressed: () async {
            if (selectedTemplateItem == null) {
              return;
            }
            Navigator.pop(context);
            ScheduledTask? newScheduledTask = await Navigator.push(context, MaterialPageRoute(builder: (context) {
              return ScheduledTaskForm(
                formTitle: "Create new schedule ",
                taskGroup: selectedTemplateItem is Template
                  ? findPredefinedTaskGroupById((selectedTemplateItem as Template).taskGroupId)
                  : selectedTemplateItem as TaskGroup,
                template: selectedTemplateItem is Template
                  ? selectedTemplateItem as Template
                  : null,
              );
            }));

            if (newScheduledTask != null) {
              ScheduledTaskRepository.insert(newScheduledTask).then((newScheduledTask) {
                ScaffoldMessenger.of(super.context).showSnackBar(
                    SnackBar(content: Text('New schedule with name \'${newScheduledTask.title}\' created')));
                _addScheduledTask(newScheduledTask);
              });
            }
        },
        cancelPressed: () {
          Navigator.pop(super.context);
        });

  }

  @override
  bool get wantKeepAlive => true;


  void _rescheduleNotification(ScheduledTask scheduledTask) {
    final missingDuration = scheduledTask.getMissingDuration();
    debugPrint("missing duration: $missingDuration");
    if (missingDuration != null && !missingDuration.isNegative) {
      _cancelNotification(scheduledTask);

      if (scheduledTask.active) {
        final taskGroup = findPredefinedTaskGroupById(
            scheduledTask.taskGroupId);
        _notificationService.scheduleNotifications(
            widget.getKey(),
            scheduledTask.id!,
            "Due scheduled task (${taskGroup.name})",
            "Scheduled task '${scheduledTask.title}' is due!",
            missingDuration,
            taskGroup.backgroundColor);
      }
    }
  }

  void _cancelNotification(ScheduledTask scheduledTask) {
    _notificationService.cancelNotifications(scheduledTask.id!);
  }


}


