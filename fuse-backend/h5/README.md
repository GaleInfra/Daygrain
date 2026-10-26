# 说明

此为部分拆分，安卓端运行和打包时不再需要添加--dart-define和--flavor配置

# A面接入
在MaterialApp中必须初始化flutter_smart_dialog组件

# 需要改的地方
1. 使用BaseManager时的runMyApp注入各包特征
2. 接口混淆

android/app/build.gradle文件 配置信息:
    resValue App名称字段
    包名、签名等
其他原生端配置

# B面资源压缩
需要在runMyApp时写入资源路径和密钥，此时会自动进行解压，不填写路径和密钥时则时从assets下读取资源
压缩包可以放在A包和B包(没测过放B包，按理说支持)，注意，如果要把压缩包放在B包里，则原文路径需要加packages/前缀