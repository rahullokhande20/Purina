//
//  ChannellCollectionViewCell.swift
//  Purina
//
//  Created by Sai Dammu on 2/14/22.
//

import UIKit

class ChannellCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var chSwitch : UISwitch!
    @IBOutlet weak var chLabel : UILabel!
    
    override func awakeFromNib() {
       super.awakeFromNib()
       //custom logic goes here
    }

    
    required init?(coder aDecoder: NSCoder) {
       super.init(coder: aDecoder)
    }
}
