//
//  Version+CoreDataProperties.swift
//  PhoneList
//
//  Created by Vincent PUGET on 18/09/2016.
//  Copyright © 2016 Vincent PUGET. All rights reserved.
//

import Foundation
import CoreData


extension Version {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Version> {
        return NSFetchRequest<Version>(entityName: "Version");
    }

    @NSManaged public var md5: String?
    @NSManaged public var lastModified: NSDate?

}
