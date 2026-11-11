platform :ios, '15.0'

target 'Daygrain' do
  use_frameworks!

  # 6.18.1 keeps appsFlyerDevKey and appleAppID writable. Do not move to 7.x.
  pod 'AppsFlyerFramework', '6.18.1'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end
