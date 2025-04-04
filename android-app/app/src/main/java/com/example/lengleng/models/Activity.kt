package com.example.lengleng.models

import java.util.*

data class Activity(
    val id: String,
    val type: Type,
    val userId: String,
    val pollId: String? = null,
    val friendId: String? = null,
    val timestamp: Date = Date(),
    val isPremium: Boolean = false
) {
    enum class Type {
        POLL_CREATED,
        POLL_VOTED,
        FRIEND_ADDED,
        FRIEND_REQUEST_SENT,
        FRIEND_REQUEST_ACCEPTED,
        SUBSCRIPTION_UPGRADED,
        FREE_TRIAL_STARTED
    }
} 