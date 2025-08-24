import 'package:drift/drift.dart';

/// Members table - stores individual contacts/participants
class Members extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text()();
  TextColumn get avatarEmoji => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Groups table - stores expense groups
class Groups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Group members table - many-to-many relationship between groups and members
class GroupMembers extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text().references(Groups, #id, onDelete: KeyAction.cascade)();
  TextColumn get memberId => text().references(Members, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get joinDate => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
  
  @override
  List<Set<Column>> get uniqueKeys => [
    {groupId, memberId}, // Prevent duplicate group memberships
  ];
}

/// Expenses table - stores both split and individual expenses
class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text().nullable().references(Groups, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()(); // 'SPLIT' | 'INDIVIDUAL'
  TextColumn get description => text()();
  IntColumn get amountMinor => integer()(); // Amount in paise
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  TextColumn get payerMemberId => text().references(Members, #id)();
  IntColumn get dateEpochDays => integer()(); // Days since epoch for efficient date queries
  TextColumn get notes => text().nullable()();
  TextColumn get category => text()();
  DateTimeColumn get createdAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Split shares table - stores individual shares for split expenses
class SplitShares extends Table {
  TextColumn get id => text()();
  TextColumn get expenseId => text().references(Expenses, #id, onDelete: KeyAction.cascade)();
  TextColumn get memberId => text().references(Members, #id)();
  IntColumn get shareMinor => integer()(); // Share amount in paise
  
  @override
  Set<Column> get primaryKey => {id};
  
  @override
  List<Set<Column>> get uniqueKeys => [
    {expenseId, memberId}, // One share per member per expense
  ];
}

/// Settlements table - stores payments made to settle debts
class Settlements extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text().references(Groups, #id, onDelete: KeyAction.cascade)();
  TextColumn get fromMemberId => text().references(Members, #id)();
  TextColumn get toMemberId => text().references(Members, #id)();
  IntColumn get amountMinor => integer()(); // Settlement amount in paise
  DateTimeColumn get createdAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Reminders table - stores reminder schedules
class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get scope => text()(); // 'GROUP' | 'MEMBER'
  TextColumn get scopeId => text()(); // groupId or memberId
  TextColumn get rrule => text()(); // Simple RRULE-like string
  DateTimeColumn get nextRunAt => dateTime()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// App settings table - stores user preferences and app state
class AppSettings extends Table {
  TextColumn get id => text().withDefault(const Constant('singleton'))();
  TextColumn get theme => text().withDefault(const Constant('system'))(); // 'light' | 'dark' | 'system'
  TextColumn get lastDefaultTab => text().withDefault(const Constant('home'))();
  TextColumn get lastUsedExpenseTypePerGroup => text().withDefault(const Constant('{}'))(); // JSON map
  BoolColumn get pinEnabled => boolean().withDefault(const Constant(false))();
  BoolColumn get biometricEnabled => boolean().withDefault(const Constant(true))();
  TextColumn get defaultCurrency => text().withDefault(const Constant('INR'))();
  BoolColumn get notificationsEnabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastBackupAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Backup records table - tracks backup history
class BackupRecords extends Table {
  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get path => text()();
  TextColumn get format => text()(); // 'JSON' | 'CSV'
  BoolColumn get encrypted => boolean().withDefault(const Constant(false))();
  IntColumn get sizeBytes => integer().nullable()();
  TextColumn get checksum => text().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Categories table - stores expense categories with usage tracking
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get emoji => text().nullable()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  IntColumn get usageCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastUsedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
  
  @override
  List<Set<Column>> get uniqueKeys => [
    {name}, // Category names must be unique
  ];
}

/// Member interactions table - tracks recent interactions for fuzzy search
class MemberInteractions extends Table {
  TextColumn get id => text()();
  TextColumn get memberId => text().references(Members, #id, onDelete: KeyAction.cascade)();
  TextColumn get interactionType => text()(); // 'EXPENSE_PAYER' | 'EXPENSE_PARTICIPANT' | 'SETTLEMENT'
  DateTimeColumn get interactionAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Expense type enumeration for type safety
enum ExpenseType {
  split('SPLIT'),
  individual('INDIVIDUAL');

  const ExpenseType(this.value);
  final String value;

  static ExpenseType fromString(String value) {
    return ExpenseType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ExpenseType.split,
    );
  }
}

/// Reminder scope enumeration
enum ReminderScope {
  group('GROUP'),
  member('MEMBER');

  const ReminderScope(this.value);
  final String value;

  static ReminderScope fromString(String value) {
    return ReminderScope.values.firstWhere(
      (scope) => scope.value == value,
      orElse: () => ReminderScope.group,
    );
  }
}

/// Theme mode enumeration
enum ThemeMode {
  light('light'),
  dark('dark'),
  system('system');

  const ThemeMode(this.value);
  final String value;

  static ThemeMode fromString(String value) {
    return ThemeMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => ThemeMode.system,
    );
  }
}

/// Backup format enumeration
enum BackupFormat {
  json('JSON'),
  csv('CSV');

  const BackupFormat(this.value);
  final String value;

  static BackupFormat fromString(String value) {
    return BackupFormat.values.firstWhere(
      (format) => format.value == value,
      orElse: () => BackupFormat.json,
    );
  }
}

/// Member interaction type enumeration
enum MemberInteractionType {
  expensePayer('EXPENSE_PAYER'),
  expenseParticipant('EXPENSE_PARTICIPANT'),
  settlement('SETTLEMENT');

  const MemberInteractionType(this.value);
  final String value;

  static MemberInteractionType fromString(String value) {
    return MemberInteractionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MemberInteractionType.expensePayer,
    );
  }
}
