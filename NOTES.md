Lab 9 Notes: One Cart, Four Ways

Tags: p1-shared, p2-setstate, p3-riverpod, p4-cubit, p5-bloc

CHECKPOINT QUESTIONS

1. Where does the state live and when does it die?

setState: in a field of the State object. It dies when the page is popped, and on hot restart.

Riverpod: in the ProviderContainer under ProviderScope. It survives popping the page and dies when the app closes (or with autoDispose, when nobody listens).

Cubit: in the Cubit instance owned by BlocProvider. It dies when the page is popped and BlocProvider calls close().

Bloc: same as Cubit.

2. What is the single public mutation API? Which style has none?

Notifier: its public methods. Cubit: its public methods that call emit. Bloc: add(event). setState has none, because the state is a plain field and any code in the State class can change it.

3. Mapping between the styles.

ref.watch is BlocBuilder, ref.read is context.read, ref.listen is BlocListener, select is buildWhen or BlocSelector. setState is the baseline where the widget is both holder and subscriber, so the whole build re-runs.

4. Why skip notifying when the state is equal, and what two things must you do to CartState?

It avoids pointless rebuilds. We must override == and hashCode together, and compare lines by value (listEquals, with == on CartLine and Product).

5. Which guard after the await?

setState needs mounted (the State may be disposed). Riverpod needs nothing (the notifier lives in the container, not in a widget). Cubit needs isClosed (emit after close throws). Bloc needs emit.isDone (the handler’s emit is no longer valid). They differ because each style’s state has a different owner and lifetime.

INLINE QUESTIONS

Part 1

Why is CartLine immutable? Each change creates a new object, so “did it change?” is an equality check, which Riverpod, Cubit and Bloc rely on. It also makes undo possible. setState would still work with mutation because it always rebuilds, which is the trap: with the other styles, a mutated object equals the old one, so nothing notifies.

Why does CartBody take callbacks? So it does not depend on any state library and can be reused in all four pages, and it is easy to test.

Part 2

T3: why not store total? It is a second copy of data from lines and coupon, so one forgotten update leaves a wrong price. A getter always recomputes.

T4: what happens without mounted? If the user leaves during the 1.5 s wait, setState runs on a disposed State and throws.

After T4, how would a second page read the cart? It can’t, because the state is private to one State object. We would have to lift the state up and pass it down, or use an InheritedWidget.

After T5, where does _history live? In the State object. Hot reload keeps it, and hot restart wipes it.

Part 3

ref.read is used for: the notifier handle in the page, orderId inside the listen callback, checkoutApiProvider inside the notifier, and canUndo inside canUndoProvider. ref.watch is used for: cartProvider and canUndoProvider in the page (to display data), select in CartSummary, and cartProvider inside canUndoProvider (so it recomputes).

T2: does copyWith notify if the coupon is unchanged? Without == yes, because it is a new object. With == and hashCode it does not notify.

T3: why does the summary rebuild less than in setState? setState rebuilds the whole page. Here the card watches only its four selected values, so unrelated changes do not rebuild it.

T4: why is no mounted check needed? The state belongs to the notifier in the container, not to a widget, so it stays alive after the page is popped.

T5: what must canUndoProvider watch, and what happened with autoDispose? It must watch cartProvider, because the notifier getter is not observable. With autoDispose, popping the page destroyed the notifier, so the cart and history came back empty.

Part 4

What breaks if BlocProvider is inside CartBody? Widgets outside it (the undo button, coupon field, summary) would throw ProviderNotFoundException.

Riverpod equivalents: BlocProvider is NotifierProvider with ProviderScope, BlocBuilder is ref.watch, BlocListener is ref.listen, context.read is ref.read, buildWhen is select.

T2: applying the same coupon twice emits nothing, because the new state equals the old one.

T4: emit after close throws a StateError, so we check isClosed after the await.

T5: a getter is not observable because BlocBuilder only rebuilds when a new state is emitted, so canUndo was put inside CartState.

T6: the Riverpod test checks only the final state, while blocTest checks the whole sequence of emitted states.

Part 5

When is Bloc worth the boilerplate? For checkout, where droppable() and the event log help. For adding a product it is overhead, because a Cubit method does the same with less code.

Which styles can drop duplicate taps declaratively? Only Bloc, with droppable(). In the others we use a status == submitting guard or disable the button.

T2: what extra information does the observer give? onTransition shows the event that caused the change, and Cubit onChange does not.

T4: with three quick taps, droppable() lets only one checkout run. The Cubit would start three unless guarded by hand. Bloc checks emit.isDone after the await, and Cubit checks isClosed.

T5: should every event push to history? No. Only add, change quantity and apply coupon are undoable. Checkout, undo and dismissing the banner are not, so undo can’t restore a spinner or undo itself.

COMPARISON TABLE

setState: code lines 149, test lines 20, files 1. Strength: least code and no dependencies. Weakness: state is trapped in the widget, needs prop drilling and a mounted guard.

Riverpod: code lines 188, test lines 43, files 3. Strength: state is reachable anywhere without context, and easy to unit test with ProviderContainer. Weakness: read vs watch mistakes are easy, and autoDispose lifetimes can surprise you.

Cubit: code lines 179, test lines 47, files 3. Strength: simple methods, and blocTest checks the exact sequence of states. Weakness: scoped to the widget tree, and getters are not observable.

Bloc: code lines 247, test lines 72, files 5. Strength: every change is a traceable event, and transformers like droppable() are one line. Weakness: the most boilerplate, and overkill for simple actions.

Line counts are measured with Get-Content on each file, excluding shared code (model, widgets, API).