import 'package:bloc_test/bloc_test.dart';
import 'package:cart_four_ways/bloc/cart_bloc.dart';
import 'package:cart_four_ways/bloc/cart_event.dart';
import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/services/checkout_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCheckoutApi extends Mock implements CheckoutApi {}

void main() {
  setUpAll(() => registerFallbackValue(0.0));

  blocTest<CartBloc, CartState>(
    'two keyboards then SAVE10 emit three states',
    build: () => CartBloc(MockCheckoutApi()),
    act: (b) => b
      ..add(CartProductAdded(catalog[0]))
      ..add(CartProductAdded(catalog[0]))
      ..add(const CartCouponApplied('SAVE10')),
    expect: () => [
      isA<CartState>().having((s) => s.itemCount, 'itemCount', 1),
      isA<CartState>().having((s) => s.itemCount, 'itemCount', 2),
      isA<CartState>().having((s) => s.total, 'total', closeTo(88.2, 0.001)),
    ],
  );

  blocTest<CartBloc, CartState>(
    'failed checkout emits submitting then failure',
    build: () {
      final api = MockCheckoutApi();
      when(() => api.submit(any())).thenThrow(const CheckoutException('Card declined'));
      return CartBloc(api);
    },
    act: (b) => b
      ..add(CartProductAdded(catalog[0]))
      ..add(const CartCheckoutRequested()),
    wait: const Duration(milliseconds: 100),
    skip: 1,
    expect: () => [
      isA<CartState>().having((s) => s.status, 'status', CheckoutStatus.submitting),
      isA<CartState>()
          .having((s) => s.status, 'status', CheckoutStatus.failure)
          .having((s) => s.lines, 'lines', isNotEmpty),
    ],
  );

  late MockCheckoutApi slowApi;

  blocTest<CartBloc, CartState>(
    'droppable lets only one checkout through',
    build: () {
      slowApi = MockCheckoutApi();
      when(() => slowApi.submit(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return 'ORD-1';
      });
      return CartBloc(slowApi);
    },
    act: (b) => b
      ..add(CartProductAdded(catalog[0]))
      ..add(const CartCheckoutRequested())
      ..add(const CartCheckoutRequested()),
    wait: const Duration(milliseconds: 300),
    skip: 1,
    expect: () => [
      isA<CartState>().having((s) => s.status, 'status', CheckoutStatus.submitting),
      isA<CartState>().having((s) => s.status, 'status', CheckoutStatus.success),
    ],
    verify: (_) => verify(() => slowApi.submit(any())).called(1),
  );
}