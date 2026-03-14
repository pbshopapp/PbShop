import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class agregar_productos_page extends StatefulWidget {
  @override
  _AgregarProductoPageState createState() => _AgregarProductoPageState();
}

class _AgregarProductoPageState extends State<agregar_productos_page> {
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  final _descController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nuevo Producto")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _nombreController, decoration: const InputDecoration(labelText: "Nombre")),
            TextField(controller: _precioController, decoration: const InputDecoration(labelText: "Precio"), keyboardType: TextInputType.number),
            TextField(controller: _descController, decoration: const InputDecoration(labelText: "Descripción")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await Supabase.instance.client.from('productos').insert({
                  'nombre': _nombreController.text,
                  'precio': int.parse(_precioController.text),
                  'descripcion': _descController.text,
                  'fk_negocio': 1, // ID del negocio
                });
                Navigator.pop(context);
              },
              child: const Text("Guardar Producto"),
            )
          ],
        ),
      ),
    );
  }
}