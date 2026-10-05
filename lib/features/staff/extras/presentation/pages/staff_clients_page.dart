import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../daily_logs/domain/repositories/staff_daily_logs_repository.dart';

/// Staff "Clients" module — web `/dashboard/clients` Client Directory parity
/// (BUG_Report010: Daily Logs and Clients must both appear).
/// Web staff Client Directory is browse/search only — no Add Client.
class StaffClientsPage extends StatefulWidget {
  const StaffClientsPage({super.key});

  @override
  State<StaffClientsPage> createState() => _StaffClientsPageState();
}

class _StaffClientsPageState extends State<StaffClientsPage> {
  late final AppApiClient _api;
  StaffDailyLogsRepository? _dailyLogsRepository;

  bool _loading = true;
  String? _error;
  String _search = '';
  String? _residenceId;
  String _status = 'all';
  List<Map<String, String>> _clients = const [];
  List<({String id, String name})> _residences = const [];

  @override
  void initState() {
    super.initState();
    _api = GetIt.instance<AppApiClient>();
    if (GetIt.instance.isRegistered<StaffDailyLogsRepository>()) {
      _dailyLogsRepository = GetIt.instance<StaffDailyLogsRepository>();
    }
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final options = await _dailyLogsRepository?.getResidenceOptions();
    if (mounted && options != null && options.isSuccess) {
      _residences = options.value ?? const [];
    }
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _api.get(
      ApiEndpoints.clients,
      query: {
        if (_search.trim().isNotEmpty) 'search': _search.trim(),
        if (_residenceId != null && _residenceId!.isNotEmpty)
          'residenceId': _residenceId,
        if (_status != 'all') 'status': _status,
        'page': 1,
        'limit': 50,
      },
      silent: true,
    );
    if (!mounted) return;
    result.when(
      success: (body) {
        final rows = JsonCodec.unwrapList(body).whereType<Map>().map((item) {
          final json = JsonCodec.asMap(item);
          final first = JsonCodec.stringOr(json['firstName'], '');
          final last = JsonCodec.stringOr(json['lastName'], '');
          final name = JsonCodec.stringOr(
            json['name'] ?? json['displayName'] ?? '$first $last'.trim(),
            'Client',
          );
          final residence = JsonCodec.mapAt(json, 'residence');
          return <String, String>{
            'id': JsonCodec.stringOr(json['id'], ''),
            'name': name,
            'status': JsonCodec.stringOr(json['status'], ''),
            'room': JsonCodec.stringOr(json['roomNumber'] ?? json['room'], ''),
            'residence': JsonCodec.stringOr(
              json['residenceName'] ?? residence?['name'],
              '',
            ),
            'level': JsonCodec.stringOr(json['level'] ?? json['careLevel'], ''),
          };
        }).where((row) => row['id']!.isNotEmpty).toList();
        setState(() {
          _clients = rows;
          _loading = false;
        });
      },
      failure: (error) => setState(() {
        _error = error.message;
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('staff-clients-page'),
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Clients'),
        backgroundColor: AppColors.surfaceWhite,
        foregroundColor: AppColors.textHeading,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.surfaceWhite,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Client Directory',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textHeading,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const Key('staff-clients-directory-search'),
                  decoration: const InputDecoration(
                    hintText: 'Search clients...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    _search = value;
                    _load();
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        key: const Key('staff-clients-directory-residence'),
                        initialValue: _residenceId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'All Residences',
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All Residences'),
                          ),
                          for (final item in _residences)
                            DropdownMenuItem(
                              value: item.id,
                              child: Text(
                                item.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          setState(() => _residenceId = value);
                          _load();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: const Key('staff-clients-directory-status'),
                        initialValue: _status,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('Any status'),
                          ),
                          DropdownMenuItem(
                            value: 'active',
                            child: Text('Active'),
                          ),
                          DropdownMenuItem(
                            value: 'inactive',
                            child: Text('Inactive'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _status = value ?? 'all');
                          _load();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondaryTeal,
                    ),
                  )
                : _error != null
                ? Center(child: Text(_error!))
                : RefreshIndicator(
                    color: AppColors.secondaryTeal,
                    onRefresh: _load,
                    child: _clients.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 80),
                              Center(
                                child: Text(
                                  'No clients found',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: ResponsiveHelper.getResponsivePadding(
                              context,
                              all: 16,
                            ),
                            itemCount: _clients.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final client = _clients[index];
                              final meta = [
                                if ((client['residence'] ?? '').isNotEmpty)
                                  client['residence']!,
                                if ((client['room'] ?? '').isNotEmpty)
                                  'Room ${client['room']}',
                                if ((client['level'] ?? '').isNotEmpty)
                                  client['level']!,
                              ].join(' · ');
                              return Material(
                                color: AppColors.surfaceWhite,
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor:
                                            AppColors.activeBackground,
                                        child: Text(
                                          _initials(client['name'] ?? ''),
                                          style: const TextStyle(
                                            color: AppColors.activeGreen,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              client['name'] ?? 'Client',
                                              style: const TextStyle(
                                                fontFamily: 'Outfit',
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textHeading,
                                              ),
                                            ),
                                            if (meta.isNotEmpty)
                                              Text(
                                                meta,
                                                style: const TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 12,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if ((client['status'] ?? '').isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.activeBackground,
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            client['status']!,
                                            style: const TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.activeGreen,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
