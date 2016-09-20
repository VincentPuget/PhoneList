//
//  L.swift
//  PhoneList
//
//  Created by Vincent PUGET on 16/09/2016.
//  Copyright © 2016 Vincent PUGET. All rights reserved.
//

import Cocoa

struct L
{
    static func v(_ anyObjects:AnyObject!...) -> Void
    {
        if(Const.App.DEBUG)
        {
            for anyObject:AnyObject! in anyObjects
            {
              if(anyObject != nil){
                print(anyObject);
              }
            }
        }
    }
}
