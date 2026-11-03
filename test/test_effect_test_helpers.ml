open! Base
open Expect_test_helpers_base
open Effect_test_helpers

type 'a op = E : unit op [@@warning "-37"]

module Eff = Handled_effect.Make (struct
    type 'a t = 'a op
  end)

let create_fiber () =
  match Eff.run (fun _ -> ()) with
  | Value () -> ()
  | Exception exn -> raise exn
  | Operation (E, _) -> assert false
;;

(* Goes through [caml_alloc_stack_preemptible] rather than [caml_alloc_stack]. *)
let create_preemptible_fiber () =
  match
    (Eff.Preemptible.run [@alert "-do_not_nest"])
      ~on_tick:(fun () -> Handled_effect.Preemptible.Tick_outcome.Continue)
      (fun _ -> ())
  with
  | Value () -> ()
  | Exception exn -> raise exn
  | Operation (E, _) | Preemption _ -> assert false
;;

let%expect_test "no fibers" =
  require_does_not_create_fibers (fun () -> ());
  [%expect {| |}]
;;

let%expect_test "one fiber" =
  require_does_not_create_fibers ~cr:Comment create_fiber;
  [%expect
    {|
    (* require-failed: lib/effect_test_helpers/test/test_effect_test_helpers.ml:LINE:COL. *)
    ("Created more fibers than the limit."
      (fibers_created 1)
      (limit          0))
    |}]
;;

let%expect_test "two fibers" =
  require_does_not_create_fibers ~cr:Comment (fun () ->
    create_fiber ();
    create_fiber ());
  [%expect
    {|
    (* require-failed: lib/effect_test_helpers/test/test_effect_test_helpers.ml:LINE:COL. *)
    ("Created more fibers than the limit."
      (fibers_created 2)
      (limit          0))
    |}]
;;

let%expect_test "at or under the limit" =
  require_fiber_creation_does_not_exceed 0 (fun () -> ());
  require_fiber_creation_does_not_exceed 1 create_fiber;
  require_fiber_creation_does_not_exceed 2 create_fiber;
  require_fiber_creation_does_not_exceed 2 (fun () ->
    create_fiber ();
    create_fiber ());
  [%expect {| |}]
;;

let%expect_test "over the limit" =
  require_fiber_creation_does_not_exceed ~cr:Comment 0 create_fiber;
  require_fiber_creation_does_not_exceed ~cr:Comment 1 (fun () ->
    create_fiber ();
    create_fiber ());
  [%expect
    {|
    (* require-failed: lib/effect_test_helpers/test/test_effect_test_helpers.ml:LINE:COL. *)
    ("Created more fibers than the limit."
      (fibers_created 1)
      (limit          0))
    (* require-failed: lib/effect_test_helpers/test/test_effect_test_helpers.ml:LINE:COL. *)
    ("Created more fibers than the limit."
      (fibers_created 2)
      (limit          1))
    |}]
;;

let%expect_test "preemptible fibers" =
  require_does_not_create_fibers ~cr:Comment create_preemptible_fiber;
  require_fiber_creation_does_not_exceed ~cr:Comment 1 (fun () ->
    create_fiber ();
    create_preemptible_fiber ());
  require_fiber_creation_does_not_exceed 2 (fun () ->
    create_fiber ();
    create_preemptible_fiber ());
  [%expect
    {|
    (* require-failed: lib/effect_test_helpers/test/test_effect_test_helpers.ml:LINE:COL. *)
    ("Created more fibers than the limit."
      (fibers_created 1)
      (limit          0))
    (* require-failed: lib/effect_test_helpers/test/test_effect_test_helpers.ml:LINE:COL. *)
    ("Created more fibers than the limit."
      (fibers_created 2)
      (limit          1))
    |}]
;;

let%expect_test "negative limit" =
  require_does_raise (fun () -> require_fiber_creation_does_not_exceed (-1) Fn.id);
  [%expect {| ("Fiber creation limit must be non-negative." (limit -1)) |}]
;;
