import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../dto/auth/app_role.dart';
import '../../routes.dart';

class ActiveUsersScreen extends StatefulWidget {
  const ActiveUsersScreen({Key? key}) : super(key: key);

  @override
  State<ActiveUsersScreen> createState() => _ActiveUsersScreenState();
}

class _ActiveUsersScreenState extends State<ActiveUsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadActiveUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios activos y calificaciones')),
      body: Consumer2<AuthProvider, AdminProvider>(builder: (context, auth, provider, child) {
        // If auth user not loaded yet, show loader
        if (auth.currentUser == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Access control: only Admins can view
        if (auth.currentUser!.role != AppRole.Admin) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.block, size: 64, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  const Text('Acceso denegado', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('No tienes permisos para ver esta sección.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
                    child: const Text('Volver al inicio'),
                  ),
                ],
              ),
            ),
          );
        }

        // Auth is admin: show admin UI
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = provider.activeUsers;
        final avg = provider.averageRating;
        final usersWithRating = provider.usersWithRating;
        final distribution = provider.ratingDistribution;

        // Additional aggregated metrics
        final totalListings = provider.totalListings;
        final activeListings = provider.activeListingsCount;
        final uniqueUsers = provider.uniqueUsersCount;
        final totalTrueCoinsActive = provider.totalTrueCoinsActive;
        final avgTrueCoins = provider.avgTrueCoinsPerListing;

        final topByListings = provider.topUsersByListings;
        final topByRating = provider.topUsersByRating.where((u) => u.averageRating > 0).toList();

        if (users.isEmpty) {
          return const Center(child: Text('No hay usuarios activos para mostrar'));
        }

        return RefreshIndicator(
          onRefresh: provider.loadActiveUsers,
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Summary: Ratings
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 28),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Rating promedio', style: Theme.of(context).textTheme.bodySmall),
                              Text(avg.toStringAsFixed(2), style: Theme.of(context).textTheme.titleLarge),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Usuarios con rating', style: Theme.of(context).textTheme.bodySmall),
                              Text('$usersWithRating', style: Theme.of(context).textTheme.titleLarge),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Distribution
                      Column(
                        children: List.generate(5, (i) {
                          final stars = 5 - i; // show 5..1
                          final count = distribution[stars] ?? 0;
                          final total = users.length == 0 ? 1 : users.length;
                          final pct = count / total;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                SizedBox(width: 40, child: Text('$stars⭐')),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    minHeight: 10,
                                    backgroundColor: Colors.grey.shade200,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(width: 48, child: Text('$count')),
                              ],
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              // Activity summary
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Actividad general', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _smallMetric('Publicaciones totales', '$totalListings'),
                          _smallMetric('Publicaciones activas', '$activeListings'),
                          _smallMetric('Usuarios que publicaron', '$uniqueUsers'),
                          _smallMetric('TrueCoins (activas)', totalTrueCoinsActive.toStringAsFixed(2)),
                          _smallMetric('Promedio TC por pub', avgTrueCoins.toStringAsFixed(2)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Charts: Activas vs Inactivas
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Publicaciones: Activas vs Inactivas', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      _buildActiveInactiveChart(provider),
                    ],
                  ),
                ),
              ),

              // Charts: TrueCoin histogram
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Distribución de TrueCoins por publicación', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      _buildTrueCoinHistogram(provider),
                    ],
                  ),
                ),
              ),

              // Top users
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Top usuarios', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text('Más activos', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 8),
                      Column(
                        children: topByListings.take(5).map((u) => ListTile(
                          leading: u.avatarUrl != null && u.avatarUrl!.isNotEmpty ? CircleAvatar(backgroundImage: NetworkImage(u.avatarUrl!)) : const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(u.displayName),
                          subtitle: Text('Publicaciones: ${u.listingCount}'),
                        )).toList(),
                      ),
                      if (topByRating.isNotEmpty) ...[
                        const Divider(),
                        Text('Mejor valorados', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 8),
                        Column(
                          children: topByRating.take(5).map((u) => ListTile(
                            leading: u.avatarUrl != null && u.avatarUrl!.isNotEmpty ? CircleAvatar(backgroundImage: NetworkImage(u.avatarUrl!)) : const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(u.displayName),
                            subtitle: Text('Rating: ${u.averageRating.toStringAsFixed(2)} · Publicaciones: ${u.listingCount}'),
                          )).toList(),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _smallMetric(String label, String value) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }

  Widget _buildActiveInactiveChart(AdminProvider provider) {
    final total = provider.totalListings;
    final active = provider.activeListingsCount;
    final inactive = provider.inactiveListingsCount;
    if (total == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('No hay publicaciones para mostrar.'),
      );
    }

    final activePct = active / total;
    final inactivePct = inactive / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Total: $total · Activas: $active · Inactivas: $inactive', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth;
          final barHeight = 14.0;
          return Column(
            children: [
              // Active
              Row(children: [
                SizedBox(width: 72, child: Text('Activas', style: Theme.of(context).textTheme.bodySmall)),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(
                    children: [
                      Container(height: barHeight, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6))),
                      Container(width: (width - 80) * activePct, height: barHeight, decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(6))),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(width: 48, child: Text('${(activePct * 100).toStringAsFixed(0)}%')),
              ]),
              const SizedBox(height: 8),
              // Inactive
              Row(children: [
                SizedBox(width: 72, child: Text('Inactivas', style: Theme.of(context).textTheme.bodySmall)),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(
                    children: [
                      Container(height: barHeight, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6))),
                      Container(width: (width - 80) * inactivePct, height: barHeight, decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(6))),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(width: 48, child: Text('${(inactivePct * 100).toStringAsFixed(0)}%')),
              ]),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildTrueCoinHistogram(AdminProvider provider) {
    final hist = provider.trueCoinHistogram;
    final entries = [
      MapEntry('0-100', hist['0-100'] ?? 0),
      MapEntry('101-500', hist['101-500'] ?? 0),
      MapEntry('501-1000', hist['501-1000'] ?? 0),
      MapEntry('>1000', hist['>1000'] ?? 0),
    ];
    final maxCount = entries.map((e) => e.value).fold<int>(0, (p, c) => c > p ? c : p);

    if (entries.every((e) => e.value == 0)) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('No hay publicaciones para el histograma.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.map((e) {
        final label = e.key;
        final count = e.value;
        final frac = maxCount == 0 ? 0.0 : (count / maxCount);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(width: 84, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  children: [
                    Container(height: 14, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6))),
                    FractionallySizedBox(widthFactor: frac, child: Container(height: 14, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(6)))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(width: 56, child: Text('$count')),
            ],
          ),
        );
      }).toList(),
    );
  }
}
