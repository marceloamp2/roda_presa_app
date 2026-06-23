import 'package:flutter/material.dart';

import '../models/ride.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/ride_card.dart';
import 'ride_detail_screen.dart';

const _upcomingRides = [
  Ride(
    id: -1,
    title: 'Campos do Jordão',
    destination: 'Campos do Jordão',
    departureName: 'Posto Graal',
    departureDetail: 'Marginal Tietê, SP',
    time: '09:30',
    weekday: 'Sáb',
    date: '27/06',
    fullDate: '27/06 sábado',
    distanceKm: 115,
    confirmedCount: 14,
    users: [],
    hot: true,
    canceled: false,
    briefing: '09:00',
    tolls: 'R\$ 14,20',
  ),
  Ride(
    id: -2,
    title: 'Santos · orla',
    destination: 'Santos · orla',
    departureName: 'Shell',
    departureDetail: 'Av. dos Bandeirantes',
    time: '07:00',
    weekday: 'Dom',
    date: '28/06',
    fullDate: '28/06 domingo',
    distanceKm: 144,
    confirmedCount: 6,
    users: [],
    hot: false,
    canceled: false,
    briefing: '09:00',
    tolls: 'R\$ 22,40',
  ),
  Ride(
    id: -3,
    title: 'Serra do Rio do Rastro',
    destination: 'Serra do Rio do Rastro',
    departureName: 'Posto Trevo',
    departureDetail: 'Anchieta',
    time: '08:15',
    weekday: 'Sáb',
    date: '04/07',
    fullDate: '04/07 sábado',
    distanceKm: 92,
    confirmedCount: 3,
    users: [],
    hot: false,
    canceled: false,
    briefing: '09:00',
    tolls: 'sem pedágio',
  ),
];

const _pastRides = [
  Ride(
    id: -4,
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
    users: [],
    hot: false,
    canceled: false,
    briefing: '09:00',
    tolls: 'R\$ 14,20',
  ),
  Ride(
    id: -5,
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
    users: [],
    hot: false,
    canceled: true,
    briefing: '09:00',
    tolls: 'R\$ 14,20',
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
          for (final ride in _upcomingRides)
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
