import React, { useEffect, useState } from 'react';
import { Box, Typography, Grid, Paper } from '@mui/material';
import { Line } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
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
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend
);

interface UserMetrics {
  dailyActiveUsers: number;
  weeklyActiveUsers: number;
  monthlyActiveUsers: number;
  newUsers: number;
  retentionRate: number;
}

const UserAnalytics: React.FC = () => {
  const [metrics, setMetrics] = useState<UserMetrics>({
    dailyActiveUsers: 0,
    weeklyActiveUsers: 0,
    monthlyActiveUsers: 0,
    newUsers: 0,
    retentionRate: 0,
  });
  const [dailyData, setDailyData] = useState<{ labels: string[]; data: number[] }>({
    labels: [],
    data: [],
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchUserMetrics = async () => {
      try {
        // Get daily active users (last 7 days)
        const last7Days = Array.from({ length: 7 }, (_, i) => {
          const date = subDays(new Date(), i);
          return format(date, 'yyyy-MM-dd');
        }).reverse();

        const dailyUsersData = {
          labels: last7Days.map(date => format(new Date(date), 'MMM dd')),
          data: [] as number[],
        };

        // Fetch user data from Firestore
        const usersRef = collection(db, 'users');
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        // Get daily active users
        for (const date of last7Days) {
          const startDate = new Date(date);
          startDate.setHours(0, 0, 0, 0);
          const endDate = new Date(date);
          endDate.setHours(23, 59, 59, 999);

          const q = query(
            usersRef,
            where('lastActive', '>=', startDate),
            where('lastActive', '<=', endDate)
          );
          const querySnapshot = await getDocs(q);
          dailyUsersData.data.push(querySnapshot.size);
        }

        // Get total users
        const totalUsersSnapshot = await getDocs(usersRef);
        const totalUsers = totalUsersSnapshot.size;

        // Get new users in the last 30 days
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
        const newUsersQuery = query(
          usersRef,
          where('createdAt', '>=', thirtyDaysAgo)
        );
        const newUsersSnapshot = await getDocs(newUsersQuery);
        const newUsers = newUsersSnapshot.size;

        // Calculate retention rate (users who returned in the last 7 days)
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
        const returningUsersQuery = query(
          usersRef,
          where('lastActive', '>=', sevenDaysAgo)
        );
        const returningUsersSnapshot = await getDocs(returningUsersQuery);
        const returningUsers = returningUsersSnapshot.size;
        const retentionRate = totalUsers > 0 ? (returningUsers / totalUsers) * 100 : 0;

        setMetrics({
          dailyActiveUsers: dailyUsersData.data[dailyUsersData.data.length - 1],
          weeklyActiveUsers: dailyUsersData.data.reduce((a, b) => a + b, 0),
          monthlyActiveUsers: totalUsers,
          newUsers,
          retentionRate,
        });
        setDailyData(dailyUsersData);
        setLoading(false);
      } catch (error) {
        console.error('Error fetching user metrics:', error);
        setLoading(false);
      }
    };

    fetchUserMetrics();
  }, []);

  const chartData = {
    labels: dailyData.labels,
    datasets: [
      {
        label: 'Daily Active Users',
        data: dailyData.data,
        fill: false,
        borderColor: 'rgb(75, 192, 192)',
        tension: 0.1,
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
        text: 'Daily Active Users (Last 7 Days)',
      },
    },
  };

  if (loading) {
    return <Typography>Loading user analytics...</Typography>;
  }

  return (
    <Box>
      <Grid container spacing={2}>
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 2, height: '100%' }}>
            <Typography variant="h6" gutterBottom>
              User Metrics
            </Typography>
            <Grid container spacing={2}>
              <Grid item xs={6}>
                <Typography variant="subtitle2" color="text.secondary">
                  Daily Active Users
                </Typography>
                <Typography variant="h4">{metrics.dailyActiveUsers}</Typography>
              </Grid>
              <Grid item xs={6}>
                <Typography variant="subtitle2" color="text.secondary">
                  Weekly Active Users
                </Typography>
                <Typography variant="h4">{metrics.weeklyActiveUsers}</Typography>
              </Grid>
              <Grid item xs={6}>
                <Typography variant="subtitle2" color="text.secondary">
                  Monthly Active Users
                </Typography>
                <Typography variant="h4">{metrics.monthlyActiveUsers}</Typography>
              </Grid>
              <Grid item xs={6}>
                <Typography variant="subtitle2" color="text.secondary">
                  New Users (30 days)
                </Typography>
                <Typography variant="h4">{metrics.newUsers}</Typography>
              </Grid>
              <Grid item xs={12}>
                <Typography variant="subtitle2" color="text.secondary">
                  Retention Rate (7 days)
                </Typography>
                <Typography variant="h4">{metrics.retentionRate.toFixed(1)}%</Typography>
              </Grid>
            </Grid>
          </Paper>
        </Grid>
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 2, height: '100%' }}>
            <Line data={chartData} options={chartOptions} />
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
};

export default UserAnalytics; 