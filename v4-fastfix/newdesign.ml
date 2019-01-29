(* TODO:
 * - equality tests
 * - some base type to compute with; naturals?
 * - boolean intro/elim forms
 * - sum types
 *)

(*

NEW DESIGN as of January 2019
=============================

All tagless-final. Compiler flowchart:

    BIDIR: Bidirectional Datafun
      |
      | typecheck
      V
    MODAL: Explicit modal Datafun
      |              |
      | φ/δ          | forget □
      V              V
    SIMPLE: Non-monotone λ-calculus with fix & fast-fix
      |
      | normalize
      V
    NORMAL: Normal non-monotone λ-calculus with fix & fast-fix
      |
      | eval/compile
      V
    Output

GRIPES
======

This design involves passing types explicitly everywhere, which would be fine if
we weren't also computing with those types. But we are computing with them;
we're applying phi and delta to them. And this means we'll end up doing a
superlinear amount of work because we'll recompute the adjusted phi/delta types
at each level. If we instead worked bidirectionally the whole way through, I
believe we could avoid this. But, this would require more involved plumbing
boilerpate.

However, I suspect the total amount of type computation will be negligible
anyway, and compilation speed isn't the point here anyway; this is just a proof
of concept.

*)

exception TODO of string
exception Impossible of string

let todo msg = raise (TODO msg)
let impossible msg = raise (Impossible msg)

(* Strings with a unique identifier and a derivative degree. The "derivative
   degree" makes it easy, given a variable, to make up a variable standing for
   its derivative. This is kind of a hack, but the alternatives are:

   1. Passing contexts mapping variables to their derivative variables; or
   2. weak hashtable magic; or
   3. functorizing everything over the type of symbols/variables.

   All of which seem like more trouble than they're worth.
 *)
type sym = {name: string; id: int; degree: int}
module Sym = struct
  type t = sym
  let compare = Pervasives.compare
  let next_id = ref 0
  let nextId () = let x = !next_id in next_id := x + 1; x
  let gen name = {name = name; id = nextId(); degree = 0}
  let d x = {name = x.name; id = x.id; degree = 1+x.degree}
end

(* Contexts mapping variables to stuff. *)
module Cx = Map.Make(Sym)
type 'a cx = 'a Cx.t

(* Frontend, modal types. *)
type modtp = [ `Bool | `Set of modtp | `Box of modtp
             | `Tuple of modtp list | `Fn of modtp * modtp ]
(* Backend, non-modal types. *)
type rawtp = [ `Bool | `Set of rawtp | `Tuple of rawtp list | `Fn of rawtp * rawtp ]
(* Semilattices, parameterized by underlying types *)
type 'a semilat = [ `Bool | `Set of 'a | `Tuple of 'a semilat list | `Fn of 'a * 'a semilat ]

let rec firstOrder: modtp -> bool = function
  | `Fn _ -> false
  | `Bool | `Set _ -> true
  | `Box a -> firstOrder a
  | `Tuple tps -> List.for_all firstOrder tps

let rec phiDelta: modtp -> rawtp * rawtp = function
  | `Bool -> `Bool, `Bool
  | `Set a -> let fa = phi a in `Set fa, `Set fa
  | `Box a -> let fa, da = phiDelta a in `Tuple [fa;da], da
  | `Tuple tps -> let ftps, dtps = List.(map phiDelta tps |> split) in
                  `Tuple ftps, `Tuple dtps
  | `Fn (a,b) -> let fa,da = phiDelta a and fb,db = phiDelta b in
                 `Fn (fa, fb), `Fn (fa, `Fn (da, db))
and phi a = fst (phiDelta a)
and delta a = snd (phiDelta a)

let phiDeltaLat: modtp semilat -> rawtp semilat * rawtp semilat = Obj.magic phiDelta
let phiLat: modtp semilat -> rawtp semilat = Obj.magic phi
let deltaLat: modtp semilat -> rawtp semilat = Obj.magic delta


(* M,N ::= x | λx.M | M N | (M0,M1,...,Mn) | πᵢ M
 *       | ⊥ | M ∨ N | {M} | for (x in M) N
 *       | box M | let box x = M in N
 *)
module type BIDIR = sig
  type tp
  type term
  type expr

  (* checking terms *)
  val expr: expr -> term
  val letIn: sym -> expr -> term -> term
  val lam: sym -> term -> term
  val tuple: term list -> term
  val set: term list -> term
  val union: term list -> term
  val forIn: sym -> expr -> term -> term
  val box: term -> term
  val letBox: sym -> expr -> term -> term
  val fix: sym -> term -> term

  (* inferring exprs *)
  val var: sym -> expr
  val app: expr -> term -> expr
  val proj: int -> expr -> expr
  val asc: tp -> term -> expr
end

(* For now, no typing contexts or variable usage/freeness information. *)
module type BASE = sig
  type tp
  type term
  val var: tp -> sym -> term
  val letIn: tp -> tp -> sym -> term -> term -> term
  val lam: tp -> tp -> sym -> term -> term
  val app: tp -> tp -> term -> term -> term
  val tuple: (tp * term) list -> term
  val proj: tp list -> int -> term -> term
  (* set A [M0;...;Mn] = {M0,...,Mn} : {A} *)
  val set: tp -> term list -> term
  (* union A [M0;...;Mn] = M0 ∨ ... ∨ Mn : A *)
  val union: tp semilat -> term list -> term
  (* forIn A B x M N = for (x : A in M) do N : B *)
  val forIn: tp -> tp semilat -> sym -> term -> term -> term
  val fix: tp semilat -> term -> term
end

module type MODAL = sig
  include BASE with type tp = modtp
  val box: tp -> term -> term
  val letBox: tp -> tp -> sym -> term -> term -> term
end

module type SIMPLE = sig
  include BASE with type tp = rawtp
  val fastfix: tp semilat -> term -> term
end


(* Implementation of the go-faster transformation. *)
module Seminaive(Raw: SIMPLE): MODAL
       with type term = Raw.term * Raw.term
= struct
  type tp = modtp
  type term = Raw.term * Raw.term (* φM, δM *)

  (* This should only ever be used at base types. It almost ignores its
   * argument; however, at sum types, it does depend on the tag. *)
  let rec zero (tp: tp) (term: Raw.term): Raw.term = match tp with
    | `Box a -> zero a term
    | `Bool -> todo "no boolean literals yet"
    | `Set a -> Raw.set (phi a) []
    | `Tuple tps ->
       let dtps = List.map delta tps in
       List.mapi (fun i a -> delta a, zero a (Raw.proj dtps i term)) tps
       |> Raw.tuple
    (* This case _should_ be dead code. *)
    | `Fn (a,b) -> impossible "cannot compute zero change at function type"

  (* φx = x                 δx = dx *)
  let var (a: tp) (x: sym) = Raw.var (phi a) x, Raw.var (delta a) (Sym.d x)

  (* φ(box M) = φM, δM      δ(box M) = δM *)
  let box (a: tp) (fTerm, dTerm: term): term =
    let fa, da = phiDelta a in
    Raw.tuple [fa, fTerm; da, dTerm], dTerm

  (* φ(let box x = M in N) = let x,dx = φM in φN
   * δ(let box x = M in N) = let x,dx = φM in δN *)
  let letBox (a: tp) (b: tp) (x: sym) (fExpr, dExpr: term) (fBody, dBody: term): term =
    let fa,da = phiDelta a and fb,db = phiDelta b and dx = Sym.d x in
    let y = Sym.gen x.name and ytps = [fa;da] in
    let ytp = `Tuple ytps in
    let yproj i = Raw.proj ytps i (Raw.var ytp y) in
    let binder body =
      (* let y = φM in let x = fst y in let dx = snd y in ... *)
      Raw.letIn ytp fb y fExpr
        (Raw.letIn fa fb x (yproj 0) (Raw.letIn da fb dx (yproj 1) body))
    in binder fBody, binder dBody

  (* φ(let x = M in N) = let x = φM in φN
   * δ(let x = M in N) = let x = φM in δN *)
  let letIn (a: tp) (b: tp) (x: sym) (fExpr, dExpr: term) (fBody, dBody: term): term =
    let fA = phi a and fB, dB = phiDelta b in
    Raw.letIn fA fB x fExpr fBody, Raw.letIn fA dB x fExpr dBody

  (* φ(λx.M) = λx.φM        δ(λx.M) = λx dx. δM *)
  let lam (a: tp) (b: tp) (x: sym) (fBody, dBody: term): term =
    let fA,dA = phiDelta a and fB,dB = phiDelta b in
    Raw.lam fA fB x fBody,
    Raw.lam fA (`Fn (dA, dB)) x (Raw.lam dA dB (Sym.d x) dBody)

  (* φ(M N) = φM φN         δ(M N) = δM φN δN *)
  let app (a: tp) (b: tp) (fFnc, dFnc: term) (fArg, dArg: term): term =
    let fA,dA = phiDelta a and fB,dB = phiDelta b in
    Raw.app fA fB fFnc fArg,
    Raw.app dA dB (Raw.app fA (`Fn (dA, dB)) dFnc fArg) dArg

  (* φ(M,N) = φM,φN         δ(M,N) = δM,δN *)
  let tuple (elts: (tp * term) list) =
    Raw.tuple (List.map (fun (a, (fE,_)) -> phi a, fE) elts),
    Raw.tuple (List.map (fun (a, (_,dE)) -> delta a, dE) elts)

  (* φ(πᵢ M) = πᵢ φM        δ(πᵢ M) = πᵢ δM *)
  let proj (tps: tp list) (i: int) (fTerm, dTerm: term) =
    let ftps, dtps = List.(map phiDelta tps |> split) in
    Raw.proj ftps i fTerm, Raw.proj dtps i dTerm

  (* φ({M}) = {φM}          δ({M}) = ∅ *)
  let set (a: tp) (elts: term list) =
    Raw.set (phi a) (List.map fst elts), Raw.set (phi a) []

  (* φ(M ∨ N) = φM ∨ φN     δ(M ∨ N) = δM ∨ δN *)
  let union (a: tp semilat) (terms: term list) =
    Raw.union (phiLat a) (List.map fst terms),
    Raw.union (deltaLat a) (List.map snd terms)

  let forIn (a: tp) (b: tp semilat) (x: sym) (fExpr, dExpr: term) (fBody, dBody: term) =
    let fa,da = phiDelta a and fb,db = phiDeltaLat b in
    (* φ(for (x in M) N) = for (x in φM) let dx = 0 x in φN *)
    Raw.forIn fa fb x fExpr
      (Raw.letIn da fb (Sym.d x) (zero a (Raw.var fa x)) fBody),
    (* δ(for (x in φM) φN)
     * =  (for (x in δM) let dx = 0 x in φN)
     *   ∨ for (x in φM ∪ δM) let dx = 0 x in δN
     *
     * However, this assumes ΦB = ΔB and that ⊕ = ∨. This is false for
     * functional types. In that case the correct strategy is to eta-expand.
     * However, I don't expect to be using forIn at functional types in any real
     * programs, so I just fail if the type isn't first-order. *)
    if not (firstOrder (b :> modtp))
    then todo "forIn only implemented for first-order data"
    else if not (fb = db) then impossible "this shouldn't happen"
    else
      let loopBody body = Raw.letIn da fb (Sym.d x) (zero a (Raw.var fa x)) body in
      Raw.union fb
        (* for (x in δM) let dx = 0 x in φN *)
        [ Raw.forIn fa fb x dExpr (loopBody fBody)
        (* for (x in M ∪ δM) let dx = 0 x in δN *)
        ; Raw.forIn fa fb x (Raw.union (`Set fa) [fExpr;dExpr]) (loopBody dBody) ]

  (* φ(fix M) = fastfix φM
   * δ(fix M) = zero ⊥ = ⊥ *)
  let fix (a: tp semilat) (fFunc, dFunc: term) =
    let fa,da = phiDeltaLat a in
    Raw.fastfix fa fFunc, Raw.union da [] 
end
