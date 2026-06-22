import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';

class CreateRideScreen extends StatefulWidget {
  const CreateRideScreen({super.key});

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _startPointController = TextEditingController();
  final TextEditingController _tollsController = TextEditingController();
  final TextEditingController _returnController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedBriefingTime;
  TimeOfDay? _selectedDepartureTime;

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      child: ListView(
        children: [
          const TwoToneTitle(prefix: 'Novo', highlight: 'Role'),
          const SizedBox(height: AppGaps.section),
          const SectionLabel('Dados'),
          const SizedBox(height: AppGaps.sm),
          _SelectorField(
            label: 'Data',
            value: _formattedDate,
            icon: FontAwesomeIcons.calendar,
            onTap: _selectDate,
            isPlaceholder: _selectedDate == null,
          ),
          _TextInputField(
            label: 'Destino',
            hintText: AppStrings.selectPlaceholder,
            icon: FontAwesomeIcons.flagCheckered,
            controller: _destinationController,
          ),
          _TextInputField(
            label: 'Ponto de partida',
            hintText: AppStrings.selectPlaceholder,
            icon: FontAwesomeIcons.gasPump,
            controller: _startPointController,
          ),
          _SelectorField(
            label: 'Hora do briefing',
            value: _formatTime(_selectedBriefingTime),
            icon: FontAwesomeIcons.userGroup,
            onTap: _selectBriefingTime,
            isPlaceholder: _selectedBriefingTime == null,
          ),
          _SelectorField(
            label: 'Hora da saída',
            value: _formatTime(_selectedDepartureTime),
            icon: FontAwesomeIcons.clock,
            onTap: _selectDepartureTime,
            isPlaceholder: _selectedDepartureTime == null,
          ),
          _TextInputField(
            label: 'Pedágios',
            hintText: AppStrings.selectPlaceholder,
            icon: FontAwesomeIcons.moneyBill,
            controller: _tollsController,
          ),
          _TextInputField(
            label: 'Volta',
            hintText: AppStrings.selectPlaceholder,
            icon: FontAwesomeIcons.arrowRotateLeft,
            controller: _returnController,
          ),
          _SuggestedTitle(controller: _titleController),
          const SizedBox(height: AppGaps.lg),
          FilledButton(onPressed: _publish, child: const Text('Publicar role')),
          const SizedBox(height: AppGaps.bottom),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _startPointController.dispose();
    _tollsController.dispose();
    _returnController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  String get _formattedDate {
    final date = _selectedDate;
    if (date == null) return AppStrings.selectPlaceholder;

    final weekday = AppDateStrings.weekdays[date.weekday - 1];
    final month = AppDateStrings.months[date.month - 1];

    return '$weekday, ${date.day} de $month';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return AppStrings.selectPlaceholder;

    return '${AppDateStrings.twoDigits(time.hour)}:'
        '${AppDateStrings.twoDigits(time.minute)}';
  }

  Future<void> _selectDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 2)),
      helpText: 'Selecione a data',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (pickedDate == null || !mounted) return;

    setState(() => _selectedDate = pickedDate);
  }

  Future<void> _selectBriefingTime() => _pickTime(
    initial: _selectedBriefingTime ?? const TimeOfDay(hour: 9, minute: 0),
    helpText: 'Selecione a hora do briefing',
    onPicked: (time) => _selectedBriefingTime = time,
  );

  Future<void> _selectDepartureTime() => _pickTime(
    initial: _selectedDepartureTime ?? const TimeOfDay(hour: 9, minute: 30),
    helpText: 'Selecione a hora da saída',
    onPicked: (time) => _selectedDepartureTime = time,
  );

  Future<void> _pickTime({
    required TimeOfDay initial,
    required String helpText,
    required ValueChanged<TimeOfDay> onPicked,
  }) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: helpText,
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (pickedTime == null || !mounted) return;

    setState(() => onPicked(pickedTime));
  }

  void _publish() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Role mockado publicado para visualização.'),
      ),
    );
  }
}

class _SelectorField extends StatelessWidget {
  const _SelectorField({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
    this.isPlaceholder = false,
  });

  final String label;
  final String value;
  final FaIconData icon;
  final VoidCallback? onTap;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.paper2,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: ListTile(
        onTap: onTap,
        leading: FaIcon(icon, color: AppColors.orange),
        title: Text(
          label,
          style: const TextStyle(
            color: AppColors.asphalt,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            fontSize: 18,
            color: isPlaceholder ? AppColors.asphalt : AppColors.ink,
            fontWeight: isPlaceholder ? FontWeight.w800 : FontWeight.w900,
          ),
        ),
        trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 16),
      ),
    );
  }
}

class _TextInputField extends StatelessWidget {
  const _TextInputField({
    required this.label,
    required this.hintText,
    required this.icon,
    required this.controller,
  });

  final String label;
  final String hintText;
  final FaIconData icon;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.paper2,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 11),
            child: FaIcon(icon, color: AppColors.orange),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.asphalt,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextField(
                  controller: controller,
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(
                      fontSize: 18,
                      color: AppColors.asphalt,
                      fontWeight: FontWeight.w800,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.only(top: 4),
                    filled: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestedTitle extends StatelessWidget {
  const _SuggestedTitle({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Título sugerido'),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: 2,
            minLines: 1,
            style: Theme.of(context).textTheme.headlineMedium,
            decoration: InputDecoration(
              hintText: 'Digite o título do role',
              hintStyle: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: AppColors.asphalt),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              filled: false,
            ),
          ),
        ],
      ),
    );
  }
}
