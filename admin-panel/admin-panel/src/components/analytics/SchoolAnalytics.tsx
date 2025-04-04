import React from 'react';
import { Card, CardContent, Typography, Box } from '@mui/material';
import { Bar } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend
} from 'chart.js';

ChartJS.register(
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend
);

interface SchoolAnalyticsProps {
  schoolData: {
    labels: string[];
    datasets: {
      label: string;
      data: number[];
      backgroundColor: string;
    }[];
  };
}

const SchoolAnalytics: React.FC<SchoolAnalyticsProps> = ({ schoolData }) => {
  return (
    <Card>
      <CardContent>
        <Typography variant="h6" gutterBottom>
          School Analytics
        </Typography>
        <Box sx={{ height: 300 }}>
          <Bar
            data={schoolData}
            options={{
              responsive: true,
              maintainAspectRatio: false,
              plugins: {
                legend: {
                  position: 'top' as const,
                },
              },
            }}
          />
        </Box>
      </CardContent>
    </Card>
  );
};

export default SchoolAnalytics; 