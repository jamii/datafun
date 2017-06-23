module Prelude where

-- STANDARD LIBRARY STUFF
open import Level renaming (zero to lzero; suc to lsuc) public

open import Data.Bool using (Bool; true; false; not; if_then_else_) public
open import Data.Empty using (⊥; ⊥-elim) public
open import Data.Maybe using (Maybe; just; nothing; maybe) public
open import Data.Nat using (ℕ; zero; suc) public
open import Data.Product using (Σ; proj₁; proj₂; Σ-syntax; ∃; ∄; _×_; _,_; ,_) public
open import Data.Sum using (_⊎_; inj₁; inj₂) public
open import Data.Unit using (⊤; tt) public
open import Function using (_∘_; flip; _on_) public
open import Relation.Nullary using (¬_; Dec; yes; no) public

module Eq where
  open import Relation.Binary.PropositionalEquality public

open Eq using (_≡_) public

-- MY STUFF
open import Composition public