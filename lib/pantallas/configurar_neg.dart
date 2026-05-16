import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class ConfigurarNegocioPage extends StatefulWidget {
  final String idNegocio;
  const ConfigurarNegocioPage({super.key, required this.idNegocio});

  @override
  State<ConfigurarNegocioPage> createState() => _ConfigurarNegocioPageState();
}

class _ConfigurarNegocioPageState extends State<ConfigurarNegocioPage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _datosNegocio;
  List<dynamic> _metodosPago = [];
  
  // Paleta de colores PB-Shop
  final Color colorPB = const Color.fromRGBO(0, 180, 195, 1);

  // Controladores de texto
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _ubicacionController;  // Nuevo campo
  final _emailAyudanteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _ubicacionController.dispose();
    _emailAyudanteController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE DATOS ---

  Future<void> _cargarDatos() async {
    try {
      final res = await supabase
          .from('negocios')
          .select('*, metodos_pago(*)')
          .eq('id', widget.idNegocio)
          .single();
      
      if (mounted) {
        setState(() {
          _datosNegocio = res;
          _metodosPago = res['metodos_pago'] ?? [];
          // Ordenamos por ID de forma fija para que no salten de posición al actualizar
          _metodosPago.sort((a, b) => a['id'].compareTo(b['id']));
          
          _nameController = TextEditingController(text: res['nombre'] ?? "");
          _descController = TextEditingController(text: res['descripcion'] ?? "");
          _ubicacionController = TextEditingController(text: res['ubicacion'] ?? ""); // Nuevo
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error cargando datos: $e");
      _notificar("Error al conectar con el servidor");
    }
  }

  // --- LÓGICA DE IMAGEN (LOGO) ---

  Future<void> _cambiarLogo() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);

    if (image != null) {
      _notificar("Subiendo nueva imagen...");
      try {
        final file = File(image.path);
        final fileName = 'logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = '${widget.idNegocio}/$fileName';

        // Subir al bucket 'logos_negocios'
        await supabase.storage.from('logos_negocios').upload(path, file);
        
        // Obtener URL pública
        final String publicUrl = supabase.storage.from('logos_negocios').getPublicUrl(path);

        // Actualizar tabla negocios
        await supabase.from('negocios').update({'imagen_url': publicUrl}).eq('id', widget.idNegocio);
        
        setState(() {
          _datosNegocio?['imagen_url'] = publicUrl;
        });
        _notificar("¡Logo actualizado con éxito!");
      } catch (e) {
        debugPrint("Error subiendo logo: $e");
        _notificar("Error al cambiar el logo de la empresa");
      }
    }
  }

  // --- MÉTODOS DE ACTUALIZACIÓN ---

  Future<void> _actualizarPerfil() async {
    try {
      await supabase.from('negocios').update({
        'nombre': _nameController.text,
        'descripcion': _descController.text,
        'ubicacion': _ubicacionController.text, // Nuevo
      }).eq('id', widget.idNegocio);
      _notificar("¡Cambios guardados con éxito!");
    } catch (e) {
      _notificar("Error al guardar cambios");
    }
  }

  Future<void> _updateToggle(String campo, bool valor) async {
    setState(() => _datosNegocio?[campo] = valor);
    try {
      await supabase.from('negocios').update({campo: valor}).eq('id', widget.idNegocio);
    } catch (e) {
      _cargarDatos(); // Revertir si falla
      _notificar("Error al actualizar estado");
    }
  }

  Future<void> _toggleEstadoCuenta(dynamic idCuenta, bool nuevoEstado) async {
    // Cambio local inmediato para evitar saltos o retrasos visuales
    setState(() {
      final index = _metodosPago.indexWhere((m) => m['id'] == idCuenta);
      if (index != -1) {
        _metodosPago[index]['activo'] = nuevoEstado;
      }
    });

    try {
      await supabase.from('metodos_pago').update({'activo': nuevoEstado}).eq('id', idCuenta);
    } catch (e) {
      _cargarDatos(); // Si falla el servidor, revertimos al estado real
      _notificar("Error al cambiar estado de cuenta");
    }
  }

  Future<void> _borrarMetodo(String id) async {
    try {
      await supabase.from('metodos_pago').delete().eq('id', id);
      _cargarDatos();
    } catch (e) {
      _notificar("No se pudo eliminar la cuenta");
    }
  }

  // --- INTERFAZ DE USUARIO ---

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 75, // Altura extra para desahogar las pestañas y que se lean completas
          title: const Text("Mi Negocio", style: TextStyle(fontWeight: FontWeight.bold, color:  Colors.white)),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: isDark ? const Color.fromARGB(255, 36, 167, 179): Colors.white,
            labelColor: isDark ? const Color.fromARGB(255, 36, 167, 179): Colors.white,
            unselectedLabelColor: isDark ? Colors.white60 : const Color.fromARGB(255, 255, 255, 255),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
            tabs: const [
              Tab(icon: Icon(Icons.store_rounded, size: 22), text: "Perfil",),
              Tab(icon: Icon(Icons.payments_rounded, size: 22), text: "Pagos"),
              Tab(icon: Icon(Icons.badge_rounded, size: 22), text: "Equipo"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTabPerfil(isDark),
            _buildTabPagos(isDark),
            _buildTabAyudantes(isDark),
          ],
        ),
      ),
    );
  }

  // --- SECCIÓN 1: PERFIL ---
  Widget _buildTabPerfil(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: Column(
        children: [
          _buildSelectorImagenPerfil(),
          const SizedBox(height: 35),
          _buildTextField(
            controller: _nameController,
            label: "Nombre del emprendimiento",
            icon: Icons.store,
            isDark: isDark,
          ),
          const SizedBox(height: 18),
          _buildTextField(
            controller: _descController,
            label: "Descripción breve",
            icon: Icons.description,
            maxLines: 3,
            isDark: isDark,
          ),
          const SizedBox(height: 18),
          _buildTextField(
            controller: _ubicacionController, // Control de ubicación mapeado
            label: "Ubicación en la u (Ej: Bloque P13)",
            icon: Icons.location_on_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 35),
          _buildBotonGuardar(),
        ],
      ),
    );
  }

  // --- SECCIÓN 2: PAGOS ---
  Widget _buildTabPagos(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionLabel("Métodos de recepción"),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              _buildSwitchMetodo("Efectivo", "Pago contra entrega", _datosNegocio?['acepta_efectivo'] ?? false, 'acepta_efectivo', Icons.money_rounded),
              const Divider(height: 1),
              _buildSwitchMetodo("Transferencia", "Nequi, Daviplata, etc.", _datosNegocio?['acepta_transferencia_manual'] ?? false, 'acepta_transferencia_manual', Icons.account_balance_wallet_rounded),
              const Divider(height: 1),
              _buildSwitchMetodo("Pago por API", "Tarjetas y PSE", _datosNegocio?['acepta_pagos_api'] ?? false, 'acepta_pagos_api', Icons.credit_card_rounded),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionLabel("Mis Cuentas Bancarias"),
            TextButton.icon(
              onPressed: _dialogMetodoPago,
              icon: const Icon(Icons.add),
              label: const Text("Añadir"),
              style: TextButton.styleFrom(foregroundColor: colorPB),
            )
          ],
        ),
        if (_metodosPago.isEmpty) 
          const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No hay cuentas registradas", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)))),
        ..._metodosPago.map((m) => _buildCardCuenta(m, isDark)),
      ],
    );
  }

  // --- SECCIÓN 3: EQUIPO (AYUDANTES) ---
  Widget _tabEquipo() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildSectionLabel("Gestión de Equipo"),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _dialogAgregarAyudante,
            icon: const Icon(Icons.person_add_rounded),
            label: const Text("VINCULAR AYUDANTE"),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: BorderSide(color: colorPB),
              foregroundColor: colorPB,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder(
              future: supabase.from('perfiles').select().eq('fk_negocio', widget.idNegocio),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final ayudantes = snapshot.data as List? ?? [];
                if (ayudantes.isEmpty) return const Center(child: Text("Aún no tienes ayudantes"));
                
                return ListView.builder(
                  itemCount: ayudantes.length,
                  itemBuilder: (context, i) {
                    final data = ayudantes[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorPB, 
                          child: Text(
                            (data['nombre'] != null && data['nombre'].toString().isNotEmpty) 
                                ? data['nombre'][0].toUpperCase() 
                                : 'U', 
                            style: const TextStyle(color: Colors.white)
                          )
                        ),
                        title: Text(data['nombre'] ?? 'Sin nombre'),
                        subtitle: Text(data['email'] ?? ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.person_remove, color: Colors.redAccent),
                          onPressed: () => _confirmarDesvinculacion(data['id'], data['nombre'] ?? 'Ayudante'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  // --- WIDGETS DE APOYO ---

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, int maxLines = 1, required bool isDark}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: colorPB),
          labelText: label,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildSwitchMetodo(String titulo, String subtitulo, bool valor, String campo, IconData icon) {
    return SwitchListTile(
      activeColor: colorPB,
      secondary: Icon(icon, color: valor ? colorPB : Colors.grey),
      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitulo, style: const TextStyle(fontSize: 12)),
      value: valor,
      onChanged: (bool nuevoValor) => _updateToggle(campo, nuevoValor),
    );
  }

  Widget _buildCardCuenta(Map<String, dynamic> m, bool isDark) {
    bool activa = m['activo'] ?? true;
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: ListTile(
        leading: Icon(Icons.account_balance, color: activa ? colorPB : Colors.grey),
        title: Text(m['tipo_metodo'].toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(m['numero_cuenta']),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: activa, 
              activeColor: colorPB, 
              onChanged: (v) => _toggleEstadoCuenta(m['id'], v)
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent), 
              onPressed: () => _borrarMetodo(m['id'].toString())
            ),
          ],
        ),
      ),
    );
  }

  // --- DIÁLOGOS ---

  void _dialogMetodoPago() {
    final tC = TextEditingController(), nC = TextEditingController(), hC = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nueva Cuenta"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: tC, decoration: const InputDecoration(labelText: "Tipo (Nequi, Daviplata...)")),
            TextField(controller: nC, decoration: const InputDecoration(labelText: "Número de cuenta"), keyboardType: TextInputType.number),
            TextField(controller: hC, decoration: const InputDecoration(labelText: "Nombre del titular")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (tC.text.isEmpty || nC.text.isEmpty) return;
              await supabase.from('metodos_pago').insert({
                'fk_negocio': widget.idNegocio,
                'tipo_metodo': tC.text,
                'numero_cuenta': nC.text,
                'nombre_titular': hC.text,
                'activo': true,
              });
              if (context.mounted) Navigator.pop(context);
              _cargarDatos();
            },
            style: ElevatedButton.styleFrom(backgroundColor: colorPB, foregroundColor: Colors.white),
            child: const Text("Agregar"),
          )
        ],
      ),
    );
  }

  void _dialogAgregarAyudante() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Vincular Ayudante"),
        content: TextField(
          controller: _emailAyudanteController, 
          decoration: const InputDecoration(labelText: "Correo electrónico"),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (_emailAyudanteController.text.trim().isEmpty) return;
              await supabase
                  .from('perfiles')
                  .update({'fk_negocio': widget.idNegocio})
                  .eq('email', _emailAyudanteController.text.trim());
                  
              _emailAyudanteController.clear();
              if (context.mounted) Navigator.pop(context);
              _cargarDatos(); // Sincroniza la lista de equipo de inmediato
            },
            style: ElevatedButton.styleFrom(backgroundColor: colorPB, foregroundColor: Colors.white),
            child: const Text("Vincular"),
          )
        ],
      ),
    );
  }

  Future<void> _confirmarDesvinculacion(String userId, String nombre) async {
    try {
      await supabase.from('perfiles').update({'fk_negocio': null}).eq('id', userId);
      _cargarDatos();
      _notificar("$nombre ha sido removido del equipo");
    } catch (e) {
      _notificar("Error al desvincular");
    }
  }

  // --- OTROS COMPONENTES ---

  Widget _buildTabAyudantes(bool isDark) => _tabEquipo();

  Widget _buildSectionLabel(String texto) => Text(texto.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2));

  Widget _buildBotonGuardar() => SizedBox(
    width: double.infinity, height: 55,
    child: ElevatedButton(
      onPressed: _actualizarPerfil,
      style: ElevatedButton.styleFrom(backgroundColor: colorPB, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
      child: const Text("GUARDAR CONFIGURACIÓN", style: TextStyle(fontWeight: FontWeight.bold)),
    ),
  );

  Widget _buildSelectorImagenPerfil() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 65, 
            backgroundColor: Colors.grey[300],
            backgroundImage: NetworkImage(_datosNegocio?['imagen_url'] ?? "https://via.placeholder.com/150")
          ),
          Positioned(
            bottom: 0, 
            right: 0, 
            child: GestureDetector(
              onTap: _cambiarLogo, // Ahora ejecuta la función de cambio de logo
              child: CircleAvatar(
                backgroundColor: colorPB, 
                radius: 20,
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20)
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _notificar(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: colorPB));
}