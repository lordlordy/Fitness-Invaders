//
//  CoreDataStack.swift
//  Fitness Invaders
//
//  Created by Steven Lord on 22/07/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Foundation
import CoreData


class CoreDataStack{
    
    static let shared = CoreDataStack()
    
    // MARK: - Core Data stack
    
    lazy var modelPC: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "FitnessInvaders")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            let type = storeDescription.type
            let url = storeDescription.url
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
        })
        return container
    }()
    
    func save(){
        do {
            try modelPC.viewContext.save()
        } catch {
            print(error)
        }
    }
    
    func updateHighestScore(with score: Int64){
        let hs = getHighestScoreEntity()
        if score > hs.value{
            hs.value = score
            save()
        }
    }
    
    func highestScore() -> Int64{
        return getHighestScoreEntity().value
    }
    
    func getPowerUp() -> PowerUp{
        let fetch = NSFetchRequest<NSFetchRequestResult>.init(entityName: "PowerUp")
        do{
            let pup = try modelPC.viewContext.fetch(fetch) as! [NSManagedObject]
            if pup.count > 0{
                if let result = pup[0] as? PowerUp{
                    //for testing
                    result.defence = 8
                    result.attack = 11
                    return result
                }
            }
        }catch{
            print("Fetch failed with error \(error)")
        }
        
        //no result found. Create one
        let pup = NSEntityDescription.insertNewObject(forEntityName: "PowerUp", into: modelPC.viewContext)
        let powerUp: PowerUp = pup as! PowerUp
        powerUp.defence = 8
        powerUp.attack = 11
        save()
        return pup as! PowerUp
    }
    
    private func getHighestScoreEntity() -> HighestScore{
        let fetch = NSFetchRequest<NSFetchRequestResult>.init(entityName: "HighestScore")
        do{
            let hs = try modelPC.viewContext.fetch(fetch) as! [NSManagedObject]
            if hs.count > 0{
                if let result = hs[0] as? HighestScore{
                    //for testing
                    return result
                }
            }
        }catch{
            print("Fetch failed with error \(error)")
        }
        
        //no result found. Create one
        let hs = NSEntityDescription.insertNewObject(forEntityName: "HighestScore", into: modelPC.viewContext)
        return hs as! HighestScore
    }
    

    
}
