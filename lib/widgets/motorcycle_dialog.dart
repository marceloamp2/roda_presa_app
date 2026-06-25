import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MotorcycleDialog extends StatefulWidget {
  const MotorcycleDialog({required this.initialValue, super.key});

  final String initialValue;

  @override
  State<MotorcycleDialog> createState() => _MotorcycleDialogState();
}

class _MotorcycleDialogState extends State<MotorcycleDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: const Text('Minha moto'),
      content: SizedBox(
        width: double.maxFinite,
        child: TextField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            fillColor: AppColors.modalField,
            hintText: 'Ex.: Yamaha MT-07',
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Salvar')),
      ],
    );
  }

  void _submit() {
    Navigator.pop(context, _controller.text);
  }
}
