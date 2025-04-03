import Foundation

struct ContactToInvite: Identifiable, Hashable {
    let id: String
    let name: String
    let phoneNumber: String
    let school: String?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ContactToInvite, rhs: ContactToInvite) -> Bool {
        lhs.id == rhs.id
    }
} 