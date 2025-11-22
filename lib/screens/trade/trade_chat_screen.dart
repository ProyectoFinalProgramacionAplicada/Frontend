import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../../providers/trade_provider.dart';
import '../../providers/auth_provider.dart';
import 'package:truekapp/dto/trade/trade_message_dto.dart';

enum _SendStatus { pending, failed }

class _OptimisticMessage {
  final TradeMessageDto dto;
  _SendStatus status;
  _OptimisticMessage({required this.dto, this.status = _SendStatus.pending});
}

class TradeChatScreen extends StatefulWidget {
  const TradeChatScreen({Key? key}) : super(key: key);

  @override
  State<TradeChatScreen> createState() => _TradeChatScreenState();
}

class _TradeChatScreenState extends State<TradeChatScreen> {
  int? _tradeId;
  bool _initialized = false;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_OptimisticMessage> _optimisticMessages = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      // rebuild to update send button enabled/disabled state
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int) {
        _tradeId = args;
        // Fetch messages for this trade
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Provider.of<TradeProvider>(context, listen: false)
              .fetchMessages(_tradeId!)
              .then((_) => _scrollToBottom())
              .catchError((_) {});
        });
      }
      _initialized = true;
    }
  }

  void _scrollToBottom() {
    if (!mounted) return;
    if (!_scrollController.hasClients) return;
    try {
      final pos = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(pos,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } catch (_) {
      // ignore scroll errors
    }
  }

  Color _bubbleColor(BuildContext context, bool isMe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isMe) return isDark ? const Color(0xFF0B8440) : const Color(0xFFD2F8C6);
    return isDark ? Colors.grey.shade800 : Colors.grey.shade200;
  }

  Color _bubbleTextColor(BuildContext context, bool isMe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isMe) return isDark ? Colors.white : const Color(0xFF0F1720);
    return isDark ? Colors.white70 : Colors.black87;
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_tradeId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: Text('Trade ID no válido')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Chat - Trueque #${_tradeId}')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Consumer<TradeProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoadingMessages) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final error = provider.messagesError;
                  if (error != null) {
                    return Center(child: Text('Error: $error'));
                  }

                  final messages = List<TradeMessageDto>.from(provider.getMessagesForTrade(_tradeId!));

                  if (messages.isEmpty && _optimisticMessages.isEmpty) {
                    return const Center(
                        child: Text(
                      'Todavía no hay mensajes en este trueque. Envía el primero ✨',
                      textAlign: TextAlign.center,
                    ));
                  }

                  // Combine provider messages with optimistic local messages
                  final combined = List<TradeMessageDto>.from(messages);
                  for (final om in _optimisticMessages) {
                    final exists = messages.any((m) => m.message == om.dto.message && m.fromUserId == om.dto.fromUserId && m.createdAt == om.dto.createdAt);
                    if (!exists) combined.add(om.dto);
                  }

                  // Ensure chronological order (older first)
                  combined.sort((a, b) {
                    final ta = a.createdAt ?? DateTime(1970);
                    final tb = b.createdAt ?? DateTime(1970);
                    return ta.compareTo(tb);
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: combined.length,
                    itemBuilder: (context, index) {
                      final msg = combined[index];
                      final time = msg.createdAt != null
                          ? DateFormat.Hm().format(msg.createdAt!)
                          : '';
                      final currentUserId = Provider.of<AuthProvider>(context, listen: false).user?.id;
                      final isMe = currentUserId != null && msg.fromUserId != null && currentUserId == msg.fromUserId;

                      // Determine if this message corresponds to an optimistic entry
                      _OptimisticMessage? opt;
                      try {
                        opt = _optimisticMessages.firstWhere((o) =>
                            o.dto.message == msg.message &&
                            o.dto.fromUserId == msg.fromUserId &&
                            o.dto.createdAt == msg.createdAt);
                      } catch (_) {
                        opt = null;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment:
                              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.72),
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  // Bubble with tail drawn as a rotated square
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                        decoration: BoxDecoration(
                                          color: _bubbleColor(context, isMe),
                                          borderRadius: isMe
                                              ? const BorderRadius.only(
                                                  topLeft: Radius.circular(16),
                                                  topRight: Radius.circular(16),
                                                  bottomLeft: Radius.circular(16),
                                                  bottomRight: Radius.circular(4),
                                                )
                                              : const BorderRadius.only(
                                                  topLeft: Radius.circular(16),
                                                  topRight: Radius.circular(16),
                                                  bottomLeft: Radius.circular(4),
                                                  bottomRight: Radius.circular(16),
                                                ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              offset: const Offset(0, 1),
                                              blurRadius: 2,
                                            )
                                          ],
                                        ),
                                        child: Text(
                                          msg.message ?? '',
                                          style: TextStyle(
                                              color: _bubbleTextColor(context, isMe)),
                                        ),
                                      ),
                                      // tail
                                      Positioned(
                                        bottom: -6,
                                        right: isMe ? -6 : null,
                                        left: isMe ? null : -6,
                                        child: Transform.rotate(
                                          angle: math.pi / 4,
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: _bubbleColor(context, isMe),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(
                                            left: isMe ? 0 : 6,
                                            right: isMe ? 6 : 0),
                                        child: Text(
                                          time,
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600]),
                                        ),
                                      ),
                                      if (opt != null && opt.status == _SendStatus.pending) ...[
                                        const SizedBox(width: 6),
                                        const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(strokeWidth: 2)),
                                      ] else if (opt != null && opt.status == _SendStatus.failed) ...[
                                        const SizedBox(width: 6),
                                        GestureDetector(
                                          onTap: () async {
                                            // retry
                                            setState(() => opt!.status = _SendStatus.pending);
                                            try {
                                              await provider.sendMessageAndRefresh(_tradeId!, opt!.dto.message);
                                              setState(() {
                                                _optimisticMessages.removeWhere((m) => m.dto.createdAt == opt!.dto.createdAt && m.dto.message == opt!.dto.message);
                                              });
                                              WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                                            } catch (_) {
                                              setState(() => opt!.status = _SendStatus.failed);
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error reenviando mensaje'), backgroundColor: Colors.red));
                                            }
                                          },
                                          child: const Icon(Icons.error, size: 14, color: Colors.red),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Consumer<TradeProvider>(builder: (context, provider, child) {
              final isPending = _tradeId != null && provider.isSendPendingFor(_tradeId!);
              final canSend = _controller.text.trim().isNotEmpty && !isPending;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Escribe un mensaje...',
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) async {
                          if (canSend && _tradeId != null) {
                            final text = _controller.text.trim();
                            if (text.isEmpty) return;
                            final currentUserId = Provider.of<AuthProvider>(context, listen: false).user?.id;
                            final temp = TradeMessageDto(
                                id: null,
                                fromUserId: currentUserId,
                                tradeId: _tradeId,
                                message: text,
                                createdAt: DateTime.now());
                            setState(() => _optimisticMessages.add(_OptimisticMessage(dto: temp)));
                            try {
                              await provider.sendMessageAndRefresh(_tradeId!, text);
                              _controller.clear();
                              // remove optimistic instance that matches
                              setState(() {
                                _optimisticMessages.removeWhere((m) => m.dto.createdAt == temp.createdAt && m.dto.message == temp.message);
                              });
                              WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Error enviando mensaje: $e'),
                                backgroundColor: Colors.red,
                              ));
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: canSend
                            ? () async {
                                final text = _controller.text.trim();
                                if (text.isEmpty || _tradeId == null) return;
                                final currentUserId = Provider.of<AuthProvider>(context, listen: false).user?.id;
                                final temp = TradeMessageDto(
                                    id: null,
                                    fromUserId: currentUserId,
                                    tradeId: _tradeId,
                                    message: text,
                                    createdAt: DateTime.now());
                                setState(() => _optimisticMessages.add(_OptimisticMessage(dto: temp)));
                                try {
                                  await provider.sendMessageAndRefresh(_tradeId!, text);
                                  _controller.clear();
                                  setState(() {
                                    _optimisticMessages.removeWhere((m) => m.dto.createdAt == temp.createdAt && m.dto.message == temp.message);
                                  });
                                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text('Error enviando mensaje: $e'),
                                    backgroundColor: Colors.red,
                                  ));
                                }
                              }
                            : null,
                      child: isPending
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Enviar'),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
