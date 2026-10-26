/// Compile-time activity configuration. Empty defaults stay empty; callers merge URL and host options first.
class BakedConfig {
  static const String packageName = String.fromEnvironment('PACKAGE_NAME');
  static const String appVersion = String.fromEnvironment('APP_VERSION');
  static const String baseUrl = String.fromEnvironment('BASE_URL');
  static const String socketUrl = String.fromEnvironment('SOCKET_URL');
  static const String logUrl = String.fromEnvironment('LOG_URL');
  static const String privacyPolicy = String.fromEnvironment('PRIVACY_POLICY');
  static const String termsConditions = String.fromEnvironment('TERMS_CONDITIONS');
  static const String iosAppId = String.fromEnvironment('IOS_APP_ID');
  static const String localScheme = String.fromEnvironment('LOCAL_SCHEME');
  static const String returnUri = String.fromEnvironment('ACTIVITY_RETURN_URI');
  static const String deviceParameter = String.fromEnvironment('ACTIVITY_DEVICE_PARAMETER', defaultValue: 'device-id');
  static const String broadcasterEnv = String.fromEnvironment('BROADCASTER_ENV', defaultValue: 'prod');
  static const String testBroadcasterIdsCsv = String.fromEnvironment('TEST_BROADCASTER_IDS_CSV');
  static const String popHostMode = String.fromEnvironment('POP_HOST_MODE', defaultValue: 'pop');
  static const String key1 = String.fromEnvironment('KEY1');
  static const String key2 = String.fromEnvironment('KEY2');
  static const String key3 = String.fromEnvironment('KEY3');
  static const String key4 = String.fromEnvironment('KEY4');
  static const String commerceMode = String.fromEnvironment('COMMERCE_MODE');
  static const String preloginWindowSlot = String.fromEnvironment('PRELOGIN_WINDOW_SLOT');
  static const String preloginSlotDeviceId = String.fromEnvironment('PRELOGIN_SLOT_DEVICE_ID');
  static const String preloginSlotToken = String.fromEnvironment('PRELOGIN_SLOT_TOKEN');
  static const String preloginSlotFirstReg = String.fromEnvironment('PRELOGIN_SLOT_FIRST_REG');
  static const String preloginSlotUser = String.fromEnvironment('PRELOGIN_SLOT_USER');
  static const String preloginSlotConfig = String.fromEnvironment('PRELOGIN_SLOT_CONFIG');
  static const String preloginSlotStrategy = String.fromEnvironment('PRELOGIN_SLOT_STRATEGY');
  static const String preloginSlotIssuedAt = String.fromEnvironment('PRELOGIN_SLOT_ISSUED_AT');
  /// `code:coins:price` rows, comma separated. When set, the coin store sells only these codes.
  static const String productAllowlist = String.fromEnvironment('PRODUCT_ALLOWLIST');
}
