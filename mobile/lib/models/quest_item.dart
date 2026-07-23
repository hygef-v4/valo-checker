class QuestItem {
  final String title;
  final String description;
  final int currentProgress;
  final int targetProgress;
  final int rewardXP;
  final bool isCompleted;

  QuestItem({
    required this.title,
    required this.description,
    required this.currentProgress,
    required this.targetProgress,
    required this.rewardXP,
    required this.isCompleted,
  });
}
