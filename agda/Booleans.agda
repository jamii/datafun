open import Prelude
open import Cat

module Booleans where

-- The booleans, ordered false < true.
data bool≤ : Rel Bool zero where
  f≤* : ∀{a} -> bool≤ false a
  t≤t : bool≤ true true

instance
  bools : Proset
  Obj bools = Bool
  Hom bools = bool≤
  ident bools {false} = f≤*
  ident bools {true}  = t≤t
  compo bools f≤* _   = f≤*
  compo bools t≤t t≤t = t≤t

  bool-sums : Sums bools
  bottom bool-sums = false , f≤*
  lub bool-sums false y = y / f≤* / id / λ p q → q
  lub bool-sums true true = true / t≤t / t≤t / λ p q → p
  lub bool-sums true false = true / t≤t / f≤* / λ p q → p

  bool≤? : Decidable bool≤
  bool≤? false _     = yes f≤*
  bool≤? true  true  = yes t≤t
  bool≤? true  false = no λ {()}

antisym:bool≤ : Antisymmetric _≡_ bool≤
antisym:bool≤ f≤* f≤* = Eq.refl
antisym:bool≤ t≤t _   = Eq.refl

-- Used in ChangeSem.Terms3
bool⇒ : ∀{A a b} -> Hom A a b -> bools ⇒ A
bool⇒ {a = a}{b} a≤b .ap x = if x then b else a
bool⇒ a≤b .map {.false} {true} f≤* = a≤b
bool⇒ {A} a≤b .map {.false} {false} f≤* = ident A
bool⇒ {A} a≤b .map t≤t = ident A

module _ {Γ : Proset} {{A : Proset}} where
  private instance zub = cat→ Γ A
  If : (F G : Γ ⇒ A) → G ≤ F → Γ ⇒ (bools ⇨ A)
  If F G F≤G .ap γ = bool⇒ (F≤G {γ})
  If F G F≤G .map γ≤η {true} = map F γ≤η
  If F G F≤G .map γ≤η {false} = map G γ≤η

When : ∀{{A}} {{S : Sums A}} {Γ} → Γ ⇒ bools → Γ ⇒ A → Γ ⇒ A
When cond then = call (If then (constant ⊥) ⊥≤) cond
