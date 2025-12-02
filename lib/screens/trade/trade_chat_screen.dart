import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:truekapp/dto/trade/trade_status.dart';

// Imports propios (Ajusta las rutas si es necesario)
import '../../core/app_export.dart'; // Para AppColors
import '../../providers/auth_provider.dart';
import '../../providers/trade_provider.dart';
import '../../widgets/rate_user_dialog.dart'; // El diálogo que creamos antes
import '../../dto/trade/trade_dto.dart';
import '../../dto/trade/trade_message_dto.dart';

class TradeChatScreen extends StatefulWidget {
  const TradeChatScreen({super.key});

  @override
  State<TradeChatScreen> createState() => _TradeChatScreenState();
}

class _TradeChatScreenState extends State<TradeChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int? _tradeId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Obtenemos el ID del argumento de la ruta
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int && _tradeId == null) {
      _tradeId = args;
      _initData();
    }
  }

  void _initData() {
    if (_tradeId == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<TradeProvider>(context, listen: false);
      
      // 1. Cargar historial antiguo (API REST)
      await provider.fetchMessages(_tradeId!);
      
      // 2. Conectarse al tiempo real (SignalR)
      await provider.joinTradeChat(_tradeId!);
    });
  }

  @override
  void dispose() {
    // Salir del grupo al cerrar la pantalla
    if (_tradeId != null) {
      Provider.of<TradeProvider>(context, listen: false).leaveTradeChat(_tradeId!);
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    if (_tradeId == null) return;
    await Provider.of<TradeProvider>(
      context,
      listen: false,
    ).fetchMessages(_tradeId!);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _tradeId == null) return;

    _messageController.clear();
    try {
      await Provider.of<TradeProvider>(
        context,
        listen: false,
      ).sendMessageAndRefresh(_tradeId!, text);

      // Scroll al fondo
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent +
              60, // un poco extra por si acaso
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al enviar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- LÓGICA DE FINALIZAR TRUEQUE ---
  void _showCompleteConfirmation(BuildContext context, int tradeId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Finalizar Trueque?"),
        content: const Text(
          "Al confirmar:\n"
          "1. El producto se marcará como VENDIDO.\n"
          "2. Esta conversación se cerrará.\n"
          "3. El comprador podrá calificarte.\n\n"
          "¿Confirmas que el intercambio fue exitoso?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Cierra diálogo
              try {
                await Provider.of<TradeProvider>(
                  context,
                  listen: false,
                ).completeTrade(tradeId);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("¡Trueque finalizado con éxito!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              "Sí, Finalizar",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final tradeProvider = Provider.of<TradeProvider>(context);
    final currentUser = authProvider.currentUser;

    if (_tradeId == null || currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Buscamos el Trade actual en la lista del provider para tener el estado REACTIVO
    // Si no está (raro), usamos null safe
    final TradeDto? currentTrade = tradeProvider.myTrades
        .cast<TradeDto?>()
        .firstWhere((t) => t?.id == _tradeId, orElse: () => null);

    if (currentTrade == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Chat")),
        body: const Center(
          child: Text("No se encontró la información del trueque."),
        ),
      );
    }

    // Determinamos roles
    // ownerUserId = Vendedor (Dueño del producto publicado)
    // requesterUserId = Comprador (Quien inició el trueque)
    // NOTA: Usamos los campos nuevos que mapeamos en el DTO para evitar confusión
    final isSeller = currentUser.id == currentTrade.listingOwnerId;
    final isBuyer = currentUser.id == currentTrade.initiatorUserId;

    final isCompleted = currentTrade.status == TradeStatus.Completed;
    final isCancelled = currentTrade.status == TradeStatus.Cancelled;

    final String? otherUserAvatar = isSeller 
        ? currentTrade.requesterAvatarUrl 
        : currentTrade.ownerAvatarUrl;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSeller ? "Mi Venta" : "Mi Compra",
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              isCompleted
                  ? "Finalizado"
                  : (isCancelled ? "Cancelado" : "En proceso"),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
            ),
          ],
        ),
        actions: [
          // --- BOTÓN PARA EL VENDEDOR: FINALIZAR ---
          // Solo aparece si soy el vendedor y NO está terminado ni cancelado
          if (isSeller && !isCompleted && !isCancelled)
            IconButton(
              icon: const Icon(Icons.check_circle_outline, size: 28),
              color: Colors.green,
              tooltip: "Marcar como Finalizado",
              onPressed: () =>
                  _showCompleteConfirmation(context, currentTrade.id),
            ),
        ],
      ),
      body: Column(
        children: [
          // --- BANNER DE ESTADO (SI ESTÁ COMPLETADO) ---
          if (isCompleted)
            Container(
              width: double.infinity,
              color: Colors.green.shade50,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.verified, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        "¡Trueque Completado!",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  // Botón para el Comprador: Calificar
                  if (isBuyer) ...[
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(
                        Icons.star_rate_rounded,
                        color: Colors.white,
                      ),
                      label: const Text("Calificar Vendedor"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => RateUserDialog(
                            toUserId: currentTrade.listingOwnerId,
                            tradeId: currentTrade.id,
                            userName:
                                "Vendedor", // Podrías pasar el nombre real si lo agregas al DTO
                          ),
                        );
                      },
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    const Text(
                      "Gracias por usar TruekApp.",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),

          // --- BANNER DE CANCELADO ---
          if (isCancelled)
            Container(
              width: double.infinity,
              color: Colors.red.shade50,
              padding: const EdgeInsets.all(12),
              child: const Center(
                child: Text(
                  "Este trueque ha sido cancelado.",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),

          // --- LISTA DE MENSAJES ---
          Expanded(
            child: Consumer<TradeProvider>(
              builder: (context, provider, child) {
                final messages = provider.getMessagesForTrade(_tradeId!);

                if (provider.isLoadingMessages && messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      "Inicia la conversación...",
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final bool isMe = msg.senderUserId == currentUser.id;
                    return _buildMessageBubble(msg, isMe);
                  },
                );
              },
            ),
          ),
          if (tradeProvider.isOtherUserTyping)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    // Una animación simple de puntos o texto
                    SizedBox(
                      width: 12, 
                      height: 12, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Escribiendo...",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // --- INPUT DE MENSAJES ---
          // Solo habilitado si el trade NO está finalizado ni cancelado
          if (!isCompleted && !isCancelled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: "Escribe un mensaje...",
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (text) {
                          if (text.isNotEmpty) {
                            final myName = authProvider.currentUser?.displayName ?? "Alguien";
                            tradeProvider.notifyImTyping(_tradeId!, myName);
                          }
                        },
                        
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    // ✅ PEGAR ESTO (El botón correcto)
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _sendMessage, // Llama a la función de enviar
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(TradeMessageDto msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: 70.w), // Usando sizer
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              Text(
                msg.senderUserName ?? "Usuario",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              msg.text ?? "",
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(msg.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return "";
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
