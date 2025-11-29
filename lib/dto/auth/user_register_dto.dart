import 'app_role.dart';

class UserRegisterDto {
  final String? name;
  final String? email;
  final String? password;
  final String? phone;
  final AppRole role;
  final int? companyId;

  UserRegisterDto({
    this.name,
    this.email,
    this.password,
    this.phone,
    required this.role,
    this.companyId,
  });

  factory UserRegisterDto.fromJson(Map<String, dynamic> json) {
    return UserRegisterDto(
      name: json['name'],
      email: json['email'],
      password: json['password'],
      phone: json['phone'],
      role: AppRole.values[json['role']],
      companyId: json['companyId'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'password': password,
    'phone': phone,
    'role': role.index,
    'companyId': companyId,
  };
}
