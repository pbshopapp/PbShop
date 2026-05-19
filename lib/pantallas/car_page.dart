import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbshop/servicios/CartService.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data'; // 👈 Importante para manejar los bytes de la imagen
import 'package:pbshop/widgets/EncabezadoAnimado.dart';

class car_page extends StatefulWidget {
  const car_page({super.key});

  @override
  State<car_page> createState() => _car_pageState();
}

class _car_pageState extends State<car_page> {
  bool _isConfirming = false;
  final _cartService = CartService();
  final f = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
  final colorPB = const Color.fromRGBO(0, 180, 195, 1);
  
  final Map<String, TextEditingController> _notaControllers = {};
  final Map<String, bool> _mostrandoPago = {}; 
  
  // 👈 CAMBIO 1: Cambiamos File? por Uint8List? para guardar los bytes de la imagen de forma híbrida
  final Map<String, Uint8List?> _comprobantesBytes = {}; 
  final Map<String, String?> _metodoSeleccionado = {}; 

  @override
  void dispose() {
    for (var controller in _notaControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _confirmarPedido(String idNegocio, List<ItemCarrito> itemsTienda) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final metodo = _metodoSeleccionado[idNegocio];
    
    if (user == null) {
      _mostrarMensaje("Inicia sesión para pedir", Colors.orange);
      return;
    }

    setState(() => _isConfirming = true);

    try {
      if (metodo == 'api') {
        _mostrarMensaje("Redirigiendo a pasarela de pagos...", Colors.blue);
        return; 
      }

      String? imageUrl;
      // 👈 CAMBIO 2: Validamos contra el mapa de bytes
      if (metodo == 'transferencia' && _comprobantesBytes[idNegocio] != null) {
        final String fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        // 👈 CAMBIO 3: Usamos uploadBinary en lugar de upload. Esto es compatible con Web y Celular.
        await supabase.storage.from('comprobantes').uploadBinary(
          fileName, 
          _comprobantesBytes[idNegocio]!,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
        
        imageUrl = supabase.storage.from('comprobantes').getPublicUrl(fileName);
      }

      double totalNegocio = itemsTienda.fold(0, (sum, item) => sum + item.total);
      
      final pedido = await supabase.from('pedidos').insert({
        'id_usuario': user.id,
        'fk_negocio': idNegocio,
        'total': totalNegocio,
        'estado': 'pendiente',
        'comprobante_url': imageUrl,
        'metodo_pago': metodo,
        'notas': _notaControllers[idNegocio]?.text ?? "",
      }).select().single();

      final detalles = itemsTienda.map((item) => {
        'fk_pedido': pedido['id'],
        'fk_producto': item.id,
        'cantidad': item.cantidad,
        'precio_unitario': item.precioUnitario,
      }).toList();

      await supabase.from('detalles_pedido').insert(detalles);

      setState(() {
        _cartService.items.removeWhere((item) => item.fkNegocio == idNegocio);
        _comprobantesBytes.remove(idNegocio); // 👈 Limpiamos el mapa de bytes
        _mostrandoPago.remove(idNegocio);
        _metodoSeleccionado.remove(idNegocio);
      });

      _mostrarMensaje("¡Pedido enviado con éxito!", Colors.green);
      
    } catch (e) {
      _mostrarMensaje("Error: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  void _mostrarMensaje(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListenableBuilder(
        listenable: _cartService,
        builder: (context, _) {
          final items = _cartService.items;

          final Map<String, List<ItemCarrito>> gruposPorTienda = {};
          for (var item in items) {
            gruposPorTienda.putIfAbsent(item.fkNegocio, () => []).add(item);
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const EncabezadoAnimado(
                titulo: "Mi Carrito",
                subtitulo: "Finaliza tus compras pascualinas",
                mostrarLogo: false,
                iconoAlternativo: Icon(
                  Icons.shopping_cart_checkout_rounded,
                  color: Colors.white,
                  size: 50,
                ),
              ),

              if (items.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.remove_shopping_cart_outlined, size: 60, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("Tu carrito está vacío", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(15),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final entry = gruposPorTienda.entries.elementAt(index);
                        return _buildSeccionTienda(entry.key, entry.value);
                      },
                      childCount: gruposPorTienda.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSeccionTienda(String idNegocio, List<ItemCarrito> itemsTienda) {
    bool enModoPago = _mostrandoPago[idNegocio] ?? false;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), 
        side: BorderSide(color: theme.dividerColor)
      ),
      color: theme.cardTheme.color,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));
          return SlideTransition(position: slide, child: child);
        },
        child: enModoPago 
            ? _buildVistaPago(idNegocio, itemsTienda) 
            : _buildVistaResumen(idNegocio, itemsTienda),
      ),
    );
  }

  Widget _buildVistaResumen(String idNegocio, List<ItemCarrito> itemsTienda) {
    _notaControllers.putIfAbsent(idNegocio, () => TextEditingController());
    double subtotal = itemsTienda.fold(0, (sum, item) => sum + item.total);
    final theme = Theme.of(context);

    return Column(
      key: ValueKey("resumen_$idNegocio"),
      children: [
        _buildHeaderTienda(idNegocio),
        ...itemsTienda.map((item) => _buildCardProducto(item, _cartService.items.indexOf(item))),
        Padding(
          padding: const EdgeInsets.all(15),
          child: TextField(
            controller: _notaControllers[idNegocio],
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            decoration: InputDecoration(
              hintText: "Notas para esta tienda",
              hintStyle: TextStyle(color: theme.hintColor),
              prefixIcon: Icon(Icons.note_alt_outlined, color: theme.hintColor),
              filled: true,
              fillColor: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        _buildFooterResumen(idNegocio, subtotal),
      ],
    );
  }

  Widget _buildVistaPago(String idNegocio, List<ItemCarrito> itemsTienda) {
    final theme = Theme.of(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: Supabase.instance.client
          .from('negocios')
          .select('*, metodos_pago (*)')
          .eq('id', idNegocio)
          .eq('metodos_pago.activo', true) 
          .single(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        
        final data = snapshot.data!;
        List<Widget> botones = [];
        if (data['acepta_efectivo'] == true) botones.add(_btnMetodo(idNegocio, 'efectivo', Icons.payments, "Efectivo"));
        if (data['acepta_transferencia_manual'] == true) botones.add(_btnMetodo(idNegocio, 'transferencia', Icons.camera_alt, "Transferencia"));
        if (data['acepta_pagos_api'] == true) botones.add(_btnMetodo(idNegocio, 'api', Icons.account_balance, "En línea"));

        return Container(
          key: ValueKey("pago_$idNegocio"),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, size: 20, color: theme.iconTheme.color), 
                  onPressed: () => setState(() => _mostrandoPago[idNegocio] = false)
                ),
                Text("Método de Pago", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.textTheme.bodyLarge?.color)),
              ]),
              const SizedBox(height: 20),
              Row( 
                children: botones.map((b) => Expanded(
                  child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: b),
                )).toList(),
              ),
              const SizedBox(height: 20),
              AnimatedSize(duration: const Duration(milliseconds: 300), child: _buildDetalleMetodo(idNegocio, data)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _puedeFinalizar(idNegocio) ? () => _confirmarPedido(idNegocio, itemsTienda) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPB,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: theme.dividerColor,
                ),
                child: _isConfirming ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Finalizar Compra"),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetalleMetodo(String idNegocio, Map<String, dynamic> data) {
    final metodo = _metodoSeleccionado[idNegocio];
    if (metodo == 'transferencia') {
      final listaMetodos = data['metodos_pago'] as List<dynamic>;
      if (listaMetodos.isEmpty) return _infoMetodo("Este negocio no tiene cuentas registradas.", Colors.red);
      return Column(children: [_buildSeccionCuentas(listaMetodos), const SizedBox(height: 15), _buildSelectorImagen(idNegocio)]);
    } else if (metodo == 'efectivo') {
      return _infoMetodo("Pagas al recibir el producto en el local.", Colors.orange);
    } else if (metodo == 'api') {
      return _infoMetodo("Pago seguro vía PSE o Tarjeta.", Colors.blue);
    }
    return const Center(child: Text("Selecciona un método para continuar"));
  }

  Widget _infoMetodo(String txt, Color col) => Container(
    padding: const EdgeInsets.all(12),
    width: double.infinity,
    decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
    child: Text(txt, style: TextStyle(color: col, fontSize: 13), textAlign: TextAlign.center),
  );

  Widget _btnMetodo(String idNegocio, String tipo, IconData icon, String label) {
    bool sel = _metodoSeleccionado[idNegocio] == tipo;
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => setState(() => _metodoSeleccionado[idNegocio] = tipo),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: sel ? colorPB.withOpacity(0.1) : theme.cardTheme.color, 
          border: Border.all(color: sel ? colorPB : theme.dividerColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [
          Icon(icon, size: 20, color: sel ? colorPB : theme.hintColor),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: sel ? FontWeight.bold : FontWeight.normal, color: sel ? (theme.brightness == Brightness.dark ? Colors.white : Colors.black) : theme.hintColor)),
        ]),
      ),
    );
  }

  Widget _buildSelectorImagen(String idNegocio) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () async {
        final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
        if (img != null) {
          // 👈 CAMBIO 4: En lugar de crear un objeto File, extraemos los bytes del XFile de inmediato
          final bytes = await img.readAsBytes();
          setState(() => _comprobantesBytes[idNegocio] = bytes);
        }
      },
      child: Container(
        height: 120, width: double.infinity,
        decoration: BoxDecoration(border: Border.all(color: theme.dividerColor), borderRadius: BorderRadius.circular(12)),
        child: _comprobantesBytes[idNegocio] == null 
          ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, color: theme.hintColor), Text("Subir Comprobante", style: TextStyle(fontSize: 12, color: theme.hintColor))])
          // 👈 CAMBIO 5: Reemplazamos Image.file por Image.memory pasándole los bytes guardados
          : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(_comprobantesBytes[idNegocio]!, fit: BoxFit.cover)),
      ),
    );
  }

  bool _puedeFinalizar(String idNegocio) {
    final m = _metodoSeleccionado[idNegocio];
    if (m == 'efectivo' || m == 'api') return true;
    if (m == 'transferencia' && _comprobantesBytes[idNegocio] != null) return true; // 👈 Ajuste de validación
    return false;
  }

  Widget _buildHeaderTienda(String idNegocio) {
    final theme = Theme.of(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: Supabase.instance.client.from('negocios').select('nombre').eq('id', idNegocio).single(),
      builder: (context, snap) => Container(
        padding: const EdgeInsets.all(15), 
        color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        child: Row(children: [
          Icon(Icons.storefront, color: colorPB), 
          const SizedBox(width: 10), 
          Text(snap.hasData ? snap.data!['nombre'] : "...", style: const TextStyle(fontWeight: FontWeight.bold))
        ]),
      ),
    );
  }

  Widget _buildSeccionCuentas(List<dynamic> cuentas) {
    final theme = Theme.of(context);
    return Column(
      children: cuentas.take(2).map((cuenta) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorPB.withOpacity(0.2)),
          ),
          child: Column(children: [
            Text(cuenta['tipo_metodo'].toString().toUpperCase(), style: TextStyle(color: colorPB, fontWeight: FontWeight.bold, fontSize: 11)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: cuenta['numero_cuenta'].toString()));
                _mostrarMensaje("¡Número copiado!", colorPB);
              },
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(cuenta['numero_cuenta'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                const SizedBox(width: 8),
                Icon(Icons.copy_rounded, size: 18, color: theme.hintColor),
              ]),
            ),
            Text("Titular: ${cuenta['nombre_titular']}", style: TextStyle(color: theme.hintColor, fontSize: 12)),
          ]),
        );
      }).toList(),
    );
  }

  Widget _buildFooterResumen(String idNegocio, double sub) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Total", style: TextStyle(color: theme.hintColor, fontSize: 12)), 
          Text(f.format(sub), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green))
        ]),
        ElevatedButton(
          onPressed: () => setState(() => _mostrandoPago[idNegocio] = true), 
          style: ElevatedButton.styleFrom(backgroundColor: colorPB, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), 
          child: const Text("Confirmar")
        ),
      ]),
    );
  }

  Widget _buildCardProducto(ItemCarrito item, int idx) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.nombre, style: const TextStyle(fontWeight: FontWeight.w600)), 
          Text(f.format(item.precioUnitario), style: TextStyle(color: theme.hintColor, fontSize: 12))
        ])),
        _btnQty(Icons.remove, () => _cartService.cambiarCantidad(idx, false)),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text("${item.cantidad}")),
        _btnQty(Icons.add, () => _cartService.cambiarCantidad(idx, true)),
        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), onPressed: () => _cartService.eliminarProducto(idx)),
      ]),
    );
  }

  Widget _btnQty(IconData icon, VoidCallback tap) {
    final theme = Theme.of(context);
    return InkWell(onTap: tap, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(border: Border.all(color: theme.dividerColor), borderRadius: BorderRadius.circular(6)), child: Icon(icon, size: 16, color: theme.iconTheme.color)));
  }
}