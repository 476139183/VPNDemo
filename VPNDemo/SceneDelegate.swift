import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = AppColors.background
        window.overrideUserInterfaceStyle = .dark
        window.rootViewController = createTabBarController()
        window.makeKeyAndVisible()
        self.window = window
    }

    private func createTabBarController() -> UITabBarController {
        let tabBarController = UITabBarController()
        tabBarController.view.backgroundColor = AppColors.background
        tabBarController.overrideUserInterfaceStyle = .dark

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

        let homeNav = makeNav(root: homeVC)
        let rulesNav = makeNav(root: rulesVC)
        let profileNav = makeNav(root: profileVC)

        tabBarController.viewControllers = [homeNav, rulesNav, profileNav]
        tabBarController.tabBar.isTranslucent = false
        tabBarController.tabBar.tintColor = AppColors.primary
        tabBarController.tabBar.unselectedItemTintColor = AppColors.textSecondary
        tabBarController.tabBar.barTintColor = AppColors.cardBackground
        tabBarController.tabBar.backgroundColor = AppColors.cardBackground

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppColors.cardBackground
        appearance.shadowColor = AppColors.border

        appearance.stackedLayoutAppearance.normal.iconColor = AppColors.textSecondary
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: AppColors.textSecondary]
        appearance.stackedLayoutAppearance.selected.iconColor = AppColors.primary
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: AppColors.primary]

        tabBarController.tabBar.standardAppearance = appearance
        tabBarController.tabBar.scrollEdgeAppearance = appearance

        return tabBarController
    }

    private func makeNav(root: UIViewController) -> UINavigationController {
        let nav = UINavigationController(rootViewController: root)
        nav.view.backgroundColor = AppColors.background
        nav.navigationBar.isHidden = true
        nav.navigationBar.isTranslucent = false

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppColors.background
        appearance.titleTextAttributes = [.foregroundColor: AppColors.textPrimary]
        appearance.shadowColor = .clear
        nav.navigationBar.standardAppearance = appearance
        nav.navigationBar.scrollEdgeAppearance = appearance
        nav.navigationBar.tintColor = AppColors.primary
        return nav
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}
