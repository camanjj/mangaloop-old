# Uncomment this line to define a global platform for your project
platform :ios, '9.0'
# Uncomment this line if you're using Swift
use_frameworks!




target 'MangaLoop' do
  
#  link_with 'MangaLoop', 'ml-playground'

  pod 'Alamofire', '~> 3.0'
  pod 'Kanna', '1.0.2'
  pod 'Unbox'
  pod 'SnapKit', '~> 0.22.0'
  pod 'MZFormSheetPresentationController', '~> 2.2'
  pod 'MXSegmentedPager'
  pod 'Kingfisher', '~> 2.6.0'
  pod 'CircleProgressView', '= 1.0.11'
  pod 'Pantry', :git => 'https://github.com/nickoneill/Pantry.git', :branch => 'swift2'
  pod 'RealmSwift', '~> 1.0'
  pod 'DZNEmptyDataSet'
  pod 'SCLAlertView'
  pod 'Eureka', :git => 'https://github.com/xmartlabs/Eureka.git', :branch => 'swift2.3'
  pod 'TLTagsControl', :git => 'https://github.com/ali312/TLTagsControl.git'
  pod 'JAMSVGImage', '~> 1.6'
  pod 'Reveal-iOS-SDK', :configurations => ['Debug']
  pod 'PKHUD', '~> 3.0'
  pod 'Fabric'
  pod 'Crashlytics'

  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |configuration|
        configuration.build_settings['SWIFT_VERSION'] = "2.3"
      end
    end
  end



end

target 'MangaLoopTests' do

end

target 'MangaLoopUITests' do

end

