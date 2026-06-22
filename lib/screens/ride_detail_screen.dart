import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';

class RideDetailScreen extends StatefulWidget {
  const RideDetailScreen({required this.ride, super.key});

  final Ride ride;

  @override
  State<RideDetailScreen> createState() => _RideDetailScreenState();
}

extension RideNavigation on BuildContext {
  void openRide(Ride ride) {
    Navigator.of(this).push(
      MaterialPageRoute<void>(builder: (_) => RideDetailScreen(ride: ride)),
    );
  }
}

class _RideDetailScreenState extends State<RideDetailScreen> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenFrame(
        child: ListView(
          children: [
            _DetailTop(ride: widget.ride),
            const SizedBox(height: AppGaps.lg),
            _BriefingGrid(ride: widget.ride),
            const SizedBox(height: AppGaps.lg),
            _ConfirmedList(ride: widget.ride, confirmed: _confirmed),
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomNavigationBar: _ActionBar(
        onCopy: _copyRideText,
        onJoin: _handleJoin,
        joined: _confirmed,
      ),
    );
  }

  Future<void> _copyRideText() async {
    await Clipboard.setData(ClipboardData(text: widget.ride.shareText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lista copiada no formato do WhatsApp.')),
    );
  }

  void _handleJoin() {
    if (_confirmed) {
      setState(() => _confirmed = false);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.paper,
      showDragHandle: true,
      builder: (_) =>
          _LoginSheet(ride: widget.ride, onContinue: _confirmAfterLogin),
    );
  }

  void _confirmAfterLogin() {
    Navigator.pop(context);
    setState(() => _confirmed = true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Você entrou na lista.')));
  }
}

class _DetailTop extends StatelessWidget {
  const _DetailTop({required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const FaIcon(FontAwesomeIcons.arrowLeft),
          label: const Text('voltar'),
        ),
        const SizedBox(height: 12),
        Text(
          ride.hot ? 'Role · 🔥 enchendo' : 'Role',
          style: const TextStyle(
            color: AppColors.asphalt,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          ride.destination,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.displayMedium?.copyWith(color: AppColors.inkMedium),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              ride.date,
              maxLines: 1,
              style: Theme.of(
                context,
              ).textTheme.displayLarge?.copyWith(color: AppColors.inkMedium),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${ride.weekday} · saída às ${ride.time}',
          style: const TextStyle(
            color: AppColors.asphalt,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _BriefingGrid extends StatelessWidget {
  const _BriefingGrid({required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    return CardFrame(
      child: Column(
        children: [
          _BriefRow(
            label: 'saída',
            value: '${ride.departureName}, ${ride.departureDetail}',
          ),
          _BriefRow(label: 'Briefing', value: ride.briefing),
          _BriefRow(label: 'Volta', value: ride.returnPlan),
          _BriefRow(
            label: 'Distância',
            value: '${ride.distanceKm} km · ida e volta',
          ),
          _BriefRow(label: 'Pedágios', value: ride.tolls),
          const _BriefRow(label: 'Antes de sair', child: _ChecklistValue()),
        ],
      ),
    );
  }
}

class _BriefRow extends StatelessWidget {
  const _BriefRow({required this.label, this.value, this.child})
    : assert(value != null || child != null);

  final String label;
  final String? value;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 96, child: SectionLabel(label)),
          Expanded(
            child:
                child ??
                Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

// Checklist de "antes de sair", no mesmo formato de pill da tela de feed.
class _ChecklistValue extends StatelessWidget {
  const _ChecklistValue();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ChecklistPill(icon: FontAwesomeIcons.gasPump, label: 'Abastecer'),
        _ChecklistPill(icon: FontAwesomeIcons.gaugeHigh, label: 'Calibrar'),
      ],
    );
  }
}

class _ChecklistPill extends StatelessWidget {
  const _ChecklistPill({required this.icon, required this.label});

  final FaIconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Pill(
      color: AppColors.inkSoft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 15, color: AppColors.ink),
          const SizedBox(width: 5),
          Text(label),
        ],
      ),
    );
  }
}

class _ConfirmedList extends StatelessWidget {
  const _ConfirmedList({required this.ride, required this.confirmed});

  final Ride ride;
  final bool confirmed;

  @override
  Widget build(BuildContext context) {
    final count = ride.riders.length + (confirmed ? 1 : 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Lista de confirmados',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.inkMedium,
                  fontSize: 24,
                ),
              ),
            ),
            Text(
              '$count',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 24,
                color: AppColors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (confirmed)
          const _PersonRow(
            number: '✓',
            rider: Rider(initials: 'VC', name: 'Você', motorcycle: 'sua moto'),
          ),
        for (var index = 0; index < ride.riders.length; index++)
          _PersonRow(number: '${index + 1}', rider: ride.riders[index]),
      ],
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.number, required this.rider});

  final String number;
  final Rider rider;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Text(
        number,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      title: Text(
        rider.name,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(rider.motorcycle),
      trailing: InitialsAvatar(rider.initials),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.onCopy,
    required this.onJoin,
    required this.joined,
  });

  final VoidCallback onCopy;
  final VoidCallback onJoin;
  final bool joined;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onCopy,
              icon: const FaIcon(FontAwesomeIcons.copy),
              label: const Text('Copiar'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: onJoin,
              style: FilledButton.styleFrom(
                backgroundColor: joined ? AppColors.green : AppColors.orange,
              ),
              child: Text(joined ? 'Estou na lista' : 'Vou nessa'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginSheet extends StatelessWidget {
  const _LoginSheet({required this.ride, required this.onContinue});

  final Ride ride;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Só falta dizer\nquem é você',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontSize: 34, height: 0.95),
          ),
          const SizedBox(height: 12),
          const Text('Entre com o Google pra entrar na lista. Leva um toque.'),
          const SizedBox(height: 18),
          _SmallRideTicket(ride: ride),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onContinue,
              icon: const FaIcon(FontAwesomeIcons.google),
              label: const Text('Continuar com o Google'),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Ver o feed e os roles é livre. O login só aparece quando você se compromete.',
          ),
        ],
      ),
    );
  }
}

class _SmallRideTicket extends StatelessWidget {
  const _SmallRideTicket({required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.paper2,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              ride.time,
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontSize: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${ride.weekday} ${ride.date}'),
                  Text(
                    ride.destination,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'saída: ${ride.departureName} · ${ride.confirmedCount} confirmados',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
