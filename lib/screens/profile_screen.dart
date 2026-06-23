import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      child: ListView(
        children: const [
          TwoToneTitle(prefix: 'Meu', highlight: 'Perfil'),
          SizedBox(height: AppGaps.md),
          _ProfileHeader(),
          SizedBox(height: AppGaps.lg),
          _StatsRow(),
          SizedBox(height: AppGaps.section),
          SectionLabel('Conta'),
          SizedBox(height: AppGaps.xs),
          _MenuItem(
            title: 'Minha moto',
            value: 'Mirage 250',
            icon: FontAwesomeIcons.motorcycle,
          ),
          _MenuItem(
            title: 'Cidade base',
            value: 'Ribeirão Preto, SP',
            icon: FontAwesomeIcons.locationDot,
          ),
          _MenuItem(
            title: 'Notificações',
            value: 'Roles novos perto · ligado',
            icon: FontAwesomeIcons.bell,
          ),
          _MenuItem(
            title: 'Privacidade',
            value: 'Perfil visível na lista',
            icon: FontAwesomeIcons.lock,
          ),
          SizedBox(height: AppGaps.bottom),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InitialsAvatar('MA', size: 72),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Marcelo',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              const Text(
                'marceloamp2@gmail.com',
                style: TextStyle(color: AppColors.asphalt),
              ),
              const SizedBox(height: 12),
              const Pill(
                color: AppColors.ink,
                foreground: AppColors.paper,
                child: Text('Mirage 250'),
              ),
            ],
          ),
        ),
        TextButton(onPressed: null, child: Text('sair')),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return const CardFrame(
      child: Row(
        children: [
          Expanded(
            child: _Stat(number: '23', label: 'roles feitos'),
          ),
          Expanded(
            child: _Stat(number: '7', label: 'organizados'),
          ),
          Expanded(
            child: _Stat(number: '2', label: 'próximos'),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(fontSize: 30, height: 0.95),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.asphalt, fontSize: 12),
        ),
      ],
    );
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
        trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 16),
      ),
    );
  }
}
