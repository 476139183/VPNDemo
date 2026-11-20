import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = createTabBarController()
        window?.makeKeyAndVisible()
    }

    private func createTabBarController() -> UITabBarController {
        let tabBarController = UITabBarController()

        let homeVC = HomeViewController()
        homeVC.tabBarItem = UITabBarItem(
            title: "首页",
            image: UIImage(systemName: "network"),
            selectedImage: UIImage(systemName: "network")
        )

        let rulesVC = RulesViewController()
        rulesVC.tabBarItem = UITabBarItem(
            title: "规则",
            image: UIImage(systemName: "list.bullet.rectangle"),
            selectedImage: UIImage(systemName: "list.bullet.rectangle.fill")
        )

        let profileVC = ProfileViewController()
        profileVC.tabBarItem = UITabBarItem(
            title: "我的",
            image: UIImage(systemName: "person.circle"),
            selectedImage: UIImage(systemName: "person.circle.fill")
        )

        let homeNav = UINavigationController(rootViewController: homeVC)
        let rulesNav = UINavigationController(rootViewController: rulesVC)
        let profileNav = UINavigationController(rootViewController: profileVC)

        homeNav.navigationBar.isHidden = true
        rulesNav.navigationBar.isHidden = true
        profileNav.navigationBar.isHidden = true

        tabBarController.viewControllers = [homeNav, rulesNav, profileNav]
        tabBarController.tabBar.tintColor = AppColors.primary
        tabBarController.tabBar.unselectedItemTintColor = AppColors.textSecondary
        tabBarController.tabBar.barTintColor = AppColors.cardBackground
        tabBarController.tabBar.backgroundColor = AppColors.cardBackground

        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = AppColors.cardBackground

            appearance.stackedLayoutAppearance.normal.iconColor = AppColors.textSecondary
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: AppColors.textSecondary]

            appearance.stackedLayoutAppearance.selected.iconColor = AppColors.primary
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: AppColors.primary]

            tabBarController.tabBar.standardAppearance = appearance
            tabBarController.tabBar.scrollEdgeAppearance = appearance
        }

        return tabBarController
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}
