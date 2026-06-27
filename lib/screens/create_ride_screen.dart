import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../auth/auth_scope.dart';
import '../models/place.dart';
import '../models/ride.dart';
import '../services/api_exception.dart';
import '../services/ride_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/place_search_field.dart';

class CreateRideScreen extends StatefulWidget {
  const CreateRideScreen({
    required this.isActive,
    required this.onSessionExpired,
    required this.onRidePublished,
    this.rideToEdit,
    super.key,
  });

  final bool isActive;
  final VoidCallback onSessionExpired;
  final VoidCallback onRidePublished;
  final Ride? rideToEdit;

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

/// Opens the create screen in edit mode for an existing ride. Returns true
/// when the ride was saved, so the caller can reload it.
extension EditRideNavigation on BuildContext {
  Future<bool?> editRide(Ride ride) {
    return Navigator.of(this).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => _EditRidePage(ride: ride)),
    );
  }
}

class _EditRidePage extends StatelessWidget {
  const _EditRidePage({required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CreateRideScreen(
        isActive: true,
        rideToEdit: ride,
        onSessionExpired: () => Navigator.pop(context),
        onRidePublished: () => Navigator.pop(context, true),
      ),
    );
  }
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final RideApiService _rideApiService = RideApiService();
  final TextEditingController _tollsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _whatsappGroupLinkController =
      TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedBriefingTime;
  TimeOfDay? _selectedDepartureTime;
  SelectedPlace? _destinationPlace;
  SelectedPlace? _startPlace;
  bool _publishing = false;

  bool get _isEditing => widget.rideToEdit != null;

  @override
  void initState() {
    super.initState();

    if (widget.rideToEdit != null) {
      _fillFieldsFrom(widget.rideToEdit!.editData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      child: ListView(
        children: [
          TwoToneTitle(
            prefix: _isEditing ? 'Editar' : 'Novo',
            highlight: 'Rolê',
          ),
          const SizedBox(height: AppGaps.section),
          const SectionLabel('Dados'),
          const SizedBox(height: AppGaps.xs),
          const Text(
            'Campos com * são obrigatórios',
            style: TextStyle(
              color: AppColors.orange,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppGaps.sm),
          _SelectorField(
            label: 'Data',
            value: _formattedDate,
            icon: FontAwesomeIcons.calendar,
            onTap: _selectDate,
            isPlaceholder: _selectedDate == null,
            isRequired: true,
          ),
          PlaceSearchField(
            label: 'Destino',
            hintText: AppStrings.selectPlaceholder,
            icon: FontAwesomeIcons.flagCheckered,
            rideApiService: _rideApiService,
            selectedPlace: _destinationPlace,
            onSelected: (place) => setState(() => _destinationPlace = place),
            isRequired: true,
          ),
          PlaceSearchField(
            label: 'Ponto de partida',
            hintText: AppStrings.selectPlaceholder,
            icon: FontAwesomeIcons.gasPump,
            rideApiService: _rideApiService,
            selectedPlace: _startPlace,
            onSelected: (place) => setState(() => _startPlace = place),
            isRequired: true,
          ),
          _SelectorField(
            label: 'Hora do briefing',
            value: _formatTime(_selectedBriefingTime),
            icon: FontAwesomeIcons.userGroup,
            onTap: _selectBriefingTime,
            isPlaceholder: _selectedBriefingTime == null,
            isRequired: true,
          ),
          _SelectorField(
            label: 'Hora da saída',
            value: _formatTime(_selectedDepartureTime),
            icon: FontAwesomeIcons.clock,
            onTap: _selectDepartureTime,
            isPlaceholder: _selectedDepartureTime == null,
            isRequired: true,
          ),
          _TextInputField(
            label: 'Pedágios (ida e volta)',
            hintText: 'R\$ 0,00',
            icon: FontAwesomeIcons.moneyBill,
            controller: _tollsController,
            keyboardType: TextInputType.number,
            inputFormatters: const [_BrazilianCurrencyInputFormatter()],
            isRequired: true,
          ),
          _TextInputField(
            label: 'Observações',
            hintText: 'Toque para digitar',
            icon: FontAwesomeIcons.noteSticky,
            controller: _notesController,
            keyboardType: TextInputType.multiline,
          ),
          _TextInputField(
            label: 'Link do grupo do WhatsApp (opcional)',
            hintText: 'https://chat.whatsapp.com/...',
            icon: FontAwesomeIcons.whatsapp,
            controller: _whatsappGroupLinkController,
            keyboardType: TextInputType.url,
          ),
          _TextInputField(
            label: 'Título',
            hintText: 'Toque para digitar',
            icon: FontAwesomeIcons.heading,
            controller: _titleController,
            isRequired: true,
          ),
          const SizedBox(height: AppGaps.lg),
          FilledButton(
            onPressed: _publishing ? null : _publish,
            child: _publishing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : Text(_isEditing ? 'Salvar alterações' : 'Publicar rolê'),
          ),
          const SizedBox(height: AppGaps.bottom),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(covariant CreateRideScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_isEditing && !oldWidget.isActive && widget.isActive) {
      _resetFields();
    }
  }

  @override
  void dispose() {
    _rideApiService.close();
    _tollsController.dispose();
    _notesController.dispose();
    _whatsappGroupLinkController.dispose();
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
    _notesController.clear();
    _whatsappGroupLinkController.clear();
    _titleController.clear();
  }

  void _fillFieldsFrom(RideEditData editData) {
    _selectedDate = DateTime.parse(editData.rideDate);
    _selectedBriefingTime = _parseTimeOfDay(editData.briefingTime);
    _selectedDepartureTime = _parseTimeOfDay(editData.departureTime);
    _startPlace = editData.startPlace;
    _destinationPlace = editData.destinationPlace;
    _titleController.text = editData.title;
    _notesController.text = editData.notes;
    _whatsappGroupLinkController.text = editData.whatsappGroupLink ?? '';

    if (editData.toll != null) {
      _tollsController.text = _formatTollForField(editData.toll!);
    }
  }

  TimeOfDay? _parseTimeOfDay(String? value) {
    if (value == null || value.length < 5) {
      return null;
    }

    final hour = int.tryParse(value.substring(0, 2));
    final minute = int.tryParse(value.substring(3, 5));
    if (hour == null || minute == null) {
      return null;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTollForField(double toll) {
    return _BrazilianCurrencyInputFormatter.format((toll * 100).round());
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
    initial: _selectedBriefingTime ?? const TimeOfDay(hour: 7, minute: 30),
    helpText: 'Selecione a hora do briefing',
    onPicked: (time) => _selectedBriefingTime = time,
  );

  Future<void> _selectDepartureTime() => _pickTime(
    initial: _selectedDepartureTime ?? const TimeOfDay(hour: 8, minute: 0),
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
      AppSnackBar.showError(context, validationMessage);
      return;
    }

    final toll = _parseToll();
    if (toll == null) {
      AppSnackBar.showError(context, 'Informe o pedágio como valor em reais.');
      return;
    }

    final auth = AuthScope.of(context);
    final authToken = auth.token;

    if (authToken == null || authToken.isEmpty) {
      AppSnackBar.showError(
        context,
        _isEditing
            ? 'Entre novamente para salvar o rolê.'
            : 'Entre novamente para publicar o rolê.',
      );
      widget.onSessionExpired();
      return;
    }

    setState(() => _publishing = true);

    try {
      await _saveRide(authToken: authToken, toll: toll);

      if (!mounted) {
        return;
      }

      setState(() {
        _publishing = false;
        if (!_isEditing) {
          _resetFields();
        }
      });
      AppSnackBar.showSuccess(
        context,
        _isEditing ? 'Rolê atualizado.' : 'Rolê publicado.',
      );
      widget.onRidePublished();
    } catch (exception) {
      if (!mounted) {
        return;
      }

      setState(() => _publishing = false);

      if (await auth.handleApiException(exception)) {
        widget.onSessionExpired();
        return;
      }

      if (!mounted) {
        return;
      }

      AppSnackBar.showError(
        context,
        _publishErrorMessage(exception),
        exception: exception,
      );
    }
  }

  Future<void> _saveRide({
    required String authToken,
    required double toll,
  }) async {
    final rideToEdit = widget.rideToEdit;

    if (rideToEdit != null) {
      await _rideApiService.updateRide(
        authToken: authToken,
        rideId: rideToEdit.id,
        title: _titleController.text.trim(),
        rideDate: _formatDateForApi(_selectedDate!),
        briefingTime: _formatTimeForApi(_selectedBriefingTime!),
        departureTime: _formatTimeForApi(_selectedDepartureTime!),
        startPlace: _startPlace!,
        destinationPlace: _destinationPlace!,
        toll: toll,
        notes: _notesController.text.trim(),
        whatsappGroupLink: _whatsappGroupLinkController.text.trim(),
      );
      return;
    }

    await _rideApiService.createRide(
      authToken: authToken,
      title: _titleController.text.trim(),
      rideDate: _formatDateForApi(_selectedDate!),
      briefingTime: _formatTimeForApi(_selectedBriefingTime!),
      departureTime: _formatTimeForApi(_selectedDepartureTime!),
      startPlace: _startPlace!,
      destinationPlace: _destinationPlace!,
      toll: toll,
      notes: _notesController.text.trim(),
      whatsappGroupLink: _whatsappGroupLinkController.text.trim(),
    );
  }

  String? _validationMessage() {
    final missingFields = <String>[
      if (_destinationPlace == null) 'destino',
      if (_startPlace == null) 'ponto de partida',
      if (_selectedDate == null) 'data',
      if (_selectedBriefingTime == null) 'hora do briefing',
      if (_selectedDepartureTime == null) 'hora da saída',
      if (_tollsController.text.trim().isEmpty) 'pedágio',
      if (_titleController.text.trim().isEmpty) 'título',
    ];

    if (missingFields.isEmpty) {
      return null;
    }

    return 'Preencha os campos obrigatórios: ${missingFields.join(', ')}.';
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
    final action = _isEditing ? 'salvar' : 'publicar';

    if (exception is ApiException) {
      return switch (exception.statusCode) {
        422 => 'Confira os dados do rolê antes de $action.',
        429 => 'Muitas tentativas. Aguarde um pouco e tente novamente.',
        502 => 'Não foi possível $action agora. Tente novamente em instantes.',
        _ => exception.message,
      };
    }

    return 'Não foi possível $action o rolê agora.';
  }
}

class _SelectorField extends StatelessWidget {
  const _SelectorField({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
    this.isPlaceholder = false,
    this.isRequired = false,
  });

  final String label;
  final String value;
  final FaIconData icon;
  final VoidCallback? onTap;
  final bool isPlaceholder;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: ListTile(
        onTap: onTap,
        leading: FaIcon(icon, color: AppColors.orange),
        title: FieldLabel(label, isRequired: isRequired),
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
    this.isRequired = false,
  });

  final String label;
  final String hintText;
  final FaIconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.paperSoft,
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
                FieldLabel(label, isRequired: isRequired),
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

    final text = format(int.parse(digits));

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// Formats a value in cents as "R$ x.yyy,zz".
  static String format(int centsValue) {
    final reais = centsValue ~/ 100;
    final cents = centsValue % 100;

    return 'R\$ ${_formatReais(reais)},${AppDateStrings.twoDigits(cents)}';
  }

  static String _formatReais(int value) {
    final characters = value.toString().split('').reversed.toList();
    final groups = <String>[];

    for (var index = 0; index < characters.length; index += 3) {
      final end = (index + 3).clamp(0, characters.length);
      groups.add(characters.sublist(index, end).reversed.join());
    }

    return groups.reversed.join('.');
  }
}
