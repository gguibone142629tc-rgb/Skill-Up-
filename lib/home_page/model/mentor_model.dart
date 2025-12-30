class Mentor {
  final String id;
  final String name;
  final String jobTitle;
  final String image;
  final double rating;
  final List<String> skills;
  final List<String> categories; // 1. Add this field
  final List<String> expertise; // NEW: include expertise so filtering can use it
  final String pricePerMonth;

  // Optional fields for membership plan data stored on the user document
  final String? planTitle;
  final int? planPrice;

  Mentor({
    required this.id,
    required this.name,
    required this.jobTitle,
    required this.image,
    required this.rating,
    required this.skills,
    required this.categories, // 2. Add to constructor
    required this.expertise, // NEW
    required this.pricePerMonth,
    this.planTitle,
    this.planPrice,
  });

  factory Mentor.fromFirestore(Map<String, dynamic> data, String id) {
    return Mentor(
      id: id,
      name: '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}',
      jobTitle: data['jobTitle'] ?? 'Mentor',
      image: data['profileImageUrl'] ?? '',
      rating: (data['rating'] ?? 5.0).toDouble(),
      skills: List<String>.from(data['skills'] ?? []),
      // 3. Fetch categories safely
      categories: List<String>.from(data['categories'] ?? []), 
      // 4. Fetch expertise safely
      expertise: List<String>.from(data['expertise'] ?? []),
      pricePerMonth: data['price'] ?? 'Free',
      planTitle: data['planTitle'] as String?,
      planPrice: data['price'] != null ? int.tryParse(data['price'].toString()) : null,
    );
  }
}