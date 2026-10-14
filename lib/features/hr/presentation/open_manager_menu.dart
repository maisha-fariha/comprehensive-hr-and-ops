import 'package:get/get.dart';

import '../hr_shell.dart';

/// Opens the manager More tab — the navigation menu behind each module hamburger.
void openManagerMenu() => Get.offAll(() => const HrShell(initialIndex: 4));
