import 'package:flutter/material.dart';
import 'package:pbshop/pantallas/details_neg_page.dart';

class CartaNegocio extends StatelessWidget {
  final Map<String, dynamic> negocio;

  const CartaNegocio({super.key, required this.negocio});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // Dentro del build de CartaNegocio
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => details_neg_page(negocio: negocio),
          ),
        );
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          children: [
            // Logo o Imagen del Negocio
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: negocio['imagen_url'] != null 
                  ? Image.network(negocio['imagen_url'], fit: BoxFit.cover)
                  : const Icon(Icons.store, size: 50, color: Color.fromRGBO(0, 180, 195, 1)),
              ),
            ),
            // Información breve
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      negocio['nombre'] ?? 'Sin nombre',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      negocio['ubicacion'] ?? 'Ubicación...',
                      style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 4),
                    // Etiqueta de Categoría
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        negocio['categoria'] ?? 'General',
                        style: const TextStyle(fontSize: 9, color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}