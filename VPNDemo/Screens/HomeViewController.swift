import UIKit
import SnapKit

class HomeViewController: UIViewController {

    private var allServers: [ServerNode] = ServerNodeStore.loadAll()
    private var displayedServers: [ServerNode] = []
    private var currentStatus: VPNStatus = .disconnected
    private var currentMode: VPNMode = VPNManager.shared.currentMode {
        didSet {
            updateModeDescription()
            filterServersByMode()
        }
    }

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    private let contentView = UIView()

    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "VPN"
        label.font = AppFonts.bold(size: 32)
        label.textColor = AppColors.textPrimary
        return label
    }()

    private let demoBadge: UILabel = {
        let label = UILabel()
        label.text = "演示"
        label.font = AppFonts.bold(size: 10)
        label.textColor = AppColors.warning
        label.textAlignment = .center
        label.backgroundColor = AppColors.warning.withAlphaComponent(0.15)
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        label.isHidden = true
        return label
    }()

    private let scanButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "qrcode.viewfinder"), for: .normal)
        button.tintColor = AppColors.primary
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        return button
    }()

    private let modeSelector = ModeSelectorView()

    private let modeDescCard: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.cardBackground
        view.layer.cornerRadius = AppConstants.smallCornerRadius
        return view
    }()

    private let modeDescIcon: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = AppColors.textSecondary
        return iv
    }()

    private let modeDescLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.regular(size: 12)
        label.textColor = AppColors.textSecondary
        label.numberOfLines = 0
        return label
    }()

    private let connectButton = ConnectButton()

    private let routingSummaryLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.regular(size: 11)
        label.textColor = AppColors.textSecondary
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    private let currentServerCard: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.cardBackground
        view.layer.cornerRadius = AppConstants.cornerRadius
        return view
    }()

    private let currentServerTitle: UILabel = {
        let label = UILabel()
        label.text = "当前节点"
        label.font = AppFonts.regular(size: 12)
        label.textColor = AppColors.textSecondary
        return label
    }()

    private let currentServerName: UILabel = {
        let label = UILabel()
        label.font = AppFonts.semibold(size: 16)
        label.textColor = AppColors.textPrimary
        return label
    }()

    private let currentServerType: UILabel = {
        let label = UILabel()
        label.font = AppFonts.bold(size: 9)
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        return label
    }()

    private let changeServerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("更换", for: .normal)
        button.titleLabel?.font = AppFonts.medium(size: 14)
        button.setTitleColor(AppColors.primary, for: .normal)
        return button
    }()

    private let serversTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "选择节点"
        label.font = AppFonts.semibold(size: 18)
        label.textColor = AppColors.textPrimary
        return label
    }()

    private let addByScanButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("＋ 扫码添加", for: .normal)
        button.titleLabel?.font = AppFonts.medium(size: 14)
        button.setTitleColor(AppColors.primary, for: .normal)
        return button
    }()

    private let emptyServersLabel: UILabel = {
        let label = UILabel()
        label.text = "当前模式暂无可用节点，请扫码添加或切换模式"
        label.font = AppFonts.regular(size: 13)
        label.textColor = AppColors.textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    private let serversTableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.register(ServerCell.self, forCellReuseIdentifier: ServerCell.identifier)
        return tableView
    }()

    private let statusCard: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.cardBackground
        view.layer.cornerRadius = AppConstants.cornerRadius
        return view
    }()

    private let downloadIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "arrow.down.circle.fill")
        imageView.tintColor = AppColors.success
        return imageView
    }()

    private let downloadLabel: UILabel = {
        let label = UILabel()
        label.text = "↓ 0 B"
        label.font = AppFonts.medium(size: 14)
        label.textColor = AppColors.textSecondary
        return label
    }()

    private let uploadIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "arrow.up.circle.fill")
        imageView.tintColor = AppColors.primary
        return imageView
    }()

    private let uploadLabel: UILabel = {
        let label = UILabel()
        label.text = "↑ 0 B"
        label.font = AppFonts.medium(size: 14)
        label.textColor = AppColors.textSecondary
        return label
    }()

    private let durationLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00:00"
        label.font = AppFonts.bold(size: 20)
        label.textColor = AppColors.textPrimary
        label.textAlignment = .center
        return label
    }()

    private var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupVPNManager()
        modeSelector.setMode(currentMode)
        currentMode = VPNManager.shared.currentMode
        updateRoutingSummary()
        syncStatus(VPNManager.shared.status)
    }

    private func setupUI() {
        view.backgroundColor = AppColors.background

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(headerLabel)
        contentView.addSubview(demoBadge)
        contentView.addSubview(scanButton)
        contentView.addSubview(modeSelector)
        contentView.addSubview(modeDescCard)
        modeDescCard.addSubview(modeDescIcon)
        modeDescCard.addSubview(modeDescLabel)
        contentView.addSubview(connectButton)
        contentView.addSubview(routingSummaryLabel)
        contentView.addSubview(currentServerCard)
        currentServerCard.addSubview(currentServerTitle)
        currentServerCard.addSubview(currentServerName)
        currentServerCard.addSubview(currentServerType)
        currentServerCard.addSubview(changeServerButton)
        contentView.addSubview(serversTitleLabel)
        contentView.addSubview(addByScanButton)
        contentView.addSubview(emptyServersLabel)
        contentView.addSubview(serversTableView)
        contentView.addSubview(statusCard)
        statusCard.addSubview(downloadIcon)
        statusCard.addSubview(downloadLabel)
        statusCard.addSubview(uploadIcon)
        statusCard.addSubview(uploadLabel)
        statusCard.addSubview(durationLabel)

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

        demoBadge.snp.makeConstraints { make in
            make.leading.equalTo(headerLabel.snp.trailing).offset(8)
            make.centerY.equalTo(headerLabel)
            make.width.equalTo(32)
            make.height.equalTo(18)
        }

        scanButton.snp.makeConstraints { make in
            make.centerY.equalTo(headerLabel)
            make.trailing.equalToSuperview().offset(-20)
            make.width.height.equalTo(28)
        }

        modeSelector.snp.makeConstraints { make in
            make.top.equalTo(headerLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(110)
        }
        modeSelector.delegate = self

        modeDescCard.snp.makeConstraints { make in
            make.top.equalTo(modeSelector.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.greaterThanOrEqualTo(36)
        }

        modeDescIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.top.equalToSuperview().offset(9)
            make.width.height.equalTo(18)
        }

        modeDescLabel.snp.makeConstraints { make in
            make.leading.equalTo(modeDescIcon.snp.trailing).offset(6)
            make.trailing.equalToSuperview().offset(-10)
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
        }

        connectButton.snp.makeConstraints { make in
            make.top.equalTo(modeDescCard.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(180)
        }

        routingSummaryLabel.snp.makeConstraints { make in
            make.top.equalTo(connectButton.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        currentServerCard.snp.makeConstraints { make in
            make.top.equalTo(routingSummaryLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(60)
        }

        currentServerTitle.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(10)
        }

        currentServerName.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-10)
            make.trailing.lessThanOrEqualTo(changeServerButton.snp.leading).offset(-8)
        }

        currentServerType.snp.makeConstraints { make in
            make.leading.equalTo(currentServerName.snp.trailing).offset(8)
            make.centerY.equalTo(currentServerName)
            make.height.equalTo(18)
            make.width.equalTo(52)
        }

        changeServerButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        serversTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(currentServerCard.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(20)
        }

        addByScanButton.snp.makeConstraints { make in
            make.centerY.equalTo(serversTitleLabel)
            make.trailing.equalToSuperview().offset(-20)
        }

        emptyServersLabel.snp.makeConstraints { make in
            make.top.equalTo(serversTitleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(32)
        }

        serversTableView.snp.makeConstraints { make in
            make.top.equalTo(serversTitleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(140)
        }

        statusCard.snp.makeConstraints { make in
            make.top.equalTo(serversTableView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(80)
            make.bottom.equalToSuperview().offset(-20)
        }

        downloadIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(16)
            make.width.height.equalTo(20)
        }

        downloadLabel.snp.makeConstraints { make in
            make.leading.equalTo(downloadIcon.snp.trailing).offset(8)
            make.centerY.equalTo(downloadIcon)
        }

        uploadIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(100)
            make.top.equalToSuperview().offset(16)
            make.width.height.equalTo(20)
        }

        uploadLabel.snp.makeConstraints { make in
            make.leading.equalTo(uploadIcon.snp.trailing).offset(8)
            make.centerY.equalTo(uploadIcon)
        }

        durationLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-16)
        }

        connectButton.delegate = self
        changeServerButton.addTarget(self, action: #selector(changeServerTapped), for: .touchUpInside)
        scanButton.addTarget(self, action: #selector(scanTapped), for: .touchUpInside)
        addByScanButton.addTarget(self, action: #selector(scanTapped), for: .touchUpInside)
    }

    private func setupTableView() {
        serversTableView.delegate = self
        serversTableView.dataSource = self
    }

    private func setupVPNManager() {
        VPNManager.shared.statusDidChange = { [weak self] status in
            DispatchQueue.main.async {
                self?.syncStatus(status)
            }
        }
    }

    private func syncStatus(_ status: VPNStatus) {
        currentStatus = status
        connectButton.setStatus(status)
        demoBadge.isHidden = !(VPNManager.shared.isDemoMode && (status == .connected || status == .connecting))
        updateRoutingSummary()
        serversTableView.reloadData()

        if status == .connected {
            startTimer()
        } else if status == .disconnected || status == .invalid {
            stopTimer()
        }
    }

    private func updateModeDescription() {
        let descriptions: [VPNMode: (icon: String, text: String)] = [
            .smart: ("arrow.triangle.branch", "国内流量直连，国外流量及匹配规则的域名走 VPN 隧道"),
            .globalOutbound: ("globe", "所有流量经海外节点转发，适合从国内访问国际网络"),
            .globalInbound: ("house", "所有流量经国内节点转发，适合从国外访问国内网络")
        ]
        if let desc = descriptions[currentMode] {
            modeDescIcon.image = UIImage(systemName: desc.icon)
            modeDescLabel.text = desc.text
        }
    }

    private func updateRoutingSummary() {
        if let config = VPNManager.shared.currentRouting {
            routingSummaryLabel.text = config.summaryText
        } else {
            let config = RoutingPolicyManager.shared.buildRoutingConfig(
                mode: currentMode,
                rules: RoutingPolicyManager.shared.loadRules()
            )
            routingSummaryLabel.text = config.summaryText
        }
    }

    private func filterServersByMode() {
        switch currentMode {
        case .smart:
            displayedServers = allServers
        case .globalOutbound:
            displayedServers = allServers.filter { $0.serverType == .outbound }
        case .globalInbound:
            displayedServers = allServers.filter { $0.serverType == .inbound }
        }

        let height = max(displayedServers.count * 72, displayedServers.isEmpty ? 48 : 0)
        serversTableView.snp.updateConstraints { make in
            make.height.equalTo(height)
        }
        emptyServersLabel.isHidden = !displayedServers.isEmpty
        serversTableView.isHidden = displayedServers.isEmpty

        if !displayedServers.isEmpty, !displayedServers.contains(where: { $0.isSelected }) {
            let firstId = displayedServers[0].id
            allServers.indices.forEach { allServers[$0].isSelected = allServers[$0].id == firstId }
            UserDefaults.standard.set(firstId, forKey: AppConstants.UserDefaultsKeys.selectedServerId)
        }
        updateSelectedServer()
    }

    private func updateSelectedServer() {
        guard let selected = allServers.first(where: { $0.isSelected }) ?? allServers.first else {
            currentServerName.text = "暂无节点"
            return
        }
        currentServerName.text = selected.displayName
        currentServerType.text = selected.serverType.displayName
        currentServerType.textColor = selected.serverType == .outbound ? AppColors.primary : AppColors.warning
        currentServerType.backgroundColor = (selected.serverType == .outbound ? AppColors.primary : AppColors.warning).withAlphaComponent(0.15)

        for i in allServers.indices {
            allServers[i].isSelected = allServers[i].id == selected.id
        }
        serversTableView.reloadData()
    }

    @objc private func changeServerTapped() {
        let target = serversTitleLabel.frame.origin.y - 12
        scrollView.setContentOffset(CGPoint(x: 0, y: max(target, 0)), animated: true)
    }

    @objc private func scanTapped() {
        let scanner = QRScannerViewController()
        scanner.delegate = self
        scanner.modalPresentationStyle = .fullScreen
        present(scanner, animated: true)
    }

    private func applyScannedNodes(_ nodes: [ServerNode]) {
        guard let first = nodes.first else { return }
        for node in nodes {
            allServers = ServerNodeStore.addCustom(node)
        }
        selectServer(id: first.id, reconnectIfNeeded: currentStatus == .connected)

        let names = nodes.map(\.name).joined(separator: "、")
        let alert = UIAlertController(title: "已添加节点", message: names, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    private func selectServer(id: String, reconnectIfNeeded: Bool) {
        for i in allServers.indices {
            allServers[i].isSelected = allServers[i].id == id
        }
        UserDefaults.standard.set(id, forKey: AppConstants.UserDefaultsKeys.selectedServerId)
        filterServersByMode()

        if reconnectIfNeeded, let server = allServers.first(where: { $0.id == id }) {
            VPNManager.shared.disconnect { [weak self] in
                self?.connectVPN(to: server)
            }
        }
    }
}

// MARK: - QRScannerViewControllerDelegate
extension HomeViewController: QRScannerViewControllerDelegate {
    func qrScanner(_ scanner: QRScannerViewController, didScan nodes: [ServerNode]) {
        applyScannedNodes(nodes)
    }

    func qrScannerDidCancel(_ scanner: QRScannerViewController) {}
}

// MARK: - UITableView
extension HomeViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        displayedServers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ServerCell.identifier, for: indexPath) as? ServerCell else {
            return UITableViewCell()
        }
        let server = displayedServers[indexPath.row]
        let merged = allServers.first { $0.id == server.id } ?? server
        cell.configure(with: merged, isVPNConnected: currentStatus == .connected && merged.isSelected)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selected = displayedServers[indexPath.row]
        let wasConnected = currentStatus == .connected
        let previousId = allServers.first(where: { $0.isSelected })?.id
        selectServer(id: selected.id, reconnectIfNeeded: wasConnected && previousId != selected.id)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let server = displayedServers[indexPath.row]
        guard ServerNodeStore.isCustom(id: server.id) else { return nil }

        let delete = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, completion in
            guard let self = self else {
                completion(false)
                return
            }
            if server.isSelected && (self.currentStatus == .connected || self.currentStatus == .connecting) {
                VPNManager.shared.disconnect()
            }
            self.allServers = ServerNodeStore.removeCustom(id: server.id)
            self.filterServersByMode()
            completion(true)
        }
        delete.backgroundColor = AppColors.error
        return UISwipeActionsConfiguration(actions: [delete])
    }
}

// MARK: - ConnectButtonDelegate
extension HomeViewController: ConnectButtonDelegate {

    func connectButtonTapped() {
        if currentStatus == .connected {
            disconnectVPN()
        } else if currentStatus == .connecting || currentStatus == .disconnecting {
            return
        } else {
            if !UserManager.shared.isLoggedIn {
                presentLoginScreen()
                return
            }
            connectVPN()
        }
    }

    private func presentLoginScreen() {
        let loginVC = LoginViewController()
        loginVC.onLoginSuccess = { [weak self] in
            self?.connectVPN()
        }
        let nav = UINavigationController(rootViewController: loginVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    private func connectVPN(to server: ServerNode? = nil) {
        guard let server = server ?? allServers.first(where: { $0.isSelected }) else {
            let alert = UIAlertController(title: "无法连接", message: "请先选择一个节点", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            present(alert, animated: true)
            return
        }

        VPNManager.shared.connect(to: server, mode: currentMode) { [weak self] result in
            DispatchQueue.main.async {
                self?.updateRoutingSummary()
                self?.demoBadge.isHidden = !VPNManager.shared.isDemoMode
                if case .failure(let error) = result {
                    let alert = UIAlertController(title: "连接失败", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "确定", style: .default))
                    self?.present(alert, animated: true)
                }
            }
        }
    }

    private func disconnectVPN() {
        VPNManager.shared.disconnect { [weak self] in
            DispatchQueue.main.async {
                self?.stopTimer()
                self?.demoBadge.isHidden = true
                self?.serversTableView.reloadData()
            }
        }
    }

    private func startTimer() {
        timer?.invalidate()
        updateDuration()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateDuration()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        durationLabel.text = "00:00:00"
        downloadLabel.text = "↓ 0 B"
        uploadLabel.text = "↑ 0 B"
    }

    private func updateDuration() {
        let start = VPNManager.shared.connectedDate
        guard let start else { return }
        let total = Int(Date().timeIntervalSince(start))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        durationLabel.text = String(format: "%02d:%02d:%02d", hours, minutes, seconds)

        let sent = VPNManager.shared.currentBytesSent
        let received = VPNManager.shared.currentBytesReceived
        downloadLabel.text = "↓ \(ByteCountFormatter.string(fromByteCount: received, countStyle: .binary))"
        uploadLabel.text = "↑ \(ByteCountFormatter.string(fromByteCount: sent, countStyle: .binary))"
    }
}

// MARK: - ModeSelectorDelegate
extension HomeViewController: ModeSelectorDelegate {
    func modeDidChange(_ mode: VPNMode) {
        let previous = currentMode
        currentMode = mode
        VPNManager.shared.currentMode = mode
        updateRoutingSummary()

        guard currentStatus == .connected, previous != mode else { return }

        let alert = UIAlertController(
            title: "切换模式",
            message: "已连接状态下切换模式将重新应用分流并重连，是否继续？",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel) { [weak self] _ in
            self?.currentMode = previous
            self?.modeSelector.setMode(previous)
            VPNManager.shared.currentMode = previous
            self?.updateRoutingSummary()
        })
        alert.addAction(UIAlertAction(title: "重连", style: .default) { [weak self] _ in
            VPNManager.shared.refreshRouting { [weak self] result in
                DispatchQueue.main.async {
                    self?.updateRoutingSummary()
                    if case .failure(let error) = result {
                        let fail = UIAlertController(title: "重连失败", message: error.localizedDescription, preferredStyle: .alert)
                        fail.addAction(UIAlertAction(title: "确定", style: .default))
                        self?.present(fail, animated: true)
                    }
                }
            }
        })
        present(alert, animated: true)
    }
}
