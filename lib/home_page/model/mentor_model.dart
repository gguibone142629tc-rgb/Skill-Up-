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
  final String? plan1Title; // Growth Starter (Plan 1) title
  final int? plan1Price; // Growth Starter (Plan 1) price

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
    this.plan1Title,
    this.plan1Price,
  });

  factory Mentor.fromFirestore(Map<String, dynamic> data, String id) {
    int? parsePrice(dynamic value) {
      if (value == null) return null;
      final digits = value.toString().replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isEmpty) return null;
      return int.tryParse(digits);
    }

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
      pricePerMonth: (data['price'] ?? 'Free').toString(),
      planTitle: data['planTitle']?.toString(),
      planPrice: parsePrice(data['price']),
      plan1Title: data['plan_Growth_Starter_title']?.toString(),
      plan1Price: parsePrice(data['plan_Growth_Starter_price']),
    );
  }
}