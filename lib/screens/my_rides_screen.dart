import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
  _Panel _openPanel = _Panel.upcoming;
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
      setState(() {
        _segment = 0;
        _openPanel = _Panel.upcoming;
      });
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
    return ScreenFrame(
      child: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const TwoToneTitle(prefix: 'Meus', highlight: 'Rolês'),
            const SizedBox(height: AppGaps.md),
            _SegmentedControl(value: _segment, onChanged: _selectSegment),
            const SizedBox(height: AppGaps.lg),
            if (_loading) const _LoadingState(),
            if (!_loading && _errorMessage != null)
              _MessageState(message: _errorMessage!, onRetry: _reload),
            if (!_loading && _errorMessage == null) ..._content(),
            const SizedBox(height: AppGaps.bottom),
          ],
        ),
      ),
    );
  }

  List<Widget> _content() {
    final rides = _selectedRides;

    if (rides.isEmpty) {
      return const [_EmptyState()];
    }

    final upcoming = [
      for (final ride in rides)
        if (!ride.isPast) ride,
    ];
    final past = [
      for (final ride in rides)
        if (ride.isPast) ride,
    ];

    return [
      _AccordionPanel(
        title: 'Por vir',
        count: upcoming.length,
        expanded: _openPanel == _Panel.upcoming,
        onTap: () => _togglePanel(_Panel.upcoming),
        child: upcoming.isEmpty
            ? const _NothingUpcoming()
            : _rideList(upcoming),
      ),
      const SizedBox(height: AppGaps.sm),
      _AccordionPanel(
        title: 'Já rolaram',
        count: past.length,
        expanded: _openPanel == _Panel.past,
        onTap: () => _togglePanel(_Panel.past),
        child: past.isEmpty ? const _NothingPast() : _rideList(past),
      ),
    ];
  }

  Widget _rideList(List<Ride> rides) {
    return Column(
      children: [
        for (final ride in rides)
          RideCard(ride: ride, onTap: () => _openRide(ride)),
      ],
    );
  }

  void _togglePanel(_Panel panel) {
    setState(() => _openPanel = _openPanel == panel ? _Panel.none : panel);
  }

  List<Ride> get _selectedRides {
    final rides = _rides;

    if (rides == null) {
      return const [];
    }

    return _segment == 0 ? rides.confirmed : rides.organized;
  }

  void _selectSegment(int value) {
    setState(() {
      _segment = value;
      _openPanel = _Panel.upcoming;
    });
  }

  Future<void> _openRide(Ride ride) async {
    final initialOrganizer = _isInList(ride, _rides?.organized);
    final initialJoined =
        initialOrganizer || _isInList(ride, _rides?.confirmed);

    await context.openRide(
      ride,
      initialJoined: initialJoined,
      initialOrganizer: initialOrganizer,
    );

    if (mounted) {
      await _reload();
    }
  }

  bool _isInList(Ride ride, List<Ride>? rides) {
    return rides?.any((item) => item.id == ride.id) ?? false;
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
        side: const WidgetStatePropertyAll(
          BorderSide(color: AppColors.hairline),
        ),
      ),
    );
  }
}

enum _Panel { upcoming, past, none }

class _AccordionPanel extends StatelessWidget {
  const _AccordionPanel({
    required this.title,
    required this.count,
    required this.expanded,
    required this.onTap,
    required this.child,
  });

  final String title;
  final int count;
  final bool expanded;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                FaIcon(
                  expanded
                      ? FontAwesomeIcons.chevronDown
                      : FontAwesomeIcons.chevronRight,
                  size: 12,
                  color: AppColors.asphalt,
                ),
                const SizedBox(width: 8),
                SectionLabel('$title ($count)'),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.only(top: AppGaps.xs),
                  child: child,
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _NothingUpcoming extends StatelessWidget {
  const _NothingUpcoming();

  @override
  Widget build(BuildContext context) {
    return const CardFrame(child: Text('Nada por vir por enquanto.'));
  }
}

class _NothingPast extends StatelessWidget {
  const _NothingPast();

  @override
  Widget build(BuildContext context) {
    return const CardFrame(child: Text('Nenhum rolê já rolou ainda.'));
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
          TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}
