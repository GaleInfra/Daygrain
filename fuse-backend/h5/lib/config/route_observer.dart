import 'package:flutter/cupertino.dart';
import 'package:untitled1/utils/dialog_util.dart';
import 'package:untitled1/utils/permission_util.dart';

final AppRouteObserver<Route> routeObserver = AppRouteObserver();

class AppRouteObserver<R extends Route<dynamic>> extends RouteObserver<R> {
  //记录路由
  List<Route> routes = [];
  @override
  void didPush(Route route, Route? previousRoute) {
    _closePermission();
    routes.add(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _closePermission();
    routes.remove(route);
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    _closePermission();
    routes.remove(route);
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    _closePermission();
    if (oldRoute != null) routes.remove(oldRoute);
    if (newRoute != null) routes.add(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  void _closePermission() {
    if (kShowPermission) {
      DialogUtil.dismiss(tag: 'Permission');
    }
  }
}
