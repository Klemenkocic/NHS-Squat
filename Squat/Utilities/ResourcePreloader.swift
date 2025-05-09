import UIKit
import SwiftUI

/// Utility class to preload and cache resources at app launch
class ResourcePreloader {
    static let shared = ResourcePreloader()
    
    private init() {}
    
    /// Preloads essential images to avoid UI jank when they are first displayed
    func preloadImages() {
        // List of key image names to preload
        let imageNames = [
            "welcome_bg",
            "apple_icon",
            "apple_icon_white",
            "google_icon"
        ]
        
        // Load each image into memory
        for imageName in imageNames {
            if let _ = UIImage(named: imageName) {
                // Image loaded successfully into cache
                print("Preloaded image: \(imageName)")
            }
        }
    }
    
    /// Warms up any slow-to-initialize services
    func warmupServices() {
        // This is where you would initialize any services that should be
        // ready when the user interacts with the app
    }
    
    /// Preload all essential resources
    func preloadAll() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.preloadImages()
            self?.warmupServices()
            
            DispatchQueue.main.async {
                print("Resource preloading complete")
            }
        }
    }
} 