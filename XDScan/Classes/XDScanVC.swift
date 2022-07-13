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
        title = config.title
        scan.addViedoPreviewLayer()
        scan.startScanning()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scan.startScanning()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        scan.stopScanning()
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
    
    public func frameView(rect: CGRect) -> UIView? {
        let qrFramedView = XDScanFrame(frame: rect)
        qrFramedView.thickness = config.thickness
        qrFramedView.length = config.length
        qrFramedView.radius = config.radius
        qrFramedView.color = config.color
        return qrFramedView
    }
    
    public func animationView(rect: CGRect) -> XDScanAnimation? {
        XDScanLineAnimation(image: config.animationImage)
    }
    
    public func qrScanEvent(_ event: XDScanEvent) {
        if case .scanFinish(_) = event {
            if navigationController != nil {
                navigationController?.popViewController(animated: true)
            } else {
                dismiss(animated: true)
            }
        }
        eventBlock?(event)
    }
}
