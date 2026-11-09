import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/riverpod/cart_notifier.dart';
import 'package:cart_four_ways/services/checkout_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCheckoutApi extends Mock implements CheckoutApi {}

void main() {
  setUpAll(() => registerFallbackValue(0.0));

  test('two keyboards with SAVE10 total 88.2', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final cart = container.read(cartProvider.notifier);
    cart.add(catalog[0]);
    cart.add(catalog[0]);
    cart.applyCoupon('SAVE10');

    expect(container.read(cartProvider).total, closeTo(88.2, 0.001));
  });

  test('failed checkout sets failure and keeps the lines', () async {
    final api = MockCheckoutApi();
    when(() => api.submit(any()))
        .thenThrow(const CheckoutException('Card declined'));

    final container = ProviderContainer(
      overrides: [checkoutApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);

    final cart = container.read(cartProvider.notifier);
    cart.add(catalog[0]);
    await cart.checkout();

    final state = container.read(cartProvider);
    expect(state.status, CheckoutStatus.failure);
    expect(state.lines, isNotEmpty);
  });
}
