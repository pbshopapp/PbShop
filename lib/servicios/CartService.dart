import 'package:flutter/material.dart';

// 1. Modelo de datos con ID como String (para soportar UUID de Supabase)
class ItemCarrito {
  final String id;
  final String nombre;
  final int precioUnitario;
  final String fkNegocio;
  int cantidad;

  ItemCarrito({
    required this.id,
    required this.nombre,
    required this.precioUnitario,
    required this.fkNegocio,
    this.cantidad = 1,
  });

  int get total => precioUnitario * cantidad;
}

// 2. Servicio con patrón Singleton y ChangeNotifier
class CartService with ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<ItemCarrito> _items = [];

  // Getter para acceder a los items
  List<ItemCarrito> get items => _items;

  // Lógica para agregar productos
  void agregarProducto(Map<String, dynamic> producto) {
    final String prodId = producto['id'].toString();
    final index = _items.indexWhere((item) => item.id == prodId);

    if (index != -1) {
      _items[index].cantidad++;
    } else {
      _items.add(ItemCarrito(
        id: prodId,
        nombre: producto['nombre'],
        // Usamos .toInt() para asegurar que sea int
        precioUnitario: (producto['precio'] as num).toInt(),
        fkNegocio: producto['fk_negocio'],
      ));
    }
    notifyListeners(); // <--- Notifica a la UI del cambio
  }

  void eliminarProducto(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void cambiarCantidad(int index, bool aumentar) {
    if (aumentar) {
      _items[index].cantidad++;
    } else if (_items[index].cantidad > 1) {
      _items[index].cantidad--;
    }
    notifyListeners();
  }

  void limpiarCarrito() {
    _items.clear();
    notifyListeners();
  }

  int get granTotal => _items.fold(0, (sum, item) => sum + item.total);
}