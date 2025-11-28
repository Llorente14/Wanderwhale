// lib/models/destination_master_model.dart

class DestinationMasterModel {
  final String destinationId;
  final String name;
  final String country;
  final String city;
  final String continent;
  final String description;
  final String imageUrl;
  final List<String> images;
  final double rating;
  final int reviewsCount;
  final double averageBudget;
  final bool isPopular;
  final List<String> tags;
  final List<PopularActivityModel> popularActivities;

  DestinationMasterModel({
    required this.destinationId,
    required this.name,
    required this.country,
    required this.city,
    required this.continent,
    required this.description,
    required this.imageUrl,
    required this.images,
    required this.rating,
    required this.reviewsCount,
    required this.averageBudget,
    required this.isPopular,
    required this.tags,
    required this.popularActivities,
  });

  // From JSON (Data dari Firestore)
  factory DestinationMasterModel.fromJson(
    String id,
    Map<String, dynamic> json,
  ) {
    return DestinationMasterModel(
      destinationId: id, // Ambil ID dokumen
      name: json['name'] ?? '',
      country: json['country'] ?? '',
      city: json['city'] ?? '',
      continent: json['continent'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewsCount: json['reviewsCount'] ?? 0,
      averageBudget: (json['averageBudget'] ?? 0.0).toDouble(),
      isPopular: json['isPopular'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      popularActivities:
          (json['popularActivities'] as List<dynamic>?)
              ?.map(
                (activityJson) => PopularActivityModel.fromJson(
                  activityJson as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'country': country,
      'city': city,
      'continent': continent,
      'description': description,
      'imageUrl': imageUrl,
      'images': images,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'averageBudget': averageBudget,
      'isPopular': isPopular,
      'tags': tags,
      'popularActivities': popularActivities
          .map((activity) => activity.toJson())
          .toList(),
    };
  }
}

// Sub-model untuk aktivitas populer
class PopularActivityModel {
  final String name;
  final String description;
  final String imageUrl;

  PopularActivityModel({
    required this.name,
    required this.description,
    required this.imageUrl,
  });

  factory PopularActivityModel.fromJson(Map<String, dynamic> json) {
    return PopularActivityModel(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'description': description, 'imageUrl': imageUrl};
  }
}
