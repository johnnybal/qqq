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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.android.billingclient.api.ProductDetails
import com.example.lengleng.services.SubscriptionService
import com.example.lengleng.services.SubscriptionTier

@Composable
fun SubscriptionView(
    subscriptionService: SubscriptionService,
    onBackClick: () -> Unit
) {
    val context = LocalContext.current
    val currentTier by subscriptionService.currentTier.collectAsState()
    val availableProducts by subscriptionService.availableProducts.collectAsState()
    val freeTrialEligible by subscriptionService.freeTrialEligible.collectAsState()
    val pollsVotedForTrial by subscriptionService.pollsVotedForTrial.collectAsState()
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Power Mode") },
                navigationIcon = {
                    IconButton(onClick = onBackClick) {
                        Icon(Icons.Default.ArrowBack, "Back")
                    }
                }
            )
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            item {
                Spacer(modifier = Modifier.height(16.dp))
                
                Text(
                    text = "Upgrade to Power Mode",
                    style = MaterialTheme.typography.headlineMedium,
                    textAlign = TextAlign.Center
                )
                
                Spacer(modifier = Modifier.height(8.dp))
                
                Text(
                    text = "Get access to all premium features",
                    style = MaterialTheme.typography.bodyLarge,
                    textAlign = TextAlign.Center
                )
                
                Spacer(modifier = Modifier.height(24.dp))
            }
            
            item {
                FeatureList()
                Spacer(modifier = Modifier.height(24.dp))
            }
            
            if (freeTrialEligible) {
                item {
                    FreeTrialCard(
                        pollsVoted = pollsVotedForTrial,
                        onStartTrial = { subscriptionService.startFreeTrial() }
                    )
                    Spacer(modifier = Modifier.height(24.dp))
                }
            }
            
            items(availableProducts) { product ->
                SubscriptionPlanCard(
                    product = product,
                    isCurrentPlan = currentTier == SubscriptionTier.POWER_MODE,
                    onSubscribe = { subscriptionService.purchase(context as android.app.Activity, product) }
                )
                Spacer(modifier = Modifier.height(16.dp))
            }
            
            item {
                Spacer(modifier = Modifier.height(16.dp))
                TermsAndConditions()
                Spacer(modifier = Modifier.height(32.dp))
            }
        }
    }
}

@Composable
private fun FeatureList() {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
    ) {
        FeatureItem(
            icon = Icons.Default.People,
            title = "Unlimited Invites",
            description = "Invite as many friends as you want to your polls"
        )
        FeatureItem(
            icon = Icons.Default.Analytics,
            title = "Advanced Analytics",
            description = "Get detailed insights about your polls"
        )
        FeatureItem(
            icon = Icons.Default.Palette,
            title = "Custom Themes",
            description = "Personalize your app with beautiful themes"
        )
        FeatureItem(
            icon = Icons.Default.Support,
            title = "Priority Support",
            description = "Get help faster with priority support"
        )
    }
}

@Composable
private fun FeatureItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    description: String
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            modifier = Modifier.size(24.dp),
            tint = MaterialTheme.colorScheme.primary
        )
        Spacer(modifier = Modifier.width(16.dp))
        Column {
            Text(
                text = title,
                style = MaterialTheme.typography.titleMedium
            )
            Text(
                text = description,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun FreeTrialCard(
    pollsVoted: Int,
    onStartTrial: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
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
                text = "You've earned a free trial!",
                style = MaterialTheme.typography.titleLarge,
                textAlign = TextAlign.Center
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "You've voted on $pollsVoted polls",
                style = MaterialTheme.typography.bodyMedium,
                textAlign = TextAlign.Center
            )
            Spacer(modifier = Modifier.height(16.dp))
            Button(onClick = onStartTrial) {
                Text("Start Free Trial")
            }
        }
    }
}

@Composable
private fun SubscriptionPlanCard(
    product: ProductDetails,
    isCurrentPlan: Boolean,
    onSubscribe: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (isCurrentPlan) {
                MaterialTheme.colorScheme.primaryContainer
            } else {
                MaterialTheme.colorScheme.surface
            }
        )
    ) {
        Column(
            modifier = Modifier
                .padding(16.dp)
                .fillMaxWidth()
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = product.name,
                    style = MaterialTheme.typography.titleLarge
                )
                Text(
                    text = product.subscriptionOfferDetails?.firstOrNull()?.pricingPhases?.pricingPhaseList?.firstOrNull()?.formattedPrice ?: "",
                    style = MaterialTheme.typography.titleLarge
                )
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = product.description,
                style = MaterialTheme.typography.bodyMedium
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Button(
                onClick = onSubscribe,
                modifier = Modifier.fillMaxWidth(),
                enabled = !isCurrentPlan
            ) {
                Text(if (isCurrentPlan) "Current Plan" else "Subscribe")
            }
        }
    }
}

@Composable
private fun TermsAndConditions() {
    Text(
        text = "Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period. You can manage your subscription in your Google Play account settings.",
        style = MaterialTheme.typography.bodySmall,
        textAlign = TextAlign.Center,
        modifier = Modifier.padding(horizontal = 16.dp)
    )
} 