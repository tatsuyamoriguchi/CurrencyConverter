//
//  CoreDataController.swift
//  CurrencyConverter
//
//  Created by Tatsuya Moriguchi on 11/1/20.
//  Copyright © 2020 Tatsuya Moriguchi. All rights reserved.
//

import UIKit
import CoreData

class CoreDataController: ViewController {

    // Save key and value data to Core Data
    func saveData(key: String, value: Float?, currencyDescription: String?) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let context = appDelegate.persistentContainer.viewContext
            guard let entityDescription = NSEntityDescription.entity(forEntityName: "CurrencyEntity", in: context) else { return }
            let newValue = NSManagedObject(entity: entityDescription, insertInto: context)
            
            newValue.setValue(key, forKey: "currencySymbol")
            
            if value != nil { newValue.setValue(value, forKey: "currencyRate") }
            
            if currencyDescription != "" {
                newValue.setValue(currencyDescription, forKey: "currencyDescription")
            }
            
            
            do {
                try context.save()
                //print("Saved: \(key) = \(String(describing: value)) = \(currencyDescription)")
            } catch {
                print("Core Data Saving Error: \(error)")
            }
        }
    }
    
    
    func getCurrencyDescriptionData() {
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<CurrencyEntity>(entityName: "CurrencyEntity")
            
            // initialize arrays
            currencyDescriptionArray = []
            currencySymbols = []

            
            do {
                let results = try context.fetch(fetchRequest)
                
                for result in results {
                    // If currencyDescription data exists, append it to currencyDescptionArray
                    // to display in tableView
                    
                    if result.currencyDescription != nil {
                        currencyDescriptionArray.append(result.currencyDescription!)
                    
                    } else { print("currencyDescription not found")}
                    
                    if result.currencySymbol != nil {
                        currencySymbols.append(result.currencySymbol!)
                        
                    } else {
                        print("currencySymbol not found")
                    }
                
                }
                
            } catch {
                print("Core Data Retrieve Error: \(error)")
            }
        }
        
    }
    
    // Retrieve data via Core Data
    func retrieve(key: String) -> Float {
        var convRate: Float?

        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<CurrencyEntity>(entityName: "CurrencyEntity")
            
            do {
                let results = try context.fetch(fetchRequest)
               
                for result in results {

                    // Return convRate if result.currencySymbol equals to key
                    if result.currencySymbol == key {
                        convRate = result.currencyRate
                        
                        return convRate!
                    }
                }
            } catch {
                print("Core Data Retrieve Error: \(error)")
            }
        }
        return 0
    }
    
    
    
    func deleteAllData(_ entity:String) {
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<CurrencyEntity>(entityName: entity)
            fetchRequest.returnsObjectsAsFaults = false
            do {
                let results = try context.fetch(fetchRequest)
                for object in results {
                    let objectData = object
                    context.delete(objectData)
                }
            } catch let error {
                print("Detele all data in \(entity) error :", error)
            }
        }
        
    }

}
