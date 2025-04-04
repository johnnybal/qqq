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
    lastUpdated: Date;
}

export interface PlatformComparison {
    totalUsers: {
        ios: number;
        android: number;
        total: number;
    };
    activeUsers: {
        ios: number;
        android: number;
        total: number;
    };
    newUsers: {
        ios: number;
        android: number;
        total: number;
    };
    iosPercentage: number;
    androidPercentage: number;
} 