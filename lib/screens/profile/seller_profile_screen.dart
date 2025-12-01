import 'package:provider/provider.dart';
// Necesitarás agregar intl en pubspec.yaml si quieres formatear fechas, o usa toString() simple
import '../../core/app_export.dart';
import '../../dto/listing/listing_dto.dart';
import '../../dto/review/user_review_dto.dart'; // Importar DTO de reviews
import '../../providers/listing_provider.dart';
import '../../providers/review_provider.dart'; // Importar ReviewProvider

class SellerProfileScreen extends StatefulWidget {
  final int sellerId;
  final String sellerName;
  final String? sellerAvatarUrl;
  final double sellerRating;

  const SellerProfileScreen({
    super.key,
    required this.sellerId,
    required this.sellerName,
    this.sellerAvatarUrl,
    required this.sellerRating,
  });

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  late Future<List<ListingDto>> _ownerListingsFuture;
  late Future<List<UserReviewDto>> _reviewsFuture; // <--- Nuevo Future

  @override
  void initState() {
    super.initState();
    final listingProvider = Provider.of<ListingProvider>(
      context,
      listen: false,
    );
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);

    _ownerListingsFuture = listingProvider.getListingsByOwner(widget.sellerId);
    _reviewsFuture = reviewProvider.getReviewsByUser(
      widget.sellerId,
    ); // Cargar reviews
  }

  @override
  Widget build(BuildContext context) {
    final fullAvatarUrl = widget.sellerAvatarUrl != null
        ? '${AppConstants.apiBaseUrl}${widget.sellerAvatarUrl}'
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.sellerName)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // --- HEADER (Avatar y Rating General) ---
            Center(
              child: Column(
                children: [
                  Hero(
                    tag: 'seller_${widget.sellerId}',
                    child: CircleAvatar(
                      radius: 40,
                      // Donde definas la URL o dentro del NetworkImage:
                      backgroundImage: fullAvatarUrl != null
                        ? NetworkImage(
                          fullAvatarUrl.startsWith('http')
                            ? fullAvatarUrl
                            : '${AppConstants.apiBaseUrl}${fullAvatarUrl}',
                          )
                        : null,
                      child: fullAvatarUrl == null
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.sellerName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      Text(
                        " ${widget.sellerRating > 0 ? widget.sellerRating.toStringAsFixed(1) : 'N/A'}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Divider(
              thickness: 8,
              color: Colors.black12,
            ), // Separador grueso visual
            const SizedBox(height: 20),

            // --- SECCIÓN 1: PRODUCTOS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "En venta",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            _buildListingsGrid(),

            const SizedBox(height: 30),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(),
            ),

            // --- SECCIÓN 2: RESEÑAS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Text(
                    "Reseñas",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Aquí podrías poner un "Ver todas" si fueran muchas
                ],
              ),
            ),
            _buildReviewsList(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildListingsGrid() {
    return FutureBuilder<List<ListingDto>>(
      future: _ownerListingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final listings = snapshot.data ?? [];
        if (listings.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "No hay publicaciones activas.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return SizedBox(
          height: 180, // Scroll horizontal para ahorrar espacio vertical
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final item = listings[index];
              return Container(
                width: 140,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Card(
                  elevation: 2,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.listingDetail,
                      arguments: item.id,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) =>
                                Container(color: Colors.grey[300]),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                "${item.trueCoinValue} TC",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildReviewsList() {
    return FutureBuilder<List<UserReviewDto>>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text("No se pudieron cargar las reseñas."),
          );
        }

        final reviews = snapshot.data ?? [];
        if (reviews.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 40,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 8),
                const Text(
                  "Aún no tiene reseñas.",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(), // Scrollea con toda la página
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: reviews.length,
          separatorBuilder: (ctx, i) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final review = reviews[index];
            final avatarUrl = review.fromUserAvatarUrl != null
                ? '${AppConstants.apiBaseUrl}${review.fromUserAvatarUrl}'
                : null;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(
                          avatarUrl.startsWith('http')
                            ? avatarUrl
                            : '${AppConstants.apiBaseUrl}${avatarUrl}',
                          )
                        : null,
                    child: avatarUrl == null
                        ? const Icon(Icons.person, size: 20)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre y Fecha
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              review.fromUserName ?? "Usuario",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              // Formateo simple de fecha (o usa intl: DateFormat.yMMMd().format(review.createdAt))
                              "${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}",
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Estrellas
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < review.rating
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 14,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Comentario
                        if (review.comment != null &&
                            review.comment!.isNotEmpty)
                          Text(
                            review.comment!,
                            style: const TextStyle(fontSize: 14, height: 1.4),
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
    );
  }
}
