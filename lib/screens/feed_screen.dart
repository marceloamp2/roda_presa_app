import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/city.dart';
import '../models/ride.dart';
import '../services/ride_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/ride_card.dart';
import 'ride_detail_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({
    required this.homeLocation,
    required this.selectedLocation,
    required this.radiusKm,
    required this.onRadiusChanged,
    required this.onLocationSelected,
    required this.onReturnHome,
    super.key,
  });

  final FeedLocation homeLocation;
  final FeedLocation selectedLocation;
  final double radiusKm;
  final ValueChanged<double> onRadiusChanged;
  final ValueChanged<FeedLocation> onLocationSelected;
  final VoidCallback onReturnHome;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final RideApiService _rideApiService = RideApiService();

  List<Ride> _rides = const [];
  bool _loading = true;
  String? _errorMessage;
  int _requestVersion = 0;

  bool get _exploringAway => widget.selectedLocation != widget.homeLocation;

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  @override
  void dispose() {
    _rideApiService.close();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedLocation != widget.selectedLocation ||
        oldWidget.radiusKm != widget.radiusKm) {
      _loadRides();
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = widget.selectedLocation;

    return ScreenFrame(
      child: RefreshIndicator(
        onRefresh: _loadRides,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _FeedHeader(
              city: location.city,
              onChangeLocation: () => _openLocationSheet(context),
            ),
            if (_exploringAway) _HomeBack(onPressed: widget.onReturnHome),
            const SizedBox(height: 20),
            _RadiusControl(
              radiusKm: widget.radiusKm,
              onChanged: widget.onRadiusChanged,
            ),
            const SizedBox(height: AppGaps.lg),
            _FeedTitle(count: _rides.length, radiusKm: widget.radiusKm),
            const SizedBox(height: AppGaps.xs),
            ..._rideContent(),
            const SizedBox(height: AppGaps.bottom),
          ],
        ),
      ),
    );
  }

  List<Widget> _rideContent() {
    if (_loading && _rides.isEmpty) {
      return const [_LoadingState()];
    }

    if (_errorMessage != null && _rides.isEmpty) {
      return [_ErrorState(onRetry: _loadRides)];
    }

    if (_rides.isEmpty) {
      return const [_EmptyState()];
    }

    return [
      if (_loading) const LinearProgressIndicator(minHeight: 2),
      for (final ride in _rides)
        RideCard(ride: ride, onTap: () => context.openRide(ride)),
    ];
  }

  Future<void> _loadRides() async {
    final requestVersion = ++_requestVersion;
    final location = widget.selectedLocation;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final rides = await _rideApiService.fetchRides(
        lat: location.lat,
        lng: location.lng,
        radiusKm: widget.radiusKm,
      );

      if (!mounted || requestVersion != _requestVersion) {
        return;
      }

      setState(() {
        _rides = rides;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || requestVersion != _requestVersion) {
        return;
      }

      setState(() {
        _rides = const [];
        _loading = false;
        _errorMessage = 'Não foi possível carregar os roles agora.';
      });
    }
  }

  void _openLocationSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.paper,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _LocationSheet(
        rideApiService: _rideApiService,
        onCitySelected: _selectCity,
      ),
    );
  }

  void _selectCity(City city) {
    widget.onLocationSelected(
      FeedLocation(city: city.displayName, lat: city.lat, lng: city.lng),
    );
  }
}

class FeedLocation {
  const FeedLocation({
    required this.city,
    required this.lat,
    required this.lng,
  });

  final String city;
  final double lat;
  final double lng;

  @override
  bool operator ==(Object other) {
    return other is FeedLocation &&
        other.city == city &&
        other.lat == lat &&
        other.lng == lng;
  }

  @override
  int get hashCode => Object.hash(city, lat, lng);
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
            child: const Text('Voltar pra minha região'),
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const _StatusCard(
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text('Carregando roles perto de você...'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _StatusCard(
      child: Column(
        children: [
          const FaIcon(FontAwesomeIcons.triangleExclamation, size: 28),
          const SizedBox(height: 10),
          const Text(
            'Não foi possível carregar os roles agora.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const _StatusCard(
      child: Text(
        'Nenhum role encontrado nesse raio. Tente aumentar a distância.',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CardFrame(
      child: SizedBox(
        width: double.infinity,
        height: 120,
        child: Center(child: child),
      ),
    );
  }
}

class _LocationSheet extends StatefulWidget {
  const _LocationSheet({
    required this.rideApiService,
    required this.onCitySelected,
  });

  final RideApiService rideApiService;
  final ValueChanged<City> onCitySelected;

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  static const int _minimumSearchLength = 2;
  static const int _resultLimit = 20;
  static const Duration _debounceDuration = Duration(milliseconds: 400);

  final TextEditingController _controller = TextEditingController();

  Timer? _debounce;
  List<City> _cities = const [];
  bool _loading = false;
  String? _errorMessage;
  bool _hasSearched = false;
  String _lastSearch = '';
  int _requestVersion = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Buscar cidade',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  onChanged: _onSearchChanged,
                  decoration: const InputDecoration(
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(12),
                      child: FaIcon(FontAwesomeIcons.magnifyingGlass, size: 18),
                    ),
                    hintText: 'Digite a cidade',
                  ),
                ),
                const SizedBox(height: 14),
                const SectionLabel('Resultados'),
                const SizedBox(height: 8),
                Flexible(child: _resultContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultContent() {
    if (!_hasSearched) {
      return const _LocationMessage('Digite pelo menos 2 letras da cidade.');
    }

    if (_loading) {
      return const _LocationMessage.withProgress('Buscando cidades...');
    }

    if (_errorMessage != null) {
      return _LocationSearchError(onRetry: _retrySearch);
    }

    if (_cities.isEmpty) {
      return const _LocationMessage('Nenhuma cidade encontrada.');
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: _cities.length,
      itemBuilder: (context, index) {
        final city = _cities[index];

        return _CityOption(
          title: city.name,
          subtitle: city.state,
          onTap: () => _select(context, city),
        );
      },
    );
  }

  void _onSearchChanged(String value) {
    final search = value.trim();
    final requestVersion = ++_requestVersion;
    _debounce?.cancel();
    _lastSearch = search;

    if (search.length < _minimumSearchLength) {
      _resetSearch();
      return;
    }

    setState(() {
      _cities = const [];
      _loading = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    _debounce = Timer(
      _debounceDuration,
      () => _searchCities(search, requestVersion),
    );
  }

  Future<void> _searchCities(String search, int requestVersion) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    try {
      final cities = await widget.rideApiService.searchCities(
        search: search,
        limit: _resultLimit,
      );

      if (!mounted || requestVersion != _requestVersion) {
        return;
      }

      setState(() {
        _cities = cities;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || requestVersion != _requestVersion) {
        return;
      }

      setState(() {
        _cities = const [];
        _loading = false;
        _errorMessage = 'Não foi possível buscar cidades agora.';
      });
    }
  }

  void _retrySearch() {
    if (_lastSearch.length < _minimumSearchLength) {
      return;
    }

    _debounce?.cancel();
    final requestVersion = ++_requestVersion;
    _searchCities(_lastSearch, requestVersion);
  }

  void _resetSearch() {
    setState(() {
      _cities = const [];
      _loading = false;
      _errorMessage = null;
      _hasSearched = false;
    });
  }

  void _select(BuildContext context, City city) {
    widget.onCitySelected(city);
    Navigator.pop(context);
  }
}

class _LocationMessage extends StatelessWidget {
  const _LocationMessage(this.message) : showProgress = false;

  const _LocationMessage.withProgress(this.message) : showProgress = true;

  final String message;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showProgress) ...[
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationSearchError extends StatelessWidget {
  const _LocationSearchError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FaIcon(FontAwesomeIcons.triangleExclamation, size: 24),
            const SizedBox(height: 10),
            const Text(
              'Não foi possível buscar cidades agora.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
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
