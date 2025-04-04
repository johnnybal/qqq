import React from 'react';
import { Box, Grid, Paper, Typography } from '@mui/material';
import {
  Line,
  Bar,
  Doughnut,
  Radar,
} from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  RadialLinearScale,
  Title,
  Tooltip,
  Legend,
  Filler,
} from 'chart.js';

// Register ChartJS components
ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  RadialLinearScale,
  Title,
  Tooltip,
  Legend,
  Filler,
);

const DashboardOverview: React.FC = () => {
  // Sample data - replace with real data from your backend
  const userActivityData = {
    labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    datasets: [
      {
        label: 'Daily Active Users',
        data: [1200, 1350, 1450, 1300, 1500, 1250, 1400],
        borderColor: 'rgb(75, 192, 192)',
        backgroundColor: 'rgba(75, 192, 192, 0.2)',
        fill: true,
      },
    ],
  };

  const pollEngagementData = {
    labels: ['Completed', 'In Progress', 'Not Started'],
    datasets: [
      {
        data: [65, 20, 15],
        backgroundColor: [
          'rgba(75, 192, 192, 0.8)',
          'rgba(255, 206, 86, 0.8)',
          'rgba(255, 99, 132, 0.8)',
        ],
      },
    ],
  };

  const retentionData = {
    labels: ['Day 1', 'Day 7', 'Day 30', 'Day 60', 'Day 90'],
    datasets: [
      {
        label: 'User Retention',
        data: [100, 80, 60, 45, 35],
        backgroundColor: 'rgba(54, 162, 235, 0.8)',
      },
    ],
  };

  const userSegmentsData = {
    labels: ['Students', 'Teachers', 'Admins', 'Premium Users', 'Trial Users', 'Inactive'],
    datasets: [
      {
        label: 'User Distribution',
        data: [70, 85, 65, 80, 60, 40],
        backgroundColor: 'rgba(255, 99, 132, 0.2)',
        borderColor: 'rgb(255, 99, 132)',
        pointBackgroundColor: 'rgb(255, 99, 132)',
        pointBorderColor: '#fff',
        pointHoverBackgroundColor: '#fff',
        pointHoverBorderColor: 'rgb(255, 99, 132)',
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

  const radarOptions = {
    ...chartOptions,
    scales: {
      r: {
        min: 0,
        max: 100,
        ticks: {
          stepSize: 20,
        },
      },
    },
  };

  return (
    <Box sx={{ flexGrow: 1, p: 3 }}>
      <Grid container spacing={3}>
        {/* User Activity Chart */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 2, height: 400 }}>
            <Typography variant="h6" gutterBottom>
              User Activity Trends
            </Typography>
            <Box sx={{ height: 350 }}>
              <Line data={userActivityData} options={chartOptions} />
            </Box>
          </Paper>
        </Grid>

        {/* Poll Engagement Chart */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 2, height: 400 }}>
            <Typography variant="h6" gutterBottom>
              Poll Engagement Distribution
            </Typography>
            <Box sx={{ height: 350 }}>
              <Doughnut data={pollEngagementData} options={chartOptions} />
            </Box>
          </Paper>
        </Grid>

        {/* Retention Chart */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 2, height: 400 }}>
            <Typography variant="h6" gutterBottom>
              User Retention Rates
            </Typography>
            <Box sx={{ height: 350 }}>
              <Bar data={retentionData} options={chartOptions} />
            </Box>
          </Paper>
        </Grid>

        {/* User Segments Chart */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 2, height: 400 }}>
            <Typography variant="h6" gutterBottom>
              User Segments Analysis
            </Typography>
            <Box sx={{ height: 350 }}>
              <Radar data={userSegmentsData} options={radarOptions} />
            </Box>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
};

export default DashboardOverview; 