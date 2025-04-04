import { PlatformStats, PlatformComparison } from '../models/PlatformStats';

export class PlatformStatsService {
    private static instance: PlatformStatsService;
    private baseUrl: string;

    private constructor() {
        this.baseUrl = process.env.REACT_APP_API_BASE_URL || 'http://localhost:3000/api';
    }

    public static getInstance(): PlatformStatsService {
        if (!PlatformStatsService.instance) {
            PlatformStatsService.instance = new PlatformStatsService();
        }
        return PlatformStatsService.instance;
    }

    public async getPlatformStats(): Promise<PlatformStats> {
        try {
            const response = await fetch(`${this.baseUrl}/stats/platform`);
            if (!response.ok) {
                throw new Error('Failed to fetch platform stats');
            }
            return await response.json();
        } catch (error) {
            console.error('Error fetching platform stats:', error);
            throw error;
        }
    }

    public calculateComparison(stats: PlatformStats): PlatformComparison {
        const totalUsers = {
            ios: stats.ios.totalUsers,
            android: stats.android.totalUsers,
            total: stats.ios.totalUsers + stats.android.totalUsers
        };

        const activeUsers = {
            ios: stats.ios.activeUsers,
            android: stats.android.activeUsers,
            total: stats.ios.activeUsers + stats.android.activeUsers
        };

        const newUsers = {
            ios: stats.ios.newUsersLastMonth,
            android: stats.android.newUsersLastMonth,
            total: stats.ios.newUsersLastMonth + stats.android.newUsersLastMonth
        };

        const iosPercentage = (totalUsers.ios / totalUsers.total) * 100;
        const androidPercentage = (totalUsers.android / totalUsers.total) * 100;

        return {
            totalUsers,
            activeUsers,
            newUsers,
            iosPercentage,
            androidPercentage
        };
    }
} 