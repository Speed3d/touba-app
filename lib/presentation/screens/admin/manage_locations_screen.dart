import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/city_model.dart';
import '../../../data/repositories/location_repository.dart';
import '../../widgets/core/decorated_background.dart';
import '../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final arController = TextEditingController(text: cityToEdit?.nameAr);
    final enController = TextEditingController(text: cityToEdit?.nameEn);
    final kuController = TextEditingController(text: cityToEdit?.nameKu);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(cityToEdit == null
            ? l10n.addGovernorate
            : l10n.editGovernorate),
        content: SingleChildScrollView(
          child: Column(
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
              const SizedBox(height: 8),
              TextField(
                controller: kuController,
                decoration: InputDecoration(labelText: l10n.nameKurdish),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (arController.text.isEmpty) return;
              Navigator.pop(ctx);

              final city = CityModel(
                id: cityToEdit?.id ?? '',
                nameAr: arController.text,
                nameEn: enController.text,
                nameKu: kuController.text,
                isActive: cityToEdit?.isActive ?? true,
                order: cityToEdit?.order ?? 0,
              );

              if (cityToEdit == null) {
                await _repo.addCity(city);
              } else {
                await _repo.updateCity(city);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _seedAllIraq() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSeeding = true);
    try {
      await _repo.seedAllIraq();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.importSuccessTitle),
          content: Text(l10n.importSuccessBody),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.okBtn),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) ToobaSnackBar.error(context, l10n.errorX(e.toString()));
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(l10n.manageGovernoratesTitle),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
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
              tooltip: l10n.importIraqTooltip,
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.importConfirmTitle),
                    content: Text(l10n.importConfirmBody),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l10n.cancel),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(l10n.importBtn),
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
      body: DecoratedBackground(
        showOrbs: false,
        child: StreamBuilder<List<CityModel>>(
          stream: _repo.getCitiesStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(l10n.errorX(snapshot.error.toString())));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final cities = snapshot.data!;
            if (cities.isEmpty) {
              return Center(child: Text(l10n.noGovernorates));
            }

            return ListView.builder(
              itemCount: cities.length,
              padding: const EdgeInsets.only(bottom: 80, top: 12),
              itemBuilder: (context, index) {
                final city = cities[index];
                return Card(
                  elevation: 0,
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark ? const Color(0xFF1E2A38) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(city.nameAr,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
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
                                title: Text(l10n.confirmDeleteTitle),
                                content:
                                    Text(l10n.confirmDeleteCityX(city.nameAr)),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text(l10n.cancel)),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(l10n.delete),
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
      ),
    );
  }
}
