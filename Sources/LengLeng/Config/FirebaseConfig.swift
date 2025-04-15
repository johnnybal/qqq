import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage
import FirebaseMessaging
import FirebaseFunctions
import FirebaseRemoteConfig
import FirebaseCrashlytics

class FirebaseConfig: ObservableObject {
    static let shared = FirebaseConfig()
    
    let auth: Auth
    let db: Firestore
    let storage: Storage
    let functions: Functions
    let remoteConfig: RemoteConfig
    let messaging: Messaging
    
    private init() {
        // Initialize Firebase services
        auth = Auth.auth()
        db = Firestore.firestore()
        storage = Storage.storage()
        functions = Functions.functions()
        remoteConfig = RemoteConfig.remoteConfig()
        messaging = Messaging.messaging()
        
        // Configure Firestore settings
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        db.settings = settings
        
        // Configure Remote Config
        let remoteConfigSettings = RemoteConfigSettings()
        remoteConfigSettings.minimumFetchInterval = 0
        remoteConfig.configSettings = remoteConfigSettings
        
        // Set default Remote Config values
        let defaultValues: [String: NSObject] = [
            "welcome_message": "Welcome to LengLeng!" as NSObject,
            "max_friends": 100 as NSObject,
            "poll_creation_cooldown": 300 as NSObject, // 5 minutes in seconds
            "max_polls_per_day": 10 as NSObject,
            "flames_per_vote": 1 as NSObject,
            "gems_per_poll": 5 as NSObject
        ]
        remoteConfig.setDefaults(defaultValues)
        
        // Configure Crashlytics
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
    }
    
    func configureMessaging(delegate: MessagingDelegate) {
        messaging.delegate = delegate
        messaging.isAutoInitEnabled = true
        
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func fetchRemoteConfig(completion: @escaping (Error?) -> Void) {
        remoteConfig.fetch { [weak self] status, error in
            if let error = error {
                completion(error)
                return
            }
            
            self?.remoteConfig.activate { _, error in
                completion(error)
            }
        }
    }
    
    func getRemoteConfigValue<T>(forKey key: String) -> T? {
        return remoteConfig.configValue(forKey: key).dataValue as? T
    }
} 