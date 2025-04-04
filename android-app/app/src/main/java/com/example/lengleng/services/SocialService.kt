package com.example.lengleng.services

import com.example.lengleng.models.User
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import java.util.*

class SocialService {
    private val db = FirebaseFirestore.getInstance()
    private val auth = FirebaseAuth.getInstance()
    
    fun getFriends(onComplete: (List<User>) -> Unit) {
        val userId = auth.currentUser?.uid ?: return onComplete(emptyList())
        
        db.collection("users").document(userId).collection("friends")
            .get()
            .addOnSuccessListener { documents ->
                val friends = documents.mapNotNull { it.toObject(User::class.java) }
                onComplete(friends)
            }
            .addOnFailureListener { onComplete(emptyList()) }
    }
    
    fun getPendingRequests(onComplete: (List<User>) -> Unit) {
        val userId = auth.currentUser?.uid ?: return onComplete(emptyList())
        
        db.collection("users").document(userId).collection("pending_requests")
            .get()
            .addOnSuccessListener { documents ->
                val requests = documents.mapNotNull { it.toObject(User::class.java) }
                onComplete(requests)
            }
            .addOnFailureListener { onComplete(emptyList()) }
    }
    
    fun sendInvite(friendId: String, onComplete: (Boolean) -> Unit) {
        val userId = auth.currentUser?.uid ?: return onComplete(false)
        
        // Check if already friends
        db.collection("users").document(userId).collection("friends")
            .document(friendId)
            .get()
            .addOnSuccessListener { document ->
                if (document.exists()) {
                    onComplete(false) // Already friends
                } else {
                    // Check if already sent request
                    db.collection("users").document(friendId).collection("pending_requests")
                        .document(userId)
                        .get()
                        .addOnSuccessListener { requestDoc ->
                            if (requestDoc.exists()) {
                                onComplete(false) // Request already sent
                            } else {
                                // Send request
                                db.collection("users").document(friendId).collection("pending_requests")
                                    .document(userId)
                                    .set(mapOf(
                                        "id" to userId,
                                        "timestamp" to Date()
                                    ))
                                    .addOnSuccessListener { onComplete(true) }
                                    .addOnFailureListener { onComplete(false) }
                            }
                        }
                        .addOnFailureListener { onComplete(false) }
                }
            }
            .addOnFailureListener { onComplete(false) }
    }
    
    fun acceptRequest(friendId: String, onComplete: (Boolean) -> Unit) {
        val userId = auth.currentUser?.uid ?: return onComplete(false)
        
        // Add to friends collection for both users
        val batch = db.batch()
        
        // Add friend to user's friends
        batch.set(
            db.collection("users").document(userId).collection("friends").document(friendId),
            mapOf("id" to friendId, "timestamp" to Date())
        )
        
        // Add user to friend's friends
        batch.set(
            db.collection("users").document(friendId).collection("friends").document(userId),
            mapOf("id" to userId, "timestamp" to Date())
        )
        
        // Remove from pending requests
        batch.delete(
            db.collection("users").document(userId).collection("pending_requests").document(friendId)
        )
        
        batch.commit()
            .addOnSuccessListener { onComplete(true) }
            .addOnFailureListener { onComplete(false) }
    }
    
    fun rejectRequest(friendId: String, onComplete: (Boolean) -> Unit) {
        val userId = auth.currentUser?.uid ?: return onComplete(false)
        
        db.collection("users").document(userId).collection("pending_requests")
            .document(friendId)
            .delete()
            .addOnSuccessListener { onComplete(true) }
            .addOnFailureListener { onComplete(false) }
    }
    
    fun removeFriend(friendId: String, onComplete: (Boolean) -> Unit) {
        val userId = auth.currentUser?.uid ?: return onComplete(false)
        
        val batch = db.batch()
        
        // Remove friend from user's friends
        batch.delete(
            db.collection("users").document(userId).collection("friends").document(friendId)
        )
        
        // Remove user from friend's friends
        batch.delete(
            db.collection("users").document(friendId).collection("friends").document(userId)
        )
        
        batch.commit()
            .addOnSuccessListener { onComplete(true) }
            .addOnFailureListener { onComplete(false) }
    }
} 