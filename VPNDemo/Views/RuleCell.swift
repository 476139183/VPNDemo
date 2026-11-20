import UIKit
import SnapKit

class RuleCell: UITableViewCell {

    static let identifier = "RuleCell"

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.cardBackground
        view.layer.cornerRadius = AppConstants.cornerRadius
        return view
    }()

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = AppColors.primary
        return imageView
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.semibold(size: 15)
        label.textColor = AppColors.textPrimary
        return label
    }()

    private let noteLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.regular(size: 12)
        label.textColor = AppColors.textSecondary
        return label
    }()

    private let typeBadge: UILabel = {
        let label = UILabel()
        label.font = AppFonts.medium(size: 10)
        label.textColor = AppColors.textSecondary
        label.backgroundColor = AppColors.border.withAlphaComponent(0.3)
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        label.textAlignment = .center
        return label
    }()

    private let actionLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.bold(size: 12)
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        return label
    }()

    private let toggle: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = AppColors.primary
        toggle.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        return toggle
    }()

    var onToggle: ((Bool) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(containerView)
        containerView.addSubview(iconView)
        containerView.addSubview(valueLabel)
        containerView.addSubview(noteLabel)
        containerView.addSubview(typeBadge)
        containerView.addSubview(actionLabel)
        containerView.addSubview(toggle)

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 3, left: 16, bottom: 3, right: 16))
            make.height.equalTo(64)
        }

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(22)
        }

        valueLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(10)
            make.top.equalToSuperview().offset(12)
            make.trailing.equalTo(toggle.snp.leading).offset(-8)
        }

        noteLabel.snp.makeConstraints { make in
            make.leading.equalTo(valueLabel)
            make.top.equalTo(valueLabel.snp.bottom).offset(2)
        }

        typeBadge.snp.makeConstraints { make in
            make.leading.equalTo(noteLabel.snp.trailing).offset(6)
            make.centerY.equalTo(noteLabel)
            make.height.equalTo(18)
            make.width.greaterThanOrEqualTo(32)
        }

        actionLabel.snp.makeConstraints { make in
            make.leading.equalTo(typeBadge.snp.trailing).offset(6)
            make.centerY.equalTo(noteLabel)
            make.height.equalTo(18)
            make.width.equalTo(42)
        }

        toggle.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
        }

        toggle.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)
    }

    func configure(with rule: RoutingRule) {
        valueLabel.text = rule.value
        noteLabel.text = rule.note.isEmpty ? rule.matchType.displayName : rule.note

        typeBadge.text = rule.matchType.displayName
        typeBadge.isHidden = !rule.note.isEmpty

        switch rule.action {
        case .proxy:
            actionLabel.text = "VPN"
            actionLabel.textColor = AppColors.primary
            actionLabel.backgroundColor = AppColors.primary.withAlphaComponent(0.15)
        case .direct:
            actionLabel.text = "直连"
            actionLabel.textColor = AppColors.warning
            actionLabel.backgroundColor = AppColors.warning.withAlphaComponent(0.15)
        }

        let iconName = rule.action == .proxy ? "lock.shield" : "arrow.right.arrow.left"
        iconView.image = UIImage(systemName: iconName)
        iconView.tintColor = rule.action == .proxy ? AppColors.primary : AppColors.warning

        toggle.isOn = rule.isEnabled
        containerView.alpha = rule.isEnabled ? 1.0 : 0.55
    }

    @objc private func toggleChanged() {
        onToggle?(toggle.isOn)
        UIView.animate(withDuration: 0.2) {
            self.containerView.alpha = self.toggle.isOn ? 1.0 : 0.55
        }
    }
}
