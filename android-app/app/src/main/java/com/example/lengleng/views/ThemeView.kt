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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.lengleng.models.SubscriptionTier
import com.example.lengleng.services.SubscriptionService
import com.example.lengleng.services.ThemeService
import com.google.firebase.auth.FirebaseAuth

@Composable
fun ThemeView(
    themeService: ThemeService,
    subscriptionService: SubscriptionService,
    onNavigateBack: () -> Unit
) {
    var themes by remember { mutableStateOf<List<Theme>>(emptyList()) }
    var selectedTheme by remember { mutableStateOf<Theme?>(null) }
    var currentSubscription by remember { mutableStateOf<SubscriptionTier>(SubscriptionTier.FREE) }
    var isLoading by remember { mutableStateOf(true) }
    
    val userId = FirebaseAuth.getInstance().currentUser?.uid ?: return
    
    LaunchedEffect(Unit) {
        themeService.getThemes { fetchedThemes ->
            themes = fetchedThemes
            themeService.getUserTheme(userId) { userTheme ->
                selectedTheme = userTheme
                isLoading = false
            }
        }
        subscriptionService.getSubscription(userId) { subscription ->
            currentSubscription = subscription
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Themes") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { padding ->
        if (isLoading) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                item {
                    Text(
                        text = "Select a Theme",
                        style = MaterialTheme.typography.headlineMedium,
                        fontWeight = FontWeight.Bold
                    )
                }
                
                items(themes) { theme ->
                    ThemeCard(
                        theme = theme,
                        isSelected = selectedTheme?.id == theme.id,
                        isPremium = theme.isPremium,
                        hasPremiumAccess = currentSubscription == SubscriptionTier.POWER_MODE,
                        onSelect = {
                            if (!theme.isPremium || currentSubscription == SubscriptionTier.POWER_MODE) {
                                themeService.setUserTheme(userId, theme.id) { success ->
                                    if (success) {
                                        selectedTheme = theme
                                    }
                                }
                            }
                        }
                    )
                }
            }
        }
    }
}

@Composable
fun ThemeCard(
    theme: Theme,
    isSelected: Boolean,
    isPremium: Boolean,
    hasPremiumAccess: Boolean,
    onSelect: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        onClick = onSelect,
        colors = CardDefaults.cardColors(
            containerColor = if (isSelected) theme.primaryColor else MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = theme.name,
                    style = MaterialTheme.typography.titleLarge,
                    color = if (isSelected) Color.White else MaterialTheme.colorScheme.onSurface
                )
                
                if (isPremium && !hasPremiumAccess) {
                    Icon(
                        imageVector = Icons.Default.Lock,
                        contentDescription = "Premium",
                        tint = MaterialTheme.colorScheme.primary
                    )
                } else if (isSelected) {
                    Icon(
                        imageVector = Icons.Default.Check,
                        contentDescription = "Selected",
                        tint = Color.White
                    )
                }
            }
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Box(
                    modifier = Modifier
                        .size(32.dp)
                        .background(theme.primaryColor)
                )
                Box(
                    modifier = Modifier
                        .size(32.dp)
                        .background(theme.secondaryColor)
                )
                Box(
                    modifier = Modifier
                        .size(32.dp)
                        .background(theme.tertiaryColor)
                )
            }
        }
    }
} 