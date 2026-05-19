import 'package:flutter/material.dart';
import 'package:pbshop/widgets/mostrarestrellas.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbshop/servicios/CartService.dart' as CartServiceLib;
import 'package:pbshop/widgets/CuadroDeImagenes.dart';
import 'package:intl/intl.dart';
import 'package:pbshop/servicios/HorarioHelper.dart';

class product_page extends StatefulWidget {
  final Map producto;
  const product_page({super.key, required this.producto});

  @override
  State<product_page> createState() => _product_pageState();
}

class _product_pageState extends State<product_page> {
  bool _estaProcesando = false;
  bool _puedeResenar = false;
  bool _esEdicion = false;
  String? _idPedidoMapeado;
  String? _idResenaExistente;
  double _estrellasPrevias = 0;
  String _comentarioPrevio = "";
  
  final f = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

  // Color institucional turquesa
  final Color _colorInstitucional = const Color.fromRGBO(0, 180, 195, 1);

  @override
  void initState() {
    super.initState();
    _verificarCompraDelProducto();
  }

  Future<void> _verificarCompraDelProducto() async {
    try {
      final usuarioId = Supabase.instance.client.auth.currentUser?.id;
      if (usuarioId == null) return;

      final List<dynamic> compraData = await Supabase.instance.client
          .from('detalles_pedido')
          .select('fk_pedido, pedidos!inner(id_usuario, estado)')
          .eq('fk_producto', widget.producto['id'])
          .eq('pedidos.id_usuario', usuarioId)
          .eq('pedidos.estado', 'entregado')
          .limit(1);

      if (compraData.isNotEmpty && mounted) {
        _idPedidoMapeado = compraData[0]['fk_pedido'].toString();

        final List<dynamic> resenaData = await Supabase.instance.client
            .from('resenas')
            .select('id, puntuacion, comentario')
            .eq('fk_producto', widget.producto['id'])
            .eq('fk_usuario', usuarioId)
            .limit(1);

        if (mounted) {
          setState(() {
            _puedeResenar = true; 
            if (resenaData.isNotEmpty) {
              _esEdicion = true;
              _idResenaExistente = resenaData[0]['id'].toString();
              _estrellasPrevias = (resenaData[0]['puntuacion'] as num).toDouble();
              _comentarioPrevio = resenaData[0]['comentario'] ?? "";
            } else {
              _esEdicion = false;
              _idResenaExistente = null;
              _estrellasPrevias = 0;
              _comentarioPrevio = "";
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error verificando compra o reseña del producto: $e");
    }
  }

  Future<List<String>> _obtenerFotos() async {
    try {
      final String productoId = widget.producto['id'].toString();
      final response = await Supabase.instance.client
          .from('imagenes_producto')
          .select('url')
          .eq('fk_producto', productoId)
          .timeout(const Duration(seconds: 4));

      final listaUrls = (response as List).map((item) => item['url'].toString()).toList();
      if (listaUrls.isEmpty && widget.producto['imagen_url'] != null) {
        return [widget.producto['imagen_url']];
      }
      return listaUrls;
    } catch (e) {
      return [widget.producto['imagen_url'] ?? ''];
    }
  }

  void _mostrarModalResena(bool isDarkMode, Color colorPB) async {
    final TextEditingController controller = TextEditingController(text: _esEdicion ? _comentarioPrevio : "");
    double estrellas = _esEdicion ? _estrellasPrevias : 0;

    final Map<String, dynamic>? resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _esEdicion ? "Actualizar mi opinión" : "¿Qué tal estuvo el producto?", 
          textAlign: TextAlign.center,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RatingBarCustom(
              initialRating: estrellas.toInt(),
              onRatingSelected: (val) => estrellas = val.toDouble(),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: controller,
              maxLines: 2,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: "Escribe tu opinión sobre este producto...",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true, 
                fillColor: isDarkMode ? Colors.white10 : Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null), 
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            onPressed: () async {
              if (estrellas == 0) return;

              final comentarioTexto = controller.text.trim();

              try {
                if (_esEdicion) {
                  await Supabase.instance.client
                      .from('resenas')
                      .update({
                        'puntuacion': estrellas.toInt(),
                        'comentario': comentarioTexto,
                      })
                      .eq('id', _idResenaExistente!);
                  
                  if (context.mounted) {
                    Navigator.pop(context, {
                      'puntuacion': estrellas,
                      'comentario': comentarioTexto,
                      'id_resena': _idResenaExistente,
                    });
                  }
                } else {
                  final nuevaResena = await Supabase.instance.client.from('resenas').insert({
                    'fk_pedido': _idPedidoMapeado,
                    'puntuacion': estrellas.toInt(),
                    'comentario': comentarioTexto,
                    'fk_usuario': Supabase.instance.client.auth.currentUser!.id,
                    'fk_producto': widget.producto['id'], 
                  }).select('id').single();
                  
                  if (context.mounted) {
                    Navigator.pop(context, {
                      'puntuacion': estrellas,
                      'comentario': comentarioTexto,
                      'id_resena': nuevaResena['id'].toString(),
                    });
                  }
                }
              } catch (e) {
                debugPrint("Error al procesar la reseña: $e");
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: colorPB),
            child: Text(
              _esEdicion ? "ACTUALIZAR" : "ENVIAR", 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
    );

    if (resultado != null && mounted) {
      setState(() {
        _esEdicion = true; 
        _estrellasPrevias = (resultado['puntuacion'] as num).toDouble();
        _comentarioPrevio = resultado['comentario'].toString();
        _idResenaExistente = resultado['id_resena'].toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String imagenSegura = widget.producto['imagen_url'] ?? '';
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    final String horarioTienda = widget.producto['horario']?.toString() ?? "24 Horas";
    final bool estaAbierto = HorarioHelper.estaAbierto(horarioTienda);

    return Scaffold(
      backgroundColor: esOscuro ? Colors.black : Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: esOscuro ? Colors.black54 : Colors.white.withOpacity(0.9), 
            shape: BoxShape.circle
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: esOscuro ? Colors.white : Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 40), 
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              width: double.infinity,
              child: FutureBuilder<List<String>>(
                future: _obtenerFotos(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: _colorInstitucional));
                  }
                  final urls = snapshot.data ?? [imagenSegura];
                  return CuadroDeImagenes(urls: urls);
                },
              ),
            ),

            Transform.translate(
              offset: const Offset(0, -30),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 35),
                decoration: BoxDecoration(
                  color: esOscuro ? const Color(0xFF121212) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1), 
                      blurRadius: 10, 
                      offset: const Offset(0, -5)
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.producto['nombre'] ?? '',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                          ),
                        ),
                        Text(
                          f.format(widget.producto['precio']),
                          style: TextStyle(fontSize: 22, color: _colorInstitucional, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildBadgeTienda(esOscuro),
                    const SizedBox(height: 30),
                    const Text("Descripción", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(
                      widget.producto['descripcion'] ?? "Este producto no tiene descripción.",
                      style: TextStyle(
                        fontSize: 15, 
                        color: esOscuro ? Colors.grey[400] : Colors.grey[700], 
                        height: 1.6
                      ),
                    ),
                    const SizedBox(height: 35),
                    const Text("Reseñas de la comunidad", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    _seccionResenasReales(esOscuro),
                    const SizedBox(height: 120), 
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBarraAccionCompra(esOscuro, estaAbierto),
    );
  }

  Widget _buildBadgeTienda(bool esOscuro) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: esOscuro ? Colors.grey[900] : Colors.grey[100], 
        borderRadius: BorderRadius.circular(15)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.storefront, size: 18, color: _colorInstitucional),
          const SizedBox(width: 8),
          Text(
            "Vendido por ${widget.producto['nombre_negocio'] ?? 'Emprendedor PB'}", 
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)
          ),
        ],
      ),
    );
  }

  Widget _buildBarraAccionCompra(bool esOscuro, bool estaAbierto) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: esOscuro ? const Color(0xFF121212) : Colors.white,
        border: Border(top: BorderSide(color: esOscuro ? Colors.white10 : Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: ElevatedButton(
          // 👈 AQUÍ ESTÁ EL CAMBIO CLAVE:
          // Si está cargando o la tienda está cerrada, pasamos 'null' para apagar por completo el botón.
          onPressed: (_estaProcesando || !estaAbierto) 
              ? null 
              : () => _agregarAlPedido(context),
          style: ElevatedButton.styleFrom(
            // Color cuando está activo vs color gris por defecto de Flutter cuando se pasa null
            backgroundColor: _colorInstitucional, 
            foregroundColor: Colors.white,
            // Ajustamos el color de deshabilitado explícitamente para que mantenga tu estética limpia
            disabledBackgroundColor: esOscuro ? Colors.grey[900] : Colors.grey[300],
            disabledForegroundColor: esOscuro ? Colors.grey[600] : Colors.grey[500],
            minimumSize: const Size(double.infinity, 60),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: _estaProcesando 
            ? const SizedBox(
                height: 25, 
                width: 25, 
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
              )
            : Text(
                estaAbierto ? "Agregar al carrito" : "Local Cerrado",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
        ),
      ),
    );
  }

  void _agregarAlPedido(BuildContext context) {
    setState(() => _estaProcesando = true);
    try {
      CartServiceLib.CartService().agregarProducto({
        'id': widget.producto['id'].toString(),
        'nombre': widget.producto['nombre'],
        'precio': (widget.producto['precio'] as num).toDouble(),
        'fk_negocio': widget.producto['fk_negocio'],
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("¡Producto añadido con éxito!", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF007025),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(20),
        )
      );
    } catch (e) {
      debugPrint("Error al agregar al carrito: $e");
    } finally {
      setState(() => _estaProcesando = false);
    }
  }

  Widget _seccionResenasReales(bool esOscuro) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('resenas')
          .stream(primaryKey: ['id'])
          .eq('fk_producto', widget.producto['id']),
      builder: (context, snapshot) {
        List<Map<String, dynamic>> resenas = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_puedeResenar) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: ElevatedButton.icon(
                  onPressed: () => _mostrarModalResena(esOscuro, _colorInstitucional),
                  icon: Icon(_esEdicion ? Icons.edit_note_rounded : Icons.rate_review_rounded, color: Colors.white),
                  label: Text(
                    _esEdicion ? "Editar mi reseña" : "Calificar este producto", 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _esEdicion ? Colors.amber[800] : _colorInstitucional,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                ),
              ),
            ],

            if (resenas.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: esOscuro ? Colors.white.withOpacity(0.05) : Colors.grey[50], 
                  borderRadius: BorderRadius.circular(20)
                ),
                child: const Center(
                  child: Text("Aún no hay opiniones. ¡Sé el primero!", style: TextStyle(fontStyle: FontStyle.italic))
                ),
              )
            else
              Column(
                children: resenas.map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: esOscuro ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      mostrarEstrellas(r['puntuacion'] ?? 0),
                      const SizedBox(height: 10),
                      Text(
                        r['comentario'] ?? "", 
                        style: TextStyle(
                          fontSize: 14, 
                          fontStyle: FontStyle.italic,
                          color: esOscuro ? Colors.grey[300] : Colors.black87
                        )
                      ),
                    ],
                  ),
                )).toList(),
              ),
          ],
        );
      },
    );
  }
}

class RatingBarCustom extends StatefulWidget {
  final int initialRating; 
  final Function(double) onRatingSelected;
  
  const RatingBarCustom({
    super.key, 
    this.initialRating = 0, 
    required this.onRatingSelected
  });

  @override
  State<RatingBarCustom> createState() => _RatingBarCustomState();
}

class _RatingBarCustomState extends State<RatingBarCustom> {
  int _rating = 0;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating; 
  }

  @override
  void didUpdateWidget(covariant RatingBarCustom oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRating != widget.initialRating) {
      _rating = widget.initialRating;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
            color: Colors.amber,
            size: 36,
          ),
          onPressed: () {
            setState(() => _rating = index + 1);
            widget.onRatingSelected(_rating.toDouble());
          },
        );
      }),
    );
  }
}