/// DTO para restablecer contraseña con token
class ResetPasswordDto {
  final String token;
  final String newPassword;

  ResetPasswordDto({
    required this.token,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
    'token': token,
    'newPassword': newPassword,
  };

  factory ResetPasswordDto.fromJson(Map<String, dynamic> json) =>
      ResetPasswordDto(
        token: json['token'] ?? '',
        newPassword: json['newPassword'] ?? '',
      );
}
