import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbshop/widgets/CartaProducto.dart';
import 'package:pbshop/widgets/BarraEmpresas.dart';
import 'package:pbshop/widgets/EncabezadoAnimado.dart';
import 'package:pbshop/widgets/BuscadorWidget.dart';
import 'package:pbshop/widgets/Filtros.dart';
import 'package:pbshop/servicios/HorarioHelper.dart'; // 👈 Importamos el nuevo Helper

class InicioContent extends StatefulWidget {
  const InicioContent({super.key});

  @override
  State<InicioContent> createState() => _InicioContentState();
}

class _InicioContentState extends State<InicioContent> {
  final supabase = Supabase.instance.client;

  // --- VARIABLES DE CONTROL DE FILTROS ---
  String textoBusqueda = "";
  String? categoriaIdActiva; // Almacena el UUID de la categoría seleccionada
  RangeValues rangoActual = const RangeValues(0, 150000); // Rango inicial por defecto
  final RangeValues rangoMaximo = const RangeValues(0, 200000); // El tope que maneja la App

  // Lista dinámica para guardar las categorías de la base de datos
  List<Map<String, dynamic>> listaCategoriasDeLaDB = [];

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  // Carga las categorías desde Supabase de forma asíncrona al iniciar
  Future<void> _cargarCategorias() async {
    try {
      final List<dynamic> data = await supabase
          .from('categorias')
          .select('id, nombre')
          .order('nombre', ascending: true);

      if (mounted) {
        setState(() {
          listaCategoriasDeLaDB = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint("Error al cargar categorías en Inicio: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definimos el stream de productos en tiempo real
    final Stream<List<Map<String, dynamic>>> productosStream = supabase
        .from('v_productos_con_rating')
        .stream(primaryKey: ['id']);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const EncabezadoAnimado(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                BuscadorWidget(
                  onChanged: (query) {
                    setState(() {
                      textoBusqueda = query;
                    });
                  },
                  onFilterPressed: () {
                    FiltrosModal.mostrar(
                      context,
                      categorias: listaCategoriasDeLaDB, 
                      categoriaSeleccionada: categoriaIdActiva, 
                      rangoPreciosSeleccionado: rangoActual, 
                      rangoMaximoPrecios: rangoMaximo, 
                      onAplicarFiltros: (idCat, rangoPrecios) {
                        setState(() {
                          categoriaIdActiva = idCat;
                          rangoActual = rangoPrecios;
                        });
                      },
                    );
                  },
                ),
                const BarraEmpresas(),
              ],
            ),
          ),
          
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: productosStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(50.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }

              List<Map<String, dynamic>> productos = snapshot.data ?? [];

              // --- TUBERÍA DE FILTRADO LOCAL (OPTIMIZA VELOCIDAD Y CONSUMO) ---

              // Filtro 1: Barra de búsqueda por texto
              if (textoBusqueda.isNotEmpty) {
                productos = productos.where((item) {
                  final nombre = item['nombre'].toString().toLowerCase();
                  final consulta = textoBusqueda.toLowerCase();
                  return nombre.contains(consulta);
                }).toList();
              }

              // Filtro 2: Filtrado por Categoría (UUID)
              if (categoriaIdActiva != null) {
                productos = productos.where((item) {
                  return item['fk_categoria'].toString() == categoriaIdActiva;
                }).toList();
              }

              // Filtro 3: Filtrado por Rango de Precios
              productos = productos.where((item) {
                final precio = num.tryParse(item['precio'].toString()) ?? 0;
                return precio >= rangoActual.start && precio <= rangoActual.end;
              }).toList();

              // --- INTEGRACIÓN: VALIDACIÓN DE HORARIOS CON HELPER CENTRALIZADO ---
              for (var item in productos) {
                final String horarioLocal = item['horario']?.toString() ?? "24 Horas";
                
                // 👈 Evaluamos directamente con el HorarioHelper global
                item['esta_abierto'] = HorarioHelper.estaAbierto(horarioLocal);
              }

              // Mezclar el resultado únicamente si no hay criterios de filtrado activos
              if (textoBusqueda.isEmpty && 
                  categoriaIdActiva == null && 
                  rangoActual.start == rangoMaximo.start && 
                  rangoActual.end == rangoMaximo.end) {
                productos.shuffle(); 
              }

              if (productos.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text(
                        "No se encontraron productos con estos filtros",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),
                );
              }

              // GRID DINÁMICO Y RESPONSIVO
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200, 
                    mainAxisSpacing: 12,    
                    crossAxisSpacing: 12,   
                    mainAxisExtent: 260,    
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return CartaProducto(producto: productos[index]);
                    },
                    childCount: productos.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}