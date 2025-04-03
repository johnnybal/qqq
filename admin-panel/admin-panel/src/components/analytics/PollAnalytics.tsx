import React, { useEffect, useState } from 'react';
import { Box, Typography, Grid, Paper } from '@mui/material';
import { Bar } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js';
import { db } from '../../config/firebase';
import { collection, query, where, getDocs } from 'firebase/firestore';
import { format, subDays } from 'date-fns';

// Register ChartJS components
ChartJS.register(
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend
);

interface PollMetrics {
  totalPolls: number;
  activePolls: number;
  totalVotes: number;
  averageVotesPerPoll: number;
  participationRate: number;
}

const PollAnalytics: React.FC = () => {
  const [metrics, setMetrics] = useState<PollMetrics>({
    totalPolls: 0,
    activePolls: 0,
    totalVotes: 0,
    averageVotesPerPoll: 0,
    participationRate: 0,
  });
  const [dailyData, setDailyData] = useState<{ labels: string[]; data: number[] }>({
    labels: [],
    data: [],
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchPollMetrics = async () => {
      try {
        // Get polls created in the last 7 days
        const last7Days = Array.from({ length: 7 }, (_, i) => {
          const date = subDays(new Date(), i);
          return format(date, 'yyyy-MM-dd');
        }).reverse();

        const dailyPollsData = {
          labels: last7Days.map(date => format(new Date(date), 'MMM dd')),
          data: [] as number[],
        };

        // Fetch poll data from Firestore
        const pollsRef = collection(db, 'polls');
        
        // Get total polls
        const totalPollsSnapshot = await getDocs(pollsRef);
        const totalPolls = totalPollsSnapshot.size;
        
        // Get active polls (created in the last 30 days)
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
        const activePollsQuery = query(
          pollsRef,
          where('createdAt', '>=', thirtyDaysAgo)
        );
        const activePollsSnapshot = await getDocs(activePollsQuery);
        const activePolls = activePollsSnapshot.size;
        
        // Get daily polls
        for (const date of last7Days) {
          const startDate = new Date(date);
          startDate.setHours(0, 0, 0, 0);
          const endDate = new Date(date);
          endDate.setHours(23, 59, 59, 999);

          const q = query(
            pollsRef,
            where('createdAt', '>=', startDate),
            where('createdAt', '<=', endDate)
          );
          const querySnapshot = await getDocs(q);
          dailyPollsData.data.push(querySnapshot.size);
        }
        
        // Get votes
        const votesRef = collection(db, 'votes');
        const votesSnapshot = await getDocs(votesRef);
        const totalVotes = votesSnapshot.size;
        
        // Calculate average votes per poll
        const averageVotesPerPoll = totalPolls > 0 ? totalVotes / totalPolls : 0;
        
        // Calculate participation rate (users who voted / total users)
        const usersRef = collection(db, 'users');
        const usersSnapshot = await getDocs(usersRef);
        const totalUsers = usersSnapshot.size;
        
        // Get unique users who voted
        const uniqueVoters = new Set();
        votesSnapshot.forEach(doc => {
          const data = doc.data();
          if (data.userId) {
            uniqueVoters.add(data.userId);
          }
        });
        
        const participationRate = totalUsers > 0 ? (uniqueVoters.size / totalUsers) * 100 : 0;

        setMetrics({
          totalPolls,
          activePolls,
          totalVotes,
          averageVotesPerPoll,
          participationRate,
        });
        setDailyData(dailyPollsData);
        setLoading(false);
      } catch (error) {
        console.error('Error fetching poll metrics:', error);
        setLoading(false);
      }
    };

    fetchPollMetrics();
  }, []);

  const chartData = {
    labels: dailyData.labels,
    datasets: [
      {
        label: 'Polls Created',
        data: dailyData.data,
        backgroundColor: 'rgba(54, 162, 235, 0.5)',
      },
    ],
  };

  const chartOptions = {
    responsive: true,
    plugins: {
      legend: {
        position: 'top' as const,
      },
      title: {
        display: true,
        text: 'Polls Created (Last 7 Days)',
      },
    },
  };

  if (loading) {
    return <Typography>Loading poll analytics...</Typography>;
  }

  return (
    <Box>
      <Grid container spacing={2}>
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 2, height: '100%' }}>
            <Typography variant="h6" gutterBottom>
              Poll Metrics
            </Typography>
            <Grid container spacing={2}>
              <Grid item xs={6}>
                <Typography variant="subtitle2" color="text.secondary">
                  Total Polls
                </Typography>
                <Typography variant="h4">{metrics.totalPolls}</Typography>
              </Grid>
              <Grid item xs={6}>
                <Typography variant="subtitle2" color="text.secondary">
                  Active Polls (30 days)
                </Typography>
                <Typography variant="h4">{metrics.activePolls}</Typography>
              </Grid>
              <Grid item xs={6}>
                <Typography variant="subtitle2" color="text.secondary">
                  Total Votes
                </Typography>
                <Typography variant="h4">{metrics.totalVotes}</Typography>
              </Grid>
              <Grid item xs={6}>
                <Typography variant="subtitle2" color="text.secondary">
                  Avg. Votes per Poll
                </Typography>
                <Typography variant="h4">{metrics.averageVotesPerPoll.toFixed(1)}</Typography>
              </Grid>
              <Grid item xs={12}>
                <Typography variant="subtitle2" color="text.secondary">
                  Participation Rate
                </Typography>
                <Typography variant="h4">{metrics.participationRate.toFixed(1)}%</Typography>
              </Grid>
            </Grid>
          </Paper>
        </Grid>
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 2, height: '100%' }}>
            <Bar data={chartData} options={chartOptions} />
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
};

export default PollAnalytics; 