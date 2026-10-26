import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/utils/assets_handle.dart';
import 'package:untitled1/widget/image/my_extended_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
// 重新定义Image 类 ，保持原有功能，只是添加了一个 storong参数

class StrongImage {
  // static final Map<String, AssetImage> _imageCache = {};
  static final RequestQueueManager _requestQueueManager = RequestQueueManager();
  static CachedNetworkImage asset(
    String name, {
    Key? key,
    double? scale,
    double? width,
    double? height,
    BoxFit? fit,
    Color? color,
  }) {
    return CachedNetworkImage(
      // key: ValueKey("my_extended_network_image_$url"),
      imageUrl: AssetsHandle.instance.getPassiveAssetsDomain(name),
      width: width,
      height: height,
      fit: fit,
      fadeOutDuration: Duration.zero,
      fadeInDuration: Duration.zero,

      imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
      // memCacheWidth: memCacheWidth,
    );

    // return Image(
    //   key: key,
    //   image: assetImage,
    //   fit: fit,
    //   width: width,
    //   height: height,
    //   color: color,

    // );
  }

// 默认缓存管理器（与CachedNetworkImage共用）
  static final BaseCacheManager cacheManager = DefaultCacheManager();

  /// 预缓存单张图片
  /// [url] 图片网络地址
  /// 返回值：是否缓存成功
  static Future<bool> _precacheImage(String url) async {
    
    try {
      // 检查是否已缓存
      final fileInfo = await cacheManager.getFileFromCache(url);
      if (fileInfo != null && fileInfo.file.existsSync()) {
        // 已缓存，无需重复操作
        return true;
      }

      final completer = Completer<bool>();
      try {
        _requestQueueManager.addRequest(RequestTask(
          taskId: url,
          requestFunction: () {
            return cacheManager.downloadFile(url);
          },
          onError: (error) {
            completer.complete(false);
          },
          onSuccess: (result) {
            completer.complete(true);
          },
        ));
        return completer.future;
      } catch (e) {
        return false;
      }
    } catch (e) {
      print('图片预缓存失败：$url，错误：$e');
      return false;
    }
  }

  static Future<void> precacheImagesAssets(List<String> urls) async {
    for (final url in urls) {
      final passiveAssetsDomain =
          AssetsHandle.instance.getPassiveAssetsDomain(url);
      await _precacheImage(passiveAssetsDomain);
    }
  }

  /// 预缓存单张图片
  /// [url] 图片网络地址
  /// 返回值：是否缓存成功
  static Future<bool> precacheImageAssets(String url) async {
    final passiveAssetsDomain =
        AssetsHandle.instance.getPassiveAssetsDomain(url);
    return await _precacheImage(passiveAssetsDomain);
  }

  /// 预缓存多张图片
  /// [urls] 图片网络地址列表
  /// 返回值：全部缓存成功返回true，否则false
  static Future<bool> precacheImages(List<String> urls) async {
    bool allSuccess = true;
    for (final url in urls) {
      final success = await _precacheImage(url);
      if (!success) allSuccess = false;
    }
    return allSuccess;
  }

  /// 检查图片是否已缓存
  static Future<bool> isImageCached(String url) async {
    final fileInfo = await cacheManager.getFileFromCache(url);
    return fileInfo != null && fileInfo.file.existsSync();
  }

  /// 清除单张图片缓存
  static Future<void> clearImageCache(String url) async {
    _requestQueueManager.removeTask( url);
    await cacheManager.removeFile(url);
  }

  ///清除单张图片缓存
  static Future<void> clearImageCacheAssets(String url) async {
    final passiveAssetsDomain =
        AssetsHandle.instance.getPassiveAssetsDomain(url);
    await clearImageCache(passiveAssetsDomain);
  }
}

/// 请求队列管理器，控制最大并发数并支持任务ID去重
class RequestQueueManager {
  //单例
  /// 最大并发请求数
  final int maxConcurrentRequests;
  
  /// 等待执行的请求队列
  final Queue<RequestTask> _waitingQueue = Queue();
  
  /// 当前正在执行的请求数量
  int _currentRunning = 0;
  
  /// 已存在的任务ID集合（用于去重）
  final Set<String> _existingTaskIds = <String>{};

  RequestQueueManager({this.maxConcurrentRequests = 10});

  /// 添加请求到队列，如果ID已存在则不添加
  /// 返回值：true表示添加成功，false表示ID已存在
  bool addRequest(RequestTask task) {
    // 检查任务ID是否已存在
    if (_existingTaskIds.contains(task.taskId)) {
      return false;
    }
    
    _existingTaskIds.add(task.taskId);
    _waitingQueue.add(task);
    _processQueue();
    return true;
  }

  /// 批量添加请求，自动过滤重复ID的任务
  /// 返回值：成功添加的任务数量
  int addRequests(List<RequestTask> tasks) {
    int addedCount = 0;
    for (final task in tasks) {
      if (!_existingTaskIds.contains(task.taskId)) {
        _existingTaskIds.add(task.taskId);
        _waitingQueue.add(task);
        addedCount++;
      }
    }
    _processQueue();
    return addedCount;
  }

  /// 处理队列中的请求
  void _processQueue() {
    // 如果当前运行的请求数小于最大并发数，且有等待的请求，则继续处理
    while (_currentRunning < maxConcurrentRequests && _waitingQueue.isNotEmpty) {
      final task = _waitingQueue.removeFirst();
      _currentRunning++;
      
      // 执行请求
      _executeTask(task).whenComplete(() {
        _currentRunning--;
        _existingTaskIds.remove(task.taskId); // 移除已完成任务的ID
        _processQueue(); // 继续处理队列
      });
    }
  }

  /// 执行单个请求任务
  Future<void> _executeTask(RequestTask task) async {
    try {
      // 执行请求前的回调
      if (task.onStart != null) {
        task.onStart!();
      }
      
      // 执行实际请求
      final result = await task.requestFunction();
      
      // 请求成功的回调
      if (task.onSuccess != null) {
        task.onSuccess!(result);
      }
    } catch (e) {
      // 请求失败的回调
      if (task.onError != null) {
        task.onError!(e);
      }
    } finally {
      // 请求完成的回调（无论成功失败都会调用）
      if (task.onComplete != null) {
        task.onComplete!();
      }
    }
  }

  /// 清空队列
  void clearQueue() {
    _waitingQueue.clear();
    _existingTaskIds.clear();
  }

  /// 检查队列是否为空
  bool get isEmpty => _waitingQueue.isEmpty && _currentRunning == 0;
  
  /// 检查任务ID是否已存在（在队列中或正在执行）
  bool hasTaskId(String taskId) => _existingTaskIds.contains(taskId);
  
  /// 移除指定任务（如果在等待队列中）
  bool removeTask(String taskId) {
    if (!_existingTaskIds.contains(taskId)) {
      return false;
    }
    
    // 从等待队列中移除
    final iterator = _waitingQueue.iterator;
    while (iterator.moveNext()) {
      if (iterator.current.taskId == taskId) {
        _waitingQueue.remove(iterator.current);
        _existingTaskIds.remove(taskId);
        return true;
      }
    }
    
    return false; // 任务可能正在执行中，无法移除
  }
}

/// 带唯一ID的请求任务模型
class RequestTask<T> {
  /// 任务唯一ID，用于去重
  final String taskId;
  
  /// 实际执行的请求函数
  final Future<T> Function() requestFunction;
  
  /// 请求开始时的回调
  final VoidCallback? onStart;
  
  /// 请求成功时的回调
  final void Function(T result)? onSuccess;
  
  /// 请求失败时的回调
  final void Function(dynamic error)? onError;
  
  /// 请求完成时的回调（无论成功失败）
  final VoidCallback? onComplete;

  RequestTask({
    required this.taskId,
    required this.requestFunction,
    this.onStart,
    this.onSuccess,
    this.onError,
    this.onComplete,
  });
}
