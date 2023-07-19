//
//  XDScan.swift
//  XDScan
//
//  Created by dyw on 22/06/28.
//  Copyright © 2022年 dongyouwei. All rights reserved.
//

import UIKit
import CoreGraphics
import AVFoundation

public class XDScan: NSObject {
    /// 基础配置
    private var config: XDScanConfig
    /// 初始焦距，默认1
    private var factor = 1.0
    private let captureSession = AVCaptureSession()
    
    public var isRunning: Bool {
        return captureSession.isRunning
    }
    
    private let dataOutput = AVCaptureMetadataOutput()
    
    public weak var dataSource: XDScanDataSource?
    public weak var delegate: XDScanDelegate?
    public var eventBlock: ((XDScanEvent)->())?
    /// 是否开启自动调整焦距
    public var factorEnable = true
    /// 自动调焦间隔时间，默认与扫码动画时间一致
    public var factorLoopTime = 1.7
    /// 每次增加倍数
    public var stepMultiple = 0.3
    /// 初始化
    /// - Parameters:
    ///   - config: 基础配置
    ///   - dataSource: UI配置
    ///   - delegate: 扫码结果代理
    public init(config: XDScanConfig,
                dataSource: XDScanDataSource,
                delegate: XDScanDelegate? = nil) {
        self.config = config
        self.dataSource = dataSource
        self.delegate = delegate
        super.init()
        setupCaptureSession()
    }
    
    /// 初始化相机设备
    private func setupCaptureSession() {
        if captureSession.isRunning { return }
        guard let defaultDeviceInput = defaultCaptureInput,
              captureSession.canAddInput(defaultDeviceInput) else {
            let event = XDScanEvent.fail(.inputFailed)
            delegate?.qrScanEvent(event)
            eventBlock?(event)
            print("XDScan->\(event)")
            return
        }
        captureSession.addInput(defaultDeviceInput)
            
        guard captureSession.canAddOutput(dataOutput) else {
            let event = XDScanEvent.fail(.outoutFailed)
            delegate?.qrScanEvent(event)
            eventBlock?(event)
            print("XDScan->\(event)")
            return
        }
        captureSession.sessionPreset = .hd1920x1080
        captureSession.addOutput(dataOutput)
        dataOutput.metadataObjectTypes = [.qr]
        dataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
    }
    
    /// 添加相机预览 及 预览镂空样式
    public func addViedoPreviewLayer() {
        guard let atView = dataSource?.previewView() else {
            return
        }
        /// 添加相机预览
        videoPreviewLayer.frame = CGRect(x: atView.bounds.origin.x,
                                         y: atView.bounds.origin.y,
                                         width: atView.bounds.size.width,
                                         height: atView.bounds.size.height)
        atView.layer.insertSublayer(videoPreviewLayer, at: 0)
        /// 添加镂空样式
        let scanFrameWidth: CGFloat  = atView.frame.size.width * config.maskScale
        let roundViewFrame = CGRect(origin: CGPoint(x: atView.frame.midX - scanFrameWidth/2,
                                                    y: atView.frame.midY - scanFrameWidth/2 + config.offsetY),
                                    size: CGSize(width: scanFrameWidth, height: scanFrameWidth))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = atView.bounds
        maskLayer.fillColor = config.maskBgColor.cgColor
        let path = UIBezierPath(roundedRect: roundViewFrame, byRoundingCorners: [.allCorners], cornerRadii: CGSize(width: config.maskRadius, height: config.maskRadius))
        path.append(UIBezierPath(rect: atView.bounds))
        maskLayer.path = path.cgPath
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        atView.layer.insertSublayer(maskLayer, above: videoPreviewLayer)
        /// 添加提示文字
        addHintTextLayer(maskLayer: maskLayer, cropRect: roundViewFrame)
        /// 添加动画
        starLineAnimation(cropRect: roundViewFrame)
        /// 添加添加边框
        addRoundCornerFrame(atView: atView)
    }
    
    /// 添加提示文字
    private func addHintTextLayer(maskLayer: CAShapeLayer, cropRect: CGRect) {
        guard let atView = dataSource?.previewView() else {
            return
        }
        guard let hint = config.hint else { return }
        let hintTextLayer = CATextLayer()
        hintTextLayer.fontSize = config.hintSize
        hintTextLayer.string = hint
        hintTextLayer.alignmentMode = CATextLayerAlignmentMode.center
        hintTextLayer.contentsScale = UIScreen.main.scale
        let hitHeight = config.hintSize + 4
        let hintY = config.hintIsTop ? (cropRect.minY - config.hintEdge - hitHeight) : (cropRect.maxY + config.hintEdge)
        hintTextLayer.frame = CGRect(x: 0,
                                     y: hintY,
                                     width: atView.frame.size.width,
                                     height: hitHeight)
        hintTextLayer.foregroundColor = config.hintColor.cgColor
        atView.layer.insertSublayer(hintTextLayer, above: maskLayer)
    }
    
    /// 添加边框
    private func addRoundCornerFrame(atView: UIView) {
        let width: CGFloat = atView.frame.size.width * config.maskScale + config.thickness * 2
        let height: CGFloat = width
        let roundViewFrame = CGRect(origin: CGPoint(x: atView.frame.midX - width/2,
                                                    y: atView.frame.midY - height/2 + config.offsetY),
                                    size: CGSize(width: width, height: width))
        guard let frameView = dataSource?.frameView(rect: roundViewFrame) else {
            return
        }
        frameView.autoresizingMask = UIView.AutoresizingMask(rawValue: UInt(0.0))
        atView.addSubview(frameView)
    }
    
    /// 扫码动画
    /// - Parameter cropRect: 位置大小
    private func starLineAnimation(cropRect: CGRect) {
        guard let atView = dataSource?.previewView(),
              let animationView = dataSource?.animationView(rect: cropRect) else {
            return
        }
        atView.addSubview(animationView)
        animationView.startAnimatingWithRect(animationRect: cropRect)
    }
    
    /// 开始扫码
    public func startScanning() {
        guard !captureSession.isRunning else { return }
        captureSession.startRunning()
        enableFocus(true)
    }
    
    /// 停止扫码
    public func stopScanning() {
        enableFocus(false)
        captureSession.stopRunning()
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

extension XDScan {
    
    /// 设置自动对焦是否开启
    /// - Parameter enable: 是否开启自动对焦
    private func enableFocus(_ enable: Bool) {
        XDScan.cancelPreviousPerformRequests(withTarget: self)
        guard factorEnable, enable else { /// 如果上次有变焦，需要重置
            guard let device = defaultDevice, factor > 1 else { return }
            factor = 1
            do {
                try device.lockForConfiguration()
                device.ramp(toVideoZoomFactor: factor, withRate: 1.0)
                device.unlockForConfiguration()
            } catch {
                print("lockForConfiguration error")
            }
            return
        }
        factor = 1
//        tofocus()
    }
    
    // 循环自动对焦
//   @objc func tofocus() {
//       guard let device = defaultDevice else { return }
//       factor += stepMultiple
//       if factor > 3 {
//           factor = 3
//       }
//        do {
//            let focusPoint = CGPoint(x: 0.5, y: 0.5)
//            try device.lockForConfiguration()
//            device.ramp(toVideoZoomFactor: factor, withRate: 1.0)
//            if device.isFocusModeSupported(.autoFocus) {
//                device.focusPointOfInterest = focusPoint
//                device.focusMode = .autoFocus
//            }
//
//            if device.isExposureModeSupported(.autoExpose) {
//                device.exposurePointOfInterest = focusPoint
//                device.exposureMode = .autoExpose
//            }
//            device.unlockForConfiguration()
//        } catch {
//            print("lockForConfiguration error")
//        }
//       perform(#selector(tofocus), with: self, afterDelay: factorLoopTime)
//    }
    
}

extension XDScan: AVCaptureMetadataOutputObjectsDelegate {
    
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              metadataObj.type == AVMetadataObject.ObjectType.qr else {
            return
        }
        guard let atView = dataSource?.previewView() else {
            return
        }
        guard let barCodeObject = videoPreviewLayer.transformedMetadataObject(for: metadataObj), atView.bounds.contains(barCodeObject.bounds) else {
            return
        }
        if let resut = metadataObj.stringValue {
            let event = XDScanEvent.scanFinish(resut)
            delegate?.qrScanEvent(event)
            eventBlock?(event)
            print("XDScan->\(event)")
        } else {
            let event = XDScanEvent.fail(.emptyResult)
            delegate?.qrScanEvent(event)
            print("XDScan->\(event)")
        }
        captureSession.stopRunning()
    }
}

extension XDScan {
    
    // 相机权限
    public static func cameraAuth(_ handler: @escaping ((Bool) -> Void)) {
        AVCaptureDevice.requestAccess(for: .video) { result in
            DispatchQueue.main.async {
                var selected: Bool = false
                if result {
                    // 允许访问相机
                    selected = true
                } else {
                    // 不允许访问相机
                    selected = false
                }
                handler(selected)
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

// MARK: ----- 事件枚举
public enum XDScanEvent {
    case scanFinish(_ resut: String)
    case fail(_ error: XDScanError)
    case cancel
}

// MARK: ----- 代理
public protocol XDScanDataSource: AnyObject {
    /// 相机预览所在的View
    /// - Returns: view
    func previewView() -> UIView
    
    /// 边框View
    /// - Parameter rect: 边框大小位置
    /// - Returns: 边框view
    func frameView(rect: CGRect) -> UIView?
    
    /// 动画View
    /// - Parameter rect: 动画大小位置
    /// - Returns: 动画view
    func animationView(rect: CGRect) -> XDScanAnimation?
}

public protocol XDScanDelegate: AnyObject {
    func qrScanEvent(_ event:XDScanEvent)
}

public protocol XDScanAnimation: UIView {
    func startAnimatingWithRect(animationRect: CGRect)
    func stopStepAnimating()
}

// MARK: ----- 识别图片中二维码
extension UIImage {
    
    /// 解析二维码
    /// - Returns: 二维码内容
    public func parseQRCode() -> String? {
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

// MARK: ----- 资源获取
extension XDScan {
    
    static var bundle: Bundle = {
        let bundle = Bundle.init(path: Bundle.init(for: XDScan.self).path(forResource: "XDScan", ofType: "bundle", inDirectory: nil)!)
        return bundle!
    }()
       
    public static func getBundleImg(with name: String) -> UIImage? {
        var image = UIImage(named: name, in: bundle, compatibleWith: nil)
        if image == nil {
            image = UIImage(named: name)
        }
        return image
    }
    
}
