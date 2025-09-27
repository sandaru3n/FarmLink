# 🔧 API Key Troubleshooting Guide

## Current Error:
```
Invalid API key. Please check your OpenWeatherMap API key.
```

## Common Causes & Solutions:

### 1. 🔑 **API Key Not Activated Yet**
**Problem**: New API keys take 2-10 minutes to activate
**Solution**: Wait 10 minutes and try again

### 2. 📧 **Email Not Verified**
**Problem**: Account email not verified
**Solution**: 
1. Check your email for verification link
2. Click the verification link
3. Try the API again

### 3. 🚫 **Wrong API Key Format**
**Problem**: API key has extra spaces or wrong format
**Solution**: 
- Remove any spaces before/after the key
- Make sure it's exactly 32 characters
- Example: `055eec6551429b959c978fd76171ecad`

### 4. 🌐 **Wrong Service**
**Problem**: Using API key from different weather service
**Solution**: Make sure you're using OpenWeatherMap API key

### 5. ⏰ **API Key Expired/Disabled**
**Problem**: API key was disabled or expired
**Solution**: Generate a new API key

## 🔍 **Debug Steps:**

### Step 1: Check Your Account
1. Go to https://openweathermap.org/api
2. Login to your account
3. Go to "API keys" section
4. Make sure your key is **active** (not disabled)
5. Check if it shows "Active" status

### Step 2: Test API Key Manually
Open your browser and test this URL:
```
https://api.openweathermap.org/data/2.5/weather?q=Delhi,IN&appid=055eec6551429b959c978fd76171ecad&units=metric
```

**Expected Result**: Should return weather data in JSON format
**If Error**: Your API key is invalid

### Step 3: Generate New API Key
If the above doesn't work:
1. Go to OpenWeatherMap account
2. Delete the current API key
3. Generate a new one
4. Wait 5-10 minutes for activation
5. Update the code with the new key

### Step 4: Check Debug Output
Run the app and check the console output:
- Look for "Weather API URL: ..."
- Look for "Response status: ..."
- Look for "Response body: ..."

## 🚀 **Quick Fix:**

1. **Wait 10 minutes** (API key activation time)
2. **Verify your email** if you haven't already
3. **Check account status** on OpenWeatherMap
4. **Try a different city** like "London,UK" to test
5. **Generate a new API key** if needed

## 📞 **Still Not Working?**

If none of the above works:
1. Create a completely new OpenWeatherMap account
2. Use a different email address
3. Generate a fresh API key
4. Wait 10 minutes for activation
5. Update the code with the new key

## ✅ **Success Indicators:**
- Console shows "Response status: 200"
- Weather data appears in the app
- No error messages
- Real temperature and weather conditions displayed
