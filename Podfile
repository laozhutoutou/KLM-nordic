use_frameworks!

platform :ios, '13.0'

targets = ['KLM_GN', 'KLM_GW', 'KLM_Test', 'KLM_Sensetrack']
targets.each do |t|
  target t do
    pod 'nRFMeshProvision', '~> 3.1.2' #蓝牙mesh
    pod 'SnapKit', '~> 5.0.1' #自动布局框架
    pod 'RxSwift', '~> 6.2.0' #函数响应式编程框架
    pod 'RxCocoa', '~> 6.2.0'
    pod 'AFNetworking', '~> 3.2.1', :subspecs => ['Reachability', 'Serialization', 'Security', 'NSURLSession']
    pod 'Kingfisher', '~> 7.1.0' #图片加载框架
    pod 'IQKeyboardManagerSwift', '~> 6.5.6' #键盘管理
    pod 'SnapKitExtend', '~> 1.1.0' #SnapKit扩展
    pod 'YBPopupMenu', '~> 1.1.2' #弹框
    pod 'SVProgressHUD'
    pod 'JKSwiftExtension', '~> 1.6.8'
    pod 'MJRefresh', '~> 3.5.0'
    pod 'DZNEmptyDataSet', '~> 1.8.1' #数据为空时显示空白占位图
#    pod 'Charts' #图表
    pod 'KeychainAccess', '~> 4.2.2'
    pod 'Bugly'
    pod 'HandyJSON'
  end
end

#target 'KLM' do
#  
#  pod 'nRFMeshProvision', '~> 3.1.2' #蓝牙mesh
#  pod 'SnapKit', '~> 5.0.1' #自动布局框架
#  pod 'RxSwift', '~> 6.2.0' #函数响应式编程框架
#  pod 'RxCocoa', '~> 6.2.0'
#  pod 'AFNetworking', '~> 3.2.1', :subspecs => ['Reachability', 'Serialization', 'Security', 'NSURLSession']
#  pod 'Kingfisher', '~> 7.1.0' #图片加载框架
#  pod 'IQKeyboardManagerSwift', '~> 6.5.6' #键盘管理
#  pod 'SnapKitExtend', '~> 1.1.0' #SnapKit扩展
#  pod 'YBPopupMenu', '~> 1.1.2' #弹框
#  pod 'SVProgressHUD'
#  pod 'JKSwiftExtension', '~> 1.6.8'
#  pod 'MJRefresh', '~> 3.5.0'
#  pod 'DZNEmptyDataSet', '~> 1.8.1' #数据为空时显示空白占位图
#  pod 'Charts' #图表
#  
#end
#给第三方库增加bitcode 为NO，x-code更新到13.3 后无法打包
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
