import 'package:flutter/material.dart';

import '../auth/auth_scope.dart';
import '../models/my_rides.dart';
import '../models/ride.dart';
import '../services/api_exception.dart';
import '../services/ride_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/ride_card.dart';
import 'ride_detail_screen.dart';

class MyRidesScreen extends StatefulWidget {
  const MyRidesScreen({
    required this.isActive,
    required this.onSessionExpired,
    super.key,
  });

  final bool isActive;
  final VoidCallback onSessionExpired;

  @override
  State<MyRidesScreen> createState() => _MyRidesScreenState();
}

class _MyRidesScreenState extends State<MyRidesScreen> {
  final RideApiService _rideApiService = RideApiService();

  int _segment = 0;
  bool _loading = false;
  String? _errorMessage;
  String? _loadedToken;
  MyRides? _rides;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.isActive) {
      _loadIfNeeded();
    }
  }

  @override
  void didUpdateWidget(covariant MyRidesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.isActive && widget.isActive) {
      _reload();
    }
  }

  @override
  void dispose() {
    _rideApiService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rides = _selectedRides;

    return ScreenFrame(
      child: ListView(
        children: [
          const TwoToneTitle(prefix: 'Meus', highlight: 'Rolês'),
          const SizedBox(height: AppGaps.md),
          _SegmentedControl(
            value: _segment,
            onChanged: (value) => setState(() => _segment = value),
          ),
          const SizedBox(height: AppGaps.lg),
          SectionLabel(_segment == 0 ? 'Vou nesses' : 'Organizo'),
          const SizedBox(height: AppGaps.xs),
          if (_loading) const _LoadingState(),
          if (!_loading && _errorMessage != null)
            _MessageState(message: _errorMessage!, onRetry: _reload),
          if (!_loading && _errorMessage == null && rides.isEmpty)
            const _EmptyState(),
          if (!_loading && _errorMessage == null)
            for (final ride in rides)
              RideCard(ride: ride, onTap: () => _openRide(ride)),
          const SizedBox(height: AppGaps.bottom),
        ],
      ),
    );
  }

  List<Ride> get _selectedRides {
    final rides = _rides;

    if (rides == null) {
      return const [];
    }

    return _segment == 0 ? rides.confirmed : rides.organized;
  }

  Future<void> _openRide(Ride ride) async {
    await context.openRide(ride);

    if (mounted) {
      await _reload();
    }
  }

  void _loadIfNeeded() {
    if (_loading) {
      return;
    }

    _load(AuthScope.of(context).token);
  }

  Future<void> _reload() async {
    await _load(AuthScope.of(context).token, force: true);
  }

  Future<void> _load(String? token, {bool force = false}) async {
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _errorMessage = 'Entre novamente para ver seus rolês.';
        _rides = null;
        _loadedToken = null;
      });
      return;
    }

    if (!force && token == _loadedToken && _rides != null) {
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final rides = await _rideApiService.fetchMyRides(authToken: token);

      if (!mounted) {
        return;
      }

      setState(() {
        _rides = rides;
        _loadedToken = token;
        _loading = false;
      });
    } catch (exception) {
      if (!mounted) {
        return;
      }

      if (await AuthScope.of(context).handleApiException(exception)) {
        widget.onSessionExpired();
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _errorMessage = _errorFor(exception);
      });
    }
  }

  String _errorFor(Object exception) {
    if (exception is ApiException) {
      return exception.message;
    }

    return 'Não foi possível carregar seus rolês agora.';
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
        ButtonSegment(value: 0, label: Text('Vou nesses')),
        ButtonSegment(value: 1, label: Text('Organizo')),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.orange;
          }

          return AppColors.paperSoft;
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const CardFrame(child: Text('Nenhum rolê por aqui ainda.'));
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return CardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: AppGaps.sm),
          TextButton(onPressed: onRetry, child: const Text('tentar de novo')),
        ],
      ),
    );
  }
}
