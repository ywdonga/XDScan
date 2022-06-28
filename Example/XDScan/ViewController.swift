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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let vc = XDScanVC(config: XDScanConfig.defaultConfig)
        navigationController?.pushViewController(vc, animated: true)
    }
}

