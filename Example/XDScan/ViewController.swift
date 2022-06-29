//
//  ViewController.swift
//  XDScan
//
//  Created by 329720990@qq.com on 06/28/2022.
//  Copyright (c) 2022 329720990@qq.com. All rights reserved.
//

import UIKit
import XDScan

class ViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            let vc = XDScanVC(config: XDScanConfig.defaultConfig)
            vc.eventBlock = { event in
                print(event)
            }
            navigationController?.pushViewController(vc, animated: true)
        case 1:
            let vc = ScanVC()
            navigationController?.pushViewController(vc, animated: true)
        default: break
        }
    }
}
