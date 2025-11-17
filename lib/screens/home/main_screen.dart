import 'package:provider/provider.dart';
import '../../providers/listing_provider.dart';
import '../../core/app_export.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter/services.dart';
import '../../dto/listing/listing_create_dto.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/trade_provider.dart';
import '../../dto/trade/trade_status.dart';
import '../../dto/trade/trade_dto.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
        _HomeTab(),
        _BrowseTab(),
        _AddItemTab(),
        _MessagesTab(),
        _WalletTab(),
      ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('TruekApp'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _showMenu(context, auth),
        ),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explorar'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Publicar'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Mensajes'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Billetera'),
        ],
      ),
    );
  }

  void _showMenu(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Ver perfil'),
                onTap: () {
                  Navigator.pop(context);
                  // Por ahora solo muestra diálogo sencillo
                  showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                            title: const Text('Perfil'),
                            content: Text(auth.user != null
                                ? 'Usuario: ${auth.user!.email}'
                                : 'No hay usuario cargado'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cerrar'))
                            ],
                          ));
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Cerrar sesión'),
                onTap: () {
                  Navigator.pop(context);
                  auth.logout();
                  // Volver al login
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- Tabs ---
class _HomeTab extends StatefulWidget {
  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _searchController = TextEditingController();

  @override
void initState() {
  super.initState();
  
  // CORRECTO: Ejecuta la lógica después del primer build.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Usamos 'listen: false' porque estamos en initState.
    // La UI se actualizará mediante los Consumers o Selectors en el método build().
    Provider.of<ListingProvider>(context, listen: false).fetchCatalog();
  });
}

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // Usamos Consumer para que la UI reaccione a los cambios del ListingProvider
    return Consumer<ListingProvider>(
      builder: (context, listingProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // (Esta parte del balance se mantiene igual)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Ubicación: Ciudad de Ejemplo',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      Text('TrueCoin Balance',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  Card(
                    color: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Column(
                        children: [
                          Text('${auth.user?.trueCoinBalance ?? 120}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          const Text('TrueCoins',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // TextField de Búsqueda funcional
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar productos...'),
                onSubmitted: (query) {
                  // Al presionar Enter, llamamos al fetch con el filtro 'q'
                  listingProvider.fetchCatalog(q: query);
                },
              ),
              const SizedBox(height: 16),
              const Text('Destacados',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),

              // --- CONTENIDO DINÁMICO (Destacados) ---
              listingProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        // Usamos la longitud de la lista del provider
                        itemCount: listingProvider.listings.length,
                        itemBuilder: (context, index) {
                          // Obtenemos el listado específico
                          final listing = listingProvider.listings[index];

                          return Container(
                            width: 220,
                            margin: const EdgeInsets.only(right: 12),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Imagen dinámica
                                  Image.network(
                                    listing.imageUrl,
                                    height: 100,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    // Placeholder mientras carga
                                    loadingBuilder:
                                        (context, child, progress) {
                                      return progress == null
                                          ? child
                                          : Container(
                                              height: 100,
                                              color: Colors.grey[300]);
                                    },
                                    // Manejo de error si la URL falla
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      return Container(
                                          height: 100,
                                          color: Colors.grey[300],
                                          child:
                                              const Icon(Icons.error_outline));
                                    },
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Título dinámico
                                        Text(listing.title,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 4),
                                        // Valor dinámico
                                        Text(
                                            '${listing.trueCoinValue} TrueCoins',
                                            style: const TextStyle(
                                                color: Colors.green)),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

              const SizedBox(height: 16),
              const Text('Recientes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),

              // --- CONTENIDO DINÁMICO (Recientes) ---
              listingProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: listingProvider.listings.length,
                      itemBuilder: (context, index) {
                        final listing = listingProvider.listings[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(listing.imageUrl),
                            onBackgroundImageError: (e, s) => {},
                            backgroundColor: Colors.grey[300],
                          ),
                          title: Text(listing.title),
                          subtitle:
                              Text('${listing.trueCoinValue} TrueCoins • Cerca de ti'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pushNamed(
                              context, 
                              AppRoutes.listingDetail, 
                              arguments: listing.id // <-- Enviamos el ID como argumento
                            );
                          },
                        );
                      },
                    ),
            ],
          ),
        );
      },
    );
  }
}

class _BrowseTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.explore, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text('Explorar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _AddItemTab extends StatefulWidget {
  @override
  State<_AddItemTab> createState() => _AddItemTabState();
}

class _AddItemTabState extends State<_AddItemTab> {
  // Clave para validar el formulario
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos de texto
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _valueController = TextEditingController();
  final _imageUrlController = TextEditingController(); // Requerido por el DTO

  // Estado de carga
  bool _isLoading = false;

  /// Lógica para manejar la publicación
  Future<void> _handlePublish() async {
    // 1. Validar el formulario
    if (!_formKey.currentState!.validate()) {
      return; // Si hay errores, no continuar
    }

    setState(() => _isLoading = true);

    try {
      // 2. Obtener la ubicación del dispositivo
      Position position;
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            throw Exception("Permiso de ubicación denegado.");
          }
        }
        if (permission == LocationPermission.deniedForever) {
          throw Exception("Permiso de ubicación denegado permanentemente.");
        }
        // Obtenemos la ubicación actual
        position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium);
      } catch (e) {
        throw Exception("Error al obtener ubicación: ${e.toString()}");
      }

      // 3. Parsear valores de los controladores
      final title = _titleController.text;
      final description = _descController.text;
      final imageUrl = _imageUrlController.text;
      final trueCoinValue = double.tryParse(_valueController.text);

      if (trueCoinValue == null) {
        throw Exception("El valor de TrueCoins es inválido.");
      }

      // 4. Crear el DTO (Data Transfer Object)
      final dto = ListingCreateDto(
        title: title,
        description: description,
        trueCoinValue: trueCoinValue,
        imageUrl: imageUrl, // El backend lo requiere
        latitude: position.latitude,
        longitude: position.longitude,
        // 'address' es opcional en el backend, por lo que no lo enviamos por ahora
      );

      // 5. Llamar al Provider
      // Usamos 'listen: false' porque estamos dentro de una función
      await Provider.of<ListingProvider>(context, listen: false)
          .createListing(dto);

      // 6. Éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Publicación creada con éxito"),
            backgroundColor: AppColors.successColor), // Usando color de tu tema
      );
      _clearForm();
    } catch (e) {
      // 7. Error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: AppColors.errorColor), // Usando color de tu tema
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Limpia los campos del formulario después de publicar
  void _clearForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _descController.clear();
    _valueController.clear();
    _imageUrlController.clear();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _valueController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reemplazamos el Column simple por un Form con SingleChildScrollView
    // para profesionalismo y evitar overflow del teclado.
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'El título es requerido' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
                // Descripción es opcional, no necesita validador
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _valueController,
                decoration:
                    const InputDecoration(labelText: 'Valor (TrueCoins)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                // Filtro profesional para aceptar solo números y dos decimales
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                ],
                validator: (v) =>
                    v == null || v.isEmpty ? 'El valor es requerido' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'URL de la Imagen'),
                keyboardType: TextInputType.url,
                validator: (v) => v == null || v.isEmpty
                    ? 'La URL de la imagen es requerida'
                    : null,
              ),
              const SizedBox(height: 16),

              // Botón de carga dinámico
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _handlePublish, // Conectamos la lógica
                      child: const Text('Publicar'),
                    )
            ],
          ),
        ),
      ),
    );
  }
}

class _MessagesTab extends StatefulWidget {
  @override
  State<_MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<_MessagesTab> {
  @override
  void initState() {
    super.initState();
    // Cargar los trades del usuario al iniciar la pestaña
    // Usamos 'listen: false' en initState
    Provider.of<TradeProvider>(context, listen: false).fetchMyTrades();
  }

  // --- Helpers para mostrar el estado del Trueque ---

  // Devuelve un texto legible para el estado
  String _getStatusText(TradeStatus status) {
    switch (status) {
      case TradeStatus.Pending:
        return "Pendiente";
      case TradeStatus.Accepted:
        return "Aceptado";
      case TradeStatus.Rejected:
        return "Rechazado";
      case TradeStatus.Completed:
        return "Completado";
      case TradeStatus.Cancelled:
        return "Cancelado";
      default:
        return "Desconocido";
    }
  }

  // Devuelve un color para el chip de estado
  Color _getStatusColor(TradeStatus status) {
    switch (status) {
      case TradeStatus.Pending:
        return Colors.orangeAccent;
      case TradeStatus.Accepted:
        return Colors.blueAccent;
      case TradeStatus.Completed:
        return Colors.green;
      case TradeStatus.Rejected:
      case TradeStatus.Cancelled:
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  // --- Fin de Helpers ---

  @override
  Widget build(BuildContext context) {
    // Usamos Consumer para que la UI reaccione a los cambios del TradeProvider
    return Consumer<TradeProvider>(
      builder: (context, tradeProvider, child) {
        // 1. Manejar estado de carga
        if (tradeProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. Manejar estado vacío
        if (tradeProvider.myTrades.isEmpty) {
          return const Center(
            child: Text(
              "No tienes conversaciones de trueques.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        // 3. Mostrar la lista de trueques (conversaciones)
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tradeProvider.myTrades.length,
          itemBuilder: (context, index) {
            // Obtenemos el trade específico
            final trade = tradeProvider.myTrades[index];

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.person_outline,
                    color: Colors.white), // Placeholder
              ),
              title: Text('Trueque #${trade.id}'),
              subtitle: Text(
                trade.message ?? 'Ver detalles del trueque...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Usamos un Chip para el estado
              trailing: Chip(
                label: Text(
                  _getStatusText(trade.status),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                backgroundColor: _getStatusColor(trade.status),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              ),
              onTap: () {
                // --- PRÓXIMO PASO ---
                // Aquí es donde debemos navegar a una nueva pantalla de chat.
                // Como aún no existe, mostramos un SnackBar temporal.
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'TODO: Abrir pantalla de chat para Trade ID: ${trade.id}'),
                  ),
                );
                // El código final sería:
                // Navigator.pushNamed(context, AppRoutes.tradeChat, arguments: trade.id);
              },
            );
          },
        );
      },
    );
  }
}
class _WalletTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TrueCoin Balance', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                const Text('120', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: () {}, child: const Text('Recargar'))
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            itemBuilder: (context, index) => ListTile(
              leading: Icon(index % 2 == 0 ? Icons.add : Icons.remove, color: index % 2 == 0 ? Colors.green : Colors.red),
              title: Text(index % 2 == 0 ? '+20 TrueCoins' : '-10 TrueCoins'),
              subtitle: const Text('Movimiento de ejemplo'),
            ),
          )
        ],
      ),
    );
  }
}
