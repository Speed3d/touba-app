import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/functions_service.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../../l10n/app_localizations.dart';

class ManageRolesScreen extends StatefulWidget {
  const ManageRolesScreen({super.key});

  @override
  State<ManageRolesScreen> createState() => _ManageRolesScreenState();
}

class _ManageRolesScreenState extends State<ManageRolesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final UserRepository _userRepo = UserRepository();
  final FunctionsService _functionsService = FunctionsService();

  List<UserModel> _searchResults = [];
  bool _isLoading = false;

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final results = await _userRepo.searchUsersByPhone(query);
      setState(() => _searchResults = results);
    } catch (e) {
      if (mounted) {
        ToobaSnackBar.error(context, AppLocalizations.of(context)!.searchError(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleCapability(UserModel user, String capability, bool newValue) async {
    try {
      await _functionsService.grantCapability(user.id, capability, newValue);
      if (!mounted) return;
      // Update local state temporarily so the UI reflects the change immediately
      setState(() {
        final newPermissions = List<String>.from(user.adminPermissions);
        if (newValue) {
          if (!newPermissions.contains(capability)) newPermissions.add(capability);
        } else {
          newPermissions.remove(capability);
        }
        final index = _searchResults.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _searchResults[index] = user.copyWith(adminPermissions: newPermissions);
        }
      });
      ToobaSnackBar.success(context, AppLocalizations.of(context)!.updatedSuccessfully);
    } catch (e) {
      if (!mounted) return;
      ToobaSnackBar.error(context, AppLocalizations.of(context)!.updateFailed(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.manageRoles)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.searchByPhoneHint,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.phone),
                    ),
                    onSubmitted: (_) => _search(),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _search,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  ),
                  child: const Icon(Icons.search),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_searchResults.isEmpty)
            Expanded(child: Center(child: Text(AppLocalizations.of(context)!.noSearchResults)))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  final isOrganizer = user.adminPermissions.contains('organizer');
                  final isReferee = user.adminPermissions.contains('referee');

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: user.profileImage != null
                                    ? NetworkImage(user.profileImage!)
                                    : null,
                                child: user.profileImage == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text(user.phone, style: const TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(AppLocalizations.of(context)!.roleX(user.role)),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Text(AppLocalizations.of(context)!.additionalPermissions, style: const TextStyle(fontWeight: FontWeight.bold)),
                          SwitchListTile(
                            title: Text(AppLocalizations.of(context)!.tournamentOrganizer),
                            subtitle: Text(AppLocalizations.of(context)!.allowsCreatingTournaments),
                            value: isOrganizer,
                            onChanged: (val) => _toggleCapability(user, 'organizer', val),
                          ),
                          SwitchListTile(
                            title: Text(AppLocalizations.of(context)!.referee),
                            subtitle: Text(AppLocalizations.of(context)!.allowsEnteringResults),
                            value: isReferee,
                            onChanged: (val) => _toggleCapability(user, 'referee', val),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
