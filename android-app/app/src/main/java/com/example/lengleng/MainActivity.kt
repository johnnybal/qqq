package com.example.lengleng

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.*
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.example.lengleng.services.*
import com.example.lengleng.theme.AppTheme
import com.example.lengleng.views.*
import com.google.firebase.auth.FirebaseAuth

class MainActivity : ComponentActivity() {
    private val userService = UserService()
    private val pollService = PollService()
    private val socialService = SocialService()
    private val subscriptionService = SubscriptionService()
    private val themeService = ThemeService()
    private val analyticsService = AnalyticsService()
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        setContent {
            val navController = rememberNavController()
            var isLoggedIn by remember { mutableStateOf(FirebaseAuth.getInstance().currentUser != null) }
            
            AppTheme(themeService = themeService) {
                NavHost(
                    navController = navController,
                    startDestination = if (isLoggedIn) "home" else "login"
                ) {
                    composable("login") {
                        LoginView(
                            userService = userService,
                            onLoginSuccess = {
                                isLoggedIn = true
                                navController.navigate("home") {
                                    popUpTo("login") { inclusive = true }
                                }
                            }
                        )
                    }
                    
                    composable("home") {
                        HomeView(
                            pollService = pollService,
                            socialService = socialService,
                            subscriptionService = subscriptionService,
                            analyticsService = analyticsService,
                            onNavigateToPolls = { navController.navigate("polls") },
                            onNavigateToSocial = { navController.navigate("social") },
                            onNavigateToProfile = { navController.navigate("profile") }
                        )
                    }
                    
                    composable("polls") {
                        PollsView(
                            pollService = pollService,
                            subscriptionService = subscriptionService,
                            analyticsService = analyticsService,
                            onNavigateBack = { navController.popBackStack() }
                        )
                    }
                    
                    composable("social") {
                        SocialView(
                            socialService = socialService,
                            subscriptionService = subscriptionService,
                            onNavigateBack = { navController.popBackStack() }
                        )
                    }
                    
                    composable("profile") {
                        ProfileView(
                            userService = userService,
                            subscriptionService = subscriptionService,
                            themeService = themeService,
                            onNavigateToSubscription = { navController.navigate("subscription") },
                            onNavigateToTheme = { navController.navigate("theme") },
                            onSignOut = {
                                FirebaseAuth.getInstance().signOut()
                                isLoggedIn = false
                                navController.navigate("login") {
                                    popUpTo("home") { inclusive = true }
                                }
                            }
                        )
                    }
                    
                    composable("subscription") {
                        SubscriptionView(
                            subscriptionService = subscriptionService,
                            onNavigateBack = { navController.popBackStack() }
                        )
                    }
                    
                    composable("theme") {
                        ThemeView(
                            themeService = themeService,
                            subscriptionService = subscriptionService,
                            onNavigateBack = { navController.popBackStack() }
                        )
                    }
                }
            }
        }
    }
} 