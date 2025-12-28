enum SessionStatus { upcoming, completed, cancelled }

class Session {
  final String name;
  final String role;
  final String date;
  final String time;
  final String imagePath; // Local asset path
  final SessionStatus status;

  Session({
    required this.name,
    required this.role,
    required this.date,
    required this.time,
    required this.imagePath,
    required this.status,
  });
}