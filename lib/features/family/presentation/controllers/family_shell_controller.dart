import 'package:get/get.dart';

/// Keeps Family bottom-nav index without remounting the shell via `Get.offAll`.
///
/// Overview / Journal quick links must call [goTo] instead of replacing the
/// route — pull-to-refresh under those cards was otherwise firing a full
/// shell remount that looked like an auto-redirect.
class FamilyShellController extends GetxController {
  FamilyShellController({int initialIndex = 0})
      : currentIndex = initialIndex.clamp(0, 4).obs;

  final RxInt currentIndex;

  void goTo(int index) {
    final next = index.clamp(0, 4);
    if (currentIndex.value == next) return;
    currentIndex.value = next;
  }
}
