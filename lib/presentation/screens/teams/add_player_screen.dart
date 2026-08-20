import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/core/decorated_background.dart';

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
  String? _position;
  String? _preferredFoot;

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
    final fill = isDark ? AppColors.surfaceDark : Colors.white;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: isDark ? const Color(0xFF1E2A38) : const Color(0xFFE2E8F0),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.addPlayer),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: DecoratedBackground(
        showOrbs: false,
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
                    labelText: AppLocalizations.of(context)!.playerNameLabel,
                    prefixIcon: const Icon(Icons.person),
                    border: border,
                    filled: true,
                    fillColor: fill,
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? AppLocalizations.of(context)!.pleaseEnterName : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _position,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.position,
                    prefixIcon: const Icon(Icons.sports_soccer),
                    border: border,
                    filled: true,
                    fillColor: fill,
                  ),
                  items: [
                    DropdownMenuItem(value: 'حارس مرمى', child: Text(AppLocalizations.of(context)!.posGoalkeeper)),
                    DropdownMenuItem(value: 'مدافع', child: Text(AppLocalizations.of(context)!.posDefender)),
                    DropdownMenuItem(value: 'خط وسط', child: Text(AppLocalizations.of(context)!.posMidfielder)),
                    DropdownMenuItem(value: 'مهاجم', child: Text(AppLocalizations.of(context)!.posForward)),
                  ],
                  onChanged: (v) => setState(() => _position = v ?? _position),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _numberController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.shirtNumberOptional,
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
                    labelText: AppLocalizations.of(context)!.preferredFootOptional,
                    prefixIcon: const Icon(Icons.do_not_step),
                    border: border,
                    filled: true,
                    fillColor: fill,
                  ),
                  items: [
                    DropdownMenuItem(value: 'يمنى', child: Text(AppLocalizations.of(context)!.footRight)),
                    DropdownMenuItem(value: 'يسرى', child: Text(AppLocalizations.of(context)!.footLeft)),
                    DropdownMenuItem(value: 'كلاهما', child: Text(AppLocalizations.of(context)!.footBoth)),
                  ],
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
                  child: Text(AppLocalizations.of(context)!.addToRosterBtn,
                      style:
                          const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
