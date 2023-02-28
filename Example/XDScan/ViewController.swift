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
    let tv = UITextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()


        tv.frame = CGRect(x: 0, y: view.bounds.height - 200, width: view.bounds.width, height: 200)
        view.addSubview(tv)
        tv.backgroundColor = UIColor.gray.withAlphaComponent(0.6)
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
            vc.callback = {
                [weak self] (code) in
                self?.tv.text = code
            }
            navigationController?.pushViewController(vc, animated: true)
        default: break
        }
    }
}
