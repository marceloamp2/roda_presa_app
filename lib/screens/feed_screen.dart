import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/city.dart';
import '../models/ride.dart';
import '../services/ride_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/city_search_sheet.dart';
import '../widgets/ride_card.dart';
import 'ride_detail_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({
    required this.homeLocation,
    required this.selectedLocation,
    required this.radiusKm,
    required this.feedRefreshTick,
    required this.onRadiusChanged,
    required this.onLocationSelected,
    required this.onReturnHome,
    super.key,
  });

  final FeedLocation homeLocation;
  final FeedLocation selectedLocation;
  final double radiusKm;
  final int feedRefreshTick;
  final ValueChanged<double> onRadiusChanged;
  final ValueChanged<FeedLocation> onLocationSelected;
  final VoidCallback onReturnHome;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final RideApiService _rideApiService = RideApiService();
  late final Future<PackageInfo> _packageInfoFuture;

  List<Ride> _rides = const [];
  bool _loading = true;
  String? _errorMessage;
  int _requestVersion = 0;

  bool get _exploringAway => widget.selectedLocation != widget.homeLocation;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
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
        oldWidget.radiusKm != widget.radiusKm ||
        oldWidget.feedRefreshTick != widget.feedRefreshTick) {
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
              packageInfoFuture: _packageInfoFuture,
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
        RideCard(ride: ride, onTap: () => _openRide(ride)),
    ];
  }

  Future<void> _openRide(Ride ride) async {
    await context.openRide(ride);

    if (mounted) {
      await _loadRides();
    }
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
        _errorMessage = 'Não foi possível carregar os rolês agora.';
      });
    }
  }

  void _openLocationSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CitySearchSheet(
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
  const _FeedHeader({
    required this.city,
    required this.packageInfoFuture,
    required this.onChangeLocation,
  });

  final String city;
  final Future<PackageInfo> packageInfoFuture;
  final VoidCallback onChangeLocation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BrandMark(),
            const Spacer(),
            _HeaderInfo(packageInfoFuture: packageInfoFuture),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                city,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onChangeLocation,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 24),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('trocar'),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderInfo extends StatelessWidget {
  const _HeaderInfo({required this.packageInfoFuture});

  final Future<PackageInfo> packageInfoFuture;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const BrandClock(),
        const SizedBox(height: 6),
        FutureBuilder<PackageInfo>(
          future: packageInfoFuture,
          builder: (_, snapshot) => _VersionText(packageInfo: snapshot.data),
        ),
      ],
    );
  }
}

class _VersionText extends StatelessWidget {
  const _VersionText({required this.packageInfo});

  final PackageInfo? packageInfo;

  @override
  Widget build(BuildContext context) {
    if (packageInfo == null) {
      return const SizedBox.shrink();
    }

    return Text(
      _versionText(packageInfo!),
      style: const TextStyle(
        color: AppColors.asphalt,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  String _versionText(PackageInfo packageInfo) {
    final buildNumber = packageInfo.buildNumber.trim();

    if (buildNumber.isEmpty) {
      return 'v${packageInfo.version}';
    }

    return 'v${packageInfo.version}+$buildNumber';
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

class _RadiusControl extends StatefulWidget {
  const _RadiusControl({required this.radiusKm, required this.onChanged});

  final double radiusKm;
  final ValueChanged<double> onChanged;

  @override
  State<_RadiusControl> createState() => _RadiusControlState();
}

class _RadiusControlState extends State<_RadiusControl> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final value = _dragValue ?? widget.radiusKm;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.paperSoft,
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
                  '${value.round()} km',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            Slider(
              value: value,
              min: 10,
              max: 100,
              divisions: 9,
              onChanged: (value) => setState(() => _dragValue = value),
              onChangeEnd: (value) {
                setState(() => _dragValue = null);
                widget.onChanged(value);
              },
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
            'Próximos rolês',
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
          Text('Carregando rolês perto de você...'),
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
            'Não foi possível carregar os rolês agora.',
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
        'Nenhum rolê encontrado nesse raio. Tente aumentar a distância.',
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
