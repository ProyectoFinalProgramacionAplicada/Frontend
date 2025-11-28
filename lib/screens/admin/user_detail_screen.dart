import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../dto/listing/listing_dto.dart';
import '../../providers/auth_provider.dart';
import '../../services/review_service.dart';
import '../../dto/review/user_review_dto.dart';
import '../../services/wallet_service.dart';
import '../../dto/wallet/wallet_adjust_request.dart';

class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({Key? key}) : super(key: key);

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late final AdminProvider _adminProvider;
  final ReviewService _reviewService = ReviewService();
  final WalletService _walletService = WalletService();

  bool _isLoading = true;
  bool _isAdjusting = false;
  List<UserReviewDto> _reviews = [];
  int? _userId;

  // adjust form
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adminProvider = Provider.of<AdminProvider>(context, listen: false);
    if (_userId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int) {
        _userId = args;
        _loadReviews();
      } else {
        // invalid usage
        Navigator.pop(context);
      }
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    try {
      _reviews = await _reviewService.getUserReviews(_userId!);
    } catch (e) {
      _reviews = [];
      // ignore error but show message
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error cargando reseñas: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitAdjust() async {
    if (_userId == null) return;
    final text = _amountController.text.trim();
    final reason = _reasonController.text.trim();
    final value = double.tryParse(text.replaceAll(',', '.'));
    if (value == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingrese un monto válido')));
      return;
    }
    setState(() => _isAdjusting = true);
    try {
      final req = WalletAdjustRequest(
        userId: _userId!,
        amount: value,
        reason: reason.isEmpty ? null : reason,
      );
      await _walletService.adjustBalance(req);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ajuste aplicado')));
      _amountController.clear();
      _reasonController.clear();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al ajustar: $e')));
    } finally {
      if (mounted) setState(() => _isAdjusting = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userIndex = _adminProvider.activeUsers.indexWhere(
      (u) => u.userId == _userId,
    );
    final userSummary = userIndex == -1
        ? null
        : _adminProvider.activeUsers[userIndex];
    final listings = _adminProvider.getListingsForUser(_userId ?? -1);

    if (userSummary == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Usuario')),
        body: const Center(
          child: Text('Usuario no encontrado en el catálogo.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(userSummary.displayName)),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            Row(
              children: [
                userSummary.avatarUrl != null &&
                        userSummary.avatarUrl!.isNotEmpty
                    ? CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(userSummary.avatarUrl!),
                      )
                    : const CircleAvatar(radius: 30, child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userSummary.displayName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 6),
                          Text(userSummary.averageRating.toStringAsFixed(2)),
                          const SizedBox(width: 12),
                          Text('${userSummary.listingCount} publicaciones'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Listings section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Publicaciones del usuario',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (listings.isEmpty)
                      const Text('No hay publicaciones para mostrar.'),
                    ...listings
                        .take(10)
                        .map(
                          (ListingDto l) => ListTile(
                            leading: l.imageUrl.isNotEmpty
                                ? CircleAvatar(
                                    backgroundImage: NetworkImage(l.imageUrl),
                                  )
                                : const CircleAvatar(child: Icon(Icons.image)),
                            title: Text(l.title),
                            subtitle: Text(
                              '${l.trueCoinValue.toStringAsFixed(2)} TC · ${l.isPublished ? 'Activa' : 'Inactiva'}',
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Reviews
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Reseñas',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _loadReviews,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator()),
                    if (!_isLoading && _reviews.isEmpty)
                      const Text('No hay reseñas para este usuario.'),
                    if (!_isLoading && _reviews.isNotEmpty)
                      ..._reviews.map(
                        (r) => ListTile(
                          leading:
                              r.fromUserAvatarUrl != null &&
                                  r.fromUserAvatarUrl!.isNotEmpty
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    r.fromUserAvatarUrl!,
                                  ),
                                )
                              : const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(
                            '${r.fromUserName ?? 'Anonimo'} · ${r.rating}⭐',
                          ),
                          subtitle: r.comment != null ? Text(r.comment!) : null,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Adjust TrueCoins
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ajustar TrueCoins (ADMIN)',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Monto (use - para debitar)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Motivo (opcional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _isAdjusting ? null : _submitAdjust,
                          child: _isAdjusting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Aplicar ajuste'),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () {
                            _amountController.clear();
                            _reasonController.clear();
                          },
                          child: const Text('Limpiar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
