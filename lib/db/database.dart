import 'dart:async';
import 'package:floor/floor.dart';
import 'package:personaltasklogger/db/dao/SequencesDao.dart';
import 'package:personaltasklogger/db/dao/TaskEventDao.dart';
import 'package:personaltasklogger/db/entity/SequencesEntity.dart';
import 'package:personaltasklogger/db/entity/TaskEventEntity.dart';
import 'package:personaltasklogger/db/entity/TaskTemplateEntity.dart';
import 'package:personaltasklogger/db/entity/TaskTemplateVariantEntity.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'dao/ScheduledTaskDao.dart';
import 'dao/ScheduledTaskEventDao.dart';
import 'dao/TaskTemplateDao.dart';
import 'dao/TaskTemplateVariantDao.dart';
import 'entity/ScheduledTaskEntity.dart';
import 'entity/ScheduledTaskEventEntity.dart';

part 'database.g.dart'; // the generated code will be there

@Database(version: 10, entities: [
  TaskEventEntity, TaskTemplateEntity, TaskTemplateVariantEntity, ScheduledTaskEntity, ScheduledTaskEventEntity, SequencesEntity])
abstract class AppDatabase extends FloorDatabase {
  TaskEventDao get taskEventDao;
  TaskTemplateDao get taskTemplateDao;
  TaskTemplateVariantDao get taskTemplateVariantDao;
  ScheduledTaskDao get scheduledTaskDao;
  ScheduledTaskEventDao get scheduledTaskEventDao;
  SequencesDao get sequencesDao;
}

final migration2To3 = new Migration(2, 3,
        (sqflite.Database database) async {
          await database.execute("ALTER TABLE TaskEventEntity ADD COLUMN originTaskTemplateId INTEGER");
          await database.execute("ALTER TABLE TaskEventEntity ADD COLUMN originTaskTemplateVariantId INTEGER");
        });

final migration3To4 = new Migration(3, 4,
        (sqflite.Database database) async {
          await database.execute(
              'CREATE TABLE `TaskTemplateEntity` (`id` INTEGER, `taskGroupId` INTEGER NOT NULL, `title` TEXT NOT NULL, `description` TEXT, `startedAt` INTEGER, `aroundStartedAt` INTEGER, `duration` INTEGER, `aroundDuration` INTEGER, `severity` INTEGER, `favorite` INTEGER NOT NULL, PRIMARY KEY (`id`))');
          await database.execute(
              'CREATE TABLE `TaskTemplateVariantEntity` (`id` INTEGER, `taskGroupId` INTEGER NOT NULL, `taskTemplateId` INTEGER NOT NULL, `title` TEXT NOT NULL, `description` TEXT, `startedAt` INTEGER, `aroundStartedAt` INTEGER, `duration` INTEGER, `aroundDuration` INTEGER, `severity` INTEGER, `favorite` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        });

final migration4To5 = new Migration(4, 5,
        (sqflite.Database database) async {
      await database.execute("ALTER TABLE TaskTemplateEntity ADD COLUMN `hidden` INTEGER");
      await database.execute("ALTER TABLE TaskTemplateVariantEntity ADD COLUMN `hidden` INTEGER");
    });

final migration5To6 = new Migration(5, 6,
        (sqflite.Database database) async {
      await database.execute('CREATE TABLE `SequencesEntity` (`id` INTEGER, `table` TEXT NOT NULL, `lastId` INTEGER NOT NULL, PRIMARY KEY (`id`))');
      await database.execute("INSERT INTO `SequencesEntity` (`table`, `lastId`) VALUES ('TaskTemplateEntity', 1000)");
      await database.execute("INSERT INTO `SequencesEntity` (`table`, `lastId`) VALUES ('TaskTemplateVariantEntity', 1000)");
    });

final migration6To7 = new Migration(6, 7,
        (sqflite.Database database) async {
          await database.execute("ALTER TABLE ScheduledTaskEntity ADD COLUMN `pausedAt` INTEGER");
        });

final migration7To8 = new Migration(7, 8,
        (sqflite.Database database) async {
          await database.execute("CREATE INDEX IF NOT EXISTS idx_ScheduledTaskEventEntity_taskEventId ON ScheduledTaskEventEntity (taskEventId)");
          await database.execute("CREATE INDEX IF NOT EXISTS idx_ScheduledTaskEventEntity_scheduledTaskId ON ScheduledTaskEventEntity (scheduledTaskId)");

          await database.execute("CREATE INDEX IF NOT EXISTS idx_TaskEventEntity_taskGroupId ON TaskEventEntity (taskGroupId)");
          await database.execute("CREATE INDEX IF NOT EXISTS idx_TaskEventEntity_originTaskTemplateId ON TaskEventEntity (originTaskTemplateId)");
          await database.execute("CREATE INDEX IF NOT EXISTS idx_TaskEventEntity_originTaskTemplateVariantId ON TaskEventEntity (originTaskTemplateVariantId)");
        });

final migration8To9 = new Migration(8, 9,
        (sqflite.Database database) async {
      await database.execute("ALTER TABLE ScheduledTaskEntity ADD COLUMN `repetitionMode` INTEGER");
    });

final migration9To10 = new Migration(9, 10,
        (sqflite.Database database) async {
      await database.execute("ALTER TABLE TaskEventEntity ADD COLUMN trackingFinishedAt INTEGER");
    });


Future<AppDatabase> getDb([String? name]) async => $FloorAppDatabase
    .databaseBuilder(name??'app_database.db')
    .addMigrations([migration2To3, migration3To4, migration4To5, migration5To6, migration6To7, migration7To8, migration8To9, migration9To10])
    .build();
