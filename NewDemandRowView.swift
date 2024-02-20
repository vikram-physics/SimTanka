//
//  NewDemandRowView.swift
//  SimTanka-iOS
//
//  Created by Vikram Vyas on 03/11/23.
//
// Released under
// GNU General Public License v3.0 or later
// https://www.gnu.org/licenses/gpl-3.0-standalone.html

import SwiftUI

struct NewDemandRowView: View {
    
    @AppStorage("userDemandUnitSymbol") private var userDemandUnitSymbol: String = Region.preferredVolumeUnit().symbol
    @State private var selectedUnit = Region.preferredDemandUnit()
    
    @EnvironmentObject var demandModel:DemandModel
    
    @Binding var monthIndex: Int
    @State var dailyWater: String = ""
    @State var useSameDailyBudgetForAllMonths = false
    
    @FocusState private var dailyDemandIsFocused: Bool
   
    
    
    
    var body: some View {
        
        GeometryReader { geometry in
            ZStack{
                
                Color.gray
                VStack {
                    HStack{
                        Text(Helper.intMonthToShortString(monthInt: monthIndex + 1)).padding()
                        Spacer()
                        TextField("Daily Demand ", text: $dailyWater )
                       
                        Text(selectedUnit.symbol).padding()
                        
                        
                    }.frame(width: geometry.size.width, height: 50, alignment: .leading)
                        .background(Color.clear)
                        .focused($dailyDemandIsFocused)
                        .keyboardType(.numberPad)
                        .frame(width: 100)
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(.primary)
                    .onTapGesture {
                                  dailyDemandIsFocused = false
                    }
                    .onDisappear {
                        if useSameDailyBudgetForAllMonths {
                            sameDailyDemandForAllMonths()
                        } else {
                            dailyDemandForGivenMonth()
                        }
                       
                    }.onAppear {
                        
                        loadUserPreferedUnit()
                        demandString()
                    }
                    HStack{
                        Toggle(isOn:$useSameDailyBudgetForAllMonths) {
                            Text("Use for all the months").foregroundColor(.white).padding()
                        }.toggleStyle(CheckboxToggleStyle())
                    }.padding()
                }
            }
            
            
        }
       
    }
}

extension NewDemandRowView {
    
    private func loadUserPreferedUnit() {
        let userSymbol = userDemandUnitSymbol
        
        switch userSymbol {
        case "L" :
            selectedUnit = .liters
        case "gal" :
            selectedUnit = .gallons
        default :
            selectedUnit = Region.preferredVolumeUnit()
        }
    }
    
    private func convertVolume(oldUnit: UnitVolume, newUnit: UnitVolume) {
        
        if let volumeValue = Double(dailyWater) {
            
            let oldMeasurment = Measurement(value: volumeValue, unit: oldUnit)
            let newMeasurment = oldMeasurment.converted(to: newUnit)
            
            let roundedValue = round(newMeasurment.value)
           
            dailyWater = String(format: "%.0f", roundedValue)
        }
    }
    
    private func dailyDemandInM3() -> Double {
        
        if let demandValue = Double(dailyWater) {
            
             // demand in users unit
            let demandInUserUnit = Measurement(value: demandValue, unit: selectedUnit)
            
            // convert demand in M^3
            let demandInM3 = demandInUserUnit.converted(to: .cubicMeters)
            
            return demandInM3.value
            
        } else {
            return 0.0
        }
        
        
    }
    
    private func demandString() {
        
        let demandInM3 = demandModel.dailyDemandM3Array[self.monthIndex].dailyDemandM3
        
        // convert to users unit
        let  simTankaDailyDemand = Measurement(value: demandInM3, unit: UnitVolume.cubicMeters)
        
        let dailyDemandInUserUnits = simTankaDailyDemand.converted(to: self.selectedUnit)
        
        if dailyDemandInUserUnits.value == 0.0 {
            self.dailyWater = ""
        } else {
            self.dailyWater = String(format: "%.0f",dailyDemandInUserUnits.value)
        }
        //let formattedString = String(format: "%.0f %@", dailyDemandInUserUnits.value, self.selectedUnit.symbol)
    }
    
    
    func sameDailyDemandForAllMonths() {
        
        for monthIndex in 0...11 {
            demandModel.dailyDemandM3Array[monthIndex].dailyDemandM3 = dailyDemandInM3()
        }
        
    }
    
    func dailyDemandForGivenMonth() {
        demandModel.dailyDemandM3Array[self.monthIndex].dailyDemandM3 = dailyDemandInM3()
    }
    
}

#Preview {
    NewDemandRowView( monthIndex: .constant(3))
}
