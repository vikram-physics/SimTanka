//
//  SetTankSizeView.swift
//  SimTanka-iOS
//
//  Created by Vikram Vyas on 29/09/23.
//
// Released under
// GNU General Public License v3.0 or later
// https://www.gnu.org/licenses/gpl-3.0-standalone.html

import SwiftUI

struct SetTankSizeView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var simTankaVC: SimTankaVC
    @EnvironmentObject var demandModel:DemandModel
    
    // for storing tank size
    @AppStorage("tankSizeM3") private var tankSizeM3 = 0.0
    @AppStorage("tankSizeIsSet") private var tankSizeIsSet = false
    @AppStorage("userVolumeUnitSymbol") private var userVolumeUnitSymbol: String = UnitVolume.liters.symbol
   
    // for reading catchment area
    @AppStorage("runOff") var runOff = 0.0
    @AppStorage("catchAreaM2") private var catchAreaM2 = 0.0
   
    
    @State private var volumeString = ""
    @State private var selectedVolumeUnit = Region.preferredVolumeUnit()
    @State private var oldVolumeUnit = Region.volumeUnits().first!
    
    @FocusState private var isFocused: Bool
    
    // build or planning to build
    @AppStorage("isRWHSBuilt") private var isRWHSBuilt = true
    
    // reliability of the existing system
    @AppStorage("reliabiltyOfSystem") private var reliabiltyOfSystem = 0
    
    var body: some View {
        
        List {
            
            Section("RWHS Status") {
                            Toggle("Is RWHS already built?", isOn: $isRWHSBuilt)
                                .listRowBackground(AppColors.lightGray)
                        } .font(.headline)
            
            Section(header: Text(!isRWHSBuilt ? "Planning" : "Tank Size")) {
                
                if isRWHSBuilt {
                    
                    HStack {
                        Text("Enter your storage tank size")
                    }.font(.subheadline).listRowBackground(AppColors.lightGray)
                    
                    HStack{
                        TextField("Tank Size", text: $volumeString)
                            .focused($isFocused)
                            .keyboardType(.numberPad)
                            .onChange(of: volumeString) { newValue in
                                saveVolumeM3()
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
                } else {
                    // If RWHS is not built, inform the user that they can enter the tank size later
                    HStack {
                        Text("You can enter your tank size once you have built the system.")
                            
                    }.font(.headline).listRowBackground(AppColors.lightGray)
                    
                    HStack {
                        Text("You can use the tank size optimization tool to find a suitable tank size for your water needs and system size.")
                    }.font(.subheadline).listRowBackground(AppColors.lightBlue)
                }
                
                    
                }.font(.headline)
               
            if isRWHSBuilt {
                Section("Estimate Reliability") {
                    
                    VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 10) {
                                    
                                    Text("SimTanka estimates the reliability of your RWHS by considering the following factors:").font(.subheadline)
                                }
                            HStack(spacing: 10) {
                                Image(systemName: "circle.fill")
                                .foregroundColor(.blue) // Customize the bullet point color
                                Text("Your daily water budget.")
                            }.font(.caption)
                        
                            HStack(spacing: 10) {
                                Image(systemName: "circle.fill")
                                        .foregroundColor(.blue) // Customize the bullet point color
                                Text("Daily rainfall records from the past five years.")
                            }.font(.caption)
                                
                            HStack(spacing: 10) {
                                Image(systemName: "circle.fill")
                                .foregroundColor(.blue) // Customize the bullet point color
                                Text("The size of your storage tank.")
                            }.font(.caption)
                        }
                        .listRowBackground(AppColors.lightGray)
                    
                    if !self.simTankaVC.performanceSim {
                        Button(action: {
                                       // Your button action here
                                Task {
                                    
                                        await self.estimateRWHSreliability()
                                    }
                                   }) {
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
                                   .disabled(tankSizeM3 == 0.0)
                                   .opacity(tankSizeM3 != 0.0 ? 1 : 0.5)
                                   .listRowBackground(AppColors.lightBlue)
                    }
                   
                    
                    if self.simTankaVC.performanceSim {
                        HStack {
                            Text(self.simTankaVC.performanceMsg)
                            Spacer()
                            ProgressView().padding()
                        }.font(.caption).frame(height: 30).listRowBackground(AppColors.lightBlue).id(UUID())
                    }
                    
                    if self.simTankaVC.displayResults.count != 0 {
                        VStack {
                            HStack{
                                Text("Reliability of your system:")
                                Spacer()
                                
                                Text("\(Helper.LikelyHoodProbFrom(reliability: simTankaVC.displayResults[0].annualSuccess))")
                            }.font(.caption).frame(height: 30).listRowBackground(AppColors.lightGray)
                            if simTankaVC.displayResults[0].annualSuccess < 90 {
                                HStack {
                                    Text("**You can try to improve the reliability by exploring larger tank sizes.**")
                                }.font(.caption).listRowBackground(AppColors.lightBlue)
                            }
                           
                        }.listRowBackground(AppColors.lightBlue)
                       
                    }
                    
                }
                .font(.headline)
            }
            
            
            HStack {
                Button(action: {
                    Task {
                        saveVolumeM3()
                        tankSizeIsSet = true
                    }
                    print("saved")
                    // return to the main view
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Save").frame(width: 100)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.blue)
                        .cornerRadius(10)
                }.buttonStyle(.borderless)
                       Spacer()
                Button(action: {
                    tankSizeIsSet = false
                    print("cancelled")
                    // return to the main view
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel").frame(width: 100)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.red)
                        .cornerRadius(10)
                }.buttonStyle(.borderless)
                      
            }.font(.headline).listRowBackground(AppColors.lightGray).frame(height: 40)
            
        }
        .onDisappear {
            userVolumeUnitSymbol = selectedVolumeUnit.symbol
        }
        .background(AppColors.lightBlue).scrollContentBackground(.hidden)
        .navigationTitle("Storage Tank Size")
        
       
        
    
    }
}

extension SetTankSizeView {
    
    private func convertVolume(oldUnit: UnitVolume, newUnit: UnitVolume) {
        
        if let volumeValue = Double(volumeString) {
            
            let oldMeasurment = Measurement(value: volumeValue, unit: oldUnit)
            let newMeasurment = oldMeasurment.converted(to: newUnit)
            
            let roundedValue = round(newMeasurment.value)
           
            volumeString = String(format: "%.0f", roundedValue)
        }
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
    
    func estimateRWHSreliability() async {
       
        let myTanka = SimInput(runOff: runOff, catchAreaM2: catchAreaM2, tankSizeM3: tankSizeM3, dailyDemands: demandModel.DailyDemandM3())
      
        simTankaVC.displayResults = []
        await self.simTankaVC.EstimateReliabilityOfUsersRWHS(myTanka: myTanka)
        self.reliabiltyOfSystem = simTankaVC.displayResults[0].annualSuccess
       
    }
}

#Preview {
    let persistenceController = PersistenceController.shared
    
   return  SetTankSizeView().environmentObject(DemandModel(managedObjectContext: persistenceController.container.viewContext))
        .environmentObject(SimTankaVC(managedObjectContext: persistenceController.container.viewContext))
}


