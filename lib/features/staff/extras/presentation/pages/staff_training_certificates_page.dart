import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../domain/repositories/staff_extras_repository.dart';
import '../widgets/staff_extras_list_scaffold.dart';

class StaffTrainingCertificatesPage extends StatefulWidget {
  const StaffTrainingCertificatesPage({super.key});

  @override
  State<StaffTrainingCertificatesPage> createState() =>
      _StaffTrainingCertificatesPageState();
}

class _StaffTrainingCertificatesPageState
    extends State<StaffTrainingCertificatesPage> {
  late final StaffExtrasRepository _repository;
  bool _loading = true;
  String? _error;
  List<Map<String, String>> _items = const [];

  @override
  void initState() {
    super.initState();
    _repository = GetIt.instance<StaffExtrasRepository>();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repository.getTrainingCertificates();
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

  @override
  Widget build(BuildContext context) {
    return StaffExtrasListScaffold(
      title: 'Certificates',
      loading: _loading,
      error: _error,
      items: _items,
      onRefresh: _load,
    );
  }
}
