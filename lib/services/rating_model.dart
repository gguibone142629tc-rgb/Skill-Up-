class MentorRating {
  final String id;
  final String mentorId;
  final String studentId;
  final String studentName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  MentorRating({
    required this.id,
    required this.mentorId,
    required this.studentId,
    required this.studentName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'mentorId': mentorId,
      'studentId': studentId,
      'studentName': studentName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MentorRating.fromMap(String id, Map<String, dynamic> map) {
    DateTime createdAt;
    try {
      // Try parsing as ISO string
      createdAt = DateTime.parse(map['createdAt']);
    } catch (e) {
      // Fallback to current time if parsing fails
      createdAt = DateTime.now();
    }
    
    return MentorRating(
      id: id,
      mentorId: map['mentorId'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: createdAt,
    );
  }
}
