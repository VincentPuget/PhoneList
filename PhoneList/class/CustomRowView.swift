//
//  CustomRow.swift
//  PhoneList
//
//  Created by Vincent PUGET on 20/09/2016.
//  Copyright © 2016 Vincent PUGET. All rights reserved.
//

import Foundation
import AppKit

class CustomRowView: NSTableRowView {
  
  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
    
    if isSelected == true {
      NSColor.init(red: 79/225, green: 150/225, blue: 137/225, alpha: 1).set()
      NSRectFill(dirtyRect)
    }
  }
}
