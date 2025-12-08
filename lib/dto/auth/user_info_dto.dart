import 'app_role.dart';

class UserInfoDto {
  final int id;
  final String? email;
  final AppRole role;
  final int? companyId;
  final double trueCoinBalance;
  // --- NUEVOS CAMPOS ---
  final String? displayName;
  final String? phone;
  final String? avatarUrl;

  UserInfoDto({
    required this.id,
    this.email,
    required this.role,
    this.companyId,
    required this.trueCoinBalance,
    this.displayName,
    this.phone,
    this.avatarUrl,
  });

  factory UserInfoDto.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v, [int defaultValue = 0]) {
      if (v == null) return defaultValue;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? defaultValue;
      if (v is num) return v.toInt();
      return defaultValue;
    }

    double parseDouble(dynamic v, [double defaultValue = 0.0]) {
      if (v == null) return defaultValue;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? defaultValue;
      if (v is num) return v.toDouble();
      return defaultValue;
    }

    AppRole parseRole(dynamic v) {
      try {
        if (v is int) {
          if (v >= 0 && v < AppRole.values.length) return AppRole.values[v];
        }
        if (v is String) {
          final idx = int.tryParse(v);
          if (idx != null && idx >= 0 && idx < AppRole.values.length) {
            return AppRole.values[idx];
          }
          return AppRole.values.firstWhere(
            (r) =>
                r.toString().split('.').last.toLowerCase() == v.toLowerCase(),
            orElse: () => AppRole.User,
          );
        }
      } catch (_) {}
      return AppRole.User;
    }

    return UserInfoDto(
      id: parseInt(json['id']),
      email: json['email']?.toString(),
      role: parseRole(json['role']),
      companyId: json['companyId'] == null ? null : parseInt(json['companyId']),
      trueCoinBalance: parseDouble(json['trueCoinBalance']),
      // --- MAPEO DE NUEVOS CAMPOS ---
      displayName: json['displayName']?.toString(),
      phone: json['phone']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'role': role.index,
    'companyId': companyId,
    'trueCoinBalance': trueCoinBalance,
    'displayName': displayName,
    'phone': phone,
    'avatarUrl': avatarUrl,
  };
}
