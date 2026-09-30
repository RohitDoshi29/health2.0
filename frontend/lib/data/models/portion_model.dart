class PortionGuideModel {
  final String id;
  final String foodCanonicalName;
  final String label;
  final double grams;
  final String? imageAsset;

  const PortionGuideModel({
    required this.id,
    required this.foodCanonicalName,
    required this.label,
    required this.grams,
    this.imageAsset,
  });

  factory PortionGuideModel.fromJson(Map<String, dynamic> json) {
    return PortionGuideModel(
      id: json['id'] as String,
      foodCanonicalName: json['food_canonical_name'] as String,
      label: json['label'] as String,
      grams: (json['grams'] as num).toDouble(),
      imageAsset: json['image_asset'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'food_canonical_name': foodCanonicalName,
      'label': label,
      'grams': grams,
      'image_asset': imageAsset,
    };
  }
}
