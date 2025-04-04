package com.example.lengleng.services

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class LengLengMessagingService : FirebaseMessagingService() {
    private lateinit var notificationService: NotificationService

    override fun onCreate() {
        super.onCreate()
        notificationService = NotificationService(this)
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        notificationService.handleRemoteMessage(remoteMessage)
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        // Handle token refresh if needed
    }
} 