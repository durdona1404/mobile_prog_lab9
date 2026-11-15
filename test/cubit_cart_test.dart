import 'package:bloc_test/bloc_test.dart';
import 'package:cart_four_ways/cubit/cart_cubit.dart';
import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/services/checkout_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCheckoutApi extends Mock implements CheckoutApi {}

void main() {
  setUpAll(() => registerFallbackValue(0.0));

  blocTest<CartCubit, CartState>(
    'two keyboards then SAVE10 emit three states',
    build: () => CartCubit(MockCheckoutApi()),
    act: (c) {
      c.add(catalog[0]);
      c.add(catalog[0]);
      c.applyCoupon('SAVE10');
    },
    expect: () => [
      isA<CartState>().having((s) => s.itemCount, 'itemCount', 1),
      isA<CartState>().having((s) => s.itemCount, 'itemCount', 2),
      isA<CartState>().having((s) => s.total, 'total', closeTo(88.2, 0.001)),
    ],
  );

  blocTest<CartCubit, CartState>(
    'failed checkout emits submitting then failure',
    build: () {
      final api = MockCheckoutApi();
      when(() => api.submit(any())).thenThrow(const CheckoutException('Card declined'));
      return CartCubit(api);
    },
    act: (c) async {
      c.add(catalog[0]);
      await c.checkout();
    },
    skip: 1,
    expect: () => [
      isA<CartState>().having((s) => s.status, 'status', CheckoutStatus.submitting),
      isA<CartState>()
          .having((s) => s.status, 'status', CheckoutStatus.failure)
          .having((s) => s.lines, 'lines', isNotEmpty),
    ],
  );
}