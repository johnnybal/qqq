package com.example.lengleng

import androidx.compose.runtime.Composable
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.example.lengleng.services.SubscriptionService
import com.example.lengleng.views.*

@Composable
fun App(subscriptionService: SubscriptionService) {
    val navController = rememberNavController()
    
    NavHost(navController = navController, startDestination = "login") {
        composable("login") {
            LoginView(navController)
        }
        composable("home") {
            HomeView(navController, subscriptionService)
        }
        composable("polls") {
            PollsView(navController, subscriptionService)
        }
        composable("social") {
            SocialView(navController, subscriptionService)
        }
        composable("profile") {
            ProfileView(navController, subscriptionService)
        }
        composable("settings") {
            SettingsView(navController, subscriptionService)
        }
        composable("subscription") {
            SubscriptionView(
                subscriptionService = subscriptionService,
                onBackClick = { navController.popBackStack() }
            )
        }
    }
} 