# Match the app target's deployment target (see Purina target build
# settings / instructions.md) so pod-resolved dependencies don't warn
# about or build against a different minimum iOS version.
platform :ios, '15.6'

target 'Purina' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  pod 'DGCharts'
  pod 'MBProgressHUD'
  pod 'NordicDFU'
  pod 'DropDown'
  pod 'DBNumberedSlider'
  pod 'IQKeyboardManagerSwift'
  pod 'SnapKit'
  pod 'MRHexKeyboard', :git => 'https://github.com/doofyus/HexKeyboard.git', :branch => "master"
end

# Force every pod's own compiled target to build against iOS 15.6 too,
# since each pod's podspec can otherwise declare its own (older or newer)
# deployment target independent of the app/Podfile platform line above.
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.6'
    end
  end
end
