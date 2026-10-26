import 'package:untitled1/js/rc_manager_js.dart';
import 'package:untitled1/utils/bh_platform.dart';

/// Web hosts without a StoreKit bridge must not take the GP/IAP shortcut, or loading never ends.
bool hasNativePayBridge() {
  if (!BHPlatform.isWeb) return true;
  try {
    return JSRongCloudManager.hasNativePayBridge();
  } catch (_) {
    return false;
  }
}

bool isNativePayChannel(String? name) => name == "GP" || name == "IAP";
