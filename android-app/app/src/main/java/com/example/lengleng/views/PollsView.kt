package com.example.lengleng.views

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.example.lengleng.models.Poll
import com.example.lengleng.services.PollService
import com.example.lengleng.services.SubscriptionService
import com.example.lengleng.models.PremiumFeature
import java.text.SimpleDateFormat
import java.util.*

@Composable
fun PollsView(
    navController: NavController,
    subscriptionService: SubscriptionService
) {
    var polls by remember { mutableStateOf<List<Poll>>(emptyList()) }
    var isLoading by remember { mutableStateOf(false) }
    var showCreatePoll by remember { mutableStateOf(false) }
    var showPremiumLock by remember { mutableStateOf(false) }
    val pollService = PollService()

    LaunchedEffect(Unit) {
        isLoading = true
        polls = pollService.getRecentPolls()
        isLoading = false
    }

    fun handleVote(poll: Poll, option: String) {
        // Increment polls voted for trial
        subscriptionService.incrementPollsVotedForTrial()
        
        // ... existing vote handling code ...
    }

    Scaffold(
        floatingActionButton = {
            FloatingActionButton(
                onClick = { showCreatePoll = true },
                containerColor = MaterialTheme.colorScheme.primary,
                contentColor = MaterialTheme.colorScheme.onPrimary
            ) {
                Icon(Icons.Default.Add, contentDescription = "Create Poll")
            }
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 16.dp)
        ) {
            Text(
                text = "Polls",
                style = MaterialTheme.typography.headlineMedium.copy(
                    fontWeight = FontWeight.Bold,
                    fontSize = 24.sp
                ),
                modifier = Modifier.padding(vertical = 16.dp)
            )

            if (isLoading) {
                CircularProgressIndicator(
                    modifier = Modifier
                        .size(48.dp)
                        .align(Alignment.CenterHorizontally)
                        .padding(vertical = 24.dp),
                    strokeWidth = 2.dp
                )
            } else if (polls.isEmpty()) {
                Text(
                    text = "No polls available",
                    style = MaterialTheme.typography.bodyLarge.copy(
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    ),
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 24.dp),
                    textAlign = TextAlign.Center
                )
            } else {
                LazyColumn(
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(polls) { poll ->
                        PollRow(poll = poll)
                    }
                }
            }
        }
    }

    if (showCreatePoll) {
        CreatePollDialog(
            onDismiss = { showCreatePoll = false },
            onCreate = { title, description, options ->
                if (subscriptionService.isPremiumFeatureAvailable(PremiumFeature.UNLIMITED_INVITES)) {
                    // Allow unlimited options for premium users
                    pollService.createPoll(title, description, options)
                } else if (options.size <= 5) {
                    // Free users limited to 5 options
                    pollService.createPoll(title, description, options)
                } else {
                    // Show premium feature lock
                    showPremiumLock = true
                }
                showCreatePoll = false
            }
        )
    }

    if (showPremiumLock) {
        PremiumFeatureLockView(
            feature = PremiumFeature.UNLIMITED_INVITES,
            subscriptionService = subscriptionService,
            onUpgradeClick = {
                showPremiumLock = false
                navController.navigate("subscription")
            }
        )
    }
}

@Composable
fun PollRow(poll: Poll) {
    var showVoteDialog by remember { mutableStateOf(false) }
    val pollService = PollService()
    val dateFormat = SimpleDateFormat("MMM d, h:mm a", Locale.getDefault())

    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = poll.title,
                style = MaterialTheme.typography.titleMedium.copy(
                    fontWeight = FontWeight.Medium
                )
            )
            
            Text(
                text = poll.description,
                style = MaterialTheme.typography.bodyMedium.copy(
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                ),
                modifier = Modifier.padding(vertical = 8.dp)
            )

            poll.options.forEach { option ->
                OutlinedButton(
                    onClick = { showVoteDialog = true },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 4.dp),
                    colors = ButtonDefaults.outlinedButtonColors(
                        contentColor = MaterialTheme.colorScheme.primary
                    )
                ) {
                    Text("${option.text} (${option.votes} votes)")
                }
            }

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 8.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "${poll.comments.size} comments",
                    style = MaterialTheme.typography.bodySmall.copy(
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                )
                Text(
                    text = dateFormat.format(poll.createdAt),
                    style = MaterialTheme.typography.bodySmall.copy(
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                )
            }
        }
    }

    if (showVoteDialog) {
        AlertDialog(
            onDismissRequest = { showVoteDialog = false },
            title = { 
                Text(
                    "Vote on Poll",
                    style = MaterialTheme.typography.titleLarge.copy(
                        fontWeight = FontWeight.Bold
                    )
                )
            },
            text = {
                Column {
                    poll.options.forEach { option ->
                        Button(
                            onClick = {
                                pollService.vote(poll.id, option.id)
                                showVoteDialog = false
                            },
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 4.dp),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = MaterialTheme.colorScheme.primary
                            )
                        ) {
                            Text(option.text)
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(
                    onClick = { showVoteDialog = false },
                    colors = ButtonDefaults.textButtonColors(
                        contentColor = MaterialTheme.colorScheme.primary
                    )
                ) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
fun CreatePollDialog(
    onDismiss: () -> Unit,
    onCreate: (String, String, List<String>) -> Unit
) {
    var title by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var options by remember { mutableStateOf(listOf("", "")) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { 
            Text(
                "Create Poll",
                style = MaterialTheme.typography.titleLarge.copy(
                    fontWeight = FontWeight.Bold
                )
            )
        },
        text = {
            Column {
                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it },
                    label = { Text("Title") },
                    singleLine = true,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 8.dp)
                )

                OutlinedTextField(
                    value = description,
                    onValueChange = { description = it },
                    label = { Text("Description") },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 8.dp)
                )

                Text(
                    text = "Options",
                    style = MaterialTheme.typography.titleSmall.copy(
                        fontWeight = FontWeight.Medium
                    ),
                    modifier = Modifier.padding(vertical = 8.dp)
                )

                options.forEachIndexed { index, option ->
                    OutlinedTextField(
                        value = option,
                        onValueChange = { newValue ->
                            options = options.toMutableList().apply {
                                set(index, newValue)
                            }
                        },
                        label = { Text("Option ${index + 1}") },
                        singleLine = true,
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 4.dp)
                    )
                }

                TextButton(
                    onClick = {
                        options = options + ""
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 8.dp),
                    colors = ButtonDefaults.textButtonColors(
                        contentColor = MaterialTheme.colorScheme.primary
                    )
                ) {
                    Text("Add Option")
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    onCreate(title, description, options.filter { it.isNotBlank() })
                },
                enabled = title.isNotBlank() && description.isNotBlank() &&
                        options.any { it.isNotBlank() },
                colors = ButtonDefaults.textButtonColors(
                    contentColor = MaterialTheme.colorScheme.primary
                )
            ) {
                Text("Create")
            }
        },
        dismissButton = {
            TextButton(
                onClick = onDismiss,
                colors = ButtonDefaults.textButtonColors(
                    contentColor = MaterialTheme.colorScheme.primary
                )
            ) {
                Text("Cancel")
            }
        }
    )
} 