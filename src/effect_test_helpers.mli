(** Test helpers for checking whether code allocates fibers.

    Linking this library wraps the functions in the runtime that allocate fibers, so that
    every fiber created in the process is counted. *)

open! Base

(** The number of fibers created in this process, across all domains, since startup. *)
val fibers_created : unit -> int

(** [require_does_not_create_fibers f] runs [f], and prints a CR if any fibers were
    created while it ran. Fibers created concurrently by other domains are also counted. *)
val require_does_not_create_fibers
  :  ?cr:Expect_test_helpers_base.CR.t
  -> ?hide_positions:bool (** default is [false] when [cr=CR], [true] otherwise *)
  -> ?here:Stdlib.Lexing.position
  -> (unit -> 'a)
  -> 'a

(** [require_fiber_creation_does_not_exceed limit f] runs [f], and prints a CR if more
    than [limit] fibers were created while it ran. Fibers created concurrently by other
    domains are also counted. Raises if [limit] is negative. *)
val require_fiber_creation_does_not_exceed
  :  ?cr:Expect_test_helpers_base.CR.t
  -> ?hide_positions:bool (** default is [false] when [cr=CR], [true] otherwise *)
  -> ?here:Stdlib.Lexing.position
  -> int
  -> (unit -> 'a)
  -> 'a
