import 'user_info_dto.dart';

/// DTO para la respuesta del endpoint POST /api/Auth/login
/// Contiene el token JWT y los datos completos del usuario
class LoginResponseDto {
  final String? token;
  final UserInfoDto? user;

  LoginResponseDto({
    this.token,
    this.user,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    return LoginResponseDto(
      token: json['token']?.toString(),
      user: json['user'] != null 
          ? UserInfoDto.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'user': user?.toJson(),
  };
}
