import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/city.dart';
import '../services/ride_api_service.dart';
import 'search_sheet.dart';

class CitySearchSheet extends StatelessWidget {
  const CitySearchSheet({
    required this.rideApiService,
    required this.onCitySelected,
    this.title = 'Buscar cidade',
    super.key,
  });

  final RideApiService rideApiService;
  final ValueChanged<City> onCitySelected;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SearchSheet<City>(
      texts: SearchSheetTexts(
        title: title,
        hintText: 'Digite a cidade',
        emptyHint: 'Digite pelo menos 2 letras da cidade.',
        loading: 'Buscando cidades...',
        notFound: 'Nenhuma cidade encontrada.',
        searchError: 'Não foi possível buscar cidades agora.',
      ),
      search: (search, limit) =>
          rideApiService.searchCities(search: search, limit: limit),
      itemBuilder: (context, city, selecting, onTap) => _CityOption(
        title: city.name,
        subtitle: city.state,
        onTap: onTap,
      ),
      onSelect: (city) async {
        onCitySelected(city);
        return true;
      },
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
