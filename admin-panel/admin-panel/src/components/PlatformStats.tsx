import React, { useEffect, useState } from 'react';
import {
    Box,
    Card,
    CardContent,
    Grid,
    Typography,
    CircularProgress,
    useTheme
} from '@mui/material';
import { PlatformStats, PlatformComparison } from '../models/PlatformStats';
import { PlatformStatsService } from '../services/PlatformStatsService';

const PlatformStatsComponent: React.FC = () => {
    const [stats, setStats] = useState<PlatformStats | null>(null);
    const [comparison, setComparison] = useState<PlatformComparison | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const theme = useTheme();

    useEffect(() => {
        const fetchStats = async () => {
            try {
                const statsService = PlatformStatsService.getInstance();
                const platformStats = await statsService.getPlatformStats();
                const platformComparison = statsService.calculateComparison(platformStats);
                
                setStats(platformStats);
                setComparison(platformComparison);
                setLoading(false);
            } catch (err) {
                setError('Failed to load platform statistics');
                setLoading(false);
            }
        };

        fetchStats();
    }, []);

    if (loading) {
        return (
            <Box display="flex" justifyContent="center" alignItems="center" minHeight="200px">
                <CircularProgress />
            </Box>
        );
    }

    if (error) {
        return (
            <Box display="flex" justifyContent="center" alignItems="center" minHeight="200px">
                <Typography color="error">{error}</Typography>
            </Box>
        );
    }

    if (!stats || !comparison) {
        return null;
    }

    return (
        <Grid container spacing={3}>
            {/* Total Users */}
            <Grid item xs={12} md={6}>
                <Card>
                    <CardContent>
                        <Typography variant="h6" gutterBottom>
                            Total Users
                        </Typography>
                        <Box display="flex" alignItems="center" mb={2}>
                            <Box flex={1}>
                                <Typography variant="h4">
                                    {comparison.totalUsers.total.toLocaleString()}
                                </Typography>
                            </Box>
                            <Box>
                                <Typography color="textSecondary">
                                    iOS: {comparison.iosPercentage.toFixed(1)}%
                                </Typography>
                                <Typography color="textSecondary">
                                    Android: {comparison.androidPercentage.toFixed(1)}%
                                </Typography>
                            </Box>
                        </Box>
                        <Box display="flex" justifyContent="space-between">
                            <Typography>
                                iOS: {comparison.totalUsers.ios.toLocaleString()}
                            </Typography>
                            <Typography>
                                Android: {comparison.totalUsers.android.toLocaleString()}
                            </Typography>
                        </Box>
                    </CardContent>
                </Card>
            </Grid>

            {/* Active Users */}
            <Grid item xs={12} md={6}>
                <Card>
                    <CardContent>
                        <Typography variant="h6" gutterBottom>
                            Active Users (Last 30 Days)
                        </Typography>
                        <Box display="flex" alignItems="center" mb={2}>
                            <Box flex={1}>
                                <Typography variant="h4">
                                    {comparison.activeUsers.total.toLocaleString()}
                                </Typography>
                            </Box>
                            <Box>
                                <Typography color="textSecondary">
                                    iOS: {((comparison.activeUsers.ios / comparison.totalUsers.ios) * 100).toFixed(1)}%
                                </Typography>
                                <Typography color="textSecondary">
                                    Android: {((comparison.activeUsers.android / comparison.totalUsers.android) * 100).toFixed(1)}%
                                </Typography>
                            </Box>
                        </Box>
                        <Box display="flex" justifyContent="space-between">
                            <Typography>
                                iOS: {comparison.activeUsers.ios.toLocaleString()}
                            </Typography>
                            <Typography>
                                Android: {comparison.activeUsers.android.toLocaleString()}
                            </Typography>
                        </Box>
                    </CardContent>
                </Card>
            </Grid>

            {/* New Users */}
            <Grid item xs={12} md={6}>
                <Card>
                    <CardContent>
                        <Typography variant="h6" gutterBottom>
                            New Users (Last 30 Days)
                        </Typography>
                        <Box display="flex" alignItems="center" mb={2}>
                            <Box flex={1}>
                                <Typography variant="h4">
                                    {comparison.newUsers.total.toLocaleString()}
                                </Typography>
                            </Box>
                            <Box>
                                <Typography color="textSecondary">
                                    iOS: {((comparison.newUsers.ios / comparison.newUsers.total) * 100).toFixed(1)}%
                                </Typography>
                                <Typography color="textSecondary">
                                    Android: {((comparison.newUsers.android / comparison.newUsers.total) * 100).toFixed(1)}%
                                </Typography>
                            </Box>
                        </Box>
                        <Box display="flex" justifyContent="space-between">
                            <Typography>
                                iOS: {comparison.newUsers.ios.toLocaleString()}
                            </Typography>
                            <Typography>
                                Android: {comparison.newUsers.android.toLocaleString()}
                            </Typography>
                        </Box>
                    </CardContent>
                </Card>
            </Grid>

            {/* Last Updated */}
            <Grid item xs={12} md={6}>
                <Card>
                    <CardContent>
                        <Typography variant="h6" gutterBottom>
                            Last Updated
                        </Typography>
                        <Typography variant="body1">
                            {new Date(stats.lastUpdated).toLocaleString()}
                        </Typography>
                    </CardContent>
                </Card>
            </Grid>
        </Grid>
    );
};

export default PlatformStatsComponent; 