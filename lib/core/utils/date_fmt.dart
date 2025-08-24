import 'package:intl/intl.dart';

/// Date formatting utilities for the app
class DateFormatter {
  DateFormatter._();

  // Date formatters for Indian locale
  static final _shortDateFormat = DateFormat('dd/MM/yyyy', 'en_IN');
  static final _mediumDateFormat = DateFormat('dd MMM yyyy', 'en_IN');
  static final _longDateFormat = DateFormat('dd MMMM yyyy', 'en_IN');
  static final _timeFormat = DateFormat('hh:mm a', 'en_IN');
  static final _dateTimeFormat = DateFormat('dd/MM/yyyy hh:mm a', 'en_IN');
  static final _monthYearFormat = DateFormat('MMM yyyy', 'en_IN');
  static final _dayMonthFormat = DateFormat('dd MMM', 'en_IN');
  static final _weekdayFormat = DateFormat('EEEE', 'en_IN');
  static final _monthFormat = DateFormat('MMMM', 'en_IN');
  static final _yearFormat = DateFormat('yyyy', 'en_IN');

  /// Format date as short format (dd/MM/yyyy)
  static String shortDate(DateTime date) => _shortDateFormat.format(date);

  /// Format date as medium format (dd MMM yyyy)
  static String mediumDate(DateTime date) => _mediumDateFormat.format(date);

  /// Format date as long format (dd MMMM yyyy)
  static String longDate(DateTime date) => _longDateFormat.format(date);

  /// Format time (hh:mm a)
  static String time(DateTime date) => _timeFormat.format(date);

  /// Format date and time (dd/MM/yyyy hh:mm a)
  static String dateTime(DateTime date) => _dateTimeFormat.format(date);

  /// Format as month and year (MMM yyyy)
  static String monthYear(DateTime date) => _monthYearFormat.format(date);

  /// Format as day and month (dd MMM)
  static String dayMonth(DateTime date) => _dayMonthFormat.format(date);

  /// Format as weekday name (Monday, Tuesday, etc.)
  static String weekday(DateTime date) => _weekdayFormat.format(date);

  /// Format as month name (January, February, etc.)
  static String month(DateTime date) => _monthFormat.format(date);

  /// Format as year (yyyy)
  static String year(DateTime date) => _yearFormat.format(date);

  /// Format date relative to today (Today, Yesterday, Tomorrow, or date)
  static String relative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    final difference = dateOnly.difference(today).inDays;
    
    return switch (difference) {
      0 => 'Today',
      1 => 'Tomorrow',
      -1 => 'Yesterday',
      _ when difference > 1 && difference <= 7 => weekday(date),
      _ when difference < -1 && difference >= -7 => weekday(date),
      _ => mediumDate(date),
    };
  }

  /// Format date with relative context and time
  static String relativeWithTime(DateTime date) {
    final relativeDate = relative(date);
    if (relativeDate == 'Today' || relativeDate == 'Yesterday' || relativeDate == 'Tomorrow') {
      return '$relativeDate at ${time(date)}';
    }
    return '${mediumDate(date)} at ${time(date)}';
  }

  /// Format duration ago (2 hours ago, 3 days ago, etc.)
  static String ago(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      final days = difference.inDays;
      return days == 1 ? '1 day ago' : '$days days ago';
    } else if (difference.inHours > 0) {
      final hours = difference.inHours;
      return hours == 1 ? '1 hour ago' : '$hours hours ago';
    } else if (difference.inMinutes > 0) {
      final minutes = difference.inMinutes;
      return minutes == 1 ? '1 minute ago' : '$minutes minutes ago';
    } else {
      return 'Just now';
    }
  }

  /// Format date range (1 Jan - 31 Jan 2024)
  static String dateRange(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month) {
      // Same month
      return '${start.day} - ${end.day} ${monthYear(start)}';
    } else if (start.year == end.year) {
      // Same year, different months
      return '${dayMonth(start)} - ${dayMonth(end)} ${year(start)}';
    } else {
      // Different years
      return '${mediumDate(start)} - ${mediumDate(end)}';
    }
  }

  /// Format month range for analytics (Jan 2024 - Jun 2024)
  static String monthRange(DateTime start, DateTime end) {
    if (start.year == end.year) {
      if (start.month == end.month) {
        return monthYear(start);
      } else {
        return '${month(start)} - ${monthYear(end)}';
      }
    } else {
      return '${monthYear(start)} - ${monthYear(end)}';
    }
  }

  /// Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get end of month
  static DateTime endOfMonth(DateTime date) {
    final nextMonth = date.month == 12 
        ? DateTime(date.year + 1, 1, 1)
        : DateTime(date.year, date.month + 1, 1);
    return nextMonth.subtract(const Duration(milliseconds: 1));
  }

  /// Get start of year
  static DateTime startOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }

  /// Get end of year
  static DateTime endOfYear(DateTime date) {
    return DateTime(date.year, 12, 31, 23, 59, 59, 999);
  }

  /// Get start of week (Monday)
  static DateTime startOfWeek(DateTime date) {
    final weekday = date.weekday;
    return startOfDay(date.subtract(Duration(days: weekday - 1)));
  }

  /// Get end of week (Sunday)
  static DateTime endOfWeek(DateTime date) {
    final weekday = date.weekday;
    return endOfDay(date.add(Duration(days: 7 - weekday)));
  }

  /// Check if two dates are on the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  /// Check if date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return isSameDay(date, tomorrow);
  }

  /// Check if date is in current week
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startWeek = startOfWeek(now);
    final endWeek = endOfWeek(now);
    return date.isAfter(startWeek.subtract(const Duration(milliseconds: 1))) &&
           date.isBefore(endWeek.add(const Duration(milliseconds: 1)));
  }

  /// Check if date is in current month
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Check if date is in current year
  static bool isThisYear(DateTime date) {
    return date.year == DateTime.now().year;
  }

  /// Get days between two dates
  static int daysBetween(DateTime start, DateTime end) {
    final startDate = startOfDay(start);
    final endDate = startOfDay(end);
    return endDate.difference(startDate).inDays;
  }

  /// Get months between two dates
  static int monthsBetween(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + (end.month - start.month);
  }

  /// Parse date from string (dd/MM/yyyy format)
  static DateTime? parseShortDate(String dateString) {
    try {
      return _shortDateFormat.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Parse date from string (dd MMM yyyy format)
  static DateTime? parseMediumDate(String dateString) {
    try {
      return _mediumDateFormat.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Get financial year start date (April 1st)
  static DateTime getFinancialYearStart(DateTime date) {
    final year = date.month >= 4 ? date.year : date.year - 1;
    return DateTime(year, 4, 1);
  }

  /// Get financial year end date (March 31st)
  static DateTime getFinancialYearEnd(DateTime date) {
    final year = date.month >= 4 ? date.year + 1 : date.year;
    return DateTime(year, 3, 31, 23, 59, 59, 999);
  }

  /// Format financial year (FY 2023-24)
  static String financialYear(DateTime date) {
    final startYear = date.month >= 4 ? date.year : date.year - 1;
    final endYear = startYear + 1;
    return 'FY ${startYear.toString().substring(2)}-${endYear.toString().substring(2)}';
  }
}

/// Extension methods for DateTime
extension DateTimeExtension on DateTime {
  /// Format as short date
  String get shortDate => DateFormatter.shortDate(this);

  /// Format as medium date
  String get mediumDate => DateFormatter.mediumDate(this);

  /// Format as long date
  String get longDate => DateFormatter.longDate(this);

  /// Format as time
  String get time => DateFormatter.time(this);

  /// Format as date and time
  String get dateTime => DateFormatter.dateTime(this);

  /// Format as relative date
  String get relative => DateFormatter.relative(this);

  /// Format as relative date with time
  String get relativeWithTime => DateFormatter.relativeWithTime(this);

  /// Format as time ago
  String get ago => DateFormatter.ago(this);

  /// Get start of day
  DateTime get startOfDay => DateFormatter.startOfDay(this);

  /// Get end of day
  DateTime get endOfDay => DateFormatter.endOfDay(this);

  /// Get start of month
  DateTime get startOfMonth => DateFormatter.startOfMonth(this);

  /// Get end of month
  DateTime get endOfMonth => DateFormatter.endOfMonth(this);

  /// Check if is today
  bool get isToday => DateFormatter.isToday(this);

  /// Check if is yesterday
  bool get isYesterday => DateFormatter.isYesterday(this);

  /// Check if is tomorrow
  bool get isTomorrow => DateFormatter.isTomorrow(this);

  /// Check if is this week
  bool get isThisWeek => DateFormatter.isThisWeek(this);

  /// Check if is this month
  bool get isThisMonth => DateFormatter.isThisMonth(this);

  /// Check if is this year
  bool get isThisYear => DateFormatter.isThisYear(this);
}
