package com.example.lengleng.views

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.example.lengleng.services.PremiumFeature
import com.example.lengleng.services.SubscriptionService

@Composable
fun PremiumFeatureLockView(
    feature: PremiumFeature,
    subscriptionService: SubscriptionService,
    onUpgradeClick: () -> Unit
) {
    var showUpgradeDialog by remember { mutableStateOf(false) }
    
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier
                .padding(16.dp)
                .fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = Icons.Default.Lock,
                contentDescription = "Premium Feature",
                modifier = Modifier.size(48.dp),
                tint = MaterialTheme.colorScheme.primary
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Text(
                text = "Premium Feature",
                style = MaterialTheme.typography.titleLarge,
                textAlign = TextAlign.Center
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = when (feature) {
                    PremiumFeature.UNLIMITED_INVITES -> "Unlock unlimited invites to your polls"
                    PremiumFeature.ADVANCED_ANALYTICS -> "Get detailed analytics and insights"
                    PremiumFeature.CUSTOM_THEMES -> "Customize your app with beautiful themes"
                    PremiumFeature.PRIORITY_SUPPORT -> "Get priority support for any issues"
                },
                style = MaterialTheme.typography.bodyMedium,
                textAlign = TextAlign.Center
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Button(
                onClick = { showUpgradeDialog = true },
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Upgrade to Power Mode")
            }
        }
    }
    
    if (showUpgradeDialog) {
        AlertDialog(
            onDismissRequest = { showUpgradeDialog = false },
            title = { Text("Upgrade to Power Mode") },
            text = {
                Column {
                    Text("Get access to all premium features:")
                    Spacer(modifier = Modifier.height(8.dp))
                    Text("• Unlimited invites")
                    Text("• Advanced analytics")
                    Text("• Custom themes")
                    Text("• Priority support")
                    Spacer(modifier = Modifier.height(16.dp))
                    Text("Choose your plan:")
                }
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        showUpgradeDialog = false
                        onUpgradeClick()
                    }
                ) {
                    Text("View Plans")
                }
            },
            dismissButton = {
                TextButton(onClick = { showUpgradeDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
} 