import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final Color colorFondo = const Color(0xFFF8F9FA);
  final Color colorTextoSecundario = const Color(0xFF6C757D);

  late TextEditingController _nameController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final res = await supabase
          .from('negocios')
          .select('*, metodos_pago(*)')
          .eq('id', widget.idNegocio)
          .single();
      
      setState(() {
        _datosNegocio = res;
        _metodosPago = res['metodos_pago'];
        _nameController = TextEditingController(text: res['nombre']);
        _descController = TextEditingController(text: res['descripcion']);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error cargando datos: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Scaffold(backgroundColor: colorFondo, body: const Center(child: CircularProgressIndicator()));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: colorFondo,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: const Text("Mi Negocio", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: TabBar(
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 3,
            indicatorColor: colorPB,
            labelColor: colorPB,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(icon: Icon(Icons.store_rounded), text: "Perfil"),
              Tab(icon: Icon(Icons.payments_rounded), text: "Pagos"),
              Tab(icon: Icon(Icons.badge_rounded), text: "Equipo"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTabPerfil(),
            _buildTabPagos(),
            _buildTabAyudantes(),
          ],
        ),
      ),
    );
  }

  // --- SECCIÓN 1: PERFIL (Rediseñado) ---
  Widget _buildTabPerfil() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSelectorImagenPerfil(),
          const SizedBox(height: 40),
          _buildLabel("Información Pública"),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _nameController,
            label: "Nombre del emprendimiento",
            icon: Icons.edit,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _descController,
            label: "Descripción breve",
            icon: Icons.description,
            maxLines: 3,
          ),
          const SizedBox(height: 40),
          _buildBotonGuardar(),
        ],
      ),
    );
  }

  // --- SECCIÓN 2: PAGOS (Estilo Moderno) ---
  Widget _buildTabPagos() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildLabel("Métodos de recepción"),
        const SizedBox(height: 10),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              _buildSwitchMetodo(
                titulo: "Efectivo",
                subtitulo: "Pago contra entrega",
                valor: _datosNegocio?['acepta_efectivo'] ?? false,
                campo: 'acepta_efectivo',
                icon: Icons.money,
              ),
              const Divider(height: 1),
              _buildSwitchMetodo(
                titulo: "Transferencia Directa",
                subtitulo: "Nequi, Daviplata o Ahorro a la mano",
                valor: _datosNegocio?['acepta_transferencia_manual'] ?? false,
                campo: 'acepta_transferencia_manual',
                icon: Icons.account_balance_wallet,
              ),
              const Divider(height: 1),
              _buildSwitchMetodo(
                titulo: "Pago por API",
                subtitulo: "Tarjetas de crédito/débito",
                valor: _datosNegocio?['acepta_pagos_api'] ?? false,
                campo: 'acepta_pagos_api',
                icon: Icons.credit_card,
              ),

            ],
          ),
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel("Mis Cuentas Bancarias"),
            TextButton.icon(
              onPressed: _dialogMetodoPago,
              icon: const Icon(Icons.add),
              label: const Text("Añadir"),
              style: TextButton.styleFrom(foregroundColor: colorPB),
            )
          ],
        ),
        if (_metodosPago.isEmpty) _buildEmptyState("Sin cuentas registradas"),
        ..._metodosPago.map((m) => _buildCardCuenta(m)),
      ],
    );
  }

  // --- COMPONENTES UI AUXILIARES ---

  Widget _buildLabel(String texto) {
    return Text(
      texto.toUpperCase(),
      style: TextStyle(color: colorTextoSecundario, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: colorPB),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildBotonGuardar() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(colors: [colorPB, colorPB.withOpacity(0.8)]),
        boxShadow: [BoxShadow(color: colorPB.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: ElevatedButton(
        onPressed: _actualizarPerfil,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
        child: const Text("GUARDAR CONFIGURACIÓN", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1), selectionColor: Color.fromARGB(255, 184, 184, 184),),
      ),
    );
  }

  Widget _buildSwitchMetodo({required String titulo, required String subtitulo, required bool valor, required String campo, required IconData icon}) {
    return SwitchListTile(
      activeColor: colorPB,
      secondary: Icon(icon, color: valor ? colorPB : Colors.grey),
      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitulo, style: TextStyle(color: colorTextoSecundario, fontSize: 12)),
      value: valor,
      onChanged: (bool nuevoValor) => _updateToggle(campo, nuevoValor),
    );
  }

  Widget _buildCardCuenta(Map<String, dynamic> m) {
    // Verificamos el estado actual usando la llave correcta 'activo'
    bool estaActiva = m['activo'] ?? true;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // El borde cambia de intensidad según el estado
        border: Border.all(
          color: estaActiva ? Colors.black.withOpacity(0.05) : Colors.grey.shade200,
        ),
        boxShadow: [
          if (estaActiva)
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          // Avatar circular que se opaca si la cuenta está inactiva
          CircleAvatar(
            backgroundColor: estaActiva ? colorPB.withOpacity(0.1) : Colors.grey.shade100,
            child: Icon(
              Icons.account_balance_rounded,
              color: estaActiva ? colorPB : Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 15),

          // Información de la cuenta con efectos visuales de estado
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m['tipo_metodo'].toString().toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: estaActiva ? Colors.black : Colors.grey,
                  ),
                ),
                Text(
                  m['numero_cuenta'],
                  style: TextStyle(
                    color: estaActiva ? colorTextoSecundario : Colors.grey.shade400,
                    fontSize: 13,
                    // Tacha el número si la cuenta está desactivada
                    decoration: estaActiva ? null : TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
          ),

          // Acción: Borrar cuenta
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
            onPressed: () => _borrarMetodo(m['id']),
            tooltip: "Eliminar cuenta",
          ),

          // Acción: Switch de activación rápida
          // Al moverlo, se dispara la actualización en Supabase que ya corregiste
          Switch(
            value: estaActiva,
            activeColor: colorPB,
            onChanged: (bool valor) => _toggleEstadoCuenta(m['id'], valor),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(child: Text(msg, style: TextStyle(color: colorTextoSecundario, fontStyle: FontStyle.italic))),
    );
  }

  // --- SECCIÓN 3: AYUDANTES (Minimalista) ---
  Widget _buildTabAyudantes() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildLabel("Gestión de Equipo"),
          const SizedBox(height: 20),
          _buildBotonAyudante(), // El botón que llama a _dialogAgregarAyudante
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder(
              // Usamos un query que traiga a los que tienen este negocio asignado
              future: supabase
                  .from('perfiles')
                  .select('id, nombre, email')
                  .eq('fk_negocio', widget.idNegocio),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final ayudantes = snapshot.data as List? ?? [];
                
                if (ayudantes.isEmpty) {
                  return _buildEmptyState("Aún no tienes ayudantes vinculados");
                }

                return ListView.separated(
                  itemCount: ayudantes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _buildTileAyudante(ayudantes[i]),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTileAyudante(Map<String, dynamic> data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorPB.withOpacity(0.1),
          child: Text(data['nombre'][0].toUpperCase(), style: TextStyle(color: colorPB, fontWeight: FontWeight.bold)),
        ),
        title: Text(data['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(data['email'] ?? '', style: const TextStyle(fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.person_remove_outlined, color: Colors.redAccent, size: 20),
          onPressed: () => _confirmarDesvinculacion(data['id'], data['nombre']),
        ),
      ),
    );
  }

  Widget _buildBotonAyudante() {
    return OutlinedButton.icon(
      onPressed: _dialogAgregarAyudante,
      icon: const Icon(Icons.person_add_rounded),
      label: const Text("VINCULAR AYUDANTE"),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        side: BorderSide(color: colorPB),
        foregroundColor: colorPB,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // --- WIDGETS AUXILIARES Y LÓGICA ---

  // Controladores para el diálogo de ayudantes
  final _emailAyudanteController = TextEditingController();

  void _dialogAgregarAyudante() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Vincular Ayudante", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Ingresa el correo del estudiante para que pueda gestionar este negocio.",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _emailAyudanteController,
              label: "Correo electrónico",
              icon: Icons.alternate_email,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: _vincularAyudante,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorPB,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Vincular"),
          ),
        ],
      ),
    );
  }

  Future<void> _vincularAyudante() async {
    final email = _emailAyudanteController.text.trim();
    if (email.isEmpty) return;

    try {
      // 1. Buscamos si el usuario existe en la tabla perfiles
      final userRes = await supabase
          .from('perfiles')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (userRes == null) {
        _notificar("El usuario no está registrado en la app");
        return;
      }

      // 2. Actualizamos su perfil para vincularlo al negocio
      await supabase
          .from('perfiles')
          .update({'fk_negocio': widget.idNegocio})
          .eq('email', email);

      _emailAyudanteController.clear();
      if (mounted) Navigator.pop(context);
      
      setState(() {}); // Refrescar la lista de ayudantes
      _notificar("¡Ayudante vinculado correctamente!");
      
    } catch (e) {
      debugPrint("Error vinculando: $e");
      _notificar("Error al intentar vincular");
    }
  }

  Future<void> _confirmarDesvinculacion(String userId, String nombre) async {
    // Aquí podrías mostrar un pequeño diálogo de confirmación antes de proceder
    try {
      await supabase
          .from('perfiles')
          .update({'fk_negocio': null}) // Quitamos la relación
          .eq('id', userId);
      
      setState(() {}); // Refrescar lista
      _notificar("$nombre ha sido removido del equipo");
    } catch (e) {
      _notificar("No se pudo desvincular");
    }
  }

  Future<void> _updateToggle(String campo, bool valor) async {
    setState(() => _datosNegocio?[campo] = valor); // Update optimista
    try {
      await supabase.from('negocios').update({campo: valor}).eq('id', widget.idNegocio);
    } catch (e) {
      setState(() => _datosNegocio?[campo] = !valor); // Revertir si falla
      _notificar("Error al actualizar estado");
    }
  }

  Future<void> _actualizarPerfil() async {
    await supabase.from('negocios').update({
      'nombre': _nameController.text,
      'descripcion': _descController.text,
    }).eq('id', widget.idNegocio);
    _notificar("¡Cambios guardados!");
  }

  void _dialogMetodoPago() {
    final tController = TextEditingController();
    final nController = TextEditingController();
    final hController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Nueva Cuenta", style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox( // Agregamos un SizedBox para darle un límite físico al diálogo
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min, // Esto evita que la columna intente ser infinita
            children: [
              TextField(
                controller: tController, 
                decoration: const InputDecoration(labelText: "Tipo (Nequi, Daviplata...)")
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nController, 
                decoration: const InputDecoration(labelText: "Número de cuenta"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: hController, 
                decoration: const InputDecoration(labelText: "Nombre del titular")
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorPB,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            onPressed: () async {
              // Validación simple para evitar errores en Supabase
              if (tController.text.isEmpty || nController.text.isEmpty) {
                _notificar("Llena los campos obligatorios");
                return;
              }

              try {
                await supabase.from('metodos_pago').insert({
                  'fk_negocio': widget.idNegocio,
                  'tipo_metodo': tController.text,
                  'numero_cuenta': nController.text,
                  'nombre_titular': hController.text,
                  'activo': true, 
                });
                
                if (mounted) {
                  Navigator.pop(context);
                  _cargarDatos(); // Refresca la lista
                }
              } catch (e) {
                _notificar("Error al guardar: $e");
              }
            }, 
            child: const Text("Agregar", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
  }

  Future<void> _toggleEstadoCuenta(dynamic idCuenta, bool nuevoEstado) async {
    try {
      final response = await Supabase.instance.client
          .from('metodos_pago')
          .update({'activo': nuevoEstado})
          .eq('id', idCuenta)
          .select(); // Agregamos .select() para confirmar que devolvió algo

      if (response.isEmpty) {
        print("⚠️ No se actualizó nada. Posible problema de RLS o ID incorrecto.");
        return;
      }

      if (mounted) {
        setState(() {
          // Forzamos la comparación a String para evitar errores de tipo UUID/String
          final index = _metodosPago.indexWhere((item) => item['id'].toString() == idCuenta.toString());
          
          if (index != -1) {
            _metodosPago[index]['activo'] = nuevoEstado;
          } else {
            print("❌ No se encontró el ID $idCuenta en la lista local.");
          }
        });
      }
    } catch (e) {
      print("Log de error: $e");
    }
  }

  Future<void> _borrarMetodo(String id) async {
    await supabase.from('metodos_pago').delete().eq('id', id);
    _cargarDatos();
  }

  void _notificar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: colorPB));
  }

  Widget _buildSelectorImagenPerfil() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 65, 
            backgroundColor: Colors.grey[200],
            backgroundImage: NetworkImage(_datosNegocio?['imagen_url'] ?? "https://via.placeholder.com/150")
          ),
          Positioned(
            bottom: 0, right: 0,
            child: CircleAvatar(
              backgroundColor: colorPB,
              child: IconButton(icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20), onPressed: () {}),
            ),
          ),
        ],
      ),
    );
  }
}