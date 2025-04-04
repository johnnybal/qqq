package com.lengleng.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.lengleng.models.Poll
import com.lengleng.services.FirebaseService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class PollsViewModel @Inject constructor(
    private val firebaseService: FirebaseService
) : ViewModel() {
    
    private val _polls = MutableStateFlow<List<Poll>>(emptyList())
    val polls: StateFlow<List<Poll>> = _polls.asStateFlow()
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()
    
    private val _selectedCategory = MutableStateFlow<Poll.PollCategory?>(null)
    val selectedCategory: StateFlow<Poll.PollCategory?> = _selectedCategory.asStateFlow()
    
    init {
        loadPolls()
    }
    
    fun refreshPolls() {
        loadPolls()
    }
    
    fun setCategory(category: Poll.PollCategory?) {
        _selectedCategory.value = category
        loadPolls()
    }
    
    private fun loadPolls() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                val allPolls = firebaseService.fetchPolls()
                _polls.value = if (_selectedCategory.value != null) {
                    allPolls.filter { it.category == _selectedCategory.value }
                } else {
                    allPolls
                }
            } catch (e: Exception) {
                // Handle error
            } finally {
                _isLoading.value = false
            }
        }
    }
    
    fun voteOnPoll(pollId: String, optionId: String) {
        viewModelScope.launch {
            try {
                val result = firebaseService.voteOnPoll(pollId, optionId)
                if (result.isSuccess) {
                    // Check for matches
                    val poll = _polls.value.find { it.id == pollId }
                    poll?.let {
                        val hasMatch = firebaseService.checkForMatches(pollId, optionId)
                        if (hasMatch) {
                            // Update poll with match information
                            loadPolls()
                        }
                    }
                }
            } catch (e: Exception) {
                // Handle error
            }
        }
    }
    
    fun boostPoll(pollId: String) {
        viewModelScope.launch {
            try {
                val result = firebaseService.boostPoll(pollId)
                if (result.isSuccess) {
                    loadPolls()
                }
            } catch (e: Exception) {
                // Handle error
            }
        }
    }
} 