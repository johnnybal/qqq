# QQQ Admin Panel

A web-based admin dashboard for managing the QQQ application. This dashboard provides analytics, user management, and system configuration capabilities.

## Prerequisites

Before building the admin panel, ensure you have the following installed:

- Node.js (v14 or higher)
- npm (v6 or higher)
- Firebase project credentials
- Git

## Setup

1. Clone the repository:
   ```bash
   git clone [repository-url]
   cd qqq/admin-panel
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

## Features

- **User Analytics**
  - User growth metrics
  - Engagement statistics
  - User behavior analysis

- **Poll Analytics**
  - Poll creation trends
  - Voting patterns
  - Popular poll categories

- **School Analytics**
  - School participation metrics
  - Regional engagement data
  - School-specific insights

- **User Management**
  - User account management
  - Role-based access control
  - User activity monitoring

- **System Configuration**
  - Feature toggles
  - System settings
  - Maintenance mode control

## Architecture

The admin panel follows a modern React architecture with the following structure:
- `src/`
  - `components/`: Reusable UI components
  - `pages/`: Main application pages
  - `services/`: API and Firebase services
  - `hooks/`: Custom React hooks
  - `utils/`: Utility functions
  - `context/`: React context providers
  - `types/`: TypeScript type definitions

## Testing

### Running Tests

1. Run all tests:
   ```bash
   npm test
   ```

2. Run tests in watch mode:
   ```bash
   npm test -- --watch
   ```

3. Generate test coverage report:
   ```bash
   npm test -- --coverage
   ```

### Testing Guidelines

- Write tests for all new features
- Maintain test coverage above 80%
- Use React Testing Library for component tests
- Mock Firebase services in tests

## Troubleshooting

### Common Issues

1. **Firebase Authentication Issues**
   - Verify Firebase configuration in `.env`
   - Check Firebase project settings
   - Ensure proper Firebase rules are set

2. **Build Failures**
   - Clear npm cache: `npm cache clean --force`
   - Delete node_modules and reinstall
   - Check for version conflicts in package.json

3. **Development Server Issues**
   - Check if port 3000 is available
   - Verify Node.js version compatibility
   - Check for syntax errors in code

### Getting Help

If you encounter issues not covered here:
1. Check the browser console for errors
2. Review the Firebase console logs
3. Contact the development team

## Contributing

1. Fork the repository
2. Create your feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. Commit your changes:
   ```bash
   git commit -m 'Add some feature'
   ```
4. Push to the branch:
   ```bash
   git push origin feature/your-feature-name
   ```
5. Create a Pull Request

## Additional Resources

- [React Documentation](https://reactjs.org/docs/getting-started.html)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Material-UI Documentation](https://mui.com/getting-started/installation/)
- [TypeScript Documentation](https://www.typescriptlang.org/docs/)

## License

This project is proprietary and confidential. Unauthorized copying, modification, distribution, or use of this software is strictly prohibited. 