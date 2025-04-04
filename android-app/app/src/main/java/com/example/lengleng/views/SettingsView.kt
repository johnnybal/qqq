@Composable
fun SettingsView(
    navController: NavController,
    subscriptionService: SubscriptionService
) {
    val currentTier by subscriptionService.currentTier.collectAsState()
    var showPremiumLock by remember { mutableStateOf(false) }
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        // ... existing settings ...
        
        Spacer(modifier = Modifier.height(24.dp))
        
        Text(
            text = "Premium Features",
            style = MaterialTheme.typography.titleLarge
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        PremiumFeatureItem(
            title = "Custom Themes",
            description = "Personalize your app with beautiful themes",
            isAvailable = subscriptionService.isPremiumFeatureAvailable(PremiumFeature.CUSTOM_THEMES),
            onClick = {
                if (subscriptionService.isPremiumFeatureAvailable(PremiumFeature.CUSTOM_THEMES)) {
                    // Show theme picker
                } else {
                    showPremiumLock = true
                }
            }
        )
        
        PremiumFeatureItem(
            title = "Advanced Analytics",
            description = "Get detailed insights about your polls",
            isAvailable = subscriptionService.isPremiumFeatureAvailable(PremiumFeature.ADVANCED_ANALYTICS),
            onClick = {
                if (subscriptionService.isPremiumFeatureAvailable(PremiumFeature.ADVANCED_ANALYTICS)) {
                    // Show analytics
                } else {
                    showPremiumLock = true
                }
            }
        )
        
        PremiumFeatureItem(
            title = "Priority Support",
            description = "Get help faster with priority support",
            isAvailable = subscriptionService.isPremiumFeatureAvailable(PremiumFeature.PRIORITY_SUPPORT),
            onClick = {
                if (subscriptionService.isPremiumFeatureAvailable(PremiumFeature.PRIORITY_SUPPORT)) {
                    // Show priority support
                } else {
                    showPremiumLock = true
                }
            }
        )
        
        if (showPremiumLock) {
            PremiumFeatureLockView(
                feature = PremiumFeature.CUSTOM_THEMES,
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
private fun PremiumFeatureItem(
    title: String,
    description: String,
    isAvailable: Boolean,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (isAvailable) {
                MaterialTheme.colorScheme.surface
            } else {
                MaterialTheme.colorScheme.surfaceVariant
            }
        )
    ) {
        Row(
            modifier = Modifier
                .padding(16.dp)
                .fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(
                modifier = Modifier.weight(1f)
            ) {
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
            
            if (!isAvailable) {
                Icon(
                    imageVector = Icons.Default.Lock,
                    contentDescription = "Premium Feature",
                    tint = MaterialTheme.colorScheme.primary
                )
            }
        }
    }
} 