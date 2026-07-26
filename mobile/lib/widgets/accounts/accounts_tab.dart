import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/rank_info.dart';
import '../../models/user_profile.dart';
import '../../theme/app_colors.dart';

class AccountsTab extends StatelessWidget {
  final UserProfile? profile;
  final RankInfo? rankInfo;
  final VoidCallback onSelect;
  final VoidCallback onLogout;
  final VoidCallback onSwitchAccount;

  const AccountsTab({
    super.key,
    required this.profile,
    required this.rankInfo,
    required this.onSelect,
    required this.onLogout,
    required this.onSwitchAccount,
  });

  @override
  Widget build(BuildContext context) {
    final rankText = rankInfo != null ? '${rankInfo!.currentTierName} - ${rankInfo!.currentRR} RR' : 'UNRANKED';
    final rankIcon = rankInfo?.currentTierIcon ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'ACCOUNTS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 28,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: (profile?.cardIcon.isNotEmpty ?? false)
                            ? CachedNetworkImage(
                                imageUrl: profile!.cardIcon,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => _cardFallback(),
                              )
                            : _cardFallback(),
                      ),
                      if ((profile?.accountLevel ?? 0) > 0)
                        Positioned(
                          top: -6,
                          left: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white38, width: 1.2),
                            ),
                            child: Text(
                              '${profile?.accountLevel}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.riotId ?? 'Riot User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (rankIcon.isNotEmpty)
                              CachedNetworkImage(imageUrl: rankIcon, width: 20, height: 20)
                            else
                              const Icon(Icons.shield, color: Colors.amber, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                rankText,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: onSelect,
                        child: const Text(
                          'Select',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      tooltip: 'Log out',
                      icon: const Icon(Icons.logout, color: AppColors.primary, size: 20),
                      onPressed: onLogout,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: onSwitchAccount,
            icon: const Icon(Icons.swap_horiz, color: Colors.white),
            label: const Text(
              'Switch Account',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Switching signs you in to a different Riot account.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }

  Widget _cardFallback() {
    return Container(
      width: 70,
      height: 70,
      color: AppColors.primary.withValues(alpha: 0.2),
      child: const Icon(Icons.person, color: AppColors.primary, size: 36),
    );
  }
}
