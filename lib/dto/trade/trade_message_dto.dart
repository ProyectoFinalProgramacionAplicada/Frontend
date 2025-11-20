// lib/dto/trade/trade_message_dto.dart
// DTO para mensajes de un Trade (chat de trueque)
// Estructura mínima definida por petición del equipo.

class TradeMessageDto {
  final int? id;
  final int? fromUserId;
  final int? tradeId;
  final String message;
  final DateTime? createdAt;

  TradeMessageDto({
    this.id,
    this.fromUserId,
    this.tradeId,
    required this.message,
    this.createdAt,
  });

  factory TradeMessageDto.fromJson(Map<String, dynamic> json) {
    // Helpers to safely parse ints that might come as int or string or null
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      if (v is double) return v.toInt();
      return null;
    }

    String parseMessage(Map<String, dynamic> j) {
      if (j['message'] != null) return j['message'].toString();
      if (j['text'] != null) return j['text'].toString();
      if (j['body'] != null) return j['body'].toString();
      // If server returns plain string (unlikely here), fallback to empty
      return '';
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        if (v is String && v.isNotEmpty) return DateTime.parse(v);
      } catch (_) {}
      return null;
    }

    // FromUser could be nested object
    int? fromUserId = parseInt(json['fromUserId']);
    if (fromUserId == null && json['fromUser'] != null) {
      final fu = json['fromUser'];
      if (fu is Map && fu['id'] != null) fromUserId = parseInt(fu['id']);
    }

    return TradeMessageDto(
      id: parseInt(json['id']),
      fromUserId: fromUserId,
      tradeId: parseInt(json['tradeId'] ?? json['tradeId']),
      message: parseMessage(json),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (fromUserId != null) 'fromUserId': fromUserId,
      if (tradeId != null) 'tradeId': tradeId,
      'message': message,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}

// Nota: esta implementación es tolerante a campos nulos y variantes comunes
// de nombres devueltos por el backend (ej. 'text', 'body', 'fromUser').
