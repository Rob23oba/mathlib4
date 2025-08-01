/-
Copyright (c) 2024 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios
-/
import Mathlib.SetTheory.Ordinal.FixedPoint

/-!
# Veblen hierarchy

We define the two-arguments Veblen function, which satisfies `veblen 0 a = ω ^ a` and that for
`o ≠ 0`, `veblen o` enumerates the common fixed points of `veblen o'` for `o' < o`.

We use this to define two important functions on ordinals: the epsilon function `ε_ o = veblen 1 o`,
and the gamma function `Γ_ o` enumerating the fixed points of `veblen · 0`.

## Main definitions

* `veblenWith`: The Veblen hierarchy with a specified initial function.
* `veblen`: The Veblen hierarchy starting with `ω ^ ·`.

## Notation

The following notation is scoped to the `Ordinal` namespace.

- `ε_ o` is notation for `veblen 1 o`. `ε₀` is notation for `ε_ 0`.
- `Γ_ o` is notation for `gamma o`. `Γ₀` is notation for `Γ_ 0`.

## TODO

- Prove that `ε₀` and `Γ₀` are countable.
- Prove that the exponential principal ordinals are the epsilon ordinals (and 0, 1, 2, ω).
- Prove that the ordinals principal under `veblen` are the gamma ordinals (and 0).
-/

noncomputable section

open Order

universe u

namespace Ordinal

variable {f : Ordinal.{u} → Ordinal.{u}} {o o₁ o₂ a b : Ordinal.{u}}

/-! ### Veblen function with a given starting function -/

section veblenWith

/-- `veblenWith f o` is the `o`-th function in the Veblen hierarchy starting with `f`. This is
defined so that

- `veblenWith f 0 = f`.
- `veblenWith f o` for `o ≠ 0` enumerates the common fixed points of `veblenWith f o'` over all
  `o' < o`.
-/
@[pp_nodot]
def veblenWith (f : Ordinal.{u} → Ordinal.{u}) (o : Ordinal.{u}) : Ordinal.{u} → Ordinal.{u} :=
  if o = 0 then f else derivFamily fun (⟨x, _⟩ : Set.Iio o) ↦ veblenWith f x
termination_by o

@[simp]
theorem veblenWith_zero (f : Ordinal → Ordinal) : veblenWith f 0 = f := by
  rw [veblenWith, if_pos rfl]

theorem veblenWith_of_ne_zero (f : Ordinal → Ordinal) (h : o ≠ 0) :
    veblenWith f o = derivFamily fun x : Set.Iio o ↦ veblenWith f x.1 := by
  rw [veblenWith, if_neg h]

/-- `veblenWith f o` is always normal for `o ≠ 0`. See `isNormal_veblenWith` for a version which
assumes `IsNormal f`. -/
theorem isNormal_veblenWith' (f : Ordinal → Ordinal) (h : o ≠ 0) : IsNormal (veblenWith f o) := by
  rw [veblenWith_of_ne_zero f h]
  exact isNormal_derivFamily _

variable (hf : IsNormal f)
include hf

/-- `veblenWith f o` is always normal whenever `f` is. See `isNormal_veblenWith'` for a version
which does not assume `IsNormal f`. -/
theorem isNormal_veblenWith (o : Ordinal) : IsNormal (veblenWith f o) := by
  obtain rfl | h := eq_or_ne o 0
  · rwa [veblenWith_zero]
  · exact isNormal_veblenWith' f h

protected alias IsNormal.veblenWith := isNormal_veblenWith

theorem veblenWith_veblenWith_of_lt (h : o₁ < o₂) (a : Ordinal) :
    veblenWith f o₁ (veblenWith f o₂ a) = veblenWith f o₂ a := by
  let x : Set.Iio _ := ⟨o₁, h⟩
  rw [veblenWith_of_ne_zero f h.bot_lt.ne',
    derivFamily_fp (f := fun y : Set.Iio o₂ ↦ veblenWith f y.1) (i := x)]
  exact hf.veblenWith x

theorem veblenWith_succ (o : Ordinal) : veblenWith f (succ o) = deriv (veblenWith f o) := by
  rw [deriv_eq_enumOrd (hf.veblenWith o), veblenWith_of_ne_zero f (succ_ne_zero _),
    derivFamily_eq_enumOrd]
  · apply congr_arg
    ext a
    rw [Set.mem_iInter]
    use fun ha ↦ ha ⟨o, lt_succ o⟩
    rintro (ha : _ = _) ⟨b, hb : b < _⟩
    obtain rfl | hb := lt_succ_iff_eq_or_lt.1 hb
    · rw [Function.mem_fixedPoints_iff, ha]
    · rw [← ha]
      exact veblenWith_veblenWith_of_lt hf hb _
  · exact fun o ↦ hf.veblenWith o.1

theorem veblenWith_right_strictMono (o : Ordinal) : StrictMono (veblenWith f o) :=
  (hf.veblenWith o).strictMono

@[simp]
theorem veblenWith_lt_veblenWith_iff_right : veblenWith f o a < veblenWith f o b ↔ a < b :=
  (veblenWith_right_strictMono hf o).lt_iff_lt

@[simp]
theorem veblenWith_le_veblenWith_iff_right : veblenWith f o a ≤ veblenWith f o b ↔ a ≤ b :=
  (veblenWith_right_strictMono hf o).le_iff_le

theorem veblenWith_injective (o : Ordinal) : Function.Injective (veblenWith f o) :=
  (veblenWith_right_strictMono hf o).injective

@[simp]
theorem veblenWith_inj : veblenWith f o a = veblenWith f o b ↔ a = b :=
  (veblenWith_injective hf o).eq_iff

theorem right_le_veblenWith (o a : Ordinal) : a ≤ veblenWith f o a :=
  (veblenWith_right_strictMono hf o).le_apply

theorem veblenWith_left_monotone (a : Ordinal) : Monotone (veblenWith f · a) := by
  rw [monotone_iff_forall_lt]
  intro o₁ o₂ h
  rw [← veblenWith_veblenWith_of_lt hf h]
  exact (veblenWith_right_strictMono hf o₁).monotone (right_le_veblenWith hf o₂ a)

theorem veblenWith_pos (hp : 0 < f 0) : 0 < veblenWith f o a := by
  have H (b) : 0 < veblenWith f 0 b := by
    rw [veblenWith_zero]
    exact hp.trans_le (hf.monotone (Ordinal.zero_le _))
  obtain rfl | h := Ordinal.eq_zero_or_pos o
  · exact H a
  · rw [← veblenWith_veblenWith_of_lt hf h]
    exact H _

theorem veblenWith_zero_strictMono (hp : 0 < f 0) : StrictMono (veblenWith f · 0) := by
  intro o₁ o₂ h
  dsimp only
  rw [← veblenWith_veblenWith_of_lt hf h, veblenWith_lt_veblenWith_iff_right hf]
  exact veblenWith_pos hf hp

theorem veblenWith_zero_lt_veblenWith_zero (hp : 0 < f 0) :
    veblenWith f o₁ 0 < veblenWith f o₂ 0 ↔ o₁ < o₂ :=
  (veblenWith_zero_strictMono hf hp).lt_iff_lt

theorem veblenWith_zero_le_veblenWith_zero (hp : 0 < f 0) :
    veblenWith f o₁ 0 ≤ veblenWith f o₂ 0 ↔ o₁ ≤ o₂ :=
  (veblenWith_zero_strictMono hf hp).le_iff_le

theorem veblenWith_zero_inj (hp : 0 < f 0) : veblenWith f o₁ 0 = veblenWith f o₂ 0 ↔ o₁ = o₂ :=
  (veblenWith_zero_strictMono hf hp).injective.eq_iff

theorem left_le_veblenWith (hp : 0 < f 0) (o a : Ordinal) : o ≤ veblenWith f o a :=
  (veblenWith_zero_strictMono hf hp).le_apply.trans <|
    (veblenWith_right_strictMono hf _).monotone (Ordinal.zero_le _)

theorem IsNormal.veblenWith_zero (hp : 0 < f 0) : IsNormal (veblenWith f · 0) := by
  rw [isNormal_iff_strictMono_limit]
  refine ⟨veblenWith_zero_strictMono hf hp, fun o ho a IH ↦ ?_⟩
  rw [veblenWith_of_ne_zero f ho.ne_bot, derivFamily_zero]
  apply nfpFamily_le fun l ↦ ?_
  suffices ∃ b < o, List.foldr _ 0 l ≤ veblenWith f b 0 by
    obtain ⟨b, hb, hb'⟩ := this
    exact hb'.trans (IH b hb)
  induction l with
  | nil => use 0; simpa using ho.bot_lt
  | cons a l IH =>
    obtain ⟨b, hb, hb'⟩ := IH
    refine ⟨_, ho.succ_lt (max_lt a.2 hb), ((veblenWith_right_strictMono hf _).monotone <|
      hb'.trans <| veblenWith_left_monotone hf _ <|
        (le_max_right a.1 b).trans (le_succ _)).trans ?_⟩
    rw [veblenWith_veblenWith_of_lt hf]
    rw [lt_succ_iff]
    exact le_max_left _ b

theorem cmp_veblenWith :
    cmp (veblenWith f o₁ a) (veblenWith f o₂ b) =
    match cmp o₁ o₂ with
    | .eq => cmp a b
    | .lt => cmp a (veblenWith f o₂ b)
    | .gt => cmp (veblenWith f o₁ a) b := by
  obtain h | rfl | h := lt_trichotomy o₁ o₂
  on_goal 2 => simp [(veblenWith_right_strictMono hf _).cmp_map_eq]
  all_goals
    conv_lhs => rw [← veblenWith_veblenWith_of_lt hf h]
    simp [h.cmp_eq_lt, h.cmp_eq_gt, (veblenWith_right_strictMono hf _).cmp_map_eq]

/-- `veblenWith f o₁ a < veblenWith f o₂ b` iff one of the following holds:
* `o₁ = o₂` and `a < b`
* `o₁ < o₂` and `a < veblenWith f o₂ b`
* `o₁ > o₂` and `veblenWith f o₁ a < b` -/
theorem veblenWith_lt_veblenWith_iff :
    veblenWith f o₁ a < veblenWith f o₂ b ↔
      o₁ = o₂ ∧ a < b ∨ o₁ < o₂ ∧ a < veblenWith f o₂ b ∨ o₂ < o₁ ∧ veblenWith f o₁ a < b := by
  rw [← cmp_eq_lt_iff, cmp_veblenWith hf]
  aesop (add simp lt_asymm)

/-- `veblenWith f o₁ a ≤ veblenWith f o₂ b` iff one of the following holds:
* `o₁ = o₂` and `a ≤ b`
* `o₁ < o₂` and `a ≤ veblenWith f o₂ b`
* `o₁ > o₂` and `veblenWith f o₁ a ≤ b` -/
theorem veblenWith_le_veblenWith_iff :
    veblenWith f o₁ a ≤ veblenWith f o₂ b ↔
      o₁ = o₂ ∧ a ≤ b ∨ o₁ < o₂ ∧ a ≤ veblenWith f o₂ b ∨ o₂ < o₁ ∧ veblenWith f o₁ a ≤ b := by
  rw [← not_lt, ← cmp_eq_gt_iff, cmp_veblenWith hf]
  aesop (add simp [not_lt_of_ge, lt_asymm])

/-- `veblenWith f o₁ a = veblenWith f o₂ b` iff one of the following holds:
* `o₁ = o₂` and `a = b`
* `o₁ < o₂` and `a = veblenWith f o₂ b`
* `o₁ > o₂` and `veblenWith f o₁ a = b` -/
theorem veblenWith_eq_veblenWith_iff :
    veblenWith f o₁ a = veblenWith f o₂ b ↔
      o₁ = o₂ ∧ a = b ∨ o₁ < o₂ ∧ a = veblenWith f o₂ b ∨ o₂ < o₁ ∧ veblenWith f o₁ a = b := by
  rw [← cmp_eq_eq_iff, cmp_veblenWith hf]
  aesop (add simp lt_asymm)

end veblenWith

/-! ### Veblen function -/

section veblen

/-- `veblen o` is the `o`-th function in the Veblen hierarchy starting with `ω ^ ·`. That is:

- `veblen 0 a = ω ^ a`.
- `veblen o` for `o ≠ 0` enumerates the fixed points of `veblen o'` for `o' < o`.
-/
@[pp_nodot]
def veblen : Ordinal.{u} → Ordinal.{u} → Ordinal.{u} :=
  veblenWith (ω ^ ·)

@[simp]
theorem veblen_zero : veblen 0 = fun a ↦ ω ^ a := by
  rw [veblen, veblenWith_zero]

theorem veblen_zero_apply (a : Ordinal) : veblen 0 a = ω ^ a := by
  rw [veblen_zero]

theorem veblen_of_ne_zero (h : o ≠ 0) : veblen o = derivFamily fun x : Set.Iio o ↦ veblen x.1 :=
  veblenWith_of_ne_zero _ h

theorem isNormal_veblen (o : Ordinal) : IsNormal (veblen o) :=
  (isNormal_opow one_lt_omega0).veblenWith o

theorem veblen_veblen_of_lt (h : o₁ < o₂) (a : Ordinal) : veblen o₁ (veblen o₂ a) = veblen o₂ a :=
  veblenWith_veblenWith_of_lt (isNormal_opow one_lt_omega0) h a

theorem veblen_succ (o : Ordinal) : veblen (succ o) = deriv (veblen o) :=
  veblenWith_succ (isNormal_opow one_lt_omega0) o

theorem veblen_right_strictMono (o : Ordinal) : StrictMono (veblen o) :=
  veblenWith_right_strictMono (isNormal_opow one_lt_omega0) o

@[simp]
theorem veblen_lt_veblen_iff_right : veblen o a < veblen o b ↔ a < b :=
  veblenWith_lt_veblenWith_iff_right (isNormal_opow one_lt_omega0)

@[simp]
theorem veblen_le_veblen_iff_right : veblen o a ≤ veblen o b ↔ a ≤ b :=
  veblenWith_le_veblenWith_iff_right (isNormal_opow one_lt_omega0)

theorem veblen_injective (o : Ordinal) : Function.Injective (veblen o) :=
  veblenWith_injective (isNormal_opow one_lt_omega0) o

@[simp]
theorem veblen_inj : veblen o a = veblen o b ↔ a = b :=
  (veblen_injective o).eq_iff

theorem right_le_veblen (o a : Ordinal) : a ≤ veblen o a :=
  right_le_veblenWith (isNormal_opow one_lt_omega0) o a

theorem veblen_left_monotone (o : Ordinal) : Monotone (veblen · o) :=
  veblenWith_left_monotone (isNormal_opow one_lt_omega0) o

@[simp]
theorem veblen_pos : 0 < veblen o a :=
  veblenWith_pos (isNormal_opow one_lt_omega0) (by simp)

theorem veblen_zero_strictMono : StrictMono (veblen · 0) :=
  veblenWith_zero_strictMono (isNormal_opow one_lt_omega0) (by simp)

@[simp]
theorem veblen_zero_lt_veblen_zero : veblen o₁ 0 < veblen o₂ 0 ↔ o₁ < o₂ :=
  veblen_zero_strictMono.lt_iff_lt

@[simp]
theorem veblen_zero_le_veblen_zero : veblen o₁ 0 ≤ veblen o₂ 0 ↔ o₁ ≤ o₂ :=
  veblen_zero_strictMono.le_iff_le

@[simp]
theorem veblen_zero_inj : veblen o₁ 0 = veblen o₂ 0 ↔ o₁ = o₂ :=
  veblen_zero_strictMono.injective.eq_iff

theorem left_le_veblen (o a : Ordinal) : o ≤ veblen o a :=
  left_le_veblenWith (isNormal_opow one_lt_omega0) (by simp) o a

theorem isNormal_veblen_zero : IsNormal (veblen · 0) :=
  (isNormal_opow one_lt_omega0).veblenWith_zero (by simp)

theorem cmp_veblen : cmp (veblen o₁ a) (veblen o₂ b) =
    match cmp o₁ o₂ with
    | .eq => cmp a b
    | .lt => cmp a (veblen o₂ b)
    | .gt => cmp (veblen o₁ a) b :=
  cmp_veblenWith (isNormal_opow one_lt_omega0)

/-- `veblen o₁ a < veblen o₂ b` iff one of the following holds:
* `o₁ = o₂` and `a < b`
* `o₁ < o₂` and `a < veblen o₂ b`
* `o₁ > o₂` and `veblen o₁ a < b` -/
theorem veblen_lt_veblen_iff :
    veblen o₁ a < veblen o₂ b ↔
      o₁ = o₂ ∧ a < b ∨ o₁ < o₂ ∧ a < veblen o₂ b ∨ o₂ < o₁ ∧ veblen o₁ a < b :=
  veblenWith_lt_veblenWith_iff (isNormal_opow one_lt_omega0)

/-- `veblen o₁ a ≤ veblen o₂ b` iff one of the following holds:
* `o₁ = o₂` and `a ≤ b`
* `o₁ < o₂` and `a ≤ veblen o₂ b`
* `o₁ > o₂` and `veblen o₁ a ≤ b` -/
theorem veblen_le_veblen_iff :
    veblen o₁ a ≤ veblen o₂ b ↔
      o₁ = o₂ ∧ a ≤ b ∨ o₁ < o₂ ∧ a ≤ veblen o₂ b ∨ o₂ < o₁ ∧ veblen o₁ a ≤ b :=
  veblenWith_le_veblenWith_iff (isNormal_opow one_lt_omega0)

/-- `veblen o₁ a ≤ veblen o₂ b` iff one of the following holds:
* `o₁ = o₂` and `a = b`
* `o₁ < o₂` and `a = veblen o₂ b`
* `o₁ > o₂` and `veblen o₁ a = b` -/
theorem veblen_eq_veblen_iff :
    veblen o₁ a = veblen o₂ b ↔
      o₁ = o₂ ∧ a = b ∨ o₁ < o₂ ∧ a = veblen o₂ b ∨ o₂ < o₁ ∧ veblen o₁ a = b :=
  veblenWith_eq_veblenWith_iff (isNormal_opow one_lt_omega0)

end veblen

/-! ### Epsilon function -/

/-- The epsilon function enumerates the fixed points of `ω ^ ⬝`.
This is an abbreviation for `veblen 1`. -/
abbrev epsilon := veblen 1

@[inherit_doc] scoped notation "ε_ " => epsilon

/-- `ε₀` is the first fixed point of `ω ^ ⬝`, i.e. the supremum of `ω`, `ω ^ ω`, `ω ^ ω ^ ω`, … -/
scoped notation "ε₀" => ε_ 0

theorem epsilon_eq_deriv (o : Ordinal) : ε_ o = deriv (fun a ↦ ω ^ a) o := by
  rw [epsilon, ← succ_zero, veblen_succ, veblen_zero]

theorem epsilon0_eq_nfp : ε₀ = nfp (fun a ↦ ω ^ a) 0 := by
  rw [epsilon_eq_deriv, deriv_zero_right]

theorem epsilon_succ_eq_nfp (o : Ordinal) : ε_ (succ o) = nfp (fun a ↦ ω ^ a) (succ (ε_ o)) := by
  rw [epsilon_eq_deriv, epsilon_eq_deriv, deriv_succ]

theorem epsilon0_le_of_omega0_opow_le (h : ω ^ o ≤ o) : ε₀ ≤ o := by
  rw [epsilon0_eq_nfp]
  exact nfp_le_fp (fun _ _ ↦ (opow_le_opow_iff_right one_lt_omega0).2) (Ordinal.zero_le o) h

@[simp]
theorem omega0_opow_epsilon (o : Ordinal) : ω ^ ε_ o = ε_ o := by
  rw [epsilon_eq_deriv, (isNormal_opow one_lt_omega0).deriv_fp]

/-- `ε₀` is the limit of `0`, `ω ^ 0`, `ω ^ ω ^ 0`, … -/
theorem lt_epsilon0 : o < ε₀ ↔ ∃ n : ℕ, o < (fun a ↦ ω ^ a)^[n] 0 := by
  rw [epsilon0_eq_nfp, lt_nfp_iff]

/-- `ω ^ ω ^ … ^ 0 < ε₀` -/
theorem iterate_omega0_opow_lt_epsilon0 (n : ℕ) : (fun a ↦ ω ^ a)^[n] 0 < ε₀ := by
  rw [epsilon0_eq_nfp]
  apply iterate_lt_nfp (isNormal_opow one_lt_omega0).strictMono
  simp

theorem omega0_lt_epsilon (o : Ordinal) : ω < ε_ o := by
  apply lt_of_lt_of_le _ <| (veblen_right_strictMono _).monotone (Ordinal.zero_le o)
  simpa using iterate_omega0_opow_lt_epsilon0 2

theorem natCast_lt_epsilon (n : ℕ) (o : Ordinal) : n < ε_ o :=
  (nat_lt_omega0 n).trans <| omega0_lt_epsilon o

theorem epsilon_pos (o : Ordinal) : 0 < ε_ o :=
  veblen_pos

/-! ### Gamma function -/

/-- The gamma function enumerates the fixed points of `veblen · 0`.

Of particular importance is `Γ₀ = gamma 0`, the Feferman-Schütte ordinal. -/
def gamma (o : Ordinal) : Ordinal :=
  deriv (veblen · 0) o

@[inherit_doc]
scoped notation "Γ_ " => gamma

/-- The Feferman-Schütte ordinal `Γ₀` is the smallest fixed point of `veblen · 0`, i.e. the supremum
of `veblen ε₀ 0`, `veblen (veblen ε₀ 0) 0`, etc. -/
scoped notation "Γ₀" => Γ_ 0

theorem isNormal_gamma : IsNormal gamma :=
  isNormal_deriv _

theorem strictMono_gamma : StrictMono gamma :=
  isNormal_gamma.strictMono

theorem monotone_gamma : Monotone gamma :=
  isNormal_gamma.monotone

@[simp]
theorem gamma_lt_gamma : Γ_ a < Γ_ b ↔ a < b :=
  strictMono_gamma.lt_iff_lt

@[simp]
theorem gamma_le_gamma : Γ_ a ≤ Γ_ b ↔ a ≤ b :=
  strictMono_gamma.le_iff_le

@[simp]
theorem gamma_inj : Γ_ a = Γ_ b ↔ a = b :=
  strictMono_gamma.injective.eq_iff

@[simp]
theorem veblen_gamma_zero (o : Ordinal) : veblen (Γ_ o) 0 = Γ_ o :=
  isNormal_veblen_zero.deriv_fp o

theorem gamma0_eq_nfp : Γ₀ = nfp (veblen · 0) 0 :=
  deriv_zero_right _

theorem gamma_succ_eq_nfp (o : Ordinal) : Γ_ (succ o) = nfp (veblen · 0) (succ (Γ_ o)) :=
  deriv_succ _ _

theorem gamma0_le_of_veblen_le (h : veblen o 0 ≤ o) : Γ₀ ≤ o := by
  rw [gamma0_eq_nfp]
  exact nfp_le_fp (veblen_left_monotone 0) (Ordinal.zero_le o) h

/-- `Γ₀` is the limit of `0`, `veblen 0 0`, `veblen (veblen 0 0) 0`, … -/
theorem lt_gamma0 : o < Γ₀ ↔ ∃ n : ℕ, o < (fun a ↦ veblen a 0)^[n] 0 := by
  rw [gamma0_eq_nfp, lt_nfp_iff]

/-- `veblen (veblen … (veblen 0 0) … 0) 0 < Γ₀` -/
theorem iterate_veblen_lt_gamma0 (n : ℕ) : (fun a ↦ veblen a 0)^[n] 0 < Γ₀ := by
  rw [gamma0_eq_nfp]
  apply iterate_lt_nfp veblen_zero_strictMono
  simp

theorem epsilon0_lt_gamma (o : Ordinal) : ε₀ < Γ_ o := by
  apply lt_of_lt_of_le _ <| (gamma_le_gamma.2 (Ordinal.zero_le _))
  simpa using iterate_veblen_lt_gamma0 2

theorem omega0_lt_gamma (o : Ordinal) : ω < Γ_ o :=
  (omega0_lt_epsilon 0).trans (epsilon0_lt_gamma o)

theorem natCast_lt_gamma (n : ℕ) : n < Γ_ o :=
  (nat_lt_omega0 n).trans (omega0_lt_gamma o)

@[simp]
theorem gamma_pos : 0 < Γ_ o :=
  natCast_lt_gamma 0

end Ordinal
