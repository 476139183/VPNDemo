import UIKit
import SnapKit

class ServerCell: UITableViewCell {

    static let identifier = "ServerCell"

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.cardBackground
        view.layer.cornerRadius = AppConstants.cornerRadius
        return view
    }()

    private let flagLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28)
        return label
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.semibold(size: 16)
        label.textColor = AppColors.textPrimary
        return label
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.regular(size: 12)
        label.textColor = AppColors.textSecondary
        return label
    }()

    private let typeBadge: UILabel = {
        let label = UILabel()
        label.font = AppFonts.bold(size: 9)
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        return label
    }()

    private let checkmarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "checkmark.circle.fill")
        imageView.tintColor = AppColors.primary
        imageView.isHidden = true
        return imageView
    }()

    private let latencyIndicator: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        return view
    }()

    private let latencyLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.regular(size: 10)
        label.textColor = AppColors.textSecondary
        return label
    }()

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
        containerView.addSubview(flagLabel)
        containerView.addSubview(nameLabel)
        containerView.addSubview(typeBadge)
        containerView.addSubview(statusLabel)
        containerView.addSubview(checkmarkImageView)
        containerView.addSubview(latencyIndicator)
        containerView.addSubview(latencyLabel)

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16))
            make.height.equalTo(64)
        }

        flagLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(36)
        }

        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(flagLabel.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(12)
        }

        typeBadge.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel.snp.trailing).offset(8)
            make.centerY.equalTo(nameLabel)
            make.height.equalTo(18)
            make.width.equalTo(52)
        }

        statusLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
        }

        latencyIndicator.snp.makeConstraints { make in
            make.leading.equalTo(statusLabel.snp.trailing).offset(8)
            make.centerY.equalTo(statusLabel)
            make.width.height.equalTo(8)
        }

        latencyLabel.snp.makeConstraints { make in
            make.leading.equalTo(latencyIndicator.snp.trailing).offset(4)
            make.centerY.equalTo(latencyIndicator)
        }

        checkmarkImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
    }

    func configure(with node: ServerNode, isVPNConnected: Bool = false) {
        flagLabel.text = node.countryCodeFlag
        nameLabel.text = node.name

        let isCustom = ServerNodeStore.isCustom(id: node.id)
        if node.isSelected && isVPNConnected {
            statusLabel.text = isCustom ? "扫码节点 · 使用中" : "使用中"
            statusLabel.textColor = AppColors.success
        } else if node.isSelected {
            statusLabel.text = isCustom ? "扫码节点 · 已选择" : "已选择"
            statusLabel.textColor = AppColors.primary
        } else {
            statusLabel.text = isCustom ? "扫码添加 · 点击选择" : "点击选择"
            statusLabel.textColor = AppColors.textSecondary
        }

        typeBadge.text = node.serverType.displayName
        typeBadge.textColor = node.serverType == .outbound ? AppColors.primary : AppColors.warning
        typeBadge.backgroundColor = (node.serverType == .outbound ? AppColors.primary : AppColors.warning).withAlphaComponent(0.15)

        checkmarkImageView.isHidden = !node.isSelected

        if node.isSelected {
            containerView.layer.borderWidth = 1
            containerView.layer.borderColor = AppColors.primary.cgColor
        } else {
            containerView.layer.borderWidth = 0
        }

        if let latency = node.latency {
            latencyIndicator.isHidden = false
            latencyLabel.text = "\(latency)ms"
            latencyLabel.isHidden = false
            if latency < 50 {
                latencyIndicator.backgroundColor = AppColors.success
            } else if latency < 100 {
                latencyIndicator.backgroundColor = AppColors.warning
            } else {
                latencyIndicator.backgroundColor = AppColors.error
            }
        } else {
            latencyIndicator.isHidden = true
            latencyLabel.isHidden = true
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        UIView.animate(withDuration: 0.1) {
            self.containerView.alpha = highlighted ? 0.7 : 1.0
        }
    }
}
