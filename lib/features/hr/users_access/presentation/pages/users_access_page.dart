import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../../core/widgets/app_refresh_indicator.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../../clients/presentation/clients_labels.dart';
import '../../../profile_settings/presentation/widgets/hr_initials_avatar.dart';
import '../../data/users_access_repository.dart';
import '../../domain/users_access_models.dart';
import '../widgets/add_user_onboard_sheet.dart';
import '../widgets/edit_user_sheet.dart';
import '../widgets/role_form_sheets.dart';
import '../widgets/role_holders_sheet.dart';
import '../widgets/staff_categories_sheet.dart';
import 'role_permissions_page.dart';

/// Web `/dashboard/users` — people directory + roles, permission-gated.
class UsersAccessPage extends StatefulWidget {
  const UsersAccessPage({super.key});

  @override
  State<UsersAccessPage> createState() => _UsersAccessPageState();
}

class _UsersAccessPageState extends State<UsersAccessPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final UserSession _session;
  late final AppApiClient _api;
  late final UsersAccessRepository _repo;

  // Users directory
  DirectorySummary _summary = const DirectorySummary();
  List<DirectoryPerson> _people = const [];
  bool _loadingPeople = false;
  String? _peopleError;
  String _peopleQuery = '';
  String _typeFilter = 'all'; // all | employee | family | no_login
  String? _roleCodeFilter;
  String? _statusFilter; // null | active | inactive | invited
  String? _residenceIdFilter;
  bool _showDeactivated = false;
  List<({String id, String name})> _residences = const [];

  // Roles
  List<_AccessRole> _roles = const [];
  bool _loadingRoles = false;
  String? _rolesError;
  String _roleQuery = '';
  bool _creatingRole = false;

  bool get _canUsers => _session.can('users:read');
  bool get _canWriteUsers => _session.can('users:write');
  bool get _canRoles => _session.can('roles:read');
  bool get _canWriteRoles => _session.can('roles:write');
  bool get _canReadCategories => _session.can('staff-categories:read');
  bool get _canWriteCategories => _session.can('staff-categories:write');

  @override
  void initState() {
    super.initState();
    _session = Get.find<UserSession>();
    _api = GetIt.instance<AppApiClient>();
    _repo = UsersAccessRepository(api: _api);
    final tabCount = (_canUsers ? 1 : 0) + (_canRoles ? 1 : 0);
    _tabs = TabController(length: tabCount < 1 ? 1 : tabCount, vsync: this);
    _tabs.addListener(() {
      if (mounted) setState(() {});
    });
    _refresh();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  bool get _onRolesTab {
    if (!_canRoles) return false;
    if (!_canUsers) return true;
    return _tabs.index == 1;
  }

  Future<void> _refresh() async {
    await Future.wait([
      if (_canUsers) _loadPeople(),
      if (_canUsers) _loadResidences(),
      if (_canRoles) _loadRoles(),
    ]);
  }

  Future<void> _loadResidences() async {
    if (!_session.can('residences:read') && !_canUsers) return;
    final result = await _repo.fetchResidences();
    if (!mounted) return;
    result.when(
      success: (rows) => setState(() => _residences = rows),
      failure: (_) {},
    );
  }

  Future<void> _loadPeople() async {
    setState(() {
      _loadingPeople = true;
      _peopleError = null;
    });
    final result = await _repo.fetchDirectory(
      search: _peopleQuery,
      userType: switch (_typeFilter) {
        'employee' => 'employee',
        'family' => 'family',
        _ => null,
      },
      hasLogin: _typeFilter == 'no_login' ? false : null,
      roleCode: _roleCodeFilter,
      status: _showDeactivated
          ? null
          : (_statusFilter ?? 'active'),
      residenceId: _residenceIdFilter,
      includeInactive: _showDeactivated,
      limit: 100,
    );
    if (!mounted) return;
    result.when(
      success: (page) => setState(() {
        _people = page.people;
        _summary = page.summary;
        _loadingPeople = false;
      }),
      failure: (error) => setState(() {
        _loadingPeople = false;
        _peopleError = error.message;
      }),
    );
  }

  Future<void> _loadRoles() async {
    setState(() {
      _loadingRoles = true;
      _rolesError = null;
    });
    final result = await _api.get(ApiEndpoints.roles, silent: true);
    if (!mounted) return;
    result.when(
      success: (body) {
        final rows = JsonCodec.unwrapList(body).whereType<Map>();
        setState(() {
          _roles = [
            for (final row in rows)
              _AccessRole.fromJson(JsonCodec.asMap(row)),
          ]..sort((a, b) => a.name.compareTo(b.name));
          _loadingRoles = false;
        });
      },
      failure: (error) => setState(() {
        _loadingRoles = false;
        _rolesError = error.message;
      }),
    );
  }

  Future<void> _openAddUser() async {
    if (!_canWriteUsers) {
      AppSnackbar.show(
        'Not allowed',
        'Adding people needs users:write.',
        force: true,
      );
      return;
    }
    final created = await showAddUserOnboardSheet(context, repository: _repo);
    if (created == true && mounted) await _loadPeople();
  }

  Future<void> _openEditUser(DirectoryPerson person) async {
    if (!_canWriteUsers && !_canUsers) return;
    if (!_canWriteUsers) {
      AppSnackbar.show(
        'Not allowed',
        'Editing people needs users:write.',
        force: true,
      );
      return;
    }
    final saved = await showEditUserSheet(
      context,
      repository: _repo,
      person: person,
    );
    if (saved == true && mounted) await _loadPeople();
  }

  Future<void> _openCategories() async {
    if (!_canReadCategories) {
      AppSnackbar.show(
        'Not allowed',
        'Job titles need staff-categories:read.',
        force: true,
      );
      return;
    }
    await showStaffCategoriesSheet(
      context,
      repository: _repo,
      canWrite: _canWriteCategories,
    );
  }

  Future<void> _personAction(DirectoryPerson person) async {
    if (person.userId.isEmpty) {
      AppSnackbar.show(
        'No login account',
        'This person has no user login to manage.',
        force: true,
      );
      return;
    }
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                person.name,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(person.email),
            ),
            if (_canWriteUsers && person.isDeactivated)
              ListTile(
                leading: const Icon(Icons.restart_alt),
                title: const Text('Reactivate'),
                onTap: () => Navigator.pop(ctx, 'reactivate'),
              ),
            if (_canWriteUsers && !person.isDeactivated)
              ListTile(
                leading: const Icon(Icons.person_off_outlined),
                title: const Text('Deactivate'),
                onTap: () => Navigator.pop(ctx, 'deactivate'),
              ),
            if (_canWriteUsers && person.hasLogin)
              ListTile(
                leading: const Icon(Icons.lock_reset_outlined),
                title: const Text('Send password reset'),
                onTap: () => Navigator.pop(ctx, 'reset'),
              ),
            if (_canWriteUsers)
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Assign roles'),
                onTap: () => Navigator.pop(ctx, 'roles'),
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case 'deactivate':
        final r = await _repo.deactivateUser(person.userId);
        r.when(
          success: (_) {
            AppSnackbar.show('Deactivated', person.name, force: true);
            _loadPeople();
          },
          failure: (e) =>
              AppSnackbar.show('Could not deactivate', e.message, force: true),
        );
      case 'reactivate':
        final r = await _repo.reactivateUser(person.userId);
        r.when(
          success: (_) {
            AppSnackbar.show('Reactivated', person.name, force: true);
            _loadPeople();
          },
          failure: (e) =>
              AppSnackbar.show('Could not reactivate', e.message, force: true),
        );
      case 'reset':
        final r = await _repo.sendPasswordReset(person.userId);
        r.when(
          success: (_) => AppSnackbar.show(
            'Reset email sent',
            person.email,
            force: true,
          ),
          failure: (e) =>
              AppSnackbar.show('Could not send reset', e.message, force: true),
        );
      case 'roles':
        await _assignRoles(person);
    }
  }

  Future<void> _assignRoles(DirectoryPerson person) async {
    if (!_canWriteUsers) return;
    final roles = await _repo.fetchRoles();
    var catalog = <({String id, String name, String code})>[];
    roles.when(
      success: (rows) => catalog = rows,
      failure: (e) {
        AppSnackbar.show('Could not load roles', e.message, force: true);
      },
    );
    if (!mounted || catalog.isEmpty) return;
    final selected = {...person.roleIds};
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Roles — ${person.name}'),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final r in catalog)
                    CheckboxListTile(
                      value: selected.contains(r.id),
                      title: Text(r.name),
                      subtitle: Text(r.code),
                      onChanged: (on) => setLocal(() {
                        if (on == true) {
                          selected.add(r.id);
                        } else {
                          selected.remove(r.id);
                        }
                      }),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await _repo.replaceUserRoles(
      userId: person.userId,
      roleIds: selected.toList(growable: false),
    );
    result.when(
      success: (_) {
        AppSnackbar.show('Roles updated', person.name, force: true);
        _loadPeople();
      },
      failure: (e) =>
          AppSnackbar.show('Could not update roles', e.message, force: true),
    );
  }

  Future<void> _openPermissions(_AccessRole role) async {
    if (role.id.isEmpty) return;
    final updated = await Get.to<List<String>>(
      () => RolePermissionsPage(
        roleId: role.id,
        roleName: role.name,
        initialPermissions: role.permissions,
      ),
    );
    if (!mounted || updated == null) return;
    setState(() {
      _roles = [
        for (final r in _roles)
          if (r.id == role.id)
            r.copyWith(
              permissions: updated,
              permissionCount: updated.length,
            )
          else
            r,
      ];
    });
  }

  Future<void> _createRole() async {
    if (!_canWriteRoles || _creatingRole) return;
    setState(() => _creatingRole = true);
    final created = await showNewRoleSheet(context, api: _api);
    if (!mounted) return;
    setState(() => _creatingRole = false);
    if (created == null) return;
    await _loadRoles();
  }

  Future<void> _renameRole(_AccessRole role) async {
    if (!_canWriteRoles || role.id.isEmpty) return;
    final updated = await showRenameRoleSheet(
      context,
      api: _api,
      roleId: role.id,
      name: role.name,
      description: role.description,
    );
    if (!mounted || updated == null) return;
    setState(() {
      _roles = [
        for (final r in _roles)
          if (r.id == role.id)
            r.copyWith(
              name: JsonCodec.stringOr(updated['name'], r.name),
              description:
                  JsonCodec.stringOr(updated['description'], r.description),
            )
          else
            r,
      ]..sort((a, b) => a.name.compareTo(b.name));
    });
  }

  Future<void> _deleteRole(_AccessRole role) async {
    if (!_canWriteRoles || role.id.isEmpty || role.builtIn) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete role?'),
        content: Text('Delete "${role.name}" (${role.code})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.criticalRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final result = await _api.delete(ApiEndpoints.roleById(role.id));
    if (!mounted) return;
    result.when(
      success: (_) {
        setState(() {
          _roles = [for (final r in _roles) if (r.id != role.id) r];
        });
        AppSnackbar.show('Role deleted', role.name, force: true);
      },
      failure: (error) =>
          AppSnackbar.show('Could not delete', error.message, force: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = <String>[
      if (_canUsers) 'Users',
      if (_canRoles) 'Roles',
    ];
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        title: Text(
          'Users & Access',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (_canUsers && !_onRolesTab) ...[
            if (_canReadCategories)
              TextButton(
                onPressed: _openCategories,
                child: const Text('Staff categories'),
              ),
            TextButton(
              onPressed: () {
                setState(() => _showDeactivated = !_showDeactivated);
                _loadPeople();
              },
              child: Text(
                _showDeactivated ? 'Hide deactivated' : 'Show deactivated',
              ),
            ),
          ],
        ],
        bottom: titles.length > 1
            ? TabBar(
                controller: _tabs,
                labelColor: AppColors.secondaryTeal,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.secondaryTeal,
                tabs: [for (final t in titles) Tab(text: t)],
              )
            : null,
      ),
      floatingActionButton: _onRolesTab
          ? (_canWriteRoles
              ? FloatingActionButton.extended(
                  onPressed: _creatingRole ? null : _createRole,
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add),
                  label: Text(_creatingRole ? 'Creating…' : 'New role'),
                )
              : null)
          : (_canWriteUsers
              ? FloatingActionButton.extended(
                  onPressed: _openAddUser,
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add),
                  label: const Text('Add user'),
                )
              : null),
      body: AppRefreshIndicator(
        onRefresh: _refresh,
        child: titles.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      'Users & Access is not available for your account.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              )
            : TabBarView(
                controller: _tabs,
                children: [
                  if (_canUsers) _usersPane(),
                  if (_canRoles) _rolesPane(),
                ],
              ),
      ),
    );
  }

  InputDecoration _filterFieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontFamily: 'Manrope',
        color: AppColors.textSecondary,
      ),
      filled: true,
      fillColor: AppColors.surfaceWhite,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.searchBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.searchBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.secondaryTeal),
      ),
    );
  }

  Widget _usersPane() {
    if (_loadingPeople && _people.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_peopleError != null && _people.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Center(child: Text(_peopleError!)),
        ],
      );
    }
    final s = _summary;
    // Web: login accounts without a staff link = withLogin − linkedToStaff
    // (not people − linkedToStaff — that over-counts staff-only rows).
    final linkedBase = s.withLogin > 0 ? s.withLogin : s.people;
    final unlinked = (linkedBase - s.linkedToStaff).clamp(0, linkedBase);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.7,
          children: [
            _MetricChip(label: 'Total people', value: '${s.people}'),
            _MetricChip(label: 'Active accounts', value: '${s.active}'),
            _MetricChip(label: 'Pending invitations', value: '${s.invited}'),
            _MetricChip(label: 'Never signed in', value: '${s.neverSignedIn}'),
          ],
        ),
        if (s.neverSignedIn > 0 || unlinked > 0) ...[
          const SizedBox(height: 12),
          _WorthALookCard(
            neverSignedIn: s.neverSignedIn,
            unlinkedToStaff: unlinked,
            onShowNoLogin: () {
              setState(() => _typeFilter = 'no_login');
              _loadPeople();
            },
          ),
        ],
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (id, label, count) in [
                ('all', 'All', s.people),
                ('employee', 'Employees', s.employees),
                ('family', 'Family', s.family),
                ('no_login', 'No login', s.withoutLogin),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text('$label ($count)'),
                    selected: _typeFilter == id,
                    selectedColor: AppColors.activeBackground,
                    labelStyle: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      color: _typeFilter == id
                          ? AppColors.secondaryTeal
                          : AppColors.textBody,
                    ),
                    onSelected: (_) {
                      setState(() => _typeFilter = id);
                      _loadPeople();
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: const Text('All roles'),
                  selected: _roleCodeFilter == null,
                  selectedColor: AppColors.activeBackground,
                  checkmarkColor: AppColors.secondaryTeal,
                  labelStyle: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    color: _roleCodeFilter == null
                        ? AppColors.secondaryTeal
                        : AppColors.textBody,
                  ),
                  onSelected: (_) {
                    setState(() => _roleCodeFilter = null);
                    _loadPeople();
                  },
                ),
              ),
              for (final role in s.byRole)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text('${role.name} ${role.people}'),
                    selected: _roleCodeFilter == role.code,
                    selectedColor: AppColors.activeBackground,
                    checkmarkColor: AppColors.secondaryTeal,
                    labelStyle: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      color: _roleCodeFilter == role.code
                          ? AppColors.secondaryTeal
                          : AppColors.textBody,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _roleCodeFilter =
                            _roleCodeFilter == role.code ? null : role.code;
                      });
                      _loadPeople();
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: (v) {
            _peopleQuery = v;
          },
          onSubmitted: (_) => _loadPeople(),
          style: const TextStyle(fontFamily: 'Manrope', fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search name, email, employee code…',
            hintStyle: const TextStyle(
              fontFamily: 'Manrope',
              color: AppColors.textMuted,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: AppColors.surfaceWhite,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.searchBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.searchBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.secondaryTeal),
            ),
            suffixIcon: IconButton(
              tooltip: 'Search',
              onPressed: _loadPeople,
              icon: const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.secondaryTeal,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                initialValue: _residenceIdFilter,
                isExpanded: true,
                decoration: _filterFieldDecoration('Residence'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All residences'),
                  ),
                  for (final r in _residences)
                    DropdownMenuItem(value: r.id, child: Text(r.name)),
                ],
                onChanged: (v) {
                  setState(() => _residenceIdFilter = v);
                  _loadPeople();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String?>(
                initialValue: _statusFilter,
                isExpanded: true,
                decoration: _filterFieldDecoration('Status'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All statuses')),
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  DropdownMenuItem(value: 'invited', child: Text('Invited')),
                ],
                onChanged: (v) {
                  setState(() => _statusFilter = v);
                  _loadPeople();
                },
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              setState(() {
                _peopleQuery = '';
                _typeFilter = 'all';
                _roleCodeFilter = null;
                _statusFilter = null;
                _residenceIdFilter = null;
                _showDeactivated = false;
              });
              _loadPeople();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.secondaryTeal,
            ),
            child: const Text(
              'Clear filters',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Text(
          'People — Everyone on the books',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            color: AppColors.primaryNavy,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
          ),
        ),
        const SizedBox(height: 8),
        if (_loadingPeople)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_people.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No people match these filters.')),
          )
        else
          for (final person in _people) ...[
            _PersonCard(
              person: person,
              canManage: _canWriteUsers,
              onOpen: () => _openEditUser(person),
              onActions: () => _personAction(person),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget _rolesPane() {
    if (_loadingRoles && _roles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_rolesError != null && _roles.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Center(child: Text(_rolesError!)),
        ],
      );
    }
    final q = _roleQuery.trim().toLowerCase();
    final roles = q.isEmpty
        ? _roles
        : [
            for (final role in _roles)
              if (role.name.toLowerCase().contains(q) ||
                  role.code.toLowerCase().contains(q) ||
                  role.description.toLowerCase().contains(q))
                role,
          ];
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        TextField(
          onChanged: (v) => setState(() => _roleQuery = v),
          decoration: const InputDecoration(
            hintText: 'Search by role name or code',
            prefixIcon: Icon(Icons.search_rounded),
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < roles.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _RoleCard(
            role: roles[i],
            canOpenPermissions: _canRoles && roles[i].id.isNotEmpty,
            canWrite: _canWriteRoles,
            onPermissions: () => _openPermissions(roles[i]),
            onRename: _canWriteRoles ? () => _renameRole(roles[i]) : null,
            onHolders: () => showRoleHoldersSheet(
              context,
              api: _api,
              roleId: roles[i].id,
              roleName: roles[i].name,
            ),
            onDelete: _canWriteRoles && !roles[i].builtIn
                ? () => _deleteRole(roles[i])
                : null,
          ),
        ],
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A16293F),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: AppColors.primaryNavy,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Web "Worth a look" callouts — never signed in + accounts without staff link.
class _WorthALookCard extends StatelessWidget {
  final int neverSignedIn;
  final int unlinkedToStaff;
  final VoidCallback onShowNoLogin;

  const _WorthALookCard({
    required this.neverSignedIn,
    required this.unlinkedToStaff,
    required this.onShowNoLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.infoBlue.withValues(alpha: 0.28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A16293F),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.infoBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.visibility_outlined,
                  size: 16,
                  color: AppColors.infoBlue,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Worth a look',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.primaryNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (neverSignedIn > 0)
            _WorthRow(
              color: AppColors.urgentAmber,
              icon: Icons.login_outlined,
              text:
                  '$neverSignedIn account${neverSignedIn == 1 ? '' : 's'} never signed in.',
            ),
          if (neverSignedIn > 0 && unlinkedToStaff > 0)
            const SizedBox(height: 8),
          if (unlinkedToStaff > 0)
            _WorthRow(
              color: AppColors.infoBlue,
              icon: Icons.link_off_outlined,
              text:
                  '$unlinkedToStaff account${unlinkedToStaff == 1 ? '' : 's'} not tied to an employee record.',
            ),
          if (neverSignedIn > 0) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onShowNoLogin,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.secondaryTeal,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Show people with no login',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WorthRow extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const _WorthRow({
    required this.color,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: color,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _PersonCard extends StatelessWidget {
  final DirectoryPerson person;
  final bool canManage;
  final VoidCallback onOpen;
  final VoidCallback onActions;

  const _PersonCard({
    required this.person,
    required this.canManage,
    required this.onOpen,
    required this.onActions,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSeed =
        person.staffId.isNotEmpty ? person.staffId : person.id;
    return SurfaceCard.card(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HrInitialsAvatar(
                  initials: IsoDateRange.initials(
                    person.name,
                    fallback: '?',
                  ),
                  imageUrl: person.photoUrl,
                  size: 44,
                  background: ClientsLabels.avatarColor(avatarSeed),
                  foreground: AppColors.surfaceWhite,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.name,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      if (person.email.isNotEmpty)
                        Text(
                          person.email,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _Tag(person.typeLabel),
                          _Tag(person.roleLabel),
                          _Tag(person.residenceLabel),
                          _Tag(person.loginLabel),
                          _Tag('Cert: ${person.certificationLabel}'),
                          _Tag(
                            person.isDeactivated ? 'Inactive' : 'Active',
                            tone: person.isDeactivated
                                ? AppColors.criticalRed
                                : AppColors.activeGreen,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (canManage || person.userId.isNotEmpty)
                  IconButton(
                    onPressed: onActions,
                    icon: const Icon(Icons.more_vert),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color? tone;

  const _Tag(this.label, {this.tone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.filterButtonBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: tone ?? AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final _AccessRole role;
  final bool canOpenPermissions;
  final bool canWrite;
  final VoidCallback onPermissions;
  final VoidCallback? onRename;
  final VoidCallback? onHolders;
  final VoidCallback? onDelete;

  const _RoleCard({
    required this.role,
    required this.canOpenPermissions,
    required this.canWrite,
    required this.onPermissions,
    this.onRename,
    this.onHolders,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard.card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.name,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      if (role.code.isNotEmpty)
                        Text(
                          role.code,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                if (role.builtIn)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.filterButtonBackground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Built in',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (role.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                role.description,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '${role.permissionCount} granted'
              '${role.userCount == null ? '' : ' · ${role.userCount} holders'}',
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                if (onRename != null)
                  OutlinedButton(
                    onPressed: onRename,
                    child: const Text('Rename'),
                  ),
                if (onHolders != null)
                  OutlinedButton(
                    onPressed: onHolders,
                    child: const Text('Holders'),
                  ),
                if (onDelete != null)
                  OutlinedButton(
                    onPressed: onDelete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.criticalRed,
                    ),
                    child: const Text('Delete'),
                  ),
                if (canOpenPermissions)
                  FilledButton.tonal(
                    onPressed: onPermissions,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(canWrite ? 'Permissions' : 'View permissions'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessRole {
  final String id;
  final String name;
  final String code;
  final String description;
  final int permissionCount;
  final int? userCount;
  final bool builtIn;
  final List<String> permissions;

  const _AccessRole({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.permissionCount,
    required this.userCount,
    required this.builtIn,
    required this.permissions,
  });

  _AccessRole copyWith({
    String? name,
    String? description,
    List<String>? permissions,
    int? permissionCount,
    int? userCount,
  }) {
    return _AccessRole(
      id: id,
      name: name ?? this.name,
      code: code,
      description: description ?? this.description,
      permissionCount: permissionCount ?? this.permissionCount,
      userCount: userCount ?? this.userCount,
      builtIn: builtIn,
      permissions: permissions ?? this.permissions,
    );
  }

  factory _AccessRole.fromJson(Map<String, dynamic> json) {
    final rawPerms = json['permissions'];
    final permissions = <String>[];
    if (rawPerms is List) {
      for (final item in rawPerms) {
        if (item is String && item.isNotEmpty) {
          permissions.add(item);
        } else if (item is Map) {
          final map = JsonCodec.asMap(item);
          final key = JsonCodec.string(map['key']) ??
              JsonCodec.string(map['name']) ??
              '';
          if (key.isNotEmpty) permissions.add(key);
        }
      }
    }
    return _AccessRole(
      id: JsonCodec.stringOr(json['id'], ''),
      name: JsonCodec.stringOr(
        json['name'],
        JsonCodec.stringOr(json['code'], 'Role'),
      ),
      code: JsonCodec.stringOr(json['code'], ''),
      description: JsonCodec.stringOr(json['description'], ''),
      permissionCount: permissions.isNotEmpty
          ? permissions.length
          : () {
              final raw = json['permissionCount'] ?? json['permissionsCount'];
              if (raw is int) return raw;
              if (raw is num) return raw.toInt();
              return int.tryParse('$raw') ?? 0;
            }(),
      userCount: () {
        final raw = json['userCount'] ?? json['holdersCount'];
        if (raw is int) return raw;
        if (raw is num) return raw.toInt();
        return int.tryParse('$raw');
      }(),
      builtIn: JsonCodec.boolean(json['isSystem']) ??
          JsonCodec.boolean(json['builtIn'] ?? json['isBuiltIn']) ??
          JsonCodec.boolean(json['system']) ??
          false,
      permissions: permissions,
    );
  }
}
