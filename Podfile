# Uncomment the next line to define a global platform for your project
platform :ios, '15.0'

target 'VPNDemo' do
  use_frameworks!

  # Pods for VPNDemo
  pod 'SnapKit', '~> 5.7'
  pod 'KeychainAccess', '~> 4.2'
  pod 'Alamofire', '~> 5.11'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'NO'
    end
  end
  
  installer.pods_project.build_configurations.each do |config|
    config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'NO'
  end
end
