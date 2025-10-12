# Marketplace Expired Label Feature 🔴

## Overview
Added a prominent red "EXPIRED" label and visual indicators for expired crop auctions in the distributor marketplace screen. This helps users quickly identify which auctions have ended.

---

## 🎨 Visual Features

### 1. **Top Right Badge**
Primary indicator in the top-right corner:
- **"AUCTION ENDED"** text with cancel icon
- **Red gradient background** (red 600 to red 800)
- **White text** with icon
- **Rounded pill shape**
- **Drop shadow** for emphasis

### 2. **Card Styling Changes**
The entire card adapts when expired:
- **Grey background** instead of orange
- **Red border** (2px) instead of orange (1.5px)
- **Red shadows** instead of orange
- **Greyed-out crop name**
- **Red status badge** with gradient

### 3. **Status Badge Enhancement**
The time/status indicator becomes more prominent:
- **Red gradient background** for expired items
- **White text** instead of green
- **Icon indicator** (event_busy)
- **Shadow effect** for depth
- Shows "EXPIRED" text from _getStatusText()

---

## 📍 Location

**File**: `lib/screens/distributor/crop_marketplace_screen.dart`

### Modified Sections:
1. **Line 268**: Added `isExpired` variable check
2. **Lines 270-307**: Updated card decoration (border, shadows, gradient)
3. **Lines 311-472**: Added Stack with expired overlay and badge
4. **Lines 479-532**: Updated status badge with red styling

---

## 🔍 Detection Logic

### Expiration Check:
```dart
final isExpired = crop.isExpired || crop.status == 'expired';
```

The feature checks two conditions:
- **crop.isExpired**: Computed property from CropModel (checks if current time > endDate)
- **crop.status == 'expired'**: Manual status from database

---

## 🎨 Color Scheme

### Red Gradient Colors:
- **Primary**: Red 600 (`#E53935`)
- **Secondary**: Red 700 (`#D32F2F`)
- **Accent**: Red 800 (`#C62828`)

### Background Colors:
- **Overlay**: Black with 60% opacity
- **Card Background**: Grey 100 to Grey 200
- **Border**: Red 300

### Shadow Colors:
- **Main Shadow**: Red with 15% opacity (12px blur)
- **Secondary Shadow**: Red with 8% opacity (6px blur)
- **Badge Shadow**: Red with 50% opacity

---

## 🎯 User Experience

### Visual Hierarchy:
1. **Most Prominent**: Top-right "AUCTION ENDED" badge
2. **Secondary**: Red status badge next to crop name
3. **Supporting**: Greyed-out crop name text
4. **Context**: Grey card background and red border

### Accessibility:
- ✅ High contrast white text on red/black backgrounds
- ✅ Multiple indicators (text + icons)
- ✅ Color + text combination (not color-only)
- ✅ Large, readable text sizes
- ✅ Clear visual separation from active auctions

---

## 🚀 Benefits

### For Distributors:
- ✅ **Instant recognition** of expired auctions
- ✅ **Prevents wasted effort** on closed auctions
- ✅ **Clear visual feedback**
- ✅ **Professional appearance**

### For the Platform:
- ✅ **Improved UX** - users don't try to bid on expired items
- ✅ **Reduced errors** - clear status indication
- ✅ **Modern design** - attractive visual treatment
- ✅ **Consistent styling** - matches app theme

---

## 📊 Visual Breakdown

### Card Structure:
```
┌─────────────────────────────────────┐
│  [🚫 AUCTION ENDED]  ← Red badge   │
│                                     │
│         [CROP IMAGE]               │
│                                     │
│                                     │
│                                     │
├─────────────────────────────────────┤ Red border
│  Grey Crop Name    [🚫 EXPIRED]   │
│                     ↑ Red badge    │
│  Quantity: XXX kg                  │
│  Min Bid: LKR XXX                  │
│  ...                               │
└─────────────────────────────────────┘
```

---

## 🎨 Before vs After

### Before (No Expired Indicator):
```
┌─────────────────────────────┐
│      [Crop Image]          │ Orange border
│  Crop Name   [ACTIVE]      │ Green badge
│  Details...                │
└─────────────────────────────┘
```

### After (With Expired Indicator):
```
┌─────────────────────────────┐
│  [🚫 AUCTION ENDED]        │ Red badge
│   [Crop Image]             │
│                            │
│────────────────────────────│ Red border
│  Grey Name  [🚫 EXPIRED]  │ Red badge
│  Details...                │
└─────────────────────────────┘
```

---

## 💻 Code Implementation

### Key Components:

#### 1. Expiration Detection:
```dart
final isExpired = crop.isExpired || crop.status == 'expired';
```

#### 2. Card Border/Shadow:
```dart
border: Border.all(
  color: isExpired ? Colors.red.shade300 : Colors.orange.shade100,
  width: isExpired ? 2 : 1.5,
),
```

#### 3. Top Right Badge:
```dart
if (isExpired)
  Positioned(
    top: 16,
    right: 16,
    child: Container(
      // "AUCTION ENDED" badge
    ),
  ),
```

---

## 🔧 Technical Details

### Performance:
- ⚡ No additional API calls
- ⚡ Uses existing crop data
- ⚡ Minimal render overhead
- ⚡ Efficient conditional rendering

### Compatibility:
- ✅ Works with existing CropModel
- ✅ Compatible with all screen sizes
- ✅ Maintains existing functionality
- ✅ No breaking changes

### Maintainability:
- ✅ Clean, readable code
- ✅ Consistent styling patterns
- ✅ Reusable color values
- ✅ Easy to modify

---

## 🧪 Testing Checklist

Test scenarios:
- ✅ Expired auction shows all indicators
- ✅ Active auction shows normal styling
- ✅ Pending auction unaffected
- ✅ Sold auction unaffected
- ✅ Image overlay displays correctly
- ✅ Top badge appears in correct position
- ✅ Status badge shows red styling
- ✅ Card border changes to red
- ✅ Crop name greys out
- ✅ Shadows change to red tint

---

## 📱 Responsive Design

### Small Screens:
- Overlay scales with image
- Text remains readable
- Badges adjust proportionally

### Large Screens:
- Full visual effect maintained
- Consistent spacing
- Proper alignment

---

## 🎯 Future Enhancements

Potential improvements:
1. Add "Archive" button for expired items
2. Filter to hide/show expired auctions
3. Add expiration countdown animation
4. Show "Expired X hours ago" timestamp
5. Different styling for "just expired" vs "long expired"
6. Add "View Results" button for expired auctions
7. Show winning bid information

---

## ✨ Summary

The expired label feature provides:
- **Multiple visual indicators** for expired auctions
- **Professional red gradient styling**
- **Clear, unmistakable messaging**
- **Enhanced user experience**
- **Consistent with modern UI/UX patterns**

### Key Features:
- 🏷️ Top-right "AUCTION ENDED" badge
- 🎨 Red gradient styling throughout
- 📛 Enhanced status badge with red gradient
- 🎯 Greyed-out card appearance
- 🔴 Red border and shadows
- 🚫 Clear expired indicators

---

**Version**: 1.0  
**Last Updated**: October 2025  
**Status**: ✅ Complete and Ready to Use  
**No Linter Errors**: ✅

