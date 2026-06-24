import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../auth/auth_scope.dart';
import '../models/app_user.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.onLoggedOut, super.key});

  final VoidCallback onLoggedOut;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loggingOut = false;

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context).user;

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
            ),
            _MenuItem(
              title: 'Cidade base',
              value: user.cityAndState,
              icon: FontAwesomeIcons.locationDot,
            ),
          ],
          const SizedBox(height: AppGaps.bottom),
        ],
      ),
    );
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
  });

  final String title;
  final String value;
  final FaIconData icon;

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
        leading: FaIcon(icon, color: AppColors.orange),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(value),
      ),
    );
  }
}
