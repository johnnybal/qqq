import React, { useState, useEffect } from 'react';
import {
  Box,
  Tabs,
  Tab,
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
  IconButton,
  Typography,
  Paper,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Grid,
  Card,
  CardContent,
  LinearProgress,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  BarChart as BarChartIcon,
  FileUpload as FileUploadIcon,
} from '@mui/icons-material';
import { DatePicker } from '@mui/x-date-pickers/DatePicker';

interface Poll {
  id: string;
  question: string;
  options: PollOption[];
  startDate: Date;
  endDate: Date;
  isActive: boolean;
  createdBy: string;
  createdAt: Date;
  updatedAt: Date;
  results: Record<string, number>;
  category: string;
  tags: string[];
  targetAudience: string;
  analytics: PollAnalytics;
}

interface PollOption {
  id: string;
  text: string;
  imageURL?: string;
  description?: string;
}

interface PollAnalytics {
  totalVotes: number;
  uniqueVoters: number;
  averageTimeSpent: number;
  completionRate: number;
  demographicBreakdown: Record<string, number>;
  timeSeriesData: TimeSeriesData[];
}

interface TimeSeriesData {
  timestamp: Date;
  voteCount: number;
  uniqueVoters: number;
}

interface PollBatch {
  polls: Poll[];
  importDate: Date;
  importedBy: string;
  source: string;
  validationStatus: string;
  errorCount: number;
  warningCount: number;
}

export const PollManagementSystem: React.FC = () => {
  const [selectedTab, setSelectedTab] = useState(0);
  const [activePolls, setActivePolls] = useState<Poll[]>([]);
  const [scheduledPolls, setScheduledPolls] = useState<Poll[]>([]);
  const [pastPolls, setPastPolls] = useState<Poll[]>([]);
  const [showCreatePoll, setShowCreatePoll] = useState(false);
  const [showBatchImport, setShowBatchImport] = useState(false);
  const [selectedPoll, setSelectedPoll] = useState<Poll | null>(null);

  useEffect(() => {
    loadPolls();
  }, []);

  const loadPolls = async () => {
    // TODO: Implement API call to fetch polls
  };

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setSelectedTab(newValue);
  };

  const handleCreatePoll = (poll: Poll) => {
    setActivePolls([...activePolls, poll]);
    setShowCreatePoll(false);
  };

  const handleUpdatePoll = (poll: Poll) => {
    const now = new Date();
    if (poll.startDate <= now && poll.endDate >= now) {
      setActivePolls(activePolls.map(p => p.id === poll.id ? poll : p));
    } else if (poll.startDate > now) {
      setScheduledPolls(scheduledPolls.map(p => p.id === poll.id ? poll : p));
    } else {
      setPastPolls(pastPolls.map(p => p.id === poll.id ? poll : p));
    }
    setSelectedPoll(null);
  };

  const handleImportPolls = (batch: PollBatch) => {
    const now = new Date();
    const newActivePolls = batch.polls.filter(
      poll => poll.startDate <= now && poll.endDate >= now
    );
    const newScheduledPolls = batch.polls.filter(
      poll => poll.startDate > now
    );
    const newPastPolls = batch.polls.filter(
      poll => poll.endDate < now
    );

    setActivePolls([...activePolls, ...newActivePolls]);
    setScheduledPolls([...scheduledPolls, ...newScheduledPolls]);
    setPastPolls([...pastPolls, ...newPastPolls]);
    setShowBatchImport(false);
  };

  return (
    <Box sx={{ width: '100%' }}>
      <Paper sx={{ p: 2 }}>
        <Tabs value={selectedTab} onChange={handleTabChange}>
          <Tab label="Active Polls" />
          <Tab label="Scheduled Polls" />
          <Tab label="Past Polls" />
          <Tab label="Analytics" />
        </Tabs>

        {selectedTab === 0 && (
          <Box sx={{ mt: 2 }}>
            <Box sx={{ display: 'flex', justifyContent: 'flex-end', mb: 2 }}>
              <Button
                variant="contained"
                startIcon={<AddIcon />}
                onClick={() => setShowCreatePoll(true)}
                sx={{ mr: 1 }}
              >
                Create Poll
              </Button>
              <Button
                variant="outlined"
                startIcon={<FileUploadIcon />}
                onClick={() => setShowBatchImport(true)}
              >
                Batch Import
              </Button>
            </Box>
            <List>
              {activePolls.map(poll => (
                <ListItem
                  key={poll.id}
                  button
                  onClick={() => setSelectedPoll(poll)}
                >
                  <ListItemText
                    primary={poll.question}
                    secondary={`Category: ${poll.category} | Target: ${poll.targetAudience}`}
                  />
                  <ListItemSecondaryAction>
                    <IconButton edge="end" aria-label="analytics">
                      <BarChartIcon />
                    </IconButton>
                    <IconButton edge="end" aria-label="edit">
                      <EditIcon />
                    </IconButton>
                    <IconButton edge="end" aria-label="delete">
                      <DeleteIcon />
                    </IconButton>
                  </ListItemSecondaryAction>
                </ListItem>
              ))}
            </List>
          </Box>
        )}

        {selectedTab === 1 && (
          <Box sx={{ mt: 2 }}>
            <List>
              {scheduledPolls.map(poll => (
                <ListItem
                  key={poll.id}
                  button
                  onClick={() => setSelectedPoll(poll)}
                >
                  <ListItemText
                    primary={poll.question}
                    secondary={`Starts: ${poll.startDate.toLocaleString()}`}
                  />
                  <ListItemSecondaryAction>
                    <IconButton edge="end" aria-label="edit">
                      <EditIcon />
                    </IconButton>
                    <IconButton edge="end" aria-label="delete">
                      <DeleteIcon />
                    </IconButton>
                  </ListItemSecondaryAction>
                </ListItem>
              ))}
            </List>
          </Box>
        )}

        {selectedTab === 2 && (
          <Box sx={{ mt: 2 }}>
            <List>
              {pastPolls.map(poll => (
                <ListItem
                  key={poll.id}
                  button
                  onClick={() => setSelectedPoll(poll)}
                >
                  <ListItemText
                    primary={poll.question}
                    secondary={`Ended: ${poll.endDate.toLocaleString()}`}
                  />
                  <ListItemSecondaryAction>
                    <IconButton edge="end" aria-label="analytics">
                      <BarChartIcon />
                    </IconButton>
                  </ListItemSecondaryAction>
                </ListItem>
              ))}
            </List>
          </Box>
        )}

        {selectedTab === 3 && (
          <Box sx={{ mt: 2 }}>
            <Grid container spacing={2}>
              <Grid item xs={12} md={6}>
                <Card>
                  <CardContent>
                    <Typography variant="h6">Overall Statistics</Typography>
                    <Typography>
                      Total Polls: {activePolls.length + scheduledPolls.length + pastPolls.length}
                    </Typography>
                    <Typography>
                      Active Polls: {activePolls.length}
                    </Typography>
                    <Typography>
                      Total Votes: {activePolls.reduce((sum, poll) => sum + poll.analytics.totalVotes, 0)}
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
              <Grid item xs={12} md={6}>
                <Card>
                  <CardContent>
                    <Typography variant="h6">Performance Metrics</Typography>
                    {activePolls.map(poll => (
                      <Box key={poll.id} sx={{ mb: 2 }}>
                        <Typography>{poll.question}</Typography>
                        <LinearProgress
                          variant="determinate"
                          value={poll.analytics.completionRate * 100}
                        />
                        <Typography variant="body2">
                          Completion Rate: {Math.round(poll.analytics.completionRate * 100)}%
                        </Typography>
                      </Box>
                    ))}
                  </CardContent>
                </Card>
              </Grid>
            </Grid>
          </Box>
        )}
      </Paper>

      {/* Create Poll Dialog */}
      <Dialog
        open={showCreatePoll}
        onClose={() => setShowCreatePoll(false)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>Create New Poll</DialogTitle>
        <DialogContent>
          {/* Add poll creation form fields */}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setShowCreatePoll(false)}>Cancel</Button>
          <Button onClick={() => setShowCreatePoll(false)}>Create</Button>
        </DialogActions>
      </Dialog>

      {/* Batch Import Dialog */}
      <Dialog
        open={showBatchImport}
        onClose={() => setShowBatchImport(false)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>Batch Import Polls</DialogTitle>
        <DialogContent>
          {/* Add batch import form fields */}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setShowBatchImport(false)}>Cancel</Button>
          <Button onClick={() => setShowBatchImport(false)}>Import</Button>
        </DialogActions>
      </Dialog>

      {/* Poll Detail Dialog */}
      <Dialog
        open={!!selectedPoll}
        onClose={() => setSelectedPoll(null)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>Poll Details</DialogTitle>
        <DialogContent>
          {selectedPoll && (
            <Box>
              <Typography variant="h6">{selectedPoll.question}</Typography>
              <Typography>Category: {selectedPoll.category}</Typography>
              <Typography>Target Audience: {selectedPoll.targetAudience}</Typography>
              <Typography>
                Duration: {selectedPoll.startDate.toLocaleString()} - {selectedPoll.endDate.toLocaleString()}
              </Typography>
              <Typography>Tags: {selectedPoll.tags.join(', ')}</Typography>
              <Typography variant="h6" sx={{ mt: 2 }}>Options</Typography>
              {selectedPoll.options.map(option => (
                <Box key={option.id} sx={{ mt: 1 }}>
                  <Typography>{option.text}</Typography>
                  {option.imageURL && (
                    <img
                      src={option.imageURL}
                      alt={option.text}
                      style={{ maxWidth: '100%', maxHeight: 200 }}
                    />
                  )}
                  {option.description && (
                    <Typography variant="body2" color="text.secondary">
                      {option.description}
                    </Typography>
                  )}
                </Box>
              ))}
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setSelectedPoll(null)}>Close</Button>
          <Button variant="contained" onClick={() => setSelectedPoll(null)}>
            Save Changes
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}; 