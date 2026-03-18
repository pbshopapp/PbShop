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
  List<Map<String, dynamic>> categorias = [];
  String? categoriaSeleccionada;

  @override
  void initState() {
    super.initState();
    _cargarDatosNegocio();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    final data = await _supabase.from('categorias').select('id, nombre');
    setState(() {
      categorias = List<Map<String, dynamic>>.from(data);
    });
  }

  Future<void> _cargarDatosNegocio() async {
    try {
      final user = _supabase.auth.currentUser;
      final perfil = await _supabase
          .from('perfiles')
          .select('fk_negocio')
          .eq('id', user!.id)
          .single();

      if (perfil['fk_negocio'] != null) {
        final negocio = await _supabase
            .from('negocios')
            .select()
            .eq('id', perfil['fk_negocio'])
            .single();

        setState(() {
          datosNegocio = negocio;
          _cargando = false;
        });
      } else {
        setState(() => _cargando = false);
      }
    } catch (e) {
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
        body: const Center(child: Text("No tienes un negocio vinculado.")),
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
          children: [
            _buildHeaderNegocio(),
            const SizedBox(height: 30),
            const Divider(),
            const Text("Tus Productos Publicados", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(datosNegocio!['imagen_url'] ?? 'https://via.placeholder.com/150'),
          ),
          const SizedBox(height: 15),
          Text(datosNegocio!['nombre'] ?? "Mi Negocio", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
      stream: _supabase.from('productos').stream(primaryKey: ['id']).eq('fk_negocio', datosNegocio!['id']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
        final productos = snapshot.data ?? [];
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: productos.length,
          itemBuilder: (context, index) {
            final prod = productos[index];
            return ListTile(
              title: Text(prod['nombre']),
              subtitle: Text("\$${prod['precio']}"),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _confirmarEliminacion(prod['id'], prod['nombre']),
              ),
            );
          },
        );
      },
    );
  }

void _confirmarEliminacion(dynamic id, String nombre) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Eliminar Producto"),
      content: Text("¿Estás seguro de eliminar \"$nombre\"? Se borrarán sus datos y archivos del servidor."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        TextButton(
          onPressed: () async {
            try {
              final String productoId = id.toString();
              // Obtenemos el ID del negocio que ya tienes cargado en la clase
              final String negocioId = datosNegocio!['id'].toString();

              // 1. RUTA DINÁMICA SEGÚN TU ESTRUCTURA
              // La ruta es: "ID_NEGOCIO/ID_PRODUCTO"
              final String rutaCarpeta = "$negocioId/$productoId";

              debugPrint("Listando archivos en: $rutaCarpeta");

              // 2. LISTAR ARCHIVOS DENTRO DE LA CARPETA DEL PRODUCTO
              final List<FileObject> archivos = await _supabase
                  .storage
                  .from('productos')
                  .list(path: rutaCarpeta);

              if (archivos.isNotEmpty) {
                // Creamos las rutas completas para borrar: "negocio/producto/archivo.jpg"
                final List<String> rutasABorrar = archivos
                    .map((file) => "$rutaCarpeta/${file.name}")
                    .toList();

                // 3. BORRAR ARCHIVOS FÍSICOS
                await _supabase
                    .storage
                    .from('productos')
                    .remove(rutasABorrar);
                
                debugPrint("✅ Archivos borrados: ${rutasABorrar.length}");
              }

              // 4. BORRAR REGISTRO DE LA BASE DE DATOS
              await _supabase
                  .from('productos')
                  .delete()
                  .eq('id', productoId);

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("✅ $nombre eliminado por completo"))
                );
              }
            } catch (e) {
              debugPrint("❌ Error en borrado total: $e");
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                );
              }
            }
          },
          child: const Text("Eliminar", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

  void _mostrarVentanaNuevoProducto(BuildContext context) {
    final nomController = TextEditingController();
    final preController = TextEditingController();
    final descController = TextEditingController();
    List<XFile> imagenesSeleccionadas = [];
    bool estaAbriendoGaleria = false;
    bool estaPublicando = false; // ESTADO PARA EL BOTÓN

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> seleccionarImagenes() async {
            if (estaAbriendoGaleria) return;
            try {
              estaAbriendoGaleria = true;
              final List<XFile> images = await ImagePicker().pickMultiImage();
              if (images.isNotEmpty) {
                setModalState(() {
                  imagenesSeleccionadas = [...imagenesSeleccionadas, ...images].take(3).toList();
                });
              }
            } finally {
              estaAbriendoGaleria = false;
            }
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Nuevo Producto", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(controller: nomController, decoration: const InputDecoration(labelText: "Nombre", border: OutlineInputBorder())),
                  const SizedBox(height: 15),
                  TextField(controller: descController, maxLines: 2, decoration: const InputDecoration(labelText: "Descripción", border: OutlineInputBorder())),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: categoriaSeleccionada,
                    items: categorias.map((cat) => DropdownMenuItem(value: cat['id'].toString(), child: Text(cat['nombre']))).toList(),
                    onChanged: (val) => setModalState(() => categoriaSeleccionada = val),
                    decoration: const InputDecoration(labelText: "Categoría", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 15),
                  TextField(controller: preController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Precio", border: OutlineInputBorder(), prefixText: "\$ ")),
                  const SizedBox(height: 20),
                  
                  // Galería de fotos
                  Row(
                    children: [
                      if (imagenesSeleccionadas.length < 3)
                        GestureDetector(
                          onTap: seleccionarImagenes,
                          child: Container(height: 80, width: 80, decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.add_a_photo)),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 80,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: imagenesSeleccionadas.length,
                            itemBuilder: (context, index) => Stack(
                              children: [
                                Container(margin: const EdgeInsets.only(right: 10), width: 80, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), image: DecorationImage(image: FileImage(File(imagenesSeleccionadas[index].path)), fit: BoxFit.cover))),
                                Positioned(top: 0, right: 5, child: GestureDetector(onTap: () => setModalState(() => imagenesSeleccionadas.removeAt(index)), child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 12, color: Colors.white)))),
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 25),

                  // BOTÓN CON ANIMACIÓN Y BLOQUEO
                  ElevatedButton(
                    onPressed: estaPublicando 
                        ? null // Deshabilitado si está publicando
                        : () async {
                            if (nomController.text.isEmpty || preController.text.isEmpty || categoriaSeleccionada == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Faltan datos obligatorios")));
                              return;
                            }

                            setModalState(() => estaPublicando = true); // Iniciar carga

                            try {
                              await ProductosService().crearProductoAutomatico(
                                context,
                                nomController.text,
                                double.parse(preController.text),
                                descController.text,
                                imagenesSeleccionadas,
                                categoriaSeleccionada!,
                              );
                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              setModalState(() => estaPublicando = false);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.green,
                      disabledBackgroundColor: Colors.green.withOpacity(0.5), // Color más suave al cargar
                      foregroundColor: Colors.white,
                    ),
                    child: estaPublicando
                        ? const SizedBox(
                            height: 20, width: 20, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                        : const Text("Publicar Ahora"),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}