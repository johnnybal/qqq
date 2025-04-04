package com.example.lengleng.services

import com.example.lengleng.models.Activity
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import java.util.*

class ActivityService {
    private val db = FirebaseFirestore.getInstance()
    private val auth = FirebaseAuth.getInstance()
    
    fun getRecentActivities(onComplete: (List<Activity>) -> Unit) {
        val userId = auth.currentUser?.uid ?: return onComplete(emptyList())
        
        db.collection("activities")
            .whereEqualTo("userId", userId)
            .orderBy("timestamp", com.google.firebase.firestore.Query.Direction.DESCENDING)
            .limit(20)
            .get()
            .addOnSuccessListener { documents ->
                val activities = documents.mapNotNull { it.toObject(Activity::class.java) }
                onComplete(activities)
            }
            .addOnFailureListener { onComplete(emptyList()) }
    }
    
    fun logActivity(activity: Activity, onComplete: (Boolean) -> Unit) {
        db.collection("activities").document(activity.id).set(activity)
            .addOnSuccessListener { onComplete(true) }
            .addOnFailureListener { onComplete(false) }
    }
    
    fun logPollCreated(pollId: String, isPremium: Boolean = false, onComplete: (Boolean) -> Unit) {
        val userId = auth.currentUser?.uid ?: return onComplete(false)
        
        val activity = Activity(
            id = UUID.randomUUID().toString(),
            type = Activity.Type.POLL_CREATED,
            userId = userId,
            pollId = pollId,
            isPremium = isPremium
        )
        
        logActivity(activity, onComplete)
    }
    
    fun logPollVoted(pollId: String, isPremium: Boolean = false, onComplete: (Boolean) -> Unit) {
        val userId = auth.currentUser?.uid ?: return onComplete(false)
        
        val activity = Activity(
            id = UUID.randomUUID().toString(),
            type = Activity.Type.POLL_VOTED,
            userId = userId,
            pollId = pollId,
            isPremium = isPremium
        )
        
        logActivity(activity, onComplete)
    }
    
    fun logFriendAdded(friendId: String, isPremium: Boolean = false, onComplete: (Boolean) -> Unit) {
        val userId = auth.currentUser?.uid ?: return onComplete(false)
        
        val activity = Activity(
            id = UUID.randomUUID().toString(),
            type = Activity.Type.FRIEND_ADDED,
            userId = userId,
            friendId = friendId,
            isPremium = isPremium
        )
        
        logActivity(activity, onComplete)
    }
    
    fun logFriendRequestSent(friendId: String, isPremium: Boolean = false, onComplete: (Boolean) -> Unit) {
        val userId = auth.currentUser?.uid ?: return onComplete(false)
        
        val activity = Activity(
            id = UUID.randomUUID().toString(),
            type = Activity.Type.FRIEND_REQUEST_SENT,
            userId = userId,
            friendId = friendId,
            isPremium = isPremium
        )
        
        logActivity(activity, onComplete)
    }
    
    fun logFriendRequestAccepted(friendId: String, isPremium: Boolean = false, onComplete: (Boolean) -> Unit) {
        val userId = auth.currentUser?.uid ?: return onComplete(false)
        
        val activity = Activity(
            id = UUID.randomUUID().toString(),
            type = Activity.Type.FRIEND_REQUEST_ACCEPTED,
            userId = userId,
            friendId = friendId,
            isPremium = isPremium
        )
        
        logActivity(activity, onComplete)
    }
    
    fun logSubscriptionUpgraded(onComplete: (Boolean) -> Unit) {
        val userId = auth.currentUser?.uid ?: return onComplete(false)
        
        val activity = Activity(
            id = UUID.randomUUID().toString(),
            type = Activity.Type.SUBSCRIPTION_UPGRADED,
            userId = userId,
            isPremium = true
        )
        
        logActivity(activity, onComplete)
    }
    
    fun logFreeTrialStarted(onComplete: (Boolean) -> Unit) {
        val userId = auth.currentUser?.uid ?: return onComplete(false)
        
        val activity = Activity(
            id = UUID.randomUUID().toString(),
            type = Activity.Type.FREE_TRIAL_STARTED,
            userId = userId,
            isPremium = true
        )
        
        logActivity(activity, onComplete)
    }
} 