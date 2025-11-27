import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/trade_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/trade_card.dart';

class TradeListScreen extends StatefulWidget {
  const TradeListScreen({Key? key}) : super(key: key);

  @override
  State<TradeListScreen> createState() => _TradeListScreenState();
}

class _TradeListScreenState extends State<TradeListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      debugPrint('TradeListScreen: Iniciando carga de trueques...');
      Provider.of<TradeProvider>(context, listen: false).fetchMyTrades().then((
        _,
      ) {
        debugPrint(
          'TradeListScreen: Trueques cargados. Total: ${Provider.of<TradeProvider>(context, listen: false).myTrades.length}',
        );
      });
      _isInit = true;
    }
  }

  Future<void> _refresh() async {
    await Provider.of<TradeProvider>(context, listen: false).fetchMyTrades();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TradeProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final currentUserId = auth.currentUser?.id;

    debugPrint(
      'TradeListScreen BUILD - currentUserId: $currentUserId, totalTrades: ${provider.myTrades.length}, isLoading: ${provider.isLoading}',
    );

    if (currentUserId == null) {
      return const Scaffold(body: Center(child: Text('No autenticado')));
    }

    // Filtrar: Mis Ofertas (donde yo soy el iniciador)
    final myOffers = provider.myTrades
        .where((t) => t.initiatorUserId == currentUserId)
        .toList();

    // Filtrar: Ofertas Recibidas (donde yo soy el dueño del listing pero NO el iniciador)
    final receivedOffers = provider.myTrades
        .where(
          (t) =>
              t.listingOwnerId == currentUserId &&
              t.initiatorUserId != currentUserId,
        )
        .toList();

    debugPrint(
      'TradeListScreen FILTER - myOffers: ${myOffers.length}, receivedOffers: ${receivedOffers.length}',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Trueques'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Mis Ofertas (${myOffers.length})'),
            Tab(text: 'Ofertas Recibidas (${receivedOffers.length})'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: provider.isLoading && provider.myTrades.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Mis Ofertas
                  myOffers.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 120),
                            const Center(
                              child: Text('No has hecho ofertas aún.'),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                'Total trueques: ${provider.myTrades.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 12, bottom: 24),
                          itemCount: myOffers.length,
                          itemBuilder: (context, idx) {
                            final trade = myOffers[idx];
                            return TradeCard(trade: trade);
                          },
                        ),
                  // Tab 2: Ofertas Recibidas
                  receivedOffers.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 120),
                            const Center(
                              child: Text('No tienes ofertas recibidas.'),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                'Total trueques: ${provider.myTrades.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 12, bottom: 24),
                          itemCount: receivedOffers.length,
                          itemBuilder: (context, idx) {
                            final trade = receivedOffers[idx];
                            return TradeCard(trade: trade);
                          },
                        ),
                ],
              ),
      ),
    );
  }
}
