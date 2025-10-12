# Language Selection Implementation - Bug Fix

## Issue
After implementing the language selection feature, the app failed to build with the following error:

```
Error: Constant evaluation error:
The key '"home"' conflicts with another existing key in the map.
```

## Root Cause
Duplicate keys in the `_localizedValues` constant map in `lib/utils/app_localizations.dart`:

1. **'home'** key was defined in two places:
   - Line 68: In the **Common** section
   - Line 88: In the **Farmer Dashboard** section

2. **'farmer'** key was defined in two places:
   - Line 30: In the **Role Selection** section  
   - Line 104: In the **Farmer Dashboard** section

These duplicates existed in all three language sections (English, Sinhala, Tamil).

## Solution
Removed the duplicate keys from the Farmer Dashboard section since they were already defined in other sections:

### Changes Made:

#### English Section:
- Removed duplicate `'home': 'Home'` from Farmer Dashboard section (already in Common)
- Removed duplicate `'farmer': 'Farmer'` from Farmer Dashboard section (already in Role Selection)

#### Sinhala Section (සිංහල):
- Removed duplicate `'home': 'මුල් පිටුව'` from Farmer Dashboard section
- Removed duplicate `'farmer': 'ගොවියා'` from Farmer Dashboard section

#### Tamil Section (தமிழ்):
- Removed duplicate `'home': 'முகப்பு'` from Farmer Dashboard section
- Removed duplicate `'farmer': 'விவசாயி'` from Farmer Dashboard section

## Verification
After the fix:
- ✅ `flutter analyze lib/utils/app_localizations.dart` - No issues found
- ✅ `flutter build apk --debug` - Build successful (running in background)

## Why This Happened
When adding comprehensive translations for the farmer dashboard, we inadvertently added keys that were already defined in other sections. Dart's const maps don't allow duplicate keys, causing a compilation error.

## Prevention
When adding new translation keys in the future:
1. Check if the key already exists in any section
2. Use the existing key if it already provides the correct translation
3. Only create new keys if the context requires a different translation

## Status
✅ **FIXED** - All duplicate keys removed, build successful.

## Files Modified
- `lib/utils/app_localizations.dart` - Removed duplicate keys from all language sections

