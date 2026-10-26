import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/utils/throttle_util.dart';

import '../../../base_manager.dart';

Future showCountryPicker({
  required BuildContext targetContext,
  required String initCode,
  required Function(String code, String emoji) onSelect,
}) async {
  //加入防抖
  throttleUtil.throttle(() async {
    try {
      List<Map<String, dynamic>> countryList = [];
      countryList.add({"name": "All", "code": "All", "emoji": ""});
      final list = await loadCountryList();
      final AppConfigManager configManager = Get.find<AppConfigManager>();
      for (var regions in (configManager.strategyModel?.broadcasterWallRegions ?? <String>[])) {
        int index = list.indexWhere((element) => element['code'] == regions);
        if (index != -1) {
          countryList.add(list[index]);
        }
      }
      if (initCode.isEmpty) {
        initCode = "All";
      }
      throttleUtil.cancel("showCountryPicker");
      await SmartDialog.showAttach(
        targetContext: targetContext,
        maskColor: Colors.transparent,
        bindWidget: targetContext,
        tag: "CountryPicker",
        builder: (_) {
          return _CountryPicker(
            initCode: initCode,
            onSelect: onSelect,
            countryList: countryList,
          );
        },
      );
    } catch (e) {
      throttleUtil.cancel("showCountryPicker");
    }
  }, time: 10000, key: "showCountryPicker");
}

List<dynamic> _all_country_list = [];
//加载国家文件
Future<List<dynamic>> loadCountryList() async {
  if (_all_country_list.isNotEmpty) {
    return _all_country_list;
  }
  String jsonString = await rootBundle.loadString('${BaseManager.instance.assetsPrefix}assets/json/country.json');
  _all_country_list = jsonDecode(jsonString) as List;
  return _all_country_list;
}

Future dismissCountryPicker() => SmartDialog.dismiss(status: SmartStatus.attach, tag: "CountryPicker");

/// create: 2024/1/12
/// desc: 主播墙国家选择
class _CountryPicker extends StatefulWidget {
  final List<Map<String, dynamic>> countryList;
  const _CountryPicker({
    required this.initCode,
    required this.onSelect,
    required this.countryList,
  });

  // 初始选中国家code
  final String initCode;

  // 选中回调
  final Function(String code, String emoji) onSelect;

  @override
  State<_CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<_CountryPicker> {
  // 当前选择的国家code
  String selectCode = "";

  @override
  void initState() {
    selectCode = widget.initCode;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.w),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6.w),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(6.w),
              ),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 5.w),
                child: Wrap(
                  runSpacing: 6.w,
                  spacing: 6.w,
                  children: [
                    for (var map in widget.countryList) ...{
                      _item(map),
                    }
                  ],
                ),
              )
              ,
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(Map<String, dynamic> data) {
    bool isAll = true;
    String text = "${data['name']}";
    if ("All" != data['name']) {
      isAll = false;
      text = "${data['emoji']} $text";
    }
    bool select = selectCode == data['code'];
    return GestureDetector(
      onTap: () {
        selectCode = data['code'];
        setState(() {});
        dismissCountryPicker();
        widget.onSelect.call(selectCode, data['emoji']);
      },
      child: Container(
        padding: isAll ? EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.w) : EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          gradient: select
              ?  LinearGradient(
                  colors: MyColor.btnGradientColors,
                  begin: BHLanguageMar().isRightToLeft.value ? Alignment.centerRight : Alignment.centerLeft ,
                  end: BHLanguageMar().isRightToLeft.value ? Alignment.centerLeft : Alignment.centerRight,
                )
              : null,
          color: select ? null : Colors.white,
          borderRadius: BorderRadius.circular(14.w),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 6.sp,
                //fontStyle: FontStyle.italic, // 添加字体倾斜效果
                // fontWeight: FontWeight.bold, // 可选：添加粗体效果使文字更突出
                color: select ? Colors.white : MyColor.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundedContainerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black.withOpacity(.8)
      ..style = PaintingStyle.fill;

    // 绘制圆角矩形
    RRect rRect = RRect.fromLTRBR(7.w, 10.h, size.width - 7.w, size.height - 10.h, Radius.circular(10.r));
    canvas.drawRRect(rRect, paint);

    // 绘制三角形
    Path path = Path();
    if (BHLanguageMar().isRightToLeft.value) {
      path.moveTo(45.w, 10.h);
      path.lineTo(25.w, 10.h);
      path.lineTo(35.w, 0);
    } else {
      path.moveTo(size.width - 45.w, 10.h);
      path.lineTo(size.width - 25.w, 10.h);
      path.lineTo(size.width - 35.w, 0);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
