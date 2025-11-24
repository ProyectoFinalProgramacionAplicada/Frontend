// lib/dto/trade/trade_message_dto.dart

class TradeMessageDto {
  final int? id;
  final int? senderUserId;    // Antes fromUserId
  final String? senderUserName; // NUEVO: Para mostrar el nombre en el chat
  final int? tradeId;
  final String? text;         // Antes message
  final DateTime? createdAt;

  TradeMessageDto({
    this.id,
    this.senderUserId,
    this.senderUserName,
    this.tradeId,
    this.text,
    this.createdAt,
  });

  factory TradeMessageDto.fromJson(Map<String, dynamic> json) {
    
    // Helper para parsear enteros seguros
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      if (v is double) return v.toInt();
      return null;
    }

    // Helper para parsear fechas
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        if (v is String && v.isNotEmpty) return DateTime.parse(v);
      } catch (_) {}
      return null;
    }

    return TradeMessageDto(
      id: parseInt(json['id']),
      
      // Mapeamos 'senderUserId' (o fallbacks antiguos 'fromUserId')
      senderUserId: parseInt(json['senderUserId'] ?? json['fromUserId']),
      
      // Mapeamos 'senderUserName' (o fallbacks)
      senderUserName: json['senderUserName']?.toString() ?? json['senderName']?.toString(),
      
      tradeId: parseInt(json['tradeId']),
      
      // Mapeamos 'text' (o fallbacks 'message')
      text: json['text']?.toString() ?? json['message']?.toString() ?? '',
      
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderUserId': senderUserId,
      'senderUserName': senderUserName,
      'tradeId': tradeId,
      'text': text,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}