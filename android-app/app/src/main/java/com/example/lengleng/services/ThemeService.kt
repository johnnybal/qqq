package com.example.lengleng.services

import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import java.util.*

data class Theme(
    val id: String,
    val name: String,
    val primaryColor: Color,
    val secondaryColor: Color,
    val tertiaryColor: Color,
    val isPremium: Boolean = false
)

class ThemeService {
    private val db = FirebaseFirestore.getInstance()
    private val auth = FirebaseAuth.getInstance()
    
    fun getThemes(onComplete: (List<Theme>) -> Unit) {
        db.collection("themes").get()
            .addOnSuccessListener { documents ->
                val themes = documents.mapNotNull { it.toObject(Theme::class.java) }
                onComplete(themes)
            }
            .addOnFailureListener { onComplete(emptyList()) }
    }
    
    fun getPremiumThemes(onComplete: (List<Theme>) -> Unit) {
        db.collection("themes")
            .whereEqualTo("isPremium", true)
            .get()
            .addOnSuccessListener { documents ->
                val themes = documents.mapNotNull { it.toObject(Theme::class.java) }
                onComplete(themes)
            }
            .addOnFailureListener { onComplete(emptyList()) }
    }
    
    fun getFreeThemes(onComplete: (List<Theme>) -> Unit) {
        db.collection("themes")
            .whereEqualTo("isPremium", false)
            .get()
            .addOnSuccessListener { documents ->
                val themes = documents.mapNotNull { it.toObject(Theme::class.java) }
                onComplete(themes)
            }
            .addOnFailureListener { onComplete(emptyList()) }
    }
    
    fun getUserTheme(userId: String, onComplete: (Theme?) -> Unit) {
        db.collection("users").document(userId).get()
            .addOnSuccessListener { document ->
                if (document.exists()) {
                    val themeId = document.getString("themeId")
                    if (themeId != null) {
                        db.collection("themes").document(themeId).get()
                            .addOnSuccessListener { themeDoc ->
                                if (themeDoc.exists()) {
                                    val theme = themeDoc.toObject(Theme::class.java)
                                    onComplete(theme)
                                } else {
                                    onComplete(null)
                                }
                            }
                            .addOnFailureListener { onComplete(null) }
                    } else {
                        onComplete(null)
                    }
                } else {
                    onComplete(null)
                }
            }
            .addOnFailureListener { onComplete(null) }
    }
    
    fun setUserTheme(userId: String, themeId: String, onComplete: (Boolean) -> Unit) {
        db.collection("users").document(userId).update(
            "themeId", themeId
        )
            .addOnSuccessListener { onComplete(true) }
            .addOnFailureListener { onComplete(false) }
    }
    
    fun createTheme(theme: Theme, onComplete: (Boolean) -> Unit) {
        db.collection("themes").document(theme.id).set(theme)
            .addOnSuccessListener { onComplete(true) }
            .addOnFailureListener { onComplete(false) }
    }
    
    fun updateTheme(theme: Theme, onComplete: (Boolean) -> Unit) {
        db.collection("themes").document(theme.id).set(theme)
            .addOnSuccessListener { onComplete(true) }
            .addOnFailureListener { onComplete(false) }
    }
    
    fun deleteTheme(themeId: String, onComplete: (Boolean) -> Unit) {
        db.collection("themes").document(themeId).delete()
            .addOnSuccessListener { onComplete(true) }
            .addOnFailureListener { onComplete(false) }
    }
} 