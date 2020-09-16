//
//  Astronomy+CoreDataProperties.swift
//  APOD Explorer
//
//  Created by Tanner Quesenberry on 9/16/20.
//  Copyright © 2020 Tanner Quesenberry. All rights reserved.
//
//

import Foundation
import CoreData


extension Astronomy {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Astronomy> {
        return NSFetchRequest<Astronomy>(entityName: "Astronomy")
    }

    @NSManaged public var copyright: String
    @NSManaged public var date: String
    @NSManaged public var explanation: String
    @NSManaged public var media_type: String
    @NSManaged public var title: String
    @NSManaged public var url: String

}
