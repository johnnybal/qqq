import React, { useState, useEffect } from 'react';
import {
  Box,
  Button,
  Card,
  CardContent,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Grid,
  IconButton,
  MenuItem,
  Select,
  TextField,
  Typography,
  FormControl,
  InputLabel,
} from '@mui/material';
import { Delete as DeleteIcon, Edit as EditIcon } from '@mui/icons-material';
import { collection, addDoc, getDocs, deleteDoc, doc, updateDoc } from 'firebase/firestore';
import { db } from '../config/firebase';

interface Poll {
  id: string;
  question: string;
  options: string[];
  category: string;
  visibility: string;
  createdAt: Date;
}

const PollManagement: React.FC = () => {
  const [polls, setPolls] = useState<Poll[]>([]);
  const [openDialog, setOpenDialog] = useState(false);
  const [editingPoll, setEditingPoll] = useState<Poll | null>(null);
  const [newPoll, setNewPoll] = useState({
    question: '',
    options: ['', ''],
    category: 'general',
    visibility: 'public',
  });

  const categories = ['General', 'School', 'Social', 'Entertainment', 'Sports', 'Other'];
  const visibilityOptions = ['Public', 'Friends Only', 'Private'];

  useEffect(() => {
    fetchPolls();
  }, []);

  const fetchPolls = async () => {
    try {
      const querySnapshot = await getDocs(collection(db, 'polls'));
      const pollsData = querySnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data().createdAt?.toDate(),
      })) as Poll[];
      setPolls(pollsData);
    } catch (error) {
      console.error('Error fetching polls:', error);
    }
  };

  const handleCreatePoll = async () => {
    try {
      const pollData = {
        ...newPoll,
        createdAt: new Date(),
      };
      await addDoc(collection(db, 'polls'), pollData);
      setNewPoll({
        question: '',
        options: ['', ''],
        category: 'general',
        visibility: 'public',
      });
      setOpenDialog(false);
      fetchPolls();
    } catch (error) {
      console.error('Error creating poll:', error);
    }
  };

  const handleDeletePoll = async (pollId: string) => {
    try {
      await deleteDoc(doc(db, 'polls', pollId));
      fetchPolls();
    } catch (error) {
      console.error('Error deleting poll:', error);
    }
  };

  const handleEditPoll = async () => {
    if (!editingPoll) return;
    try {
      await updateDoc(doc(db, 'polls', editingPoll.id), {
        question: editingPoll.question,
        options: editingPoll.options,
        category: editingPoll.category,
        visibility: editingPoll.visibility,
      });
      setEditingPoll(null);
      fetchPolls();
    } catch (error) {
      console.error('Error updating poll:', error);
    }
  };

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
        <Typography variant="h4">Poll Management</Typography>
        <Button variant="contained" color="primary" onClick={() => setOpenDialog(true)}>
          Create New Poll
        </Button>
      </Box>

      <Grid container spacing={3}>
        {polls.map((poll) => (
          <Grid item xs={12} md={6} lg={4} key={poll.id}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Typography variant="h6">{poll.question}</Typography>
                  <Box>
                    <IconButton onClick={() => setEditingPoll(poll)}>
                      <EditIcon />
                    </IconButton>
                    <IconButton onClick={() => handleDeletePoll(poll.id)}>
                      <DeleteIcon />
                    </IconButton>
                  </Box>
                </Box>
                <Typography variant="body2" color="text.secondary">
                  Category: {poll.category}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Visibility: {poll.visibility}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Options:
                </Typography>
                <ul>
                  {poll.options.map((option, index) => (
                    <li key={index}>{option}</li>
                  ))}
                </ul>
                <Typography variant="body2" color="text.secondary">
                  Created: {poll.createdAt?.toLocaleDateString()}
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* Create/Edit Poll Dialog */}
      <Dialog open={openDialog || !!editingPoll} onClose={() => {
        setOpenDialog(false);
        setEditingPoll(null);
      }}>
        <DialogTitle>{editingPoll ? 'Edit Poll' : 'Create New Poll'}</DialogTitle>
        <DialogContent>
          <TextField
            autoFocus
            margin="dense"
            label="Question"
            fullWidth
            value={editingPoll?.question || newPoll.question}
            onChange={(e) => {
              if (editingPoll) {
                setEditingPoll({ ...editingPoll, question: e.target.value });
              } else {
                setNewPoll({ ...newPoll, question: e.target.value });
              }
            }}
          />
          {(editingPoll?.options || newPoll.options).map((option, index) => (
            <TextField
              key={index}
              margin="dense"
              label={`Option ${index + 1}`}
              fullWidth
              value={option}
              onChange={(e) => {
                if (editingPoll) {
                  const newOptions = [...editingPoll.options];
                  newOptions[index] = e.target.value;
                  setEditingPoll({ ...editingPoll, options: newOptions });
                } else {
                  const newOptions = [...newPoll.options];
                  newOptions[index] = e.target.value;
                  setNewPoll({ ...newPoll, options: newOptions });
                }
              }}
            />
          ))}
          <Button
            onClick={() => {
              if (editingPoll) {
                setEditingPoll({
                  ...editingPoll,
                  options: [...editingPoll.options, ''],
                });
              } else {
                setNewPoll({
                  ...newPoll,
                  options: [...newPoll.options, ''],
                });
              }
            }}
          >
            Add Option
          </Button>
          <FormControl fullWidth margin="dense">
            <InputLabel>Category</InputLabel>
            <Select
              value={editingPoll?.category || newPoll.category}
              onChange={(e) => {
                if (editingPoll) {
                  setEditingPoll({ ...editingPoll, category: e.target.value });
                } else {
                  setNewPoll({ ...newPoll, category: e.target.value });
                }
              }}
            >
              {categories.map((category) => (
                <MenuItem key={category} value={category.toLowerCase()}>
                  {category}
                </MenuItem>
              ))}
            </Select>
          </FormControl>
          <FormControl fullWidth margin="dense">
            <InputLabel>Visibility</InputLabel>
            <Select
              value={editingPoll?.visibility || newPoll.visibility}
              onChange={(e) => {
                if (editingPoll) {
                  setEditingPoll({ ...editingPoll, visibility: e.target.value });
                } else {
                  setNewPoll({ ...newPoll, visibility: e.target.value });
                }
              }}
            >
              {visibilityOptions.map((visibility) => (
                <MenuItem key={visibility} value={visibility.toLowerCase()}>
                  {visibility}
                </MenuItem>
              ))}
            </Select>
          </FormControl>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => {
            setOpenDialog(false);
            setEditingPoll(null);
          }}>
            Cancel
          </Button>
          <Button onClick={editingPoll ? handleEditPoll : handleCreatePoll} color="primary">
            {editingPoll ? 'Save' : 'Create'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default PollManagement; 