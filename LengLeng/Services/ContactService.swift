import Foundation
import Contacts
import ContactsUI

class ContactService: ObservableObject {
    @Published var contacts: [ContactToInvite] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let contactStore = CNContactStore()
    
    func requestAccess() async throws {
        let status = try await contactStore.requestAccess(for: .contacts)
        guard status else {
            throw NSError(domain: "ContactService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Contact access denied"])
        }
    }
    
    func loadContacts() async throws {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }
        
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactPhoneNumbersKey,
            CNContactEmailAddressesKey,
            CNContactImageDataKey,
            CNContactThumbnailImageDataKey,
            CNContactOrganizationNameKey,
            CNContactNoteKey
        ] as [CNKeyDescriptor]
        
        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        
        var loadedContacts: [ContactToInvite] = []
        
        try contactStore.enumerateContacts(with: request) { contact, _ in
            let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { return }
            
            let phoneNumbers = contact.phoneNumbers.map { $0.value.stringValue }
            guard !phoneNumbers.isEmpty else { return }
            
            let contactToInvite = ContactToInvite(
                id: UUID().uuidString,
                name: name,
                phoneNumber: phoneNumbers[0],
                school: contact.organizationName,
                image: contact.thumbnailImageData.flatMap { UIImage(data: $0) }
            )
            
            loadedContacts.append(contactToInvite)
        }
        
        await MainActor.run {
            self.contacts = loadedContacts.sorted { $0.name < $1.name }
        }
    }
    
    func filterContacts(by filter: ContactFilter, schoolName: String? = nil) -> [ContactToInvite] {
        switch filter {
        case .topMatches:
            return contacts.prefix(10).map { $0 }
        case .school:
            guard let school = schoolName else { return contacts }
            return contacts.filter { $0.school == school }
        case .recent:
            // In a real app, you would track recently contacted users
            // For now, we'll return the first 20 contacts
            return contacts.prefix(20).map { $0 }
        }
    }
    
    func searchContacts(query: String) -> [ContactToInvite] {
        guard !query.isEmpty else { return contacts }
        return contacts.filter { contact in
            contact.name.localizedCaseInsensitiveContains(query) ||
            contact.school?.localizedCaseInsensitiveContains(query) ?? false
        }
    }
} 