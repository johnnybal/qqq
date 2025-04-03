import Foundation
import MessageUI
import UIKit

class MessagingService: NSObject, MFMessageComposeViewControllerDelegate {
    private var completionHandler: ((Bool) -> Void)?
    private var messageVC: MFMessageComposeViewController?
    
    func sendInvitation(to contact: ContactToInvite, message: String, inviteLink: String) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                if MFMessageComposeViewController.canSendText() {
                    let messageVC = MFMessageComposeViewController()
                    messageVC.messageComposeDelegate = self
                    messageVC.recipients = [contact.phoneNumber]
                    messageVC.body = "\(message)\n\n\(inviteLink)"
                    
                    self.messageVC = messageVC
                    self.completionHandler = { success in
                        self.cleanup()
                        continuation.resume(returning: success)
                    }
                    
                    // Present the message composer
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        rootViewController.present(messageVC, animated: true)
                    } else {
                        self.cleanup()
                        continuation.resume(throwing: NSError(domain: "MessagingService", code: -1, userInfo: [
                            NSLocalizedDescriptionKey: "Could not present message composer"
                        ]))
                    }
                } else {
                    continuation.resume(throwing: NSError(domain: "MessagingService", code: -2, userInfo: [
                        NSLocalizedDescriptionKey: "Device cannot send text messages"
                    ]))
                }
            }
        }
    }
    
    // MARK: - MFMessageComposeViewControllerDelegate
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true) {
            switch result {
            case .sent:
                self.completionHandler?(true)
            case .failed, .cancelled:
                self.completionHandler?(false)
            @unknown default:
                self.completionHandler?(false)
            }
        }
    }
    
    func shareInvitation(to contact: ContactToInvite, message: String, inviteLink: URL) {
        let activityItems: [Any] = [message, inviteLink]
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    // MARK: - Cleanup
    
    private func cleanup() {
        messageVC = nil
        completionHandler = nil
    }
    
    deinit {
        cleanup()
    }
} 