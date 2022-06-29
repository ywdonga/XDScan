//
//  ViewController.swift
//  XDScan
//
//  Created by 329720990@qq.com on 06/28/2022.
//  Copyright (c) 2022 329720990@qq.com. All rights reserved.
//

import UIKit
import XDScan

class ViewController: UIViewController {

    lazy var scan: XDScan = {
        XDScan(config: XDScanConfig.defaultConfig, dataSource: self, delegate: self)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        scan.addViedoPreviewLayer()
        scan.startScanning()
    }

    deinit {
        scan.stopScanning()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        let vc = XDScanVC(config: XDScanConfig.defaultConfig)
//        navigationController?.pushViewController(vc, animated: true)
//    }
}

extension ViewController: XDScanDataSource, XDScanDelegate {
    func previewView() -> UIView {
        view
    }
    
    func qrScanEvent(_ event: XDScanEvent) {
        print(event)
    }

}
