import 'package:provider/provider.dart';
import '../core/app_export.dart'; // Importa tus constantes/colores
import '../dto/review/user_review_create_dto.dart';
import '../providers/review_provider.dart';
import 'primary_button.dart'; // Tu botón personalizado existente

class RateUserDialog extends StatefulWidget {
  final int toUserId;
  final int tradeId;
  final String userName;

  const RateUserDialog({
    super.key,
    required this.toUserId,
    required this.tradeId,
    required this.userName,
  });

  @override
  State<RateUserDialog> createState() => _RateUserDialogState();
}

class _RateUserDialogState extends State<RateUserDialog> {
  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor selecciona una calificación")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<ReviewProvider>(context, listen: false);

      final dto = UserReviewCreateDto(
        toUserId: widget.toUserId,
        tradeId: widget.tradeId,
        rating: _selectedRating,
        comment: _commentController.text.trim(),
      );

      await provider.createReview(dto);

      if (mounted) {
        Navigator.pop(context, true); // Retorna true al cerrar si tuvo éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("¡Calificación enviada!"),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildStar(int index) {
    // index es 1, 2, 3, 4, 5
    return IconButton(
      onPressed: () {
        setState(() {
          _selectedRating = index;
        });
      },
      icon: Icon(
        index <= _selectedRating ? Icons.star : Icons.star_border,
        color: Colors.amber,
        size: 32,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Calificar a ${widget.userName}",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // --- ESTRELLAS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => _buildStar(index + 1)),
            ),
            const SizedBox(height: 20),

            // --- CAMPO DE TEXTO ---
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: "¿Cómo fue tu experiencia? (Opcional)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // --- BOTONES ---
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text("Cancelar"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: _isLoading ? "Enviando..." : "Enviar",
                    onPressed: _isLoading ? () {} : _submitReview,
                    isEnabled: !_isLoading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
