//
//  XDScanConfig.swift
//  XDScan
//
//  Created by dyw on 22/06/28.
//  Copyright © 2022年 dongyouwei. All rights reserved.
//

import UIKit

public struct XDScanConfig {
    /// 标题
    public var title: String = ""
    
    /// 提示文案
    public var hint: String?
    /// 提示文案字体大小
    public var hintSize: CGFloat = 18
    /// 提示文案颜色
    public var hintColor: UIColor = UIColor.white.withAlphaComponent(0.8)

    /// 四角线条长度
    public var length: CGFloat = 20
    /// 四角线条颜色
    public var color: UIColor = .white
    /// 四角线条圆角
    public var radius: CGFloat = 0.0
    /// 四角线条宽度
    public var thickness: CGFloat = 4.0
    /// 镂空的尺寸的宽高，相对屏幕宽度的比例
    public var maskScale: CGFloat = 0.638
    /// 镂空的圆角
    public var maskRadius: CGFloat = 0.0
    /// 镂空周边背景颜色
    public var maskBgColor: UIColor = UIColor(white: 0, alpha: 0.5)
    /// 动画图片
    public var animationImage: UIImage = XDScan.getBundleImg(with: "xdscan_animation_line")!
}

extension XDScanConfig {
    
    public static var defaultConfig: XDScanConfig {
        XDScanConfig(hint: "请扫描二维码")
    }
}

