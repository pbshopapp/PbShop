import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PagoManualScreen extends StatefulWidget {
  final double total;
  const PagoManualScreen({super.key, required this.total});

  @override
  State<PagoManualScreen> createState() => _PagoManualScreenState();
}

class _PagoManualScreenState extends State<PagoManualScreen> {
  File? _imageFile;
  bool _isUploading = false;
  final _picker = ImagePicker();

  // Función para seleccionar la foto
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  // Función para subir a Supabase Storage y guardar el pedido
  Future<void> _confirmarPedido() async {
    if (_imageFile == null) return;

    setState(() => _isUploading = true);

    try {
      final supabase = Supabase.instance.client;
      
      // 1. Subir la imagen al Bucket 'comprobantes'
      final fileName = 'pago_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('comprobantes').upload(fileName, _imageFile!);
      
      // 2. Obtener la URL pública
      final imageUrl = supabase.storage.from('comprobantes').getPublicUrl(fileName);

      // 3. Crear el registro en la tabla pedidos
      await supabase.from('pedidos').insert({
        'monto_total': widget.total,
        'comprobante_url': imageUrl,
        'estado_pago': 'pendiente_verificacion',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Pedido enviado! Espera la confirmación del vendedor.")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Finalizar Pago")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text("Total a pagar: \$${widget.total}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text("Transfiere a Nequi: 300 123 4567"),
            const SizedBox(height: 30),
            
            // Preview de la imagen
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _imageFile == null 
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Icon(Icons.add_a_photo, size: 50), Text("Subir Comprobante")],
                    )
                  : Image.file(_imageFile!, fit: BoxFit.cover),
              ),
            ),
            
            const Spacer(),
            
            ElevatedButton(
              onPressed: (_imageFile == null || _isUploading) ? null : _confirmarPedido,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: _isUploading 
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text("Confirmar Envío de Pedido"),
            )
          ],
        ),
      ),
    );
  }
}