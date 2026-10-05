import 'package:comprehensive_hr_and_ops/core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/hr/handovers/presentation/widgets/handover_common.dart';
import 'package:comprehensive_hr_and_ops/features/hr/inventory/data/mappers/inventory_mapper.dart';
import 'package:comprehensive_hr_and_ops/features/hr/inventory/domain/entities/inventory_item.dart';
import 'package:comprehensive_hr_and_ops/features/hr/inventory/domain/entities/purchasing.dart';
import 'package:comprehensive_hr_and_ops/features/hr/inventory/domain/entities/stock_ops.dart';
import 'package:comprehensive_hr_and_ops/features/hr/inventory/domain/repositories/inventory_repository.dart';
import 'package:comprehensive_hr_and_ops/features/hr/inventory/presentation/controllers/inventory_stock_controller.dart';
import 'package:comprehensive_hr_and_ops/features/hr/inventory/presentation/controllers/purchasing_controller.dart';
import 'package:comprehensive_hr_and_ops/features/hr/inventory/presentation/controllers/stock_counts_controller.dart';
import 'package:comprehensive_hr_and_ops/features/hr/inventory/presentation/controllers/stock_transfers_controller.dart';
import 'package:comprehensive_hr_and_ops/features/hr/inventory/presentation/pages/inventory_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gems_core/gems_core.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

Future<void> _loadOutfitFont() async {
  final data = await rootBundle.load('assets/fonts/outfit/Outfit-Variable.ttf');
  final loader = FontLoader('Outfit')..addFont(Future.value(data));
  await loader.load();
}

Widget _app(Widget home) => ScreenUtilInit(
      designSize: const Size(ResponsiveHelper.baseWidth, ResponsiveHelper.baseHeight),
      minTextAdapt: true,
      builder: (_, _) => GetMaterialApp(
        home: home,
        theme: ThemeData(
          fontFamily: 'Outfit',
          scaffoldBackgroundColor: AppColors.scaffoldBackground,
        ),
      ),
    );

void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _tapKey(WidgetTester tester, String key) => _tap(tester, find.byKey(ValueKey(key)));

Finder _inKey(String key, Finder matching) =>
    find.descendant(of: find.byKey(ValueKey(key)), matching: matching);

Future<void> _type(WidgetTester tester, String key, String text) async {
  final field = _inKey(key, find.byType(TextField));
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, text);
  await tester.pumpAndSettle();
}

/// Opens an [InventorySelect] by key and picks [label] from its sheet.
Future<void> _pick(WidgetTester tester, String key, String label) async {
  await _tap(tester, _inKey(key, find.byType(InkWell)).first);
  await _tap(tester, find.text(label).last);
}

VoidCallback? _onPressed(WidgetTester tester, String key) =>
    tester.widget<HandoverButton>(find.byKey(ValueKey(key))).onPressed;

class _Session extends UserSession {
  final Set<String> denied;

  _Session({this.denied = const {}});

  @override
  bool can(String permission) => !denied.contains(permission);
}

// ---------------------------------------------------------------- fixtures ----

String _isoIn(int days) {
  final now = DateTime.now().toUtc();
  final d = DateTime.utc(now.year, now.month, now.day).add(Duration(days: days));
  return '${d.toIso8601String().substring(0, 10)}T00:00:00.000Z';
}

const _gloves = InventoryItem(
  id: 'i1',
  name: 'Nitrile gloves',
  residenceId: 'r1',
  residenceName: 'Elm House',
  categoryId: 'c1',
  categoryName: 'PPE',
  sku: 'GL-M',
  quantity: 3,
  unit: 'box',
  reorderLevel: 5,
  supplierName: 'MedSupply',
  lastUnitCost: 2.75,
  stockValue: 30,
);

const _cream = InventoryItem(
  id: 'i2',
  name: 'Barrier cream',
  residenceId: 'r1',
  residenceName: 'Elm House',
  categoryId: 'c1',
  categoryName: 'PPE',
  quantity: 12,
  unit: 'tube',
  tracksBatches: true,
);

const _summary = InventorySummary(
  items: 2,
  lowStock: 1,
  outOfStock: 0,
  watched: 1,
  value: 1234.5,
  unpriced: 1,
);

final _counts = [
  const StockCount(
    id: 'k1',
    residenceId: 'r1',
    residenceName: 'Elm House',
    status: 'draft',
    lines: [
      StockCountLine(id: 'cl1', itemName: 'Nitrile gloves', itemUnit: 'box', systemQty: 3),
      StockCountLine(
        id: 'cl2',
        itemName: 'Barrier cream',
        itemUnit: 'tube',
        hasBatch: true,
        batchNo: 'L-9',
        batchExpiry: '2027-03-01T00:00:00.000Z',
        systemQty: 5,
      ),
    ],
  ),
  const StockCount(
    id: 'k2',
    residenceId: 'r2',
    residenceName: 'Oak Lodge',
    status: 'submitted',
    varianceCount: 2,
  ),
];

const _transfers = [
  StockTransfer(
    id: 't1',
    status: 'requested',
    fromResidenceId: 'r1',
    toResidenceId: 'r2',
    fromResidenceName: 'Elm House',
    toResidenceName: 'Oak Lodge',
    notes: 'Short until Thursday',
    lines: [StockTransferLine(id: 'tl1', itemName: 'Nitrile gloves', quantity: 2)],
  ),
  StockTransfer(
    id: 't2',
    status: 'dispatched',
    fromResidenceId: 'r1',
    toResidenceId: 'r2',
    fromResidenceName: 'Elm House',
    toResidenceName: 'Oak Lodge',
    lines: [
      StockTransferLine(id: 'tl2', itemName: 'Barrier cream', quantity: 4, dispatchedQuantity: 4),
    ],
  ),
  StockTransfer(
    id: 't3',
    status: 'received',
    fromResidenceId: 'r2',
    toResidenceId: 'r1',
    fromResidenceName: 'Oak Lodge',
    toResidenceName: 'Elm House',
    lines: [
      StockTransferLine(
        id: 'tl3',
        itemName: 'Aprons',
        quantity: 5,
        dispatchedQuantity: 5,
        receivedQuantity: 3,
      ),
    ],
  ),
];

const _orders = [
  PurchaseOrder(
    id: 'o1',
    reference: 'PO-0001',
    status: 'draft',
    residenceId: 'r1',
    residenceName: 'Elm House',
    items: [
      PurchaseOrderLine(
        id: 'ol1',
        description: 'Gloves',
        quantity: 10,
        unitCost: 2,
        lineTotal: 20,
        inventoryItem: PurchaseOrderLineItem(id: 'i1', name: 'Nitrile gloves', unit: 'box'),
      ),
    ],
  ),
  PurchaseOrder(
    id: 'o2',
    reference: 'PO-0002',
    status: 'pending_approval',
    residenceId: 'r1',
    residenceName: 'Elm House',
    supplierId: 's1',
    supplierName: 'MedSupply',
  ),
  PurchaseOrder(
    id: 'o3',
    reference: 'PO-0003',
    status: 'submitted',
    residenceId: 'r1',
    residenceName: 'Elm House',
    supplierId: 's1',
    supplierName: 'MedSupply',
    items: [
      PurchaseOrderLine(
        id: 'ol3',
        description: 'Cream',
        quantity: 6,
        receivedQuantity: 2,
        unit: 'tube',
        inventoryItem: PurchaseOrderLineItem(
          id: 'i2',
          name: 'Barrier cream',
          unit: 'tube',
          tracksBatches: true,
        ),
      ),
      PurchaseOrderLine(id: 'ol4', description: 'Paper', quantity: 3, receivedQuantity: 3),
    ],
  ),
];

final _suppliers = [
  const InventorySupplier(id: 's1', name: 'MedSupply', category: 'pharmacy', email: 'orders@med.test'),
  InventorySupplier(
    id: 's2',
    name: 'Retired Co',
    residenceId: 'r2',
    category: 'general',
    deletedAt: DateTime.utc(2026, 1, 1),
  ),
];

class _FakeRepo implements InventoryRepository {
  final List<(String, Object?)> calls = [];
  final List<Map<String, Object?>> itemQueries = [];

  Iterable<Object?> payloads(String name) => calls.where((c) => c.$1 == name).map((c) => c.$2);

  Future<Result<void>> _ok(String name, [Object? payload]) async {
    calls.add((name, payload));
    return Result.success(null);
  }

  @override
  Future<Result<InventoryItemPage>> items({
    required int page,
    required int limit,
    String? search,
    String? residenceId,
    String? categoryId,
    bool lowStock = false,
  }) async {
    itemQueries.add({
      'page': page,
      'limit': limit,
      'search': search,
      'residenceId': residenceId,
      'lowStock': lowStock,
    });
    final rows = lowStock ? const [_gloves] : const [_gloves, _cream];
    return Result.success(InventoryItemPage(items: rows, total: rows.length, summary: _summary));
  }

  @override
  Future<Result<void>> createItem(Map<String, dynamic> body) => _ok('createItem', body);

  @override
  Future<Result<void>> updateItem(String id, Map<String, dynamic> body) =>
      _ok('updateItem', {'id': id, ...body});

  @override
  Future<Result<void>> deleteItem(String id) => _ok('deleteItem', id);

  @override
  Future<Result<void>> adjust(String id, Map<String, dynamic> body) =>
      _ok('adjust', {'id': id, ...body});

  @override
  Future<Result<void>> move(String id, Map<String, dynamic> body) => _ok('move', {'id': id, ...body});

  @override
  Future<Result<void>> recordLoss(Map<String, dynamic> body) => _ok('recordLoss', body);

  @override
  Future<Result<List<InventoryBatch>>> batches(String itemId) async => Result.success(
        itemId == 'i2'
            ? [InventoryBatch(id: 'b2', batchNo: 'L-9', quantity: 5, expiryDate: _isoIn(40), unitCost: 2.5)]
            : const [],
      );

  @override
  Future<Result<void>> addBatch(String itemId, Map<String, dynamic> body) =>
      _ok('addBatch', {'itemId': itemId, ...body});

  @override
  Future<Result<void>> updateBatch(String itemId, String batchId, Map<String, dynamic> body) =>
      _ok('updateBatch', {'batchId': batchId, ...body});

  @override
  Future<Result<List<InventoryBatch>>> expiringBatches({
    required int withinDays,
    String? residenceId,
  }) async =>
      Result.success([
        InventoryBatch(
          id: 'b1',
          batchNo: 'L-22',
          quantity: 4,
          expiryDate: _isoIn(3),
          itemName: 'Barrier cream',
          itemUnit: 'tube',
        ),
      ]);

  @override
  Future<Result<List<StockMovement>>> movements({
    String? itemId,
    String? residenceId,
    required int limit,
  }) async =>
      Result.success(
        itemId != null
            ? [
                StockMovement(
                  id: 'm2',
                  type: 'adjustment',
                  changeQty: 2,
                  previousQty: 10,
                  newQty: 12,
                  reason: 'Found box',
                  performedByName: 'Rafi Ahmed',
                  createdAt: DateTime.utc(2026, 9, 1, 9),
                ),
              ]
            : [
                StockMovement(
                  id: 'm1',
                  type: 'stock_out',
                  changeQty: -2,
                  itemName: 'Nitrile gloves',
                  unit: 'box',
                  residenceName: 'Elm House',
                  performedByName: 'Rafi Ahmed',
                  createdAt: DateTime.utc(2026, 9, 1, 9),
                ),
              ],
      );

  @override
  Future<Result<List<InventoryCostEntry>>> costHistory(String itemId) async => Result.success(const [
        InventoryCostEntry(
          purchaseOrderId: 'po2',
          reference: 'PO-2',
          supplierName: 'MedSupply',
          quantity: 4,
          receivedQuantity: 4,
          unit: 'tube',
          unitCost: 3,
          receivedAt: '2026-09-10T10:00:00.000Z',
        ),
        InventoryCostEntry(
          purchaseOrderId: 'po1',
          reference: 'PO-1',
          quantity: 4,
          unitCost: 2.5,
          orderedAt: '2026-08-01T10:00:00.000Z',
        ),
      ]);

  @override
  Future<Result<List<InventoryItemSupplier>>> itemSuppliers(String itemId) async =>
      Result.success(const [
        InventoryItemSupplier(
          id: 'link1',
          supplierId: 's1',
          supplierName: 'MedSupply',
          supplierSku: 'MS-1',
          unitCost: 3,
          leadTimeDays: 2,
          isPreferred: true,
        ),
      ]);

  @override
  Future<Result<void>> linkSupplier(String itemId, Map<String, dynamic> body) =>
      _ok('linkSupplier', {'itemId': itemId, ...body});

  @override
  Future<Result<void>> unlinkSupplier(String itemId, String linkId) => _ok('unlinkSupplier', linkId);

  @override
  Future<Result<List<InventoryLoss>>> losses({required int page, required int limit}) async =>
      Result.success([
        InventoryLoss(
          id: 'l1',
          exceptionType: 'expired',
          itemName: 'Barrier cream',
          unit: 'tube',
          quantity: 1,
          notes: 'Past date',
          residenceName: 'Elm House',
          loggedByName: 'Rafi Ahmed',
          createdAt: DateTime.utc(2026, 9, 2, 9),
        ),
      ]);

  @override
  Future<Result<List<InventoryCatalogueEntry>>> categories({bool includeArchived = false}) async =>
      Result.success([
        const InventoryCatalogueEntry(id: 'c1', name: 'PPE'),
        if (includeArchived) const InventoryCatalogueEntry(id: 'c2', name: 'Old stock', isActive: false),
      ]);

  @override
  Future<Result<List<InventoryCatalogueEntry>>> unitTypes({bool includeArchived = false}) async =>
      Result.success(const [InventoryCatalogueEntry(id: 'u1', name: 'Box', code: 'box')]);

  @override
  Future<Result<void>> createCategory(String name) => _ok('createCategory', name);

  @override
  Future<Result<void>> renameCategory(String id, String name) => _ok('renameCategory', name);

  @override
  Future<Result<void>> archiveCategory(String id, bool archive) =>
      _ok('archiveCategory', {'id': id, 'archive': archive});

  @override
  Future<Result<void>> createUnitType(String code, String name) =>
      _ok('createUnitType', {'code': code, 'name': name});

  @override
  Future<Result<void>> renameUnitType(String id, String name) => _ok('renameUnitType', name);

  @override
  Future<Result<void>> archiveUnitType(String id, bool archive) => _ok('archiveUnitType', id);

  @override
  Future<Result<List<InventoryOption>>> residences() async => Result.success(const [
        InventoryOption(value: 'r1', label: 'Elm House'),
        InventoryOption(value: 'r2', label: 'Oak Lodge'),
      ]);

  @override
  Future<Result<InventoryListPage<StockCount>>> stockCounts({required int page, required int limit}) async =>
      Result.success(InventoryListPage(items: _counts, total: _counts.length));

  @override
  Future<Result<StockCount>> stockCount(String id) async =>
      Result.success(_counts.firstWhere((c) => c.id == id));

  @override
  Future<Result<StockCountOpened>> openStockCount({
    required String residenceId,
    String? categoryId,
  }) async {
    calls.add(('openStockCount', residenceId));
    return Result.success(const StockCountOpened(id: 'k1'));
  }

  @override
  Future<Result<void>> saveCountLines(String id, List<Map<String, dynamic>> lines) =>
      _ok('saveCountLines', lines);

  @override
  Future<Result<void>> submitCount(String id) => _ok('submitCount', id);

  @override
  Future<Result<void>> cancelCount(String id) => _ok('cancelCount', id);

  @override
  Future<Result<InventoryListPage<StockTransfer>>> transfers({required int page, required int limit}) async =>
      Result.success(InventoryListPage(items: _transfers, total: _transfers.length));

  @override
  Future<Result<void>> createTransfer(Map<String, dynamic> body) => _ok('createTransfer', body);

  @override
  Future<Result<void>> approveTransfer(String id) => _ok('approveTransfer', id);

  @override
  Future<Result<void>> dispatchTransfer(String id, List<Map<String, dynamic>> lines) =>
      _ok('dispatchTransfer', lines);

  @override
  Future<Result<void>> receiveTransfer(String id, List<Map<String, dynamic>> lines) =>
      _ok('receiveTransfer', lines);

  @override
  Future<Result<void>> cancelTransfer(String id) => _ok('cancelTransfer', id);

  @override
  Future<Result<InventoryListPage<InventorySupplier>>> suppliers({required int page, required int limit}) async =>
      Result.success(InventoryListPage(items: _suppliers, total: _suppliers.length));

  @override
  Future<Result<void>> createSupplier({required String name, required String category}) =>
      _ok('createSupplier', {'name': name, 'category': category});

  @override
  Future<Result<void>> removeSupplier(String id) => _ok('removeSupplier', id);

  @override
  Future<Result<void>> restoreSupplier(String id) => _ok('restoreSupplier', id);

  @override
  Future<Result<InventoryListPage<PurchaseOrder>>> purchaseOrders({required int page, required int limit}) async =>
      Result.success(const InventoryListPage(items: _orders, total: 3));

  @override
  Future<Result<void>> createOrder(Map<String, dynamic> body) => _ok('createOrder', body);

  @override
  Future<Result<void>> updateOrder(String id, Map<String, dynamic> body) =>
      _ok('updateOrder', {'id': id, ...body});

  @override
  Future<Result<void>> submitOrder(String id) => _ok('submitOrder', id);

  @override
  Future<Result<void>> requestOrderApproval(String id) => _ok('requestOrderApproval', id);

  @override
  Future<Result<void>> approveOrder(String id) => _ok('approveOrder', id);

  @override
  Future<Result<void>> rejectOrder(String id, String reason) =>
      _ok('rejectOrder', {'id': id, 'reason': reason});

  @override
  Future<Result<void>> receiveOrder(String id, Map<String, dynamic> body) =>
      _ok('receiveOrder', {'id': id, ...body});

  @override
  Future<Result<void>> cancelOrder(String id) => _ok('cancelOrder', id);
}

Future<_FakeRepo> _pumpInventory(
  WidgetTester tester, {
  Set<String> denied = const {},
  InventoryArea area = InventoryArea.stock,
}) async {
  _tallView(tester);
  final repo = _FakeRepo();
  final session = Get.put<UserSession>(_Session(denied: denied));
  GetIt.I
    ..registerFactory<InventoryStockController>(
      () => InventoryStockController(repository: repo, session: session),
    )
    ..registerFactory<StockCountsController>(
      () => StockCountsController(repository: repo, session: session),
    )
    ..registerFactory<StockTransfersController>(
      () => StockTransfersController(repository: repo, session: session),
    )
    ..registerFactory<PurchasingController>(
      () => PurchasingController(repository: repo, session: session),
    );
  await tester.pumpWidget(_app(InventoryPage(initialArea: area)));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await _loadOutfitFont();
    Get.reset();
    await GetIt.I.reset();
  });

  tearDown(() async {
    Get.reset();
    await GetIt.I.reset();
  });

  group('M09 mapper (live payload shapes)', () {
    test('items read string quantities, nested names and meta.summary', () {
      final page = InventoryMapper.itemPageFrom({
        'data': [
          {
            'id': 'i1',
            'name': 'Gloves',
            'residenceId': 'r1',
            'residence': {'id': 'r1', 'name': 'Elm House'},
            'categoryId': 'c1',
            'category': {'id': 'c1', 'name': 'PPE'},
            'quantity': '12',
            'reorderLevel': '5',
            'unit': 'box',
            'tracksBatches': true,
            'stockValue': null,
            'lastUnitCost': '2.75',
          },
        ],
        'meta': {
          'page': 1,
          'limit': 20,
          'total': 41,
          'totalPages': 3,
          'summary': {'items': 41, 'outOfStock': 2, 'lowStock': 5, 'watched': 9, 'value': 812.4, 'unpriced': 3},
        },
      });
      final item = page.items.single;
      expect(item.quantity, 12);
      expect(item.reorderLevel, 5);
      expect(item.residenceName, 'Elm House');
      expect(item.categoryName, 'PPE');
      expect(item.lastUnitCost, 2.75);
      expect(item.stockState, InventoryStockState.ok);
      expect(page.total, 41);
      expect(page.summary.lowStock, 5);
      expect(page.summary.unpriced, 3);
      expect(page.summary.value, 812.4);
    });

    test('purchase orders total only priced lines and keep the restocked item', () {
      final order = InventoryMapper.orderFrom({
        'id': 'abcdef123456',
        'status': 'partially_received',
        'supplierId': 's1',
        'supplier': {'id': 's1', 'name': 'MedSupply'},
        'items': [
          {
            'id': 'l1',
            'description': 'Gloves',
            'quantity': '10',
            'receivedQuantity': '4',
            'lineTotal': '25.50',
            'inventoryItem': {'id': 'i1', 'name': 'Gloves', 'unit': 'box', 'tracksBatches': true},
          },
          {'id': 'l2', 'description': 'Paper', 'quantity': 2, 'lineTotal': null},
        ],
      })!;
      expect(order.total, 25.5);
      expect(order.orderedUnits, 12);
      expect(order.receivedUnits, 4);
      expect(order.displayReference, '#abcdef12');
      expect(order.items.first.inventoryItem!.tracksBatches, isTrue);
      expect(order.allows('receive'), isTrue);
      expect(order.allows('edit'), isFalse);
      expect(order.allows('cancel'), isTrue);
    });

    test('transfers and counts follow the web transition tables', () {
      final transfer = InventoryMapper.transferFrom({
        'id': 't1',
        'status': 'partially_dispatched',
        'fromResidenceId': 'r1',
        'toResidenceId': 'r2',
        'fromResidence': {'id': 'r1', 'name': 'Elm House'},
        'lines': [
          {'id': 'x', 'item': {'id': 'i1', 'name': 'Gloves'}, 'quantity': '4', 'dispatchedQuantity': 0},
        ],
      })!;
      expect(transfer.nextSteps, ['dispatch', 'receive']);
      expect(transfer.canCancel, isFalse);
      expect(transfer.lines.single.dispatchedQuantity, 0);
      final count = InventoryMapper.countFrom({
        'id': 'k1',
        'residenceId': 'r1',
        'status': 'draft',
        'lines': [
          {
            'id': 'cl',
            'item': {'id': 'i1', 'name': 'Gloves', 'unit': 'box', 'currentQuantity': '3'},
            'batch': {'id': 'b', 'batchNo': null, 'expiryDate': null},
            'systemQty': '3',
            'countedQty': null,
          },
        ],
      })!;
      expect(count.isEditable, isTrue);
      expect(count.lines.single.hasBatch, isTrue);
      expect(count.lines.single.systemQty, 3);
    });
  });

  group('M09 navigation and access', () {
    testWidgets('shows the four web sub-pages and switches between them', (tester) async {
      await _pumpInventory(tester);
      expect(find.text('Inventory'), findsOneWidget);
      for (final tab in ['Stock', 'Stock counts', 'Transfers', 'Purchasing']) {
        expect(find.text(tab), findsWidgets);
      }
      await _tapKey(tester, 'inventory-nav-transfers');
      expect(find.text('Stock transfers'), findsOneWidget);
      await _tapKey(tester, 'inventory-nav-purchasing');
      expect(find.byKey(const ValueKey('inventory-title')), findsOneWidget);
      expect(find.text('Purchase orders'), findsOneWidget);
    });

    testWidgets('Purchasing is hidden without purchase-orders:read', (tester) async {
      await _pumpInventory(tester, denied: {'purchase-orders:read'});
      expect(find.byKey(const ValueKey('inventory-nav-purchasing')), findsNothing);
      expect(find.byKey(const ValueKey('inventory-nav-counts')), findsOneWidget);
    });

    testWidgets('no inventory or purchasing permission shows the web fallback', (tester) async {
      await _pumpInventory(
        tester,
        denied: {'inventory:read', 'purchase-orders:read', 'suppliers:read'},
      );
      expect(find.text("You don't have access to this page"), findsOneWidget);
      expect(find.text('Ask an administrator to grant your role the permission it needs.'), findsOneWidget);
    });
  });

  group('M09 stock', () {
    testWidgets('renders KPIs, panels, item rows, movements and losses', (tester) async {
      await _pumpInventory(tester);
      expect(find.text('ITEMS'), findsOneWidget);
      expect(find.text('On these shelves'), findsOneWidget);
      expect(find.text('NEEDS ORDERING'), findsOneWidget);
      expect(find.text('1,234.50'), findsOneWidget);
      expect(find.text('1 item not costed yet'), findsOneWidget);
      expect(find.text('1 below its level'), findsOneWidget);
      expect(find.text('3 box left · reorder at 5'), findsOneWidget);
      expect(find.text('1 lots'), findsOneWidget);
      expect(find.text('3d left'), findsOneWidget);
      expect(find.textContaining('4 tube · lot L-22 · '), findsOneWidget);
      expect(find.text('Low stock'), findsOneWidget);
      expect(find.text('In stock'), findsOneWidget);
      expect(find.text('Batch tracked'), findsOneWidget);
      expect(find.text('Not costed'), findsOneWidget);
      expect(find.text('PPE · GL-M'), findsOneWidget);
      expect(find.text('reorder at 5'), findsOneWidget);
      expect(find.textContaining('stock out · -2 box'), findsOneWidget);
      expect(find.text('Barrier cream · 1 tube · Past date'), findsOneWidget);
      expect(find.text('Expired'), findsOneWidget);
    });

    testWidgets('the needs-ordering link filters to low stock until Show everything', (tester) async {
      final repo = await _pumpInventory(tester);
      await _tapKey(tester, 'inventory-kpi-low-link');
      expect(find.text('Showing only what is at or below its reorder level.'), findsOneWidget);
      expect(repo.itemQueries.last['lowStock'], isTrue);
      expect(repo.itemQueries.last['limit'], 20);
      await _tapKey(tester, 'inventory-show-everything');
      expect(find.byKey(const ValueKey('inventory-low-banner')), findsNothing);
      expect(repo.itemQueries.last['lowStock'], isFalse);
    });

    testWidgets('Order more opens Purchasing', (tester) async {
      await _pumpInventory(tester);
      await _tapKey(tester, 'inventory-order-more');
      expect(find.text('Purchasing'), findsWidgets);
      expect(find.byKey(const ValueKey('inventory-area-purchasing')), findsOneWidget);
    });

    testWidgets('write actions are gated on inventory:write', (tester) async {
      await _pumpInventory(tester, denied: {'inventory:write'});
      expect(find.byKey(const ValueKey('inventory-add-item')), findsNothing);
      expect(find.byKey(const ValueKey('inventory-open-catalogue')), findsNothing);
      expect(find.byKey(const ValueKey('inventory-item-edit-i1')), findsNothing);
      expect(find.byKey(const ValueKey('inventory-item-delete-i1')), findsNothing);
      expect(find.byKey(const ValueKey('inventory-item-stock-i1')), findsOneWidget);
    });

    testWidgets('Add item validates like the web and posts the web body', (tester) async {
      final repo = await _pumpInventory(tester);
      await _tapKey(tester, 'inventory-add-item');
      expect(find.text('Items belong to one residence and one category.'), findsOneWidget);
      await _tapKey(tester, 'inventory-item-save');
      expect(find.text('A name and a category are required.'), findsOneWidget);
      await _type(tester, 'inventory-item-name', 'Aprons');
      await _pick(tester, 'inventory-item-category', 'PPE');
      expect(find.text('Old stock'), findsNothing);
      await _tapKey(tester, 'inventory-item-save');
      expect(find.text('Choose which residence holds this stock.'), findsOneWidget);
      await _pick(tester, 'inventory-item-residence', 'Elm House');
      await _type(tester, 'inventory-item-quantity', '7');
      await _tapKey(tester, 'inventory-item-save');
      expect(repo.payloads('createItem').single, {
        'name': 'Aprons',
        'categoryId': 'c1',
        'reorderLevel': null,
        'tracksBatches': false,
        'residenceId': 'r1',
        'quantity': 7,
      });
    });

    testWidgets('batch-tracked items start empty', (tester) async {
      await _pumpInventory(tester);
      await _tapKey(tester, 'inventory-add-item');
      await _tapKey(tester, 'inventory-item-batches');
      expect(
        find.text('A batch-tracked item starts empty — record its stock as dated lots once it exists.'),
        findsOneWidget,
      );
      final field = tester.widget<TextField>(_inKey('inventory-item-quantity', find.byType(TextField)));
      expect(field.enabled, isFalse);
      expect(field.controller!.text, '0');
    });

    testWidgets('Move blocks taking out more than the shelf holds', (tester) async {
      final repo = await _pumpInventory(tester);
      await _tapKey(tester, 'inventory-item-stock-i1');
      expect(find.text('Records that stock left or arrived. The quantity changes by this much.'), findsOneWidget);
      await _type(tester, 'inventory-stock-qty', '5');
      expect(find.text('Only 3 box on the shelf.'), findsOneWidget);
      expect(_onPressed(tester, 'inventory-stock-save'), isNull);
      await _type(tester, 'inventory-stock-qty', '2');
      await _tapKey(tester, 'inventory-stock-save');
      expect(repo.payloads('move').single, {'id': 'i1', 'changeQty': -2});
    });

    testWidgets('Recount needs a reason and posts countedQuantity', (tester) async {
      final repo = await _pumpInventory(tester);
      await _tapKey(tester, 'inventory-item-stock-i1');
      await _tapKey(tester, 'inventory-stock-mode-recount');
      await _type(tester, 'inventory-stock-qty', '4');
      await _tapKey(tester, 'inventory-stock-save');
      expect(find.text('Say why the count differs — it goes on the record.'), findsOneWidget);
      await _type(tester, 'inventory-stock-note', 'Miscounted');
      await _tapKey(tester, 'inventory-stock-save');
      expect(repo.payloads('adjust').single, {'id': 'i1', 'countedQuantity': 4, 'reason': 'Miscounted'});
    });

    testWidgets('batch-tracked items cannot be recounted; Loss names the type', (tester) async {
      final repo = await _pumpInventory(tester);
      await _tapKey(tester, 'inventory-item-stock-i2');
      expect(find.byKey(const ValueKey('inventory-stock-mode-recount')), findsNothing);
      await _tapKey(tester, 'inventory-stock-mode-loss');
      expect(find.text('Oldest expiry first'), findsOneWidget);
      await _pick(tester, 'inventory-stock-loss-type', 'Damaged');
      await _type(tester, 'inventory-stock-qty', '2');
      await _tapKey(tester, 'inventory-stock-save');
      expect(repo.payloads('recordLoss').single, {
        'itemId': 'i2',
        'exceptionType': 'damaged',
        'quantity': 2,
      });
    });

    testWidgets('without movement, adjustment or waste the stock sheet refuses', (tester) async {
      await _pumpInventory(
        tester,
        denied: {'inventory:movement', 'inventory:adjustment', 'inventory:waste'},
      );
      await _tapKey(tester, 'inventory-item-stock-i1');
      expect(find.text('You cannot change stock'), findsOneWidget);
    });

    testWidgets('delete asks first, then removes the item', (tester) async {
      final repo = await _pumpInventory(tester);
      await _tapKey(tester, 'inventory-item-delete-i1');
      expect(find.text('Delete this item?'), findsOneWidget);
      await _tapKey(tester, 'inventory-confirm');
      expect(repo.payloads('deleteItem').single, 'i1');
    });

    testWidgets('item detail shows lots, history, cost trend and suppliers', (tester) async {
      final repo = await _pumpInventory(tester);
      await _tapKey(tester, 'inventory-item-open-i2');
      expect(find.text('12 tube on hand · PPE'), findsOneWidget);
      expect(find.text('5 tube · lot L-9'), findsOneWidget);
      expect(find.text('40d left'), findsOneWidget);
      expect(find.text('Count adjustment · Found box'), findsOneWidget);
      expect(find.text('10 → 12'), findsOneWidget);
      expect(find.text('+2 tube'), findsOneWidget);
      expect(find.text('Up 0.50 since the delivery before'), findsOneWidget);
      expect(find.text('3.00 each'), findsOneWidget);
      expect(find.text('Preferred'), findsOneWidget);
      expect(find.text('3 each · their code MS-1 · 2d lead'), findsOneWidget);

      await _tapKey(tester, 'inventory-record-lot');
      await _type(tester, 'inventory-lot-qty', '6');
      await _tapKey(tester, 'inventory-lot-save');
      expect(repo.payloads('addBatch').single, {'itemId': 'i2', 'quantity': 6});
    });

    testWidgets('categories and units: retired ones hide until asked, adding works', (tester) async {
      final repo = await _pumpInventory(tester);
      await _tapKey(tester, 'inventory-open-catalogue');
      expect(find.text('Categories and units'), findsOneWidget);
      expect(find.text('Old stock'), findsNothing);
      await _tapKey(tester, 'inventory-catalogue-retired');
      expect(find.text('Old stock'), findsOneWidget);
      expect(find.text('Retired'), findsOneWidget);
      await _type(tester, 'inventory-category-new', 'Continence');
      await _tapKey(tester, 'inventory-category-add');
      expect(repo.payloads('createCategory').single, 'Continence');
      await _tapKey(tester, 'inventory-catalogue-archive-c1');
      expect(repo.payloads('archiveCategory').single, {'id': 'c1', 'archive': true});
    });
  });

  group('M09 stock counts', () {
    testWidgets('lists counts and runs the count sheet', (tester) async {
      final repo = await _pumpInventory(tester, area: InventoryArea.counts);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('View'), findsOneWidget);
      expect(find.text('None'), findsOneWidget);

      await _tapKey(tester, 'count-start');
      await _tapKey(tester, 'count-open');
      expect(find.text('Choose which residence is being counted.'), findsOneWidget);
      await _pick(tester, 'count-residence', 'Elm House');
      await _tapKey(tester, 'count-open');
      expect(repo.payloads('openStockCount').single, 'r1');

      expect(find.text('Count · Elm House'), findsOneWidget);
      expect(find.text('0 of 2 counted'), findsOneWidget);
      expect(find.text('Lot L-9 · expires 2027-03-01 · Record says 5 tube'), findsOneWidget);
      await _type(tester, 'count-input-cl1', '3');
      expect(find.text('Matches'), findsOneWidget);
      expect(find.text('1 of 2 counted · everything matches so far'), findsOneWidget);
      await _type(tester, 'count-input-cl2', '4');
      expect(find.text('-1'), findsOneWidget);
      expect(find.text('2 of 2 counted · 1 difference'), findsOneWidget);
      await _tapKey(tester, 'count-filter-differences');
      expect(find.byKey(const ValueKey('count-line-cl1')), findsNothing);

      await _tapKey(tester, 'count-save');
      expect(repo.payloads('saveCountLines').single, [
        {'lineId': 'cl1', 'countedQty': 3},
        {'lineId': 'cl2', 'countedQty': 4},
      ]);
      await _tapKey(tester, 'count-submit');
      expect(repo.payloads('submitCount').single, 'k1');
      expect(find.text('Count · Elm House'), findsNothing);
    });

    testWidgets('without inventory:adjustment counts are read-only', (tester) async {
      await _pumpInventory(tester, area: InventoryArea.counts, denied: {'inventory:adjustment'});
      expect(find.byKey(const ValueKey('count-start')), findsNothing);
      expect(find.byKey(const ValueKey('count-cancel-k1')), findsNothing);
      await _tapKey(tester, 'count-open-k1');
      expect(_inKey('count-line-cl1', find.text('Not counted')), findsOneWidget);
      expect(_inKey('count-line-cl2', find.text('Not counted')), findsOneWidget);
      expect(find.byKey(const ValueKey('count-input-cl1')), findsNothing);
      expect(find.byKey(const ValueKey('count-submit')), findsNothing);
    });
  });

  group('M09 transfers', () {
    testWidgets('cards show line progress and permitted steps', (tester) async {
      final repo = await _pumpInventory(tester, area: InventoryArea.transfers);
      expect(find.text('Elm House → Oak Lodge'), findsNWidgets(2));
      expect(find.text('1 product · Short until Thursday'), findsOneWidget);
      expect(find.text('2 requested'), findsOneWidget);
      expect(find.text('4 sent of 4'), findsOneWidget);
      expect(find.text('3 arrived of 5 sent · 2 unaccounted for'), findsOneWidget);
      expect(find.byKey(const ValueKey('transfer-cancel-t1')), findsOneWidget);
      expect(find.byKey(const ValueKey('transfer-cancel-t2')), findsNothing);
      await _tapKey(tester, 'transfer-approve-t1');
      expect(repo.payloads('approveTransfer').single, 't1');
    });

    testWidgets('steps follow their own permissions', (tester) async {
      await _pumpInventory(
        tester,
        area: InventoryArea.transfers,
        denied: {'inventory:transfer:approve', 'inventory:transfer:receive', 'inventory:transfer:request'},
      );
      expect(find.byKey(const ValueKey('transfer-approve-t1')), findsNothing);
      expect(find.byKey(const ValueKey('transfer-receive-t2')), findsNothing);
      expect(find.byKey(const ValueKey('transfer-cancel-t1')), findsNothing);
      expect(find.byKey(const ValueKey('transfer-new')), findsNothing);
    });

    testWidgets('receiving short needs a reason', (tester) async {
      final repo = await _pumpInventory(tester, area: InventoryArea.transfers);
      await _tapKey(tester, 'transfer-receive-t2');
      expect(find.text('What turned up'), findsOneWidget);
      expect(find.text('4 requested · 4 left the other house'), findsOneWidget);
      await _type(tester, 'transfer-step-qty-tl2', '3');
      expect(find.text('1 short'), findsOneWidget);
      await _tapKey(tester, 'transfer-step-save');
      expect(find.text('Barrier cream: 1 did not arrive — say what happened to it.'), findsOneWidget);
      await _pick(tester, 'transfer-short-reason-tl2', 'Missing from the parcel');
      await _tapKey(tester, 'transfer-step-save');
      expect(repo.payloads('receiveTransfer').single, [
        {'lineId': 'tl2', 'receivedQuantity': 3, 'shortfallReason': 'missing'},
      ]);
    });

    testWidgets('requesting a transfer validates houses, products and stock', (tester) async {
      final repo = await _pumpInventory(tester, area: InventoryArea.transfers);
      await _tapKey(tester, 'transfer-new');
      await _tapKey(tester, 'transfer-request-save');
      expect(find.text('Choose which house it leaves and which it goes to.'), findsOneWidget);
      await _pick(tester, 'transfer-from', 'Elm House');
      await _pick(tester, 'transfer-to', 'Oak Lodge');
      await _tapKey(tester, 'transfer-request-save');
      expect(find.text('Add at least one product.'), findsOneWidget);
      // Choosing the sending house starts a fresh product list.
      await _pick(tester, 'transfer-item-1', 'Nitrile gloves — 3 box on hand');
      await _type(tester, 'transfer-qty-1', '9');
      expect(find.text('Only 3 on hand'), findsOneWidget);
      await _tapKey(tester, 'transfer-request-save');
      expect(find.text('Only 3 box of Nitrile gloves on that shelf.'), findsOneWidget);
      await _type(tester, 'transfer-qty-1', '2');
      await _tapKey(tester, 'transfer-request-save');
      expect(repo.payloads('createTransfer').single, {
        'fromResidenceId': 'r1',
        'toResidenceId': 'r2',
        'lines': [
          {'fromItemId': 'i1', 'quantity': 2},
        ],
      });
    });
  });

  group('M09 purchasing', () {
    testWidgets('order cards show value, arrivals and status-gated actions', (tester) async {
      final repo = await _pumpInventory(tester, area: InventoryArea.purchasing);
      expect(find.text('No supplier'), findsOneWidget);
      expect(find.text('PO-0001 · 1 product'), findsOneWidget);
      expect(find.text('20.00'), findsOneWidget);
      expect(find.text('Not priced'), findsNWidgets(2));
      expect(find.text('5 of 9'), findsOneWidget);
      expect(find.text('Pending approval'), findsOneWidget);
      expect(_onPressed(tester, 'order-submit-o1'), isNull);
      expect(find.byKey(const ValueKey('order-edit-o1')), findsOneWidget);
      expect(find.byKey(const ValueKey('order-edit-o2')), findsNothing);
      expect(find.byKey(const ValueKey('order-receive-o3')), findsOneWidget);
      await _tapKey(tester, 'order-request-approval-o1');
      expect(repo.payloads('requestOrderApproval').single, 'o1');
      await _tapKey(tester, 'order-approve-o2');
      expect(repo.payloads('approveOrder').single, 'o2');
    });

    testWidgets('approve/receive buttons follow their permissions', (tester) async {
      await _pumpInventory(
        tester,
        area: InventoryArea.purchasing,
        denied: {'purchase-orders:approve', 'purchase-orders:receive', 'purchase-orders:write'},
      );
      expect(find.byKey(const ValueKey('order-approve-o2')), findsNothing);
      expect(find.byKey(const ValueKey('order-receive-o3')), findsNothing);
      expect(find.byKey(const ValueKey('order-new')), findsNothing);
      expect(find.byKey(const ValueKey('order-cancel-o1')), findsNothing);
    });

    testWidgets('rejecting needs a reason', (tester) async {
      final repo = await _pumpInventory(tester, area: InventoryArea.purchasing);
      await _tapKey(tester, 'order-reject-o2');
      expect(find.text('From MedSupply'), findsOneWidget);
      await _tapKey(tester, 'order-reject-save');
      expect(find.text('Say why this order is rejected.'), findsOneWidget);
      await _type(tester, 'order-reject-reason', 'Too expensive');
      await _tapKey(tester, 'order-reject-save');
      expect(repo.payloads('rejectOrder').single, {'id': 'o2', 'reason': 'Too expensive'});
    });

    testWidgets('booking in caps each line at what is outstanding', (tester) async {
      final repo = await _pumpInventory(tester, area: InventoryArea.purchasing);
      await _tapKey(tester, 'order-receive-o3');
      expect(find.text('6 ordered · 2 already in · 4 still to come (tube)'), findsOneWidget);
      expect(find.text('Restocks Barrier cream'), findsOneWidget);
      expect(find.text('One-off — no stock change'), findsOneWidget);
      final closed = tester.widget<TextField>(_inKey('order-receive-qty-ol4', find.byType(TextField)));
      expect(closed.enabled, isFalse);
      await _type(tester, 'order-receive-qty-ol3', '5');
      await _tapKey(tester, 'order-receive-save');
      expect(find.text('More Cream arrived than was outstanding (4).'), findsOneWidget);
      await _type(tester, 'order-receive-qty-ol3', '4');
      await _tapKey(tester, 'order-receive-save');
      expect(repo.payloads('receiveOrder').single, {
        'id': 'o3',
        'items': [
          {'itemId': 'ol3', 'receivedQuantity': 4},
        ],
      });
    });

    testWidgets('new order picks shelf stock and posts the draft', (tester) async {
      final repo = await _pumpInventory(tester, area: InventoryArea.purchasing);
      await _tapKey(tester, 'order-new');
      await _tapKey(tester, 'order-save');
      expect(find.text('Choose which house this is for.'), findsOneWidget);
      await _pick(tester, 'order-residence', 'Elm House');
      await _tapKey(tester, 'order-save');
      expect(find.text('Add at least one product.'), findsOneWidget);

      await _tapKey(tester, 'order-line-pick-0');
      await _tapKey(tester, 'order-stock-option-i1');
      expect(find.text("The delivery will be added to this item's stock."), findsOneWidget);
      expect(find.text('Last paid 2.75'), findsOneWidget);
      await _type(tester, 'order-line-qty-0', '0');
      await _tapKey(tester, 'order-save');
      expect(find.text('How many Nitrile gloves? It has to be more than zero.'), findsOneWidget);
      await _type(tester, 'order-line-qty-0', '4');
      expect(find.text('Order total 11.00'), findsOneWidget);
      await _tapKey(tester, 'order-save');
      expect(repo.payloads('createOrder').single, {
        'residenceId': 'r1',
        'items': [
          {
            'inventoryItemId': 'i1',
            'description': 'Nitrile gloves',
            'quantity': 4,
            'unit': 'box',
            'unitCost': 2.75,
          },
        ],
      });
    });

    testWidgets('suppliers tab: remove / restore need suppliers:write', (tester) async {
      final repo = await _pumpInventory(tester, area: InventoryArea.purchasing);
      await _tapKey(tester, 'purchasing-tab-suppliers');
      expect(find.text('orders@med.test'), findsOneWidget);
      expect(find.text('Pharmacy'), findsOneWidget);
      await _tapKey(tester, 'supplier-remove-s1');
      expect(repo.payloads('removeSupplier').single, 's1');
      await _tapKey(tester, 'supplier-restore-s2');
      expect(repo.payloads('restoreSupplier').single, 's2');
      await _tapKey(tester, 'supplier-new');
      await _tapKey(tester, 'supplier-add-save');
      expect(find.text('A name is required.'), findsOneWidget);
    });

    testWidgets('residence manager without suppliers:write cannot change suppliers', (tester) async {
      await _pumpInventory(tester, area: InventoryArea.purchasing, denied: {'suppliers:write'});
      await _tapKey(tester, 'purchasing-tab-suppliers');
      expect(find.byKey(const ValueKey('supplier-new')), findsNothing);
      expect(find.byKey(const ValueKey('supplier-remove-s1')), findsNothing);
    });
  });
}
