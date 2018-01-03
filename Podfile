# Uncomment this line to define a global platform for your project
platform :ios, '9.0'
# Uncomment this line if you're using Swift
use_frameworks!

target 'MangaLoop' do
  

  pod 'Alamofire', '~> 4.0'
#  pod 'Kanna', :git => 'https://github.com/tid-kijyun/Kanna.git', :branch => 'feature/v4.0.0'
  pod 'Fuzi', '~> 2.0.0'
  pod 'Unbox'
  pod 'SnapKit', '~> 4.0'
  pod 'MZFormSheetPresentationController', '~> 2.2'
  pod 'MXSegmentedPager'
  pod 'Kingfisher', '~> 4.0'
  pod 'CircleProgressView', '~> 1.0'
  pod 'Pantry', '~> 0.3'
#  pod 'RealmSwift', '~> 1.0'
  pod 'DZNEmptyDataSet'
  pod 'SCLAlertView', :git => 'https://github.com/vikmeup/SCLAlertView-Swift', :branch => 'master'
  pod 'Eureka', '~> 4.0'
  pod 'TLTagsControl', :git => 'https://github.com/ali312/TLTagsControl.git'
  pod 'JAMSVGImage', '~> 1.6'
  pod 'Reveal-iOS-SDK', '~> 1.6.2', :configurations => ['Debug']
  pod 'PKHUD', '~> 5.0'
  pod 'Fabric'
  pod 'Crashlytics'




end

post_install do |installer|
  # Your list of targets here.
  myTargets = ['MangaLoop']
  
  installer.pods_project.targets.each do |target|
    if myTargets.include? target.name
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '4.0'
      end
    end
  end
end

