import 'package:flutter/foundation.dart';
import '../services/listing_service.dart';
import '../services/admin_service.dart';
import '../dto/listing/listing_dto.dart';
import '../dto/admin/admin_metrics_dto.dart';

class ActiveUserSummary {
  final int userId;
  final String displayName;
  final String? avatarUrl;
  final double averageRating;
  final int listingCount;
  final int tradeCount;

  ActiveUserSummary({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.averageRating,
    required this.listingCount,
    this.tradeCount = 0,
  });
}

class AdminProvider with ChangeNotifier {
  final ListingService _listingService = ListingService();
  final AdminService _adminService = AdminService();

  bool _isLoading = false;
  bool _isLoadingMetrics = false;
  List<ActiveUserSummary> _activeUsers = [];
  // keep raw listings in memory so admin widgets can compute histograms and other metrics
  List<ListingDto> _listings = [];

  // Métricas del backend (nuevos DTOs que coinciden con la API real)
  AdminStatsDto _stats = AdminStatsDto.empty();
  List<AdminUserDto> _adminUsers = [];
  List<AdminTradeDto> _adminTrades = [];
  List<WalletActivityDto> _walletActivities = [];

  // Additional aggregated metrics
  int _totalListings = 0;
  int _activeListingsCount = 0;
  int _uniqueUsersCount = 0;
  double _totalTrueCoinsActive = 0.0;
  double _avgTrueCoinsPerListing = 0.0;

  bool get isLoading => _isLoading;
  bool get isLoadingMetrics => _isLoadingMetrics;
  List<ActiveUserSummary> get activeUsers => List.unmodifiable(_activeUsers);

  // Getters para las nuevas métricas del backend (desde AdminStatsDto)
  AdminStatsDto get stats => _stats;
  int get totalUsers => _stats.totalUsers;
  int get activeUsersCount => _stats.activeUsers;
  int get inactiveUsersCount => _stats.inactiveUsers;
  int get newUsersLast7Days => _stats.newUsersLast7Days;
  int get activeUsersLast7Days =>
      _stats.newUsersLast7Days; // Alias para compatibilidad con UI
  int get totalTrades => _stats.totalTrades;
  int get completedTrades => _stats.completedTrades;
  int get cancelledTrades => _stats.cancelledTrades;
  double get completionRate =>
      _stats.completionRate; // Ya viene como porcentaje (ej: 12.12)
  double get avgClosureTimeHours => _stats.avgClosureTimeHours;
  int get backendTotalListings => _stats.totalListings;
  int get publishedListings => _stats.publishedListings;

  // Getters para usuarios y trades del admin
  List<AdminUserDto> get adminUsers => List.unmodifiable(_adminUsers);
  List<AdminTradeDto> get adminTrades => List.unmodifiable(_adminTrades);
  List<WalletActivityDto> get walletActivities =>
      List.unmodifiable(_walletActivities);

  // Compatibilidad con código anterior (usando valores vacíos o derivados)
  List<DailyActiveUsersEntry> get dailyActiveUsersTrend => [];
  double get tradeCompletionRate =>
      _stats.completionRate / 100; // Convertir a decimal para compatibilidad
  double get averageTradeCompletionTimeHours => _stats.avgClosureTimeHours;
  int get tradesLast30Days => _stats.totalTrades;
  double get tradeAcceptRejectRatio => _stats.cancelledTrades > 0
      ? _stats.completedTrades / _stats.cancelledTrades
      : _stats.completedTrades.toDouble();
  double get totalTrueCoinVolume => _totalTrueCoinsActive;
  ListingTypeDistribution get listingTypeDistribution =>
      ListingTypeDistribution(
        productOnly: _stats.publishedListings,
        trueCoinOnly: 0,
        hybrid: 0,
      );
  List<TopUserEntry> get topUsersByTrades => [];
  List<TopUserEntry> get topUsersByListingsFromBackend => [];

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

  /// Carga las métricas avanzadas desde el backend
  Future<void> loadMetrics() async {
    _isLoadingMetrics = true;
    notifyListeners();
    try {
      // Cargar estadísticas desde el endpoint correcto /Admin/stats
      _stats = await _adminService.getStats();

      // Cargar usuarios y trades para datos adicionales
      _adminUsers = await _adminService.getUsers();
      _adminTrades = await _adminService.getTrades();

      // Opcionalmente cargar actividad de wallet
      try {
        _walletActivities = await _adminService.getWalletActivity();
      } catch (e) {
        _walletActivities = [];
      }
    } catch (e) {
      // Si falla, mantenemos las métricas vacías
      _stats = AdminStatsDto.empty();
      _adminUsers = [];
      _adminTrades = [];
      _walletActivities = [];
    } finally {
      _isLoadingMetrics = false;
      notifyListeners();
    }
  }

  /// Carga todos los datos del admin (usuarios activos + métricas)
  Future<void> loadAllData() async {
    _isLoading = true;
    _isLoadingMetrics = true;
    notifyListeners();

    // Cargar en paralelo
    await Future.wait([loadActiveUsers(), loadMetrics()]);
  }

  /// Formatea el tiempo promedio de cierre de trades
  String get formattedAvgCompletionTime {
    final hours = averageTradeCompletionTimeHours;
    if (hours < 1) {
      return '${(hours * 60).toStringAsFixed(0)} min';
    } else if (hours < 24) {
      return '${hours.toStringAsFixed(1)} hrs';
    } else {
      final days = hours / 24;
      return '${days.toStringAsFixed(1)} días';
    }
  }

  /// Formatea la tasa de completado como porcentaje (el backend ya lo devuelve como porcentaje)
  String get formattedCompletionRate {
    return '${completionRate.toStringAsFixed(1)}%';
  }

  /// Formatea el ratio aceptados/rechazados
  String get formattedAcceptRejectRatio {
    if (tradeAcceptRejectRatio == 0) return '0:1';
    if (tradeAcceptRejectRatio.isInfinite) return '∞:1';
    return '${tradeAcceptRejectRatio.toStringAsFixed(1)}:1';
  }
}
