// lib/dto/admin/admin_metrics_dto.dart

/// DTO para las estadísticas del panel de administración
/// Mapeado desde GET /api/admin/stats
class AdminStatsDto {
  final int totalUsers;
  final int activeUsers;
  final int inactiveUsers;
  final int newUsersLast7Days;
  final int totalTrades;
  final int completedTrades;
  final int cancelledTrades;
  final double completionRate; // Porcentaje (ej: 12.12)
  final double avgClosureTimeHours;
  final int totalListings;
  final int publishedListings;
  final DateTime? generatedAt;

  AdminStatsDto({
    required this.totalUsers,
    required this.activeUsers,
    required this.inactiveUsers,
    required this.newUsersLast7Days,
    required this.totalTrades,
    required this.completedTrades,
    required this.cancelledTrades,
    required this.completionRate,
    required this.avgClosureTimeHours,
    required this.totalListings,
    required this.publishedListings,
    this.generatedAt,
  });

  factory AdminStatsDto.fromJson(Map<String, dynamic> json) {
    return AdminStatsDto(
      totalUsers: json['totalUsers'] ?? 0,
      activeUsers: json['activeUsers'] ?? 0,
      inactiveUsers: json['inactiveUsers'] ?? 0,
      newUsersLast7Days: json['newUsersLast7Days'] ?? 0,
      totalTrades: json['totalTrades'] ?? 0,
      completedTrades: json['completedTrades'] ?? 0,
      cancelledTrades: json['cancelledTrades'] ?? 0,
      completionRate: (json['completionRate'] ?? 0).toDouble(),
      avgClosureTimeHours: (json['avgClosureTimeHours'] ?? 0).toDouble(),
      totalListings: json['totalListings'] ?? 0,
      publishedListings: json['publishedListings'] ?? 0,
      generatedAt: json['generatedAt'] != null
          ? DateTime.tryParse(json['generatedAt'])
          : null,
    );
  }

  factory AdminStatsDto.empty() {
    return AdminStatsDto(
      totalUsers: 0,
      activeUsers: 0,
      inactiveUsers: 0,
      newUsersLast7Days: 0,
      totalTrades: 0,
      completedTrades: 0,
      cancelledTrades: 0,
      completionRate: 0,
      avgClosureTimeHours: 0,
      totalListings: 0,
      publishedListings: 0,
    );
  }

  /// Publicaciones inactivas (no publicadas)
  int get unpublishedListings => totalListings - publishedListings;

  /// Trades pendientes (no completados ni cancelados)
  int get pendingTrades => totalTrades - completedTrades - cancelledTrades;
}

/// DTO para usuario de administración
/// Mapeado desde GET /api/admin/users
class AdminUserDto {
  final int id;
  final String? displayName;
  final String email;
  final int role; // 0 = User, 2 = Admin
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final double trueCoinBalance;

  AdminUserDto({
    required this.id,
    this.displayName,
    required this.email,
    required this.role,
    required this.isActive,
    this.createdAt,
    this.lastLoginAt,
    required this.trueCoinBalance,
  });

  factory AdminUserDto.fromJson(Map<String, dynamic> json) {
    return AdminUserDto(
      id: json['id'] ?? 0,
      displayName: json['displayName'],
      email: json['email'] ?? '',
      role: json['role'] ?? 0,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.tryParse(json['lastLoginAt'])
          : null,
      trueCoinBalance: (json['trueCoinBalance'] ?? 0).toDouble(),
    );
  }

  /// Nombre a mostrar (displayName o email antes del @)
  String get name => displayName ?? email.split('@').first;

  /// Es administrador
  bool get isAdmin => role == 0;

  /// Días desde registro
  int get daysSinceRegistration {
    if (createdAt == null) return 0;
    return DateTime.now().difference(createdAt!).inDays;
  }
}

/// DTO para trade de administración
/// Mapeado desde GET /api/admin/trades
class AdminTradeDto {
  final int id;
  final int targetListingId;
  final int requesterUserId;
  final int ownerUserId;
  final int status; // 0=Pending, 3=Completed, 4=Cancelled
  final DateTime? createdAt;
  final DateTime? completedAt;
  final String? targetListingTitle;
  final double targetListingValue;

  AdminTradeDto({
    required this.id,
    required this.targetListingId,
    required this.requesterUserId,
    required this.ownerUserId,
    required this.status,
    this.createdAt,
    this.completedAt,
    this.targetListingTitle,
    required this.targetListingValue,
  });

  factory AdminTradeDto.fromJson(Map<String, dynamic> json) {
    return AdminTradeDto(
      id: json['id'] ?? 0,
      targetListingId: json['targetListingId'] ?? 0,
      requesterUserId: json['requesterUserId'] ?? 0,
      ownerUserId: json['ownerUserId'] ?? 0,
      status: json['status'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'])
          : null,
      targetListingTitle: json['targetListingTitle'],
      targetListingValue: (json['targetListingValue'] ?? 0).toDouble(),
    );
  }

  /// Estado legible
  String get statusName {
    switch (status) {
      case 0:
        return 'Pendiente';
      case 3:
        return 'Completado';
      case 4:
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  bool get isPending => status == 0;
  bool get isCompleted => status == 3;
  bool get isCancelled => status == 4;
}

/// DTO para actividad de wallet
/// Mapeado desde GET /api/admin/wallet-activity
class WalletActivityDto {
  final int id;
  final int userId;
  final String? userName;
  final double amount;
  final int type; // 2 = AdminAdjustment
  final String? refType;
  final DateTime? createdAt;

  WalletActivityDto({
    required this.id,
    required this.userId,
    this.userName,
    required this.amount,
    required this.type,
    this.refType,
    this.createdAt,
  });

  factory WalletActivityDto.fromJson(Map<String, dynamic> json) {
    return WalletActivityDto(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      userName: json['userName'],
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] ?? 0,
      refType: json['refType'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  String get typeName {
    switch (type) {
      case 2:
        return 'Ajuste Admin';
      default:
        return 'Otro';
    }
  }
}

// ====== DTOs auxiliares (mantener compatibilidad) ======

/// Entrada para la tendencia de usuarios activos diarios
class DailyActiveUsersEntry {
  final DateTime date;
  final int count;

  DailyActiveUsersEntry({required this.date, required this.count});

  factory DailyActiveUsersEntry.fromJson(Map<String, dynamic> json) {
    return DailyActiveUsersEntry(
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      count: json['count'] ?? 0,
    );
  }

  /// Formato corto del día (ej: "Lun", "Mar")
  String get dayShort {
    const days = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    return days[date.weekday % 7];
  }

  /// Formato con día del mes (ej: "25")
  String get dayNumber => date.day.toString();
}

/// Distribución de tipos de publicaciones/trades
class ListingTypeDistribution {
  final int productOnly; // Solo producto
  final int trueCoinOnly; // Solo TrueCoins
  final int hybrid; // Producto + TrueCoins

  ListingTypeDistribution({
    required this.productOnly,
    required this.trueCoinOnly,
    required this.hybrid,
  });

  factory ListingTypeDistribution.fromJson(Map<String, dynamic> json) {
    return ListingTypeDistribution(
      productOnly: json['productOnly'] ?? 0,
      trueCoinOnly: json['trueCoinOnly'] ?? json['trueCoinsOnly'] ?? 0,
      hybrid: json['hybrid'] ?? 0,
    );
  }

  factory ListingTypeDistribution.empty() {
    return ListingTypeDistribution(productOnly: 0, trueCoinOnly: 0, hybrid: 0);
  }

  int get total => productOnly + trueCoinOnly + hybrid;

  double get productOnlyPct => total > 0 ? productOnly / total : 0;
  double get trueCoinOnlyPct => total > 0 ? trueCoinOnly / total : 0;
  double get hybridPct => total > 0 ? hybrid / total : 0;
}

/// Entrada para top usuarios
class TopUserEntry {
  final int userId;
  final String displayName;
  final String? avatarUrl;
  final int count; // cantidad de trades o listings según contexto
  final double? rating;

  TopUserEntry({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.count,
    this.rating,
  });

  factory TopUserEntry.fromJson(Map<String, dynamic> json) {
    return TopUserEntry(
      userId: json['userId'] ?? 0,
      displayName: json['displayName'] ?? json['userName'] ?? 'Usuario',
      avatarUrl: json['avatarUrl'],
      count: json['count'] ?? json['tradeCount'] ?? json['listingCount'] ?? 0,
      rating: (json['rating'] ?? json['averageRating'])?.toDouble(),
    );
  }
}
