package com.example.lengleng.services

import com.example.lengleng.models.Poll
import com.google.firebase.firestore.FirebaseFirestore
import java.util.*

class PollService {
    private val db = FirebaseFirestore.getInstance()
    
    fun createPoll(title: String, description: String, options: List<String>, onComplete: (Boolean) -> Unit) {
        val poll = Poll(
            id = UUID.randomUUID().toString(),
            title = title,
            description = description,
            options = options.map { Poll.Option(it, 0) },
            createdAt = Date()
        )
        
        db.collection("polls").document(poll.id).set(poll)
            .addOnSuccessListener { onComplete(true) }
            .addOnFailureListener { onComplete(false) }
    }
    
    fun getPoll(pollId: String, onComplete: (Poll?) -> Unit) {
        db.collection("polls").document(pollId).get()
            .addOnSuccessListener { document ->
                if (document.exists()) {
                    val poll = document.toObject(Poll::class.java)
                    onComplete(poll)
                } else {
                    onComplete(null)
                }
            }
            .addOnFailureListener { onComplete(null) }
    }
    
    fun getPolls(onComplete: (List<Poll>) -> Unit) {
        db.collection("polls")
            .orderBy("createdAt", com.google.firebase.firestore.Query.Direction.DESCENDING)
            .get()
            .addOnSuccessListener { documents ->
                val polls = documents.mapNotNull { it.toObject(Poll::class.java) }
                onComplete(polls)
            }
            .addOnFailureListener { onComplete(emptyList()) }
    }
    
    fun vote(pollId: String, optionIndex: Int, onComplete: (Boolean) -> Unit) {
        db.collection("polls").document(pollId).get()
            .addOnSuccessListener { document ->
                if (document.exists()) {
                    val poll = document.toObject(Poll::class.java)
                    if (poll != null && optionIndex in poll.options.indices) {
                        val updatedOptions = poll.options.toMutableList()
                        updatedOptions[optionIndex] = updatedOptions[optionIndex].copy(
                            votes = updatedOptions[optionIndex].votes + 1
                        )
                        
                        db.collection("polls").document(pollId).update(
                            "options", updatedOptions
                        )
                            .addOnSuccessListener { onComplete(true) }
                            .addOnFailureListener { onComplete(false) }
                    } else {
                        onComplete(false)
                    }
                } else {
                    onComplete(false)
                }
            }
            .addOnFailureListener { onComplete(false) }
    }
} 