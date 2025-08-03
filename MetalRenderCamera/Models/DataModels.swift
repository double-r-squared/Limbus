//
//  EyeData.swift
//  MetalRenderCamera
//
//  Created by Nate  on 7/24/25.
//  Copyright © 2025 Old Yellow Bricks. All rights reserved.
//

import SwiftUI
import SwiftData

@Model
class Patient {
    var firstName: String
    var lastName: String
    var age: Int?
    var email: String?
    var phone: String?
    var address: String?
    var eyeData: EyeData?
    
    init(firstName: String, lastName: String, age: Int? = nil, email: String? = nil, phone: String? = nil, address: String? = nil, eyeData: EyeData? = nil) {
        self.firstName = firstName
        self.lastName = lastName
        self.age = age
        self.email = email
        self.phone = phone
        self.address = address
        self.eyeData = eyeData
    }
}

@Model
class EyeData {
    var leftEyeNotes: String?
    var rightEyeNotes: String?
    var leftEyeImages: ImageStore?
    var rightEyeImages: ImageStore?
    var leftEyeScore: Double?
    var rightEyeScore: Double?
    var leftEyeTimestamp: Date?
    var rightEyeTimestamp: Date?
    
    init(leftEyeNotes: String? = nil, rightEyeNotes: String? = nil, leftEyeImages: ImageStore? = nil, rightEyeImages: ImageStore? = nil, leftEyeScore: Double? = nil, rightEyeScore: Double? = nil, leftEyeTimestamp: Date? = nil, rightEyeTimestamp: Date? = nil) {
        self.leftEyeNotes = leftEyeNotes
        self.rightEyeNotes = rightEyeNotes
        self.leftEyeImages = leftEyeImages
        self.rightEyeImages = rightEyeImages
        self.leftEyeScore = leftEyeScore
        self.rightEyeScore = rightEyeScore
        self.leftEyeTimestamp = leftEyeTimestamp
        self.rightEyeTimestamp = rightEyeTimestamp
    }
}

@Model
class ImageStore {
    var eyeType: EyeType
    var original: Data?
    var heatmap: Data?
    var lensFit: Data?
    var avatarImageData: Data?
    
    init(eyeType: EyeType, original: Data? = nil, heatmap: Data? = nil, lensFit: Data? = nil, avatarImageData: Data? = nil) {
        self.eyeType = eyeType
        self.original = original
        self.heatmap = heatmap
        self.lensFit = lensFit
        self.avatarImageData = avatarImageData
    }
    
    func image(for key: KeyPath<ImageStore, Data?>) -> Image? {
        guard let data = self[keyPath: key], let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
    }
}

enum EyeType: String, CaseIterable, Codable {
    case left = "Left Eye"
    case right = "Right Eye"
    
    var displayName: String {
        return rawValue
    }
}

// Used to standardize the rest of the pipline.
@Model
class CalibrationData {
    var ringCenters: [Int: [(radius: Double, x: Double, y: Double)]]?
    var zernikeCoefficients: [Double]?
    var zernikeModes: [(n: Int, m: Int)]?
    
    init(
        ringCenters: [Int: [(radius: Double, x: Double, y: Double)]]? = nil, zernikeCoefficients:[Double]? = nil, zernikeModes: [(n: Int, m: Int)]? = nil) {
        self.ringCenters = ringCenters
        self.zernikeCoefficients = zernikeCoefficients
        self.zernikeModes = zernikeModes
    }
}
