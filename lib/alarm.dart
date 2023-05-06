class Alarm {
  final int id;
  final DateTime date;
  final List<int> daysToFire;
  final String message;
  final String soundPath;
  final bool isActive;

  Alarm({
    required this.id,
    required this.date,
    required this.message,
    required this.soundPath,
    required this.daysToFire,
    required this.isActive,
  });
}
