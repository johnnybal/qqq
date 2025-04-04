package com.example.lengleng.services

import com.example.lengleng.models.User
import com.example.lengleng.models.SubscriptionTier
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton
import java.util.*

@Singleton
class UserService @Inject constructor(
    private val auth: FirebaseAuth,
    private val firestore: FirebaseFirestore
) {
    suspend fun getUser(userId: String): Result<User> = try {
        val document = firestore.collection("users").document(userId).get().await()
        if (document.exists()) {
            Result.success(document.toObject(User::class.java)!!)
        } else {
            Result.failure(Exception("User not found"))
        }
    } catch (e: Exception) {
        Result.failure(e)
    }

    suspend fun updateUser(user: User): Result<Unit> = try {
        firestore.collection("users").document(user.id).set(user).await()
        Result.success(Unit)
    } catch (e: Exception) {
        Result.failure(e)
    }

    suspend fun signIn(email: String, password: String): Result<Unit> = try {
        auth.signInWithEmailAndPassword(email, password).await()
        Result.success(Unit)
    } catch (e: Exception) {
        Result.failure(e)
    }

    suspend fun signUp(email: String, password: String, username: String): Result<Unit> = try {
        val authResult = auth.createUserWithEmailAndPassword(email, password).await()
        val user = User(
            id = authResult.user?.uid ?: throw Exception("User creation failed"),
            email = email,
            username = username
        )
        firestore.collection("users").document(user.id).set(user).await()
        Result.success(Unit)
    } catch (e: Exception) {
        Result.failure(e)
    }

    fun signOut() {
        auth.signOut()
    }

    suspend fun updateUserStatus(userId: String, isOnline: Boolean): Result<Unit> {
        return try {
            firestore.collection("users").document(userId)
                .update(mapOf(
                    "isOnline" to isOnline,
                    "lastActive" to System.currentTimeMillis()
                ))
                .await()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    fun createUser(user: User, onComplete: (Boolean) -> Unit) {
        firestore.collection("users").document(user.id).set(user)
            .addOnSuccessListener { onComplete(true) }
            .addOnFailureListener { onComplete(false) }
    }

    fun updateSubscriptionTier(
        userId: String,
        tier: SubscriptionTier,
        expiryDate: Date? = null,
        isFreeTrial: Boolean = false,
        onComplete: (Boolean) -> Unit
    ) {
        val updates = hashMapOf<String, Any>(
            "subscriptionTier" to tier.name,
            "subscriptionExpiryDate" to (expiryDate ?: Date()),
            "isFreeTrial" to isFreeTrial
        )
        
        if (isFreeTrial) {
            updates["hasUsedFreeTrial"] = true
            updates["freeTrialStartedAt"] = Date()
        }
        
        firestore.collection("users").document(userId).update(updates)
            .addOnSuccessListener { onComplete(true) }
            .addOnFailureListener { onComplete(false) }
    }

    fun incrementPollsVotedForTrial(userId: String, onComplete: (Boolean) -> Unit) {
        firestore.collection("users").document(userId).update(
            "pollsVotedForTrial", com.google.firebase.firestore.FieldValue.increment(1)
        )
            .addOnSuccessListener { onComplete(true) }
            .addOnFailureListener { onComplete(false) }
    }

    fun updateLastTransactionId(userId: String, transactionId: String, onComplete: (Boolean) -> Unit) {
        firestore.collection("users").document(userId).update(
            "lastTransactionId", transactionId
        )
            .addOnSuccessListener { onComplete(true) }
            .addOnFailureListener { onComplete(false) }
    }
} 