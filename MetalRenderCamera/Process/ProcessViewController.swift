//
//  ProcessViewController.swift
//  Metal Camera
//
//  Created by Nate  on 7/9/25.
//  Copyright © 2025 Old Yellow Bricks. All rights reserved.
//

import Foundation
import UIKit

class ProcessViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    
    
    
    
    
    internal class PreProcessing {
        
        // Helps reduce dimensionality speed up processing
        func cropAroundCenter(){
            
        }
        
        // Adjusts setting the virtual center based on the center detected in the image
        func reCenter() {
            
        }
        
        // Extracts pixels that are bright (rings) exclusivley from image.
        func binaryThreshold() {
            
        }
        
    }


    internal class Processing {
        
        // Extras points of bright pixels (rings) radially from center
        func ExtractPoints() {
            
        }
        
    }


    internal class PostProcessing {
        func trimMaxRings() {
            
        }
        
        
    }

    // MARK: User Removes or gets new image
    internal class ManualProcess {
        
        // Restarts the capture process and deletes all captured data
        func reset() {
            
        }
        
        // When a user removes a point manualually
        func removePoint() {
            
        }
        
    }

    internal class Restart {
        // Removes generated processing data
        fileprivate func removeData() {
            
        }
        
        fileprivate func restartCapture() {
            
        }
    }


}
