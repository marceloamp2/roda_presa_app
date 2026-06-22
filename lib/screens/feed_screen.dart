import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/ride_card.dart';
import 'ride_detail_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({
    required this.exploringAway,
    required this.radiusKm,
    required this.onRadiusChanged,
    required this.onLocationChanged,
    super.key,
  });

  final bool exploringAway;
  final double radiusKm;
  final ValueChanged<double> onRadiusChanged;
  final ValueChanged<bool> onLocationChanged;

  @override
  Widget build(BuildContext context) {
    final rides = exploringAway ? MockData.awayRides : MockData.homeRides;
    final city = exploringAway ? 'Curitiba, PR' : 'São Paulo, SP';

    return ScreenFrame(
      child: ListView(
        children: [
          _FeedHeader(
            city: city,
            onChangeLocation: () => _openLocationSheet(context),
          ),
          if (exploringAway)
            _HomeBack(onPressed: () => onLocationChanged(false)),
          const SizedBox(height: 20),
          _RadiusControl(radiusKm: radiusKm, onChanged: onRadiusChanged),
          const SizedBox(height: AppGaps.lg),
          _FeedTitle(count: rides.length, radiusKm: radiusKm),
          const SizedBox(height: AppGaps.xs),
          for (final ride in rides)
            RideCard(ride: ride, onTap: () => context.openRide(ride)),
          const SizedBox(height: AppGaps.bottom),
        ],
      ),
    );
  }

  void _openLocationSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.paper,
      showDragHandle: true,
      builder: (_) =>
          _LocationSheet(onSelectAway: () => onLocationChanged(true)),
    );
  }
}

class _FeedHeader extends StatelessWidget {
  const _FeedHeader({required this.city, required this.onChangeLocation});

  final String city;
  final VoidCallback onChangeLocation;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BrandMark(),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(city, style: Theme.of(context).textTheme.titleMedium),
            Transform.translate(
              offset: const Offset(0, -3),
              child: TextButton(
                onPressed: onChangeLocation,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 24),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('trocar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HomeBack extends StatelessWidget {
  const _HomeBack({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Row(
        children: [
          const FaIcon(FontAwesomeIcons.locationDot, color: AppColors.orange),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Você está fora da sua região',
              style: TextStyle(
                color: AppColors.paper,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(
            onPressed: onPressed,
            child: const Text('Voltar pra São Paulo'),
          ),
        ],
      ),
    );
  }
}

class _RadiusControl extends StatelessWidget {
  const _RadiusControl({required this.radiusKm, required this.onChanged});

  final double radiusKm;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.paper2,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
        child: Column(
          children: [
            Row(
              children: [
                const SectionLabel('SAÍDAS EM UM RAIO DE:'),
                const Spacer(),
                Text(
                  '${radiusKm.round()} km',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            Slider(
              value: radiusKm,
              min: 10,
              max: 100,
              divisions: 9,
              onChanged: onChanged,
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('10 km'), Text('100 km')],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedTitle extends StatelessWidget {
  const _FeedTitle({required this.count, required this.radiusKm});

  final int count;
  final double radiusKm;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'Próximos roles',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: AppColors.inkMedium),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$count num raio de ${radiusKm.round()} km',
          style: const TextStyle(
            color: AppColors.asphalt,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LocationSheet extends StatelessWidget {
  const _LocationSheet({required this.onSelectAway});

  final VoidCallback onSelectAway;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ver roles de onde?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: EdgeInsets.all(12),
                child: FaIcon(FontAwesomeIcons.magnifyingGlass, size: 18),
              ),
              hintText: 'Buscar cidade ou estado',
            ),
          ),
          const SizedBox(height: 14),
          _CityOption(
            title: 'Minha região',
            subtitle: 'São Paulo, SP',
            onTap: () => Navigator.pop(context),
          ),
          const SectionLabel('Resultados'),
          _CityOption(
            title: 'Curitiba',
            subtitle: 'Paraná · PR',
            onTap: () => _select(context),
          ),
          _CityOption(
            title: 'Curvelo',
            subtitle: 'Minas Gerais · MG',
            onTap: () => _select(context),
          ),
          _CityOption(
            title: 'Curitibanos',
            subtitle: 'Santa Catarina · SC',
            onTap: () => _select(context),
          ),
        ],
      ),
    );
  }

  void _select(BuildContext context) {
    onSelectAway();
    Navigator.pop(context);
  }
}

class _CityOption extends StatelessWidget {
  const _CityOption({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: const FaIcon(FontAwesomeIcons.locationDot),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(subtitle),
    );
  }
}
