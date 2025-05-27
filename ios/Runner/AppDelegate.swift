import UIKit
import Flutter
import GoogleMaps
import CoreLocation
import AppTrackingTransparency
import AdSupport

@main
@objc class AppDelegate: FlutterAppDelegate {
  let locationManager = CLLocationManager()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Provide your Google Maps API Key
    GMSServices.provideAPIKey("AIzaSyDG1roweyac5cUo0BtdFd6w7ENRI5tF-Nc")
    
    // Register plugins
    GeneratedPluginRegistrant.register(with: self)
    
    // Request tracking authorization for iOS 14+
    if #available(iOS 14, *) {
      ATTrackingManager.requestTrackingAuthorization { status in
        // Handle status if needed
        switch status {
        case .authorized:
          print("Tracking Authorized")
        case .denied:
          print("Tracking Denied")
        case .restricted:
          print("Tracking Restricted")
        case .notDetermined:
          print("Tracking Not Determined")
        @unknown default:
          break
        }
      }
    }

    // Request location permissions
    locationManager.requestAlwaysAuthorization()
    locationManager.requestWhenInUseAuthorization()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
