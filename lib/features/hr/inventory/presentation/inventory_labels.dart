import '../../attendance/presentation/widgets/attendance_record_card.dart';
import '../domain/entities/inventory_item.dart';

/// Labels, pill tones and number / date formatting shared by the
/// Inventory screens, copied from the web.
abstract final class InventoryLabels {
  static const Map<String, String> movementTypes = {
    'stock_in': 'Stock in',
    'stock_out': 'Stock out',
    'adjustment': 'Count adjustment',
    'waste': 'Waste',
    'damaged': 'Damaged',
    'expired': 'Expired',
    'lost': 'Lost',
    'purchase_received': 'Purchase received',
    'transfer_out': 'Transferred out',
    'transfer_in': 'Transferred in',
    'batch_added': 'Lot recorded',
  };

  static String movement(String type) => movementTypes[type] ?? humanise(type);

  static const List<(String, String)> lossKinds = [
    ('waste', 'Wasted'),
    ('damaged', 'Damaged'),
    ('expired', 'Expired'),
    ('lost', 'Lost'),
  ];

  static AttendanceTone lossTone(String type) => switch (type) {
        'waste' || 'expired' => AttendanceTone.warning,
        'damaged' || 'lost' => AttendanceTone.danger,
        _ => AttendanceTone.neutral,
      };

  static String stockLabel(InventoryStockState state) => switch (state) {
        InventoryStockState.out => 'Out of stock',
        InventoryStockState.low => 'Low stock',
        InventoryStockState.ok => 'In stock',
      };

  static AttendanceTone stockTone(InventoryStockState state) => switch (state) {
        InventoryStockState.out => AttendanceTone.danger,
        InventoryStockState.low => AttendanceTone.warning,
        InventoryStockState.ok => AttendanceTone.success,
      };

  static AttendanceTone countTone(String status) => switch (status) {
        'draft' => AttendanceTone.warning,
        'submitted' || 'completed' => AttendanceTone.success,
        _ => AttendanceTone.neutral,
      };

  static AttendanceTone transferTone(String status) => switch (status) {
        'requested' => AttendanceTone.warning,
        'approved' || 'partially_dispatched' || 'dispatched' => AttendanceTone.info,
        'received' || 'completed' => AttendanceTone.success,
        _ => AttendanceTone.neutral,
      };

  static const Map<String, String> transferSteps = {
    'approve': 'Approve',
    'dispatch': 'Dispatch',
    'receive': 'Mark received',
  };

  static const List<(String, String)> shortfallReasons = [
    ('damaged', 'Broken in transit'),
    ('missing', 'Missing from the parcel'),
    ('leaked', 'Leaked or spoiled'),
    ('other', 'Something else'),
  ];

  static AttendanceTone orderTone(String status) => switch (status) {
        'submitted' || 'approved' => AttendanceTone.info,
        'pending_approval' || 'partially_received' => AttendanceTone.warning,
        'received' => AttendanceTone.success,
        _ => AttendanceTone.neutral,
      };

  static const List<(String, String)> supplierCategories = [
    ('general', 'General'),
    ('pharmacy', 'Pharmacy'),
    ('grocery', 'Grocery'),
    ('other', 'Other'),
  ];

  /// Web `humanise`: `partially_received` -> `Partially received`.
  static String humanise(String? value) {
    if (value == null || value.isEmpty) return '—';
    final text = value.replaceAll(RegExp(r'[_-]+'), ' ');
    return text[0].toUpperCase() + text.substring(1);
  }

  /// JavaScript `String(number)`: whole numbers without a decimal point.
  static String qty(num? value) {
    if (value == null) return '0';
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toString();
  }

  /// `toFixed(2)`.
  static String fixed2(num value) => value.toStringAsFixed(2);

  /// `toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})`.
  static String money(num value) {
    final fixed = value.abs().toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts.first;
    final grouped = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) grouped.write(',');
      grouped.write(whole[i]);
    }
    return '${value < 0 ? '-' : ''}$grouped.${parts.last}';
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  /// Tenant default `DD/MM/YYYY`.
  static String date(DateTime? value) {
    if (value == null) return '—';
    final d = value.toLocal();
    return '${_two(d.day)}/${_two(d.month)}/${d.year}';
  }

  static String time(DateTime value) {
    final d = value.toLocal();
    return '${_two(d.hour)}:${_two(d.minute)}';
  }

  static String dateTime(DateTime? value) =>
      value == null ? '—' : '${date(value)} ${time(value)}';

  /// Web `formatShort`: the time for today, the date otherwise.
  static String short(DateTime? value, {DateTime? now}) {
    if (value == null) return '';
    final d = value.toLocal();
    final today = (now ?? DateTime.now()).toLocal();
    final sameDay = d.year == today.year && d.month == today.month && d.day == today.day;
    return sameDay ? time(d) : date(d);
  }

  /// `YYYY-MM-DD` of an ISO string.
  static String day(String raw) => raw.length >= 10 ? raw.substring(0, 10) : raw;

  /// `n item` / `n items`.
  static String plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';
}
