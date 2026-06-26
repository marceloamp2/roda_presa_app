import 'dart:math';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/place.dart';
import '../services/ride_api_service.dart';
import '../theme/app_theme.dart';
import 'app_chrome.dart';
import 'search_sheet.dart';

class PlaceSearchField extends StatelessWidget {
  const PlaceSearchField({
    required this.label,
    required this.hintText,
    required this.icon,
    required this.rideApiService,
    required this.selectedPlace,
    required this.onSelected,
    this.isRequired = false,
    super.key,
  });

  final String label;
  final String hintText;
  final FaIconData icon;
  final RideApiService rideApiService;
  final SelectedPlace? selectedPlace;
  final ValueChanged<SelectedPlace> onSelected;
  final bool isRequired;

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
        title: FieldLabel(label, isRequired: isRequired),
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
    final sessionToken = _newSessionToken();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SearchSheet<PlaceSuggestion>(
        resultLimit: 5,
        texts: SearchSheetTexts(
          title: label,
          hintText: 'Digite um local ou endereço',
          emptyHint: 'Digite pelo menos 2 letras do local.',
          loading: 'Buscando locais...',
          notFound: 'Nenhum local encontrado.',
          searchError: 'Não foi possível buscar locais agora.',
          selectError: 'Não foi possível carregar esse local agora.',
        ),
        search: (search, limit) => rideApiService.autocompletePlaces(
          search: search,
          sessionToken: sessionToken,
          limit: limit,
        ),
        itemBuilder: (context, suggestion, selecting, onTap) => _PlaceOption(
          suggestion: suggestion,
          loading: selecting,
          enabled: !selecting,
          onTap: onTap,
        ),
        onSelect: (suggestion) => _selectPlace(suggestion, context),
      ),
    );
  }

  Future<bool> _selectPlace(
    PlaceSuggestion suggestion,
    BuildContext context,
  ) async {
    final place = await rideApiService.fetchPlaceDetails(
      placeId: suggestion.placeId,
    );

    if (!context.mounted) {
      return false;
    }

    onSelected(place);
    return true;
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
