class MembershipPlan {
  final String title;
  final String callDetails;
  final List<String> features;
  final int price;

  const MembershipPlan({
    required this.title,
    required this.callDetails,
    required this.features,
    required this.price,
  });

  // Default static plans used across the app
  static const List<MembershipPlan> defaultPlans = [
    MembershipPlan(
      title: "Growth Starter",
      callDetails: "1x 45-min call per month",
      features: ["Basic email support"],
      price: 1200,
    ),
    MembershipPlan(
      title: "Career Accelerator",
      callDetails: "4x 30-min call per month",
      features: ["Priority in-app messaging", "Document Review"],
      price: 2500,
    ),
    MembershipPlan(
      title: "Executive Elite",
      callDetails: "Unlimited calls",
      features: ["Direct chat access", "Resume/ Profile optimization"],
      price: 4000,
    ),
  ];

  // Default fallback starting price
  static const int defaultStartingPrice = 1200;

  // Returns the price for a plan title (case-insensitive). If not found, returns the default starting price.
  static int getPriceForTitle(String? title) {
    if (title == null || title.isEmpty) return defaultStartingPrice;
    try {
      final match = defaultPlans.firstWhere((p) => p.title.toLowerCase() == title.toLowerCase());
      return match.price;
    } catch (e) {
      return defaultStartingPrice;
    }
  }
}