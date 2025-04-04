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
import com.example.lengleng.models.User
import com.example.lengleng.services.SocialService
import com.example.lengleng.services.SubscriptionService
import com.example.lengleng.models.PremiumFeature

@Composable
fun SocialView(
    navController: NavController,
    subscriptionService: SubscriptionService
) {
    var selectedTab by remember { mutableStateOf(0) }
    var friends by remember { mutableStateOf<List<User>>(emptyList()) }
    var pendingRequests by remember { mutableStateOf<List<User>>(emptyList()) }
    var isLoading by remember { mutableStateOf(false) }
    var invitesSent by remember { mutableStateOf(0) }
    var showPremiumLock by remember { mutableStateOf(false) }
    val socialService = SocialService()

    LaunchedEffect(Unit) {
        isLoading = true
        friends = socialService.getFriends()
        pendingRequests = socialService.getPendingRequests()
        isLoading = false
    }

    fun handleInvite(friend: User) {
        if (subscriptionService.isPremiumFeatureAvailable(PremiumFeature.UNLIMITED_INVITES)) {
            // Allow unlimited invites for premium users
            socialService.sendInvite(friend.id)
        } else if (invitesSent < 5) {
            // Free users limited to 5 invites
            socialService.sendInvite(friend.id)
            invitesSent++
        } else {
            // Show premium feature lock
            showPremiumLock = true
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp)
    ) {
        Text(
            text = "Social",
            style = MaterialTheme.typography.headlineMedium.copy(
                fontWeight = FontWeight.Bold,
                fontSize = 24.sp
            ),
            modifier = Modifier.padding(vertical = 16.dp)
        )

        TabRow(
            selectedTabIndex = selectedTab,
            containerColor = MaterialTheme.colorScheme.surface,
            contentColor = MaterialTheme.colorScheme.primary
        ) {
            Tab(
                text = { 
                    Text(
                        "Friends",
                        style = MaterialTheme.typography.titleMedium.copy(
                            fontWeight = FontWeight.Medium
                        )
                    )
                },
                selected = selectedTab == 0,
                onClick = { selectedTab = 0 }
            )
            Tab(
                text = { 
                    Text(
                        "Requests",
                        style = MaterialTheme.typography.titleMedium.copy(
                            fontWeight = FontWeight.Medium
                        )
                    )
                },
                selected = selectedTab == 1,
                onClick = { selectedTab = 1 }
            )
        }

        if (isLoading) {
            CircularProgressIndicator(
                modifier = Modifier
                    .size(48.dp)
                    .align(Alignment.CenterHorizontally)
                    .padding(vertical = 24.dp),
                strokeWidth = 2.dp
            )
        } else {
            when (selectedTab) {
                0 -> FriendsList(friends = friends)
                1 -> RequestsList(requests = pendingRequests)
            }
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
}

@Composable
fun FriendsList(friends: List<User>) {
    if (friends.isEmpty()) {
        Text(
            text = "No friends yet",
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
            items(friends) { friend ->
                FriendRow(friend = friend)
            }
        }
    }
}

@Composable
fun RequestsList(requests: List<User>) {
    if (requests.isEmpty()) {
        Text(
            text = "No pending requests",
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
            items(requests) { request ->
                RequestRow(user = request)
            }
        }
    }
}

@Composable
fun FriendRow(friend: User) {
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
            // TODO: Add profile picture
            Icon(
                imageVector = Icons.Default.Person,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(40.dp)
            )

            Spacer(modifier = Modifier.width(16.dp))

            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = friend.username,
                    style = MaterialTheme.typography.titleMedium.copy(
                        fontWeight = FontWeight.Medium
                    )
                )
                Text(
                    text = if (friend.isOnline) "Online" else "Offline",
                    style = MaterialTheme.typography.bodySmall.copy(
                        color = if (friend.isOnline) MaterialTheme.colorScheme.primary 
                               else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                )
            }

            IconButton(
                onClick = { /* TODO: Open chat */ }
            ) {
                Icon(
                    Icons.Default.Message,
                    contentDescription = "Chat",
                    tint = MaterialTheme.colorScheme.primary
                )
            }
        }
    }
}

@Composable
fun RequestRow(user: User) {
    val socialService = SocialService()

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
            // TODO: Add profile picture
            Icon(
                imageVector = Icons.Default.Person,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(40.dp)
            )

            Spacer(modifier = Modifier.width(16.dp))

            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = user.username,
                    style = MaterialTheme.typography.titleMedium.copy(
                        fontWeight = FontWeight.Medium
                    )
                )
                Text(
                    text = "Wants to be friends",
                    style = MaterialTheme.typography.bodySmall.copy(
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                )
            }

            Row {
                IconButton(
                    onClick = {
                        socialService.acceptRequest(user.id)
                    }
                ) {
                    Icon(
                        Icons.Default.Check,
                        contentDescription = "Accept",
                        tint = MaterialTheme.colorScheme.primary
                    )
                }

                IconButton(
                    onClick = {
                        socialService.rejectRequest(user.id)
                    }
                ) {
                    Icon(
                        Icons.Default.Close,
                        contentDescription = "Reject",
                        tint = MaterialTheme.colorScheme.error
                    )
                }
            }
        }
    }
} 