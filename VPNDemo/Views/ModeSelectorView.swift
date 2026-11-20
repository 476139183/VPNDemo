import UIKit
import SnapKit

protocol ModeSelectorDelegate: AnyObject {
    func modeDidChange(_ mode: VPNMode)
}

class ModeSelectorView: UIView {

    weak var delegate: ModeSelectorDelegate?

    private var selectedMode: VPNMode = .smart {
        didSet { updateSelection() }
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "连接模式"
        label.font = AppFonts.semibold(size: 18)
        label.textColor = AppColors.textPrimary
        return label
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        addSubview(titleLabel)
        addSubview(stackView)

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }

        stackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }

        for mode in VPNMode.allCases {
            let card = ModeCardView(mode: mode)
            card.delegate = self
            stackView.addArrangedSubview(card)
        }

        updateSelection()
    }

    func setMode(_ mode: VPNMode) {
        selectedMode = mode
    }

    private func updateSelection() {
        for case let card as ModeCardView in stackView.arrangedSubviews {
            card.isSelected = card.mode == selectedMode
        }
    }
}

// MARK: - ModeCardView
protocol ModeCardDelegate: AnyObject {
    func modeCardTapped(_ mode: VPNMode)
}

class ModeCardView: UIView {

    let mode: VPNMode
    weak var delegate: ModeCardDelegate?

    var isSelected: Bool = false {
        didSet { updateAppearance() }
    }

    private let iconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28)
        label.textAlignment = .center
        return label
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.medium(size: 13)
        label.textAlignment = .center
        label.textColor = AppColors.textPrimary
        return label
    }()

    private let descLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.regular(size: 10)
        label.textAlignment = .center
        label.textColor = AppColors.textSecondary
        label.numberOfLines = 2
        return label
    }()

    init(mode: VPNMode) {
        self.mode = mode
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = AppColors.cardBackground
        layer.cornerRadius = AppConstants.cornerRadius
        layer.borderWidth = 1.5
        layer.borderColor = AppColors.border.cgColor

        let mapping: [VPNMode: String] = [
            .smart: "🔀",
            .globalOutbound: "🌍",
            .globalInbound: "🏠"
        ]
        iconLabel.text = mapping[mode]
        nameLabel.text = mode.displayName
        descLabel.text = mode.subtitle

        addSubview(iconLabel)
        addSubview(nameLabel)
        addSubview(descLabel)

        iconLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.centerX.equalToSuperview()
            make.height.equalTo(32)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(iconLabel.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(4)
        }

        descLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview().inset(6)
            make.bottom.equalToSuperview().offset(-10)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tap)

        updateAppearance()
    }

    private func updateAppearance() {
        UIView.animate(withDuration: 0.2) {
            self.layer.borderColor = self.isSelected ? AppColors.primary.cgColor : AppColors.border.cgColor
            self.backgroundColor = self.isSelected ? AppColors.primary.withAlphaComponent(0.1) : AppColors.cardBackground
            self.nameLabel.textColor = self.isSelected ? AppColors.primaryHighlight : AppColors.textPrimary
        }
    }

    @objc private func didTap() {
        delegate?.modeCardTapped(mode)
    }
}

extension ModeSelectorView: ModeCardDelegate {
    func modeCardTapped(_ mode: VPNMode) {
        selectedMode = mode
        delegate?.modeDidChange(mode)
    }
}
