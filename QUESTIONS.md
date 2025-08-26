# Questions and Ambiguities

This document lists questions, ambiguities, and decisions made during implementation where the specification was unclear or required interpretation.

## Implementation Decisions Made

### 1. Font Strategy
**Question**: Spec mentions "System/Inter typography" and later "Use system fonts initially (no downloads)". Should we use Inter or system fonts?

**Decision**: Started with system fonts as specified, but kept Inter configuration for future use. The pubspec.yaml was updated to remove Inter font assets and use system fonts initially.

**Rationale**: Follows the spec's explicit instruction to use system fonts initially and avoid manual font files.

### 2. Logo Generation
**Question**: How should the logo PNG be generated programmatically without external tools?

**Decision**: Created a placeholder approach with SVG definition and a Dart script for PNG generation. The actual PNG generation would require running the Flutter app or using external tools.

**Rationale**: Provides a foundation for logo generation while acknowledging the limitations of the current environment.

### 3. Category Storage
**Question**: Should categories be stored as separate entities or just as strings in expenses?

**Decision**: Created a separate Categories table with full entity management (favorites, usage tracking, etc.) while also storing category name as string in Expenses for query performance.

**Rationale**: Enables rich category features (favorites, usage stats, search) while maintaining query performance.

### 4. Member Management
**Question**: How should "current user" be handled in the member system?

**Decision**: Treat current user as a regular member with a special identifier. Mock data uses 'current_user' as placeholder.

**Rationale**: Simplifies the data model and allows for consistent handling of all participants.

### 5. Currency Handling
**Question**: Spec mentions "Currency (INR only)" but also shows multi-currency support in data model.

**Decision**: Implemented full Money class with multi-currency support but defaulted to INR and focused UI on INR formatting.

**Rationale**: Provides foundation for future expansion while meeting current INR-only requirement.

### 6. Date Storage
**Question**: Should dates be stored as DateTime or epoch days as shown in the spec?

**Decision**: Used epoch days (integer) for date fields as specified in the data model, with conversion utilities.

**Rationale**: Follows the exact specification and provides efficient storage and querying.

### 7. Responsive Breakpoints
**Question**: Spec mentions "compact <600dp, 600–840dp, ≥840dp" - what should the middle range be called?

**Decision**: Named them compact (<600dp), medium (600-840dp), and expanded (≥840dp).

**Rationale**: Follows Material Design naming conventions and provides clear semantic meaning.

## Outstanding Questions

### 1. Authentication & User Management
**Question**: How should user accounts and authentication be handled?

**Current State**: Mocked with placeholder user ID. No actual authentication system implemented.

**Needs Clarification**: 
- Should there be user registration/login?
- How are users identified across app reinstalls?
- Should there be any cloud sync for user identity?

### 2. Group Invitation & Management
**Question**: How do users join groups and invite others?

**Current State**: Groups and members are managed through mock data.

**Needs Clarification**:
- How are group invitations sent and received?
- What happens when someone leaves a group?
- How are group permissions managed?

### 3. Notification Permissions & Scheduling
**Question**: What specific reminder scenarios should be supported?

**Current State**: Basic reminder data model exists but no actual scheduling.

**Needs Clarification**:
- What triggers should create reminders?
- How should reminder frequency be determined?
- What actions should reminders support?

### 4. Backup Encryption Details
**Question**: What level of encryption is required for backups?

**Current State**: Basic encryption framework with AES-GCM mentioned.

**Needs Clarification**:
- Should backups be encrypted by default?
- What key derivation parameters should be used?
- How should encryption keys be managed?

### 5. Offline Sync Strategy
**Question**: If future cloud sync is added, how should conflicts be resolved?

**Current State**: Fully offline with no sync capability.

**Needs Clarification**:
- What data should sync vs. stay local?
- How should conflicting edits be handled?
- What's the sync frequency strategy?

## Technical TODOs

### High Priority
1. **Complete Split Share Input**: Exact and percentage split input forms need full implementation
2. **Real Database Integration**: Replace mock data with actual database queries
3. **Category Initialization**: Implement default category seeding on first app launch
4. **Form Validation**: Complete validation for all expense form fields
5. **Settlement Calculations**: Wire up settlement algorithm to actual group data

### Medium Priority
1. **Biometric Authentication**: Complete app lock implementation
2. **Backup/Restore Flow**: Implement full backup and restore with encryption
3. **Notification Scheduling**: Complete reminder system with actual notifications
4. **Analytics Queries**: Replace mock data with real database analytics
5. **Error Handling**: Comprehensive error handling and user feedback

### Low Priority
1. **Performance Optimization**: Database query optimization and caching
2. **Accessibility**: Complete accessibility support for all widgets
3. **Internationalization**: Support for multiple languages
4. **Advanced Analytics**: More sophisticated spending insights
5. **Export Formats**: Additional export formats beyond JSON/CSV

## Design Decisions Needing Review

### 1. Navigation Structure
**Current**: Standard bottom navigation with separate screens.

**Question**: Should analytics be a separate tab or integrated into group/home views?

### 2. Split Preview Location
**Current**: Split preview shown in right pane on tablets.

**Question**: Should preview be always visible or toggleable?

### 3. Category Creation Flow
**Current**: Inline creation from search with no match.

**Question**: Should there be a dedicated category management screen?

### 4. Settlement Suggestions
**Current**: Calculated and displayed as suggestions.

**Question**: Should settlements be automatically created or require user confirmation?

### 5. Individual Expense Grouping
**Current**: Individual expenses are not grouped.

**Question**: Should individual expenses have optional grouping for organization?

## Testing Gaps

### Unit Tests Needed
- [ ] Date utilities and epoch day conversion
- [ ] Currency conversion and formatting edge cases
- [ ] Complex settlement scenarios with multiple currencies
- [ ] Category search ranking algorithm validation
- [ ] Backup/restore data integrity verification

### Widget Tests Needed
- [ ] Responsive layout behavior at different screen sizes
- [ ] Form state preservation during navigation
- [ ] Error state handling in all forms
- [ ] Accessibility features and screen reader support
- [ ] Theme switching and color contrast validation

### Integration Tests Needed
- [ ] Complete expense creation flow (split and individual)
- [ ] Group creation and member management
- [ ] Settlement creation and tracking
- [ ] Backup creation and restore process
- [ ] App lock and biometric authentication

## Performance Considerations

### Database Queries
**Question**: What's the expected data scale for performance optimization?

**Assumptions Made**:
- Up to 1000 expenses per group
- Up to 50 groups per user
- Up to 100 categories total
- Analytics queries for up to 2 years of data

### Memory Usage
**Question**: Should there be limits on data loading or pagination?

**Current Approach**: Load all data for simplicity, but may need pagination for large datasets.

### Battery Usage
**Question**: How frequently should background tasks run?

**Current Approach**: Minimal background processing, user-triggered operations only.

## Security Questions

### Data Sensitivity
**Question**: What data should be considered sensitive and require encryption?

**Current Approach**: All backup data encrypted, local database unencrypted.

### Key Management
**Question**: How should encryption keys be generated and stored?

**Current Approach**: Platform keychain for key storage, PBKDF2 for key derivation.

### Audit Trail
**Question**: Should there be an audit log of sensitive operations?

**Current Approach**: Basic created/updated timestamps, no detailed audit trail.

---

## Resolution Process

When questions arise during development:

1. **Check Specification**: Review original requirements for guidance
2. **Consider User Experience**: Choose option that provides best UX
3. **Maintain Consistency**: Align with existing patterns in the app
4. **Document Decision**: Add to this file with rationale
5. **Implement Simply**: Choose simplest viable solution initially
6. **Plan for Evolution**: Ensure decision doesn't block future improvements

## Contact for Clarification

For questions requiring specification clarification:
- Review original requirements document
- Consider Material Design guidelines for UI/UX decisions
- Follow Flutter/Dart best practices for technical decisions
- Prioritize user privacy and data security
