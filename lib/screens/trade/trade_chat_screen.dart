import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/trade_provider.dart';

class TradeChatScreen extends StatefulWidget {
  const TradeChatScreen({Key? key}) : super(key: key);

  @override
  State<TradeChatScreen> createState() => _TradeChatScreenState();
}

class _TradeChatScreenState extends State<TradeChatScreen> {
  int? _tradeId;
  bool _initialized = false;
  final TextEditingController _controller = TextEditingController();

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
              .fetchMessages(_tradeId!);
        });
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
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

                  final messages = provider.getMessagesForTrade(_tradeId!);
                  if (messages.isEmpty) {
                    return const Center(child: Text('No hay mensajes.'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(msg.message),
                          subtitle: Text(msg.createdAt?.toIso8601String() ?? ''),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final text = _controller.text.trim();
                      if (text.isEmpty) return;
                      final provider =
                          Provider.of<TradeProvider>(context, listen: false);
                      if (provider.isSendPendingFor(_tradeId!)) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Envío en proceso, por favor espera...'),
                          backgroundColor: Colors.orange,
                        ));
                        return;
                      }

                      try {
                        await provider.sendMessageAndRefresh(_tradeId!, text);
                        _controller.clear();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Error enviando mensaje: $e'),
                          backgroundColor: Colors.red,
                        ));
                      }
                    },
                    child: const Text('Enviar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
