//
//  CheckableTableViewCell.swift
//  FiExample
//
//  Created by Michael Gray on 9/2/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import UIKit

class CheckableTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        self.accessoryType = selected ? .checkmark : .none
    }

}

class HeaderTableViewCell: UITableViewCell {

    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var allButton: UIButton!
    @IBOutlet weak var noneButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        self.accessoryType = selected ? .checkmark : .none
    }

}
