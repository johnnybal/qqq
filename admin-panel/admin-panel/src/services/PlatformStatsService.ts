import { PlatformStats, PlatformComparison } from '../models/PlatformStats';

export class PlatformStatsService {
    private static instance: PlatformStatsService;

    // Private constructor to prevent direct instantiation
    // eslint-disable-next-line @typescript-eslint/no-empty-function
    private constructor() {}

    public static getInstance(): PlatformStatsService {
        if (!PlatformStatsService.instance) {
            PlatformStatsService.instance = new PlatformStatsService();
        }
        return PlatformStatsService.instance;
    }

    public static async getPlatformStats(): Promise<PlatformStats> {
        // TODO: Replace with actual API call
        return {
            ios: {
                totalUsers: 1000,
                activeUsers: 800,
                newUsersLastMonth: 100
            },
            android: {
                totalUsers: 1500,
                activeUsers: 1200,
                newUsersLastMonth: 150
            },
            lastUpdated: new Date().toISOString()
        };
    }

    public static calculateComparison(stats: PlatformStats): PlatformComparison {
        const totalUsers = {
            ios: stats.ios.totalUsers,
            android: stats.android.totalUsers,
            total: stats.ios.totalUsers + stats.android.totalUsers,
            iosPercentage: (stats.ios.totalUsers / (stats.ios.totalUsers + stats.android.totalUsers)) * 100,
            androidPercentage: (stats.android.totalUsers / (stats.ios.totalUsers + stats.android.totalUsers)) * 100
        };

        const activeUsers = {
            ios: stats.ios.activeUsers,
            android: stats.android.activeUsers,
            total: stats.ios.activeUsers + stats.android.activeUsers,
            iosPercentage: (stats.ios.activeUsers / (stats.ios.activeUsers + stats.android.activeUsers)) * 100,
            androidPercentage: (stats.android.activeUsers / (stats.ios.activeUsers + stats.android.activeUsers)) * 100
        };

        const newUsers = {
            ios: stats.ios.newUsersLastMonth,
            android: stats.android.newUsersLastMonth,
            total: stats.ios.newUsersLastMonth + stats.android.newUsersLastMonth,
            iosPercentage: (stats.ios.newUsersLastMonth / (stats.ios.newUsersLastMonth + stats.android.newUsersLastMonth)) * 100,
            androidPercentage: (stats.android.newUsersLastMonth / (stats.ios.newUsersLastMonth + stats.android.newUsersLastMonth)) * 100
        };

        return { totalUsers, activeUsers, newUsers };
    }
} 