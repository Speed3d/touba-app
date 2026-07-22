import 'package:flutter/material.dart';
import '../../../data/models/city_model.dart';
import '../../../data/models/district_model.dart';
import '../../../data/repositories/location_repository.dart';
import '../../../l10n/app_localizations.dart';

class ManageDistrictsScreen extends StatefulWidget {
  final CityModel city;

  const ManageDistrictsScreen({super.key, required this.city});

  @override
  State<ManageDistrictsScreen> createState() => _ManageDistrictsScreenState();
}

class _ManageDistrictsScreenState extends State<ManageDistrictsScreen> {
  final LocationRepository _repo = LocationRepository();

  void _showAddDistrictDialog([DistrictModel? districtToEdit]) {
    final arController = TextEditingController(text: districtToEdit?.nameAr);
    final enController = TextEditingController(text: districtToEdit?.nameEn);
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(districtToEdit == null ? l10n.addDistrict : l10n.editDistrict),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: arController,
              decoration: InputDecoration(labelText: l10n.nameArabic),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: enController,
              decoration: InputDecoration(labelText: l10n.nameEnglish),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancelBtn),
          ),
          ElevatedButton(
            onPressed: () async {
              if (arController.text.isEmpty) return;
              Navigator.pop(ctx);

              final dist = DistrictModel(
                id: districtToEdit?.id ?? '',
                nameAr: arController.text,
                nameEn: enController.text,
                cityId: widget.city.id,
                isActive: districtToEdit?.isActive ?? true,
                order: districtToEdit?.order ?? 0,
              );

              if (districtToEdit == null) {
                await _repo.addDistrict(dist);
              } else {
                await _repo.updateDistrict(dist);
              }
            },
            child: Text(l10n.saveBtn),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.districtsOfCity(widget.city.nameAr)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDistrictDialog(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<DistrictModel>>(
        stream: _repo.getDistrictsStream(widget.city.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(l10n.errorX(snapshot.error.toString())));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final districts = snapshot.data!;
          if (districts.isEmpty) {
            return Center(child: Text(l10n.noDistricts));
          }

          return ListView.builder(
            itemCount: districts.length,
            padding: const EdgeInsets.only(bottom: 80),
            itemBuilder: (context, index) {
              final dist = districts[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(dist.nameAr, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(dist.nameEn),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: dist.isActive,
                        onChanged: (val) {
                          _repo.updateDistrict(dist.copyWith(isActive: val));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showAddDistrictDialog(dist),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(l10n.confirmDeleteTitle),
                              content: Text(l10n.confirmDeleteDistrictX(dist.nameAr)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancelBtn)),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text(l10n.delete),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            _repo.deleteDistrict(dist.id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
