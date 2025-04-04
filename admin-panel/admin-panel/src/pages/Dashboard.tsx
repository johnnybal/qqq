import React from 'react';
import {
  Container,
  Grid,
  Paper,
  Typography,
  Box,
  AppBar,
  Toolbar,
  IconButton,
} from '@mui/material';
import { useAuth } from '../hooks/useAuth';
import { signOut } from 'firebase/auth';
import { auth } from '../config/firebase';
import UserAnalytics from '../components/analytics/UserAnalytics';
import PollAnalytics from '../components/analytics/PollAnalytics';
import SchoolAnalytics from '../components/analytics/SchoolAnalytics';
import LogoutIcon from '@mui/icons-material/Logout';
import PlatformStatsComponent from '../components/PlatformStats';

const Dashboard: React.FC = () => {
  const { user } = useAuth();

  const handleLogout = async () => {
    try {
      await signOut(auth);
    } catch (error) {
      console.error('Error signing out:', error);
    }
  };

  return (
    <Box sx={{ flexGrow: 1 }}>
      <AppBar position="static">
        <Toolbar>
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
            QQQ Admin Dashboard
          </Typography>
          <Typography variant="body1" sx={{ mr: 2 }}>
            {user?.email}
          </Typography>
          <IconButton color="inherit" onClick={handleLogout}>
            <LogoutIcon />
          </IconButton>
        </Toolbar>
      </AppBar>
      
      <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
        <Grid container spacing={3}>
          <Grid item xs={12}>
            <Paper sx={{ p: 2 }}>
              <Typography variant="h4" component="h1" gutterBottom>
                Welcome to the QQQ Admin Dashboard
              </Typography>
              <Typography variant="body1">
                Monitor user engagement, poll activity, and school analytics.
              </Typography>
            </Paper>
          </Grid>
          
          {/* User Analytics */}
          <Grid item xs={12}>
            <Paper sx={{ p: 2 }}>
              <Typography variant="h6" gutterBottom>
                User Analytics
              </Typography>
              <UserAnalytics />
            </Paper>
          </Grid>

          {/* Poll Analytics */}
          <Grid item xs={12}>
            <Paper sx={{ p: 2 }}>
              <Typography variant="h6" gutterBottom>
                Poll Analytics
              </Typography>
              <PollAnalytics
                pollData={{
                  labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
                  datasets: [
                    {
                      label: 'Polls Created',
                      data: [12, 19, 3, 5, 2, 3],
                      borderColor: 'rgb(75, 192, 192)',
                      backgroundColor: 'rgba(75, 192, 192, 0.5)',
                    },
                  ],
                }}
              />
            </Paper>
          </Grid>

          {/* School Analytics */}
          <Grid item xs={12}>
            <Paper sx={{ p: 2 }}>
              <Typography variant="h6" gutterBottom>
                School Analytics
              </Typography>
              <SchoolAnalytics
                schoolData={{
                  labels: ['School A', 'School B', 'School C', 'School D', 'School E'],
                  datasets: [
                    {
                      label: 'Active Users',
                      data: [65, 59, 80, 81, 56],
                      backgroundColor: 'rgba(54, 162, 235, 0.5)',
                    },
                  ],
                }}
              />
            </Paper>
          </Grid>

          <Grid item xs={12}>
            <Paper sx={{ p: 2 }}>
              <Typography variant="h5" gutterBottom>
                Platform Statistics
              </Typography>
              <PlatformStatsComponent />
            </Paper>
          </Grid>
        </Grid>
      </Container>
    </Box>
  );
};

export default Dashboard; 