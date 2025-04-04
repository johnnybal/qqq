package com.lengleng.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.lengleng.models.Poll
import com.lengleng.ui.components.PollItem
import com.lengleng.viewmodels.PollsViewModel
import kotlinx.coroutines.launch

@Composable
fun PollsScreen(
    navController: NavController,
    viewModel: PollsViewModel = hiltViewModel()
) {
    val polls by viewModel.polls.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val selectedCategory by viewModel.selectedCategory.collectAsState()
    val scope = rememberCoroutineScope()
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Polls") },
                actions = {
                    IconButton(
                        onClick = { scope.launch { viewModel.refreshPolls() } },
                        enabled = !isLoading
                    ) {
                        Icon(Icons.Default.Refresh, contentDescription = "Refresh")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            // Category Filter
            CategoryFilter(
                selectedCategory = selectedCategory,
                onCategorySelected = { category ->
                    viewModel.setCategory(category)
                }
            )
            
            if (isLoading && polls.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .weight(1f),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            } else {
                LazyColumn(
                    modifier = Modifier
                        .fillMaxSize()
                        .weight(1f),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    items(polls) { poll ->
                        PollItem(
                            poll = poll,
                            onVote = { optionId ->
                                scope.launch {
                                    viewModel.voteOnPoll(poll.id, optionId)
                                }
                            },
                            onBoost = {
                                scope.launch {
                                    viewModel.boostPoll(poll.id)
                                }
                            }
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun CategoryFilter(
    selectedCategory: Poll.PollCategory?,
    onCategorySelected: (Poll.PollCategory?) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        FilterChip(
            selected = selectedCategory == null,
            onClick = { onCategorySelected(null) },
            label = { Text("All") }
        )
        Poll.PollCategory.values().forEach { category ->
            FilterChip(
                selected = selectedCategory == category,
                onClick = { onCategorySelected(category) },
                label = { Text(category.name) }
            )
        }
    }
} 