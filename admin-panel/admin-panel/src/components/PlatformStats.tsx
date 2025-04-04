import React, { useState, useEffect } from 'react';
import { Grid, Card, CardContent, Typography, CircularProgress, Alert } from '@mui/material';
import { PlatformStatsService } from '../services/PlatformStatsService';
import { PlatformStats, PlatformComparison } from '../models/PlatformStats';

const PlatformStatsComponent: React.FC = () => {
    const [stats, setStats] = useState<PlatformStats | null>(null);
    const [comparison, setComparison] = useState<PlatformComparison | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        const fetchStats = async () => {
            try {
                const data = await PlatformStatsService.getPlatformStats();
                setStats(data);
                setComparison(PlatformStatsService.calculateComparison(data));
                setError(null);
            } catch (err) {
                setError('Failed to fetch platform statistics');
                console.error(err);
            } finally {
                setLoading(false);
            }
        };

        fetchStats();
    }, []);

    if (loading) {
        return (
            <Grid container justifyContent="center" alignItems="center" style={{ minHeight: '200px' }}>
                <CircularProgress />
            </Grid>
        );
    }

    if (error) {
        return (
            <Grid container justifyContent="center" style={{ marginTop: '20px' }}>
                <Alert severity="error">{error}</Alert>
            </Grid>
        );
    }

    if (!stats || !comparison) {
        return null;
    }

    return (
        <Grid container spacing={3}>
            <Grid item xs={12} md={6}>
                <Card>
                    <CardContent>
                        <Typography variant="h6" gutterBottom>
                            iOS Statistics
                        </Typography>
                        <Typography>Total Users: {stats.ios.totalUsers}</Typography>
                        <Typography>Active Users: {stats.ios.activeUsers}</Typography>
                        <Typography>New Users (Last Month): {stats.ios.newUsersLastMonth}</Typography>
                    </CardContent>
                </Card>
            </Grid>
            <Grid item xs={12} md={6}>
                <Card>
                    <CardContent>
                        <Typography variant="h6" gutterBottom>
                            Android Statistics
                        </Typography>
                        <Typography>Total Users: {stats.android.totalUsers}</Typography>
                        <Typography>Active Users: {stats.android.activeUsers}</Typography>
                        <Typography>New Users (Last Month): {stats.android.newUsersLastMonth}</Typography>
                    </CardContent>
                </Card>
            </Grid>
            <Grid item xs={12}>
                <Card>
                    <CardContent>
                        <Typography variant="h6" gutterBottom>
                            Platform Comparison
                        </Typography>
                        <Typography>Total Users: iOS {comparison.totalUsers.iosPercentage}% vs Android {comparison.totalUsers.androidPercentage}%</Typography>
                        <Typography>Active Users: iOS {comparison.activeUsers.iosPercentage}% vs Android {comparison.activeUsers.androidPercentage}%</Typography>
                        <Typography>New Users: iOS {comparison.newUsers.iosPercentage}% vs Android {comparison.newUsers.androidPercentage}%</Typography>
                    </CardContent>
                </Card>
            </Grid>
            <Grid item xs={12}>
                <Typography variant="body2" color="textSecondary">
                    Last Updated: {new Date(stats.lastUpdated).toLocaleString()}
                </Typography>
            </Grid>
        </Grid>
    );
};

export default PlatformStatsComponent; 