import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/place.dart';
import '../services/ride_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/place_search_field.dart';

class CreateRideScreen extends StatefulWidget {
  const CreateRideScreen({required this.isActive, super.key});

  final bool isActive;

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final RideApiService _rideApiService = RideApiService();
  final TextEditingController _tollsController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedBriefingTime;
  TimeOfDay? _selectedDepartureTime;
  SelectedPlace? _destinationPlace;
  SelectedPlace? _startPlace;
  bool _publishing = false;

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
          PlaceSearchField(
            label: 'Destino',
            hintText: AppStrings.selectPlaceholder,
            icon: FontAwesomeIcons.flagCheckered,
            rideApiService: _rideApiService,
            selectedPlace: _destinationPlace,
            onSelected: (place) => setState(() => _destinationPlace = place),
          ),
          PlaceSearchField(
            label: 'Ponto de partida',
            hintText: AppStrings.selectPlaceholder,
            icon: FontAwesomeIcons.gasPump,
            rideApiService: _rideApiService,
            selectedPlace: _startPlace,
            onSelected: (place) => setState(() => _startPlace = place),
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
            label: 'Pedágios (ida e volta)',
            hintText: 'R\$ 0,00',
            icon: FontAwesomeIcons.moneyBill,
            controller: _tollsController,
            keyboardType: TextInputType.number,
            inputFormatters: const [_BrazilianCurrencyInputFormatter()],
          ),
          _SuggestedTitle(controller: _titleController),
          const SizedBox(height: AppGaps.lg),
          FilledButton(
            onPressed: _publishing ? null : _publish,
            child: _publishing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : const Text('Publicar role'),
          ),
          const SizedBox(height: AppGaps.bottom),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(covariant CreateRideScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.isActive && widget.isActive) {
      _resetFields();
    }
  }

  @override
  void dispose() {
    _rideApiService.close();
    _tollsController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _resetFields() {
    _selectedDate = null;
    _selectedBriefingTime = null;
    _selectedDepartureTime = null;
    _destinationPlace = null;
    _startPlace = null;
    _tollsController.clear();
    _titleController.clear();
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

  Future<void> _publish() async {
    final validationMessage = _validationMessage();
    if (validationMessage != null) {
      _showMessage(validationMessage);
      return;
    }

    final toll = _parseToll();
    if (toll == null && _tollsController.text.trim().isNotEmpty) {
      _showMessage('Informe o pedágio como valor em reais.');
      return;
    }

    setState(() => _publishing = true);

    try {
      await _rideApiService.createRide(
        title: _titleController.text.trim(),
        rideDate: _formatDateForApi(_selectedDate!),
        briefingTime: _selectedBriefingTime == null
            ? null
            : _formatTimeForApi(_selectedBriefingTime!),
        departureTime: _formatTimeForApi(_selectedDepartureTime!),
        startPlace: _startPlace!,
        destinationPlace: _destinationPlace!,
        toll: toll,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _publishing = false;
        _resetFields();
      });
      _showMessage('Role publicado.');
    } catch (exception) {
      if (!mounted) {
        return;
      }

      setState(() => _publishing = false);
      _showMessage(_publishErrorMessage(exception));
    }
  }

  String? _validationMessage() {
    if (_destinationPlace == null) {
      return 'Selecione o destino na lista.';
    }

    if (_startPlace == null) {
      return 'Selecione o ponto de partida na lista.';
    }

    if (_selectedDate == null) {
      return 'Selecione a data do role.';
    }

    if (_selectedDepartureTime == null) {
      return 'Selecione a hora da saída.';
    }

    if (_titleController.text.trim().isEmpty) {
      return 'Digite o título do role.';
    }

    return null;
  }

  double? _parseToll() {
    final value = _tollsController.text.trim();
    if (value.isEmpty) {
      return null;
    }

    var cleanValue = value.replaceAll(RegExp(r'[^0-9,.]'), '');
    if (cleanValue.contains(',')) {
      cleanValue = cleanValue.replaceAll('.', '').replaceAll(',', '.');
    }

    final parsed = double.tryParse(cleanValue);
    if (parsed == null || parsed < 0) {
      return null;
    }

    return parsed;
  }

  String _formatDateForApi(DateTime date) {
    return '${date.year}-'
        '${AppDateStrings.twoDigits(date.month)}-'
        '${AppDateStrings.twoDigits(date.day)}';
  }

  String _formatTimeForApi(TimeOfDay time) {
    return '${AppDateStrings.twoDigits(time.hour)}:'
        '${AppDateStrings.twoDigits(time.minute)}';
  }

  String _publishErrorMessage(Object exception) {
    if (exception is RideApiException) {
      return switch (exception.statusCode) {
        422 => 'Confira os dados do role antes de publicar.',
        429 => 'Muitas tentativas. Aguarde um pouco e tente novamente.',
        502 => 'Não foi possível publicar agora. Tente novamente em instantes.',
        _ => exception.message,
      };
    }

    return 'Não foi possível publicar o role agora.';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
    this.keyboardType,
    this.inputFormatters,
  });

  final String label;
  final String hintText;
  final FaIconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

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
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
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

class _BrazilianCurrencyInputFormatter extends TextInputFormatter {
  const _BrazilianCurrencyInputFormatter();

  static final RegExp _nonDigits = RegExp(r'\D');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(_nonDigits, '');
    if (digits.isEmpty) {
      return const TextEditingValue();
    }

    final centsValue = int.parse(digits);
    final reais = centsValue ~/ 100;
    final cents = centsValue % 100;
    final text = 'R\$ ${_formatReais(reais)},${AppDateStrings.twoDigits(cents)}';

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  String _formatReais(int value) {
    final characters = value.toString().split('').reversed.toList();
    final groups = <String>[];

    for (var index = 0; index < characters.length; index += 3) {
      final end = (index + 3).clamp(0, characters.length);
      groups.add(characters.sublist(index, end).reversed.join());
    }

    return groups.reversed.join('.');
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
