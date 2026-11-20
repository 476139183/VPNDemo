import UIKit
import AVFoundation
import SnapKit

protocol QRScannerViewControllerDelegate: AnyObject {
    func qrScanner(_ scanner: QRScannerViewController, didScan nodes: [ServerNode])
    func qrScannerDidCancel(_ scanner: QRScannerViewController)
}

final class QRScannerViewController: UIViewController {

    weak var delegate: QRScannerViewControllerDelegate?

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasHandledResult = false

    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        return view
    }()

    private let scanFrameView: UIView = {
        let view = UIView()
        view.layer.borderColor = AppColors.primary.cgColor
        view.layer.borderWidth = 2
        view.layer.cornerRadius = 12
        view.backgroundColor = .clear
        return view
    }()

    private let hintLabel: UILabel = {
        let label = UILabel()
        label.text = "将节点二维码放入框内"
        label.font = AppFonts.medium(size: 15)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .white
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupOverlay()
        requestCameraAndStart()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hasHandledResult = false
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning {
            session.stopRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        updateOverlayMask()
    }

    private func setupOverlay() {
        view.addSubview(overlayView)
        view.addSubview(scanFrameView)
        view.addSubview(hintLabel)
        view.addSubview(closeButton)

        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        scanFrameView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(240)
        }

        hintLabel.snp.makeConstraints { make in
            make.top.equalTo(scanFrameView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            make.trailing.equalToSuperview().offset(-16)
            make.width.height.equalTo(36)
        }

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }

    private func updateOverlayMask() {
        let path = UIBezierPath(rect: overlayView.bounds)
        let hole = UIBezierPath(roundedRect: scanFrameView.frame, cornerRadius: 12)
        path.append(hole)
        path.usesEvenOddFillRule = true
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        mask.fillRule = .evenOdd
        overlayView.layer.mask = mask
    }

    private func requestCameraAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.configureSession()
                    } else {
                        self?.showPermissionDenied()
                    }
                }
            }
        default:
            showPermissionDenied()
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            showAlert(title: "无法启动相机", message: "当前设备不支持扫码")
            return
        }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            showAlert(title: "无法启动扫码", message: "初始化失败")
            return
        }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output.metadataObjectTypes = [.qr]

        session.commitConfiguration()

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.insertSublayer(layer, at: 0)
        previewLayer = layer

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    private func showPermissionDenied() {
        let alert = UIAlertController(
            title: "需要相机权限",
            message: "请在设置中允许 VPNDemo 访问相机以扫描节点二维码",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.qrScannerDidCancel(self)
            self.dismiss(animated: true)
        })
        alert.addAction(UIAlertAction(title: "去设置", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        present(alert, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.qrScannerDidCancel(self)
            self.dismiss(animated: true)
        })
        present(alert, animated: true)
    }

    @objc private func closeTapped() {
        delegate?.qrScannerDidCancel(self)
        dismiss(animated: true)
    }

    private func handleScannedString(_ string: String) {
        guard !hasHandledResult else { return }
        hasHandledResult = true
        session.stopRunning()

        do {
            let nodes = try ServerNodeQRParser.parse(string)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                self.delegate?.qrScanner(self, didScan: nodes)
            }
        } catch {
            hasHandledResult = false
            let alert = UIAlertController(
                title: "解析失败",
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "继续扫码", style: .default) { [weak self] _ in
                DispatchQueue.global(qos: .userInitiated).async {
                    self?.session.startRunning()
                }
            })
            present(alert, animated: true)
        }
    }
}

extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              object.type == .qr,
              let value = object.stringValue else {
            return
        }
        handleScannedString(value)
    }
}
