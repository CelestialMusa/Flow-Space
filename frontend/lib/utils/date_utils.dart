import 'package:intl/intl.dart';

class DateUtils {
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '\\${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '\\${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '\\${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }

  static String formatTime(DateTime dateTime) {
    // Convert to South African Standard Time (UTC+2)
    final sast = dateTime.toUtc().add(const Duration(hours: 2));
    return DateFormat('HH:mm').format(sast);
  }

  static String formatDate(DateTime dateTime) {
    return DateFormat('MMM d, y').format(dateTime);
  }

  static String formatDateTime(DateTime dateTime) {
    // Convert to South African Standard Time (UTC+2)
    final sast = dateTime.toUtc().add(const Duration(hours: 2));
    return DateFormat('MMM d, y • HH:mm').format(sast);
  }

  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  static bool isYesterday(DateTime dateTime) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day;
  }
}