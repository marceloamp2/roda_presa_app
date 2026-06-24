import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/place.dart';
import '../services/ride_api_service.dart';
import '../theme/app_theme.dart';
import 'app_chrome.dart';
import 'search_sheet_status.dart';

class PlaceSearchField extends StatelessWidget {
  const PlaceSearchField({
    required this.label,
    required this.hintText,
    required this.icon,
    required this.rideApiService,
    required this.selectedPlace,
    required this.onSelected,
    super.key,
  });

  final String label;
  final String hintText;
  final FaIconData icon;
  final RideApiService rideApiService;
  final SelectedPlace? selectedPlace;
  final ValueChanged<SelectedPlace> onSelected;

  @override
  Widget build(BuildContext context) {
    final place = selectedPlace;
    final hasSelection = place != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: ListTile(
        onTap: () => _openSearch(context),
        leading: FaIcon(icon, color: AppColors.orange),
        title: Text(
          label,
          style: const TextStyle(
            color: AppColors.asphalt,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasSelection ? place.displayName : hintText,
              style: TextStyle(
                fontSize: 18,
                color: hasSelection ? AppColors.ink : AppColors.asphalt,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (hasSelection && place.displayAddress != place.displayName) ...[
              const SizedBox(height: 2),
              Text(
                place.displayAddress,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.asphalt,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
        trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 16),
      ),
    );
  }

  Future<void> _openSearch(BuildContext context) async {
    final selected = await showModalBottomSheet<SelectedPlace>(
      context: context,
      backgroundColor: AppColors.paper,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          _PlaceSearchSheet(label: label, rideApiService: rideApiService),
    );

    if (selected != null && context.mounted) {
      onSelected(selected);
    }
  }
}

class _PlaceSearchSheet extends StatefulWidget {
  const _PlaceSearchSheet({required this.label, required this.rideApiService});

  final String label;
  final RideApiService rideApiService;

  @override
  State<_PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends State<_PlaceSearchSheet> {
  static const int _minimumSearchLength = 2;
  static const int _resultLimit = 5;
  static const Duration _debounceDuration = Duration(milliseconds: 400);

  final TextEditingController _controller = TextEditingController();
  final String _sessionToken = _newSessionToken();

  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = const [];
  bool _loading = false;
  String? _errorMessage;
  String? _selectingPlaceId;
  bool _hasSearched = false;
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
                  widget.label,
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
                    hintText: 'Digite um local ou endereço',
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
      return const SearchSheetMessage('Digite pelo menos 2 letras do local.');
    }

    if (_loading) {
      return const SearchSheetMessage.withProgress('Buscando locais...');
    }

    if (_errorMessage != null) {
      return SearchSheetError(message: _errorMessage!, onRetry: _retrySearch);
    }

    if (_suggestions.isEmpty) {
      return const SearchSheetMessage('Nenhum local encontrado.');
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];

        return _PlaceOption(
          suggestion: suggestion,
          loading: _selectingPlaceId == suggestion.placeId,
          enabled: _selectingPlaceId == null,
          onTap: () => _select(suggestion),
        );
      },
    );
  }

  void _onSearchChanged(String value) {
    final search = value.trim();
    final requestVersion = ++_requestVersion;
    _debounce?.cancel();

    if (search.length < _minimumSearchLength) {
      _resetSearch();
      return;
    }

    _startSearching();
    _debounce = Timer(
      _debounceDuration,
      () => _searchPlaces(search, requestVersion),
    );
  }

  void _startSearching() {
    setState(() {
      _suggestions = const [];
      _loading = true;
      _errorMessage = null;
      _selectingPlaceId = null;
      _hasSearched = true;
    });
  }

  Future<void> _searchPlaces(String search, int requestVersion) async {
    if (!mounted) {
      return;
    }

    try {
      final suggestions = await widget.rideApiService.autocompletePlaces(
        search: search,
        sessionToken: _sessionToken,
        limit: _resultLimit,
      );

      if (!mounted || requestVersion != _requestVersion) {
        return;
      }

      setState(() {
        _suggestions = suggestions;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || requestVersion != _requestVersion) {
        return;
      }

      setState(() {
        _suggestions = const [];
        _loading = false;
        _errorMessage = 'Não foi possível buscar locais agora.';
      });
    }
  }

  Future<void> _select(PlaceSuggestion suggestion) async {
    if (_selectingPlaceId != null) {
      return;
    }

    setState(() {
      _selectingPlaceId = suggestion.placeId;
      _errorMessage = null;
    });

    try {
      final place = await widget.rideApiService.fetchPlaceDetails(
        placeId: suggestion.placeId,
        sessionToken: _sessionToken,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context, place);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _selectingPlaceId = null;
        _errorMessage = 'Não foi possível carregar esse local agora.';
      });
    }
  }

  void _retrySearch() {
    final search = _controller.text.trim();
    if (search.length < _minimumSearchLength) {
      return;
    }

    _debounce?.cancel();
    final requestVersion = ++_requestVersion;
    _startSearching();
    _searchPlaces(search, requestVersion);
  }

  void _resetSearch() {
    setState(() {
      _suggestions = const [];
      _loading = false;
      _errorMessage = null;
      _selectingPlaceId = null;
      _hasSearched = false;
    });
  }

  static String _newSessionToken() {
    final randomValue = Random().nextInt(1 << 32);
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    return '$timestamp-$randomValue';
  }
}

class _PlaceOption extends StatelessWidget {
  const _PlaceOption({
    required this.suggestion,
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  final PlaceSuggestion suggestion;
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: enabled ? onTap : null,
      contentPadding: EdgeInsets.zero,
      leading: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 3),
            )
          : const FaIcon(FontAwesomeIcons.locationDot),
      title: Text(
        suggestion.title,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: suggestion.subtitle.isEmpty ? null : Text(suggestion.subtitle),
    );
  }
}
