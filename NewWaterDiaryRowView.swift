//
//  NewWaterDiaryRowView.swift
//  SimTanka-iOS
//
//  Created by Vikram Vyas on 22/08/23.
//
// Released under
// GNU General Public License v3.0 or later
// https://www.gnu.org/licenses/gpl-3.0-standalone.html

import SwiftUI

struct NewWaterDiaryRowView: View {
    
    @EnvironmentObject var myTankaUnits: TankaUnits
    let diary:WaterDiary?
    
    // for displaying users chosen units
    @AppStorage("userVolumeUnitSymbol") private var userVolumeUnitSymbol: String = Region.preferredVolumeUnit().symbol
    @State private var selectedVolumeUnit = Region.preferredVolumeUnit()
    
    
    var body: some View {
        VStack(spacing: 2) {
            VStack (spacing: 0) {
                
                HStack { //Spacer()
                    Text("**\(dateString())**").font(.subheadline)
                    Spacer()
                }.padding(.horizontal)
                
                VStack(spacing: 2) {
                   // Spacer()
                  
                    HStack {
                        Text("Water in the tank: \(volumeInTankString(volumeInM3:diary!.amountM3))")
                            .font(.caption)
                        Spacer()
                    }.padding(.horizontal)
                   
                    if diary!.amountM3 != 0.0 {
                        HStack {
                           
                            Text("Water is \(Potable(rawValue: Int(diary!.potable))!.text)")
                                .foregroundColor(Potable(rawValue: Int(diary!.potable))!.text == "Potable" ? .blue : .red)
                            Spacer()
                        }.padding(.horizontal)
                    }
                    
                    if isAnyCheckDisplayed(diary: diary!) {
                        VStack(spacing: 2) {
                            HStack{
                                Text("Maint. Required ").font(.caption).foregroundStyle(.black)
                                Spacer()
                                
                            }.padding(.horizontal)
                           
                            HStack{
                                
                                if diary!.roofCheck {
                                    VStack{
                                        Text("Roof")
                                        Image(systemName: diary!.roofCheck ? "wrench.and.screwdriver.fill" : "circle")
                                    }
                                
                                }
                                if diary!.firstFlushCheck {
                                    VStack{
                                        Text("First Flush")
                                        Image(systemName: diary!.firstFlushCheck ? "wrench.and.screwdriver.fill" : "circle")
                                    }
                                }
                                if diary!.plumbingCheck {
                                    VStack{
                                        Text("Plumbing")
                                        Image(systemName: diary!.plumbingCheck ? "wrench.and.screwdriver.fill" : "circle")
                                    }
                                }
                                if diary!.waterFilterCheck {
                                    VStack{
                                        Text("Filter")
                                        Image(systemName: diary!.waterFilterCheck ? "wrench.and.screwdriver.fill" : "circle")
                                    }
                                }
                                if diary!.tankCheck {
                                    VStack {
                                        Text("Tank")
                                        Image(systemName: diary!.tankCheck ? "wrench.and.screwdriver.fill" : "circle")
                                    }
                                }
                                
                            }.font(.caption2)
                        }.foregroundColor(.red)//.padding(4)
                    } else {
                        HStack{
                            Text("No maintenance required").font(.caption)
                            Spacer()
                        }.padding(.horizontal)
                    }
                     
                }.font(.caption)
            }
            
           
            
            
            
            if  let diaryText = diary!.diaryEntry  {
                
                HStack {
                    Spacer()
                    Text(diaryText)
                        .lineLimit(1)
                        .font(.caption)
                        //.italic() // Apply italic style
                    Spacer()
                }
                //.padding(.horizontal)
                .overlay(
                  RoundedRectangle(cornerRadius: 7)
                    .stroke(Color.gray, lineWidth: 1)
                )
                .padding(.horizontal)
               

                
            }
            
        }//.background(AppColors.newBlue)
        .onAppear{
            loadUserPrefVolUnit()
        }
        //.background(AppColors.lightBlue)
    }
}

extension NewWaterDiaryRowView {
    
    func dateString() -> String {
       
        if diary?.day != 0 {
           
           // return String(diary!.day) + " " +  Helper.intMonthToShortString(monthInt: Int(diary!.month)) + String(diary!.year)
            return Helper.FormatDateToString(day: Int(diary!.day), month: Int(diary!.month), year: Int(diary!.year))
            
        } else {
            
            return "\(Helper.intMonthToShortString(monthInt: Int(diary!.month))) \(String(diary!.year))"
        }
        
        
    }
    
    func isAnyCheckDisplayed(diary: WaterDiary) -> Bool {
        return diary.roofCheck || diary.firstFlushCheck || diary.plumbingCheck || diary.waterFilterCheck || diary.tankCheck
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
struct NewWaterDiaryRowView_Previews: PreviewProvider {
    static var persistenceController = PersistenceController.shared
    static var diary = WaterDiary(context: persistenceController.container.viewContext)
    
    static var previews: some View {
        NewWaterDiaryRowView(diary: diary)
            .environmentObject(TankaUnits())
            .frame(height: 100)
    }
}
