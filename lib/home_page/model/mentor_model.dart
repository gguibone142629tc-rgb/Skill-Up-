class Mentor {
  final String id;
  final String name;
  final String jobTitle;
  final String image;
  final double rating;
  final List<String> skills;
  final String pricePerMonth;

  Mentor({
    required this.id,
    required this.name,
    required this.jobTitle,
    required this.image,
    required this.rating,
    required this.skills,
    required this.pricePerMonth,
  });

  // ADD THIS: Convert Firestore Document to Mentor object
  factory Mentor.fromFirestore(Map<String, dynamic> data, String id) {
    return Mentor(
      id: id,
      name: '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}',
      jobTitle: data['jobTitle'] ?? 'Mentor',
      image: data['profileImageUrl'] ?? '', // Use the URL if you have one
      rating: (data['rating'] ?? 5.0).toDouble(),
      skills: List<String>.from(data['skills'] ?? []),
      pricePerMonth: data['price'] ?? 'Free',
    );
  }
}
