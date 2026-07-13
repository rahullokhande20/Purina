//
//  HomeTableViewCell.swift
//  Soniphi
//
//  Created by Sai Dammu on 6/14/21.
//  Copyright © 2021 SaiDammu. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class HomeTableViewCell : UITableViewCell{
    
    var button : UIButton!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let bgView = UIButton()
        bgView.backgroundColor = Color.themeBlue
        bgView.isUserInteractionEnabled = false
        self.contentView.addSubview(bgView)
        
        bgView.snp.makeConstraints { (make) in
            make.leading.trailing.top.bottom.equalToSuperview().inset(10)
        }
        bgView.layer.cornerRadius = 5.0
        bgView.clipsToBounds = true
        
        button = UIButton()
        button.isUserInteractionEnabled = false
//        button.contentHorizontalAlignment = .left
        button.titleLabel?.numberOfLines = 1
        button.contentHorizontalAlignment = .left
        button.titleLabel?.lineBreakMode = .byClipping
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        bgView.addSubview(button)
        
        button.snp.makeConstraints { (make) in
            make.centerY.trailing.equalToSuperview()
            make.leading.equalToSuperview().offset(80)
        }
        
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
