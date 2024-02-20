//
//  NewDailyBudgetView.swift
//  SimTanka-iOS
//
//  Created by Vikram Vyas on 27/10/23.
//
// uses apples Measurement for units
// Released under
// GNU General Public License v3.0 or later
// https://www.gnu.org/licenses/gpl-3.0-standalone.html


import SwiftUI
import Combine


struct NewDailyBudgetView: View {
    
    private var cancellables: Set<AnyCancellable> = Set()
    
    @AppStorage("userDemandUnitSymbol") private var userDemandUnitSymbol: String = Region.preferredVolumeUnit().symbol
    
    @State private var selectedUnit = Region.preferredDemandUnit()
    @EnvironmentObject var demandModel:DemandModel
    
    // for showing detailed view
    @State private var selcetedMonth: Int = 0
    @State private var showSheet = false
    
    //
    @AppStorage("setUpBudgetMsg") private var setUpBudgetMsg =  "Please set up your water budget, this will allow SimTanka to estimate future performances"
    
    @AppStorage("waterBudgetIsSet") private var waterBudgetIsSet = false
    
    // for recalculating optimum tank size when water budget changes
    @AppStorage("userHasSavedOptTankM3") private var userHasSavedOptTankM3 = false
    
    // for recalculating reliabilty of the existing syste
    @AppStorage("userWaterBudgetHasChanged") private var userWaterBudgetHasChanged = false
    
    
    
    var body: some View {
        
        VStack {
            HStack {
                //Spacer()
                Text("Tap on \(selectedUnit.symbol)/day to enter your daily budget for that month")
                    .padding()
                    .font(.caption)
                Picker("", selection: $selectedUnit) {
                    ForEach(Region.demandUnits(), id: \.self) { unit in
                        Text(unit.symbol)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: selectedUnit) { newValue in
                        userDemandUnitSymbol = newValue.symbol
                   
                    }
                Spacer()
            }.background(AppColors.lightBlue).padding().font(.caption2)
            
            // display months with their daily budget
            List {
                ForEach(demandModel.dailyDemandM3Array.indices, id: \.self) { month in
                    
                    HStack{
                        Text(Helper.intMonthToShortString(monthInt: month+1))
                        Spacer()
                        Text(self.dailyDemandInUserUnits(demandInM3: demandModel.dailyDemandM3Array[month].dailyDemandM3))
                       
                    }.containerShape(Rectangle()).padding().frame(height: 20).font(.caption)
                    .onTapGesture {
                        self.selcetedMonth = month
                       
                        self.showSheet = true
                    }
                        .foregroundColor(.black)
                        .listRowBackground((month % 2 == 0 ? AppColors.lightBlue : AppColors.myColor5))
                }
            }
        }.onAppear {
                loadUserPreferedUnit()
            
            }
        .onDisappear{
            // save to core data 
            self.demandModel.SaveWaterDemandArray()
            
            // update the status
            self.setWaterBudgetMsg()
            waterBudgetIsSet = demandModel.BudgetIsSet()
            
            // save user choice of units
            userDemandUnitSymbol = selectedUnit.symbol
        }
        .sheet(isPresented: $showSheet) {
            NewDemandRowView(monthIndex: self.$selcetedMonth)
                .presentationDetents([.fraction(0.4)])
        }
        
        .navigationTitle(Text("Daily Water Budget"))
       
    }
}

extension NewDailyBudgetView {
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
    private func dailyDemandInUserUnits(demandInM3: Double) -> String {
        
        let  simTankaDailyDemand = Measurement(value: demandInM3, unit: UnitVolume.cubicMeters)
       
        let dailyDemandInUserUnits = simTankaDailyDemand.converted(to: self.selectedUnit)
        
        let formattedString = String(format: "%.0f %@", dailyDemandInUserUnits.value, self.selectedUnit.symbol)
       
        return formattedString + "/day"
        
      
        
    }
    func setWaterBudgetMsg() {
        if demandModel.BudgetIsSet() {
            setUpBudgetMsg = "View or edit your daily water budget."
        }
    }
}

#Preview {
    let persistenceController = PersistenceController.shared
    return  NewDailyBudgetView().environmentObject(DemandModel(managedObjectContext: persistenceController.container.viewContext))
}
