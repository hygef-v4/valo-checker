import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/rank_info.dart';
import '../../models/saved_account.dart';
import '../../models/user_profile.dart';
import '../../theme/app_colors.dart';

class AccountsTab extends StatelessWidget {
  final List<SavedAccount> accounts;
  final String? activePuuid;
  final UserProfile? activeProfile;
  final RankInfo? activeRankInfo;
  final ValueChanged<SavedAccount> onSelectAccount;
  final ValueChanged<SavedAccount> onDeleteAccount;
  final VoidCallback onAddAccount;

  const AccountsTab({
    super.key,
    required this.accounts,
    required this.activePuuid,
    required this.activeProfile,
    required this.activeRankInfo,
    required this.onSelectAccount,
    required this.onDeleteAccount,
    required this.onAddAccount,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            IconButton(
              tooltip: 'Add Account',
              icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary, size: 26),
              onPressed: onAddAccount,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (accounts.isEmpty) _buildEmptyState(),
        for (final account in accounts) ...[
          _buildAccountCard(context, account),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: onAddAccount,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Add Riot Account',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sign in with additional Riot accounts to switch seamlessly.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.account_circle_outlined, size: 60, color: Colors.white38),
          SizedBox(height: 12),
          Text(
            'No Accounts Saved',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 4),
          Text(
            'Add your Riot Games account to view store and profile data.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, SavedAccount account) {
    final isActive = account.puuid == activePuuid;

    // Use live active details if matching current profile, otherwise saved values
    final cardIcon = (isActive && (activeProfile?.cardIcon.isNotEmpty ?? false))
        ? activeProfile!.cardIcon
        : account.cardIcon;
    final level = (isActive && ((activeProfile?.accountLevel ?? 0) > 0))
        ? activeProfile!.accountLevel
        : account.accountLevel;
    final riotId = (isActive && (activeProfile?.riotId.isNotEmpty ?? false))
        ? activeProfile!.riotId
        : account.riotId;

    final rankTierIcon = (isActive && (activeRankInfo?.currentTierIcon.isNotEmpty ?? false))
        ? activeRankInfo!.currentTierIcon
        : (account.rankTierIcon ?? '');
    final rankText = isActive
        ? (activeRankInfo != null ? '${activeRankInfo!.currentTierName} - ${activeRankInfo!.currentRR} RR' : 'UNRANKED')
        : (account.rankTierName != null ? '${account.rankTierName} - ${account.rankRR ?? 0} RR' : 'UNRANKED');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: isActive ? Border.all(color: AppColors.primary, width: 2) : Border.all(color: Colors.white10),
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
                    child: cardIcon.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: cardIcon,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => _cardFallback(),
                          )
                        : _cardFallback(),
                  ),
                  if (level > 0)
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
                          '$level',
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            riotId,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                            ),
                          ),
                        ),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (rankTierIcon.isNotEmpty)
                          CachedNetworkImage(imageUrl: rankTierIcon, width: 20, height: 20)
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
                    if (!isActive && account.isTokenExpired) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Session expired (Re-auth on switch)',
                        style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive ? AppColors.primary.withValues(alpha: 0.2) : AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: isActive ? 0 : 2,
                    ),
                    onPressed: isActive ? null : () => onSelectAccount(account),
                    child: Text(
                      isActive ? 'Current Account' : (account.isTokenExpired ? 'Re-authenticate' : 'Switch Account'),
                      style: TextStyle(
                        color: isActive ? AppColors.primary : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  tooltip: 'Remove account',
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: () => onDeleteAccount(account),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardFallback() {
    return Container(
      width: 64,
      height: 64,
      color: AppColors.primary.withValues(alpha: 0.2),
      child: const Icon(Icons.person, color: AppColors.primary, size: 32),
    );
  }
}

