enum PaymentMethodType { cashOnDelivery, payPal, applePay, googlePay }

class PaymentMethodOption {
  final PaymentMethodType type;
  final String title;
  final String subtitle;
  final String iconAsset; // logical name, map to real icon/asset in UI

  const PaymentMethodOption({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.iconAsset,
  });
}

const List<PaymentMethodOption> availablePaymentMethods = [
  PaymentMethodOption(
    type: PaymentMethodType.cashOnDelivery,
    title: 'Cash on Delivery',
    subtitle: 'Pay when your order arrives',
    iconAsset: 'cod',
  ),
  PaymentMethodOption(
    type: PaymentMethodType.payPal,
    title: 'PayPal',
    subtitle: 'Pay securely with your PayPal account',
    iconAsset: 'paypal',
  ),
  PaymentMethodOption(
    type: PaymentMethodType.applePay,
    title: 'Apple Pay',
    subtitle: 'Fast checkout with Apple Pay',
    iconAsset: 'apple_pay',
  ),
  PaymentMethodOption(
    type: PaymentMethodType.googlePay,
    title: 'Google Pay',
    subtitle: 'Fast checkout with Google Pay',
    iconAsset: 'google_pay',
  ),
];
