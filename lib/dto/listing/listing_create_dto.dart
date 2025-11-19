class ListingCreateDto {
  final String title;
  // MODIFICADO: Cambiamos de imageUrl a imagePath para reflejar que es una ruta local.
  final String imagePath;
  final double trueCoinValue;
  final String? description;
  final String? address;
  final double latitude;
  final double longitude;

  ListingCreateDto({
    required this.title,
    required this.imagePath, // MODIFICADO
    required this.trueCoinValue,
    this.description,
    this.address,
    required this.latitude,
    required this.longitude,
  });

  factory ListingCreateDto.fromJson(Map<String, dynamic> json) {
    return ListingCreateDto(
      title: json['title'],
      // MODIFICADO: Asumimos que el JSON de entrada (si lo hubiera) también usaría imagePath
      imagePath: json['imagePath'], 
      trueCoinValue: (json['trueCoinValue'] as num).toDouble(),
      description: json['description'],
      address: json['address'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    // MODIFICADO:
    'imagePath': imagePath, 
    'trueCoinValue': trueCoinValue,
    'description': description,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
  };
}