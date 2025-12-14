import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'product_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _productsRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User not logged in");
    return _db.collection('users').doc(uid).collection('products');
  }

  Future<void> addProduct(Product product) async {
    await _productsRef.add(product.toMap());
  }

  Stream<List<Product>> getProducts() {
    return _productsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> updateProduct(Product product) async {
    await _productsRef.doc(product.id).update(product.toMap());
  }

  Future<void> deleteProduct(String id) async {
    await _productsRef.doc(id).delete();
  }
}