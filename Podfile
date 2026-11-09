platform :ios, '15.0'

target 'Daygrain' do
  use_frameworks!

  # Adjust 5.4.x is inside the requested 5.0-5.8 window.
  pod 'Adjust', '5.4.6'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end
