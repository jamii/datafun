{-# OPTIONS --postfix-projections #-}
module Prosets where

open import Prelude
open import Cat
open import Decidability
open import Monads

Proset : Set1
Proset = Cat zero zero

prosets : Cat _ _
prosets = cats {zero} {zero}

-- A type for monotone maps.
-- TODO: move this into Cats.agda and generalize it to categories?
infix 1 _⇒_
_⇒_ : Rel Proset _
_⇒_ = Fun


-- The proset of monotone maps between two prosets. Like the category of
-- functors and natural transformations, but without the naturality condition.
proset→ : ∀{i j k l} (A : Cat i j) (B : Cat k l) -> Cat (i ⊔ j ⊔ k ⊔ l) _
proset→ A B .Obj = Fun A B
-- The more usual pointwise definition makes it harder to prove that prosets is
-- cartesian closed.
proset→ A B .Hom F G = ∀ {x y} -> Hom A x y -> Hom B (ap F x) (ap G y)
proset→ A B .ident {F} = map F
proset→ A B .compo {F}{G}{H} F≤G G≤H {x}{y} x≤y = compo B (F≤G x≤y) (G≤H (ident A))

-- Now we can show that prosets is cartesian closed.
instance
  proset-cc : ∀{i} -> CC (cats {i}{i})
  CC.products proset-cc = cat-products
  _⇨_   {{proset-cc}} = proset→
  -- apply or eval
  apply {{proset-cc}} .ap (F , a) = ap F a
  apply {{proset-cc}} .map (F≤G , a≤a') = F≤G a≤a'
  -- curry or λ
  curry {{proset-cc}} {A}{B}{C} F .ap a .ap b    = ap F (a , b)
  curry {{proset-cc}} {A}{B}{C} F .ap a .map b   = map F (ident A , b)
  curry {{proset-cc}} {A}{B}{C} F .map a≤a' b≤b' = map F (a≤a' , b≤b')

-- -- If B has sums, then (A ⇒ B) has sums too.
-- module _ {A B : Proset} (bs : Sums B) where
--   private instance b' = B; bs' = bs
--   -- TODO: do I use this anywhere?
--   proset→-sums : Sums (proset→ A B)
--   lub proset→-sums F G .a∨b .ap x = ap F x ∨ ap G x
--   lub proset→-sums F G .a∨b .map x≤y = map∨ (map F x≤y) (map G x≤y)
--   lub proset→-sums F G .∨I₁ x≤y = map F x≤y • in₁
--   lub proset→-sums F G .∨I₂ x≤y = map G x≤y • in₂
--   lub proset→-sums F G .∨E F≤H G≤H x≤y = [ F≤H x≤y , G≤H x≤y ]
--   bottom proset→-sums = constant bot , λ _ → bot≤


-- The "equivalence quotient" of a proset. Not actually a category of
-- isomorphisms, since we don't require that the arrows be inverses. But *if* we
-- were gonna put equations on arrows, that's what we'd require.
isos : ∀{i j} -> Cat i j -> Cat i j
isos C .Obj = Obj C
isos C .Hom x y = Iso C x y
isos C .ident = ident C , ident C
isos C .compo (f₁ , f₂) (g₁ , g₂) = compo C f₁ g₁ , compo C g₂ f₂

isos≤? : ∀{i j} (A : Cat i j) -> Decidable≤ A -> Decidable≤ (isos A)
isos≤? _ test x y = dec× (test x y) (test y x)

-- If (f : a -> b) is monotone, then (f : isos a -> isos b) is also monotone.
Isos : ∀{i j} -> cats {i}{j} ≤ cats
Isos = Fun: isos (λ f → fun (λ { (x , y) -> map f x , map f y }))

instance
  -- This comonad factors into an adjunction to groupoids, I believe.
  Isos-comonad : ∀{i j} -> Comonad (Isos {i}{j})
  Comonad.dup Isos-comonad = fun ⟨ id , swap ⟩
  Comonad.extract Isos-comonad = fun proj₁

 -- Some lemmas about isos.
⊤⇒isos : ⊤ ⇒ isos ⊤
⊤⇒isos = fun (λ {TT  → TT , TT})

juggle : ∀{i j k l} {A B C D}
       -> Σ {i}{j} A C × Σ {k}{l} B D
       -> Σ (A × B) λ { (a , b) -> C a × D b }
juggle ((a , c) , (b , d)) = (a , b) , (c , d)

∧/isos : ∀{A B} -> isos A ∧ isos B ⇒ isos (A ∧ B)
∧/isos = fun juggle

isos/∧ : ∀{A B} -> isos (A ∧ B) ⇒ isos A ∧ isos B
isos/∧ = fun juggle

isos/∨ : ∀{A B} -> isos (A ∨ B) ⇒ isos A ∨ isos B
isos/∨ .ap = id
isos/∨ .map (rel₁ p , rel₁ q) = rel₁ (p , q)
isos/∨ .map (rel₂ p , rel₂ q) = rel₂ (p , q)

isojuggle : ∀{A B C D} -> (isos A ∧ B) ∧ (isos C ∧ D) ⇒ isos (A ∧ C) ∧ (B ∧ D)
isojuggle = fun juggle • map∧ ∧/isos id

module _ {i j} {{A : Cat i j}} {{Prod : Products A}} where
  ∧≈ : ∀{a b a' b' : Obj A} -> a ≈ a' -> b ≈ b' -> (a ∧ b) ≈ (a' ∧ b')
  ∧≈ f g = map Isos functor∧ .map (juggle (f , g))

module _ {i j} {{A : Cat i j}} {{Sum : Sums A}} where
  juggle∨≈ : ∀{a b c d : Obj A} -> (a ∨ b) ∨ (c ∨ d) ≈ (a ∨ c) ∨ (b ∨ d)
  juggle∨≈ = juggle∨ , juggle∨

  -- Used in ChangeSem/Types*.agda
  ∨≈ : ∀{a b a' b' : Obj A} -> a ≈ a' -> b ≈ b' -> (a ∨ b) ≈ (a' ∨ b')
  ∨≈ f g = map Isos functor∨ .map (juggle (f , g))


-- Lifts an arbitrary function over an antisymmetric domain into a monotone map
-- over its discrete preorder.
antisym⇒ : ∀{A B} -> Antisymmetric _≡_ (Hom A) -> (Obj A -> Obj B) -> isos A ⇒ B
antisym⇒ {A}{B} antisym f = Fun: f helper
  where helper : ∀{x y} -> Hom (isos A) x y -> Hom B (f x) (f y)
        helper (x , y) with antisym x y
        ... | refl = ident B


-- The booleans, ordered false < true.
data bool≤ : Rel Bool zero where
  f≤* : ∀{a} -> bool≤ false a
  t≤t : bool≤ true true

instance
  bools : Cat _ _
  Obj bools = Bool
  Hom bools = bool≤
  ident bools {false} = f≤*
  ident bools {true}  = t≤t
  compo bools f≤* _   = f≤*
  compo bools t≤t t≤t = t≤t

  bool-sums : Sums bools
  lub bool-sums false y = y / f≤* / id / λ p q → q
  lub bool-sums true true = true / t≤t / t≤t / λ p q → p
  lub bool-sums true false = true / t≤t / f≤* / λ p q → p
  bottom bool-sums = false , f≤*

  bool≤? : Decidable bool≤
  bool≤? false _     = yes f≤*
  bool≤? true  true  = yes t≤t
  bool≤? true  false = no λ {()}

antisym:bool≤ : Antisymmetric _≡_ bool≤
antisym:bool≤ f≤* f≤* = Eq.refl
antisym:bool≤ t≤t _   = Eq.refl

-- bool⇒ : ∀{A a b} -> Hom A a b -> bools ⇒ A
-- bool⇒ {_}{a}{b} a≤b .ap x = if x then b else a
-- bool⇒ {A} a≤b .map refl = ident A
-- bool⇒ a≤b .map false<true = a≤b


-- Natural numbers
open import Data.Nat as Nat using (ℕ; z≤n; s≤s) renaming (_≤_ to _≤'_; _⊔_ to _⊔'_)
import Data.Nat.Properties

instance
  ℕ≤ : Proset
  ℕ≤ = Cat: ℕ Nat._≤_ Data.Nat.Properties.≤-refl Data.Nat.Properties.≤-trans

  -- ℕ forms a semilattice with 0 and ⊔ (max).
  -- TODO: revisit this with copattern syntax.
  ℕ-sums : Sums ℕ≤
  lub ℕ-sums ℕ.zero y = y / z≤n / id / λ p q → q
  lub ℕ-sums x ℕ.zero = x / id / z≤n / λ p q → p
  lub ℕ-sums (ℕ.suc x) (ℕ.suc y) with lub ℕ-sums x y
  ... | x∨y / ∨I₁ / ∨I₂ / ∨E
      = ℕ.suc x∨y / s≤s ∨I₁ / s≤s ∨I₂ / λ { (s≤s p) (s≤s q) → s≤s (∨E p q) }
  bottom ℕ-sums = 0 , z≤n
