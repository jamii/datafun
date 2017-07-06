module Cartesian where

open import Prelude

-- Technically, none of this needs Cat. It just needs SetRel! Hm...

cat:× : ∀{i j} (A B : Cat i j) -> Cat i j
Obj (cat:× A B) = Obj A × Obj B
Hom (cat:× A B) (a₁ , b₁) (a₂ , b₂) = (a₁ ⇨ a₂) × (b₁ ⇨ b₂)
identity (isCat (cat:× (cat A) (cat B))) = id , id
compose (isCat (cat:× (cat A) (cat B))) (f₁ , f₂) (g₁ , g₂) = f₁ • g₁ , f₂ • g₂

-- TODO: check that instance search for these things will actually work and not
-- blow up and produce horrible error messages.
record Products {i}{j} (C : Cat i j) (_⊗_ : Obj C -> Obj C -> Obj C) : Set (i ⊔ j) where
  constructor Products:
  field π₁ : ∀{A B} -> A ⊗ B ⇨ A
  field π₂ : ∀{A B} -> A ⊗ B ⇨ B
  field ⟨_,_⟩ : ∀{A B C} -> A ⇨ B -> A ⇨ C -> A ⇨ B ⊗ C

  -- asFunctor : Functor (cat:× C C) C
  -- asFunctor = {!!}

record Sums {i}{j} (C : Cat i j) (_⊕_ : Obj C -> Obj C -> Obj C) : Set (i ⊔ j) where
  constructor Sums:
  field in₁ : ∀{A B} -> A ⇨ A ⊕ B
  field in₂ : ∀{A B} -> B ⇨ A ⊕ B
  field [_,_] : ∀{A B C} -> A ⇨ C -> B ⇨ C -> A ⊕ B ⇨ C

-- TODO: maybe I should call this "Exponentials"?
record Closed {i}{j} (C : Cat i j)
              (_⊗_ : (a b : Obj C) -> Obj C)
              (hom : (a b : Obj C) -> Obj C)
              : Set (i ⊔ j) where
  constructor Closed:
  field apply : ∀{A B} -> hom A B ⊗ A ⇨ B
  field curry : ∀{A B C} -> (A ⊗ B) ⇨ C -> A ⇨ (hom B C)

open Products {{...}} public
open Sums {{...}} public
open Closed {{...}} public


-- Instances for cat:Set.
instance
  products:Set : ∀{i} -> Products (cat:Set i) _×_
  ⟨_,_⟩ {{products:Set {i}}} = <_,_> where open import Data.Product
  π₁ {{products:Set}} = proj₁
  π₂ {{products:Set}} = proj₂

  sums:Set : ∀{i} -> Sums (cat:Set i) _⊎_
  in₁ {{sums:Set}} = inj₁
  in₂ {{sums:Set}} = inj₂
  [_,_] {{sums:Set}} = Data.Sum.[_,_] where import Data.Sum
