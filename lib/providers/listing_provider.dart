// lib/providers/listing_provider.dart
import 'package:flutter/material.dart';
import '../dto/listing/listing_dto.dart';
import '../dto/listing/listing_create_dto.dart';
import '../dto/listing/listing_update_dto.dart';
import '../services/listing_service.dart';

class ListingProvider extends ChangeNotifier {
  final ListingService _service = ListingService();

  List<ListingDto> listings = [];
  bool isLoading = false;

  ListingDto? selectedListing;

  Future<ListingDto> fetchListingById(int id) async {
    isLoading = true;
    notifyListeners();
    try {
      selectedListing = await _service.getListingById(id);
      return selectedListing!;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Fetch catalog
  Future<void> fetchCatalog({
    int? ownerId,
    String? q,
    double? minValue,
    double? maxValue,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      listings = await _service.getCatalog(
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

  // Create listing
  Future<void> createListing(ListingCreateDto dto) async {
    await _service.createListing(dto);
    await fetchCatalog(); // Refresh list
  }

  // Update listing
  Future<void> updateListing(int id, ListingUpdateDto dto) async {
    await _service.updateListing(id, dto);
    await fetchCatalog();
  }

  // Delete listing
  Future<void> deleteListing(int id) async {
    await _service.deleteListing(id);
    await fetchCatalog();
  }
}