import UIKit
import SnapKit

class ProfileViewController: UIViewController {

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    private let contentView = UIView()

    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "我的"
        label.font = AppFonts.bold(size: 32)
        label.textColor = AppColors.textPrimary
        return label
    }()

    private let profileCard: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.cardBackground
        view.layer.cornerRadius = AppConstants.cornerRadius
        return view
    }()

    private let avatarView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.primary.withAlphaComponent(0.2)
        view.layer.cornerRadius = 30
        return view
    }()

    private let avatarIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.fill")
        imageView.tintColor = AppColors.primary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "游客"
        label.font = AppFonts.semibold(size: 18)
        label.textColor = AppColors.textPrimary
        return label
    }()

    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("登录", for: .normal)
        button.titleLabel?.font = AppFonts.medium(size: 14)
        button.setTitleColor(AppColors.primary, for: .normal)
        return button
    }()

    private let subscriptionCard: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.cardBackground
        view.layer.cornerRadius = AppConstants.cornerRadius
        return view
    }()

    private let subscriptionTitle: UILabel = {
        let label = UILabel()
        label.text = "套餐信息"
        label.font = AppFonts.semibold(size: 14)
        label.textColor = AppColors.textSecondary
        return label
    }()

    private let planLabel: UILabel = {
        let label = UILabel()
        label.text = "免费版"
        label.font = AppFonts.bold(size: 20)
        label.textColor = AppColors.textPrimary
        return label
    }()

    private let dataUsedLabel: UILabel = {
        let label = UILabel()
        label.text = "已使用 0 GB / 10 GB"
        label.font = AppFonts.regular(size: 14)
        label.textColor = AppColors.textSecondary
        return label
    }()

    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.trackTintColor = AppColors.border
        progress.progressTintColor = AppColors.primary
        progress.layer.cornerRadius = 4
        progress.clipsToBounds = true
        return progress
    }()

    private let menuTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .clear
        tableView.isScrollEnabled = false
        return tableView
    }()

    private let menuItems: [(icon: String, title: String)] = [
        ("gearshape", "设置"),
        ("questionmark.circle", "使用帮助"),
        ("info.circle", "关于我们"),
        ("arrow.right.square", "退出登录")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUserInfo()
    }

    private func setupUI() {
        view.backgroundColor = AppColors.background

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(headerLabel)
        contentView.addSubview(profileCard)
        profileCard.addSubview(avatarView)
        avatarView.addSubview(avatarIcon)
        profileCard.addSubview(usernameLabel)
        profileCard.addSubview(loginButton)
        contentView.addSubview(subscriptionCard)
        subscriptionCard.addSubview(subscriptionTitle)
        subscriptionCard.addSubview(planLabel)
        subscriptionCard.addSubview(dataUsedLabel)
        subscriptionCard.addSubview(progressView)
        contentView.addSubview(menuTableView)

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        headerLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(20)
        }

        profileCard.snp.makeConstraints { make in
            make.top.equalTo(headerLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(80)
        }

        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(60)
        }

        avatarIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(30)
        }

        usernameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(16)
            make.top.equalTo(avatarView).offset(8)
        }

        loginButton.snp.makeConstraints { make in
            make.leading.equalTo(usernameLabel)
            make.top.equalTo(usernameLabel.snp.bottom).offset(4)
        }

        subscriptionCard.snp.makeConstraints { make in
            make.top.equalTo(profileCard.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(120)
        }

        subscriptionTitle.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(16)
        }

        planLabel.snp.makeConstraints { make in
            make.top.equalTo(subscriptionTitle.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(16)
        }

        dataUsedLabel.snp.makeConstraints { make in
            make.top.equalTo(planLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(16)
        }

        progressView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-16)
            make.height.equalTo(8)
        }

        menuTableView.snp.makeConstraints { make in
            make.top.equalTo(subscriptionCard.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(250)
            make.bottom.equalToSuperview().offset(-20)
        }

        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
    }

    private func setupTableView() {
        menuTableView.delegate = self
        menuTableView.dataSource = self
        menuTableView.register(UITableViewCell.self, forCellReuseIdentifier: "MenuCell")
    }

    @objc private func loginTapped() {
        let loginVC = LoginViewController()
        loginVC.onLoginSuccess = { [weak self] in
            self?.updateUserInfo()
        }
        let nav = UINavigationController(rootViewController: loginVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    private func updateUserInfo() {
        if UserManager.shared.isLoggedIn, let user = UserManager.shared.currentUser {
            usernameLabel.text = user.phone ?? user.email ?? "用户"
            loginButton.isHidden = true
            
            let remaining = UserManager.shared.getRemainingData()
            let remainingGB = Double(remaining) / 1_000_000_000
            let quotaGB = Double(user.dataQuota) / 1_000_000_000
            let usedGB = Double(user.usedData) / 1_000_000_000
            
            if user.isTrial {
                planLabel.text = "试用版"
            } else {
                planLabel.text = "付费版"
            }
            dataUsedLabel.text = "已使用 \(String(format: "%.1f", usedGB)) GB / \(String(format: "%.1f", quotaGB)) GB"
            progressView.progress = Float(usedGB / quotaGB)
        } else {
            usernameLabel.text = "游客"
            loginButton.isHidden = false
            planLabel.text = "免费版"
            dataUsedLabel.text = "登录以获取试用"
            progressView.progress = 0
        }
    }
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuCell", for: indexPath)
        let item = menuItems[indexPath.row]

        var config = cell.defaultContentConfiguration()
        config.text = item.title
        config.textProperties.color = indexPath.row == menuItems.count - 1 ? AppColors.error : AppColors.textPrimary
        config.image = UIImage(systemName: item.icon)
        config.imageProperties.tintColor = indexPath.row == menuItems.count - 1 ? AppColors.error : AppColors.primary

        cell.contentConfiguration = config
        cell.backgroundColor = AppColors.cardBackground
        cell.accessoryType = indexPath.row < menuItems.count - 1 ? .disclosureIndicator : .none

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch indexPath.row {
        case 0:
            let alert = UIAlertController(title: "设置", message: "设置功能开发中...", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            present(alert, animated: true)
        case 1:
            let alert = UIAlertController(title: "使用帮助", message: "帮助文档开发中...", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            present(alert, animated: true)
        case 2:
            let alert = UIAlertController(title: "关于我们", message: "VPN Demo v1.0.0\n跨境加速VPN", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            present(alert, animated: true)
        case 3:
            showLogoutAlert()
        default:
            break
        }
    }

    private func showLogoutAlert() {
        let alert = UIAlertController(title: "退出登录", message: "确定要退出登录吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .destructive) { [weak self] _ in
            UserManager.shared.logout()
            self?.updateUserInfo()
        })
        present(alert, animated: true)
    }
}
