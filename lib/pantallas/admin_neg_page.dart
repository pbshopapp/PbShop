import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbshop/servicios/ProductosService.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class admin_neg_page extends StatefulWidget {
  const admin_neg_page({super.key});

  @override
  State<admin_neg_page> createState() => _AdminNegPageState();
}

class _AdminNegPageState extends State<admin_neg_page> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? datosNegocio;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosNegocio();
  }

  Future<void> _cargarDatosNegocio() async {
  try {
    final user = _supabase.auth.currentUser;
    print("DEBUG: ID de usuario logueado: ${user?.id}");

    final perfil = await _supabase
        .from('perfiles')
        .select('fk_negocio')
        .eq('id', user!.id)
        .single();
    
    print("DEBUG: FK_Negocio encontrado en perfil: ${perfil['fk_negocio']}");

    if (perfil['fk_negocio'] != null) {
      final negocio = await _supabase
          .from('negocios')
          .select()
          .eq('id', perfil['fk_negocio'])
          .single();

      print("DEBUG: Negocio cargado: ${negocio['nombre']}");
      setState(() {
        datosNegocio = negocio;
        _cargando = false;
      });
    } else {
      print("DEBUG: El usuario no tiene FK_NEGOCIO asignado");
      setState(() => _cargando = false);
    }
  } catch (e) {
    print("DEBUG: ERROR CATASTRÓFICO: $e");
    setState(() => _cargando = false);
  }
}

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color.fromRGBO(0, 180, 195, 1))),
      );
    }

    if (datosNegocio == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Panel Admin")),
        body: const Center(
          child: Text("No tienes un negocio vinculado a tu cuenta."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel de Administración"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderNegocio(),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              "Tus Productos Publicados",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildListaProductos(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderNegocio() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                backgroundImage: NetworkImage(
                  datosNegocio!['imagen_url'] ?? 'https://via.placeholder.com/150',
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  backgroundColor: const Color.fromRGBO(0, 180, 195, 1),
                  radius: 18,
                  child: IconButton(
                    icon: const Icon(Icons.edit, size: 15, color: Colors.white),
                    onPressed: () { /* Lógica para editar foto */ },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            datosNegocio!['nombre'] ?? "Mi Negocio",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _mostrarVentanaNuevoProducto(context),
            icon: const Icon(Icons.add),
            label: const Text("Agregar Producto Nuevo"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(0, 180, 195, 1),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaProductos() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('productos')
          .stream(primaryKey: ['id'])
          .eq('fk_negocio', datosNegocio!['id']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final productos = snapshot.data ?? [];

        if (productos.isEmpty) {
          return const Center(
            child: Text("Aún no tienes productos registrados."),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: productos.length,
          itemBuilder: (context, index) {
            final prod = productos[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.inventory_2, color: Color.fromRGBO(0, 180, 195, 1)),
                title: Text(prod['nombre']),
                subtitle: Text("\$${prod['precio']}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmarEliminacion(prod['id'], prod['nombre']),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmarEliminacion(int id, String nombre) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar producto"),
        content: Text("¿Estás seguro de eliminar $nombre?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              await _supabase.from('productos').delete().eq('id', id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

void _mostrarVentanaNuevoProducto(BuildContext context) {
  final nomController = TextEditingController();
  final preController = TextEditingController();
  final descController = TextEditingController(); 
  
  // Lista para guardar las imágenes seleccionadas localmente
  List<XFile> imagenesSeleccionadas = []; 

  // Variable de control para evitar que se abra la galería dos veces
  bool estaAbriendoGaleria = false; 

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20))
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) {
        
        // Función interna para seleccionar imágenes con protección
        Future<void> seleccionarImagenes() async {
          if (estaAbriendoGaleria) return; // Bloqueo si ya está activa

          try {
            estaAbriendoGaleria = true; 
            final ImagePicker picker = ImagePicker();
            
            // Abrir selector múltiple
            final List<XFile> images = await picker.pickMultiImage();
            
            if (images.isNotEmpty) {
              setModalState(() {
                // Agregamos las nuevas a las existentes y limitamos a 3
                imagenesSeleccionadas = [...imagenesSeleccionadas, ...images].take(3).toList();
              });
            }
          } catch (e) {
            debugPrint("Error al seleccionar imágenes: $e");
          } finally {
            estaAbriendoGaleria = false; // Liberar el bloqueo siempre
          }
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Nuevo Producto", 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Text("Completa los datos para publicar", 
                  style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                
                // Campo Nombre
                TextField(
                  controller: nomController, 
                  decoration: const InputDecoration(
                    labelText: "Nombre del producto", 
                    border: OutlineInputBorder()
                  )
                ),
                const SizedBox(height: 15),

                // Campo Descripción
                TextField(
                  controller: descController, 
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Descripción", 
                    border: OutlineInputBorder(), 
                    alignLabelWithHint: true
                  )
                ),
                const SizedBox(height: 15),

                // Campo Precio (Corregido para Android)
                TextField(
                  controller: preController, 
                  decoration: const InputDecoration(
                    labelText: "Precio", 
                    border: OutlineInputBorder(), 
                    prefixText: "\$ "
                  ), 
                  keyboardType: TextInputType.number
                ),
                const SizedBox(height: 20),

                // Sección de Selección de Imágenes
                const Text("Imágenes (Máximo 3)", 
                  style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                
                Row(
                  children: [
                    // Botón para agregar nueva foto
                    if (imagenesSeleccionadas.length < 3)
                      GestureDetector(
                        onTap: seleccionarImagenes,
                        child: Container(
                          height: 80, width: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey), 
                            borderRadius: BorderRadius.circular(10)
                          ),
                          child: const Icon(Icons.add_a_photo, color: Colors.grey),
                        ),
                      ),
                    const SizedBox(width: 10),
                    
                    // Lista horizontal de vistas previas
                    Expanded(
                      child: SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: imagenesSeleccionadas.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  width: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    image: DecorationImage(
                                      image: FileImage(File(imagenesSeleccionadas[index].path)),
                                      fit: BoxFit.cover
                                    )
                                  ),
                                ),
                                // Botón para eliminar imagen individual
                                Positioned(
                                  top: 0, right: 5,
                                  child: GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        imagenesSeleccionadas.removeAt(index);
                                      });
                                    },
                                    child: const CircleAvatar(
                                      radius: 10, 
                                      backgroundColor: Colors.red, 
                                      child: Icon(Icons.close, size: 12, color: Colors.white)
                                    ),
                                  ),
                                )
                              ],
                            );
                          },
                        ),
                      ),
                    )
                  ],
                ),
                
                const SizedBox(height: 25),
                
                // Botón Publicar Ahora
                ElevatedButton(
                  onPressed: () async {
                    if (nomController.text.isNotEmpty && preController.text.isNotEmpty) {
                      try {
                        // Asegúrate de que ProductosService reciba double y la lista de XFile
                        await ProductosService().crearProductoAutomatico(
                          context, 
                          nomController.text, 
                          double.parse(preController.text), 
                          descController.text, 
                          imagenesSeleccionadas, 
                        );
                        
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        debugPrint("Error al publicar: $e");
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50), 
                    backgroundColor: Colors.green, 
                    foregroundColor: Colors.white
                  ),
                  child: const Text("Publicar Ahora"),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      }
    ),
  );
}
}