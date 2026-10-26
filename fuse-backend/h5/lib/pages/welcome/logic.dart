import 'package:untitled1/base/get_base_controller.dart';
import 'package:untitled1/base_manager.dart';
import 'package:untitled1/res/my_keys.dart';
import 'package:untitled1/utils/assets_loading_manager.dart';
import 'package:untitled1/utils/bh_platform.dart';
import 'package:untitled1/utils/sp_util.dart';

class WelcomeLogic extends GetBaseController {
  @override
  void onReady() async {
    if (BHPlatform.isWeb) {
      AssetsLoadingManager.instance.init(null);
    }
    BaseManager.instance.armWelcomeSafetyTimeout();
    if (SPUtil.containsKey(MyKeys.token)) {
      await BaseManager.instance.handleOnOpen();
    } else {
      await BaseManager.instance.login();
    }
    super.onReady();
  }
}
