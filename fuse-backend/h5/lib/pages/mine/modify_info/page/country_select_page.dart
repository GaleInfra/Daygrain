import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/language/bh_language_manager.dart';

import 'package:untitled1/pages/broadcaster/widget/country_picker.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/widget/app_bar/default_app_bar.dart';
import 'package:untitled1/widget/gradient_backgrond_widget.dart';

class CountrySelectPage extends StatefulWidget {
  
  const CountrySelectPage({Key? key}) : super(key: key);

  @override
  State<CountrySelectPage> createState() => _CountrySelectPageState();
}

class _CountrySelectPageState extends State<CountrySelectPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> allCountries = [];
  List<dynamic> filteredCountries = [];
  String selectName = "";
  String selectIcon = "";
  String currentCountry = "";
  @override
  void initState() {
    super.initState();
    _initCountries();

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initCountries() async {

    currentCountry = Get.arguments ?? "";
    // 获取国家列表数据
    var countryList = await loadCountryList();
    // 过滤掉中国
    allCountries = countryList.where((country) => 
        country["code"] != 'CN').toList();

    for (var country in allCountries) {
      if (country["name"] == currentCountry) {
        selectName = country["name"];
        selectIcon = country["emoji"];
        break;
      }
    }

    filteredCountries = List.from(allCountries);
    
    // 如果有当前选中的国家，将其移到列表顶部
    if (currentCountry.isNotEmpty) {
      _moveSelectedCountryToTop();
    }
    
    setState(() {});
  }
  
  void _moveSelectedCountryToTop() {
    int index = filteredCountries.indexWhere((country) => 
        country["code"] == currentCountry ||
        country["name"].toString().startsWith(currentCountry));
    
    if (index != -1) {
      Map<String, dynamic> selected = filteredCountries[index];
      filteredCountries.removeAt(index);
      filteredCountries.insert(0, selected);
    }
  }
  
  void _onSearchChanged() {
    String query = _searchController.text.toLowerCase();
    
    if (query.isEmpty) {
      filteredCountries = List.from(allCountries);
    } else {
      filteredCountries = allCountries
          .where((country) => 
            country["name"].toString().toLowerCase().contains(query))
          .toList();
    }
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackgroundWidget(
      child: Scaffold(
        appBar: DefaultAppBar(
          title: selectName.isEmpty ? currentCountry : "$selectIcon $selectName",
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: MyColor.rechargeItemBG,
              size: 10.sp,
            ),
            onPressed: () => Get.back(),
          ),
        ),
        body: Container(
          margin: EdgeInsets.only(top: 5.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20.r), topRight: Radius.circular(20.r)),
              gradient: const LinearGradient(
                colors: [
                  Color(0xff7C2FB1),
                  Color(0xff755AFC),
                  Color(0xff6182F8),
                  Color(0xff3EBDFC),
                  Color(0xff01FFD1)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
          ),
          child: Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: _buildCountryList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.all(8.w),
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      height: 26.h,
      decoration: BoxDecoration(
        color: const Color(0xff5F5F5F),
        borderRadius: BorderRadius.circular(13.r),
      ),
      child: Row(
        children: [
          Image.asset(ImageAssets.minesearch, width: 10.5.w, height: 10.w),
          SizedBox(width: 5.w),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: MyColor.white, fontSize: 8.sp),
              cursorColor: MyColor.white,
              decoration: InputDecoration(
                hintText: "Search for your country".bhTR,
                hintStyle: TextStyle(
                  color: const Color(0xffB4B4B4),
                  fontSize: 8.sp,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryList() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xffFAEE47).withOpacity(0.5),
            const Color(0xff1DFDEB).withOpacity(0.5),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(6.5.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: ListView.separated(
          itemCount: filteredCountries.length,
          separatorBuilder: (context, index) => SizedBox(height: 4.h),
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Get.back(result: filteredCountries[index]);
              },
              child: _buildCountryCell(filteredCountries[index]),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildCountryCell(Map<String, dynamic> country) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff191919),
        borderRadius: BorderRadius.circular(6.r),
      ),
      padding: EdgeInsets.symmetric(vertical: 3.h, horizontal: 8.w),
      child: Row(
        children: [
          Text(
            country["emoji"] ?? '',
            style: TextStyle(fontSize: 12.sp),
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              country["name"] ?? '',
              style: TextStyle(
                color: MyColor.white,
                fontSize: 7.5.sp,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
} 