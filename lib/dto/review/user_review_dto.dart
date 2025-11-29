class UserReviewDto {
  final int id;
  final int fromUserId;
  final int toUserId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  // Nuevos campos
  final String? fromUserName;
  final String? fromUserAvatarUrl;

  UserReviewDto({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.fromUserName,
    this.fromUserAvatarUrl,
  });

  factory UserReviewDto.fromJson(Map<String, dynamic> json) {
    return UserReviewDto(
      id: json['id'],
      fromUserId: json['fromUserId'],
      toUserId: json['toUserId'],
      rating: json['rating'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['createdAt']),
      // Acepta displayName o name del backend
      fromUserName: json['fromUserDisplayName'] ?? json['fromUserName'],
      fromUserAvatarUrl: json['fromUserAvatarUrl'],
    );
  }
}
