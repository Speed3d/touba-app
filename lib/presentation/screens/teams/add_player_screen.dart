import 'package:flutter/material.dart';

/// 📝 HINT AR: نموذج إضافة لاعب للتشكيلة (يديره الكابتن). يُعيد بيانات اللاعب
/// عبر Navigator.pop ليستدعي معها cubit الإدارة createPlayer.
class AddPlayerScreen extends StatefulWidget {
  const AddPlayerScreen({super.key});

  @override
  State<AddPlayerScreen> createState() => _AddPlayerScreenState();
}

class _AddPlayerScreenState extends State<AddPlayerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  String _position = 'مهاجم';
  String? _preferredFoot;

  static const _positions = ['حارس مرمى', 'مدافع', 'خط وسط', 'مهاجم'];
  static const _feet = ['يمنى', 'يسرى', 'كلاهما'];

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'name': _nameController.text.trim(),
      'position': _position,
      'shirtNumber': int.tryParse(_numberController.text.trim()),
      'preferredFoot': _preferredFoot,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fill = isDark ? Colors.grey[900] : Colors.grey[100];
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(12));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('إضافة لاعب'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'اسم اللاعب',
                    prefixIcon: const Icon(Icons.person),
                    border: border,
                    filled: true,
                    fillColor: fill,
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'يرجى إدخال الاسم' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _position,
                  decoration: InputDecoration(
                    labelText: 'المركز',
                    prefixIcon: const Icon(Icons.sports_soccer),
                    border: border,
                    filled: true,
                    fillColor: fill,
                  ),
                  items: _positions
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => _position = v ?? _position),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _numberController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'رقم القميص (اختياري)',
                    prefixIcon: const Icon(Icons.tag),
                    border: border,
                    filled: true,
                    fillColor: fill,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _preferredFoot,
                  decoration: InputDecoration(
                    labelText: 'القدم المفضلة (اختياري)',
                    prefixIcon: const Icon(Icons.do_not_step),
                    border: border,
                    filled: true,
                    fillColor: fill,
                  ),
                  items: _feet
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) => setState(() => _preferredFoot = v),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('إضافة للتشكيلة',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
