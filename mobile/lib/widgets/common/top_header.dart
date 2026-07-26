import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/user_profile.dart';
import '../../theme/app_colors.dart';

/// Header shown on Shop/Profile tabs: avatar, Riot ID, currency balances,
/// and a large section title.
class TopHeader extends StatelessWidget {
  final UserProfile? profile;
  final String title;

  const TopHeader({super.key, required this.profile, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: (profile?.cardIcon.isNotEmpty ?? false)
                          ? CachedNetworkImage(
                              imageUrl: profile!.cardIcon,
                              width: 34,
                              height: 34,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => _avatarFallback(),
                            )
                          : _avatarFallback(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    profile?.riotId ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CurrencyPill(
                    iconUrl: 'https://media.valorant-api.com/currencies/85ad13f7-3d1b-5128-9eb2-7cd8ee0b5741/displayicon.png',
                    amount: '${profile?.vp ?? 0}',
                  ),
                  const SizedBox(width: 4),
                  _CurrencyPill(
                    iconUrl: 'https://media.valorant-api.com/currencies/e59aa87c-4cbf-517a-5983-6e81511be9b7/displayicon.png',
                    amount: '${profile?.rad ?? 0}',
                  ),
                  const SizedBox(width: 4),
                  _CurrencyPill(
                    iconUrl: 'https://media.valorant-api.com/currencies/85ca954a-41f2-ce94-9b45-8ca3dd39a00d/displayicon.png',
                    amount: '${profile?.kc ?? 0}',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 28,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.2),
      child: const Icon(Icons.person, color: AppColors.primary, size: 18),
    );
  }
}

class _CurrencyPill extends StatelessWidget {
  final String iconUrl;
  final String amount;

  const _CurrencyPill({required this.iconUrl, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CachedNetworkImage(
            imageUrl: iconUrl,
            width: 14,
            height: 14,
            fit: BoxFit.contain,
            placeholder: (context, url) => const SizedBox(width: 14, height: 14),
            errorWidget: (context, url, error) => const Icon(Icons.monetization_on, color: Colors.amber, size: 14),
          ),
          const SizedBox(width: 4),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
