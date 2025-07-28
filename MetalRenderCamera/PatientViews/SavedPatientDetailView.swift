//
//  SavedPatientDetailView.swift
//  Metal Camera
//
//  Created by Nate  on 7/25/25.
//  Copyright © 2025 Old Yellow Bricks. All rights reserved.
//

import SwiftUI
import SwiftData

struct PatientInfoView: View {
    let patient: Patient
    let modelContext: ModelContext
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Patient Basic Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Patient Information")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    InfoRow(label: "First Name", value: patient.firstName)
                    InfoRow(label: "Last Name", value: patient.lastName)
                    
                    if let age = patient.age {
                        InfoRow(label: "Age", value: "\(age)")
                    }
                    
                    if let email = patient.email {
                        InfoRow(label: "Email", value: email)
                    }
                    
                    if let phone = patient.phone {
                        InfoRow(label: "Phone", value: phone)
                    }
                    
                    if let address = patient.address {
                        InfoRow(label: "Address", value: address)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // Eye Data Section
                if let eyeData = patient.eyeData {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Eye Data")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // Left Eye
                        EyeDataCard(
                            eyeType: "Left Eye",
                            timestamp: eyeData.leftEyeTimestamp,
                            notes: eyeData.leftEyeNotes,
                            score: eyeData.leftEyeScore,
                            imageStore: eyeData.leftEyeImages
                        )
                        
                        // Right Eye
                        EyeDataCard(
                            eyeType: "Right Eye",
                            timestamp: eyeData.rightEyeTimestamp,
                            notes: eyeData.rightEyeNotes,
                            score: eyeData.rightEyeScore,
                            imageStore: eyeData.rightEyeImages
                        )
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                } else {
                    VStack {
                        Image(systemName: "eye.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No eye data available")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Eye scans will appear here after completing a topography session")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
        }
    }
}

struct EyeDataCard: View {
    let eyeType: String
    let timestamp: Date?
    let notes: String?
    let score: Double?
    let imageStore: ImageStore?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(eyeType)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if timestamp != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
            
            if let timestamp = timestamp {
                Text("Last scan: \(timestamp, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("No scan data")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let score = score {
                HStack {
                    Text("Score:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f", score))
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            
            if let notes = notes, !notes.isEmpty {
                Text("Notes: \(notes)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Image thumbnails
            if let imageStore = imageStore {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if let originalData = imageStore.original, let image = UIImage(data: originalData) {
                            ThumbnailImage(image: image, label: "Original")
                        }
                        
                        if let heatmapData = imageStore.heatmap, let image = UIImage(data: heatmapData) {
                            ThumbnailImage(image: image, label: "Heatmap")
                        }
                        
                        if let lensFitData = imageStore.lensFit, let image = UIImage(data: lensFitData) {
                            ThumbnailImage(image: image, label: "Lens Fit")
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }
}

struct ThumbnailImage: View {
    let image: UIImage
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    let patient = Patient(firstName: "John", lastName: "Doe", age: 35, email: "john.doe@example.com")
    return NavigationView {
        PatientInfoView(patient: patient, modelContext: ModelContext(try! ModelContainer(for: Patient.self)))
    }
}
