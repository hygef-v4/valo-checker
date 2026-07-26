import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../services/valorant_api_service.dart';
import '../../theme/app_colors.dart';
import 'agent_detail_modal.dart';

class AgentsTab extends StatelessWidget {
  final Set<String> ownedAgents;
  final int selectedIndex;
  final ValueChanged<int> onAgentSelected;

  const AgentsTab({
    super.key,
    required this.ownedAgents,
    required this.selectedIndex,
    required this.onAgentSelected,
  });

  @override
  Widget build(BuildContext context) {
    final agentsList = ValorantApiService.getPlayableAgentsList(ownedAgents);

    if (agentsList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            'Agent data is unavailable. Pull down to refresh.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    final activeIndex = selectedIndex < agentsList.length ? selectedIndex : 0;
    final activeAgent = agentsList[activeIndex];
    final isOwned = activeAgent['isOwned'] as bool? ?? false;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GestureDetector(
          onTap: () => AgentDetailModal.show(context, activeAgent['uuid']),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (activeAgent['displayName'] as String).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isOwned ? Icons.check_circle : Icons.lock,
                      color: isOwned ? AppColors.success : Colors.redAccent,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOwned ? 'Owned' : 'Locked',
                      style: TextStyle(
                        color: isOwned ? AppColors.success : Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if ((activeAgent['fullPortrait'] as String).isNotEmpty)
                  Center(
                    child: CachedNetworkImage(
                      imageUrl: activeAgent['fullPortrait'],
                      height: 260,
                      fit: BoxFit.contain,
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.flash_on, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            activeAgent['roleName'] as String,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'TAP FOR ABILITIES & LORE ➔',
                      style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: agentsList.length,
            itemBuilder: (context, index) {
              final a = agentsList[index];
              final isSelected = index == activeIndex;
              final agentOwned = a['isOwned'] as bool? ?? false;

              return GestureDetector(
                onTap: () => onAgentSelected(index),
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CachedNetworkImage(
                          imageUrl: a['displayIcon'],
                          width: 80,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            agentOwned ? Icons.check : Icons.lock,
                            color: agentOwned ? AppColors.success : Colors.white54,
                            size: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
