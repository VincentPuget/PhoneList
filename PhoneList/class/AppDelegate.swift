//
//  AppDelegate.swift
//  PhoneList
//
//  Created by Vincent PUGET on 16/09/2016.
//  Copyright © 2016 Vincent PUGET. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



  func applicationDidFinishLaunching(_ aNotification: Notification) {
    // Insert code here to initialize your application
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }
  
  //qui l'app si la dernière fenetre active est fermée
  func applicationShouldTerminateAfterLastWindowClosed(_ theApplication: NSApplication) -> Bool
  {
    return true;
  }
}

