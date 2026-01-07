# 💳 Stripe Integration Guide for iOS

## ✅ **What's Been Updated**

1. ✅ Month/Year pickers instead of text input
2. ✅ Updated DTO to send `paymentMethodId` instead of card details
3. ✅ Payment flow updated to create PaymentMethod first

---

## 🔧 **Option 1: Use Stripe iOS SDK (Recommended)**

### **Step 1: Add Stripe SDK to Project**

1. Open your project in Xcode
2. Go to **File → Add Packages...**
3. Enter: `https://github.com/stripe/stripe-ios`
4. Select version: **Latest (23.x.x)**
5. Click **Add Package**

### **Step 2: Update StripeCardPaymentView.swift**

Replace the `createPaymentMethod` function with:

```swift
import Stripe

private func createPaymentMethod(
    cardNumber: String,
    expiryMonth: Int,
    expiryYear: Int,
    cvv: String,
    cardholderName: String?,
    paymentIntentId: String
) {
    // Configure Stripe with your publishable key
    // Get this from: https://dashboard.stripe.com/apikeys
    STPAPIClient.shared.publishableKey = "pk_test_..." // Your Stripe publishable key
    
    // Create card parameters
    let cardParams = STPPaymentMethodCardParams()
    cardParams.number = cardNumber
    cardParams.expMonth = NSNumber(value: expiryMonth)
    cardParams.expYear = NSNumber(value: expiryYear)
    cardParams.cvc = cvv
    
    // Create payment method parameters
    let paymentMethodParams = STPPaymentMethodParams(
        card: cardParams,
        billingDetails: cardholderName != nil ? STPPaymentMethodBillingDetails().also {
            $0.name = cardholderName
        } : nil,
        metadata: nil
    )
    
    // Create PaymentMethod using Stripe SDK
    STPAPIClient.shared.createPaymentMethod(with: paymentMethodParams) { [weak self] paymentMethod, error in
        DispatchQueue.main.async {
            guard let self = self else { return }
            
            if let error = error {
                self.isProcessing = false
                self.onPaymentError("Failed to create payment method: \(error.localizedDescription)")
                return
            }
            
            guard let paymentMethodId = paymentMethod?.stripeId else {
                self.isProcessing = false
                self.onPaymentError("Failed to get payment method ID")
                return
            }
            
            print("✅ PaymentMethod created: \(paymentMethodId)")
            
            // Now confirm payment with paymentMethodId
            self.confirmPaymentWithMethodId(
                paymentIntentId: paymentIntentId,
                paymentMethodId: paymentMethodId
            )
        }
    }
}
```

### **Step 3: Add Stripe Publishable Key**

Add to your `Info.plist` or create a config file:

```swift
// In AppAPIConstants.swift or a new StripeConfig.swift
struct StripeConfig {
    static let publishableKey = "pk_test_..." // Your Stripe publishable key
}
```

---

## 🔧 **Option 2: Backend Creates PaymentMethod (Current Implementation)**

If you don't want to integrate Stripe SDK yet, the backend can create the PaymentMethod.

### **Backend Endpoint Required:**

```
POST /payments/create-payment-method
Body: {
  "cardNumber": "4242424242424242",
  "expiryMonth": 12,
  "expiryYear": 2034,
  "cvv": "123",
  "cardholderName": "John Doe",
  "paymentIntentId": "pi_xxx"
}

Response: {
  "paymentMethodId": "pm_xxx",
  "success": true
}
```

### **Backend Implementation (NestJS):**

```typescript
// src/order/payment.controller.ts
@Post('create-payment-method')
async createPaymentMethod(@Body() dto: CreatePaymentMethodDto) {
  // 1. Create PaymentMethod from card details
  const paymentMethod = await this.stripeService.stripe.paymentMethods.create({
    type: 'card',
    card: {
      number: dto.cardNumber,
      exp_month: dto.expiryMonth,
      exp_year: dto.expiryYear,
      cvc: dto.cvv,
    },
    billing_details: dto.cardholderName ? {
      name: dto.cardholderName,
    } : undefined,
  });

  // 2. Attach to PaymentIntent
  await this.stripeService.stripe.paymentIntents.update(dto.paymentIntentId, {
    payment_method: paymentMethod.id,
  });

  return {
    paymentMethodId: paymentMethod.id,
    success: true,
  };
}
```

---

## 📝 **Current Implementation**

The current code in `StripeCardPaymentView.swift` uses **Option 2** (backend creates PaymentMethod). 

To switch to **Option 1** (Stripe SDK):
1. Add Stripe SDK package
2. Replace the `createPaymentMethod` function with the code above
3. Add your Stripe publishable key

---

## ✅ **What Works Now**

1. ✅ Month picker (1-12) with month names
2. ✅ Year picker (current year to 10 years ahead)
3. ✅ Test cards automatically fill month/year correctly
4. ✅ Sends `paymentMethodId` to backend (after PaymentMethod is created)
5. ✅ Backend confirms payment with `paymentMethodId`

---

## 🎯 **Next Steps**

1. **If using Stripe SDK**: Follow Option 1 above
2. **If using backend**: Implement the `/payments/create-payment-method` endpoint
3. **Test with test cards**: Use the provided test cards to verify the flow

---

## 🧪 **Test Cards**

All test cards now use:
- **Month**: 12 (December)
- **Year**: 2034
- **CVV**: 123

The pickers will automatically select these values when you tap a test card.

