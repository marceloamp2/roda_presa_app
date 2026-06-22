import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import 'app_chrome.dart';

class RideCard extends StatelessWidget {
  const RideCard({required this.ride, required this.onTap, super.key});

  final Ride ride;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.paper,
      margin: const EdgeInsets.only(bottom: 10),
      shape: const Border(bottom: BorderSide(color: AppColors.hairline)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateBlock(ride: ride),
              const SizedBox(width: 16),
              Expanded(child: _RideInfo(ride: ride)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateBlock extends StatelessWidget {
  const _DateBlock({required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ride.date,
            maxLines: 1,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.inkMedium,
              fontSize: 23,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.calendarDay,
                size: 14,
                color: AppColors.asphalt,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  ride.weekday,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.asphalt,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.clock,
                size: 14,
                color: AppColors.asphalt,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  ride.time,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.asphalt,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RideInfo extends StatelessWidget {
  const _RideInfo({required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                ride.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.inkMedium,
                  fontSize: 23,
                  height: 1.05,
                ),
              ),
            ),
            if (ride.canceled) ...[
              const SizedBox(width: 8),
              const Pill(
                color: AppColors.redSoft,
                foreground: AppColors.red,
                child: Text('cancelado'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '↑ saída: ${ride.departureName}, ${ride.departureDetail}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.asphalt,
            fontSize: 13,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Pill(
              color: AppColors.inkSoft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.route,
                    size: 15,
                    color: AppColors.ink,
                  ),
                  const SizedBox(width: 5),
                  Text('ida e volta ${ride.distanceKm} km'),
                ],
              ),
            ),
            Pill(
              color: AppColors.greenSoft,
              foreground: AppColors.green,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.userGroup,
                    size: 15,
                    color: AppColors.green,
                  ),
                  const SizedBox(width: 5),
                  Text('${ride.confirmedCount} vão'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
