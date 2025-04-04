package com.example.lengleng.models

import java.util.*

data class User(
    val id: String,
    val email: String,
    val name: String,
    val photoUrl: String? = null,
    val createdAt: Date = Date(),
    val subscriptionTier: SubscriptionTier = SubscriptionTier.FREE,
    val subscriptionExpiryDate: Date? = null,
    val hasUsedFreeTrial: Boolean = false,
    val freeTrialStartedAt: Date? = null,
    val isFreeTrial: Boolean = false,
    val pollsVotedForTrial: Int = 0,
    val lastTransactionId: String? = null
)

data class UserSettings(
    val notificationsEnabled: Boolean = true,
    val darkMode: Boolean = false,
    val language: String = "en",
    val privacy: PrivacySettings = PrivacySettings()
)

data class PrivacySettings(
    val profileVisibility: String = "public",
    val showOnlineStatus: Boolean = true,
    val allowFriendRequests: Boolean = true
) 