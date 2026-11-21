import UIKit
import SnapKit

class HomeViewController: UIViewController {

    private var allServers: [ServerNode] = ServerNodeStore.loadAll()
    private var currentStatus: VPNStatus = .disconnected

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = AppColors.background
        return scrollView
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.background
        return view
    }()

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

    private let nodeHintCard: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.cardBackground
        view.layer.cornerRadius = AppConstants.smallCornerRadius
        return view
    }()

    private let nodeHintIcon: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = AppColors.textSecondary
        return iv
    }()

    private let nodeHintLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.regular(size: 12)
        label.textColor = AppColors.textSecondary
        label.numberOfLines = 0
        return label
    }()

    private let connectButton = ConnectButton()

    private let demoTipCard: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.warning.withAlphaComponent(0.12)
        view.layer.cornerRadius = AppConstants.smallCornerRadius
        view.layer.borderWidth = 1
        view.layer.borderColor = AppColors.warning.withAlphaComponent(0.35).cgColor
        return view
    }()

    private let demoTipLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.regular(size: 12)
        label.textColor = AppColors.warning
        label.numberOfLines = 0
        label.text = "代码已按真 PacketTunnel 写好。免费 Personal Team 无法签名扩展；升级付费开发者后，在 Xcode 为 App/PacketTunnel 勾选 Network Extension + App Groups 即可真机出系统 VPN。"
        return label
    }()

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
        view.isUserInteractionEnabled = true
        return view
    }()

    private let configNameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.regular(size: 12)
        label.textColor = AppColors.textSecondary
        label.text = "默认配置"
        return label
    }()

    private let refreshConfigButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        button.setTitle(" 刷新", for: .normal)
        button.titleLabel?.font = AppFonts.medium(size: 12)
        button.tintColor = AppColors.primary
        button.setTitleColor(AppColors.primary, for: .normal)
        return button
    }()

    private let currentServerName: UILabel = {
        let label = UILabel()
        label.font = AppFonts.semibold(size: 17)
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

    private let chevronImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "chevron.right"))
        iv.tintColor = AppColors.textSecondary
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let selectNodeHint: UILabel = {
        let label = UILabel()
        label.text = "选择节点"
        label.font = AppFonts.medium(size: 12)
        label.textColor = AppColors.primary
        return label
    }()

    private let statsDivider: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.border
        return view
    }()

    private let downloadLabel: UILabel = {
        let label = UILabel()
        label.text = "↓ 0 B"
        label.font = AppFonts.medium(size: 13)
        label.textColor = AppColors.success
        label.textAlignment = .center
        return label
    }()

    private let uploadLabel: UILabel = {
        let label = UILabel()
        label.text = "↑ 0 B"
        label.font = AppFonts.medium(size: 13)
        label.textColor = AppColors.primary
        label.textAlignment = .center
        return label
    }()

    private let totalTrafficLabel: UILabel = {
        let label = UILabel()
        label.text = "合计 0 B"
        label.font = AppFonts.medium(size: 13)
        label.textColor = AppColors.textSecondary
        label.textAlignment = .center
        return label
    }()

    private let durationLabel: UILabel = {
        let label = UILabel()
        label.text = "时长 00:00:00"
        label.font = AppFonts.regular(size: 12)
        label.textColor = AppColors.textSecondary
        label.textAlignment = .center
        return label
    }()

    private let downloadCaption: UILabel = {
        let label = UILabel()
        label.text = "下行"
        label.font = AppFonts.regular(size: 10)
        label.textColor = AppColors.textSecondary
        label.textAlignment = .center
        return label
    }()

    private let uploadCaption: UILabel = {
        let label = UILabel()
        label.text = "上行"
        label.font = AppFonts.regular(size: 10)
        label.textColor = AppColors.textSecondary
        label.textAlignment = .center
        return label
    }()

    private let totalCaption: UILabel = {
        let label = UILabel()
        label.text = "总流量"
        label.font = AppFonts.regular(size: 10)
        label.textColor = AppColors.textSecondary
        label.textAlignment = .center
        return label
    }()

    private var timer: Timer?
    private var isRefreshingConfig = false

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        setupUI()
        setupVPNManager()
        updateSelectedServer()
        updateRoutingSummary()
        syncStatus(VPNManager.shared.status)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        allServers = ServerNodeStore.loadAll()
        ensureSelectedServer()
        updateTrafficLabels()
    }

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(headerLabel)
        contentView.addSubview(demoBadge)
        contentView.addSubview(scanButton)
        contentView.addSubview(connectButton)
        contentView.addSubview(demoTipCard)
        demoTipCard.addSubview(demoTipLabel)
        contentView.addSubview(routingSummaryLabel)
        contentView.addSubview(currentServerCard)
        contentView.addSubview(nodeHintCard)
        nodeHintCard.addSubview(nodeHintIcon)
        nodeHintCard.addSubview(nodeHintLabel)

        currentServerCard.addSubview(configNameLabel)
        currentServerCard.addSubview(refreshConfigButton)
        currentServerCard.addSubview(currentServerName)
        currentServerCard.addSubview(currentServerType)
        currentServerCard.addSubview(selectNodeHint)
        currentServerCard.addSubview(chevronImageView)
        currentServerCard.addSubview(statsDivider)
        currentServerCard.addSubview(downloadCaption)
        currentServerCard.addSubview(downloadLabel)
        currentServerCard.addSubview(uploadCaption)
        currentServerCard.addSubview(uploadLabel)
        currentServerCard.addSubview(totalCaption)
        currentServerCard.addSubview(totalTrafficLabel)
        currentServerCard.addSubview(durationLabel)

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
            make.height.equalTo(18)
            make.width.greaterThanOrEqualTo(32)
        }
        scanButton.snp.makeConstraints { make in
            make.centerY.equalTo(headerLabel)
            make.trailing.equalToSuperview().offset(-20)
            make.width.height.equalTo(28)
        }

        connectButton.snp.makeConstraints { make in
            make.top.equalTo(headerLabel.snp.bottom).offset(28)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(180)
        }

        demoTipCard.snp.makeConstraints { make in
            make.top.equalTo(connectButton.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        demoTipLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(10)
        }

        routingSummaryLabel.snp.makeConstraints { make in
            make.top.equalTo(demoTipCard.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        currentServerCard.snp.makeConstraints { make in
            make.top.equalTo(routingSummaryLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        configNameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualTo(refreshConfigButton.snp.leading).offset(-8)
        }
        refreshConfigButton.snp.makeConstraints { make in
            make.centerY.equalTo(configNameLabel)
            make.trailing.equalToSuperview().offset(-12)
        }
        currentServerName.snp.makeConstraints { make in
            make.top.equalTo(configNameLabel.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualTo(selectNodeHint.snp.leading).offset(-8)
        }
        currentServerType.snp.makeConstraints { make in
            make.leading.equalTo(currentServerName.snp.trailing).offset(8)
            make.centerY.equalTo(currentServerName)
            make.height.equalTo(18)
            make.width.equalTo(52)
        }
        selectNodeHint.snp.makeConstraints { make in
            make.centerY.equalTo(currentServerName)
            make.trailing.equalTo(chevronImageView.snp.leading).offset(-2)
        }
        chevronImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalTo(currentServerName)
            make.width.height.equalTo(14)
        }
        statsDivider.snp.makeConstraints { make in
            make.top.equalTo(currentServerName.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }

        let statsStack = UIStackView(arrangedSubviews: [
            makeStatColumn(caption: downloadCaption, value: downloadLabel),
            makeStatColumn(caption: uploadCaption, value: uploadLabel),
            makeStatColumn(caption: totalCaption, value: totalTrafficLabel)
        ])
        statsStack.axis = .horizontal
        statsStack.distribution = .fillEqually
        currentServerCard.addSubview(statsStack)
        statsStack.snp.makeConstraints { make in
            make.top.equalTo(statsDivider.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(8)
        }
        durationLabel.snp.makeConstraints { make in
            make.top.equalTo(statsStack.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-14)
        }

        nodeHintCard.snp.makeConstraints { make in
            make.top.equalTo(currentServerCard.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-24)
        }
        nodeHintIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.top.equalToSuperview().offset(9)
            make.width.height.equalTo(18)
        }
        nodeHintLabel.snp.makeConstraints { make in
            make.leading.equalTo(nodeHintIcon.snp.trailing).offset(6)
            make.trailing.equalToSuperview().offset(-10)
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
        }

        connectButton.delegate = self
        scanButton.addTarget(self, action: #selector(scanTapped), for: .touchUpInside)
        refreshConfigButton.addTarget(self, action: #selector(refreshConfigTapped), for: .touchUpInside)
        currentServerCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openServerList)))
    }

    private func makeStatColumn(caption: UILabel, value: UILabel) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [value, caption])
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .center
        return stack
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
        updateDemoBadge(for: status)
        updateRoutingSummary()
        if status == .connected {
            startTimer()
        } else if status == .disconnected || status == .invalid {
            stopTimer()
        }
        updateTrafficLabels()
    }

    private func updateDemoBadge(for status: VPNStatus) {
        let active = status == .connected || status == .connecting
        guard active else {
            demoBadge.isHidden = true
            return
        }
        if VPNManager.shared.isDemoMode {
            demoBadge.text = " App演示 "
        } else if VPNManager.shared.isTunnelDemo {
            demoBadge.text = " 隧道演示 "
        } else {
            demoBadge.text = " Tunnel "
            demoBadge.textColor = AppColors.success
            demoBadge.backgroundColor = AppColors.success.withAlphaComponent(0.15)
        }
        if VPNManager.shared.isDemoMode || VPNManager.shared.isTunnelDemo {
            demoBadge.textColor = AppColors.warning
            demoBadge.backgroundColor = AppColors.warning.withAlphaComponent(0.15)
        }
        demoBadge.isHidden = false
    }

    private func updateNodeHint(for server: ServerNode?) {
        guard let server else {
            nodeHintIcon.image = UIImage(systemName: "info.circle")
            nodeHintLabel.text = "请选择节点。出国 / 回国节点会自动采用对应路由策略。"
            return
        }
        switch server.serverType {
        case .outbound:
            nodeHintIcon.image = UIImage(systemName: "globe")
        case .inbound:
            nodeHintIcon.image = UIImage(systemName: "house")
        }
        nodeHintLabel.text = server.serverType.routingHint
    }

    private func updateRoutingSummary() {
        if VPNManager.shared.isDemoMode && currentStatus == .connected {
            routingSummaryLabel.text = "演示连接中：未创建系统 VPN，状态栏不会出现 VPN 图标"
            return
        }
        if let config = VPNManager.shared.currentRouting {
            routingSummaryLabel.text = config.summaryText
            return
        }
        guard let selected = selectedServer() else {
            routingSummaryLabel.text = "选择节点后显示路由策略"
            return
        }
        let mode = VPNMode.inferred(from: selected.serverType)
        let config = RoutingPolicyManager.shared.buildRoutingConfig(
            mode: mode,
            rules: RoutingPolicyManager.shared.loadRules()
        )
        routingSummaryLabel.text = config.summaryText
    }

    private func selectedServer() -> ServerNode? {
        allServers.first(where: { $0.isSelected }) ?? allServers.first
    }

    @discardableResult
    private func ensureSelectedServer() -> ServerNode? {
        guard !allServers.isEmpty else {
            updateSelectedServer()
            return nil
        }
        if !allServers.contains(where: { $0.isSelected }) {
            allServers[0].isSelected = true
            ServerNodeStore.setSelectedServerId(allServers[0].id)
        }
        updateSelectedServer()
        return selectedServer()
    }

    private func updateSelectedServer() {
        configNameLabel.text = ServerNodeStore.configName
        guard let selected = selectedServer() else {
            currentServerName.text = "暂无节点"
            currentServerType.isHidden = true
            selectNodeHint.text = "选择节点"
            updateNodeHint(for: nil)
            return
        }
        currentServerType.isHidden = false
        currentServerName.text = selected.displayName
        currentServerType.text = selected.serverType.displayName
        currentServerType.textColor = selected.serverType == .outbound ? AppColors.primary : AppColors.warning
        currentServerType.backgroundColor = (selected.serverType == .outbound ? AppColors.primary : AppColors.warning).withAlphaComponent(0.15)
        selectNodeHint.text = "更换节点"
        updateNodeHint(for: selected)
        updateRoutingSummary()
    }

    @objc private func openServerList() {
        let list = ServerListViewController(
            servers: allServers,
            isVPNConnected: currentStatus == .connected
        )
        list.delegate = self
        navigationController?.pushViewController(list, animated: true)
    }

    @objc private func scanTapped() {
        let scanner = QRScannerViewController()
        scanner.delegate = self
        scanner.modalPresentationStyle = .fullScreen
        present(scanner, animated: true)
    }

    @objc private func refreshConfigTapped() {
        guard !isRefreshingConfig else { return }
        if let url = ServerNodeStore.subscriptionURL, !url.isEmpty {
            isRefreshingConfig = true
            refreshConfigButton.isEnabled = false
            ServerNodeQRParser.parseAsync(url) { [weak self] result in
                guard let self else { return }
                self.isRefreshingConfig = false
                self.refreshConfigButton.isEnabled = true
                switch result {
                case .success(let nodes):
                    ServerNodeStore.rememberSubscription(urlString: url)
                    self.applyScannedNodes(nodes, showAlert: false)
                    let alert = UIAlertController(title: "刷新成功", message: "已更新 \(nodes.count) 个节点", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "确定", style: .default))
                    self.present(alert, animated: true)
                case .failure(let error):
                    let alert = UIAlertController(title: "刷新失败", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "确定", style: .default))
                    self.present(alert, animated: true)
                }
            }
            return
        }
        allServers = ServerNodeStore.loadAll()
        ensureSelectedServer()
        let alert = UIAlertController(title: "已刷新", message: "当前为本地节点列表。扫码导入订阅后可一键拉取最新配置。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    private func applyScannedNodes(_ nodes: [ServerNode], showAlert: Bool = true) {
        guard let first = nodes.first else { return }
        for node in nodes {
            allServers = ServerNodeStore.addCustom(node)
        }
        selectServer(id: first.id, reconnectIfNeeded: currentStatus == .connected)

        guard showAlert else { return }
        let message: String
        if nodes.count == 1 {
            message = nodes[0].name
        } else if nodes.count <= 5 {
            message = "共 \(nodes.count) 个：\n" + nodes.map(\.name).joined(separator: "\n")
        } else {
            let preview = nodes.prefix(5).map(\.name).joined(separator: "\n")
            message = "共导入 \(nodes.count) 个节点\n\(preview)\n…"
        }
        let alert = UIAlertController(title: "已添加节点", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    private func selectServer(id: String, reconnectIfNeeded: Bool) {
        let previous = allServers.first(where: { $0.isSelected })
        for i in allServers.indices {
            allServers[i].isSelected = allServers[i].id == id
        }
        ServerNodeStore.setSelectedServerId(id)
        updateSelectedServer()

        guard reconnectIfNeeded, let server = allServers.first(where: { $0.id == id }) else { return }
        let typeChanged = previous?.serverType != server.serverType
        let idChanged = previous?.id != server.id
        guard idChanged else { return }

        if typeChanged {
            let alert = UIAlertController(
                title: "切换节点类型",
                message: "将按「\(server.serverType.displayName)」重连。\n\(server.serverType.routingHint)",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "取消", style: .cancel) { [weak self] _ in
                if let previous {
                    self?.selectServer(id: previous.id, reconnectIfNeeded: false)
                }
            })
            alert.addAction(UIAlertAction(title: "重连", style: .default) { [weak self] _ in
                VPNManager.shared.disconnect {
                    self?.connectVPN(to: server)
                }
            })
            present(alert, animated: true)
        } else {
            VPNManager.shared.disconnect { [weak self] in
                self?.connectVPN(to: server)
            }
        }
    }
}

extension HomeViewController: ServerListViewControllerDelegate {
    func serverList(_ list: ServerListViewController, didSelect serverId: String, shouldReconnect: Bool) {
        allServers = ServerNodeStore.loadAll()
        selectServer(id: serverId, reconnectIfNeeded: shouldReconnect)
    }

    func serverListDidRequestScan(_ list: ServerListViewController) {
        scanTapped()
    }

    func serverList(_ list: ServerListViewController, didImport nodes: [ServerNode]) {
        applyScannedNodes(nodes)
        list.reload(servers: allServers)
    }
}

extension HomeViewController: QRScannerViewControllerDelegate {
    func qrScanner(_ scanner: QRScannerViewController, didScan nodes: [ServerNode]) {
        applyScannedNodes(nodes)
    }

    func qrScannerDidCancel(_ scanner: QRScannerViewController) {}
}

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
        guard let server = server ?? selectedServer() else {
            let alert = UIAlertController(title: "无法连接", message: "请先选择一个节点", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            present(alert, animated: true)
            return
        }

        VPNManager.shared.connect(to: server) { [weak self] result in
            DispatchQueue.main.async {
                self?.updateRoutingSummary()
                self?.updateDemoBadge(for: VPNManager.shared.status)
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
                self?.updateDemoBadge(for: .disconnected)
            }
        }
    }

    private func startTimer() {
        timer?.invalidate()
        updateTrafficLabels()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTrafficLabels()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        durationLabel.text = "时长 00:00:00"
        downloadLabel.text = "↓ 0 B"
        uploadLabel.text = "↑ 0 B"
        totalTrafficLabel.text = "0 B"
    }

    private func updateTrafficLabels() {
        let sent = VPNManager.shared.currentBytesSent
        let received = VPNManager.shared.currentBytesReceived
        downloadLabel.text = "↓ \(received.formattedBytes)"
        uploadLabel.text = "↑ \(sent.formattedBytes)"
        totalTrafficLabel.text = (sent + received).formattedBytes

        if let start = VPNManager.shared.connectedDate, currentStatus == .connected {
            let totalSec = Int(Date().timeIntervalSince(start))
            durationLabel.text = String(
                format: "时长 %02d:%02d:%02d",
                totalSec / 3600,
                (totalSec % 3600) / 60,
                totalSec % 60
            )
        } else if currentStatus != .connected {
            durationLabel.text = "时长 00:00:00"
        }
    }
}
