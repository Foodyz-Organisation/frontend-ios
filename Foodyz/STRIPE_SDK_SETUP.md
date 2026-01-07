# 🔧 Stripe iOS SDK Setup Guide

## ⚠️ **CRITICAL: Why Stripe SDK is Required**

**DO NOT send raw card details to your backend!** Stripe will block this and return 400/500 errors.

**✅ CORRECT Flow:**
1. User enters card details in iOS app
2. iOS app uses Stripe SDK to create PaymentMethod (client-side)
3. Stripe returns `paymentMethodId` (e.g., "pm_1ABC123xyz")
4. iOS app sends **ONLY** `paymentMethodId` to your backend
5. Backend confirms payment with Stripe

**❌ WRONG Flow:**
- Sending `cardNumber`, `expiryMonth`, `expiryYear`, `cvv` to backend
- Backend trying to create PaymentMethod server-side with raw card details

---

## 📦 **Step 1: Add Stripe iOS SDK**

### **Using Swift Package Manager (Recommended):**

1. Open your project in Xcode
2. Go to **File → Add Packages...**
3. Enter this URL:
   ```
   https://github.com/stripe/stripe-ios
   ```
4. Select version: **Latest (23.x.x or newer)**
5. Click **Add Package**
6. Select your target (Foodyz) and click **Add Package**

### **Using CocoaPods (Alternative):**

Add to your `Podfile`:
```ruby
pod 'Stripe'
```

Then run:
```bash
pod install
```

---

## 🔑 **Step 2: Get Your Stripe Publishable Key**

1. Go to: https://dashboard.stripe.com/apikeys
2. Copy your **Publishable key** (starts with `pk_test_...` for testing)
3. **DO NOT use Secret key** - that's for backend only!

---

## ⚙️ **Step 3: Configure Stripe in Your App**

### **Option A: In StripeCardPaymentView.swift (Current Implementation)**

The code already has a placeholder. Just replace:

```swift
STPAPIClient.shared.publishableKey = "pk_test_YOUR_PUBLISHABLE_KEY_HERE"
```

With your actual key:

```swift
STPAPIClient.shared.publishableKey = "pk_test_51ABC123..." // Your actual key
```

### **Option B: Create StripeConfig.swift (Recommended for Production)**

Create a new file: `Core/StripeConfig.swift`

```swift
import Foundation

struct StripeConfig {
    // Test key (for development)
    static let publishableKey = "pk_test_YOUR_TEST_KEY_HERE"
    
    // Production key (for App Store)
    // static let publishableKey = "pk_live_YOUR_LIVE_KEY_HERE"
}
```

Then in `StripeCardPaymentView.swift`:

```swift
STPAPIClient.shared.publishableKey = StripeConfig.publishableKey
```

---

## ✅ **Step 4: Add Import Statement**

At the top of `StripeCardPaymentView.swift`, add:

```swift
import SwiftUI
import Stripe  // Add this line
```

The code already uses `#if canImport(Stripe)` which will work once the package is added.

---

## 🧪 **Step 5: Test with Test Cards**

Use these Stripe test cards:

| Card Number | Expiry | CVV | Description |
|------------|--------|-----|-------------|
| `4242 4242 4242 4242` | Any future date | Any 3 digits | Success |
| `4000 0000 0000 0002` | Any future date | Any 3 digits | Declined |
| `4000 0025 0000 3155` | Any future date | Any 3 digits | Requires 3D Secure |

---

## 🔍 **Step 6: Verify It Works**

1. Build and run your app
2. Go through payment flow
3. Enter test card: `4242 4242 4242 4242`
4. Check console logs:
   - Should see: `💳 Creating PaymentMethod using Stripe SDK (client-side)...`
   - Should see: `✅ PaymentMethod created successfully: pm_xxx`
   - Should see: `📤 Sending paymentMethodId to backend (NOT card details!)`
5. Payment should succeed!

---

## ⚠️ **Common Issues**

### **Issue: "No such module 'Stripe'"**

**Solution:** 
- Make sure you added the package correctly
- Clean build folder: **Product → Clean Build Folder**
- Rebuild: **Product → Build**

### **Issue: "Invalid API Key"**

**Solution:**
- Make sure you're using **Publishable key** (starts with `pk_`)
- NOT Secret key (starts with `sk_`)
- Make sure key is for correct environment (test vs live)

### **Issue: Still getting 400/500 errors**

**Solution:**
- Make sure you're NOT sending card details to backend
- Only send `paymentIntentId` and `paymentMethodId`
- Check backend logs to see what it's receiving

---

## 📝 **Request Format to Backend**

After Stripe SDK creates PaymentMethod, send this to backend:

```json
POST /orders/payment/confirm
{
  "paymentIntentId": "pi_3SeQNJRV5Vgu8d1f1Jl2faqg",
  "paymentMethodId": "pm_1ABC123xyz"
}
```

**DO NOT send:**
- ❌ `cardNumber`
- ❌ `expiryMonth`
- ❌ `expiryYear`
- ❌ `cvv`
- ❌ `cardholderName`

---

## ✅ **Checklist**

- [ ] Stripe iOS SDK added via Swift Package Manager
- [ ] `import Stripe` added to StripeCardPaymentView.swift
- [ ] Publishable key configured (replace `pk_test_YOUR_PUBLISHABLE_KEY_HERE`)
- [ ] Tested with test card `4242 4242 4242 4242`
- [ ] Console shows PaymentMethod created successfully
- [ ] Backend receives only `paymentIntentId` and `paymentMethodId`
- [ ] Payment succeeds!

---

## 🔗 **Resources**

- **Stripe iOS SDK Docs**: https://stripe.dev/stripe-ios/
- **Stripe Testing**: https://stripe.com/docs/testing
- **Stripe Dashboard**: https://dashboard.stripe.com/

---

**Once Stripe SDK is integrated, the payment flow will work correctly!**

