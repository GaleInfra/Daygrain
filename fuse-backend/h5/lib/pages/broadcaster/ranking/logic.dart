import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/ranking/rank_cp_model.dart';
import 'package:untitled1/model/ranking/ranking_model.dart';

class RankingLogic extends GetxController
    with GetSingleTickerProviderStateMixin {
  late TabController tabController;
  final RxInt index = 0.obs;
  final RxBool requestSuccess = false.obs;
  final tagList = ["label_charm".bhTR, "label_rich".bhTR, "label_couples".bhTR];
  List<RankingModel> charmList = [];
  List<RankingModel> richList = [];
  List<RankData> couplesList = [];
  @override
  void onInit() {
    tabController = TabController(length: 3,animationDuration: Duration.zero, vsync: this);
    tabController.animation?.addListener(_onTabChange);

    super.onInit();
  }

  @override
  void onClose() {
    tabController.animation?.removeListener(_onTabChange);
    super.onClose();
  }

  void _onTabChange() {
    int i = (tabController.animation?.value ?? 0).round();
    if (i != index.value) {
      index.trigger(i);
    }
  }
}
