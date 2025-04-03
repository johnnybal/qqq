import UIKit
import FirebaseAuth
import Contacts
import CoreLocation

private var currentStep = 0

// Add step enum
private enum OnboardingStep: Int, CaseIterable {
    case welcome
    case phoneVerification
    case profileCreation
    case permissions
    case schoolSelection
    case tutorial
    case premiumOffer
    
    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .phoneVerification: return "Phone Verification"
        case .profileCreation: return "Create Profile"
        case .permissions: return "Permissions"
        case .schoolSelection: return "Select School"
        case .tutorial: return "Tutorial"
        case .premiumOffer: return "Premium Offer"
        }
    }
}

// Content views for each step
private let stepViews: [UIView] = []

@objc private func moveToNextStep() {
    guard let currentStepEnum = OnboardingStep(rawValue: currentStep),
          currentStepEnum != .premiumOffer else {
        finishOnboarding()
        return
    }
    
    currentStep += 1
    
    // Remove current views
    for subview in view.subviews {
        subview.removeFromSuperview()
    }
    
    // Set up next step
    if let nextStep = OnboardingStep(rawValue: currentStep) {
        switch nextStep {
        case .welcome:
            setupWelcomeScreen()
        case .phoneVerification:
            setupPhoneVerification()
        case .profileCreation:
            setupProfileCreation()
        case .permissions:
            setupPermissions()
        case .schoolSelection:
            setupSchoolSelection()
        case .tutorial:
            setupTutorial()
        case .premiumOffer:
            setupPremiumOffer()
        }
    }
}

@objc private func verifyPhoneNumber() {
    guard let phoneNumber = phoneTextField.text, !phoneNumber.isEmpty else {
        showAlert(title: "Error", message: "Please enter a valid phone number")
        return
    }
    
    // Show loading indicator
    let loadingIndicator = UIActivityIndicatorView(style: .large)
    loadingIndicator.center = view.center
    view.addSubview(loadingIndicator)
    loadingIndicator.startAnimating()
    
    // Format phone number to E.164 format
    let formattedNumber = "+1\(phoneNumber.replacingOccurrences(of: "[^0-9]", with: ""))"
    
    PhoneAuthProvider.provider().verifyPhoneNumber(formattedNumber, uiDelegate: nil) { [weak self] verificationID, error in
        DispatchQueue.main.async {
            loadingIndicator.removeFromSuperview()
            
            if let error = error {
                self?.showAlert(title: "Error", message: error.localizedDescription)
                return
            }
            
            guard let verificationID = verificationID else {
                self?.showAlert(title: "Error", message: "Failed to get verification ID")
                return
            }
            
            // Store verification ID
            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            
            // Show verification code input
            self?.showVerificationCodeAlert()
        }
    }
}

private func showVerificationCodeAlert() {
    let alert = UIAlertController(title: "Enter Verification Code", 
                                message: "Please enter the code sent to your phone", 
                                preferredStyle: .alert)
    
    alert.addTextField { textField in
        textField.placeholder = "Verification Code"
        textField.keyboardType = .numberPad
    }
    
    let verifyAction = UIAlertAction(title: "Verify", style: .default) { [weak self] _ in
        guard let code = alert.textFields?.first?.text, !code.isEmpty else {
            self?.showAlert(title: "Error", message: "Please enter the verification code")
            return
        }
        
        self?.verifyCode(code)
    }
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
    
    alert.addAction(verifyAction)
    alert.addAction(cancelAction)
    
    present(alert, animated: true)
}

private func verifyCode(_ code: String) {
    guard let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") else {
        showAlert(title: "Error", message: "Missing verification ID")
        return
    }
    
    let credential = PhoneAuthProvider.provider().credential(
        withVerificationID: verificationID,
        verificationCode: code
    )
    
    // Show loading indicator
    let loadingIndicator = UIActivityIndicatorView(style: .large)
    loadingIndicator.center = view.center
    view.addSubview(loadingIndicator)
    loadingIndicator.startAnimating()
    
    Auth.auth().signIn(with: credential) { [weak self] authResult, error in
        DispatchQueue.main.async {
            loadingIndicator.removeFromSuperview()
            
            if let error = error {
                self?.showAlert(title: "Error", message: error.localizedDescription)
                return
            }
            
            // Successfully verified phone number
            self?.moveToNextStep()
        }
    }
}

private func showAlert(title: String, message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
}

class OnboardingViewController: UIViewController {
    
    // MARK: - Properties
    private let locationManager = CLLocationManager()
    private let contactStore = CNContactStore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    @objc private func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            showAlert(title: "Location Access Required",
                     message: "Please enable location access in Settings to continue",
                     showSettings: true)
        case .authorizedWhenInUse, .authorizedAlways:
            locationPermissionButton.backgroundColor = .systemGreen
            locationPermissionButton.setTitle("Location Enabled ✓", for: .normal)
            checkPermissionsStatus()
        @unknown default:
            break
        }
    }
    
    @objc private func requestContactsPermission() {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .notDetermined:
            contactStore.requestAccess(for: .contacts) { [weak self] granted, error in
                DispatchQueue.main.async {
                    if granted {
                        self?.contactsPermissionButton.backgroundColor = .systemGreen
                        self?.contactsPermissionButton.setTitle("Contacts Enabled ✓", for: .normal)
                        self?.checkPermissionsStatus()
                    } else if let error = error {
                        self?.showAlert(title: "Error", message: error.localizedDescription)
                    }
                }
            }
        case .restricted, .denied:
            showAlert(title: "Contacts Access Required",
                     message: "Please enable contacts access in Settings to continue",
                     showSettings: true)
        case .authorized:
            contactsPermissionButton.backgroundColor = .systemGreen
            contactsPermissionButton.setTitle("Contacts Enabled ✓", for: .normal)
            checkPermissionsStatus()
        @unknown default:
            break
        }
    }
    
    private func showAlert(title: String, message: String, showSettings: Bool = false) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if showSettings {
            alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            })
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - CLLocationManagerDelegate
extension OnboardingViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationPermissionButton.backgroundColor = .systemGreen
            locationPermissionButton.setTitle("Location Enabled ✓", for: .normal)
            checkPermissionsStatus()
        case .denied, .restricted:
            locationPermissionButton.backgroundColor = .systemRed
            locationPermissionButton.setTitle("Location Disabled", for: .normal)
        default:
            break
        }
    }
} 