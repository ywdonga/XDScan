//
//  XDScanWrapper.swift
//  XDScan
//
//  Created by lbxia on 22/06/28.
//  Copyright © 2022年 dyw. All rights reserved.
//

import UIKit
import CoreGraphics
import AVFoundation

public class XDScanVC: UIViewController {
    
    /// 配置
    private var config: XDScanConfig
    /// 线条动画
    private let lineAnimation = XDScanLineAnimation.instance()

    private let captureSession = AVCaptureSession()
    private let dataOutput = AVCaptureMetadataOutput()
    
    private var _delayCount: Int = 0
    private let delayCount: Int = 15

    public weak var delegate: XDScanDelegate?

    public init(config: XDScanConfig) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        setupCaptureSession()
        addViedoPreviewLayer()
        addRoundCornerFrame()
        startScanningQRCode()
    }
    
    
    private func setupCaptureSession() {
        if captureSession.isRunning { return }
        guard let defaultDeviceInput = defaultCaptureInput,
              captureSession.canAddInput(defaultDeviceInput) else {
            delegate?.qrScannerDidFail(self, error: .inputFailed)
            self.dismiss(animated: true, completion: nil)
            return
        }
        captureSession.addInput(defaultDeviceInput)
            
        guard captureSession.canAddOutput(dataOutput) else {
            delegate?.qrScannerDidFail(self, error: .outoutFailed)
            self.dismiss(animated: true, completion: nil)
            return
        }
        captureSession.addOutput(dataOutput)
        dataOutput.metadataObjectTypes = dataOutput.availableMetadataObjectTypes
        dataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
    }
    
    /// 添加相机预览 及 预览镂空样式
    private func addViedoPreviewLayer() {
        /// 添加相机预览
        videoPreviewLayer.frame = CGRect(x: view.bounds.origin.x,
                                         y: view.bounds.origin.y,
                                         width: view.bounds.size.width,
                                         height: view.bounds.size.height)
        view.layer.insertSublayer(videoPreviewLayer, at: 0)
        /// 添加镂空样式
        let scanFrameWidth: CGFloat  = self.view.frame.size.width * config.maskScale
        let roundViewFrame = CGRect(origin: CGPoint(x: view.frame.midX - scanFrameWidth/2,
                                                    y: view.frame.midY - scanFrameWidth/2),
                                    size: CGSize(width: scanFrameWidth, height: scanFrameWidth))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = view.bounds
        maskLayer.fillColor = config.maskBgColor.cgColor
        let path = UIBezierPath(roundedRect: roundViewFrame, byRoundingCorners: [.allCorners], cornerRadii: CGSize(width: config.maskRadius, height: config.maskRadius))
        path.append(UIBezierPath(rect: view.bounds))
        maskLayer.path = path.cgPath
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        view.layer.insertSublayer(maskLayer, above: videoPreviewLayer)
        addHintTextLayer(maskLayer: maskLayer)
        /// 添加动画
        starLineAnimation(cropRect: roundViewFrame)
    }
    
    /// 添加提示文字
    private func addHintTextLayer(maskLayer: CAShapeLayer) {
        guard let hint = config.hint else { return }
        let hintTextLayer = CATextLayer()
        hintTextLayer.fontSize = config.hintSize
        hintTextLayer.string = hint
        hintTextLayer.alignmentMode = CATextLayerAlignmentMode.center
        hintTextLayer.contentsScale = UIScreen.main.scale
        hintTextLayer.frame = CGRect(x: 0,
                                     y: view.frame.midY - view.frame.size.height/4 - 62,
                                     width: view.frame.size.width,
                                     height: config.hintSize + 4)
        hintTextLayer.foregroundColor = config.hintColor.cgColor
        view.layer.insertSublayer(hintTextLayer, above: maskLayer)
    }
    
    /// 添加四角
    private func addRoundCornerFrame() {
        let width: CGFloat = self.view.frame.size.width * config.maskScale + config.thickness * 2
        let height: CGFloat = width
        let roundViewFrame = CGRect(origin: CGPoint(x: self.view.frame.midX - width/2,
                                                    y: self.view.frame.midY - height/2),
                                    size: CGSize(width: width, height: width))
        self.view.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        let qrFramedView = XDScanFrame(frame: roundViewFrame)
        qrFramedView.thickness = config.thickness
        qrFramedView.length = config.length
        qrFramedView.radius = config.radius
        qrFramedView.color = config.color
        qrFramedView.autoresizingMask = UIView.AutoresizingMask(rawValue: UInt(0.0))
        self.view.addSubview(qrFramedView)
    }
    
    
    /// 扫码动画
    /// - Parameter cropRect: 位置大小
    private func starLineAnimation(cropRect: CGRect) {
        lineAnimation.startAnimatingWithRect(animationRect: cropRect,
                                             parentView: view,
                                             image: config.animationImage)
    }
    
    /// 开始扫码
    private func startScanningQRCode() {
        guard !captureSession.isRunning else { return }
        captureSession.startRunning()
    }
    
    
    /// 相机设备
    private lazy var defaultDevice: AVCaptureDevice? = {
        guard let device = AVCaptureDevice.default(for: .video) else { return nil }
        return device
    }()

    
    /// 相机输出
    private lazy var defaultCaptureInput: AVCaptureInput? = {
        guard let captureDevice = defaultDevice else { return nil }
        return try? AVCaptureDeviceInput(device: captureDevice)
    }()
    
    /// 相机画面显示
    private lazy var videoPreviewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        return layer
    }()
}

extension XDScanVC: AVCaptureMetadataOutputObjectsDelegate {
    
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        for data in metadataObjects {
            let transformed = videoPreviewLayer.transformedMetadataObject(for: data) as? AVMetadataMachineReadableCodeObject
            if let unwraped = transformed {
                if view.bounds.contains(unwraped.bounds) {
                    _delayCount = _delayCount + 1
                    if _delayCount > delayCount {
                        if let unwrapedStringValue = unwraped.stringValue {
                            delegate?.qrScanner(self, scanDidComplete: unwrapedStringValue)
                        } else {
                            delegate?.qrScannerDidFail(self, error: .emptyResult)
                        }
                        captureSession.stopRunning()
                        if let nav = self.navigationController {
                            nav.popViewController(animated: true)
                        }else{
                            dismiss(animated: true, completion: nil)
                        }
                    }
                }
            }
        }
    }

}

// MARK: ----- 错误枚举
public enum XDScanError: Error {
    case inputFailed
    case outoutFailed
    case emptyResult
}

// MARK: ----- 代理
public protocol XDScanDelegate: AnyObject {
    func qrScanner(_ controller: UIViewController, scanDidComplete result: String)
    func qrScannerDidFail(_ controller: UIViewController,  error: XDScanError)
    func qrScannerDidCancel(_ controller: UIViewController)
}

// MARK: ----- 识别图片中二维码
extension UIImage {
    
    /// 解析二维码
    /// - Returns: 二维码内容
    func parseQRCode() -> String? {
        guard let image = CIImage(image: self) else { return nil }
        let detector = CIDetector(ofType: CIDetectorTypeQRCode,
                                  context: nil,
                                  options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        let features = detector?.features(in: image) ?? []
        return features.compactMap { feature in
            return (feature as? CIQRCodeFeature)?.messageString
        }.joined()
    }
    
}
