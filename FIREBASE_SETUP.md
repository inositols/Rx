# Firebase Setup Guide

## 🔥 **Enable Anonymous Authentication**

To fix the `admin-restricted-operation` error for student login, you need to enable anonymous authentication in Firebase:

### **Step 1: Firebase Console**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Click **Authentication** in the left sidebar
4. Go to **Sign-in method** tab
5. Find **Anonymous** in the provider list
6. Click on it and **Enable** it
7. Click **Save**

### **Step 2: Verify Setup**
After enabling anonymous auth:
- Students can now login with just registration numbers
- The system will use anonymous authentication for students
- Admin users still use email/password authentication

## 🔧 **Alternative: Disable Anonymous Auth Requirement**

If you prefer not to use anonymous auth, you can modify the student login to work without Firebase Auth entirely by using the Mock User approach (currently commented out in the code).

## 📋 **Current Authentication Flow:**

| User Type | Method | Firebase Auth Required |
|-----------|--------|----------------------|
| **Admin** | Email + Password | ✅ Yes |
| **Student** | Registration Number Only | ✅ Anonymous Auth |

## 🚨 **Important:**
Make sure to enable anonymous authentication in Firebase Console, otherwise student login will fail with the `admin-restricted-operation` error you encountered.

## ✅ **Testing:**
After enabling anonymous auth:
1. Try student login with: `2023/123456`
2. Should work without errors
3. Check Firebase Console → Authentication → Users to see anonymous users created

