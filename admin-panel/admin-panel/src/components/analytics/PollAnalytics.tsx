import React, { useEffect, useState } from 'react';
import { Box, Grid, Paper, Typography, Card, CardContent } from '@mui/material';
import {
  Line,
  Bar,
  Pie,
  Bubble,
} from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js';
import { format, subDays } from 'date-fns';
import { db } from '../../config/firebase';
import { collection, query, where, getDocs } from 'firebase/firestore';

// Register ChartJS components
ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
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
  pollsByCategory: Record<string, number>;
  responseTimeDistribution: number[];
  demographicBreakdown: Record<string, number>;
  hourlyActivity: number[];
}

const PollAnalytics: React.FC = () => {
  const [metrics, setMetrics] = useState<PollMetrics>({
    totalPolls: 0,
    activePolls: 0,
    totalVotes: 0,
    averageVotesPerPoll: 0,
    participationRate: 0,
    pollsByCategory: {},
    responseTimeDistribution: [],
    demographicBreakdown: {},
    hourlyActivity: Array(24).fill(0),
  });

  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchPollMetrics();
  }, []);

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

      // Add mock data for new metrics
      const mockData = {
        pollsByCategory: {
          'Academic': 45,
          'Social': 30,
          'Events': 15,
          'Feedback': 10,
        },
        responseTimeDistribution: [10, 25, 35, 20, 10],
        demographicBreakdown: {
          'Freshman': 30,
          'Sophomore': 25,
          'Junior': 20,
          'Senior': 15,
          'Graduate': 10,
        },
        hourlyActivity: Array(24).fill(0).map(() => Math.floor(Math.random() * 100)),
      };

      setMetrics({
        totalPolls,
        activePolls,
        totalVotes,
        averageVotesPerPoll,
        participationRate,
        ...mockData,
      });
      setLoading(false);
    } catch (error) {
      console.error('Error fetching poll metrics:', error);
      setLoading(false);
    }
  };

  const categoryData = {
    labels: Object.keys(metrics.pollsByCategory),
    datasets: [
      {
        data: Object.values(metrics.pollsByCategory),
        backgroundColor: [
          'rgba(255, 99, 132, 0.8)',
          'rgba(54, 162, 235, 0.8)',
          'rgba(255, 206, 86, 0.8)',
          'rgba(75, 192, 192, 0.8)',
        ],
      },
    ],
  };

  const responseTimeData = {
    labels: ['<1min', '1-2min', '2-5min', '5-10min', '>10min'],
    datasets: [
      {
        label: 'Response Time Distribution',
        data: metrics.responseTimeDistribution,
        backgroundColor: 'rgba(75, 192, 192, 0.8)',
      },
    ],
  };

  const demographicData = {
    labels: Object.keys(metrics.demographicBreakdown),
    datasets: [
      {
        label: 'Demographic Distribution',
        data: Object.values(metrics.demographicBreakdown),
        backgroundColor: 'rgba(153, 102, 255, 0.8)',
      },
    ],
  };

  const hourlyActivityData = {
    labels: Array.from({ length: 24 }, (_, i) => `${i}:00`),
    datasets: [
      {
        label: 'Hourly Activity',
        data: metrics.hourlyActivity,
        borderColor: 'rgb(75, 192, 192)',
        backgroundColor: 'rgba(75, 192, 192, 0.2)',
        fill: true,
      },
    ],
  };

  const chartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        position: 'top' as const,
      },
    },
  };

  if (loading) {
    return <Typography>Loading poll analytics...</Typography>;
  }

  return (
    <Box sx={{ flexGrow: 1, p: 3 }}>
      <Grid container spacing={3}>
        {/* Summary Cards */}
        <Grid item xs={12}>
          <Grid container spacing={2}>
            <Grid item xs={12} sm={6} md={3}>
              <Card>
                <CardContent>
                  <Typography color="textSecondary" gutterBottom>
                    Total Polls
                  </Typography>
                  <Typography variant="h4">{metrics.totalPolls}</Typography>
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Card>
                <CardContent>
                  <Typography color="textSecondary" gutterBottom>
                    Active Polls
                  </Typography>
                  <Typography variant="h4">{metrics.activePolls}</Typography>
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Card>
                <CardContent>
                  <Typography color="textSecondary" gutterBottom>
                    Total Votes
                  </Typography>
                  <Typography variant="h4">{metrics.totalVotes}</Typography>
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Card>
                <CardContent>
                  <Typography color="textSecondary" gutterBottom>
                    Participation Rate
                  </Typography>
                  <Typography variant="h4">{`${metrics.participationRate.toFixed(1)}%`}</Typography>
                </CardContent>
              </Card>
            </Grid>
          </Grid>
        </Grid>

        {/* Charts */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 2, height: 400 }}>
            <Typography variant="h6" gutterBottom>
              Polls by Category
            </Typography>
            <Box sx={{ height: 350 }}>
              <Pie data={categoryData} options={chartOptions} />
            </Box>
          </Paper>
        </Grid>

        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 2, height: 400 }}>
            <Typography variant="h6" gutterBottom>
              Response Time Distribution
            </Typography>
            <Box sx={{ height: 350 }}>
              <Bar data={responseTimeData} options={chartOptions} />
            </Box>
          </Paper>
        </Grid>

        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 2, height: 400 }}>
            <Typography variant="h6" gutterBottom>
              Demographic Breakdown
            </Typography>
            <Box sx={{ height: 350 }}>
              <Bar data={demographicData} options={chartOptions} />
            </Box>
          </Paper>
        </Grid>

        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 2, height: 400 }}>
            <Typography variant="h6" gutterBottom>
              Hourly Activity
            </Typography>
            <Box sx={{ height: 350 }}>
              <Line data={hourlyActivityData} options={chartOptions} />
            </Box>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
};

export default PollAnalytics; 