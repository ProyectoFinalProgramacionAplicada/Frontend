import 'dart:typed_data';

class ListingCreateDto {
  final String title;
  final double trueCoinValue;
  final String? description;
  final String? address;
  final double latitude;
  final double longitude;

  /// NUEVO: en vez de `imagePath`, utilizamos los bytes de la imagen
  final Uint8List imageBytes;

  /// NUEVO: nombre del archivo a enviar al backend
  final String imageFileName;

  ListingCreateDto({
    required this.title,
    required this.trueCoinValue,
    this.description,
    this.address,
    required this.latitude,
    required this.longitude,

    /// reemplaza a imagePath
    required this.imageBytes,
    required this.imageFileName,
  });

  factory ListingCreateDto.fromJson(Map<String, dynamic> json) {
    return ListingCreateDto(
      title: json['title'],
      trueCoinValue: (json['trueCoinValue'] as num).toDouble(),
      description: json['description'],
      address: json['address'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),

      /// NO EXISTE manera de reconstruir bytes desde JSON,
      /// así que dejamos valores por defecto (esto solo sería útil si realmente lo necesitas)
      imageBytes: Uint8List(0),
      imageFileName: json['imageFileName'] ?? 'image.jpg',
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'trueCoinValue': trueCoinValue,
    'description': description,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,

    /// Los bytes NO se envían como JSON, solo se usan en multipart.
    /// Este campo queda para depuración o consistencia.
    'imageFileName': imageFileName,
  };
}
