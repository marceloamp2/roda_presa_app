import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../services/api_exception.dart';
import '../theme/app_theme.dart';

class AppSnackBar {
  const AppSnackBar._();

  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message: message,
      background: AppColors.green,
      icon: FontAwesomeIcons.circleCheck,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    Object? exception,
  }) {
    _show(
      context,
      message: message,
      details: exception == null
          ? const []
          : ApiException.fieldErrorsOf(exception),
      background: AppColors.red,
      icon: FontAwesomeIcons.circleExclamation,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color background,
    required FaIconData icon,
    List<String> details = const [],
  }) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FaIcon(icon, size: 18, color: AppColors.paper),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
                      style: const TextStyle(
                        color: AppColors.paper,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    for (final detail in details)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '• $detail',
                          style: const TextStyle(
                            color: AppColors.paper,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: background,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
          elevation: 0,
        ),
      );
  }
}
