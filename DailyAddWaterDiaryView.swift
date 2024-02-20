//
//  DailyAddWaterDiaryView.swift
//  SimTanka-iOS
//
//  Created by Vikram  on 20/08/23.
//
// Released under
// GNU General Public License v3.0 or later
// https://www.gnu.org/licenses/gpl-3.0-standalone.html

import SwiftUI

struct DailyAddWaterDiaryView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var myTankaUnits: TankaUnits
    @EnvironmentObject var waterDiaryModel:WaterDiaryModel
    
    @AppStorage("tankSizeM3") private var tankSizeM3 = 1000.0
    
    @StateObject private var viewModel = DailyWaterDiaryViewModel()
    
    var body: some View {
        
        List {
           
            
            Section(header: Text("Water in the tank \(Helper.FormatDate(date: Date()))")) {
                
                VStack {
                  
                    
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
                        Text("Amount of water in the tank = " + Helper.formattedNumber(numberString: Helper.VolumeStringFrom(volumeM3: viewModel.waterInTank, volumeUnit: myTankaUnits.volumeUnit)) + myTankaUnits.volumeUnit.text)

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
                        Text("Plumbing").foregroundColor(.black)
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
            
            VStack {
                HStack{Spacer()
                    Text("Water Diary for \(Helper.FormatDate(date: Date()))").fontWeight(.light).textCase(.uppercase).font(.caption)
                    Spacer()
                }.listRowBackground(AppColors.myColorOne)
                
                TextEditor(text: $viewModel.maintenanceComments)
                    .font(.caption2)
                 .scrollContentBackground(.hidden)
                 .padding()
                 .foregroundColor(.blue)
                 .background(Color.green.opacity(0.7))
                 .frame(width: 350, height: 100)
                 .cornerRadius(20)
                 .onTapGesture {
                     self.hideKeyboard()
             }
            }
            
         /*   HStack {
                Spacer()
                Button(action: {
                    self.saveEntryToCoreData()
                    self.presentationMode.wrappedValue.dismiss()
                }, label: {
                    HStack{
                        Spacer()
                        Image(systemName: "square.and.arrow.down.on.square.fill")
                        Text("Save").font(.headline)
                        Spacer()
                    }.font(.caption)
                        .frame(width: 200, height:30)
                        .padding(1)
                        .background(AppColors.lightGray)
                        .foregroundColor(Color.black)
                        .clipShape(Capsule())
                    
            })
                Spacer()
            } */
            
        }
        .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            Button(action: {
                                saveEntryToCoreData()
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(systemName: "square.and.arrow.down.on.square.fill")
                                Text("Save")
                            }
                        }
                    }
                }
    }
}

extension DailyAddWaterDiaryView {
    func saveEntryToCoreData() {
        
        // obtain the day, month, year
        
        viewModel.day = Int16(Helper.DayFromDate(date: Date())) //
        viewModel.month = Int16(Helper.MonthFromDate(date: Date()))
        viewModel.year = Int16(Helper.YearFromDate(date: Date()))
        
        // save to core data
        waterDiaryModel.saveWaterDiary(viewModel: viewModel)
    }
}

struct DailyAddWaterDiaryView_Previews: PreviewProvider {
    
    static var persistenceController = PersistenceController.shared
    
    static var previews: some View {
        DailyAddWaterDiaryView()
            .environmentObject(TankaUnits())
            .environmentObject(WaterDiaryModel(managedObjectContext: persistenceController.container.viewContext))
    }
}
