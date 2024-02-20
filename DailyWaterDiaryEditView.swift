//
//  DailyWaterDiaryEditView.swift
//  SimTanka-iOS
//
//  Created by Vikram Vyas on 25/08/23.
//
// Released under
// GNU General Public License v3.0 or later
// https://www.gnu.org/licenses/gpl-3.0-standalone.html

import SwiftUI

struct DailyWaterDiaryEditView: View {
    
    @Environment(\.presentationMode) var presentationMode
 
    @EnvironmentObject var waterDiaryModel:WaterDiaryModel
    
    @AppStorage("tankSizeM3") private var tankSizeM3 = 1000.0
    
    @StateObject private var viewModel = DailyWaterDiaryViewModel()
    
    let diary:WaterDiary?
    
    // for displaying users chosen units
    @AppStorage("userVolumeUnitSymbol") private var userVolumeUnitSymbol: String = Region.preferredVolumeUnit().symbol
    @State private var selectedVolumeUnit = Region.preferredVolumeUnit()
    
    var body: some View {
        List{
            Section(header: Text("Water in the tank \(Helper.FormatDate(date: Date()))")) {
                
                VStack {
                  
                    HStack { Spacer()
                        Text("**\(dateString())**").font(.caption)
                        Spacer()
                    }
                    Text("Select the amount of water in the storage tank on:")
                        .foregroundColor(.black)
                        .font(.caption)
                    
                   
                    
                    Slider(value: $viewModel.waterInTank, in: 0...tankSizeM3).padding(0)
                    
                    // for markings
                    HStack {
                       // Spacer()
                        Text("0") // Zero mark
                            .font(.system(size: 10)) // Adjust font size
                        Spacer()
                        Text("1/4") // Quarter mark
                            .font(.system(size: 10)) // Adjust font size
                        Spacer()
                        Text("1/2") // Half mark
                            .font(.system(size: 10)) // Adjust font size
                        Spacer()
                        Text("3/4") // Three quarter mark
                            .font(.system(size: 10)) // Adjust font size
                        Spacer()
                        Text("Full") // Full mark
                            .font(.system(size: 10)) // Adjust font size
                       // Spacer()
                    }
                    .foregroundColor(.gray) // Adjust mark color
                    
                    // selected amount
                    HStack {
                        Text("Amount of water in the tank = \(volumeInTankString(volumeInM3:viewModel.waterInTank))")
                    }.font(.caption)
                    
                }.listRowBackground(AppColors.lightBlue)
                
               
                VStack {
                    Picker("Potable?", selection: $viewModel.potable){
                        ForEach(Potable.allCases, id:\.self){
                            Text($0.text)
                            
                        }

                    }
                }.pickerStyle(SegmentedPickerStyle())
                .listRowBackground(AppColors.lightBlue)
                .font(.caption)
            }
            
            Section(header: Text("Maintenance required \(Helper.FormatDate(date: Date()))"), content: {
                HStack{
                    Toggle(isOn: $viewModel.roofCleaned) {
                        Text("Collecting surface").foregroundColor(.black).font(.caption2)
                    }.toggleStyle(CheckboxToggleStyle())
                    
                }.listRowBackground(AppColors.lightBlue)
                 
               
                HStack {
                    Toggle(isOn:$viewModel.firstFlushChecked) {
                        Text("First flush").foregroundColor(.black)
                    }.toggleStyle(CheckboxToggleStyle())
                }.listRowBackground(AppColors.lightGray)
                
               
                
                HStack {
                    Toggle(isOn:$viewModel.plumbingChecked) {
                        Text("Pipes and gutters").foregroundColor(.black)
                    }.toggleStyle(CheckboxToggleStyle())
                }.listRowBackground(AppColors.lightBlue)
                
                HStack {
                    Toggle(isOn:$viewModel.waterFilterChecked) {
                        Text("Water filter").foregroundColor(.black)
                    }.toggleStyle(CheckboxToggleStyle())
                }.listRowBackground(AppColors.lightGray)
                
                HStack {
                    Toggle(isOn:$viewModel.tanksChecked) {
                        Text("Tanks").foregroundColor(.black)
                    }.toggleStyle(CheckboxToggleStyle())
                }.listRowBackground(AppColors.lightBlue)
                
                
                
                
                
            })
            
            TextEditor(text: $viewModel.maintenanceComments)
                .font(.caption2)
             .scrollContentBackground(.hidden)
             .padding()
             .foregroundColor(.black)
             .background(AppColors.lightGray)
             .frame(width: 350, height: 100)
             .cornerRadius(20)
             .onTapGesture {
                 self.hideKeyboard()
         }
          /*  HStack {
                Spacer()
                Button(action: {
                    self.savedEditedChanges()
                    self.presentationMode.wrappedValue.dismiss()
                }, label: {
                    HStack{
                        Spacer()
                        Image(systemName: "square.and.arrow.down.on.square.fill")
                        Text("Save Changes").font(.headline)
                        Spacer()
                    }.font(.caption)
                        .frame(width: 200, height:30)
                        .padding(5)
                        .background(AppColors.myColorThree)
                        .foregroundColor(Color.white)
                        .clipShape(Capsule())
                    
            })
                Spacer()
                
            } */
            
        }.onAppear {
            // covert diary into view model
            self.diaryToViewModel()
            loadUserPrefVolUnit()
        }
        .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            savedEditedChanges()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down.on.square.fill")
                                Text("Save")
                            }
                        }
                    }
                }
        
    }
}

extension DailyWaterDiaryEditView {
    
    func diaryToViewModel () {
        viewModel.day = Int16(diary!.day)
        viewModel.month = Int16(diary!.month)
        viewModel.year = Int16(diary!.year)
        
        viewModel.waterInTank = diary!.amountM3
        viewModel.potable = Potable(rawValue: Int(diary!.potable))!
        
        viewModel.firstFlushChecked = diary!.firstFlushCheck
        viewModel.tanksChecked = diary!.tankCheck
        viewModel.waterFilterChecked = diary!.waterFilterCheck
        viewModel.roofCleaned = diary!.roofCheck
        viewModel.plumbingChecked = diary!.plumbingCheck
        
        viewModel.maintenanceComments = diary!.diaryEntry ?? ""
        
    }
    
    func dateString() -> String {
       
        if diary?.day != 0 {
           
           // return String(diary!.day) + " " +  Helper.intMonthToShortString(monthInt: Int(diary!.month)) + String(diary!.year)
            return Helper.FormatDateToString(day: Int(diary!.day), month: Int(diary!.month), year: Int(diary!.year))
            
        } else {
            
            return "\(Helper.intMonthToShortString(monthInt: Int(diary!.month))) \(String(diary!.year))"
        }
        
        
    }
    
    func savedEditedChanges() {
        
        // save amount of water
        diary?.amountM3 = viewModel.waterInTank
        // save potability
        diary?.potable = Int16(viewModel.potable.rawValue)
        // save diary entry
        diary?.diaryEntry = viewModel.maintenanceComments
        // save roofCleaned
        diary?.roofCheck = viewModel.roofCleaned
        // save firstFlushChecked
        diary?.firstFlushCheck = viewModel.firstFlushChecked
        // save plumbingChecked
        diary?.plumbingCheck = viewModel.plumbingChecked
        // save waterfilterChecked
        diary?.waterFilterCheck = viewModel.waterFilterChecked
        // save tankChecked
        diary?.tankCheck = viewModel.tanksChecked
        
        
        // save to the data base
        waterDiaryModel.saveEditedWaterEntry()
    }
    
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
    
    private func volumeInTankString(volumeInM3: Double) -> String {
        
        
        // volume in cubic meter
        let volumeInM3Units = Measurement(value: volumeInM3, unit: UnitVolume.cubicMeters)
        
        // convert to users units
        let volumeInUserUnit = volumeInM3Units.converted(to: selectedVolumeUnit)
        
        // set the volume string
        let roundedValue = round(volumeInUserUnit.value)
        return String(format: "%.0f", roundedValue) + String(" ") + String(selectedVolumeUnit.symbol)
        
        
    }
}

struct DailyWaterDiaryEditView_Previews: PreviewProvider {
    static var persistenceController = PersistenceController.shared
    static var diary = WaterDiary(context: persistenceController.container.viewContext)
    static var previews: some View {
        DailyWaterDiaryEditView(diary: diary)
    }
}
