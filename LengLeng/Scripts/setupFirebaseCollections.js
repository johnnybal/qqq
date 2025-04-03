const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function setupCollections() {
  // Create invitations collection
  await db.collection('invitations').doc('_config').set({
    indexes: [
      {
        fields: [
          { fieldPath: 'senderId', order: 'ASCENDING' },
          { fieldPath: 'createdAt', order: 'DESCENDING' }
        ]
      },
      {
        fields: [
          { fieldPath: 'recipientPhone', order: 'ASCENDING' },
          { fieldPath: 'status', order: 'ASCENDING' }
        ]
      }
    ]
  });

  // Create users collection with invite tracking
  await db.collection('users').doc('_config').set({
    fields: {
      availableInvites: { type: 'number', defaultValue: 10 },
      totalInvitesSent: { type: 'number', defaultValue: 0 },
      totalInvitesAccepted: { type: 'number', defaultValue: 0 },
      lastInviteAward: { type: 'timestamp' },
      inviteStreak: { type: 'number', defaultValue: 0 }
    }
  });

  // Create invite tracking collection
  await db.collection('inviteTracking').doc('_config').set({
    indexes: [
      {
        fields: [
          { fieldPath: 'invitationId', order: 'ASCENDING' },
          { fieldPath: 'timestamp', order: 'DESCENDING' }
        ]
      }
    ]
  });

  console.log('Firebase collections and indexes have been set up successfully!');
}

setupCollections().catch(console.error); 