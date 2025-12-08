import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:truekapp/dto/trade/trade_status.dart';
import 'package:dio/dio.dart';
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
      Provider.of<TradeProvider>(
        context,
        listen: false,
      ).leaveTradeChat(_tradeId!);
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

void _showCompleteConfirmation(BuildContext context, int tradeId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Finalizar Trueque?"),
        content: const Text(
          "Al confirmar:\n"
          "1. El producto se marcará como VENDIDO.\n"
          "2. Se procesará la transacción de TrueCoins.\n"
          "3. Esta conversación se cerrará.\n\n"
          "¿Confirmas que el intercambio fue exitoso?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          TextButton(
            child: const Text(
              "Sí, Finalizar",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
            onPressed: () async {
              // 1. Cerrar el diálogo de confirmación primero
              Navigator.pop(ctx); 

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
              } on DioException catch (e) {
                // Obtenemos el mensaje de error del Backend
                // El backend devuelve mensajes en inglés ("Insufficient balance...") o español
                final errorMsg = e.response?.data.toString().toLowerCase() ?? '';

                if (mounted) {
                  // CASO 1: Falta Aceptar (Error 400 + texto específico)
                  if (errorMsg.contains("aceptados")) {
                    _showAcceptRequiredDialog(tradeId);
                  }
                  // CASO 2: Saldo Insuficiente (Error 400 + texto específico)
                  // Validamos tanto inglés como español por seguridad
                  else if (errorMsg.contains("saldo") || errorMsg.contains("insufficient") || errorMsg.contains("balance")) {
                    _showInsufficientFundsDialog();
                  }
                  // CASO 3: Otro error (Snack bar rojo)
                  else {
                      ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Error: ${e.response?.data ?? e.message}"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                // Errores no controlados
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error inesperado: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAcceptRequiredDialog(int tradeId) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.info_outline, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Expanded(child: Text("Falta un paso previo", style: TextStyle(fontSize: 18))),
            ],
          ),
          content: const Text(
            "Para finalizar un intercambio, primero debes ACEPTARLO formalmente.\n\n"
            "Esto confirma que ambas partes están de acuerdo con los términos antes de cerrar el trato.",
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Entendido", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.handshake, color: Colors.white, size: 18),
              label: const Text("Aceptar Trueque Ahora"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, // Color distintivo
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.of(ctx).pop(); // Cerramos la alerta
                await _handleAceptarTrueque(tradeId); // Ejecutamos la acción
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleAceptarTrueque(int tradeId) async {
    try {
      await Provider.of<TradeProvider>(context, listen: false).acceptTrade(tradeId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Trueque aceptado! Ahora puedes finalizarlo."),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } on DioException catch (e) {
      // CASO 1: Error de API estructurado (Ideal)
      final errorData = e.response?.data.toString().toLowerCase() ?? '';
      
      if (errorData.contains("saldo") || errorData.contains("insufficient")) {
        if (mounted) _showInsufficientFundsDialog();
      } else {
        _showErrorSnackBar("Error API: ${e.response?.data ?? e.message}");
      }
    } catch (e) {
      // CASO 2: Error genérico o Exception transformada (Red de seguridad)
      // Esto capturará el error incluso si el Provider no se arregló bien.
      final msg = e.toString().toLowerCase();
      
      if (msg.contains("saldo") || msg.contains("insufficient")) {
        if (mounted) _showInsufficientFundsDialog();
      } else {
        _showErrorSnackBar("Ocurrió un error inesperado: $e");
      }
    }
  }

  // Helper para no repetir código de SnackBar
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
  
  void _showInsufficientFundsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Expanded(child: Text("Saldo Insuficiente", style: TextStyle(fontSize: 18))),
          ],
        ),
        content: const Text(
          "Para aceptar este trueque se requiere una diferencia en TrueCoins, pero tu billetera no tiene fondos suficientes.\n\n"
          "¿Deseas recargar ahora?",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
            label: const Text("Ir a Billetera"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/wallet');
            },
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
                            userName: isBuyer
                                ? (currentTrade.ownerName ?? "Vendedor")
                                : (currentTrade.requesterName ?? "Comprador"),
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
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.grey,
                      ),
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
                            final myName =
                                authProvider.currentUser?.displayName ??
                                "Alguien";
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
