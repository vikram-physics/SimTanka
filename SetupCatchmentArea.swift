//
//  SetupCatchmentArea.swift
//  SimTanka-iOS
//
//  Created by Vikram Vyas on 22/09/23.
//
// Released under
// GNU General Public License v3.0 or later
// https://www.gnu.org/licenses/gpl-3.0-standalone.html

import SwiftUI

struct SetupCatchmentArea: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @AppStorage("runOff") var runOff = 0.0
    @AppStorage("catchAreaM2") private var catchAreaM2 = 0.0
    @AppStorage("preferredAreaUnitSymbol") private var preferredAreaUnitSymbol: String = UnitArea.squareMeters.symbol
    @AppStorage("catchAreaIsSet") var catchAreaIsSet = false
    
    @State private var userRunOff = RunOff.Roof
    @State private var areaString: String = ""
    
    @State private var selectedAreaUnit = Region.preferredAreaUnit()
    @State private var oldAreaUnit  = Region.areaUnits().first!
    @State private var isAlertPresented = false
    
    @State private var alertMsg = ""
    
    var body: some View {
       
        List{
            // runoff coeffiecient
            
            Section("Type of surface") {
                
                HStack {
                    Text("Choose the surface from which your RWHS will collect rain.")
                        .font(.headline)
                }.listRowBackground(AppColors.lightGray)
                
                Picker("Runoff", selection: $userRunOff){
                    ForEach(RunOff.allCases, id:\.self){
                        Text($0.text)
                            
                    }
                }.pickerStyle(SegmentedPickerStyle())
                .listRowBackground(AppColors.myColor5)
                .font(.subheadline)
                .onChange(of: userRunOff) { newValue in
                                saveRunOff()
                            }
                    
                
                Text("You will be able to collect approx " + String(userRunOff.rawValue * 100) + " % of rain.")
                    .listRowBackground(AppColors.myColor4)
                    .foregroundColor(Color.white).font(.caption)
            }
              
            Section("Area of your collecting surface") {
                
                HStack {
                    Text("Enter the area of your collecting surface (\(userRunOff.text))")
                        .font(.headline)
                }.listRowBackground(AppColors.lightGray)
                
                HStack {
                    
                    
                                    TextField("Catchment Area", text: $areaString)
                                        .keyboardType(.numberPad)
                                        .onChange(of: areaString) { newValue in
                                                        // write a function to save area in sq meter
                                                        saveAreaInM2()
                                                       // print("saved area in square meter = ", catchAreaM2)
                                                    }
                                        .onTapGesture {
                                            // Dismiss the keyboard when tapped outside the text field
                                            hideKeyboard()
                                        }
                    
                                    Spacer()
                    
                                    Picker("", selection: $selectedAreaUnit) {
                                        ForEach(Region.areaUnits(), id: \.self) { unit in
                                            Text(unit.symbol)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .onTapGesture {
                                        oldAreaUnit = selectedAreaUnit
                                    }
                                    .onChange(of: selectedAreaUnit) { newValue in
                                        // change the area string to
                                        // the area string in new units
                                      //  print("Old area unit is ", oldAreaUnit.symbol)
                                       // print("New unit is ", newValue.symbol)
                                        convertArea(oldUnit: oldAreaUnit, newUnit: newValue)
                                        
                                                }
                                }
                
                if catchAreaM2 != 0 {
                    HStack {
                        Text("Catchement area of your RWHS is \(loadCatchArea()) and your collecting surface is: \(userRunOff.text)")
                            .foregroundColor(Color.white).font(.caption)
                    }.listRowBackground(AppColors.myColor4)
                        
                    
                   
                }
                
                
            
                
            }
            
            HStack {
                Button {
                    //  give user the choice to save catcharea and runoff
                    
                    /*
                    Task {
                        saveRunOff()
                        saveAreaInM2()
                        catchAreaIsSet = true
                    } */
                    self.isAlertPresented = true
                    // return to the main view
                   // presentationMode.wrappedValue.dismiss()
                } label: {
                    
                    Text("Save")
                        .frame(maxWidth: .infinity).frame(height: 40)
                         .background(
                             RoundedRectangle(cornerRadius: 15)
                                                    .fill(Color.blue) // Adjust the background color as needed
                          )
                         .foregroundColor(.white) // Text color
                         .font(.headline) // Text font
                   
                }
                .disabled((catchAreaM2 == 0.0))
                .opacity(catchAreaM2 == 0.0 ? 0.5 : 1.0)
                
               

            }.listRowBackground(AppColors.lightGray)
            
          /*  HStack {
                Spacer()
                Button(action: {
                    // Add any actions you need before dismissing the view
                    presentationMode.wrappedValue.dismiss()
                    catchAreaIsSet = false
                }) {
                    Text("Cancel")
                        .font(.headline) // Customize the text font and size
                        .padding(10) // Add padding to make it compact
                        .foregroundColor(.red) // Customize the button's text color
                        .background(RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white) // Background color
                            .shadow(color: .gray, radius: 2, x: 0, y: 2) // Add a subtle shadow
                        )
                }
                Spacer()
            } */
            
        }
        .onDisappear {
            // save the users prefered unit
            preferredAreaUnitSymbol = selectedAreaUnit.symbol
        }
        .navigationTitle("Catchment Area")
        .navigationBarBackButtonHidden(true)
        .alert("Saving catchment area", isPresented: $isAlertPresented) {
            Button("Save", role: .destructive) {
                        Task {
                            saveRunOff()
                            saveAreaInM2()
                            catchAreaIsSet = true
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                    Button("Cancel", role: .cancel) {
                        // No action needed here
                    }
        } message: {
            Text("Catchement area of your RWHS is \(loadCatchArea()) and your collecting surface is: \(userRunOff.text). You will not be able to change it later.")
        }

        
    }
}

extension SetupCatchmentArea {
    
    func saveRunOff() {
        runOff = userRunOff.rawValue
        
    }
    
    func loadRunOff() {
           if let matchingRunOff = RunOff(rawValue: runOff) {
               userRunOff = matchingRunOff
           }
        
       }
    
    
    func saveAreaInM2() {
        
        // get the area string
        // get the user unit
        // convert the area into m2
        // save to appstorage
        
        if let areaValue = Double(areaString) {
            
            let userMeasurment = Measurement(value: areaValue, unit: selectedAreaUnit)
            let simTankaMeasurment = userMeasurment.converted(to: .squareMeters)
            catchAreaM2 = simTankaMeasurment.value
            
        }
    }
    
    func loadCatchArea() -> String {
        
        
        
        // area in square meter
        let simTankaArea = Measurement(value: catchAreaM2, unit: UnitArea.squareMeters)
        
        // area in users prefered unit
        let userCatchArea = simTankaArea.converted(to: selectedAreaUnit)
       
        // set the area string
        let roundedValue = round(userCatchArea.value)
        return String(format: "%.0f", roundedValue) + String(" ") + String(selectedAreaUnit.symbol)
    }
    
    
    
    private func convertArea(oldUnit: UnitArea, newUnit: UnitArea) {
           if let areaValue = Double(areaString) {
               let oldMeasurement = Measurement(value: areaValue, unit: oldUnit)
               let newMeasurement = oldMeasurement.converted(to: newUnit)
             
               let roundedValue = round(newMeasurement.value)
              
               areaString = String(format: "%.0f", roundedValue)
           }
       }
  
}

#Preview {
    SetupCatchmentArea()
}
