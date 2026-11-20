import UIKit
import SnapKit

protocol ConnectButtonDelegate: AnyObject {
    func connectButtonTapped()
}

class ConnectButton: UIView {

    weak var delegate: ConnectButtonDelegate?

    private var status: VPNStatus = .disconnected {
        didSet {
            updateUI()
        }
    }

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.cardBackground
        view.layer.cornerRadius = 80
        view.layer.borderWidth = 4
        view.layer.borderColor = AppColors.border.cgColor
        return view
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.semibold(size: 16)
        label.textColor = AppColors.textSecondary
        label.textAlignment = .center
        return label
    }()

    private let buttonLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.bold(size: 24)
        label.textColor = AppColors.textPrimary
        label.textAlignment = .center
        label.text = "连接"
        return label
    }()

    private var pulseLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(statusLabel)
        containerView.addSubview(buttonLabel)

        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(160)
        }

        statusLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(50)
        }

        buttonLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(10)
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(buttonTapped))
        containerView.addGestureRecognizer(tapGesture)
        containerView.isUserInteractionEnabled = true

        updateUI()
    }

    func setStatus(_ status: VPNStatus) {
        self.status = status
    }

    private func updateUI() {
        statusLabel.text = status.displayText
        buttonLabel.text = status.buttonText
        isUserInteractionEnabled = status != .connecting && status != .disconnecting
        alpha = isUserInteractionEnabled ? 1.0 : 0.85

        UIView.animate(withDuration: AppConstants.animationDuration) {
            switch self.status {
            case .connected:
                self.containerView.layer.borderColor = AppColors.success.cgColor
                self.containerView.backgroundColor = AppColors.success.withAlphaComponent(0.1)
            case .connecting, .disconnecting:
                self.containerView.layer.borderColor = AppColors.warning.cgColor
                self.containerView.backgroundColor = AppColors.warning.withAlphaComponent(0.1)
            case .disconnected, .invalid:
                self.containerView.layer.borderColor = AppColors.border.cgColor
                self.containerView.backgroundColor = AppColors.cardBackground
            }
        }

        if status == .connecting || status == .disconnecting {
            startPulseAnimation()
        } else {
            stopPulseAnimation()
        }
    }

    private func startPulseAnimation() {
        pulseLayer.removeFromSuperlayer()

        let pulse = CAShapeLayer()
        pulse.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 160, height: 160)).cgPath
        pulse.fillColor = UIColor.clear.cgColor
        pulse.strokeColor = AppColors.primary.cgColor
        pulse.lineWidth = 2
        pulse.opacity = 0

        containerView.layer.insertSublayer(pulse, at: 0)
        pulseLayer = pulse

        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1.0
        scaleAnimation.toValue = 1.3

        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0.8
        opacityAnimation.toValue = 0.0

        let group = CAAnimationGroup()
        group.animations = [scaleAnimation, opacityAnimation]
        group.duration = 1.5
        group.repeatCount = .infinity

        pulse.add(group, forKey: "pulse")
    }

    private func stopPulseAnimation() {
        pulseLayer.removeFromSuperlayer()
    }

    @objc private func buttonTapped() {
        UIView.animate(withDuration: 0.1, animations: {
            self.containerView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.containerView.transform = .identity
            }
        }

        delegate?.connectButtonTapped()
    }
}
