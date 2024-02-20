//
//  WaterDiaryListView.swift
//  SimTanka-iOS
//
//  Created by Vikram  on 15/06/22.
//
// Released under
// GNU General Public License v3.0 or later
// https://www.gnu.org/licenses/gpl-3.0-standalone.html

import SwiftUI

struct WaterDiaryListView: View {
    
    @EnvironmentObject var waterDiaryModel:WaterDiaryModel
    
    let colors = [AppColors.lightBlue, AppColors.lightGray]
   
    var body: some View {
        
       
            VStack {
               
              /*  List {
                               ForEach(waterDiaryModel.waterDiaryArray) { diary in
                                   
                                   let rowColor = colors[abs(diary.id.hashValue) % colors.count]
                                   NavigationLink(destination: DailyWaterDiaryEditView(diary: diary)) {
                                       HStack {
                                           NewWaterDiaryRowView(diary: diary)
                                               .id(diary.id)//.frame(height: 145)
                                       }.padding(.vertical)
                                        .cornerRadius(10)       // Add corner radius to create a rounded border
                                        
                                      
                                       
                                   }
                                   .id(diary.id)
                                      .background(rowColor)
                                   .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)) // Adjust row spacing
                               }
                               .onDelete(perform: waterDiaryModel.deleteDiary)
                           }  */
                
                List {

                 // let colors = [AppColors.lightBlue, AppColors.lightGray]

                  ForEach(waterDiaryModel.waterDiaryArray.indices, id: \.self) { index in

                    let diary = waterDiaryModel.waterDiaryArray[index]
                    let rowColor = colors[index % colors.count]

                    NavigationLink(destination: DailyWaterDiaryEditView(diary: diary)) {

                      // ...
                        HStack {
                            NewWaterDiaryRowView(diary: diary)
                                .id(diary.id)//.frame(height: 145)
                        }.padding(.vertical)
                        
                         

                    }
                    .background(rowColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                  }.onDelete(perform: waterDiaryModel.deleteDiary)

                }
                
               
                          

                
                // create a button for adding new entry
                Spacer()
                if waterDiaryModel.noRecordForToday() {
                  
                    NavigationLink(destination: DailyAddWaterDiaryView()) {
                                       Text("Add new diary entry")
                                           .font(.headline)
                                           .padding()
                                          // .frame(maxWidth: .infinity)
                                           .background(Color.purple)
                                           .foregroundColor(.white)
                                           .cornerRadius(10)
                                           .shadow(color: .gray, radius: 2, x: 0, y: 2)
                                           .padding(.horizontal, 20)
                                   }
                                   .buttonStyle(PlainButtonStyle()) // Remove the default button style
                                   .padding(5)
                }
               
                Spacer()
                
            }.navigationTitle(Text("Water Diary"))
            .navigationBarTitleDisplayMode(.inline)
        
    }
       
    }


extension WaterDiaryListView {
    
    func deleteDiary(at offsets: IndexSet) {
            waterDiaryModel.deleteDiary(at: offsets)
        }
}

struct WaterDiaryListView_Previews: PreviewProvider {
    static var persistenceController = PersistenceController.shared
    static var previews: some View {
        WaterDiaryListView()
            .environmentObject(WaterDiaryModel(managedObjectContext: persistenceController.container.viewContext))
    }
}
