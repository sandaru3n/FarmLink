# FarmLink Dashboard Structure

## Overview
The FarmLink app now has separate dashboard folders for each role (Farmer, Consumer, Food Distributor, Transporter) with dedicated settings screens and role switching functionality.

## Directory Structure

```
lib/screens/dashboards/
├── main_dashboard.dart (Legacy - now routes to role-specific dashboards)
├── dashboard_router.dart (New - handles routing to appropriate dashboard)
├── farmer/
│   └── farmer_dashboard.dart
├── consumer/
│   └── consumer_dashboard.dart
├── fooddistributor/
│   └── fooddistributor_dashboard.dart
└── transporter/
    └── transporter_dashboard.dart

lib/screens/settings/
├── settings_screen.dart (Legacy - generic settings)
├── farmer_settings_screen.dart
├── consumer_settings_screen.dart
├── fooddistributor_settings_screen.dart
└── transporter_settings_screen.dart

lib/services/
└── role_switching_service.dart (New - handles role switching logic)
```

## Features

### 1. Role-Specific Dashboards

Each role has its own dedicated dashboard with:
- **Farmer Dashboard**: Green theme, crop management, product listing
- **Consumer Dashboard**: Blue theme, product browsing, order tracking
- **Food Distributor Dashboard**: Orange theme, inventory management, supplier network
- **Transporter Dashboard**: Purple theme, delivery management, route planning

### 2. Role-Specific Settings

Each role has its own settings screen with:
- Role-specific profile information
- Role-specific settings and configurations
- Role switching functionality
- Common settings (language, notifications, etc.)

### 3. Role Switching

Users can switch between roles if they have multiple roles:
- Seamless navigation between different dashboards
- Role-specific UI themes and colors
- Preserved user data across roles
- Visual indicators for available role switches

### 4. Dashboard Router

The `DashboardRouter` automatically routes users to the appropriate dashboard based on their current active role.

## Implementation Details

### Dashboard Navigation
- Each dashboard has role-specific bottom navigation
- Role-specific quick actions and statistics
- Consistent UI patterns across all dashboards

### Settings Integration
- Each settings screen includes role management section
- Role switching with confirmation dialogs
- Role-specific configuration options

### Color Themes
- **Farmer**: Green (#4CB050)
- **Consumer**: Blue (#2196F3)
- **Food Distributor**: Orange (#FF9800)
- **Transporter**: Purple (#9C27B0)

## Usage

### For Developers
1. Use `DashboardRouter` for main navigation
2. Use `RoleSwitchingService` for role switching logic
3. Each role dashboard is self-contained with its own navigation

### For Users
1. Login with their account
2. Automatically routed to their primary role dashboard
3. Access settings to switch roles if they have multiple roles
4. Each role provides different functionality and features

## Future Enhancements
- Role-specific notifications
- Role-specific analytics
- Cross-role data sharing
- Role-specific onboarding flows
