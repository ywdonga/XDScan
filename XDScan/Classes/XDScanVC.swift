//
//  XDScanVC.swift
//  XDScan
//
//  Created by dyw on 22/06/28.
//  Copyright © 2022年 dongyouwei. All rights reserved.
//

import UIKit

public class XDScanVC: UIViewController {
    /// 配置
    private let config: XDScanConfig
    /// 回调
    public var eventBlock: ((XDScanEvent)->())?

    public init(config: XDScanConfig = XDScanConfig.defaultConfig) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        view.backgroundColor = UIColor.white
        scan.addViedoPreviewLayer()
        scan.startScanning()
    }
    
    deinit {
        scan.stopScanning()
    }
    
    /// 扫码对象
    lazy var scan: XDScan = {
        XDScan(config: self.config, dataSource: self, delegate: self)
    }()
}

extension XDScanVC: XDScanDataSource, XDScanDelegate {
   
    public func previewView() -> UIView {
        view
    }
    
    
    
    public func qrScanEvent(_ event: XDScanEvent) {
        eventBlock?(event)
    }
}
