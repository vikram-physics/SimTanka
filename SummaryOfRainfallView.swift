//
//  SummaryOfRainfallView.swift
//  SimTanka-iOS
//
//  Created by Vikram Vyas on 06/10/23.
//
// Released under
// GNU General Public License v3.0 or later
// https://www.gnu.org/licenses/gpl-3.0-standalone.html

import SwiftUI

struct SummaryOfRainfallView: View {
    var body: some View {
       GeometryReader { geometery in
     
     List {
         Section {
             AnnualRainfallViewVC()
                .frame(height: geometery.size.height * 0.35)
         } header: {
             Text("Annual Rainfall").font(.subheadline)
         }.listRowBackground(AppColors.lightGray)
         
         Section {
             ThirtyDaysRainfallView()
                .frame(height: geometery.size.height * 0.45)
         } header: {
             Text("Thirty days rainfall").font(.subheadline)
         }.listRowBackground(AppColors.lightGray)


     }.listStyle(.insetGrouped)
         .navigationTitle("Rainfall")
            
           
        }
        
     /*   List {
            Section {
                AnnualRainfallViewVC()
            } header: {
                Text("Annual Rainfall").font(.subheadline)
            }.listRowBackground(AppColors.lightGray)
            
            Section {
                ThirtyDaysRainfallView()
            } header: {
                Text("Thirty days rainfall").font(.subheadline)
            }.listRowBackground(AppColors.lightGray)


        }.listStyle(.insetGrouped)
            .navigationTitle("Rainfall") */
        
    }
}

