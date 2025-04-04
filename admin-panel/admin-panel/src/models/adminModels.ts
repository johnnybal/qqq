// Admin User Model
interface AdminPermission {
  resource: string;
  actions: string[];
}

interface LoginHistory {
  timestamp: Date;
  ipAddress: string;
  device: string;
}

export interface AdminUser {
  id: string;
  email: string;
  passwordHash: string;
  firstName: string;
  lastName: string;
  role: 'super_admin' | 'content_moderator' | 'support' | 'analytics';
  permissions: AdminPermission[];
  lastLogin: Date;
  loginHistory: LoginHistory[];
  accountStatus: 'active' | 'suspended' | 'inactive';
  createdAt: Date;
  createdBy: string;
  twoFactorEnabled: boolean;
}

// Content Moderation Model
interface Flag {
  reason: string;
  reportedBy: string;
  timestamp: Date;
}

interface ModerationDecision {
  action: 'no_action' | 'warning' | 'remove' | 'ban';
  decidedBy: string;
  timestamp: Date;
  notes: string;
}

interface ModerationQueueItem {
  itemId: string;
  itemType: 'poll' | 'profile' | 'message';
  content: Record<string, any>;
  flags: Flag[];
  status: 'pending' | 'reviewed' | 'approved' | 'removed';
  priority: number;
  assignedTo: string;
  decision?: ModerationDecision;
}

interface AutomatedFilter {
  id: string;
  type: 'keyword' | 'pattern' | 'ml_model';
  settings: Record<string, any>;
  severity: 'block' | 'flag' | 'notify';
  createdAt: Date;
  lastUpdated: Date;
  effectiveness: {
    truePositives: number;
    falsePositives: number;
  };
}

export interface ModerationModel {
  queue: ModerationQueueItem[];
  automatedFilters: AutomatedFilter[];
}

// Analytics Dashboard Model
interface ActiveUsers {
  daily: number;
  weekly: number;
  monthly: number;
}

interface RetentionRates {
  day1: number;
  day7: number;
  day30: number;
}

interface PollEngagement {
  totalPolls: number;
  averagePerUser: number;
  completionRate: number;
}

interface InviteConversion {
  sentInvites: number;
  acceptedInvites: number;
  conversionRate: number;
}

interface UserSegment {
  segmentName: string;
  userCount: number;
  criteria: Record<string, any>;
  metrics: Record<string, any>;
}

interface SchoolPerformance {
  schoolId: string;
  schoolName: string;
  userCount: number;
  activeUsers: number;
  pollsPerDay: number;
  retentionRate: number;
  growthRate: number;
}

interface RevenueMetrics {
  totalRevenue: number;
  premiumSubscribers: number;
  conversionRate: number;
  averageRevenuePerUser: number;
  subscriptionRetention: number;
}

interface ReportPeriod {
  startDate: Date;
  endDate: Date;
  comparisonPeriod: 'previous_period' | 'same_period_last_year';
}

export interface AnalyticsModel {
  overview: {
    activeUsers: ActiveUsers;
    newUserSignups: ActiveUsers;
    retentionRates: RetentionRates;
    pollEngagement: PollEngagement;
    inviteConversion: InviteConversion;
  };
  userSegments: UserSegment[];
  schoolPerformance: SchoolPerformance[];
  revenueMetrics: RevenueMetrics;
  reportPeriod: ReportPeriod;
}

// School Management Model
interface Location {
  address: string;
  city: string;
  postalCode: string;
  country: string;
  coordinates: {
    latitude: number;
    longitude: number;
  };
}

interface ContactInfo {
  adminName: string;
  email: string;
  phone: string;
}

interface SchoolStats {
  totalStudents: number;
  registeredUsers: number;
  penetrationRate: number;
  dailyActiveUsers: number;
  weeklyActiveUsers: number;
}

interface SeedingProgress {
  targetUsers: number;
  currentSeedUsers: number;
  completionPercentage: number;
}

export interface School {
  id: string;
  name: string;
  location: Location;
  status: 'active' | 'pending' | 'paused' | 'blacklisted';
  deploymentPhase: 'seeding' | 'early_access' | 'full_rollout';
  contactInfo: ContactInfo;
  stats: SchoolStats;
  seedingProgress: SeedingProgress;
  tags: string[];
  notes: string;
  addedAt: Date;
  lastUpdated: Date;
}

export interface SchoolManagementModel {
  schools: School[];
}

// Poll Management Model
interface AgeAppropriate {
  min: number;
  max: number;
}

interface PollEngagementMetrics {
  impressions: number;
  responses: number;
  responseRate: number;
  flaggedCount: number;
}

interface PollSchedule {
  startDate: Date;
  endDate: Date;
  frequency: 'daily' | 'weekly' | 'special_event';
  timeOfDay: string;
}

export interface Poll {
  id: string;
  question: string;
  emoji: string;
  category: 'compliment' | 'relationship' | 'talent' | 'personality';
  status: 'active' | 'draft' | 'archived' | 'scheduled';
  ageAppropriate: AgeAppropriate;
  genderTarget: 'all' | 'male' | 'female' | 'non_binary';
  engagement: PollEngagementMetrics;
  schedule: PollSchedule;
  createdBy: string;
  createdAt: Date;
  lastModified: Date;
}

interface PollCategory {
  id: string;
  name: string;
  description: string;
  pollCount: number;
  activePollCount: number;
}

interface UpcomingPoll {
  pollId: string;
  scheduledDate: Date;
  estimatedReach: number;
}

interface SpecialEvent {
  eventName: string;
  eventDate: Date;
  associatedPolls: string[];
}

export interface PollManagementModel {
  pollLibrary: Poll[];
  pollCategories: PollCategory[];
  pollSchedule: {
    upcomingPolls: UpcomingPoll[];
    specialEvents: SpecialEvent[];
  };
}

// User Management Model
interface UserFilters {
  ageRange: {
    min: number;
    max: number;
  };
  gender: string;
  school: string;
  registrationDate: {
    start: Date;
    end: Date;
  };
  activityLevel: 'high' | 'medium' | 'low' | 'inactive';
  accountStatus: 'active' | 'suspended' | 'deleted';
  premiumStatus: boolean;
}

interface FlagHistory {
  reason: string;
  date: Date;
  resolution: string;
}

interface SupportInteraction {
  ticketId: string;
  date: Date;
  type: string;
  status: string;
  notes: string;
}

interface UserSchool {
  id: string;
  name: string;
}

export interface User {
  id: string;
  displayName: string;
  username: string;
  phoneNumber: string;
  school: UserSchool;
  accountStatus: string;
  registrationDate: Date;
  lastActive: Date;
  flagHistory: FlagHistory[];
  supportInteractions: SupportInteraction[];
}

export interface UserManagementModel {
  userSearch: {
    filters: UserFilters;
    sortBy: string;
    sortDirection: string;
    pageSize: number;
    currentPage: number;
  };
  users: User[];
} 