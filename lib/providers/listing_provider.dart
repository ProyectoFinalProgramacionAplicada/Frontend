// lib/providers/listing_provider.dart
import 'package:flutter/material.dart';
import '../dto/listing/listing_dto.dart';
import '../dto/listing/listing_create_dto.dart';
import '../dto/listing/listing_update_dto.dart';
import '../services/listing_service.dart';

class ListingProvider extends ChangeNotifier {
  // CORRECCIÓN: Usamos un nombre descriptivo consistente
  final ListingService _listingService = ListingService();

  List<ListingDto> listings = [];
  List<ListingDto> nearbyListings = [];
  bool isLoading = false;
  bool isLoadingNearby = false;

  ListingDto? selectedListing;

  // Obtener un producto por ID
  Future<ListingDto> fetchListingById(int id) async {
    isLoading = true;
    notifyListeners();
    try {
      selectedListing = await _listingService.getListingById(id);
      return selectedListing!;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Obtener el catálogo (feed principal)
  Future<void> fetchCatalog({
    int? ownerId,
    String? q,
    double? minValue,
    double? maxValue,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      listings = await _listingService.getCatalog(
        ownerId: ownerId,
        q: q,
        minValue: minValue,
        maxValue: maxValue,
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Nuevo método: fetch nearby listings
  Future<void> fetchNearbyListings({
    required double latitude,
    required double longitude,
    double radius = 25.0,
  }) async {
    isLoadingNearby = true;
    notifyListeners();
    try {
      nearbyListings = await _listingService.getNearbyListings(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      );
    } catch (e) {
      // No queremos que un fallo en nearby afecte al estado global del catálogo
      debugPrint('Error fetching nearby listings: $e');
      rethrow;
    } finally {
      isLoadingNearby = false;
      notifyListeners();
    }
  }

  // Crear publicación
  Future<void> createListing(ListingCreateDto dto) async {
    await _listingService.createListing(dto);
    await fetchCatalog(); // Refrescar la lista después de crear
  }

  // Actualizar publicación
  Future<void> updateListing(int id, ListingUpdateDto dto) async {
    await _listingService.updateListing(id, dto);
    await fetchCatalog();
  }

  // Eliminar publicación
  Future<void> deleteListing(int id) async {
    await _listingService.deleteListing(id);
    await fetchCatalog();
  }

  // --- NUEVO MÉTODO PARA EL PERFIL DEL VENDEDOR ---
  // Retorna la lista directamente sin modificar el estado global 'listings'
  // para no afectar el feed principal cuando ves un perfil.
  Future<List<ListingDto>> getListingsByOwner(int ownerId) async {
    try {
      // Ahora sí coincide el nombre de la variable
      final result = await _listingService.getCatalog(ownerId: ownerId);
      return result;
    } catch (e) {
      debugPrint("Error fetching owner listings: $e");
      rethrow;
    }
  }
}
