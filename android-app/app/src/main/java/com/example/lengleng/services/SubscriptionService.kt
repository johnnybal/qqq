package com.example.lengleng.services

import android.app.Activity
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.android.billingclient.api.*
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import java.util.concurrent.TimeUnit

enum class SubscriptionTier {
    FREE,
    POWER_MODE
}

enum class PremiumFeature {
    UNLIMITED_INVITES,
    ADVANCED_ANALYTICS,
    CUSTOM_THEMES,
    PRIORITY_SUPPORT
}

class SubscriptionService : ViewModel() {
    private val billingClient: BillingClient
    private val db = FirebaseFirestore.getInstance()
    private val auth = FirebaseAuth.getInstance()
    
    private val _currentTier = MutableStateFlow(SubscriptionTier.FREE)
    val currentTier: StateFlow<SubscriptionTier> = _currentTier
    
    private val _isSubscribed = MutableStateFlow(false)
    val isSubscribed: StateFlow<Boolean> = _isSubscribed
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading
    
    private val _availableProducts = MutableStateFlow<List<ProductDetails>>(emptyList())
    val availableProducts: StateFlow<List<ProductDetails>> = _availableProducts
    
    private val _freeTrialEligible = MutableStateFlow(false)
    val freeTrialEligible: StateFlow<Boolean> = _freeTrialEligible
    
    private val _pollsVotedForTrial = MutableStateFlow(0)
    val pollsVotedForTrial: StateFlow<Int> = _pollsVotedForTrial
    
    init {
        billingClient = BillingClient.newBuilder(context)
            .setListener(purchasesUpdatedListener)
            .enablePendingPurchases()
            .build()
            
        billingClient.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(billingResult: BillingResult) {
                if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                    loadProducts()
                    loadSubscriptionStatus()
                    checkFreeTrialEligibility()
                }
            }
            
            override fun onBillingServiceDisconnected() {
                // Try to restart the connection
                billingClient.startConnection(this)
            }
        })
    }
    
    private val purchasesUpdatedListener = PurchasesUpdatedListener { billingResult, purchases ->
        if (billingResult.responseCode == BillingClient.BillingResponseCode.OK && purchases != null) {
            for (purchase in purchases) {
                handlePurchase(purchase)
            }
        }
    }
    
    private fun loadProducts() {
        val params = QueryProductDetailsParams.newBuilder()
            .setProductList(
                listOf(
                    QueryProductDetailsParams.Product.newBuilder()
                        .setProductId("com.lengleng.powermode.monthly")
                        .setProductType(BillingClient.ProductType.SUBS)
                        .build(),
                    QueryProductDetailsParams.Product.newBuilder()
                        .setProductId("com.lengleng.powermode.yearly")
                        .setProductType(BillingClient.ProductType.SUBS)
                        .build()
                )
            )
            .build()
            
        billingClient.queryProductDetailsAsync(params) { billingResult, productDetailsList ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                _availableProducts.value = productDetailsList
            }
        }
    }
    
    private fun loadSubscriptionStatus() {
        val userId = auth.currentUser?.uid ?: return
        
        db.collection("users").document(userId).get()
            .addOnSuccessListener { document ->
                if (document.exists()) {
                    val tier = document.getString("subscriptionTier")
                    _currentTier.value = when (tier) {
                        "POWER_MODE" -> SubscriptionTier.POWER_MODE
                        else -> SubscriptionTier.FREE
                    }
                    _isSubscribed.value = tier == "POWER_MODE"
                }
            }
    }
    
    private fun checkFreeTrialEligibility() {
        val userId = auth.currentUser?.uid ?: return
        
        db.collection("users").document(userId).get()
            .addOnSuccessListener { document ->
                if (document.exists()) {
                    val hasUsedTrial = document.getBoolean("hasUsedFreeTrial") ?: false
                    val pollsVoted = document.getLong("pollsVotedForTrial")?.toInt() ?: 0
                    
                    _freeTrialEligible.value = !hasUsedTrial && pollsVoted >= 3
                    _pollsVotedForTrial.value = pollsVoted
                }
            }
    }
    
    fun purchase(activity: Activity, productDetails: ProductDetails) {
        val billingFlowParams = BillingFlowParams.newBuilder()
            .setProductDetailsParamsList(
                listOf(
                    BillingFlowParams.ProductDetailsParams.newBuilder()
                        .setProductDetails(productDetails)
                        .build()
                )
            )
            .build()
            
        billingClient.launchBillingFlow(activity, billingFlowParams)
    }
    
    private fun handlePurchase(purchase: Purchase) {
        if (purchase.purchaseState == Purchase.PurchaseState.PURCHASED) {
            if (!purchase.isAcknowledged) {
                val acknowledgePurchaseParams = AcknowledgePurchaseParams.newBuilder()
                    .setPurchaseToken(purchase.purchaseToken)
                    .build()
                    
                billingClient.acknowledgePurchase(acknowledgePurchaseParams) { billingResult ->
                    if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                        updateSubscriptionStatus(purchase)
                    }
                }
            }
        }
    }
    
    private fun updateSubscriptionStatus(purchase: Purchase) {
        val userId = auth.currentUser?.uid ?: return
        
        db.collection("users").document(userId).update(
            mapOf(
                "subscriptionTier" to "POWER_MODE",
                "subscriptionExpiryDate" to System.currentTimeMillis() + TimeUnit.DAYS.toMillis(30),
                "subscriptionProductId" to purchase.products[0],
                "lastTransactionId" to purchase.orderId
            )
        )
        .addOnSuccessListener {
            _currentTier.value = SubscriptionTier.POWER_MODE
            _isSubscribed.value = true
        }
    }
    
    fun isPremiumFeatureAvailable(feature: PremiumFeature): Boolean {
        return when (feature) {
            PremiumFeature.UNLIMITED_INVITES -> isSubscribed.value
            PremiumFeature.ADVANCED_ANALYTICS -> isSubscribed.value
            PremiumFeature.CUSTOM_THEMES -> isSubscribed.value
            PremiumFeature.PRIORITY_SUPPORT -> isSubscribed.value
        }
    }
    
    fun startFreeTrial() {
        val userId = auth.currentUser?.uid ?: return
        
        db.collection("users").document(userId).update(
            mapOf(
                "subscriptionTier" to "POWER_MODE",
                "subscriptionExpiryDate" to System.currentTimeMillis() + TimeUnit.DAYS.toMillis(30),
                "hasUsedFreeTrial" to true,
                "freeTrialStartedAt" to System.currentTimeMillis(),
                "isFreeTrial" to true
            )
        )
        .addOnSuccessListener {
            _currentTier.value = SubscriptionTier.POWER_MODE
            _isSubscribed.value = true
            _freeTrialEligible.value = false
        }
    }
    
    fun incrementPollsVotedForTrial() {
        val userId = auth.currentUser?.uid ?: return
        
        db.collection("users").document(userId).update(
            "pollsVotedForTrial", FieldValue.increment(1)
        )
        .addOnSuccessListener {
            _pollsVotedForTrial.value = _pollsVotedForTrial.value + 1
            if (_pollsVotedForTrial.value >= 3) {
                _freeTrialEligible.value = true
            }
        }
    }
    
    override fun onCleared() {
        super.onCleared()
        billingClient.endConnection()
    }
} 