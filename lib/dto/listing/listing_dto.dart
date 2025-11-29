class ListingDto {
  final int id;
  final String title;
  final double trueCoinValue;
  final bool isPublished;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final String? description;

  // Datos del Vendedor (displayName del backend)
  final int ownerUserId;
  final String? ownerName; // displayName del vendedor
  final String? ownerAvatarUrl;
  final String? ownerPhone; // Teléfono E.164 del vendedor
  final double ownerRating;

  ListingDto({
    required this.id,
    required this.title,
    required this.trueCoinValue,
    required this.isPublished,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    this.description,
    required this.ownerUserId,
    this.ownerName,
    this.ownerAvatarUrl,
    this.ownerPhone,
    this.ownerRating = 0.0,
  });

  factory ListingDto.fromJson(Map<String, dynamic> json) {
    return ListingDto(
      id: json['id'],
      title: json['title'],
      trueCoinValue: (json['trueCoinValue'] as num).toDouble(),
      isPublished: json['isPublished'],
      imageUrl: json['imageUrl'] ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      description: json['description'],

      // Mapeo robusto del vendedor - acepta displayName o name
      ownerUserId: json['ownerUserId'],
      ownerName: json['ownerDisplayName'] ?? json['ownerName'],
      ownerAvatarUrl: json['ownerAvatarUrl'],
      ownerPhone: json['ownerPhone'],
      ownerRating: (json['ownerRating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'trueCoinValue': trueCoinValue,
    'isPublished': isPublished,
    'imageUrl': imageUrl,
    'latitude': latitude,
    'longitude': longitude,
    'description': description,
    'ownerUserId': ownerUserId,
    'ownerName': ownerName,
    'ownerAvatarUrl': ownerAvatarUrl,
    'ownerPhone': ownerPhone,
    'ownerRating': ownerRating,
  };
}
