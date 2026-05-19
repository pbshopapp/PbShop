import 'dart:typed_data'; // La única librería que necesitamos para la imagen
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 🛑 CERO IMPORTACIONES DE dart:io
// 🛑 CERO IMPORTACIONES DE foundation.dart (kIsWeb)

class PagoManualScreen extends StatefulWidget {
  final double total;
  const PagoManualScreen({super.key, required this.total});

  @override
  State<PagoManualScreen> createState() => _PagoManualScreenState();
}

class _PagoManualScreenState extends State<PagoManualScreen> {
  Uint8List? _imageBytes; // 🚀 Almacenamos la imagen en memoria viva (Universal)
  bool _isUploading = false;
  final _picker = ImagePicker();

  static const Color colorTurquesa = Color.fromRGBO(0, 180, 195, 1);

  // FUNCIÓN UNIVERSAL PARA SELECCIONAR FOTO
  Future<void> _pickImage() async {
    if (_isUploading) return;

    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      
      if (file != null) {
        // readAsBytes() funciona en Web, Android y iOS por igual
        final bytes = await file.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint("Error seleccionando imagen: $e");
    }
  }

  // FUNCIÓN UNIVERSAL PARA SUBIR A SUPABASE
  Future<void> _confirmarPedido() async {
    if (_imageBytes == null || _isUploading) return;

    setState(() => _isUploading = true);

    try {
      final supabase = Supabase.instance.client;
      final fileName = 'pago_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // uploadBinary funciona de manera nativa en todas las plataformas
      await supabase.storage.from('comprobantes').uploadBinary(
        fileName,
        _imageBytes!,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );

      final imageUrl = supabase.storage.from('comprobantes').getPublicUrl(fileName);

      await supabase.from('pedidos').insert({
        'monto_total': widget.total,
        'comprobante_url': imageUrl,
        'estado_pago': 'pendiente_verificacion',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Comprobante enviado! PB-Shop verificará tu pago.")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error al confirmar: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al procesar el pago. Inténtalo de nuevo.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Verificar Pago", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  const Text("TOTAL A PAGAR", style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text(
                    "\$${widget.total.toStringAsFixed(0)}", 
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 16),
                  const Text("Transfiere a Nequi:", style: TextStyle(color: Colors.white60, fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text("300 123 4567", style: TextStyle(color: colorTurquesa, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // LA VISTA PREVIA (100% LIBRE DE dart:io)
            GestureDetector(
              onTap: _isUploading ? null : _pickImage,
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  border: Border.all(color: _imageBytes == null ? Colors.white10 : colorTurquesa, width: 2),
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFF1E1E1E),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _imageBytes == null 
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_rounded, size: 60, color: Colors.white24), 
                          SizedBox(height: 12),
                          Text("Toca para subir captura", style: TextStyle(color: Colors.white38, fontSize: 14)),
                        ],
                      )
                    // 🚀 Renderizado Universal
                    : Image.memory(_imageBytes!, fit: BoxFit.contain),
                ),
              ),
            ),
            
            const Spacer(),
            
            ElevatedButton(
              onPressed: (_imageBytes == null || _isUploading) ? null : _confirmarPedido,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorTurquesa,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isUploading 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : const Text("Confirmar Envío de Pedido", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }
}