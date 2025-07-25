//
//  SavedPatientDetailView.swift
//  Metal Camera
//
//  Created by Nate  on 7/25/25.
//  Copyright © 2025 Old Yellow Bricks. All rights reserved.
//

import CoreGraphics
import SwiftUI

struct SavedPatientDetailView: View {
    let patient: Patient
    
    var body: some View {
        VStack {
            Text("\(patient.firstName)")
                .font(.title)
                .padding(.top)
            // left image
            // right image,
            
            //
            
            // if no left image insert a place holder
            // if no right image insert a plae holder
            // add a button to the right or left image, which ever is missing
            
            //
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    // Navigate to Dashboard & Save right/left
                    // Navigate to CameraView Right/Left & Save right/left
                }
            }
        }
    }
}

#Preview {
    SavedPatientDetailView(patient: Patient(firstName: "John Doe", lastName: "Smith"))
}

