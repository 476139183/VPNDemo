import UIKit
import SnapKit

class RegisterViewController: UIViewController {

    var onRegisterSuccess: (() -> Void)?

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    private let contentView = UIView()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = AppColors.textPrimary
        return button
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "注册"
        label.font = AppFonts.bold(size: 28)
        label.textColor = AppColors.textPrimary
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "注册送体验流量"
        label.font = AppFonts.regular(size: 14)
        label.textColor = AppColors.textSecondary
        return label
    }()

    private let segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["手机号注册", "邮箱注册"])
        control.selectedSegmentIndex = 0
        control.selectedSegmentTintColor = AppColors.primary
        control.setTitleTextAttributes([.foregroundColor: AppColors.textPrimary], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        return control
    }()

    private let phoneTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "请输入手机号"
        textField.keyboardType = .phonePad
        textField.textColor = AppColors.textPrimary
        textField.backgroundColor = AppColors.cardBackground
        textField.layer.cornerRadius = AppConstants.smallCornerRadius
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftViewMode = .always
        textField.attributedPlaceholder = NSAttributedString(
            string: "请输入手机号",
            attributes: [.foregroundColor: AppColors.textSecondary]
        )
        return textField
    }()

    private let emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "请输入邮箱"
        textField.keyboardType = .emailAddress
        textField.textColor = AppColors.textPrimary
        textField.backgroundColor = AppColors.cardBackground
        textField.layer.cornerRadius = AppConstants.smallCornerRadius
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftViewMode = .always
        textField.isHidden = true
        textField.attributedPlaceholder = NSAttributedString(
            string: "请输入邮箱",
            attributes: [.foregroundColor: AppColors.textSecondary]
        )
        return textField
    }()

    private let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "设置密码（至少6位）"
        textField.isSecureTextEntry = true
        textField.textColor = AppColors.textPrimary
        textField.backgroundColor = AppColors.cardBackground
        textField.layer.cornerRadius = AppConstants.smallCornerRadius
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftViewMode = .always
        textField.attributedPlaceholder = NSAttributedString(
            string: "设置密码（至少6位）",
            attributes: [.foregroundColor: AppColors.textSecondary]
        )
        return textField
    }()

    private let confirmPasswordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "确认密码"
        textField.isSecureTextEntry = true
        textField.textColor = AppColors.textPrimary
        textField.backgroundColor = AppColors.cardBackground
        textField.layer.cornerRadius = AppConstants.smallCornerRadius
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftViewMode = .always
        textField.attributedPlaceholder = NSAttributedString(
            string: "确认密码",
            attributes: [.foregroundColor: AppColors.textSecondary]
        )
        return textField
    }()

    private let codeTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "请输入验证码"
        textField.keyboardType = .numberPad
        textField.textColor = AppColors.textPrimary
        textField.backgroundColor = AppColors.cardBackground
        textField.layer.cornerRadius = AppConstants.smallCornerRadius
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftViewMode = .always
        textField.attributedPlaceholder = NSAttributedString(
            string: "请输入验证码",
            attributes: [.foregroundColor: AppColors.textSecondary]
        )
        return textField
    }()

    private let sendCodeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("发送验证码", for: .normal)
        button.titleLabel?.font = AppFonts.medium(size: 14)
        button.setTitleColor(AppColors.primary, for: .normal)
        return button
    }()

    private let inviteCodeTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "邀请码（可选）"
        textField.textColor = AppColors.textPrimary
        textField.backgroundColor = AppColors.cardBackground
        textField.layer.cornerRadius = AppConstants.smallCornerRadius
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftViewMode = .always
        textField.attributedPlaceholder = NSAttributedString(
            string: "邀请码（可选）",
            attributes: [.foregroundColor: AppColors.textSecondary]
        )
        return textField
    }()

    private let registerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("注册并领取体验", for: .normal)
        button.titleLabel?.font = AppFonts.bold(size: 16)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = AppColors.primary
        button.layer.cornerRadius = AppConstants.smallCornerRadius
        return button
    }()

    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("已有账号？立即登录", for: .normal)
        button.titleLabel?.font = AppFonts.regular(size: 14)
        button.setTitleColor(AppColors.primary, for: .normal)
        return button
    }()

    private var isPhoneRegister = true

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }

    private func setupUI() {
        view.backgroundColor = AppColors.background

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(closeButton)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(segmentedControl)
        contentView.addSubview(phoneTextField)
        contentView.addSubview(emailTextField)
        contentView.addSubview(passwordTextField)
        contentView.addSubview(confirmPasswordTextField)
        contentView.addSubview(codeTextField)
        contentView.addSubview(sendCodeButton)
        contentView.addSubview(inviteCodeTextField)
        contentView.addSubview(registerButton)
        contentView.addSubview(loginButton)

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-20)
            make.width.height.equalTo(30)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(40)
            make.leading.equalToSuperview().offset(20)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(20)
        }

        segmentedControl.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(36)
        }

        phoneTextField.snp.makeConstraints { make in
            make.top.equalTo(segmentedControl.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }

        emailTextField.snp.makeConstraints { make in
            make.top.equalTo(segmentedControl.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }

        passwordTextField.snp.makeConstraints { make in
            make.top.equalTo(phoneTextField.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }

        confirmPasswordTextField.snp.makeConstraints { make in
            make.top.equalTo(passwordTextField.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }

        codeTextField.snp.makeConstraints { make in
            make.top.equalTo(confirmPasswordTextField.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(20)
            make.width.equalToSuperview().multipliedBy(0.55)
            make.height.equalTo(50)
        }

        sendCodeButton.snp.makeConstraints { make in
            make.centerY.equalTo(codeTextField)
            make.trailing.equalToSuperview().offset(-20)
            make.width.equalTo(100)
            make.height.equalTo(30)
        }

        inviteCodeTextField.snp.makeConstraints { make in
            make.top.equalTo(codeTextField.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }

        registerButton.snp.makeConstraints { make in
            make.top.equalTo(inviteCodeTextField.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }

        loginButton.snp.makeConstraints { make in
            make.top.equalTo(registerButton.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-40)
        }
    }

    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        sendCodeButton.addTarget(self, action: #selector(sendCodeTapped), for: .touchUpInside)
        registerButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func segmentChanged() {
        isPhoneRegister = segmentedControl.selectedSegmentIndex == 0

        UIView.animate(withDuration: 0.2) {
            self.phoneTextField.isHidden = !self.isPhoneRegister
            self.emailTextField.isHidden = self.isPhoneRegister

            if self.isPhoneRegister {
                self.passwordTextField.snp.remakeConstraints { make in
                    make.top.equalTo(self.phoneTextField.snp.bottom).offset(16)
                    make.leading.trailing.equalToSuperview().inset(20)
                    make.height.equalTo(50)
                }
            } else {
                self.passwordTextField.snp.remakeConstraints { make in
                    make.top.equalTo(self.emailTextField.snp.bottom).offset(16)
                    make.leading.trailing.equalToSuperview().inset(20)
                    make.height.equalTo(50)
                }
            }
            self.view.layoutIfNeeded()
        }
    }

    @objc private func sendCodeTapped() {
        guard let phone = phoneTextField.text, phone.count == 11 else {
            showAlert(message: "请输入正确的手机号")
            return
        }

        sendCodeButton.isEnabled = false
        var countdown = 60

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            countdown -= 1
            if countdown <= 0 {
                timer.invalidate()
                self?.sendCodeButton.setTitle("发送验证码", for: .normal)
                self?.sendCodeButton.isEnabled = true
            } else {
                self?.sendCodeButton.setTitle("\(countdown)s", for: .normal)
            }
        }

        showAlert(message: "验证码已发送 (演示: 123456)")
    }

    @objc private func registerTapped() {
        dismissKeyboard()

        let phone = phoneTextField.text ?? ""
        let email = emailTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        let confirmPassword = confirmPasswordTextField.text ?? ""
        let code = codeTextField.text ?? ""

        if isPhoneRegister {
            guard phone.count == 11 else {
                showAlert(message: "请输入正确的手机号")
                return
            }
        } else {
            guard email.contains("@") else {
                showAlert(message: "请输入正确的邮箱")
                return
            }
        }

        guard password.count >= 6 else {
            showAlert(message: "密码至少6位")
            return
        }

        guard password == confirmPassword else {
            showAlert(message: "两次密码不一致")
            return
        }

        guard code.count == 6 || code == "123456" else {
            showAlert(message: "请输入验证码")
            return
        }

        UserManager.shared.register(
            phone: isPhoneRegister ? phone : nil,
            email: isPhoneRegister ? nil : email,
            password: password,
            inviteCode: inviteCodeTextField.text
        ) { [weak self] result in
            switch result {
            case .success:
                self?.showAlert(message: "注册成功！已赠送体验流量") {
                    self?.onRegisterSuccess?()
                }
            case .failure(let error):
                self?.showAlert(message: error.localizedDescription)
            }
        }
    }

    @objc private func loginTapped() {
        let loginVC = LoginViewController()
        loginVC.onLoginSuccess = { [weak self] in
            self?.onRegisterSuccess?()
        }
        let nav = UINavigationController(rootViewController: loginVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func showAlert(message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}
