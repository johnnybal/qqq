package com.lengleng.models

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentId
import java.util.Date

data class Poll(
    @DocumentId
    val id: String = "",
    val question: String = "",
    val options: List<PollOption> = emptyList(),
    val creatorId: String = "",
    val createdAt: Date = Date(),
    val expiresAt: Date = Date(),
    val isAnonymous: Boolean = false,
    val category: PollCategory = PollCategory.GENERAL,
    val totalVotes: Int = 0,
    val boostCount: Int = 0,
    val matchType: String? = null,
    val matchedUsers: List<String>? = null
) {
    enum class PollCategory {
        GENERAL,
        SCHOOL,
        SPORTS,
        ENTERTAINMENT,
        DATING,
        OTHER
    }
}

data class PollOption(
    val id: String = "",
    val text: String = "",
    var voteCount: Int = 0
)

data class PollVote(
    val pollId: String = "",
    val userId: String = "",
    val optionId: String = "",
    val timestamp: Date = Date()
) 