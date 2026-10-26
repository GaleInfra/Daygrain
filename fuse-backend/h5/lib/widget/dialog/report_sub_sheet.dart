import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/net/request_repository.dart';
import 'package:untitled1/utils/dialog_util.dart';
import 'package:untitled1/widget/dialog/confirm_dialog.dart';

import '../../res/my_color.dart';
import '../../utils/toast.dart';
import 'sheet_item.dart';

/// create: 2023/4/26
/// desc: 举报二级弹窗
class ReportSubSheet extends StatelessWidget {
  ReportSubSheet({
    Key? key,
    required this.userId,
  }) : super(key: key);

  ReportSubSheet.show({
    super.key,
    required this.userId,
    BuildContext? bindWidget,
  }) {
    DialogUtil.showDialog(
      alignment: Alignment.bottomCenter,
      bindWidget: bindWidget,
      bindPage: false,
      child: this,
    );
  }

  /// 用户id
  final String userId;

  /// 获取仓库
  final request = Get.find<RequestRepository>();

  @override
  Widget build(BuildContext context) {
    Container gap = Container(
      width: double.infinity,
      height: 1,
      color: MyColor.black.withOpacity(0.2),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BottomDialogBgWidget(
          child: Container(
            child: Column(
              children: [
                SheetItem(
                  title: "report_reason_pornography".bhTR,
                  onTap: () {
                    onReport(reason: "Pornographic");
                    DialogUtil.dismiss();
                  },
                ),
                gap,
                SheetItem(
                  title: "report_reason_falseGender".bhTR,
                  onTap: () {
                    onReport(reason: "False gender");
                    DialogUtil.dismiss();
                  },
                ),
                gap,
                SheetItem(
                  title: "report_reason_fraud".bhTR,
                  onTap: () {
                    onReport(reason: "Fraud");
                    DialogUtil.dismiss();
                  },
                ),
                gap,
                SheetItem(
                  title: "report_reason_politicalContent".bhTR,
                  onTap: () {
                    onReport(reason: "Political sensitive");
                    DialogUtil.dismiss();
                  },
                ),
                gap,
                SheetItem(
                  title: "report_reason_other".bhTR,
                  onTap: () {
                    onReport(reason: "Other");
                    DialogUtil.dismiss();
                  },
                ),
                gap,
                GestureDetector(
                  onTap: () => DialogUtil.dismiss(),
                  behavior: HitTestBehavior.translucent,
                  child: Container(
                    height: 23.w,
                    margin: EdgeInsets.symmetric(horizontal: 6.w,vertical: 5.w),
                    padding: EdgeInsets.symmetric(horizontal: 6.w),

                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(11.5.w),
                        gradient: const LinearGradient(
                            colors: MyColor.btnGradientColors)
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "action_cancel".bhTR,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                      TextStyle(
                        fontWeight: FontWeight.bold,
                        color: MyColor.white,
                        fontSize: 8.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 举报
  Future onReport({
    required String reason,
  }) async {
    await request.reportInsertRecord(
      userId: userId,
      complainCategory: "Report",
      complainSub: reason,
      onSuccess: (data) {
        Toast.showMsg("status_reportSuccessful".bhTR);
      },
      onFail: (code, msg) {},
    );
  }
}
