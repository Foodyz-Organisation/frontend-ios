# 🔧 Backend Payment Fix - Required Changes

The current `confirmPayment` endpoint only checks the PaymentIntent status but doesn't attach a payment method. Here are the required backend changes:

## 📁 **1. UPDATE CONFIRM PAYMENT DTO**
**File**: `src/order/dto/confirm-payment.dto.ts`

```typescript
import { IsNotEmpty, IsString, IsNumber, IsOptional, Min, Max } from 'class-validator';

export class ConfirmPaymentDto {
  @IsString()
  @IsNotEmpty()
  paymentIntentId: string; // Stripe PaymentIntent ID

  @IsString()
  @IsNotEmpty()
  cardNumber: string; // Card number (without spaces)

  @IsNumber()
  @Min(1)
  @Max(12)
  expiryMonth: number; // 1-12

  @IsNumber()
  @Min(2024)
  expiryYear: number; // Full year (e.g., 2024)

  @IsString()
  @IsNotEmpty()
  cvv: string; // CVV code

  @IsString()
  @IsOptional()
  cardholderName?: string; // Optional cardholder name
}
```

## 📁 **2. UPDATE STRIPE SERVICE**
**File**: `src/order/StripeService.ts`

Add a new method to process payment with card details:

```typescript
/**
 * Process payment with card details
 * Creates PaymentMethod, attaches to PaymentIntent, and confirms it
 */
async processPaymentWithCard(
  paymentIntentId: string,
  cardNumber: string,
  expiryMonth: number,
  expiryYear: number,
  cvv: string,
  cardholderName?: string,
): Promise<{ status: string; paymentIntentId: string }> {
  try {
    // 1. Create PaymentMethod from card details
    const paymentMethod = await this.stripe.paymentMethods.create({
      type: 'card',
      card: {
        number: cardNumber,
        exp_month: expiryMonth,
        exp_year: expiryYear,
        cvc: cvv,
      },
      billing_details: cardholderName ? {
        name: cardholderName,
      } : undefined,
    });

    // 2. Attach PaymentMethod to PaymentIntent
    await this.stripe.paymentIntents.update(paymentIntentId, {
      payment_method: paymentMethod.id,
    });

    // 3. Confirm the PaymentIntent
    const confirmedPaymentIntent = await this.stripe.paymentIntents.confirm(
      paymentIntentId,
      {
        payment_method: paymentMethod.id,
      }
    );

    return {
      status: confirmedPaymentIntent.status,
      paymentIntentId: confirmedPaymentIntent.id,
    };
  } catch (error) {
    console.error('Stripe payment processing failed:', error);
    throw new InternalServerErrorException(
      `Failed to process payment: ${error.message}`,
    );
  }
}
```

## 📁 **3. UPDATE ORDER SERVICE**
**File**: `src/order/order.service.ts`

Update the `confirmPayment` method:

```typescript
// -----------------------------
// CONFIRM CARD PAYMENT (with card details)
// -----------------------------
async confirmPayment(dto: ConfirmPaymentDto): Promise<{ success: boolean; order?: Order }> {
  try {
    // 1. Get payment from DB
    const payment = await this.paymentService.getPaymentByIntentId(dto.paymentIntentId);
    if (!payment) {
      throw new NotFoundException('Payment not found');
    }

    // 2. Process payment with card details (create PaymentMethod, attach, confirm)
    const stripeResult = await this.stripeService.processPaymentWithCard(
      dto.paymentIntentId,
      dto.cardNumber,
      dto.expiryMonth,
      dto.expiryYear,
      dto.cvv,
      dto.cardholderName,
    );
    
    // 3. Update payment status in DB
    await this.paymentService.updatePaymentStatus(dto.paymentIntentId, stripeResult.status);

    // 4. Check if payment succeeded
    if (stripeResult.status === 'succeeded') {
      // 5. If order exists, return it
      if (payment.orderId) {
        const order = await this.orderModel.findById(payment.orderId);
        return {
          success: true,
          order: order || undefined,
        };
      }

      return { success: true };
    } else {
      throw new BadRequestException(`Payment status: ${stripeResult.status}`);
    }
  } catch (error) {
    console.error('Error confirming payment:', error);
    throw error;
  }
}
```

## 📁 **4. UPDATE ORDER CONTROLLER**
**File**: `src/order/order.controller.ts`

The controller should already be using the DTO, but make sure it's using the updated one:

```typescript
// -----------------------------
// CONFIRM CARD PAYMENT
// POST /orders/payment/confirm
// Body: { paymentIntentId, cardNumber, expiryMonth, expiryYear, cvv, cardholderName? }
// -----------------------------
@Post('payment/confirm')
async confirmPayment(@Body() dto: ConfirmPaymentDto) {
  return this.orderService.confirmPayment(dto);
}
```

## ✅ **Summary**

The changes:
1. **DTO**: Now accepts card details (number, expiry, CVV, name)
2. **StripeService**: New method `processPaymentWithCard` that:
   - Creates a PaymentMethod from card details
   - Attaches it to the PaymentIntent
   - Confirms the PaymentIntent
3. **OrderService**: Updated to use the new StripeService method
4. **Controller**: Already correct, just needs the updated DTO

After these changes, the iOS app will send card details to the backend, and the backend will properly process the payment through Stripe.

