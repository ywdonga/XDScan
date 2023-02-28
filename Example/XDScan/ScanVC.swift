//
//  ScanVC.swift
//  XDScan_Example
//
//  Created by dyw on 2022/6/29.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import XDScan
import PhotosUI

class ScanVC: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate  {

    /// 配置
    let config = XDScanConfig.defaultConfig
    
    /// 扫码对象
    lazy var scan: XDScan = {
        XDScan(config: self.config, dataSource: self, delegate: self)
    }()

    var callback: ((String) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        /// 添加预览
        scan.addViedoPreviewLayer()
        /// 启动相机
        scan.startScanning()

        let btn = UIButton(frame: .init(x: 100, y: view.bounds.height - 100, width: 90, height: 40))
//        btn.setTitle("选择照片", for: .normal)
        btn.setImage(UIImage(named: "icon_pick_from_albumn"), for: .normal)
        view.addSubview(btn)
        btn.addTarget(self, action: #selector(pickImage), for: .touchUpInside)
    }

    @objc private func pickImage() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }

    func findQRCode(image: UIImage) {
       if let ciImage = CIImage(image: image) {
           let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
           if let features = detector?.features(in: ciImage),
              let firstQrcode = (features as? [CIQRCodeFeature])?.first?.messageString {
               print("qrcode : \(firstQrcode)")
               return
           }
        }
        print("❌❌")
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Retrieve the selected image from the info dictionary
        if let selectedImage = info[.originalImage] as? UIImage {
            findQRCode(image: selectedImage)

        }

        // Dismiss the photo picker
        picker.dismiss(animated: true, completion: nil)
    }

    deinit {
        scan.stopScanning()
    }

}

extension ScanVC: XDScanDataSource, XDScanDelegate {
    
    func previewView() -> UIView {
        view
    }

    func frameView(rect: CGRect) -> UIView? {
        let qrFramedView = XDScanFrame(frame: rect)
        qrFramedView.thickness = config.thickness
        qrFramedView.length = config.length
        qrFramedView.radius = config.radius
        qrFramedView.color = config.color
        qrFramedView.isCornerInside = true
        return qrFramedView
    }
    
    func animationView(rect: CGRect) -> XDScanAnimation? {
        XDScanLineAnimation(image: config.animationImage)
    }
    
    func qrScanEvent(_ event: XDScanEvent) {
        print(event)
        if case .scanFinish(let code) = event {
            callback?(code)
            self.navigationController?.popViewController(animated: true)
        }
    }

}
