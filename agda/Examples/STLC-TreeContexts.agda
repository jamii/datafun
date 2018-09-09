module Examples.STLC-TreeContexts where

open import Prelude
open import Cat
open import TreeSet hiding (_∈_)

-- A structure for representing typing contexts basically has to be a
-- semilattice/cocartesian category generated by Type.
record Context (Type : Set) i j : Set (suc (i ⊔ j)) where
  field cat : Cat i j
  field sums : Sums cat
  private instance -cat = cat; -sums = sums
  Cx = Obj cat
  field hyp : Type → Cx         -- Singleton contexts.

  -- Membership is definable as being a superset of singleton, which saves us
  -- from needing more axioms/fields.
  infix 3 _∈_
  _∈_ : Type → Cx → Set _
  x ∈ X = hyp x ≤ X

  -- Finally, we need an axiom that singletons are "join prime"; equivalently,
  -- that (a ∈_) is a coproduct-preserving functor into Set. Interestingly, the
  -- categorical generalization of "join prime" coincides with the topological
  -- property of being a _connected_ space:
  -- https://ncatlab.org/nlab/show/connected+object
  field split : ∀{a X Y} → a ∈ (X ∨ Y) → a ∈ X ⊎ a ∈ Y

  -- We might also want to know that ⊥ is empty:
  -- field split⊥ : ∀{a} → a ∈ ⊥ → ∅
  -- In practice, this hasn't come up yet.

  infixr 4 _∷_
  _∷_ : Type → Cx → Cx
  a ∷ X = hyp a ∨ X

infixr 6 _⊃_
data Type : Set where
  _⊃_ _*_ : (a b : Type) → Type
  base : Type

 -- Contexts
instance tree-cxs = trees (discrete Type)

TreeContext : Context Type _ _
Context.cat TreeContext = tree-cxs
Context.sums TreeContext = it
Context.hyp TreeContext = leaf
Context.split TreeContext (≤node p) = p

import Contexts
SetContext : Context Type _ _
Context.cat SetContext = Contexts.cxs Type
Context.sums SetContext = Contexts.cx-sums Type
Context.hyp SetContext = Contexts.hyp Type
Context.split SetContext {a} x∈X∨Y with x∈X∨Y a refl
... | inj₁ x = inj₁ λ { _ refl → x }
... | inj₂ x = inj₂ λ { _ refl → x }

module STLC {i j} (context : Context Type i j) where
  open Context context
  instance -cat = cat
  instance -cxsums = sums

  
  -- Terms
  infix 1 _⊢_
  data _⊢_ (X : Cx) : Type → Set (i ⊔ j) where
    var : ∀{a} (x : a ∈ X) → X ⊢ a
    app : ∀{a b} (M : X ⊢ a ⊃ b) (N : X ⊢ a) → X ⊢ b
    lam : ∀{a b} (M : a ∷ X ⊢ b) → X ⊢ a ⊃ b

  -- Renaming terms.
  rename : ∀{X Y a} -> X ≤ Y -> X ⊢ a -> Y ⊢ a
  rename ρ (var x) = var (x ∙ ρ)
  rename ρ (app M N) = app (rename ρ M) (rename ρ N)
  rename ρ (lam M) = lam (rename (map∨ id ρ) M)

  -- Substitution.
  infix 1 _⊢*_
  _⊢*_ : (X Y : Cx) → Set _
  X ⊢* Y = ∀{a} → a ∈ Y → X ⊢ a

  ∷/⊢* : ∀{X Y} → X ⊢* Y → ∀{a} → a ∷ X ⊢* a ∷ Y
  ∷/⊢* {X}{Y} σ {a} {b} v with split v
  ... | inj₁ x = var (x ∙ in₁)
  ... | inj₂ y = rename in₂ (σ y)

  subst : ∀{X Y a} → X ⊢* Y → Y ⊢ a → X ⊢ a
  subst σ (var x) = σ x
  subst σ (app M N) = app (subst σ M) (subst σ N)
  subst σ (lam M) = lam (subst (∷/⊢* σ) M)
