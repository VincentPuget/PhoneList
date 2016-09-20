//
//  Person+CoreDataProperties.swift
//  PhoneList
//
//  Created by Vincent PUGET on 20/09/2016.
//  Copyright © 2016 Vincent PUGET. All rights reserved.
//

import Foundation
import CoreData


extension Person {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Person> {
        return NSFetchRequest<Person>(entityName: "Person");
    }

    @NSManaged public var photo: String?
    @NSManaged public var firstname: String?
    @NSManaged public var lastname: String?
    @NSManaged public var number: String?
    @NSManaged public var fullname: String?

}
