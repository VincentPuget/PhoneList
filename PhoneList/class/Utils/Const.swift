//
//  Const.swift
//  PhoneList
//
//  Created by Vincent PUGET on 16/09/2016.
//  Copyright © 2016 Vincent PUGET. All rights reserved.
//


struct Const {
  struct App {
    static let NAME:String = "PhoneList";
    static let DEBUG:Bool = true;
  }
  struct Webservice {
//    static let URL: String = "http://phonelist.jpm-next.com"
//    static let PHONE_ENDPOINT: String = "/index.php"
    static let URL: String = "https://adam.jpm-next.com"
    static let PHONE_ENDPOINT: String = "/apps/fetch"
    
    static let identifier: String = "APPPhonelist"
    static let password: String = "JPMASJPMAS";
    
  }
}
