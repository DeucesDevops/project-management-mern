// MongoDB initialization script
// Runs once when the container is first created (only if the data volume is empty)

const dbName = process.env.MONGO_INITDB_DATABASE || 'project_management';
const rootUser = process.env.MONGO_INITDB_ROOT_USERNAME || 'admin';
const rootPassword = process.env.MONGO_INITDB_ROOT_PASSWORD || 'changeme';

// Authenticate as root then create a least-privilege app user
db.auth(rootUser, rootPassword);

db = db.getSiblingDB(dbName);

db.createUser({
    user: 'appuser',
    pwd: rootPassword,
    roles: [{ role: 'readWrite', db: dbName }],
});

// Create indexes for common query patterns
db.users.createIndex({ email: 1 }, { unique: true });
db.projects.createIndex({ owner: 1 });
db.projects.createIndex({ members: 1 });
db.tasks.createIndex({ project: 1 });
db.tasks.createIndex({ assignee: 1 });

print('MongoDB initialization complete for database: ' + dbName);
