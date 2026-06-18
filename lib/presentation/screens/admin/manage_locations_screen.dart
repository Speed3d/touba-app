import 'package:flutter/material.dart';
import '../../../data/models/city_model.dart';
import '../../../data/repositories/location_repository.dart';
import 'manage_districts_screen.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../../app/router/tooba_route.dart';

class ManageLocationsScreen extends StatefulWidget {
  const ManageLocationsScreen({super.key});

  @override
  State<ManageLocationsScreen> createState() => _ManageLocationsScreenState();
}

class _ManageLocationsScreenState extends State<ManageLocationsScreen> {
  final LocationRepository _repo = LocationRepository();
  bool _isSeeding = false;

  void _showAddCityDialog([CityModel? cityToEdit]) {
    final arController = TextEditingController(text: cityToEdit?.nameAr);
    final enController = TextEditingController(text: cityToEdit?.nameEn);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(cityToEdit == null ? 'إضافة محافظة' : 'تعديل محافظة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: arController,
              decoration: const InputDecoration(labelText: 'الاسم (عربي)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: enController,
              decoration: const InputDecoration(labelText: 'الاسم (إنجليزي)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (arController.text.isEmpty) return;
              Navigator.pop(ctx);
              
              final city = CityModel(
                id: cityToEdit?.id ?? '',
                nameAr: arController.text,
                nameEn: enController.text,
                isActive: cityToEdit?.isActive ?? true,
                order: cityToEdit?.order ?? 0,
              );

              if (cityToEdit == null) {
                await _repo.addCity(city);
              } else {
                await _repo.updateCity(city);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _seedAllIraq() async {
    setState(() => _isSeeding = true);
    try {
      await _repo.seedAllIraq();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تم الاستيراد بنجاح'),
          content: const Text('تم جلب جميع محافظات ومناطق العراق.'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
    } catch (e) {
      ToobaSnackBar.error(context, 'خطأ: $e');
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المحافظات'),
        actions: [
          if (_isSeeding)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'استيراد كل العراق',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('تأكيد الاستيراد'),
                    content: const Text('سيتم حقن كافة محافظات ومناطق العراق. هل أنت متأكد؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('إلغاء'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('استيراد'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  _seedAllIraq();
                }
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCityDialog(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<CityModel>>(
        stream: _repo.getCitiesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final cities = snapshot.data!;
          if (cities.isEmpty) {
            return const Center(child: Text('لا توجد محافظات. اضغط على زر التحميل لاستيراد العراق.'));
          }

          return ListView.builder(
            itemCount: cities.length,
            padding: const EdgeInsets.only(bottom: 80),
            itemBuilder: (context, index) {
              final city = cities[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(city.nameAr, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(city.nameEn),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: city.isActive,
                        onChanged: (val) {
                          _repo.updateCity(city.copyWith(isActive: val));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showAddCityDialog(city),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('تأكيد الحذف'),
                              content: Text('هل أنت متأكد من حذف ${city.nameAr} وجميع مناطقها؟'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('حذف'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            _repo.deleteCity(city.id);
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      ToobaRoute.to(ManageDistrictsScreen(city: city)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
