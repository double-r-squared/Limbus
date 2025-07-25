import UIKit
import SwiftData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        
        do {
            let container = try ModelContainer(for: Patient.self, EyeData.self, ImageStore.self)
            let context = ModelContext(container)
            let rootViewController = DashboardViewController(modelContext: context)
            let navigationController = UINavigationController(rootViewController: rootViewController)
            window.rootViewController = navigationController
            window.makeKeyAndVisible()
            self.window = window
            return true
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
