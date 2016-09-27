//
//  SettingsViewController.swift
//  PhoneList
//
//  Created by Vincent PUGET on 26/09/2016.
//  Copyright © 2016 Vincent PUGET. All rights reserved.
//

import Cocoa

class SettingsViewController: NSViewController{
  
  @IBOutlet weak var buttonQuit: NSButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  override var representedObject: Any? {
    didSet {
      // Update the view, if already loaded.
    }
  }
  
  @IBAction func IBA_buttonQuit(_ sender: AnyObject) {
    NSApplication.shared().terminate(self)
  }
  
}
