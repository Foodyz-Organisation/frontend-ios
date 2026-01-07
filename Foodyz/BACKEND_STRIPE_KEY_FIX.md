# 🔧 Backend Stripe API Key Fix

## ❌ **Error You're Seeing**

```
StripeAuthenticationError: Invalid API Key provided: mk_1SeNr***************X86G
```

## 🔍 **Problem**

Your backend `.env` file has a **Mode Key** (`mk_...`) instead of a **Secret Key** (`sk_test_...` or `sk_live_...`).

**Mode Keys** are for Stripe Dashboard testing only - they cannot be used in API calls.

---

## ✅ **Solution: Get Correct Stripe Secret Key**

### **Step 1: Go to Stripe Dashboard**

1. Open: https://dashboard.stripe.com/apikeys
2. Make sure you're in **Test mode** (toggle in top right)

### **Step 2: Get Secret Key**

1. Find **"Secret key"** section (NOT "Publishable key")
2. Click **"Reveal test key"** or **"Reveal live key"**
3. Copy the key - it should start with:
   - `sk_test_...` (for testing)
   - `sk_live_...` (for production)

### **Step 3: Update Backend .env File**

In your backend project, open `.env` file and update:

```env
# ❌ WRONG (Mode Key - won't work)
STRIPE_SECRET_KEY=mk_1SeNr***************X86G

# ✅ CORRECT (Secret Key - will work)
STRIPE_SECRET_KEY=sk_test_51ABC123xyz...  # Your actual secret key
```

### **Step 4: Restart Backend Server**

After updating `.env`:
```bash
# Stop your backend server (Ctrl+C)
# Then restart it
npm run start:dev
# or
yarn start:dev
```

---

## 🔑 **Key Types Explained**

| Key Type | Format | Usage | Where to Use |
|----------|--------|-------|--------------|
| **Secret Key** | `sk_test_...` or `sk_live_...` | Backend API calls | ✅ Backend `.env` file |
| **Publishable Key** | `pk_test_...` or `pk_live_...` | Frontend SDK | ✅ iOS app (Stripe SDK) |
| **Mode Key** | `mk_...` | Dashboard testing only | ❌ Cannot use in code |

---

## ✅ **Verify It Works**

After updating the key, test creating an order:

1. Create an order with `paymentMethod: 'CARD'`
2. Check backend logs - should see:
   ```
   ✅ PaymentIntent created successfully
   ```
3. No more `StripeAuthenticationError`!

---

## 📝 **Complete .env Example**

```env
# Stripe Configuration
STRIPE_SECRET_KEY=sk_test_51ABC123xyz...  # Secret key from Stripe Dashboard

# Other environment variables...
DATABASE_URL=mongodb://localhost:27017/foodyz
JWT_SECRET=your-jwt-secret
PORT=3000
```

---

## ⚠️ **Security Notes**

1. **Never commit `.env` file to Git** - add it to `.gitignore`
2. **Use test keys** (`sk_test_...`) for development
3. **Use live keys** (`sk_live_...`) only in production
4. **Keep keys secret** - don't share them publicly

---

## 🔗 **Resources**

- **Stripe Dashboard**: https://dashboard.stripe.com/apikeys
- **Stripe API Keys Docs**: https://stripe.com/docs/keys
- **Test Cards**: https://stripe.com/docs/testing

---

**Once you update the `.env` file with the correct Secret Key, the payment flow will work!**

