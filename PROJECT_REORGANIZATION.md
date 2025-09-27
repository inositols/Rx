# 🏗️ Project Reorganization Plan

## 📁 **Current Structure Issues:**
- Mixed feature files in `/views` folder
- Scattered bloc files in individual folders  
- No consistent feature organization

## 🎯 **Target Structure (Following `lib/auth/` pattern):**

```
lib/
├── auth/                     ✅ Already organized
│   ├── bloc/
│   ├── models/
│   ├── view/
│   └── widget/
├── question/                 🔄 Partially organized
│   ├── bloc/                 ✅ Created
│   ├── view/                 ✅ Created (moved question_management_view.dart)
│   ├── widget/              ✅ Created
│   └── models/              📝 TO CREATE
├── quiz/                    🔄 Partially organized  
│   ├── bloc/                ✅ Created
│   ├── view/                ✅ Created (moved quiz_upload_view.dart, quiz_view.dart)
│   ├── widget/              ✅ Created
│   └── models/              📝 TO CREATE
├── test/                    📝 TO CREATE
│   ├── bloc/
│   ├── view/                (test_list, test_history, test_result, test_taking)
│   ├── widget/
│   └── models/
├── dashboard/               📝 TO CREATE
│   ├── view/                (cbt_dashboard_view.dart, admin_tools_view.dart)
│   └── widget/
├── core/                    📝 TO CREATE
│   ├── utils/               (responsive_utils, admin_setup, debug_auth)
│   ├── data/                (question_json.dart)
│   └── widgets/             (shared widgets)
└── shared/                  📝 TO CREATE
    ├── view/                (splash_view.dart, auth_selector_view.dart)
    └── widget/
```

## ✅ **Completed:**
1. Created question/bloc, question/view, question/widget folders
2. Created quiz/bloc, quiz/view, quiz/widget folders  
3. Moved question bloc files to proper location
4. Moved quiz bloc files to proper location
5. Moved question_management_view.dart to question/view/
6. Moved quiz_upload_view.dart and quiz_view.dart to quiz/view/

## 📝 **Next Steps:**
1. Create remaining folder structure
2. Move test-related views to test/view/
3. Move dashboard views to dashboard/view/
4. Move shared views to shared/view/
5. Reorganize utils folder
6. Update all import statements
7. Create barrel files (index.dart) for each feature

## 🔧 **Import Updates Required:**
After reorganization, update imports in:
- main.dart
- All view files
- All bloc files
- Any files importing moved components

## 💡 **Benefits:**
- ✅ Feature-based organization
- ✅ Easier navigation and maintenance
- ✅ Clear separation of concerns
- ✅ Consistent with auth/ folder pattern
- ✅ Scalable architecture
