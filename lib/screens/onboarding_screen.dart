import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../auth/auth_scope.dart';
import '../models/app_user.dart';
import '../services/api_exception.dart';
import '../services/ride_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/city_search_sheet.dart';
import '../widgets/motorcycle_dialog.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.onSessionExpired, super.key});

  final VoidCallback onSessionExpired;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final RideApiService _rideApiService = RideApiService();

  bool _saving = false;

  @override
  void dispose() {
    _rideApiService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context).user;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      body: ScreenFrame(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BrandMark(),
            const SizedBox(height: AppGaps.section),
            _Greeting(firstName: user.firstName),
            const SizedBox(height: AppGaps.section),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _ProfileRow(
                    icon: FontAwesomeIcons.motorcycle,
                    label: 'Minha moto',
                    value: user.hasMotorcycle ? user.motorcycle!.trim() : null,
                    placeholder: 'Qual moto você roda',
                    onTap: _saving ? null : () => _editMotorcycle(user),
                  ),
                  const SizedBox(height: AppGaps.sm),
                  _ProfileRow(
                    icon: FontAwesomeIcons.locationDot,
                    label: 'Cidade base',
                    value: user.hasCity ? user.cityAndState : null,
                    placeholder: 'De onde você costuma sair',
                    onTap: _saving ? null : _openCitySheet,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppGaps.md),
            _ContinueButton(
              hasMotorcycle: user.hasMotorcycle,
              hasCity: user.hasCity,
              isLoading: _saving,
              onPressed: _finish,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editMotorcycle(AppUser user) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => MotorcycleDialog(initialValue: user.motorcycle ?? ''),
    );

    if (result == null) {
      return;
    }

    final trimmed = result.trim();

    if (trimmed.isEmpty) {
      return;
    }

    await _saveProfile(updateMotorcycle: true, motorcycle: trimmed);
  }

  void _openCitySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CitySearchSheet(
        rideApiService: _rideApiService,
        title: 'Sua cidade base',
        onCitySelected: (city) => _saveProfile(cityId: city.id),
      ),
    );
  }

  Future<void> _saveProfile({
    bool updateMotorcycle = false,
    String? motorcycle,
    int? cityId,
  }) async {
    if (_saving) {
      return;
    }

    setState(() => _saving = true);

    final auth = AuthScope.of(context);

    try {
      await auth.updateProfile(
        updateMotorcycle: updateMotorcycle,
        motorcycle: motorcycle,
        cityId: cityId,
      );
    } catch (exception) {
      final loggedOut = await auth.handleApiException(exception);

      if (!mounted) {
        return;
      }

      if (loggedOut) {
        widget.onSessionExpired();
        return;
      }

      AppSnackBar.showError(
        context,
        _errorMessage(exception),
        exception: exception,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _errorMessage(Object exception) {
    if (exception is ApiException) {
      if (exception.statusCode == 422) {
        return 'Confira os dados antes de salvar.';
      }

      return exception.message;
    }

    return 'Não foi possível salvar agora.';
  }

  void _finish() {
    final user = AuthScope.of(context).user;

    if (user == null || !user.hasMotorcycle || !user.hasCity) {
      return;
    }

    Navigator.of(context).pop(true);
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Boas, $firstName.\n',
                style: const TextStyle(color: AppColors.ink),
              ),
              const TextSpan(
                text: 'Monta sua garagem.',
                style: TextStyle(color: AppColors.orange),
              ),
            ],
          ),
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: AppGaps.sm),
        Text(
          'Sua moto e sua cidade aparecem na lista do rolê e abrem o feed perto '
          'de você. Leva 10 segundos.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.asphalt),
        ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.placeholder,
    this.onTap,
  });

  final FaIconData icon;
  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;

    return _TappableCard(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.hairline),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Row(
            children: [
              FaIcon(icon, color: AppColors.orange, size: 18),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasValue ? value! : placeholder,
                      style: TextStyle(
                        color: hasValue
                            ? AppColors.inkMedium
                            : AppColors.asphalt,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _EditDot(done: hasValue),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditDot extends StatelessWidget {
  const _EditDot({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    return FaIcon(
      done ? FontAwesomeIcons.solidCircleCheck : FontAwesomeIcons.penToSquare,
      size: 16,
      color: done ? AppColors.green : AppColors.asphalt,
    );
  }
}

class _TappableCard extends StatelessWidget {
  const _TappableCard({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: child),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.hasMotorcycle,
    required this.hasCity,
    required this.isLoading,
    required this.onPressed,
  });

  final bool hasMotorcycle;
  final bool hasCity;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = hasMotorcycle && hasCity;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: enabled && !isLoading ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.paper,
          disabledBackgroundColor: AppColors.inkSoft,
          disabledForegroundColor: AppColors.asphalt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 3),
              )
            : Text(
                _label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: enabled ? AppColors.paper : AppColors.asphalt,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  String get _label {
    if (hasMotorcycle && hasCity) {
      return 'Bora rodar';
    }

    if (!hasMotorcycle && !hasCity) {
      return 'Falta moto e cidade';
    }

    return hasMotorcycle ? 'Falta a cidade' : 'Falta a moto';
  }
}
