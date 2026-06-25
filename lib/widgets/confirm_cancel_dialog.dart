import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

Future<bool> showCancelRideDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Cancelar este rolê?'),
        content: const Text(
          'Ele será marcado como cancelado para todos os confirmados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Cancelar rolê'),
          ),
        ],
      );
    },
  );

  return confirmed ?? false;
}
