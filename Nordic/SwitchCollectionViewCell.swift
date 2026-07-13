//
//  SwitchCollectionViewCell.swift
//  Purina
//
//  Created by Sai Dammu on 1/27/22.
//

import UIKit

class SwitchCollectionViewCell: UICollectionViewCell {
    var aSwitch: UISwitch!
    var label: UILabel!
    
  
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        aSwitch = UISwitch()
        aSwitch.isOn = false
        aSwitch.frame = CGRect(x: 0, y: 0, width: 60, height: 40)
        self.contentView.addSubview(aSwitch)
        
        label = UILabel()
        label.frame = CGRect(x: 0, y: 42, width: 60, height: 15)
        label.textColor = .black
        label.textAlignment = .center
        self.contentView.addSubview(label)
        
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

}
