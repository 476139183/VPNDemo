import UIKit
import SnapKit

protocol ServerListViewControllerDelegate: AnyObject {
    func serverList(_ list: ServerListViewController, didSelect serverId: String, shouldReconnect: Bool)
    func serverListDidRequestScan(_ list: ServerListViewController)
    func serverList(_ list: ServerListViewController, didImport nodes: [ServerNode])
}

final class ServerListViewController: UIViewController {

    weak var delegate: ServerListViewControllerDelegate?

    private var allServers: [ServerNode]
    private let isVPNConnected: Bool
    private var sections: [(title: String, nodes: [ServerNode])] = []

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(ServerCell.self, forCellReuseIdentifier: ServerCell.identifier)
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)
        return tableView
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "暂无节点，请扫码添加"
        label.font = AppFonts.regular(size: 13)
        label.textColor = AppColors.textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    init(servers: [ServerNode], isVPNConnected: Bool) {
        self.allServers = servers
        self.isVPNConnected = isVPNConnected
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "选择节点"
        view.backgroundColor = AppColors.background
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "qrcode.viewfinder"),
            style: .plain,
            target: self,
            action: #selector(scanTapped)
        )
        navigationItem.rightBarButtonItem?.tintColor = AppColors.primary

        let header = UILabel()
        header.text = "选出国或回国节点即可，路由策略随节点自动切换"
        header.font = AppFonts.regular(size: 12)
        header.textColor = AppColors.textSecondary
        header.textAlignment = .center
        header.numberOfLines = 0

        view.addSubview(header)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
        tableView.delegate = self
        tableView.dataSource = self

        header.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(32)
        }

        rebuildSections()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        applyNavigationAppearance()
        allServers = ServerNodeStore.loadAll()
        rebuildSections()
    }

    func reload(servers: [ServerNode]) {
        allServers = servers
        rebuildSections()
    }

    private func applyNavigationAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppColors.background
        appearance.titleTextAttributes = [.foregroundColor: AppColors.textPrimary]
        appearance.shadowColor = .clear
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = AppColors.primary
        navigationController?.navigationBar.isTranslucent = false
    }

    private func rebuildSections() {
        let outbound = allServers.filter { $0.serverType == .outbound }
        let inbound = allServers.filter { $0.serverType == .inbound }
        sections = []
        if !outbound.isEmpty {
            sections.append(("出国节点", outbound))
        }
        if !inbound.isEmpty {
            sections.append(("回国节点", inbound))
        }
        emptyLabel.isHidden = !sections.isEmpty
        tableView.reloadData()
    }

    @objc private func scanTapped() {
        delegate?.serverListDidRequestScan(self)
    }
}

extension ServerListViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].nodes.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.textColor = AppColors.textSecondary
        header.textLabel?.font = AppFonts.semibold(size: 13)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ServerCell.identifier, for: indexPath) as? ServerCell else {
            return UITableViewCell()
        }
        let server = sections[indexPath.section].nodes[indexPath.row]
        let merged = allServers.first { $0.id == server.id } ?? server
        cell.configure(with: merged, isVPNConnected: isVPNConnected && merged.isSelected)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        72
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selected = sections[indexPath.section].nodes[indexPath.row]
        let previousId = allServers.first(where: { $0.isSelected })?.id
        let shouldReconnect = isVPNConnected && previousId != selected.id
        delegate?.serverList(self, didSelect: selected.id, shouldReconnect: shouldReconnect)
        navigationController?.popViewController(animated: true)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let server = sections[indexPath.section].nodes[indexPath.row]
        guard ServerNodeStore.isCustom(id: server.id) else { return nil }

        let delete = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, completion in
            guard let self else {
                completion(false)
                return
            }
            if server.isSelected && self.isVPNConnected {
                VPNManager.shared.disconnect()
            }
            self.allServers = ServerNodeStore.removeCustom(id: server.id)
            self.rebuildSections()
            completion(true)
        }
        delete.backgroundColor = AppColors.error
        return UISwipeActionsConfiguration(actions: [delete])
    }
}
