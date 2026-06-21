import 'package:drift/drift.dart';

// Sync Queue Table - for managing data synchronization
@DataClassName('SyncQueueTableData')
class SyncQueueTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type =>
      text().withLength(min: 1, max: 50)(); // sms, call, location, etc.
  IntColumn get priority =>
      integer().withDefault(const Constant(2))(); // 0=urgent, 4=low
  BlobColumn get payload => blob()(); // compressed, encrypted data
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAttempt => dateTime().nullable()();
  TextColumn get status => text().withDefault(
      const Constant('pending'))(); // pending, processing, failed, completed
  TextColumn get batchId => text().nullable()();
  IntColumn get payloadSize => integer().withDefault(const Constant(0))();
}

// Collection ownership lease - coordinates main/background isolates.
@DataClassName('CollectionLeaseTableData')
class CollectionLeaseTable extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get owner => text().withLength(min: 1, max: 64)();
  IntColumn get acquiredAtMs => integer()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// SMS Data Table
@DataClassName('SmsDataTableData')
class SmsDataTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get deviceId => text().withLength(min: 1, max: 255)();
  TextColumn get messageType =>
      text().withLength(min: 1, max: 10)(); // SMS, MMS
  TextColumn get direction =>
      text().withLength(min: 1, max: 10)(); // INCOMING, OUTGOING
  TextColumn get sender => text().withLength(min: 1, max: 50)();
  TextColumn get senderName => text().nullable()();
  TextColumn get body => text()();
  DateTimeColumn get sentAt => dateTime()();
  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get conversationId => text().nullable()();
  BoolColumn get hasAttachment =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  TextColumn get hash => text().unique()(); // for deduplication
}

// Call Data Table
@DataClassName('CallDataTableData')
class CallDataTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get deviceId => text().withLength(min: 1, max: 255)();
  TextColumn get callType =>
      text().withLength(min: 1, max: 10)(); // INCOMING, OUTGOING, MISSED
  TextColumn get phoneNumber => text().withLength(min: 1, max: 50)();
  TextColumn get contactName => text().nullable()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get duration =>
      integer().withDefault(const Constant(0))(); // in seconds
  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isVideoCall => boolean().withDefault(const Constant(false))();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  TextColumn get hash => text().unique()(); // for deduplication
  IntColumn get simSlot => integer().nullable()();
  BoolColumn get isConference => boolean().withDefault(const Constant(false))();
}

// Location Data Table
@DataClassName('LocationDataTableData')
class LocationDataTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get deviceId => text().withLength(min: 1, max: 255)();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get accuracy => real()();
  RealColumn get altitude => real().nullable()();
  RealColumn get speed => real().nullable()();
  RealColumn get bearing => real().nullable()();
  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get provider =>
      text().withLength(min: 1, max: 20)(); // GPS, NETWORK, PASSIVE
  TextColumn get activityType =>
      text().nullable()(); // STILL, WALKING, DRIVING, etc.
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  IntColumn get batteryLevel => integer().nullable()();
}

// App Usage Data Table
@DataClassName('AppUsageDataTableData')
class AppUsageDataTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get deviceId => text().withLength(min: 1, max: 255)();
  TextColumn get packageName => text().withLength(min: 1, max: 255)();
  TextColumn get appName => text().withLength(min: 1, max: 255)();
  TextColumn get category => text().nullable()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  IntColumn get launchCount => integer().withDefault(const Constant(1))();
  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  TextColumn get date => text().withLength(min: 10, max: 10)(); // YYYY-MM-DD
}

// App Data Table (for installed apps)
@DataClassName('AppDataTableData')
class AppDataTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get deviceId => text().withLength(min: 1, max: 255)();
  TextColumn get packageName => text().withLength(min: 1, max: 255)();
  TextColumn get appName => text().withLength(min: 1, max: 255)();
  TextColumn get versionName => text().nullable()();
  IntColumn get versionCode => integer().nullable()();
  DateTimeColumn get firstInstallTime => dateTime()();
  DateTimeColumn get lastUpdateTime => dateTime().nullable()();
  TextColumn get appCategory => text().nullable()();
  BoolColumn get isSystemApp => boolean().withDefault(const Constant(false))();
  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
}

// Media Data Table
@DataClassName('MediaDataTableData')
class MediaDataTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get deviceId => text().withLength(min: 1, max: 255)();
  TextColumn get mediaId => text().withLength(min: 1, max: 255)();
  TextColumn get mediaType =>
      text().withLength(min: 1, max: 20)(); // PHOTO, VIDEO, AUDIO, SCREENSHOT
  TextColumn get fileName => text().withLength(min: 1, max: 255)();
  TextColumn get filePath => text()();
  TextColumn get mimeType => text().withLength(min: 1, max: 100)();
  IntColumn get fileSize => integer()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();
  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  TextColumn get captureMethod =>
      text().nullable()(); // manual, automatic, remote
  TextColumn get cameraType => text().nullable()(); // FRONT, BACK
  IntColumn get duration =>
      integer().nullable()(); // milliseconds for audio/video
  BlobColumn get thumbnail => blob().nullable()();
}

// Configuration Table
@DataClassName('ConfigurationTableData')
class ConfigurationTable extends Table {
  TextColumn get key => text().withLength(min: 1, max: 100)();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}

// Security Audit Table
@DataClassName('SecurityAuditTableData')
class SecurityAuditTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get eventType => text().withLength(
      min: 1, max: 50)(); // LOGIN, PERMISSION_CHANGE, ROOT_DETECTED, etc.
  TextColumn get description => text()();
  TextColumn get severity =>
      text().withLength(min: 1, max: 10)(); // LOW, MEDIUM, HIGH, CRITICAL
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  TextColumn get deviceId => text().withLength(min: 1, max: 255)();
  TextColumn get metadata => text().nullable()(); // JSON metadata
  TextColumn get hash => text()(); // for integrity verification
}

// Emergency Events Table
@DataClassName('EmergencyEventsTableData')
class EmergencyEventsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get emergencyId => text().withLength(min: 1, max: 255)();
  TextColumn get triggerType => text()
      .withLength(min: 1, max: 20)(); // manual, automatic, panic, external
  DateTimeColumn get activatedAt => dateTime()();
  DateTimeColumn get deactivatedAt => dateTime().nullable()();
  TextColumn get deviceId => text().withLength(min: 1, max: 255)();
  TextColumn get triggerData =>
      text()(); // JSON data about what triggered the emergency
  TextColumn get actionsPerformed => text()(); // JSON array of actions taken
  TextColumn get metadata =>
      text()(); // JSON metadata (device info, app version, etc.)
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
}
