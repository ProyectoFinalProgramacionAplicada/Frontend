import 'package:flutter/foundation.dart';
import '../services/listing_service.dart';
import '../dto/listing/listing_dto.dart';

class ActiveUserSummary {
  final int userId;
  final String displayName;
  final String? avatarUrl;
  final double averageRating;
  final int listingCount;

  ActiveUserSummary({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.averageRating,
    required this.listingCount,
  });
}

class AdminProvider with ChangeNotifier {
  final ListingService _listingService = ListingService();

  bool _isLoading = false;
  List<ActiveUserSummary> _activeUsers = [];
  // keep raw listings in memory so admin widgets can compute histograms and other metrics
  List<ListingDto> _listings = [];

  // Additional aggregated metrics
  int _totalListings = 0;
  int _activeListingsCount = 0;
  int _uniqueUsersCount = 0;
  double _totalTrueCoinsActive = 0.0;
  double _avgTrueCoinsPerListing = 0.0;

  bool get isLoading => _isLoading;
  List<ActiveUserSummary> get activeUsers => List.unmodifiable(_activeUsers);

  /// Devuelve las publicaciones completas cargadas en memoria filtradas por ownerUserId
  List<ListingDto> getListingsForUser(int userId) {
    return List.unmodifiable(
      _listings.where((l) => l.ownerUserId == userId).toList(),
    );
  }

  // New getters for metrics
  int get totalListings => _totalListings;
  int get activeListingsCount => _activeListingsCount;
  int get inactiveListingsCount => _totalListings - _activeListingsCount;
  int get uniqueUsersCount => _uniqueUsersCount;
  double get totalTrueCoinsActive => _totalTrueCoinsActive;
  double get avgTrueCoinsPerListing => _avgTrueCoinsPerListing;

  /// Histogram grouping of TrueCoin values into fixed buckets.
  /// Keys: '0-100', '101-500', '501-1000', '>1000'
  Map<String, int> get trueCoinHistogram {
    final Map<String, int> hist = {
      '0-100': 0,
      '101-500': 0,
      '501-1000': 0,
      '>1000': 0,
    };
    for (final l in _listings) {
      final v = l.trueCoinValue;
      if (v <= 100) {
        hist['0-100'] = hist['0-100']! + 1;
      } else if (v <= 500) {
        hist['101-500'] = hist['101-500']! + 1;
      } else if (v <= 1000) {
        hist['501-1000'] = hist['501-1000']! + 1;
      } else {
        hist['>1000'] = hist['>1000']! + 1;
      }
    }
    return hist;
  }

  // Top lists
  List<ActiveUserSummary> get topUsersByListings => List.unmodifiable(
    List.from(_activeUsers)
      ..sort((a, b) => b.listingCount.compareTo(a.listingCount)),
  );
  List<ActiveUserSummary> get topUsersByRating => List.unmodifiable(
    List.from(_activeUsers)
      ..sort((a, b) => b.averageRating.compareTo(a.averageRating)),
  );

  // Statistics
  double get averageRating {
    final rated = _activeUsers.where((u) => u.averageRating > 0).toList();
    if (rated.isEmpty) return 0.0;
    final sum = rated.fold<double>(0.0, (p, e) => p + e.averageRating);
    return sum / rated.length;
  }

  int get usersWithRating =>
      _activeUsers.where((u) => u.averageRating > 0).length;

  /// Distribution keyed by stars 1..5
  Map<int, int> get ratingDistribution {
    final Map<int, int> dist = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final u in _activeUsers) {
      final r = u.averageRating;
      if (r <= 0) continue;
      var key = r.round();
      if (key < 1) key = 1;
      if (key > 5) key = 5;
      dist[key] = (dist[key] ?? 0) + 1;
    }
    return dist;
  }

  Future<void> loadActiveUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final listings = await _listingService.getCatalog();
      // keep raw listings in provider memory for histogram and other derived metrics
      _listings = List<ListingDto>.from(listings);

      // Group listings by ownerUserId
      final Map<int, List<ListingDto>> grouped = {};
      for (final l in listings) {
        grouped.putIfAbsent(l.ownerUserId, () => []).add(l);
      }

      final List<ActiveUserSummary> summaries = [];
      // reset aggregates
      var totalListingsLocal = 0;
      var activeListingsLocal = 0;
      double totalTrueCoinsActiveLocal = 0.0;

      grouped.forEach((userId, list) {
        final displayName = list.first.ownerName ?? 'Usuario $userId';
        final avatar = list.first.ownerAvatarUrl;
        // average ownerRating across this user's listings (ownerRating may be repeated)
        final average =
            list.fold<double>(0.0, (p, e) => p + (e.ownerRating)) / list.length;
        summaries.add(
          ActiveUserSummary(
            userId: userId,
            displayName: displayName,
            avatarUrl: avatar,
            averageRating: double.parse(average.toStringAsFixed(2)),
            listingCount: list.length,
          ),
        );

        // aggregate counts
        totalListingsLocal += list.length;
        for (final l in list) {
          if (l.isPublished) {
            activeListingsLocal += 1;
            totalTrueCoinsActiveLocal += (l.trueCoinValue);
          }
        }
      });

      // Sort by listing count desc, then rating desc
      summaries.sort((a, b) {
        final c = b.listingCount.compareTo(a.listingCount);
        if (c != 0) return c;
        return b.averageRating.compareTo(a.averageRating);
      });

      _activeUsers = summaries;

      // set aggregated fields
      _totalListings = totalListingsLocal;
      _activeListingsCount = activeListingsLocal;
      _uniqueUsersCount = _activeUsers.length;
      _totalTrueCoinsActive = double.parse(
        totalTrueCoinsActiveLocal.toStringAsFixed(2),
      );
      _avgTrueCoinsPerListing = activeListingsLocal > 0
          ? double.parse(
              (totalTrueCoinsActiveLocal / activeListingsLocal).toStringAsFixed(
                2,
              ),
            )
          : 0.0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
