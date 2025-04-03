# QQQ Admin Panel

A web-based admin dashboard for managing the QQQ application. This dashboard provides analytics, user management, and system configuration capabilities.

## Features

- User Analytics
- Poll Analytics
- School Analytics
- User Management
- System Configuration

## Prerequisites

- Node.js (v14 or higher)
- npm (v6 or higher)
- Firebase project credentials

## Setup

1. Clone the repository
2. Navigate to the admin-panel directory:
   ```bash
   cd qqq/admin-panel
   ```

3. Install dependencies:
   ```bash
   npm install
   ```

4. Create a `.env` file in the root directory with your Firebase configuration:
   ```
   REACT_APP_FIREBASE_API_KEY=your_api_key
   REACT_APP_FIREBASE_AUTH_DOMAIN=your_auth_domain
   REACT_APP_FIREBASE_PROJECT_ID=your_project_id
   REACT_APP_FIREBASE_STORAGE_BUCKET=your_storage_bucket
   REACT_APP_FIREBASE_MESSAGING_SENDER_ID=your_messaging_sender_id
   REACT_APP_FIREBASE_APP_ID=your_app_id
   REACT_APP_FIREBASE_MEASUREMENT_ID=your_measurement_id
   ```

5. Start the development server:
   ```bash
   npm start
   ```

## Building for Production

To create a production build:

```bash
npm run build
```

The build files will be created in the `build` directory.

## Testing

Run the test suite:

```bash
npm test
```

## Contributing

1. Create a feature branch
2. Make your changes
3. Submit a pull request

## License

This project is proprietary and confidential. 