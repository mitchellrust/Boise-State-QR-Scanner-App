//
//  CustomTableViewCell.swift
//  QR Code Scanner
//
//  Created by Mitch Rust on 12/4/18.
//  Copyright © 2019 Mitch Rust. All rights reserved.
//

import UIKit

class CustomTableViewCell: UITableViewCell {

    @IBOutlet weak var menuLabel: UILabel! // Label of each cell in side menu
    
    /**
     Runs when side menu is shown to display cells.
    **/
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    /**
     Animates the user selected cell.
    **/
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
