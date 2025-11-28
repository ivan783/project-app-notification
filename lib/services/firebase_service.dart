import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:push_app_new/domain/entities/product.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'products';

  // CREATE - Crear un nuevo producto
  Future<String> createProduct(Product product) async {
    try {
      final docRef = await _firestore.collection(_collection).add(
        product.toMap(),
      );
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear producto: $e');
    }
  }

  // READ - Obtener todos los productos (una sola vez)
  Future<List<Product>> getProducts() async {
    final query = await _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs.map((doc) => Product.fromFirebase(doc)).toList();
  }

  // READ - Obtener todos los productos en tiempo real
  Stream<List<Product>> getProductsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirebase(doc)).toList());
  }

  // READ - Obtener un producto por ID
  Future<Product?> getProductById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Product.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener producto: $e');
    }
  }

  // UPDATE - Actualizar un producto
  Future<void> updateProduct(String id, Product product) async {
    try {
      await _firestore.collection(_collection).doc(id).update(
            product.copyWith(updatedAt: DateTime.now()).toMap(),
          );
    } catch (e) {
      throw Exception('Error al actualizar producto: $e');
    }
  }

  // DELETE - Eliminar un producto
  Future<void> deleteProduct(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Error al eliminar producto: $e');
    }
  }

  // SEARCH - Buscar productos por nombre (Stream)
  Stream<List<Product>> searchProducts(String query) {
    return _firestore
        .collection(_collection)
        .orderBy('name')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromMap(doc.data(), doc.id)).toList());
  }

  // UPDATE STOCK
  Future<void> updateStock(String id, int newStock) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'stock': newStock,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Error al actualizar stock: $e');
    }
  }
}
