module Prosets where

open import Prelude
open import Cat

Proset : Set1
Proset = Cat zero zero

prosets : Cat _ _
prosets = cats {zero} {zero}

-- A type for monotone maps.
infix 1 _⇒_
_⇒_ : Rel Proset _
_⇒_ = Fun

-- Decidability of the hom-sets of a proset/category.
Decidable≤ : Proset -> Set
Decidable≤ P = Decidable (Hom P)

dec× : ∀{i j P Q} -> Dec {i} P -> Dec {j} Q -> Dec (P × Q)
dec× (yes p) (yes q) = yes (p , q)
dec× (no ¬p) _ = no (λ { (x , y) -> ¬p x })
dec× _ (no ¬p) = no (λ { (x , y) -> ¬p y })

decidable× : ∀{i j k l A B} {R : Rel {i} A j} {S : Rel {k} B l}
           -> Decidable R -> Decidable S -> Decidable (rel× R S)
decidable× P Q (a₁ , b₁) (a₂ , b₂) = dec× (P a₁ a₂) (Q b₁ b₂)

decidable+ : ∀{i j k l A B} {R : Rel {i} A j} {S : Rel {k} B l}
           -> Decidable R -> Decidable S -> Decidable (rel+ R S)
decidable+ P Q (inj₁ x) (inj₁ y) with P x y
... | yes p = yes (rel₁ p)
... | no ¬p = no (λ { (rel₁ x) → ¬p x })
decidable+ P Q (inj₂ x) (inj₂ y) with Q x y
... | yes p = yes (rel₂ p)
... | no ¬p = no (λ { (rel₂ x) → ¬p x })
decidable+ P Q (inj₁ x) (inj₂ y) = no λ {()}
decidable+ P Q (inj₂ y) (inj₁ x) = no λ {()}

-- The proset of monotone maps between two prosets. Like the category of
-- functors and natural transformations, but without the naturality condition.
proset→ : (A B : Proset) -> Proset
proset→ A B .Obj = Fun A B
-- We use this definition rather than the more usual pointwise definition
-- because it makes more sense when generalized to categories.
proset→ A B .Hom F G = ∀ {x y} -> Hom A x y -> Hom B (ap F x) (ap G y)
proset→ A B .ident {F} = map F
proset→ A B .compo {F}{G}{H} F≤G G≤H {x}{y} x≤y = compo B (F≤G x≤y) (G≤H (ident A))

-- Now we can show that prosets is cartesian closed.
instance
  proset-cc : CC prosets
  CC.products proset-cc = cat-products
  _⇨_   {{proset-cc}} = proset→
  -- apply or eval
  apply {{proset-cc}} .ap (F , a) = ap F a
  apply {{proset-cc}} .map (F≤G , a≤a') = F≤G a≤a'
  -- curry or λ
  curry {{proset-cc}} {A}{B}{C} F .ap a .ap b    = ap F (a , b)
  curry {{proset-cc}} {A}{B}{C} F .ap a .map b   = map F (ident A , b)
  curry {{proset-cc}} {A}{B}{C} F .map a≤a' b≤b' = map F (a≤a' , b≤b')

-- If B has sums, then (A ⇒ B) has sums too.
module _ {A B : Proset} (bs : Sums B) where
  private instance b' = B; bs' = bs
  proset→-sums : Sums (proset→ A B)
  _∨_ {{proset→-sums}} f g .ap x = ap f x ∨ ap g x
  _∨_ {{proset→-sums}} f g .map x≤y = ∨-map (map f x≤y) (map g x≤y)
  in₁ {{proset→-sums}} {f}{g} x≤y = map f x≤y • in₁
  in₂ {{proset→-sums}} {f}{g} x≤y = map g x≤y • in₂
  [_,_] {{proset→-sums}} {f}{g}{h} f≤h g≤h x≤y = [ f≤h x≤y , g≤h x≤y ]
  init {{proset→-sums}} = const-fun init
  init≤ {{proset→-sums}} _ = init≤


-- The "equivalence quotient" of a proset. Not actually a category of
-- isomorphisms, since we don't require that the arrows be inverses. But if we
-- were gonna put equations on arrows, that's what we'd require.
isos : Proset -> Proset
isos C .Obj = Obj C
isos C .Hom x y = Hom C x y × Hom C y x
isos C .ident = ident C , ident C
isos C .compo (f₁ , f₂) (g₁ , g₂) = compo C f₁ g₁ , compo C g₂ f₂

isos≤? : ∀ A -> Decidable≤ A -> Decidable≤ (isos A)
isos≤? _ test x y = dec× (test x y) (test y x)


-- The trivial proset.
⊤-proset : Proset
⊤-proset = record { Obj = ⊤ ; Hom = λ { tt tt → ⊤ } ; ident = tt ; compo = λ { tt tt → tt } }

-- The booleans, ordered false < true.
data bool≤ : Rel Bool zero where
  bool-refl : Reflexive bool≤
  false<true : bool≤ false true

bool≤? : Decidable bool≤
bool≤? false true = yes false<true
bool≤? true  false = no λ {()}
bool≤? false false = yes bool-refl
bool≤? true  true = yes bool-refl

false≤ : ∀{a} -> bool≤ false a
false≤ {false} = bool-refl
false≤ {true}  = false<true

instance
  bools : Cat _ _
  Obj bools = Bool
  Hom bools = bool≤
  ident bools = bool-refl
  compo bools bool-refl x = x
  compo bools false<true bool-refl = false<true

  -- I never thought I'd commit a proof by exhaustive case analysis,
  -- but I was wrong.
  bool-sums : Sums bools
  _∨_ {{bool-sums}} true  _ = true
  _∨_ {{bool-sums}} _  true = true
  _∨_ {{bool-sums}} _ _ = false
  in₁ {{bool-sums}} {false} = false≤
  in₁ {{bool-sums}} {true}  = bool-refl
  in₂ {{bool-sums}} {_} {false} = false≤
  in₂ {{bool-sums}} {false} {true} = bool-refl
  in₂ {{bool-sums}} {true} {true} = bool-refl
  [_,_] {{bool-sums}} {false} {false} x y = false≤
  [_,_] {{bool-sums}} {_}     {true}  {false} x ()
  [_,_] {{bool-sums}} {true}  {false} {false} () y
  [_,_] {{bool-sums}} {false} {true}  {true}  x y = bool-refl
  [_,_] {{bool-sums}} {true}  {false} {true}  x y = bool-refl
  [_,_] {{bool-sums}} {true}  {true}  {true}  x y = bool-refl
  init {{bool-sums}} = false
  init≤ {{bool-sums}} = false≤

antisym:bool≤ : Antisymmetric _≡_ bool≤
antisym:bool≤ bool-refl _ = Eq.refl
antisym:bool≤ false<true ()