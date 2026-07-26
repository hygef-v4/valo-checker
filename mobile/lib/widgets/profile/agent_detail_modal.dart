import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../services/valorant_api_service.dart';
import '../../theme/app_colors.dart';

/// Bottom sheet with an agent's portrait, biography, and abilities.
class AgentDetailModal {
  static void show(BuildContext context, String agentUuid) {
    final agentData = ValorantApiService.getAgentFullData(agentUuid);
    if (agentData == null) return;

    final name = (agentData['displayName'] ?? 'Agent').toString();
    final description = (agentData['description'] ?? '').toString();
    final fullPortrait = (agentData['fullPortrait'] ?? agentData['displayIcon'] ?? '').toString();
    final roleName = (agentData['role']?['displayName'] ?? '').toString();
    final roleIcon = (agentData['role']?['displayIcon'] ?? '').toString();
    final abilities = (agentData['abilities'] as List? ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (roleIcon.isNotEmpty)
                      CachedNetworkImage(imageUrl: roleIcon, width: 24, height: 24)
                    else
                      const Icon(Icons.flash_on, color: AppColors.primary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      roleName.toUpperCase(),
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  name.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: 1.5),
                ),
                const SizedBox(height: 12),
                if (fullPortrait.isNotEmpty)
                  Center(
                    child: CachedNetworkImage(imageUrl: fullPortrait, height: 220, fit: BoxFit.contain),
                  ),
                const SizedBox(height: 16),
                if (description.isNotEmpty) ...[
                  const Text('BIOGRAPHY', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0)),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                ],
                const Text('ABILITIES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: abilities.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final ab = abilities[index];
                    final abName = (ab['displayName'] ?? 'Ability').toString();
                    final abDesc = (ab['description'] ?? '').toString();
                    final abIcon = (ab['displayIcon'] ?? '').toString();
                    final slot = (ab['slot'] ?? 'Ability').toString();

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                            child: abIcon.isNotEmpty
                                ? CachedNetworkImage(imageUrl: abIcon, fit: BoxFit.contain)
                                : const Icon(Icons.flash_on, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        abName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                                      child: Text(slot, style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(abDesc, style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.3)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
