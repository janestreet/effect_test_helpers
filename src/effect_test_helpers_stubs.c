#include <stdatomic.h>

#include <caml/mlvalues.h>

/* Linking this library passes [-Wl,--wrap=caml_alloc_stack] (and likewise for
   [caml_alloc_stack_preemptible]), which redirects every call to those runtime functions
   to the [__wrap_] versions below, and makes the [__real_] symbols refer to the original
   runtime functions.

   The [__real_] references are weak so that loading these stubs somewhere the wrapping
   didn't happen doesn't fail. In that case, the [__wrap_] functions are never called. */

static atomic_long fibers_created = 0;

extern value __real_caml_alloc_stack(value hval, value hexn, value heff)
    __attribute__((weak));

extern value __real_caml_alloc_stack_preemptible(value hval, value hexn, value heff,
                                                 value htick) __attribute__((weak));

value __wrap_caml_alloc_stack(value hval, value hexn, value heff) {
  atomic_fetch_add_explicit(&fibers_created, 1, memory_order_relaxed);
  return __real_caml_alloc_stack(hval, hexn, heff);
}

value __wrap_caml_alloc_stack_preemptible(value hval, value hexn, value heff,
                                          value htick) {
  atomic_fetch_add_explicit(&fibers_created, 1, memory_order_relaxed);
  return __real_caml_alloc_stack_preemptible(hval, hexn, heff, htick);
}

value effect_test_helpers_fibers_created(value unit) {
  (void)unit;
  return Val_long(atomic_load_explicit(&fibers_created, memory_order_relaxed));
}
