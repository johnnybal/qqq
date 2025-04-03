import React, { useEffect, useState } from 'react';
import { Box, Typography, Grid, Paper, Table, TableBody, TableCell, TableContainer, TableHead, TableRow } from '@mui/material';
import { db } from '../../config/firebase';
import { collection, query, where, getDocs } from 'firebase/firestore';

interface SchoolMetrics {
  schoolId: string;
  schoolName: string;
  userCount: number;
  pollCount: number;
  voteCount: number;
  premiumUsers: number;
  premiumConversionRate: number;
}

const SchoolAnalytics: React.FC = () => {
  const [schoolMetrics, setSchoolMetrics] = useState<SchoolMetrics[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchSchoolMetrics = async () => {
      try {
        // Get all schools
        const schoolsRef = collection(db, 'schools');
        const schoolsSnapshot = await getDocs(schoolsRef);
        
        const metrics: SchoolMetrics[] = [];
        
        // For each school, calculate metrics
        for (const schoolDoc of schoolsSnapshot.docs) {
          const schoolData = schoolDoc.data();
          const schoolId = schoolDoc.id;
          const schoolName = schoolData.name || 'Unknown School';
          
          // Get users in this school
          const usersRef = collection(db, 'users');
          const usersQuery = query(usersRef, where('schoolId', '==', schoolId));
          const usersSnapshot = await getDocs(usersQuery);
          const userCount = usersSnapshot.size;
          
          // Get polls created by users in this school
          const pollsRef = collection(db, 'polls');
          const pollsQuery = query(pollsRef, where('schoolId', '==', schoolId));
          const pollsSnapshot = await getDocs(pollsQuery);
          const pollCount = pollsSnapshot.size;
          
          // Get votes on polls from this school
          const votesRef = collection(db, 'votes');
          const votesQuery = query(votesRef, where('schoolId', '==', schoolId));
          const votesSnapshot = await getDocs(votesQuery);
          const voteCount = votesSnapshot.size;
          
          // Get premium users in this school
          const premiumUsersQuery = query(
            usersRef,
            where('schoolId', '==', schoolId),
            where('isPremium', '==', true)
          );
          const premiumUsersSnapshot = await getDocs(premiumUsersQuery);
          const premiumUsers = premiumUsersSnapshot.size;
          
          // Calculate premium conversion rate
          const premiumConversionRate = userCount > 0 ? (premiumUsers / userCount) * 100 : 0;
          
          metrics.push({
            schoolId,
            schoolName,
            userCount,
            pollCount,
            voteCount,
            premiumUsers,
            premiumConversionRate,
          });
        }
        
        // Sort by user count (descending)
        metrics.sort((a, b) => b.userCount - a.userCount);
        
        setSchoolMetrics(metrics);
        setLoading(false);
      } catch (error) {
        console.error('Error fetching school metrics:', error);
        setLoading(false);
      }
    };

    fetchSchoolMetrics();
  }, []);

  if (loading) {
    return <Typography>Loading school analytics...</Typography>;
  }

  return (
    <Box>
      <Paper sx={{ p: 2 }}>
        <Typography variant="h6" gutterBottom>
          School Analytics
        </Typography>
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>School</TableCell>
                <TableCell align="right">Users</TableCell>
                <TableCell align="right">Polls</TableCell>
                <TableCell align="right">Votes</TableCell>
                <TableCell align="right">Premium Users</TableCell>
                <TableCell align="right">Premium Conversion</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {schoolMetrics.map((school) => (
                <TableRow key={school.schoolId}>
                  <TableCell component="th" scope="row">
                    {school.schoolName}
                  </TableCell>
                  <TableCell align="right">{school.userCount}</TableCell>
                  <TableCell align="right">{school.pollCount}</TableCell>
                  <TableCell align="right">{school.voteCount}</TableCell>
                  <TableCell align="right">{school.premiumUsers}</TableCell>
                  <TableCell align="right">{school.premiumConversionRate.toFixed(1)}%</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      </Paper>
    </Box>
  );
};

export default SchoolAnalytics; 