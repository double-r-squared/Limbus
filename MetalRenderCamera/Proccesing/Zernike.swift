//
//  Zernike.swift
//  Metal Camera
//
//  Created by Nate  on 7/19/25.
//  Copyright © 2025 Old Yellow Bricks. All rights reserved.
//

import Foundation
import SwiftUI

extension PatientDetailView {
    
    // MARK: - Polar Data Processing
    /// Converts ringCenters data to flat (r, theta, z) coordinates with adaptive parabolic height function.
    /// - Returns: Tuple of three arrays: radii (r), angles (theta), and heights (z).
    // MARK: - Polar Data Processing
    
    // Data structure to hold angle and its heights
    typealias RadiusHeightAtAngleData = [Int: [(radius: Double, height: Double)]]

    func processPolarData() -> ([Double], [Double], [Double], RadiusHeightAtAngleData) {
        var rList: [Double] = []
        var thetaList: [Double] = []
        var zList: [Double] = []
        var radiusHeightData: RadiusHeightAtAngleData = [:]
        
        let angles = ringCenters.keys.sorted()
        
        guard !angles.isEmpty, angles.count == ringCenters.keys.count else {
            print("Error: Number of angles must match number of rays in ringCenters")
            return ([], [], [], [:])
        }
        
        for angle in angles {
            guard let rings = ringCenters[angle] else { continue }
            var radiusHeightPairs: [(radius: Double, height: Double)] = []
            
            let rayRadii = rings.map { $0.radius }
            
            for (index, radius) in rayRadii.enumerated() {
                rList.append(radius)
                thetaList.append(Double(angle) * .pi / 180.0)
                
                // Adaptive paraboloid function
                var j: Double = 0
                if index > 0 {
                    let distance = abs(rayRadii[index] - rayRadii[index - 1])
                    j = distance < 5.5 ? distance - 5.5 : 5.5 - distance
                }
                let z = 0.01 * pow((Double(index) + j), 2)
                zList.append(z)
                
                radiusHeightPairs.append((radius: radius, height: z))
            }
            
            radiusHeightData[angle] = radiusHeightPairs
        }
        
        return (rList, thetaList, zList, radiusHeightData)
    }
    
    // MARK: - Zernike Analysis
    
    func zernikePolynomial(n: Int, m: Int, rho: [Double], theta: [Double]) -> [Double] {
        guard abs(m) <= n && (n - abs(m)) % 2 == 0 else {
            return Array(repeating: 0.0, count: rho.count)
        }
        
        var R = Array(repeating: 0.0, count: rho.count)
        for k in 0...(n - abs(m)) / 2 {
            let coeff = pow(-1.0, Double(k)) * factorial(n - k) /
                (factorial(k) * factorial((n + abs(m)) / 2 - k) * factorial((n - abs(m)) / 2 - k))
            for i in 0..<rho.count {
                R[i] += coeff * pow(rho[i], Double(n - 2 * k))
            }
        }
        
        let norm = m == 0 ? sqrt(Double(n + 1)) : sqrt(2.0 * Double(n + 1))
        var Z = Array(repeating: 0.0, count: rho.count)
        for i in 0..<rho.count {
            let angular = m >= 0 ? cos(Double(m) * theta[i]) : sin(Double(abs(m)) * theta[i])
            Z[i] = norm * R[i] * angular
            if rho[i] > 1 {
                Z[i] = .nan
            }
        }
        
        return Z
    }
    
    func factorial(_ n: Int) -> Double {
        guard n >= 0 else { return 1.0 }
        return n == 0 ? 1.0 : Double(n) * factorial(n - 1)
    }
    
    func analyzePolarData(maxOrder: Int = 6) {
        isProcessing = true
        defer { isProcessing = false }
        
        var angles = ringCenters.keys.sorted()
        var (r, theta, z, radiusHeightAtAngle) = processPolarData()
        guard !r.isEmpty else {
            zernikeCoefficients = []
            zernikeModes = []
            self.radiusHeightAtAngle = [:] 
            return
        }
        
        let maxR = r.max() ?? 1.0
        let rNorm = r.map { maxR > 0 ? $0 / maxR : $0 }
        
        var modes: [(n: Int, m: Int)] = []
        for n in 0...maxOrder {
            for m in -n...n where (n - abs(m)) % 2 == 0 {
                modes.append((n, m))
            }
        }
        
        var A = Array(repeating: Array(repeating: 0.0, count: modes.count), count: r.count)
        for i in 0..<modes.count {
            let (n, m) = modes[i]
            let zernikeValues = zernikePolynomial(n: n, m: m, rho: rNorm, theta: theta)
            for j in 0..<r.count {
                A[j][i] = zernikeValues[j]
            }
        }
        
        // Simplified least-squares: A^T A x = A^T z
        let AT = transpose(A)
        let ATA = matrixMultiply(AT, A)
        let ATz = matrixVectorMultiply(AT, z)
        let coefficients = solveLeastSquares(ATA, ATz) ?? []
        
        zernikeCoefficients = coefficients
        zernikeModes = modes
        self.radiusHeightAtAngle = radiusHeightAtAngle // ← Save it here
    }
    
    func transpose(_ matrix: [[Double]]) -> [[Double]] {
        let rows = matrix.count
        let cols = matrix.first?.count ?? 0
        var result = Array(repeating: Array(repeating: 0.0, count: rows), count: cols)
        for i in 0..<rows {
            for j in 0..<cols {
                result[j][i] = matrix[i][j]
            }
        }
        return result
    }
    
    func matrixMultiply(_ A: [[Double]], _ B: [[Double]]) -> [[Double]] {
        let rowsA = A.count
        let colsA = A.first?.count ?? 0
        let colsB = B.first?.count ?? 0
        var result = Array(repeating: Array(repeating: 0.0, count: colsB), count: rowsA)
        for i in 0..<rowsA {
            for j in 0..<colsB {
                for k in 0..<colsA {
                    result[i][j] += A[i][k] * B[k][j]
                }
            }
        }
        return result
    }
    
    func matrixVectorMultiply(_ A: [[Double]], _ v: [Double]) -> [Double] {
        let rows = A.count
        let cols = A.first?.count ?? 0
        var result = Array(repeating: 0.0, count: rows)
        for i in 0..<rows {
            for j in 0..<cols {
                result[i] += A[i][j] * v[j]
            }
        }
        return result
    }
    
    func solveLeastSquares(_ A: [[Double]], _ b: [Double]) -> [Double]? {
        guard A.count == A.first?.count, A.count == b.count else { return nil }
        let n = A.count
        var x = Array(repeating: 0.0, count: n)
        
        // Gauss-Jordan elimination (simplified)
        var augmented = A
        for i in 0..<n {
            augmented[i].append(b[i])
        }
        
        for i in 0..<n {
            let pivot = augmented[i][i]
            guard pivot != 0 else { return nil }
            for j in i..<n + 1 {
                augmented[i][j] /= pivot
            }
            for k in 0..<n where k != i {
                let factor = augmented[k][i]
                for j in i..<n + 1 {
                    augmented[k][j] -= factor * augmented[i][j]
                }
            }
        }
        
        for i in 0..<n {
            x[i] = augmented[i][n]
        }
        return x
    }
}
