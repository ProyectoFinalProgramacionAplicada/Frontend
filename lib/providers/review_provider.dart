// lib/providers/review_provider.dart
import 'package:flutter/material.dart';
import '../dto/review/user_review_dto.dart';
import '../dto/review/user_review_create_dto.dart';
import '../services/review_service.dart';

class ReviewProvider extends ChangeNotifier {
  final ReviewService _service = ReviewService();

  List<UserReviewDto> reviews = [];
  bool isLoading = false;

  Future<void> fetchUserReviews(int userId) async {
    isLoading = true;
    notifyListeners();

    try {
      reviews = await _service.getUserReviews(userId);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- NUEVO MÉTODO: Para el Perfil Público ---
  Future<List<UserReviewDto>> getReviewsByUser(int userId) async {
    try {
      return await _service.getUserReviews(userId);
    } catch (e) {
      print("Error fetching reviews: $e");
      rethrow;
    }
  }

  Future<void> createReview(UserReviewCreateDto dto) async {
    await _service.createReview(dto);
    await fetchUserReviews(dto.toUserId);
  }
}
