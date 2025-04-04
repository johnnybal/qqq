package com.lengleng.ui.components

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.lengleng.models.Poll
import com.lengleng.models.PollOption
import java.text.SimpleDateFormat
import java.util.*

@Composable
fun PollItem(
    poll: Poll,
    onVote: (String) -> Unit,
    onBoost: () -> Unit
) {
    var selectedOption by remember { mutableStateOf<String?>(null) }
    
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            // Question and Boost
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = poll.question,
                    style = MaterialTheme.typography.titleMedium,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f)
                )
                IconButton(
                    onClick = onBoost,
                    enabled = poll.boostCount < 3
                ) {
                    Icon(
                        imageVector = Icons.Default.Bolt,
                        contentDescription = "Boost poll",
                        tint = if (poll.boostCount > 0) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface
                    )
                }
            }
            
            // Category and Anonymous Indicator
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = poll.category.name,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.primary
                )
                if (poll.isAnonymous) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.VisibilityOff,
                            contentDescription = "Anonymous poll",
                            modifier = Modifier.size(16.dp)
                        )
                        Text(
                            text = "Anonymous",
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                }
            }
            
            // Match Status
            poll.matchType?.let { matchType ->
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Favorite,
                        contentDescription = "Match",
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(16.dp)
                    )
                    Text(
                        text = "Matched: $matchType",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            }
            
            // Options
            poll.options.forEach { option ->
                PollOptionItem(
                    option = option,
                    totalVotes = poll.totalVotes,
                    isSelected = selectedOption == option.id,
                    onSelect = {
                        selectedOption = option.id
                        onVote(option.id)
                    }
                )
            }
            
            // Poll stats
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "${poll.totalVotes} votes",
                    style = MaterialTheme.typography.bodySmall
                )
                Text(
                    text = formatDate(poll.expiresAt),
                    style = MaterialTheme.typography.bodySmall
                )
            }
        }
    }
}

@Composable
fun PollOptionItem(
    option: PollOption,
    totalVotes: Int,
    isSelected: Boolean,
    onSelect: () -> Unit
) {
    val percentage = if (totalVotes > 0) {
        (option.voteCount.toFloat() / totalVotes) * 100
    } else 0f
    
    OutlinedButton(
        onClick = onSelect,
        modifier = Modifier.fillMaxWidth(),
        colors = ButtonDefaults.outlinedButtonColors(
            contentColor = if (isSelected) {
                MaterialTheme.colorScheme.primary
            } else {
                MaterialTheme.colorScheme.onSurface
            }
        )
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = option.text,
                modifier = Modifier.weight(1f)
            )
            Text(
                text = "${percentage.toInt()}%",
                style = MaterialTheme.typography.bodySmall
            )
        }
    }
}

private fun formatDate(timestamp: Date): String {
    val formatter = SimpleDateFormat("MMM d, yyyy", Locale.getDefault())
    return formatter.format(timestamp)
} 