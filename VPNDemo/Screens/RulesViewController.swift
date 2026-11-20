import UIKit
import SnapKit

class RulesViewController: UIViewController {

    private var rules: [RoutingRule] = RoutingRule.defaults

    private let emptyStateView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()

    private let emptyIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "list.bullet.rectangle"))
        imageView.tintColor = AppColors.textSecondary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "暂无自定义规则"
        label.font = AppFonts.regular(size: 14)
        label.textColor = AppColors.textSecondary
        label.textAlignment = .center
        return label
    }()

    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "分流规则"
        label.font = AppFonts.bold(size: 28)
        label.textColor = AppColors.textPrimary
        return label
    }()

    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        button.tintColor = AppColors.primary
        button.imageView?.contentMode = .scaleAspectFit
        return button
    }()

    private let infoLabel: UILabel = {
        let label = UILabel()
        label.text = "国内 IP 段自动直连，无需手动添加。以下规则为域名及应用级分流策略。"
        label.font = AppFonts.regular(size: 12)
        label.textColor = AppColors.textSecondary
        label.numberOfLines = 0
        return label
    }()

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(RuleCell.self, forCellReuseIdentifier: RuleCell.identifier)
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        loadRules()
    }

    private func setupUI() {
        view.backgroundColor = AppColors.background

        view.addSubview(headerLabel)
        view.addSubview(addButton)
        view.addSubview(infoLabel)
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        emptyStateView.addSubview(emptyIcon)
        emptyStateView.addSubview(emptyLabel)

        headerLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.equalToSuperview().offset(20)
        }

        addButton.snp.makeConstraints { make in
            make.centerY.equalTo(headerLabel)
            make.trailing.equalToSuperview().offset(-20)
            make.width.height.equalTo(36)
        }

        infoLabel.snp.makeConstraints { make in
            make.top.equalTo(headerLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(infoLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        emptyStateView.snp.makeConstraints { make in
            make.center.equalTo(tableView)
        }

        emptyIcon.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.width.height.equalTo(48)
        }

        emptyLabel.snp.makeConstraints { make in
            make.top.equalTo(emptyIcon.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }

        addButton.addTarget(self, action: #selector(addRuleTapped), for: .touchUpInside)
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.dragInteractionEnabled = true
        tableView.dragDelegate = self
        tableView.dropDelegate = self
    }

    private func loadRules() {
        rules = RoutingPolicyManager.shared.loadRules()
        updateUI(persist: false)
    }

    private func saveRules() {
        RoutingPolicyManager.shared.saveRules(rules)
    }

    private func updateUI(persist: Bool = true) {
        emptyStateView.isHidden = !rules.isEmpty
        tableView.reloadData()
        if persist { saveRules() }
    }

    @objc private func addRuleTapped() {
        showRuleEditor(rule: nil)
    }

    private func showRuleEditor(rule: RoutingRule?) {
        let editor = RuleEditorViewController(existingRule: rule)
        editor.onSave = { [weak self] newRule in
            if let existingRule = rule,
               let index = self?.rules.firstIndex(where: { $0.id == existingRule.id }) {
                self?.rules[index] = newRule
            } else {
                self?.rules.append(newRule)
            }
            self?.updateUI()
        }
        let nav = UINavigationController(rootViewController: editor)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium()]
        }
        present(nav, animated: true)
    }
}

extension RulesViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rules.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RuleCell.identifier, for: indexPath) as? RuleCell else {
            return UITableViewCell()
        }
        let rule = rules[indexPath.row]
        cell.configure(with: rule)
        cell.onToggle = { [weak self] isOn in
            self?.rules[indexPath.row].isEnabled = isOn
            self?.saveRules()
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showRuleEditor(rule: rules[indexPath.row])
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, completion in
            self?.rules.remove(at: indexPath.row)
            self?.updateUI()
            completion(true)
        }
        delete.backgroundColor = AppColors.error
        return UISwipeActionsConfiguration(actions: [delete])
    }
}

// MARK: - Drag & Drop for reordering
extension RulesViewController: UITableViewDragDelegate, UITableViewDropDelegate {

    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let item = UIDragItem(itemProvider: NSItemProvider(object: rules[indexPath.row].id as NSString))
        return [item]
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        rules.swapAt(sourceIndexPath.row, destinationIndexPath.row)
        saveRules()
    }

    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {}
}

// MARK: - Rule Editor
class RuleEditorViewController: UIViewController {

    private let existingRule: RoutingRule?
    var onSave: ((RoutingRule) -> Void)?

    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        return scroll
    }()

    private let contentView = UIView()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "编辑规则"
        label.font = AppFonts.bold(size: 22)
        label.textColor = AppColors.textPrimary
        return label
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = AppColors.textPrimary
        return button
    }()

    private let matchTypeLabel: UILabel = sectionLabel("匹配类型")
    private let matchTypeControl: UISegmentedControl = {
        let items = RuleMatchType.allCases.map { $0.displayName }
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.selectedSegmentTintColor = AppColors.primary
        control.setTitleTextAttributes([.foregroundColor: AppColors.textPrimary], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        return control
    }()

    private let valueTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "例如: .github.com"
        tf.textColor = AppColors.textPrimary
        tf.backgroundColor = AppColors.cardBackground
        tf.layer.cornerRadius = AppConstants.smallCornerRadius
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        tf.leftViewMode = .always
        tf.attributedPlaceholder = NSAttributedString(string: "例如: .github.com", attributes: [.foregroundColor: AppColors.textSecondary])
        return tf
    }()

    private let actionLabel = sectionLabel("动作")
    private let actionControl: UISegmentedControl = {
        let items = RuleAction.allCases.map { $0.displayName }
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 1
        control.selectedSegmentTintColor = AppColors.primary
        control.setTitleTextAttributes([.foregroundColor: AppColors.textPrimary], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        return control
    }()

    private let noteTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "备注（可选）"
        tf.textColor = AppColors.textPrimary
        tf.backgroundColor = AppColors.cardBackground
        tf.layer.cornerRadius = AppConstants.smallCornerRadius
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        tf.leftViewMode = .always
        tf.attributedPlaceholder = NSAttributedString(string: "备注（可选）", attributes: [.foregroundColor: AppColors.textSecondary])
        return tf
    }()

    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("保存", for: .normal)
        button.titleLabel?.font = AppFonts.bold(size: 16)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = AppColors.primary
        button.layer.cornerRadius = AppConstants.smallCornerRadius
        return button
    }()

    private static func sectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = AppFonts.semibold(size: 13)
        label.textColor = AppColors.textSecondary
        return label
    }

    init(existingRule: RoutingRule?) {
        self.existingRule = existingRule
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        populateExisting()
    }

    private func setupUI() {
        view.backgroundColor = AppColors.background

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(titleLabel)
        contentView.addSubview(closeButton)
        contentView.addSubview(matchTypeLabel)
        contentView.addSubview(matchTypeControl)
        contentView.addSubview(valueTextField)
        contentView.addSubview(actionLabel)
        contentView.addSubview(actionControl)
        contentView.addSubview(noteTextField)
        contentView.addSubview(saveButton)

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(20)
        }

        closeButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-20)
            make.width.height.equalTo(30)
        }

        matchTypeLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(28)
            make.leading.equalToSuperview().offset(20)
        }

        matchTypeControl.snp.makeConstraints { make in
            make.top.equalTo(matchTypeLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(36)
        }

        valueTextField.snp.makeConstraints { make in
            make.top.equalTo(matchTypeControl.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(48)
        }

        actionLabel.snp.makeConstraints { make in
            make.top.equalTo(valueTextField.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(20)
        }

        actionControl.snp.makeConstraints { make in
            make.top.equalTo(actionLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(36)
        }

        noteTextField.snp.makeConstraints { make in
            make.top.equalTo(actionControl.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(48)
        }

        saveButton.snp.makeConstraints { make in
            make.top.equalTo(noteTextField.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(50)
            make.bottom.equalToSuperview().offset(-40)
        }

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
    }

    private func populateExisting() {
        guard let rule = existingRule else { return }
        titleLabel.text = "编辑规则"
        matchTypeControl.selectedSegmentIndex = RuleMatchType.allCases.firstIndex(of: rule.matchType) ?? 0
        valueTextField.text = rule.value
        actionControl.selectedSegmentIndex = RuleAction.allCases.firstIndex(of: rule.action) ?? 0
        noteTextField.text = rule.note
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        guard let value = valueTextField.text, !value.isEmpty else {
            let alert = UIAlertController(title: nil, message: "请输入匹配值", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            present(alert, animated: true)
            return
        }

        let rule = RoutingRule(
            id: existingRule?.id ?? UUID().uuidString,
            matchType: RuleMatchType.allCases[matchTypeControl.selectedSegmentIndex],
            value: value,
            action: RuleAction.allCases[actionControl.selectedSegmentIndex],
            note: noteTextField.text ?? "",
            isEnabled: existingRule?.isEnabled ?? true
        )
        onSave?(rule)
        dismiss(animated: true)
    }
}
