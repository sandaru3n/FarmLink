# Flexible Role Switching System

## Overview

The FarmLink app now features a flexible role switching system that allows users to switch between specific roles based on predefined business rules. The system is designed around the Consumer role being the target role for other roles.

## Role Switching Rules

The system implements the following role switching rules:

### **Farmer** → Can switch to:
- **Consumer** only

### **Consumer** → Can switch to:
- **No other roles** (Consumer role cannot be switched)

### **Food Distributor** → Can switch to:
- **Consumer** only

### **Transporter** → Can switch to:
- **Consumer** only

## Business Logic

### **Consumer-Centric Design**
The system is designed around the Consumer role being the primary target:
- **Non-Consumer roles** (Farmer, Distributor, Transporter) can switch to Consumer
- **Consumer role** cannot switch to any other role
- This reflects the real-world scenario where other roles might need to act as consumers

### **Role Restrictions**
- **Farmer**: Limited to Consumer (for purchasing needs)
- **Food Distributor**: Limited to Consumer (for personal shopping)
- **Transporter**: Limited to Consumer (for personal needs)
- **Consumer**: Cannot switch to other roles (primary consumer role)

## How It Works

### 1. **Access Role Switching**
- Navigate to any role-specific settings screen
- **Non-Consumer roles**: Find the **"Role Management"** section with **"Switch Role"** button
- **Consumer role**: No role management section is displayed

### 2. **Role Selection Dialog**
When you tap "Switch Role", a dialog appears showing:
- Your current role
- Available roles you can switch to (only Consumer for non-Consumer roles)
- Each role option with its icon and color

### 3. **Role Switching Process**
- Select the desired role from the dialog
- System validates the switch is allowed
- If valid, switches to the new role
- Navigates to the appropriate dashboard or settings screen
- Shows success message with role-specific color

## User Experience

### **For Non-Consumer Roles (Farmer, Distributor, Transporter)**
- **Role Management Section**: Visible in settings
- **Switch Role Option**: Available with "Switch to: Consumer" description
- **Role Switching**: Can switch to Consumer role
- **Visual Feedback**: Loading indicators and success messages

### **For Consumer Role**
- **Role Management Section**: Hidden (no available roles to switch to)
- **Switch Role Option**: Not available
- **Role Switching**: Cannot switch to other roles
- **Message**: "Consumer role cannot be switched" if attempted

## Implementation Details

### **FlexibleRoleSwitchingService**
Located at: `lib/services/flexible_role_switching_service.dart`

Key methods:
- `getRoleSwitchingRules()` - Defines the switching rules (Consumer has empty array)
- `getAvailableRolesToSwitch(currentRole)` - Gets available roles for current role
- `canSwitchToRole(currentRole, targetRole)` - Validates if switch is allowed
- `showRoleSwitchingDialog(context)` - Shows the role selection dialog
- `switchToRole(context, targetRole)` - Performs the role switch

### **Role-Specific Settings Screens**
All role-specific settings screens now use the flexible switching system:
- `FarmerSettingsScreen` - Can switch to Consumer
- `ConsumerSettingsScreen` - No role switching available
- `FoodDistributorSettingsScreen` - Can switch to Consumer
- `TransporterSettingsScreen` - Can switch to Consumer

## Visual Feedback

### **For Non-Consumer Roles**
- **Role-specific colors** for each role option
- **Clear descriptions** of available roles ("Switch to: Consumer")
- **Success messages** with appropriate colors
- **Error handling** for invalid switches

### **For Consumer Role**
- **No role management section** in settings
- **Clean interface** without switching options
- **Clear messaging** if switching is attempted

## Benefits

1. **Clear Business Logic**: Consumer role is the primary target for switching
2. **Simplified User Experience**: Consumer users don't see unnecessary options
3. **Role-Specific Design**: Each role has appropriate switching capabilities
4. **Scalability**: Easy to modify switching rules
5. **Validation**: Prevents invalid role switches

## Future Enhancements

The system can be easily extended to:
- Add more role switching rules
- Implement role-specific permissions
- Add role switching history
- Include role switching analytics
- Add role switching notifications

## Usage Example

```dart
// Show role switching dialog (only for non-Consumer roles)
FlexibleRoleSwitchingService.showRoleSwitchingDialog(context);

// Check if role switch is allowed
bool canSwitch = FlexibleRoleSwitchingService.canSwitchToRole(
  UserRole.farmer, 
  UserRole.consumer
); // Returns true

bool canSwitchConsumer = FlexibleRoleSwitchingService.canSwitchToRole(
  UserRole.consumer, 
  UserRole.farmer
); // Returns false

// Get available roles for current role
List<UserRole> availableRoles = FlexibleRoleSwitchingService
  .getAvailableRolesToSwitch(UserRole.farmer); // Returns [UserRole.consumer]

List<UserRole> consumerRoles = FlexibleRoleSwitchingService
  .getAvailableRolesToSwitch(UserRole.consumer); // Returns []
```
