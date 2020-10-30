//
//  CurrencyEntity+CoreDataProperties.swift
//  CurrencyConverter
//
//  Created by Tatsuya Moriguchi on 10/28/20.
//  Copyright © 2020 Tatsuya Moriguchi. All rights reserved.
//
//

import Foundation
import CoreData


extension CurrencyEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CurrencyEntity> {
        return NSFetchRequest<CurrencyEntity>(entityName: "CurrencyEntity")
    }

    @NSManaged public var currencySymbol: String?
    @NSManaged public var currencyRate: Float
    @NSManaged public var currencyDescription: String?

}
