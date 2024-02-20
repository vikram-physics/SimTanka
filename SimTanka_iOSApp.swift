//
//  SimTanka_iOSApp.swift
//  SimTanka-iOS
//
//  Created by Vikram Vyas on 12/12/21.
//
/// Released under
/// GNU General Public License v3.0 or later
/// https://www.gnu.org/licenses/gpl-3.0-standalone.html
/// 
import SwiftUI

@main
struct SimTanka_iOSApp: App {
    
   
    
    @StateObject
    private var purchaseManager = PurchaseManager()
    
    @StateObject private var appSettings = AppSettings()
    
    @StateObject var myTankaUnits = TankaUnits() // user pref for units
    
    @StateObject private var downloadRain:DownloadRainfallFromVC
    
    @StateObject var demandModel:DemandModel
    
    @StateObject var simTankaVC: SimTankaVC
    
  
    
    @StateObject private var performancdModel:PerformanceModel
    
    @StateObject private var waterDiaryModel:WaterDiaryModel
    
    init() {
        self.persistenceController = PersistenceController.shared
        
        let rain = DownloadRainfallFromVC(managedObjectContext: persistenceController.container.viewContext)
        self._downloadRain = StateObject(wrappedValue: rain)
        
       
        
        let simModelVC = SimTankaVC(managedObjectContext: persistenceController.container.viewContext)
        self._simTankaVC = StateObject(wrappedValue: simModelVC)
        
        let demand = DemandModel(managedObjectContext: persistenceController.container.viewContext)
        self._demandModel = StateObject(wrappedValue: demand)
        
        let performance = PerformanceModel(managedObjectContext: persistenceController.container.viewContext)
        self._performancdModel = StateObject(wrappedValue: performance)
        
        let diaryModel = WaterDiaryModel(managedObjectContext: persistenceController.container.viewContext)
        self._waterDiaryModel = StateObject(wrappedValue: diaryModel)
    }
    let persistenceController: PersistenceController

    var body: some Scene {
        WindowGroup {
           
            SimTankaStartUpView()
                .environmentObject(myTankaUnits)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(demandModel)
                .environmentObject(performancdModel)
                .environmentObject(waterDiaryModel)
                .environmentObject(downloadRain)
                .environmentObject(simTankaVC)
                .environmentObject(purchaseManager)
                .environmentObject(appSettings)
                .task {
                        await purchaseManager.updatePurchasedProducts()
                    }
        }
    }
}
