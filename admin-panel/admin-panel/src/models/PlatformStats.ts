export interface PlatformStats {
    ios: {
        totalUsers: number;
        activeUsers: number;
        newUsersLastMonth: number;
    };
    android: {
        totalUsers: number;
        activeUsers: number;
        newUsersLastMonth: number;
    };
    lastUpdated: string;
}

export interface PlatformComparison {
    totalUsers: {
        ios: number;
        android: number;
        total: number;
        iosPercentage: number;
        androidPercentage: number;
    };
    activeUsers: {
        ios: number;
        android: number;
        total: number;
        iosPercentage: number;
        androidPercentage: number;
    };
    newUsers: {
        ios: number;
        android: number;
        total: number;
        iosPercentage: number;
        androidPercentage: number;
    };
} 