import 'package:cupid_app/services/premium_service.dart';
import 'package:flutter/material.dart';

Future<void> showSubscriptionReviewDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text(PremiumService.subscriptionReviewTitle),
      content: const Text(PremiumService.subscriptionReviewMessage),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
