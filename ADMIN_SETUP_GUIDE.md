# Admin Setup Guide

## 🔧 How to Create Admins

### Method 1: Firebase Console (Easiest)

1. **Open Firebase Console:**
   - Go to [console.firebase.google.com](https://console.firebase.google.com)
   - Select your project

2. **Navigate to Firestore:**
   - Click "Firestore Database" → "Data"

3. **Create `admins` collection:**
   - Click "Start collection"
   - Collection ID: `admins`

4. **Add admin document:**
   - Document ID: `admin@university.edu` (use admin's email)
   - Add these fields:
     ```
     email: "admin@university.edu" (string)
     name: "John Doe" (string)
     role: "class_rep" (string)
     isActive: true (boolean)
     createdAt: [current timestamp]
     ```

5. **Create Firebase Auth user:**
   - Go to Authentication → Users
   - Click "Add user"
   - Email: `admin@university.edu`
   - Password: Create a secure password

### Method 2: Using the Script (Programmatic)

1. **Run the admin creation script:**
   ```bash
   dart run scripts/create_admin.dart
   ```

2. **The script creates these default admins:**
   - `classrep@pharmacy.unn.edu.ng` / `ClassRep2024!`
   - `admin@pharmacy.unn.edu.ng` / `Admin2024!`
   - `lecturer@pharmacy.unn.edu.ng` / `Lecturer2024!`

### Method 3: Manual Code Integration

Add this to your app (temporary):

```dart
// In main.dart or a setup screen
import 'lib/utils/admin_setup.dart';

// Create admin
await AdminSetup.createAdmin(
  email: 'your-admin@email.com',
  password: 'SecurePassword123!',
  name: 'Admin Name',
  role: 'class_rep',
);
```

## 📋 **Default Admin Accounts Created:**

| Email | Password | Role |
|-------|----------|------|
| `classrep@pharmacy.unn.edu.ng` | `ClassRep2024!` | class_rep |
| `admin@pharmacy.unn.edu.ng` | `Admin2024!` | admin |
| `lecturer@pharmacy.unn.edu.ng` | `Lecturer2024!` | lecturer |

## 🛡️ **Security Notes:**

1. **Change default passwords** immediately after first login
2. **Use strong passwords** (8+ characters, mixed case, numbers, symbols)
3. **Use institutional email addresses** for admins
4. **Limit admin access** to trusted class representatives only

## ✅ **Verification Steps:**

1. **Test admin login:**
   - Go to Admin Portal
   - Use admin email/password
   - Should successfully authenticate

2. **Test CSV upload:**
   - Upload the sample CSV file
   - Check if students are created in Firestore

3. **Test student access:**
   - Use a registration number from uploaded students
   - Should successfully authenticate via Student Login

## 🔧 **Admin Management:**

### List all admins:
```dart
await AdminSetup.listAdmins();
```

### Deactivate admin:
```dart
await AdminSetup.deactivateAdmin('admin@email.com');
```

### Add existing user as admin:
```dart
await AdminSetup.addExistingUserAsAdmin(
  email: 'existing@email.com',
  name: 'User Name',
);
```

## 🚨 **Troubleshooting:**

- **"Unauthorized" error:** Admin email not in `admins` collection
- **"User not found":** Admin doesn't have Firebase Auth account
- **"Permission denied":** Check Firestore security rules

Remember to secure your admin credentials and only share them with authorized personnel!

