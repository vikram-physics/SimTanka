//
//  EditModifyTankSize.swift
//  SimTanka-iOS
//
//  Created by Vikram Vyas on 17/11/23.
//
// For exisisting RWHS
// To edit tank size
// and to display optimum tank size 
// Released under
// GNU General Public License v3.0 or later
// https://www.gnu.org/licenses/gpl-3.0-standalone.html

import SwiftUI

struct EditModifyTankSize: View {
    
    //
    // for calculating reliabilty
    @EnvironmentObject var simTankaVC: SimTankaVC
    @EnvironmentObject var demandModel:DemandModel
    
    // for displaying existing tank size
    @AppStorage("tankSizeM3") private var tankSizeM3 = 0.0
    @AppStorage("userVolumeUnitSymbol") private var userVolumeUnitSymbol: String = Region.preferredVolumeUnit().symbol
    @State private var selectedVolumeUnit = Region.preferredVolumeUnit()
    @State private var tankString = ""
    
    // reliability of the existing system
    @AppStorage("reliabiltyOfSystem") private var reliabiltyOfSystem = 0
    // for recalculating optimum tank size when water budget changes
    @AppStorage("userWaterBudgetHasChanged") private var userWaterBudgetHasChanged = false
    
    // for editing tank size
    @State private var volumeString = ""
    @FocusState private var isFocused: Bool
   
    @State private var oldVolumeUnit = Region.volumeUnits().first!
    
    //for calculating reliability
    @AppStorage("runOff") var runOff = 0.0
    @AppStorage("catchAreaM2") private var catchAreaM2 = 0.0
    
    // for displaying and showing optimum tank size.
    @AppStorage("plannedOptTankM3") private var plannedOptTankM3 = 0.0
    @AppStorage("userHasSavedOptTankM3") private var userHasSavedOptTankM3 = false
    
    var body: some View {
        
        List {
            Section {
                HStack{
                    Text("Storage capacity:").font(.subheadline)
                    Text(loadTankSize()).font(.subheadline)
                }.listRowBackground(AppColors.lightBlue)
                
                HStack{
                        
                    if (reliabiltyOfSystem != 0 && !userWaterBudgetHasChanged ) {
                            Text("Reliability of the existing system: \(Helper.LikelyHoodProbFrom(reliability: reliabiltyOfSystem))")
                            Spacer()
                    } else {
                        Button {
                            Task {
                                
                                    await self.estimateRWHSreliability()
                                }
                        } label: {
                            if !self.simTankaVC.performanceSim {
                                HStack {
                                    Spacer()
                                    Text("Estimate Reliability").font(.subheadline)
                                        .padding()
                                        .frame(height: 30)
                                        .background(tankSizeM3 != 0.0 ? Color.blue : Color.gray)
                                        .foregroundColor(.white)
                                       .cornerRadius(10)
                                    Spacer()
                                }
                            }
                           
                            if self.simTankaVC.performanceSim {
                                HStack {
                                    Text(self.simTankaVC.performanceMsg)
                                    Spacer()
                                    ProgressView().padding()
                                }.font(.caption).frame(height: 30).listRowBackground(AppColors.lightBlue).id(UUID())
                            }
                        }


                    }
                    
                    
                        
                }.padding().font(.subheadline).listRowBackground(AppColors.lightBlue)
                
            } header: {
                Text("Your existing storage").font(.headline)
            }
            Section {
                if userHasSavedOptTankM3 {
                    HStack {
                        Text("Optimum storage size for your system: \(self.tankSizeInUserUnits(tankInM3: plannedOptTankM3))").font(.subheadline).foregroundStyle(Color.black)
                        Spacer()
                    }.listRowBackground(AppColors.lightBlue).foregroundColor(.black)
                } else {
                    NavigationLink(destination: OptimizeTankSizeView()) {
                        Text("SimTanka can help you find optimum storage size").font(.subheadline)
                    }.listRowBackground(AppColors.lightGray).foregroundColor(.black)
                }
                
            } header: {
                Text("Optimum Storage Size").font(.headline)
            }
            Section {
                HStack {
                    Text("Enter your new storage tank size")
                }.font(.subheadline).listRowBackground(AppColors.lightGray)
                
                HStack{
                    TextField("Tank Size", text: $volumeString)
                        .focused($isFocused)
                        .keyboardType(.numberPad)
                        .onChange(of: volumeString) { newValue in
                            saveVolumeM3()
                            self.userWaterBudgetHasChanged = true // to trigger new cal of reliability
                        }
                        .onTapGesture {
                            // Dismiss the keyboard when tapped outside the text field
                            isFocused = false
                        }
                    Spacer()
                    Picker("", selection: $selectedVolumeUnit) {
                        ForEach(Region.volumeUnits(), id: \.self) { unit in
                            Text(unit.symbol)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onTapGesture {
                        oldVolumeUnit = selectedVolumeUnit
                    }
                    .onChange(of: selectedVolumeUnit) { newValue in
                        convertVolume(oldUnit: oldVolumeUnit, newUnit: newValue)
                    }
                }
            } header: {
                Text("New storage size").font(.headline)
            }

           

           
          
        }
        .onAppear{
            loadUserPrefVolUnit()
        }
        .navigationTitle("Modify Tank Size")
        
    }
}

#Preview {
    let persistenceController = PersistenceController.shared
    
    return EditModifyTankSize()
        .environmentObject(DemandModel(managedObjectContext: persistenceController.container.viewContext))
        .environmentObject(SimTankaVC(managedObjectContext: persistenceController.container.viewContext))
}

extension EditModifyTankSize {
    
    private func loadUserPrefVolUnit() {
        
        let userSymbol = userVolumeUnitSymbol
        
        switch userSymbol {
            
        case UnitVolume.gallons.symbol :
            selectedVolumeUnit = .gallons
            
        case UnitVolume.cubicMeters.symbol :
            selectedVolumeUnit = .cubicMeters
            
        case UnitVolume.liters.symbol :
            selectedVolumeUnit = .liters
            
        default:
            selectedVolumeUnit = Region.preferredVolumeUnit()
        }
        
       
        
    }
    
    private func loadTankSize() -> String {
        
        // volume in cubic meter
        let simTankaVolume = Measurement(value: tankSizeM3, unit: UnitVolume.cubicMeters)
        
        // volume in users unit
        let userTankSize = simTankaVolume.converted(to: selectedVolumeUnit)
        
        // set the volume string
        let roundedValue = round(userTankSize.value)
        return String(format: "%.0f", roundedValue) + String(" ") + String(selectedVolumeUnit.symbol)
    }
    
    private func convertVolume(oldUnit: UnitVolume, newUnit: UnitVolume) {
        
        if let volumeValue = Double(volumeString) {
            
            let oldMeasurment = Measurement(value: volumeValue, unit: oldUnit)
            let newMeasurment = oldMeasurment.converted(to: newUnit)
            
            let roundedValue = round(newMeasurment.value)
           
            volumeString = String(format: "%.0f", roundedValue)
        }
    }
    
    func estimateRWHSreliability() async {
       
        let myTanka = SimInput(runOff: runOff, catchAreaM2: catchAreaM2, tankSizeM3: tankSizeM3, dailyDemands: demandModel.DailyDemandM3())
      
        simTankaVC.displayResults = []
        await self.simTankaVC.EstimateReliabilityOfUsersRWHS(myTanka: myTanka)
        self.reliabiltyOfSystem = simTankaVC.displayResults[0].annualSuccess
        
        print("Your reliability: ", self.reliabiltyOfSystem)
        self.userWaterBudgetHasChanged = false // we have new reliability
       
    }
    
    private func saveVolumeM3() {
        
        // get the volume string
        
        if let volumeValue = Double(volumeString) {
            
            // get the volume in usesrs unit
            let userMeasurement = Measurement(value: volumeValue, unit: selectedVolumeUnit)
            
            // convert the volume into M^3
            let simTankaVolume = userMeasurement.converted(to: .cubicMeters)
            
            // save
            tankSizeM3 = simTankaVolume.value
        }
    }
    
    private func tankSizeInUserUnits(tankInM3: Double) -> String {
        
        
        // convert tankSizeM3 to users unit
        let volumeInM3 = Measurement(value: tankInM3, unit: UnitVolume.cubicMeters)
        
        let volumeInUserUnit = volumeInM3.converted(to: selectedVolumeUnit)
        
        // convert it into string
        // set the volume string
        let roundedValue = round(volumeInUserUnit.value)
        
        let formattedString = Helper.formattedNumber(numberString: String(roundedValue))
       // let formattedString = Helper.formattedNumber(numberString: String(tankSize))
       
        return formattedString + String(" ") + selectedVolumeUnit.symbol
     
        
    }
}
