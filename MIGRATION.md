# Database Migration Guide

## Current Schema Version: 1

The application uses Drift (SQLite) for local data storage. This document outlines the database schema and any migration procedures needed.

## Schema Overview

### Tables

#### Members
- `id` (TEXT, PRIMARY KEY): Unique member identifier
- `displayName` (TEXT, NOT NULL): Member's display name
- `avatarEmoji` (TEXT, NULLABLE): Optional emoji avatar
- `createdAt` (DATETIME, NOT NULL): Creation timestamp

#### Groups
- `id` (TEXT, PRIMARY KEY): Unique group identifier
- `name` (TEXT, NOT NULL): Group name
- `archived` (BOOLEAN, NOT NULL, DEFAULT FALSE): Archive status
- `createdAt` (DATETIME, NOT NULL): Creation timestamp

#### GroupMembers
- `id` (TEXT, PRIMARY KEY): Unique relationship identifier
- `groupId` (TEXT, NOT NULL): Foreign key to Groups
- `memberId` (TEXT, NOT NULL): Foreign key to Members
- `joinDate` (DATETIME, NOT NULL): When member joined group

#### Categories
- `id` (TEXT, PRIMARY KEY): Unique category identifier
- `name` (TEXT, NOT NULL): Category name
- `emoji` (TEXT, NULLABLE): Optional emoji icon
- `isDefault` (BOOLEAN, NOT NULL, DEFAULT FALSE): System default category
- `isFavorite` (BOOLEAN, NOT NULL, DEFAULT FALSE): User favorite status
- `usageCount` (INTEGER, NOT NULL, DEFAULT 0): Usage frequency counter
- `lastUsedAt` (DATETIME, NULLABLE): Last usage timestamp
- `createdAt` (DATETIME, NOT NULL): Creation timestamp

#### Expenses
- `id` (TEXT, PRIMARY KEY): Unique expense identifier
- `groupId` (TEXT, NULLABLE): Foreign key to Groups (null for individual expenses)
- `type` (TEXT, NOT NULL): 'SPLIT' or 'INDIVIDUAL'
- `description` (TEXT, NOT NULL): Expense description
- `amountMinor` (INTEGER, NOT NULL): Amount in paise (smallest currency unit)
- `currency` (TEXT, NOT NULL, DEFAULT 'INR'): Currency code
- `payerMemberId` (TEXT, NOT NULL): Foreign key to Members (who paid)
- `dateEpochDays` (INTEGER, NOT NULL): Date as days since epoch
- `notes` (TEXT, NULLABLE): Optional notes
- `category` (TEXT, NOT NULL): Category name
- `createdAt` (DATETIME, NOT NULL): Creation timestamp

#### SplitShares
- `id` (TEXT, PRIMARY KEY): Unique share identifier
- `expenseId` (TEXT, NOT NULL): Foreign key to Expenses
- `memberId` (TEXT, NOT NULL): Foreign key to Members
- `shareMinor` (INTEGER, NOT NULL): Share amount in paise

#### Settlements
- `id` (TEXT, PRIMARY KEY): Unique settlement identifier
- `groupId` (TEXT, NOT NULL): Foreign key to Groups
- `fromMemberId` (TEXT, NOT NULL): Foreign key to Members (payer)
- `toMemberId` (TEXT, NOT NULL): Foreign key to Members (recipient)
- `amountMinor` (INTEGER, NOT NULL): Settlement amount in paise
- `createdAt` (DATETIME, NOT NULL): Creation timestamp

#### Reminders
- `id` (TEXT, PRIMARY KEY): Unique reminder identifier
- `scope` (TEXT, NOT NULL): 'GROUP' or 'MEMBER'
- `scopeId` (TEXT, NOT NULL): ID of group or member
- `rrule` (TEXT, NOT NULL): Recurrence rule (RFC 5545)
- `nextRunAt` (DATETIME, NOT NULL): Next execution time
- `enabled` (BOOLEAN, NOT NULL, DEFAULT TRUE): Active status

#### AppSettings
- `id` (TEXT, PRIMARY KEY, DEFAULT 'singleton'): Single row identifier
- `theme` (TEXT, NOT NULL, DEFAULT 'system'): Theme preference
- `lastDefaultTab` (TEXT, NOT NULL, DEFAULT 'home'): Last active tab
- `lastUsedExpenseTypePerGroup` (TEXT, NOT NULL, DEFAULT '{}'): JSON preferences
- `pinEnabled` (BOOLEAN, NOT NULL, DEFAULT FALSE): PIN lock status
- `biometricEnabled` (BOOLEAN, NOT NULL, DEFAULT FALSE): Biometric lock status

#### BackupRecords
- `id` (TEXT, PRIMARY KEY): Unique backup identifier
- `createdAt` (DATETIME, NOT NULL): Backup creation time
- `path` (TEXT, NOT NULL): Backup file path
- `format` (TEXT, NOT NULL): 'JSON' or 'CSV'
- `encrypted` (BOOLEAN, NOT NULL, DEFAULT FALSE): Encryption status

## Initial Data Setup

### Default Categories
The application initializes with these default categories:
- Food 🍽️
- Transport 🚕
- Groceries 🛒
- Utilities 💡
- Shopping 🛍️
- Entertainment 🎬
- Health 🏥
- Education 🎓
- Bills 🧾
- Misc 🏷️

### Default Settings
- Theme: System (follows device theme)
- PIN/Biometric: Disabled
- Default tab: Home
- Currency: INR

## Migration Procedures

### Version 1 → Version 2 (Future)
When schema changes are needed:

1. **Update Schema Version**
   ```dart
   @override
   int get schemaVersion => 2;
   ```

2. **Add Migration Logic**
   ```dart
   @override
   MigrationStrategy get migration => MigrationStrategy(
     onUpgrade: (migrator, from, to) async {
       if (from == 1) {
         // Add migration steps here
         // Example: await migrator.addColumn(expenses, expenses.newColumn);
       }
     },
   );
   ```

3. **Data Preservation Steps**
   - Backup existing data before migration
   - Test migration with sample data
   - Provide rollback mechanism if needed

## Data Integrity

### Foreign Key Constraints
- All foreign keys are enforced
- Cascade deletes where appropriate
- Orphaned record cleanup procedures

### Validation Rules
- Amount values must be non-negative
- Currency codes must be valid ISO codes
- Date values must be reasonable (not in far future)
- Member names must be non-empty

### Indexes
Performance-critical queries have indexes on:
- `Expenses.groupId`
- `Expenses.payerMemberId`
- `Expenses.dateEpochDays`
- `SplitShares.expenseId`
- `SplitShares.memberId`
- `Categories.name`
- `Categories.lastUsedAt`

## Backup and Restore

### Export Format (JSON)
```json
{
  "version": 1,
  "exportedAt": "2024-01-01T00:00:00Z",
  "data": {
    "members": [...],
    "groups": [...],
    "expenses": [...],
    "splitShares": [...],
    "settlements": [...],
    "categories": [...],
    "settings": {...}
  }
}
```

### Import Process
1. Validate export format and version
2. Check for data conflicts
3. Show preview of changes
4. Create backup of current data
5. Apply import with transaction safety
6. Verify data integrity

### Encryption
- AES-GCM encryption for sensitive exports
- PBKDF2 key derivation from user password
- Integrity verification with HMAC

## Troubleshooting

### Common Issues

1. **Migration Failures**
   - Check available storage space
   - Verify database file permissions
   - Review migration logs

2. **Data Corruption**
   - Use SQLite integrity check: `PRAGMA integrity_check`
   - Restore from backup if available
   - Rebuild indexes if needed

3. **Performance Issues**
   - Analyze query execution plans
   - Check index usage
   - Consider data archiving for old records

### Recovery Procedures

1. **Database Corruption**
   ```sql
   -- Check integrity
   PRAGMA integrity_check;
   
   -- Rebuild if needed
   VACUUM;
   REINDEX;
   ```

2. **Missing Data**
   - Check backup records
   - Verify foreign key relationships
   - Restore from most recent backup

## Development Notes

### Adding New Tables
1. Define table in `tables.dart`
2. Add to database class
3. Create DAO if needed
4. Update schema version
5. Add migration logic
6. Update backup/restore logic

### Modifying Existing Tables
1. Never drop columns in production
2. Add new columns as nullable
3. Provide default values
4. Update related DAOs
5. Test migration thoroughly

### Performance Considerations
- Use batch operations for bulk inserts
- Implement pagination for large datasets
- Consider archiving old data
- Monitor query performance in production
