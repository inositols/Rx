# Authentication System Guide

## Overview

The Computer-Based Test (CBT) system has been refined to support two distinct user types:

1. **Admin/Class Representatives** - Manage student accounts via web interface
2. **Students** - Access tests via mobile using registration number only

## Admin Authentication (Web)

### Features
- Email and password authentication
- CSV file upload for bulk student creation
- University and level configuration
- Student account management

### CSV Format Requirements
The CSV file should contain student data in the following format:
- **Column 1**: S/N (Serial Number)
- **Column 2**: Full Name 
- **Column 3**: Registration Number (Format: YYYY/NNNNNN)
- **No header row**

Example CSV content:
```
1,John Doe,2023/123456
2,Jane Smith,2023/123457
3,Michael Johnson,2023/123458
```

### Usage Flow
1. Admin navigates to Admin Portal
2. Login with authorized email and password
3. Switch to "Upload Students" tab
4. Select CSV file containing student data
5. Enter level (100, 200, 300, 400, 500, Postgraduate)
6. Enter university name
7. Click "Upload Students" to create accounts

## Student Authentication (Mobile)

### Features
- Registration number only login (no password required)
- Automatic validation of registration format
- Direct access to assigned tests

### Usage Flow
1. Student opens the mobile app
2. Select "Student Login"
3. Enter registration number (YYYY/NNNNNN format)
4. Click "Access Tests" to login

## Technical Implementation

### Collections in Firestore

#### admins
- Document ID: admin email
- Contains admin authorization data

#### students  
- Document ID: normalized registration number (underscores instead of slashes)
- Fields:
  - `serialNumber`: Serial number from CSV
  - `name`: Full name from CSV
  - `regNo`: Original registration number
  - `regNoNormalized`: Normalized for querying
  - `level`: Student level
  - `university`: University name
  - `year`: Extracted year from registration number
  - `number`: Extracted number from registration number
  - `createdAt`: Timestamp
  - `isActive`: Boolean flag

#### users (legacy)
- Maintains backward compatibility with existing system

### Authentication States
- `AuthAuthenticated` - User successfully authenticated
  - `isAdmin`: Boolean flag indicating admin status
  - `userData`: User/student data from Firestore
- `BulkStudentCreationSuccess` - Bulk upload completed
  - `createdCount`: Number of students created
  - `errors`: List of errors encountered

### Key Features
- **Admin Verification**: Only authorized emails can access admin functions
- **Bulk Processing**: Efficient CSV parsing with error handling
- **Registration Validation**: Automatic format validation (YYYY/NNNNNN)
- **Responsive Design**: Works on web, mobile, and tablet
- **Error Handling**: Detailed error messages for failed operations

## Security Considerations
- Admin emails must be pre-registered in the `admins` collection
- Students cannot access admin functions
- Registration numbers are validated before account creation
- Duplicate registration numbers are prevented

## Setup Requirements
1. Add admin emails to Firestore `admins` collection
2. Ensure Firebase Auth is configured
3. Enable anonymous authentication for students (if needed)
4. Install required dependencies: `file_picker`, `csv`

