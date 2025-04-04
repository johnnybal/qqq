# QQQ Admin Panel

A web-based admin dashboard for managing the QQQ application. This dashboard provides analytics, user management, and system configuration capabilities.

## Prerequisites

Before building the admin panel, ensure you have the following installed:

- Node.js (v18 or higher)
- npm (v9 or higher)
- Firebase project credentials
- Git

## Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/johnnybal/qqq.git
   cd qqq/admin-panel/admin-panel
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Configure environment variables:
   Create a `.env` file in the root directory with your Firebase configuration:
   ```
   REACT_APP_FIREBASE_API_KEY=your_api_key
   REACT_APP_FIREBASE_AUTH_DOMAIN=your_auth_domain
   REACT_APP_FIREBASE_PROJECT_ID=your_project_id
   REACT_APP_FIREBASE_STORAGE_BUCKET=your_storage_bucket
   REACT_APP_FIREBASE_MESSAGING_SENDER_ID=your_messaging_sender_id
   REACT_APP_FIREBASE_APP_ID=your_app_id
   REACT_APP_FIREBASE_MEASUREMENT_ID=your_measurement_id
   ```

4. Start the development server:
   ```bash
   npm start
   ```

## Building the Admin Panel

The project supports different environments for building. The available options are:

### Environments
- `development`: For local development and testing
- `staging`: For testing in a staging environment
- `production`: For production deployment

### Build Commands

1. Development build:
   ```bash
   npm start
   ```

2. Staging build:
   ```bash
   npm run build:staging
   ```

3. Production build:
   ```bash
   npm run build
   ```

### Build Outputs

- Development builds run on `http://localhost:3000`
- Staging and production builds create files in the `build` directory

## Features

### User Management
- View and manage user profiles
- Monitor user activity
- Handle user reports
- Manage user permissions

### Analytics
- View usage statistics
- Monitor poll participation
- Track user engagement
- Generate reports

### System Configuration
- Manage app settings
- Configure notification templates
- Update content moderation rules
- Set up maintenance windows

### Security
- Role-based access control
- Audit logging
- Security monitoring
- Vulnerability management

## Dependencies

- React 18.x
- Material-UI 5.x
- Firebase SDK 10.x
- React Router 6.x
- Axios
- Chart.js
- Date-fns

## Deployment

### Firebase Hosting

1. Install Firebase CLI if not already installed:
   ```bash
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Deploy to Firebase:
   ```bash
   firebase deploy
   ```

### Environment-Specific Deployment

1. Staging deployment:
   ```bash
   firebase deploy --project staging-project-id
   ```

2. Production deployment:
   ```bash
   firebase deploy --project production-project-id
   ```

## Security

The admin panel implements several security measures:

1. Authentication:
   - Firebase Authentication
   - Role-based access control
   - Session management

2. Data Protection:
   - Environment variable encryption
   - Secure API endpoints
   - Input validation

3. Monitoring:
   - Activity logging
   - Error tracking
   - Security alerts

## Troubleshooting

### Common Issues

1. **Build Fails**
   - Check Node.js version
   - Clear npm cache: `npm cache clean --force`
   - Delete node_modules and reinstall

2. **Firebase Connection Issues**
   - Verify Firebase credentials
   - Check network connectivity
   - Ensure Firebase project is active

3. **Authentication Problems**
   - Verify user permissions
   - Check Firebase Authentication settings
   - Clear browser cache

### Getting Help

If you encounter any issues not covered here:
1. Check the browser console
2. Review Firebase logs
3. Contact the development team

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details. 