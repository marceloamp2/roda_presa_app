import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../auth/auth_scope.dart';
import '../models/app_user.dart';
import '../models/city.dart';
import '../services/api_exception.dart';
import '../services/ride_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/city_search_sheet.dart';
import '../widgets/motorcycle_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.onLoggedOut, super.key});

  final VoidCallback onLoggedOut;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

enum _ProfileSaveTarget { motorcycle, city }

class _ProfileScreenState extends State<ProfileScreen> {
  final RideApiService _rideApiService = RideApiService();

  bool _loggingOut = false;
  _ProfileSaveTarget? _savingProfileTarget;

  @override
  void dispose() {
    _rideApiService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context).user;
    final actionsEnabled = !_loggingOut && _savingProfileTarget == null;

    return ScreenFrame(
      child: ListView(
        children: [
          const TwoToneTitle(prefix: 'Meu', highlight: 'Perfil'),
          const SizedBox(height: AppGaps.md),
          if (user == null)
            const _MissingUserState()
          else ...[
            _ProfileHeader(
              user: user,
              isLoggingOut: _loggingOut,
              onLogout: _logout,
            ),
            const SizedBox(height: AppGaps.section),
            const SectionLabel('Conta'),
            const SizedBox(height: AppGaps.xs),
            _MenuItem(
              title: 'Minha moto',
              value: user.motorcycle ?? 'Não informado',
              icon: FontAwesomeIcons.motorcycle,
              isLoading: _savingProfileTarget == _ProfileSaveTarget.motorcycle,
              onTap: actionsEnabled ? () => _editMotorcycle(user) : null,
            ),
            _MenuItem(
              title: 'Cidade',
              value: user.cityAndState,
              icon: FontAwesomeIcons.locationDot,
              isLoading: _savingProfileTarget == _ProfileSaveTarget.city,
              onTap: actionsEnabled ? _openCitySheet : null,
            ),
          ],
          const SizedBox(height: AppGaps.bottom),
        ],
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

    await _saveProfile(
      target: _ProfileSaveTarget.motorcycle,
      updateMotorcycle: true,
      motorcycle: trimmed.isEmpty ? null : trimmed,
      successMessage: 'Moto atualizada.',
    );
  }

  void _openCitySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CitySearchSheet(
        rideApiService: _rideApiService,
        title: 'Cidade',
        onCitySelected: _saveCity,
      ),
    );
  }

  void _saveCity(City city) {
    _saveProfile(
      target: _ProfileSaveTarget.city,
      cityId: city.id,
      successMessage: 'Cidade atualizada.',
    );
  }

  Future<void> _saveProfile({
    required _ProfileSaveTarget target,
    bool updateMotorcycle = false,
    String? motorcycle,
    int? cityId,
    required String successMessage,
  }) async {
    if (_savingProfileTarget != null) {
      return;
    }

    setState(() => _savingProfileTarget = target);

    final auth = AuthScope.of(context);

    try {
      await auth.updateProfile(
        updateMotorcycle: updateMotorcycle,
        motorcycle: motorcycle,
        cityId: cityId,
      );

      if (!mounted) {
        return;
      }

      AppSnackBar.showSuccess(context, successMessage);
    } catch (exception) {
      final loggedOut = await auth.handleApiException(exception);

      if (!mounted) {
        return;
      }

      if (loggedOut) {
        widget.onLoggedOut();
        return;
      }

      AppSnackBar.showError(
        context,
        _profileErrorMessage(exception),
        exception: exception,
      );
    } finally {
      if (mounted) {
        setState(() => _savingProfileTarget = null);
      }
    }
  }

  String _profileErrorMessage(Object exception) {
    if (exception is ApiException) {
      if (exception.statusCode == 422) {
        return 'Confira os dados do perfil.';
      }

      return exception.message;
    }

    return 'Não foi possível atualizar seu perfil agora.';
  }

  Future<void> _logout() async {
    if (_loggingOut) {
      return;
    }

    setState(() => _loggingOut = true);

    await AuthScope.of(context).logout();

    if (!mounted) {
      return;
    }

    setState(() => _loggingOut = false);
    widget.onLoggedOut();
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.isLoggingOut,
    required this.onLogout,
  });

  final AppUser user;
  final bool isLoggingOut;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileAvatar(user: user),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                user.email,
                style: const TextStyle(color: AppColors.asphalt),
              ),
              const SizedBox(height: 12),
              Pill(
                color: AppColors.ink,
                foreground: AppColors.paper,
                child: Text(user.motorcycle ?? 'Moto não informada'),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: isLoggingOut ? null : onLogout,
          child: isLoggingOut
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('sair'),
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final photoUrl = user.photoUrl;

    if (photoUrl == null) {
      return InitialsAvatar(user.initials, size: 72);
    }

    return CircleAvatar(
      radius: 36,
      backgroundColor: AppColors.ink,
      backgroundImage: NetworkImage(photoUrl),
    );
  }
}

class _MissingUserState extends StatelessWidget {
  const _MissingUserState();

  @override
  Widget build(BuildContext context) {
    return const CardFrame(child: Text('Entre novamente para ver seu perfil.'));
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.title,
    required this.value,
    required this.icon,
    this.onTap,
    this.isLoading = false,
  });

  final String title;
  final String value;
  final FaIconData icon;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: ListTile(
        onTap: onTap,
        enabled: onTap != null,
        leading: FaIcon(icon, color: AppColors.orange),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(value),
        trailing: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const FaIcon(
                FontAwesomeIcons.penToSquare,
                size: 16,
                color: AppColors.asphalt,
              ),
      ),
    );
  }
}
