class UserUpdateDto {
  final String displayName;
  final String? phone;

  UserUpdateDto({
    required this.displayName,
    this.phone,
  });

  // Serialización para enviar al backend
  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'phone': phone,
    };
  }
}