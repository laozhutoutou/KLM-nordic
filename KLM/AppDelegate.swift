//
//  AppDelegate.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/2.
//

import UIKit
import nRFMeshProvision
import IQKeyboardManagerSwift


@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    //nordic
    var meshNetworkManager: MeshNetworkManager!
    var connection: NetworkConnection!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        setupSVHUD()
        
        setupKeyboard()
        
        setUpNordic()
        
//        KLMApplicationManager.sharedInstacnce.setupWindow(window: window!)
//        window?.makeKeyAndVisible()
        return true
    }
    
    private func setupKeyboard() {
        
        let manager =  IQKeyboardManager.shared
        manager.enable = true
        manager.shouldResignOnTouchOutside = true
        manager.shouldToolbarUsesTextFieldTintColor = true;
        manager.enableAutoToolbar = true;
        manager.toolbarManageBehaviour = .byTag
        
    }
    
    func setUpNordic() {
        
        meshNetworkManager = MeshNetworkManager()
        meshNetworkManager.acknowledgmentTimerInterval = 0.150
        meshNetworkManager.transmissionTimerInterval = 0.600
        meshNetworkManager.incompleteMessageTimeout = 10.0
        meshNetworkManager.retransmissionLimit = 2
        meshNetworkManager.acknowledgmentMessageInterval = 4.2
        // As the interval has been increased, the timeout can be adjusted.
        // The acknowledged message will be repeated after 4.2 seconds,
        // 12.6 seconds (4.2 + 4.2 * 2), and 29.4 seconds (4.2 + 4.2 * 2 + 4.2 * 4).
        // Then, leave 10 seconds for until the incomplete message times out.
        //发送消息超时时间
        meshNetworkManager.acknowledgmentMessageTimeout = 20.0
        meshNetworkManager.logger = self
        
        var loaded = false
        do {
            loaded = try meshNetworkManager.load()
        } catch {
            print(error)
            // ignore
        }
        
        // If load failed, create a new MeshNetwork.
        if !loaded {
            createNewMeshNetwork()
        } else {
            meshNetworkDidChange()
        }
    }
    
    func createNewMeshNetwork() {
        // TODO: Implement creator
        let provisioner = Provisioner(name: UIDevice.current.name,
                                      allocatedUnicastRange: [AddressRange(0x0001...0x199A)],
                                      allocatedGroupRange:   [AddressRange(0xC000...0xCC9A)],
                                      allocatedSceneRange:   [SceneRange(0x0001...0x3333)])
        _ = meshNetworkManager.createNewMeshNetwork(withName: "nRF Mesh Network", by: provisioner)
        _ = meshNetworkManager.save()
        
        //创建一个APP key
        if MeshNetworkManager.instance.meshNetwork!.applicationKeys.isEmpty {
            
            let newKey: Data! = Data.random128BitKey()
            let network = MeshNetworkManager.instance.meshNetwork!
            do {
                try network.add(applicationKey: newKey, withIndex: 0, name: "new key")
            } catch  {
                print(error)
            }
            
            _ =  MeshNetworkManager.instance.save()
            
        }
        
        meshNetworkDidChange()
    }
    
    func meshNetworkDidChange() {
        connection?.close()
        
        let meshNetwork = meshNetworkManager.meshNetwork!

        // Generic Default Transition Time Server model:
        let defaultTransitionTimeServerDelegate = GenericDefaultTransitionTimeServerDelegate(meshNetwork)
        // Scene Server and Scene Setup Server models:
        let sceneServer = SceneServerDelegate(meshNetwork,
                                              defaultTransitionTimeServer: defaultTransitionTimeServerDelegate)
        let sceneSetupServer = SceneSetupServerDelegate(server: sceneServer)
        
        // Set up local Elements on the phone.
        let element0 = Element(name: "Primary Element", location: .first, models: [
            // Scene Server and Scene Setup Server models (client is added automatically):
            Model(sigModelId: .sceneServerModelId, delegate: sceneServer),
            Model(sigModelId: .sceneSetupServerModelId, delegate: sceneSetupServer),
            // Sensor Client model:
            Model(sigModelId: .sensorClientModelId, delegate: SensorClientDelegate()),
            // Generic Default Transition Time Server model:
            Model(sigModelId: .genericDefaultTransitionTimeServerModelId,
                  delegate: defaultTransitionTimeServerDelegate),
            Model(sigModelId: .genericDefaultTransitionTimeClientModelId,
                  delegate: GenericDefaultTransitionTimeClientDelegate()),
            // 4 generic models defined by Bluetooth SIG:
            Model(sigModelId: .genericOnOffServerModelId,
                  delegate: GenericOnOffServerDelegate(meshNetwork,
                                                       defaultTransitionTimeServer: defaultTransitionTimeServerDelegate,
                                                       elementIndex: 0)),
            Model(sigModelId: .genericLevelServerModelId,
                  delegate: GenericLevelServerDelegate(meshNetwork,
                                                       defaultTransitionTimeServer: defaultTransitionTimeServerDelegate,
                                                       elementIndex: 0)),
            Model(sigModelId: .genericOnOffClientModelId, delegate: GenericOnOffClientDelegate()),
            Model(sigModelId: .genericLevelClientModelId, delegate: GenericLevelClientDelegate()),
            // A simple vendor model:
            Model(vendorModelId: .simpleOnOffModelId,
                  companyId: .nordicSemiconductorCompanyId,
                  delegate: SimpleOnOffClientDelegate())
        ])
        let element1 = Element(name: "Secondary Element", location: .second, models: [
            Model(sigModelId: .genericOnOffServerModelId,
                  delegate: GenericOnOffServerDelegate(meshNetwork,
                                                       defaultTransitionTimeServer: defaultTransitionTimeServerDelegate,
                                                       elementIndex: 1)),
            Model(sigModelId: .genericLevelServerModelId,
                  delegate: GenericLevelServerDelegate(meshNetwork,
                                                       defaultTransitionTimeServer: defaultTransitionTimeServerDelegate,
                                                       elementIndex: 1)),
            Model(sigModelId: .genericOnOffClientModelId, delegate: GenericOnOffClientDelegate()),
            Model(sigModelId: .genericLevelClientModelId, delegate: GenericLevelClientDelegate())
        ])
        meshNetworkManager.localElements = [element0, element1]
        
        connection = NetworkConnection(to: meshNetwork)
        connection!.dataDelegate = meshNetworkManager
        connection!.logger = self
        meshNetworkManager.transmitter = connection
        connection.isConnectionModeAutomatic = true
        connection!.open()
        
        enterMainUI()
    }
    
    func setupSVHUD() {
        
        SVProgressHUD.setDefaultStyle(.dark)
    }
    
    func enterMainUI() {
        
        let tabbar = KLMTabBarController()
        window?.rootViewController = tabbar
        window?.makeKeyAndVisible()
        
    }
    
    func enterMoreUI() {
        
        let tabbar = KLMTabBarController()
        tabbar.selectedIndex = 2
        window?.rootViewController = tabbar
        window?.makeKeyAndVisible()
        
    }
    
    //后台也可以运行定时器
    func applicationDidEnterBackground(_ application: UIApplication) {
        
        let app = UIApplication.shared
        var bgTask = UIBackgroundTaskIdentifier.init(rawValue: 0)
        app.beginBackgroundTask {
            
            app.endBackgroundTask(.invalid)
            
            DispatchQueue.main.async {
                if bgTask != .invalid {
                    bgTask = .invalid
                }
            }
        }
        
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                if bgTask != .invalid {
                    bgTask = .invalid
                }
            }
        }
    }
    
    //进程杀死
    func applicationWillTerminate(_ application: UIApplication) {
        
        //
    }
}

extension MeshNetworkManager {
    
    static var instance: MeshNetworkManager {
        if Thread.isMainThread {
            return (UIApplication.shared.delegate as! AppDelegate).meshNetworkManager
        } else {
            return DispatchQueue.main.sync {
                return (UIApplication.shared.delegate as! AppDelegate).meshNetworkManager
            }
        }
    }
    
    static var bearer: NetworkConnection! {
        if Thread.isMainThread {
            return (UIApplication.shared.delegate as! AppDelegate).connection
        } else {
            return DispatchQueue.main.sync {
                return (UIApplication.shared.delegate as! AppDelegate).connection
            }
        }
    }
    
}

// MARK: - Logger

extension AppDelegate: LoggerDelegate {
    
    func log(message: String, ofCategory category: LogCategory, withLevel level: LogLevel) {
        if #available(iOS 10.0, *) {
            os_log("%{public}@", log: category.log, type: level.type, message)
        } else {
            NSLog("%@", message)
        }
    }
    
}

extension LogLevel {
    
    /// Mapping from mesh log levels to system log types.
    var type: OSLogType {
        switch self {
        case .debug:       return .debug
        case .verbose:     return .debug
        case .info:        return .info
        case .application: return .default
        case .warning:     return .error
        case .error:       return .fault
        }
    }
    
}

extension LogCategory {
    
    var log: OSLog {
        return OSLog(subsystem: Bundle.main.bundleIdentifier!, category: rawValue)
    }
    
}


