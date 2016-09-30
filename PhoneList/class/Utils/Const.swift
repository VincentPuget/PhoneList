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
    static let URL: String = "http://phonelist.jpm-next.com"
    static let PHONE_ENDPOINT: String = "/index.php"
    static let PHONE_ENDPOINT_$GET_VERSION: String = "version"
    static let X_JSON_MD5_KEY: String = "X-Json-MD5"
    static let X_JSON_MD5_VALUE: String = "c535f3f6b2c646a31d24af41b8c52e3e"
    
    static let PERSON_KEY: String = "persons"
    static let VERSION_KEY: String = "version"
  }
}
