package com.example.lengleng.views

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.example.lengleng.models.Activity
import com.example.lengleng.services.UserService
import com.example.lengleng.services.SubscriptionService
import java.text.SimpleDateFormat
import java.util.*

@Composable
fun HomeView(
    navController: NavController,
    subscriptionService: SubscriptionService
) {
    var selectedTab by remember { mutableStateOf(0) }
    val tabs = listOf("Home", "Polls", "Social", "Profile")
    val currentTier by subscriptionService.currentTier.collectAsState()
    val freeTrialEligible by subscriptionService.freeTrialEligible.collectAsState()
    val pollsVotedForTrial by subscriptionService.pollsVotedForTrial.collectAsState()
    
    Scaffold(
        bottomBar = {
            NavigationBar(
                containerColor = MaterialTheme.colorScheme.surface,
                tonalElevation = 0.dp
            ) {
                tabs.forEachIndexed { index, title ->
                    NavigationBarItem(
                        icon = {
                            Icon(
                                imageVector = when (index) {
                                    0 -> Icons.Default.Home
                                    1 -> Icons.Default.BarChart
                                    2 -> Icons.Default.People
                                    else -> Icons.Default.Person
                                },
                                contentDescription = title
                            )
                        },
                        label = { 
                            Text(
                                title,
                                style = MaterialTheme.typography.labelSmall
                            )
                        },
                        selected = selectedTab == index,
                        onClick = { selectedTab = index },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = MaterialTheme.colorScheme.primary,
                            selectedTextColor = MaterialTheme.colorScheme.primary,
                            indicatorColor = MaterialTheme.colorScheme.surface
                        )
                    )
                }
            }
        }
    ) { padding ->
        Box(modifier = Modifier.padding(padding)) {
            when (selectedTab) {
                0 -> HomeContentView()
                1 -> PollsView(navController)
                2 -> SocialView(navController)
                3 -> ProfileView(navController)
            }
        }
    }
}

@Composable
fun HomeContentView() {
    var recentActivity by remember { mutableStateOf<List<Activity>>(emptyList()) }
    val userService = UserService()

    LaunchedEffect(Unit) {
        // TODO: Load recent activity
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp)
    ) {
        Text(
            text = "Recent Activity",
            style = MaterialTheme.typography.headlineMedium.copy(
                fontWeight = FontWeight.Bold,
                fontSize = 24.sp
            ),
            modifier = Modifier.padding(vertical = 16.dp)
        )

        if (recentActivity.isEmpty()) {
            Text(
                text = "No recent activity",
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
                items(recentActivity) { activity ->
                    ActivityRow(activity = activity)
                }
            }
        }

        if (currentTier == SubscriptionTier.FREE) {
            Spacer(modifier = Modifier.height(24.dp))
            
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer
                )
            ) {
                Column(
                    modifier = Modifier
                        .padding(16.dp)
                        .fillMaxWidth(),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = "Upgrade to Power Mode",
                        style = MaterialTheme.typography.titleLarge,
                        textAlign = TextAlign.Center
                    )
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    if (freeTrialEligible) {
                        Text(
                            text = "You've earned a free trial! ($pollsVotedForTrial/3 polls voted)",
                            style = MaterialTheme.typography.bodyMedium,
                            textAlign = TextAlign.Center
                        )
                    } else {
                        Text(
                            text = "Vote on ${3 - pollsVotedForTrial} more polls to earn a free trial",
                            style = MaterialTheme.typography.bodyMedium,
                            textAlign = TextAlign.Center
                        )
                    }
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    Button(
                        onClick = { navController.navigate("subscription") },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Upgrade Now")
                    }
                }
            }
        }
    }
}

@Composable
fun ActivityRow(activity: Activity) {
    val dateFormat = SimpleDateFormat("MMM d, h:mm a", Locale.getDefault())
    
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = when (activity.type) {
                    "poll" -> Icons.Default.BarChart
                    "friend" -> Icons.Default.People
                    else -> Icons.Default.Notifications
                },
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(24.dp)
            )

            Spacer(modifier = Modifier.width(16.dp))

            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = activity.title,
                    style = MaterialTheme.typography.titleMedium.copy(
                        fontWeight = FontWeight.Medium
                    )
                )
                Text(
                    text = activity.description,
                    style = MaterialTheme.typography.bodyMedium.copy(
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                )
            }

            Text(
                text = dateFormat.format(activity.timestamp),
                style = MaterialTheme.typography.bodySmall.copy(
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            )
        }
    }
} 