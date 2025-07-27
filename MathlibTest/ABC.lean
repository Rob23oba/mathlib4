import Mathlib.Tactic.Ring

example : Even 0 := by grind
example : (Even 0 → p) → p := by grind
example : Even 0 := Even.zero
