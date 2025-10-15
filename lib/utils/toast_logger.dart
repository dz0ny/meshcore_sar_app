import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/messages_provider.dart';

/// Toast logger utility - replaces SnackBar with system messages in the channels tab
class ToastLogger {
  /// Log an info message
  static void info(BuildContext context, String message) {
    _log(context, message, 'info');
  }

  /// Log a success message
  static void success(BuildContext context, String message) {
    _log(context, message, 'success');
  }

  /// Log a warning message
  static void warning(BuildContext context, String message) {
    _log(context, message, 'warning');
  }

  /// Log an error message
  static void error(BuildContext context, String message) {
    _log(context, message, 'error');
  }

  /// Internal method to log a system message
  static void _log(BuildContext context, String message, String level) {
    try {
      final messagesProvider = context.read<MessagesProvider>();
      messagesProvider.logSystemMessage(text: message, level: level);
    } catch (e) {
      // Fallback to print if provider is not available
      debugPrint('[$level] $message');
    }
  }
}
