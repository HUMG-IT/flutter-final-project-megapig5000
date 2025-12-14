import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';
import 'product_model.dart';
import 'firestore_service.dart';
import 'auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, 
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().userStream,
          initialData: null,
        ),
      ],
      child: MaterialApp(
        title: 'Inventory App',
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
//XÁC THỰC NGƯỜI DÙNG
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthService>().userStream;
    
    return StreamBuilder<User?>(
      stream: authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) return const HomeScreen();
        return const LoginScreen();
      },
    );
  }
}

//MÀN HÌNH ĐĂNG NHẬP
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Đăng nhập' : 'Đăng ký')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _passController, decoration: const InputDecoration(labelText: 'Mật khẩu'), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final email = _emailController.text.trim();
                final pass = _passController.text.trim();
                if (email.isEmpty || pass.isEmpty) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Vui lòng nhập đầy đủ Email và Mật khẩu"),
                      backgroundColor: Colors.red, 
                    ),
                  );
                  return;
                }
                final auth = context.read<AuthService>();
                try {
                  if (_isLogin) {
                    await auth.signIn(email, pass);
                  } else {
                    await auth.signUp(email, pass);
                  }
                  if (!context.mounted) return;
                } on FirebaseAuthException catch (e) {
                  if (!context.mounted) return;
                  String message = "Lỗi: ${e.message}";
                  if (e.code == 'network-request-failed') {
                    message = "Không có kết nối mạng. Vui lòng kiểm tra Wifi/4G.";
                  } else if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
                    message = "Sai email hoặc mật khẩu.";
                  } else if (e.code == 'email-already-in-use') {
                    message = "Email này đã được đăng ký.";
                  } else if (e.code == 'weak-password') {
                    message = "Mật khẩu quá yếu. Vui lòng chọn mật khẩu khác.";
                  } else if (e.code == 'invalid-email') {
                    message = "Địa chỉ email không hợp lệ.";
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: Colors.red,
                    )
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
                }
              },
              child: Text(_isLogin ? 'Đăng Nhập' : 'Đăng Ký'),
            ),
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(_isLogin ? 'Chưa có tài khoản? Đăng ký ngay' : 'Đã có tài khoản? Đăng nhập'),
            )
          ],
        ),
      ),
    );
  }
}
//MÀN HÌNH CHÍNH (DANH SÁCH)
enum SortType { nameAsc, nameDesc, quantityAsc, quantityDesc, dateNewest, dateOldest }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  SortType _sortType = SortType.dateNewest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _processProducts(List<Product> products) {
    var filtered = products.where((p) {
      final query = _searchQuery.toLowerCase();
      return p.title.toLowerCase().contains(query) || 
             p.description.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      switch (_sortType) {
        case SortType.nameAsc:
          return a.title.compareTo(b.title);
        case SortType.nameDesc:
          return b.title.compareTo(a.title);
        case SortType.quantityAsc:
          return a.quantity.compareTo(b.quantity);
        case SortType.quantityDesc:
          return b.quantity.compareTo(a.quantity);
        case SortType.dateNewest:
          return b.updatedAt.compareTo(a.updatedAt);
        case SortType.dateOldest:
          return a.updatedAt.compareTo(b.updatedAt);
      }
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<FirestoreService>();
    final auth = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho hàng'),
        actions: [
          PopupMenuButton<SortType>(
            icon: const Icon(Icons.sort),
            onSelected: (val) => setState(() => _sortType = val),
            itemBuilder: (context) => const [
              PopupMenuItem(value: SortType.dateNewest, child: Text('Mới cập nhật')),
              PopupMenuItem(value: SortType.dateOldest, child: Text('Cũ nhất')),
              PopupMenuItem(value: SortType.nameAsc, child: Text('Tên (A-Z)')),
              PopupMenuItem(value: SortType.nameDesc, child: Text('Tên (Z-A)')),
              PopupMenuItem(value: SortType.quantityDesc, child: Text('Số lượng (Cao-Thấp)')),
              PopupMenuItem(value: SortType.quantityAsc, child: Text('Số lượng (Thấp-Cao)')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: db.getProducts(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final products = _processProducts(snapshot.data!);

                if (products.isEmpty) {
                  return Center(
                    child: Text(_searchQuery.isEmpty 
                      ? 'Kho trống' 
                      : 'Không tìm thấy sản phẩm nào'),
                  );
                }

                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: SizedBox(
                          width: 50,
                          height: 50,
                          child: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${product.quantity}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                )
                              )
                            )
                          )
                        ),
                        title: Text(
                          product.title, 
                          style: const TextStyle(fontWeight: FontWeight.bold), 
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.description.trim().isEmpty ? 'Không có mô tả': product.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: product.description.trim().isEmpty ? const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey) : null,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Cập nhật: ${DateFormat('dd/MM/yyyy HH:mm').format(product.updatedAt)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(context, db, product.id),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(product: product)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductDetailScreen()),
        ),
      ),
    );
  }

  //DIALOG XÁC NHẬN XÓA
  void _confirmDelete(BuildContext context, FirestoreService db, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xóa sản phẩm này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              db.deleteProduct(id);
              Navigator.pop(ctx);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

//MÀN HÌNH CHI TIẾT (THÊM/SỬA)
class ProductDetailScreen extends StatefulWidget {
  final Product? product;
  const ProductDetailScreen({super.key, this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late int _quantity;
  late String _description;
  late TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _title = widget.product?.title ?? '';
    _quantity = widget.product?.quantity ?? 0;
    _description = widget.product?.description ?? '';
    _quantityController = TextEditingController(text: _quantity.toString());
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _updateQuantity(int change) {
    int current = int.tryParse(_quantityController.text) ?? 0;
    int newValue = current + change;
    if (newValue < 0) newValue = 0;

    setState(() {
      _quantity = newValue;
      _quantityController.text = newValue.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.product == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(labelText: 'Tên sản phẩm', border: OutlineInputBorder()),
                onSaved: (val) => _title = val!.trim(),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Tên sản phẩm không được để trống';
                  }
                  if (val.trim().length < 3) {
                    return 'Tên sản phẩm phải có ít nhất 3 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () => _updateQuantity(-1),
                    ),
                  ),
                  
                  const SizedBox(width: 15),
                  
                  SizedBox( 
                    width: 100,
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Số lượng',
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        isDense: true,
                        border: OutlineInputBorder(), 
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center, 
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Nhập số';
                        final n = int.tryParse(val);
                        if (n == null) return 'Phải là số';
                        if (n < 0) return 'Không âm';
                        if (n > 9999999999) return 'Quá lớn';
                        return null;
                      },
                      onChanged: (val) {
                        if (val.isNotEmpty) {
                          final n = int.tryParse(val);
                          if (n != null && n >= 0) {
                            _quantity = n;
                          }
                        }
                      },
                      onSaved: (val) => _quantity = int.parse(val!),
                    ),
                  ),
                  
                  const SizedBox(width: 15),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _updateQuantity(1),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(labelText: 'Mô tả/Ghi chú', border: OutlineInputBorder()),
                maxLines: 19,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                onSaved: (val) => _description = val!.trim(),
              ),
              const SizedBox(height: 20),
              
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final db = context.read<FirestoreService>();
                    final now = DateTime.now();
                    if (widget.product == null) {
                       db.addProduct(Product(id: '', title: _title, quantity: _quantity, description: _description, updatedAt: now));
                    } else {
                       db.updateProduct(widget.product!.copyWith(title: _title, quantity: _quantity, description: _description, updatedAt: now));
                    }
                    Navigator.pop(context);
                  }
                },
                child: const Text('Lưu'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

//MÀN HÌNH CÁ NHÂN (ĐỔI MẬT KHẨU) 
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    
    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin cá nhân')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Email: ${user?.email ?? "N/A"}', style: const TextStyle(fontSize: 18)),
            const Divider(),
            const Text('Đổi mật khẩu'),
            TextField(controller: _passController, decoration: const InputDecoration(labelText: 'Mật khẩu mới')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await context.read<AuthService>().updatePassword(_passController.text);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đổi mật khẩu thành công")));
                  _passController.clear();
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
                }
              },
              child: const Text('Cập nhật mật khẩu'),
            )
          ],
        ),
      ),
    );
  }
}