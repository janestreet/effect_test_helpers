open! Base
open Expect_test_helpers_base

external fibers_created : unit -> int = "effect_test_helpers_fibers_created"
[@@noalloc] [@@no_effects]

type _ no_ops = |

module No_ops = Handled_effect.Make (struct
    type 'a t = 'a no_ops
  end)

let create_fiber () =
  match No_ops.run (fun _ -> ()) with
  | Value () -> ()
  | Exception exn -> raise exn
  | Operation (_, _) -> .
;;

(* Fail loudly, rather than silently passing, if the linker flags didn't take effect. *)
let check_fiber_creation_is_counted =
  Portable_lazy.from_fun (fun () ->
    let before = fibers_created () in
    create_fiber ();
    if fibers_created () = before
    then
      raise_s
        [%message
          "Effect_test_helpers is not counting fiber creation. It only works in native \
           code without prelinking; add [(inline_tests ((no_experimental_prelinking \
           true)))] to the test's jbuild."])
;;

let fibers_created () =
  Portable_lazy.force check_fiber_creation_is_counted;
  fibers_created ()
;;

let require_fiber_creation_does_not_exceed
  ?cr
  ?hide_positions
  ?(here = Stdlib.Lexing.dummy_pos)
  limit
  f
  =
  if limit < 0
  then raise_s [%message "Fiber creation limit must be non-negative." (limit : int)];
  let before = fibers_created () in
  let result = f () in
  let fibers_created = fibers_created () - before in
  require
    ?cr
    ?hide_positions
    ~here
    (fibers_created <= limit)
    ~if_false_then_print_s:
      (lazy
        [%message
          "Created more fibers than the limit." (fibers_created : int) (limit : int)]);
  result
;;

let require_does_not_create_fibers ?cr ?hide_positions ?(here = Stdlib.Lexing.dummy_pos) f
  =
  require_fiber_creation_does_not_exceed ?cr ?hide_positions ~here 0 f
;;
