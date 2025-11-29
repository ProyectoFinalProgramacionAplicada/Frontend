import 'app_role.dart';

class UserRegisterDto {
  final String? displayName;
  final String? email;
  final String? password;
  final String? phone;
  final AppRole role;
  final int? companyId;

  UserRegisterDto({
    this.displayName,
    this.email,
    this.password,
    this.phone,
    required this.role,
    this.companyId,
  });

  factory UserRegisterDto.fromJson(Map<String, dynamic> json) {
    return UserRegisterDto(
      displayName: json['displayName'] ?? json['name'],
      email: json['email'],
      password: json['password'],
      phone: json['phone'],
      role: AppRole.values[json['role'] ?? 0],
      companyId: json['companyId'],
    );
  }

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'email': email,
    'password': password,
    if (phone != null && phone!.isNotEmpty) 'phone': phone,
    'role': role.index,
    if (companyId != null) 'companyId': companyId,
  };

  UserRegisterDto copyWith({
    String? displayName,
    String? email,
    String? password,
    String? phone,
    AppRole? role,
    int? companyId,
  }) {
    return UserRegisterDto(
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      companyId: companyId ?? this.companyId,
    );
  }
}
