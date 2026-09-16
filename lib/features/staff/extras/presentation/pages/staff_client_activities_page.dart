import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/repositories/staff_extras_repository.dart';

class StaffClientActivitiesPage extends StatefulWidget {
  const StaffClientActivitiesPage({super.key});

  @override
  State<StaffClientActivitiesPage> createState() =>
      _StaffClientActivitiesPageState();
}

class _StaffClientActivitiesPageState extends State<StaffClientActivitiesPage> {
  late final StaffExtrasRepository _repository;
  late final AppApiClient _api;
  late final UserSession _session;
  bool _loading = true;
  String? _error;
  List<Map<String, String>> _clients = const [];
  String? _selectedClientId;
  List<Map<String, String>> _items = const [];

  @override
  void initState() {
    super.initState();
    _repository = GetIt.instance<StaffExtrasRepository>();
    _api = GetIt.instance<AppApiClient>();
    _session = Get.find<UserSession>();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _api.get(
      ApiEndpoints.clients,
      query: const {'assignedToMe': true, 'page': 1, 'limit': 50},
      silent: true,
    );
    if (!mounted) return;
    await result.when(
      success: (body) async {
        final clients =
            JsonCodec.unwrapList(body).whereType<Map>().map((item) {
          final json = JsonCodec.asMap(item);
          return {
            'id': JsonCodec.stringOr(json['id'], ''),
            'title': JsonCodec.stringOr(
              json['displayName'] ?? json['name'],
              'Client',
            ),
          };
        }).where((c) => c['id']!.isNotEmpty).toList();
        _clients = clients;
        _selectedClientId = clients.isNotEmpty ? clients.first['id'] : null;
        if (_selectedClientId != null) {
          await _loadActivities(silent: true);
        } else {
          _loading = false;
        }
        setState(() {});
      },
      failure: (err) async {
        setState(() {
          _error = err.message;
          _loading = false;
        });
      },
    );
  }

  Future<void> _loadActivities({bool silent = false}) async {
    final clientId = _selectedClientId;
    if (clientId == null || clientId.isEmpty) return;
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final result = await _repository.getClientActivities(clientId: clientId);
    if (!mounted) return;
    result.when(
      success: (items) => setState(() {
        _items = items;
        _loading = false;
      }),
      failure: (err) => setState(() {
        _error = err.message;
        _loading = false;
      }),
    );
  }

  Future<void> _recordActivity() async {
    final clientId = _selectedClientId;
    if (clientId == null) return;
    final typeController = TextEditingController(text: 'school');
    final statusController = TextEditingController(text: 'present');
    final notesController = TextEditingController();
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Record activity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: typeController,
              decoration: const InputDecoration(labelText: 'Activity type'),
            ),
            TextField(
              controller: statusController,
              decoration: const InputDecoration(labelText: 'Status'),
            ),
            TextField(
              controller: notesController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final result = await _repository.recordClientActivity(
      clientId: clientId,
      activityType: typeController.text.trim(),
      status: statusController.text.trim(),
      notes: notesController.text,
    );
    result.when(
      success: (_) {
        Get.snackbar(
          'Saved',
          'Activity recorded.',
          snackPosition: SnackPosition.BOTTOM,
        );
        _loadActivities();
      },
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not save',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Client activities'),
        backgroundColor: AppColors.surfaceWhite,
        foregroundColor: AppColors.textHeading,
        elevation: 0,
      ),
      floatingActionButton:
          _session.canAccessClientActivities && _selectedClientId != null
              ? FloatingActionButton(
                  backgroundColor: AppColors.secondaryTeal,
                  onPressed: _recordActivity,
                  child: const Icon(Icons.add),
                )
              : null,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondaryTeal),
            )
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  color: AppColors.secondaryTeal,
                  onRefresh: _loadActivities,
                  child: ListView(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      all: 16,
                    ),
                    children: [
                      if (_clients.isNotEmpty)
                        DropdownButtonFormField<String>(
                          initialValue: _selectedClientId,
                          decoration: const InputDecoration(
                            labelText: 'Client',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            for (final c in _clients)
                              DropdownMenuItem(
                                value: c['id'],
                                child: Text(c['title'] ?? ''),
                              ),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedClientId = value);
                            _loadActivities();
                          },
                        ),
                      const SizedBox(height: 12),
                      if (_items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'No activities recorded yet.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        )
                      else
                        ..._items.map(
                          (item) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceWhite,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textHeading,
                                  ),
                                ),
                                if ((item['subtitle'] ?? '').isNotEmpty)
                                  Text(
                                    item['subtitle']!,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
