package com.example.lengleng.models

import java.util.*

data class Poll(
    val id: String,
    val title: String,
    val description: String,
    val options: List<Option>,
    val createdAt: Date = Date(),
    val creatorId: String,
    val isPremium: Boolean = false,
    val analytics: Analytics? = null
) {
    data class Option(
        val text: String,
        val votes: Int = 0
    )
    
    data class Analytics(
        val totalVotes: Int = 0,
        val uniqueVoters: Int = 0,
        val averageTimeToVote: Long = 0,
        val voteDistribution: Map<String, Int> = emptyMap(),
        val voterDemographics: Map<String, Int> = emptyMap()
    )
}

data class PollOption(
    val id: String = "",
    val text: String = "",
    val votes: Int = 0
)

data class Vote(
    val userId: String = "",
    val optionId: String = "",
    val timestamp: Long = System.currentTimeMillis()
)

data class Comment(
    val id: String = "",
    val userId: String = "",
    val text: String = "",
    val timestamp: Long = System.currentTimeMillis(),
    val likes: Int = 0
) 