//
//  DemandModel.swift
//  SimTanka-iOS
//
//  Created by Vikram  on 19/05/22.
//
// Class for handling storing and retriving daily water budget

import Foundation
import SwiftUI
import CoreData
// Released under
// GNU General Public License v3.0 or later
// https://www.gnu.org/licenses/gpl-3.0-standalone.html

class DemandModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    
    // daily water demand from core data
    private let waterDemandController: NSFetchedResultsController<WaterDemand>
    private let dbContext: NSManagedObjectContext
    
    @Published var dailyDemandM3Array: [WaterDemand] = [] // from Core Data
   
    
    @Published var arrayForChart: [WaterBudgetChart] = []
    
    // to record changes in water budget that requires recalculation of reliability
    @AppStorage("userHasSavedOptTankM3") private var userHasSavedOptTankM3 = false
    
    @AppStorage("userWaterBudgetHasChanged") private var userWaterBudgetHasChanged = false
    
    init(managedObjectContext: NSManagedObjectContext) {
        
        let fetchRequest:NSFetchRequest<WaterDemand> = WaterDemand.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "month", ascending: true)]
        
        waterDemandController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        self.dbContext = managedObjectContext
        super.init()
        
        waterDemandController.delegate = self
        
        do {
            try waterDemandController.performFetch()
            dailyDemandM3Array = waterDemandController.fetchedObjects ?? []
            if dailyDemandM3Array.count == 0 {
                createWaterBudgetInCoreData()
            }
        } catch {
            print("Could not fetch daily water demand records")
        }
    }
    
    
    // for newbudget view
    func SaveWaterDemandArray() {
        // update the database
        do {
            try self.dbContext.save()
        } catch {
            print("Error saving record")
        }
    }
   
}

extension DemandModel {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        do {
            try waterDemandController.performFetch()
            dailyDemandM3Array = waterDemandController.fetchedObjects ?? []
           
            // for recalculating optimum tank size when water budget changes, stored optimum tank no longer valid
            userHasSavedOptTankM3 = false
            
            // for recalculating reliabilty of the existing systes
             userWaterBudgetHasChanged = true
            
            
        } catch {
            print("Could not fetch daily water demand records")
        }
    }
    
    func createWaterBudgetInCoreData() {
     //   print("Ok will create a water budget now")

        for month in 1...12 {
            // create a record
            let monthRecord = WaterDemand(context: self.dbContext)
            
            // set month
            monthRecord.month = Int16(month)
            
            // append it to dailyDemandM3Array
            dailyDemandM3Array.append(monthRecord)
            
            // save the record
            // update the database
            do {
                try self.dbContext.save()
            } catch {
                print("Error saving record")
            }
        }
        
    }
    
    func BudgetIsSet() -> Bool {
        
        // sum up the total water demand
        let totalDailyDemand = dailyDemandM3Array.reduce(0) {
            $0 + $1.dailyDemandM3
        }
       
        if totalDailyDemand != 0.0 {
            return true
        } else {
            return false 
        }
       
    }
    
    func DailyDemandM3() -> [Double] {
        // returns daily demand in M3
        
        var demandArray:[Double] = []
        
        for mIndex in 0...11 {
            let demandM3 = self.dailyDemandM3Array[mIndex].dailyDemandM3
            demandArray.append(demandM3)
            
        }
        return demandArray 
    }
    
    func AnnualWaterDemandM3() -> Double{
        let dailyDemandArrayM3 = self.DailyDemandM3()
       
        let monthDemandArray = dailyDemandArrayM3.map{$0 * 30}
        
        return monthDemandArray.reduce(0) {$0 + $1}
    }
    
    func CreateArrayForBudgetChart() {
        arrayForChart = []
         
        for mIndex in 0...11 {
           
            let monthStr = Helper.intMonthToShortString(monthInt: mIndex+1)
            let demandM3 = self.dailyDemandM3Array[mIndex].dailyDemandM3
            arrayForChart.append(WaterBudgetChart(month: monthStr, dailyBudgetInM3: demandM3))
        }
    }
}

struct WaterBudgetChart:Identifiable {
    let id = UUID()
    let month:  String
    let dailyBudgetInM3: Double
    
}
