class ListingDto {
  final int id;
  final String title;
  final double trueCoinValue;
  final bool isPublished;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final String? description;
  
  // Datos del Vendedor
  final int ownerUserId;
  final String? ownerName;
  final String? ownerAvatarUrl; // <--- Nuevo
  final double ownerRating;     // <--- Nuevo

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
      
      // Mapeo robusto del vendedor
      ownerUserId: json['ownerUserId'],
      ownerName: json['ownerName'],
      ownerAvatarUrl: json['ownerAvatarUrl'], 
      ownerRating: (json['ownerRating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Si usas toJson en algún lado, actualízalo también
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
    'ownerRating': ownerRating,
  };
}