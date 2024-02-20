//
//  DisplayWaterBudgetChart.swift
//  SimTanka-iOS
//
//  Created by Vikram Vyas on 16/09/23.
//
// Released under
// GNU General Public License v3.0 or later
// https://www.gnu.org/licenses/gpl-3.0-standalone.html

import SwiftUI
import Charts

struct DisplayWaterBudgetChart: View {
    
   // @EnvironmentObject var myTankaUnits: TankaUnits
    @EnvironmentObject var demandModel:DemandModel
    
    // for units 
    @AppStorage("userDemandUnitSymbol") private var userDemandUnitSymbol: String = Region.preferredVolumeUnit().symbol
    @State private var selectedDemandUnit = Region.preferredVolumeUnit()
   
    
    var body: some View {
        VStack {
            HStack {
                Text("Daily water budget ")
                Picker("", selection: $selectedDemandUnit) {
                    ForEach(Region.demandUnits(), id: \.self) { unit in
                        Text(unit.symbol).foregroundStyle(.black)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            Chart(demandModel.arrayForChart) { month in
                
                
                BarMark(
                    // x:.value("Daily Demand", Helper.M3toDemandUnit(demandM3: month.dailyBudgetInM3, demandUnit: myTankaUnits.demandUnit)),
                     x:.value("Daily Demand", dailyDemandInUserUnits(demandInM3: month.dailyBudgetInM3)),
                     y:.value("month", month.month)
                     
                ).annotation (position: .overlay, alignment: .center) {
                    Text(String(format: "%.0f", dailyDemandInUserUnits(demandInM3: month.dailyBudgetInM3)) + "\(selectedDemandUnit.symbol)")
                        .font(.caption2).foregroundStyle(.white)
                    }
                .foregroundStyle(.blue)
                
    
            }.padding().background(AppColors.lightBlue)
            .onDisappear {
                // store users choice of unit
                userDemandUnitSymbol = selectedDemandUnit.symbol
            }
            .onAppear {
                loadUserPreferedUnit()
                demandModel.CreateArrayForBudgetChart()
            }
          
        }.background(AppColors.lightBlue)
           
        
        
    }
}

extension DisplayWaterBudgetChart {
    
    private func dailyDemandInUserUnits(demandInM3: Double) -> Double {
        
        let  simTankaDailyDemand = Measurement(value: demandInM3, unit: UnitVolume.cubicMeters)
       
        let dailyDemandInUserUnits = simTankaDailyDemand.converted(to: self.selectedDemandUnit)
       
        return dailyDemandInUserUnits.value
        
      
        
    }
    
    private func loadUserPreferedUnit() {
        let userSymbol = userDemandUnitSymbol
        
        switch userSymbol {
        case "L" :
            selectedDemandUnit = .liters
        case "gal" :
            selectedDemandUnit = .gallons
        default :
            selectedDemandUnit = Region.preferredVolumeUnit()
        }
    }
}

/*
struct DisplayWaterBudgetChart_Previews: PreviewProvider {
    
    let persistenceController = PersistenceController.shared
    
    static var previews: some View {
        DisplayWaterBudgetChart().environmentObject(DemandModel(managedObjectContext: persistenceController.container.viewContext))
            .environmentObject(TankaUnits())
           //
            
    }
}
*/
