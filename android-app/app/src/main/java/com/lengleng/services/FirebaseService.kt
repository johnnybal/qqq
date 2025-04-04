package com.lengleng.services

import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.lengleng.models.Poll
import com.lengleng.models.PollVote
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class FirebaseService @Inject constructor(
    private val auth: FirebaseAuth,
    private val firestore: FirebaseFirestore
) {
    suspend fun fetchPolls(): List<Poll> {
        return try {
            val snapshot = firestore.collection("polls")
                .orderBy("createdAt", com.google.firebase.firestore.Query.Direction.DESCENDING)
                .get()
                .await()
            
            snapshot.documents.mapNotNull { document ->
                document.toObject(Poll::class.java)
            }
        } catch (e: Exception) {
            emptyList()
        }
    }
    
    suspend fun voteOnPoll(pollId: String, optionId: String): Result<Unit> {
        return try {
            val userId = auth.currentUser?.uid ?: return Result.failure(Exception("User not authenticated"))
            
            // Check if user has already voted
            val existingVote = firestore.collection("votes")
                .whereEqualTo("pollId", pollId)
                .whereEqualTo("userId", userId)
                .get()
                .await()
            
            if (!existingVote.isEmpty) {
                return Result.failure(Exception("User has already voted on this poll"))
            }
            
            // Create vote
            val vote = PollVote(
                pollId = pollId,
                userId = userId,
                optionId = optionId
            )
            
            // Save vote
            firestore.collection("votes")
                .document("${pollId}_${userId}")
                .set(vote)
                .await()
            
            // Update poll option vote count
            firestore.collection("polls")
                .document(pollId)
                .update(
                    mapOf(
                        "options.$optionId.voteCount" to com.google.firebase.firestore.FieldValue.increment(1),
                        "totalVotes" to com.google.firebase.firestore.FieldValue.increment(1)
                    )
                )
                .await()
            
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun checkForMatches(pollId: String, optionId: String): Boolean {
        return try {
            val currentUserId = auth.currentUser?.uid ?: return false
            
            // Get all votes for this poll option
            val votes = firestore.collection("votes")
                .whereEqualTo("pollId", pollId)
                .whereEqualTo("optionId", optionId)
                .get()
                .await()
            
            // Check if any other user voted for the same option
            val hasMatch = votes.documents.any { doc ->
                val vote = doc.toObject(PollVote::class.java)
                vote?.userId != currentUserId
            }
            
            if (hasMatch) {
                // Update poll with match information
                firestore.collection("polls")
                    .document(pollId)
                    .update(
                        mapOf(
                            "matchType" to "mutual",
                            "matchedUsers" to com.google.firebase.firestore.FieldValue.arrayUnion(currentUserId)
                        )
                    )
                    .await()
            }
            
            hasMatch
        } catch (e: Exception) {
            false
        }
    }
    
    suspend fun boostPoll(pollId: String): Result<Unit> {
        return try {
            val userId = auth.currentUser?.uid ?: return Result.failure(Exception("User not authenticated"))
            
            // Get current boost count
            val pollDoc = firestore.collection("polls")
                .document(pollId)
                .get()
                .await()
            
            val poll = pollDoc.toObject(Poll::class.java)
            if (poll?.boostCount ?: 0 >= 3) {
                return Result.failure(Exception("Maximum boost count reached"))
            }
            
            // Update boost count
            firestore.collection("polls")
                .document(pollId)
                .update(
                    mapOf(
                        "boostCount" to com.google.firebase.firestore.FieldValue.increment(1)
                    )
                )
                .await()
            
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
} 