//
//  ScanVC.swift
//  XDScan_Example
//
//  Created by dyw on 2022/6/29.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import XDScan

class ScanVC: UIViewController {

    /// 配置
    let config = XDScanConfig.defaultConfig
    
    /// 扫码对象
    lazy var scan: XDScan = {
        XDScan(config: self.config, dataSource: self, delegate: self)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        /// 添加预览
        scan.addViedoPreviewLayer()
        /// 启动相机
        scan.startScanning()
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
        return qrFramedView
    }
    
    func animationView(rect: CGRect) -> XDScanAnimation? {
        XDScanLineAnimation(image: config.animationImage)
    }
    
    func qrScanEvent(_ event: XDScanEvent) {
        print(event)
    }

}
