import 'package:dio/dio.dart';
import 'api_client.dart';
import '../dto/listing/listing_create_dto.dart';
import '../dto/listing/listing_dto.dart';
import '../dto/listing/listing_update_dto.dart';

class ListingService {
  final Dio _dio = ApiClient().dio;

  Future<List<ListingDto>> getCatalog({
    int? ownerId,
    String? q,
    double? minValue,
    double? maxValue,
  }) async {
    final response = await _dio.get(
      '/Listings/catalog',
      queryParameters: {
        if (ownerId != null) 'ownerId': ownerId,
        if (q != null) 'q': q,
        if (minValue != null) 'minValue': minValue,
        if (maxValue != null) 'maxValue': maxValue,
      },
    );
    return (response.data as List).map((e) => ListingDto.fromJson(e)).toList();
  }

  Future<ListingDto> getListingById(int id) async {
    final response = await _dio.get('/Listings/$id');
    return ListingDto.fromJson(response.data);
  }

  Future<void> createListing(ListingCreateDto dto) async {
    final formData = FormData.fromMap({
      'title': dto.title,
      'trueCoinValue': dto.trueCoinValue,
      'description': dto.description,
      'address': dto.address,
      'latitude': dto.latitude,
      'longitude': dto.longitude,
      // MODIFICADO: La clave (key) debe ser "ImageFile" para coincidir con el DTO de C#
      // MODIFICADO: Usamos dto.imagePath (la ruta local del archivo) en lugar de dto.imageUrl
      'ImageFile': await MultipartFile.fromFile(
        dto.imagePath,
        filename: 'upload.jpg', // El nombre de archivo es arbitrario
      ),
    });

    await _dio.post(
      '/Listings',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  Future<void> updateListing(int id, ListingUpdateDto dto) async {
    // NOTA: La actualización (update) también necesitaría ser adaptada 
    // para manejar 'ImageFile' si desea permitir cambiar la imagen.
    await _dio.put('/Listings/$id', data: dto.toJson());
  }

  Future<void> deleteListing(int id) async {
    await _dio.delete('/Listings/$id');
  }
}