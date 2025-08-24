# PaisaSplit

An offline-first shared expense app that doubles as a personal financial journal, built with Flutter and Drift for reliable offline functionality.

## Features

### Core Features
- **Offline-First**: Works completely offline with local SQLite database
- **Shared Expenses**: Split bills with friends and family
- **Personal Journal**: Track individual expenses and spending patterns
- **Smart Settlements**: Optimized debt settlement calculations
- **Multi-Currency**: Support for different currencies (default: INR)
- **Categories**: Organize expenses by customizable categories

### Security & Privacy
- **App Lock**: PIN and biometric authentication
- **Data Encryption**: Secure local data storage
- **No Cloud Dependency**: All data stays on your device
- **Backup/Restore**: Export and import your data securely

### Analytics & Insights
- **Spending Analytics**: Detailed spending breakdowns by category
- **Trends**: Visual spending trends over time
- **Group Balances**: Real-time balance calculations
- **Settlement Optimization**: Minimize number of transactions needed

## Architecture

### Tech Stack
- **Flutter**: Cross-platform mobile framework
- **Drift**: Type-safe SQL database for Flutter
- **Riverpod**: State management and dependency injection
- **Go Router**: Declarative routing
- **Material 3**: Modern UI design system

### Project Structure
```
lib/
├── app/                    # App-level configuration
│   ├── router.dart        # Navigation configuration
│   ├── app.dart          # Main app widget
│   └── theme/            # Theme and design tokens
├── core/                  # Core utilities and services
│   ├── money/            # Money handling and formatting
│   ├── security/         # Authentication and encryption
│   ├── notifications/    # Reminder scheduling
│   └── utils/            # Common utilities
├── data/                  # Data layer
│   ├── db/drift/         # Database schema and DAOs
│   └── repos/            # Repository pattern implementations
├── features/             # Feature modules
│   ├── home/             # Home screen and overview
│   ├── group/            # Group management
│   ├── new_expense/      # Expense creation/editing
│   ├── analytics/        # Spending analytics
│   ├── settle_up/        # Settlement management
│   └── settings/         # App settings
└── widgets/              # Reusable UI components
```

### Database Schema
The app uses a normalized SQLite database with the following main entities:
- **Members**: Individual users/contacts
- **Groups**: Expense sharing groups
- **Expenses**: Individual expense records
- **SplitShares**: How expenses are split among members
- **Settlements**: Payment records between members
- **Reminders**: Scheduled notifications
- **AppSettings**: App configuration

## Getting Started

### Prerequisites
- Flutter SDK (>=3.13.0)
- Dart SDK (>=3.1.0)
- Android Studio / VS Code with Flutter extensions
- Android device/emulator or iOS device/simulator

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd paisa_split
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Code Generation

This project uses code generation for:
- **Drift**: Database code generation
- **Riverpod**: Provider code generation

Run code generation when you modify:
- Database tables or DAOs
- Riverpod providers with annotations

```bash
# One-time generation
flutter packages pub run build_runner build

# Watch for changes (development)
flutter packages pub run build_runner watch
```

## Development

### Adding New Features

1. **Create feature module** in `lib/features/`
2. **Add database entities** if needed in `lib/data/db/drift/`
3. **Create repositories** in `lib/data/repos/`
4. **Add providers** for state management
5. **Create UI screens** and widgets
6. **Add navigation routes** in `lib/app/router.dart`

### Database Migrations

When modifying database schema:
1. Update table definitions in `lib/data/db/drift/tables.dart`
2. Increment `schemaVersion` in `AppDatabase`
3. Add migration logic in `onUpgrade` method
4. Run code generation: `flutter packages pub run build_runner build`

### Testing

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter drive --target=test_driver/app.dart
```

### Building for Release

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

## Key Components

### Money Handling
The app uses a custom `Money` class for precise currency calculations:
- Stores amounts in smallest currency unit (paise for INR)
- Provides formatting and arithmetic operations
- Prevents floating-point precision issues

### Offline-First Architecture
- All data stored locally in SQLite database
- No network dependencies for core functionality
- Optional backup/restore for data portability
- Optimistic UI updates with local state management

### Security Features
- PIN and biometric authentication
- Secure storage for sensitive data
- Data encryption for backups
- Auto-lock functionality

### Settlement Algorithm
Smart debt settlement optimization:
- Minimizes number of transactions
- Handles complex multi-party settlements
- Supports partial payments
- Maintains transaction history

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style
- Follow Dart/Flutter style guidelines
- Use meaningful variable and function names
- Add documentation for public APIs
- Write tests for new features

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Flutter team for the amazing framework
- Drift team for the excellent database solution
- Riverpod team for clean state management
- Material Design team for the design system

## Roadmap

### Version 1.1
- [ ] Export to CSV/PDF
- [ ] Recurring expenses
- [ ] Expense templates
- [ ] Advanced filtering

### Version 1.2
- [ ] Multi-language support
- [ ] Custom categories
- [ ] Expense photos
- [ ] Advanced analytics

### Version 2.0
- [ ] Optional cloud sync
- [ ] Collaborative features
- [ ] Receipt scanning
- [ ] Budget tracking

## Support

For support, please open an issue on GitHub or contact the development team.

---

**PaisaSplit** - Making expense sharing simple and secure! 💰✨
