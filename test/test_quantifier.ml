open Srk
open Syntax
open OUnit
open Quantifier
open Test_pervasives

let simsat_ground simsat () =
  assert_equal `Sat (simsat srk (Ctx.mk_leq x y))

let simsat1 simsat () =
  let phi =
    Ctx.mk_forall ~name:"r" `TyReal
      (Ctx.mk_exists ~name:"s" `TyReal
         (Ctx.mk_lt (Ctx.mk_var 1 `TyReal) (Ctx.mk_var 0 `TyReal)))
  in
  assert_equal `Sat (simsat srk phi)

let sim1 name simsat () =
  let phi =
    let x = Ctx.mk_var 1 `TyInt in
    let y = Ctx.mk_var 0 `TyInt in
    let open Infix in
    Ctx.mk_exists ~name:"x" `TyInt
      (Ctx.mk_forall ~name:"y" `TyInt
         ((Ctx.mk_not ((y < x) && (x < (int 2))))
          || x = (int 1)))
  in
  assert_bool name (simsat srk phi = `Sat)

let sim2 name simsat () =
  let phi =
    let x = Ctx.mk_var 1 `TyInt in
    let y = Ctx.mk_var 0 `TyInt in
    let open Infix in
    Ctx.mk_exists ~name:"x" `TyInt
      (Ctx.mk_forall ~name:"y" `TyInt
         (x <= (Ctx.mk_ite ((int 0) < y) y (Ctx.mk_neg y))))
  in
  assert_bool name (simsat srk phi = `Sat)

let mbp1 () =
  let phi =
    let open Infix in
    let s = Ctx.mk_var 0 `TyReal in
    (Ctx.mk_exists ~name:"s" `TyReal
       (s = r && (s <= (int 0) || r <= (int 1))))
  in
  let psi =
    let open Infix in
    r <= (int 1)
  in
  assert_equiv_formula (qe_mbp srk phi) psi

let mbp2 () =
  let phi =
    let s = Ctx.mk_var 0 `TyReal in
    Ctx.mk_forall ~name:"s" `TyReal
      (Ctx.mk_leq r (Ctx.mk_ite
                       (Ctx.mk_lt (int 0) s)
                       s
                       (Ctx.mk_neg s)))
  in
  let psi = Ctx.mk_leq r (int 0) in
  assert_equiv_formula (qe_mbp srk phi) psi

let strategy1 name normalize winning_strategy check_strategy () =
  let phi =
    let open Infix in
    (((int 0) <= x) && (x < y))
    || ((x < (int 0)) && (y < x))
  in
  let phi =
    normalize srk (mk_forall_const srk xsym
      (mk_exists_const srk ysym phi))
  in
  match winning_strategy srk phi with
  | `Sat strategy ->
    assert_bool name (check_strategy srk phi strategy)
  | _ -> assert false

let strategy2 name normalize winning_strategy check_strategy () =
  let phi =
    let open Infix in
    (y < w) && (y < x)
    && (w < z) && (x < z)
  in
  let phi =
    normalize srk (mk_forall_const srk wsym
      (mk_forall_const srk xsym
        (mk_exists_const srk ysym
          (mk_exists_const srk zsym phi))))
  in
  match winning_strategy srk phi with
  | `Sat strategy ->
    assert_bool name (check_strategy srk phi strategy)
  | _ -> assert false

let strategy3 name normalize winning_strategy check_strategy () =
  let phi =
    let open Infix in
    (((int 0) < x) && (x < y)) || ((x <= (int 0)) && (y < x))
  in
  let phi =
    normalize srk (mk_forall_const srk xsym (mk_exists_const srk ysym phi))
  in
  match winning_strategy srk phi with
  | `Sat strategy ->
    assert_bool name (check_strategy srk phi strategy)
  | _ -> assert false

let strategy4 name normalize winning_strategy check_strategy () =
  let phi =
    let open Infix in
    Ctx.mk_ite ((int 0) <= y) (x <= y) (y < x)
  in
  let phi =
    normalize srk (mk_exists_const srk xsym (mk_forall_const srk ysym phi))
  in
  match winning_strategy srk phi with
  | `Sat strategy ->
    assert_bool name (check_strategy srk phi strategy)
  | _ -> assert false
  

let cg_normalize = CoarseGrainStrategyImprovement.normalize 
let fg_normalize = FineGrainStrategyImprovement.normalize
let cg_simsat = CoarseGrainStrategyImprovement.simsat
let fg_simsat = FineGrainStrategyImprovement.simsat
let cg_simsat_forward = CoarseGrainStrategyImprovement.simsat_forward
let fg_simsat_forward = FineGrainStrategyImprovement.simsat_forward
let cg_winning_strategy = CoarseGrainStrategyImprovement.winning_strategy
let fg_winning_strategy = FineGrainStrategyImprovement.winning_strategy
let cg_check_strategy = CoarseGrainStrategyImprovement.check_strategy
let fg_check_strategy = FineGrainStrategyImprovement.check_strategy

let suite = "Quantifier" >::: [
    (* Coarse Grain Simsat tests *)
    "simsat_ground_coarse_grain" >:: simsat_ground cg_simsat;
    "simsat_forward_ground_coarse_grain" >:: simsat_ground cg_simsat_forward;
    "simsat1_coarse_grain" >:: simsat1 cg_simsat;
    "sim1_coarse_grain" >:: sim1 "sim1_coarse_grain" cg_simsat;
    "sim2_coarse_grain" >:: sim2 "sim2_coarse_grain" cg_simsat;

    (* Fine Grain Simsat tests *)
    "simsat_ground_fine_grain" >:: simsat_ground fg_simsat;
    (* "simsat_forward_ground_fine_grain" >:: simsat_ground fg_simsat_forward;    (* not implemented *) *)
    "simsat1_fine_grain" >:: simsat1 fg_simsat;
    "sim1_fine_grain" >:: sim1 "sim1_fine_grain" fg_simsat;
    "sim2_fine_grain" >:: sim2 "sim2_fine_grain" fg_simsat;

    (* Coarse Grain Strategy synthesis tests *)
(*  Extract strategy is not yet implemented for coarse grain strategies
    "strategy1_coarse_grain" >:: strategy1 "strategy1_coarse_grain" cg_normalize cg_winning_strategy cg_check_strategy;
    "strategy2_coarse_grain" >:: strategy2 "strategy2_coarse_grain" cg_normalize cg_winning_strategy cg_check_strategy; *)

    (* Fine Grain Strategy synthesis tests *)
    "strategy1_fine_grain" >:: strategy1 "strategy1_fine_grain" fg_normalize fg_winning_strategy fg_check_strategy;
    "strategy2_fine_grain" >:: strategy2 "strategy2_fine_grain" fg_normalize fg_winning_strategy fg_check_strategy;
    "strategy3_fine_grain" >:: strategy3 "strategy3_fine_grain" fg_normalize fg_winning_strategy fg_check_strategy;
    "strategy4_fine_grain" >:: strategy4 "strategy4_fine_grain" fg_normalize fg_winning_strategy fg_check_strategy;

    (* Quantifier Elimination via Model Based Projection tests *)
    "mbp1" >:: mbp1;
    "mbp2" >:: mbp2;
  ]
