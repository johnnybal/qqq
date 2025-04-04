package com.example.lengleng.di

import com.example.lengleng.services.*
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.messaging.FirebaseMessaging
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {
    
    @Provides
    @Singleton
    fun provideFirebaseAuth(): FirebaseAuth = FirebaseAuth.getInstance()
    
    @Provides
    @Singleton
    fun provideFirebaseFirestore(): FirebaseFirestore = FirebaseFirestore.getInstance()
    
    @Provides
    @Singleton
    fun provideFirebaseMessaging(): FirebaseMessaging = FirebaseMessaging.getInstance()
    
    @Provides
    @Singleton
    fun provideUserService(
        auth: FirebaseAuth,
        firestore: FirebaseFirestore
    ): UserService = UserService(auth, firestore)
    
    @Provides
    @Singleton
    fun providePollService(
        firestore: FirebaseFirestore
    ): PollService = PollService(firestore)
    
    @Provides
    @Singleton
    fun provideSocialService(
        firestore: FirebaseFirestore
    ): SocialService = SocialService(firestore)
    
    @Provides
    @Singleton
    fun provideNotificationService(
        messaging: FirebaseMessaging
    ): NotificationService = NotificationService(messaging)
} 