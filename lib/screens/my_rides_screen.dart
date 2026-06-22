import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/ride_card.dart';
import 'ride_detail_screen.dart';

const _pastRides = [
  Ride(
    title: 'Monte Verde',
    destination: 'Monte Verde',
    departureName: 'Posto Graal',
    departureDetail: 'Rodovia Fernão Dias',
    time: '08:00',
    weekday: 'Sáb',
    date: '31/05',
    fullDate: '31/05 sábado',
    distanceKm: 168,
    confirmedCount: 9,
    riders: MockData.riders,
  ),
  Ride(
    title: 'Guarujá',
    destination: 'Guarujá',
    departureName: 'Cancelado',
    departureDetail: 'pelo organizador',
    time: '07:30',
    weekday: 'Sáb',
    date: '17/05',
    fullDate: '17/05 sábado',
    distanceKm: 96,
    confirmedCount: 0,
    riders: MockData.riders,
    canceled: true,
  ),
];

class MyRidesScreen extends StatefulWidget {
  const MyRidesScreen({super.key});

  @override
  State<MyRidesScreen> createState() => _MyRidesScreenState();
}

class _MyRidesScreenState extends State<MyRidesScreen> {
  int _segment = 0;

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      child: ListView(
        children: [
          const TwoToneTitle(prefix: 'Meus', highlight: 'Roles'),
          const SizedBox(height: AppGaps.md),
          _SegmentedControl(
            value: _segment,
            onChanged: (value) => setState(() => _segment = value),
          ),
          const SizedBox(height: AppGaps.lg),
          const SectionLabel('Próximos'),
          const SizedBox(height: AppGaps.xs),
          for (final ride in MockData.homeRides.take(3))
            RideCard(ride: ride, onTap: () => context.openRide(ride)),
          const SizedBox(height: AppGaps.lg),
          const SectionLabel('Já rolaram'),
          const SizedBox(height: AppGaps.xs),
          for (final ride in _pastRides)
            RideCard(ride: ride, onTap: () => context.openRide(ride)),
          const SizedBox(height: AppGaps.bottom),
        ],
      ),
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 0, label: Text('Vou nessas')),
        ButtonSegment(value: 1, label: Text('Organizo')),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.orange;
          }

          return AppColors.paper2;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.paper;
          }

          return AppColors.ink;
        }),
        side: const WidgetStatePropertyAll(BorderSide(color: AppColors.paper)),
      ),
    );
  }
}
