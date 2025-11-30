/// DTO para solicitar restablecimiento de contraseña
class ForgotPasswordDto {
  final String email;

  ForgotPasswordDto({required this.email});

  Map<String, dynamic> toJson() => {'email': email};

  factory ForgotPasswordDto.fromJson(Map<String, dynamic> json) =>
      ForgotPasswordDto(email: json['email'] ?? '');
}
