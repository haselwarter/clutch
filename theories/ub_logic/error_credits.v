(** This file implements error credits, following the ideas from
    the implementation of later credits
 *)

From Coq Require Import Reals RIneq Psatz.
From clutch.prelude Require Export base classical Reals_ext NNRbar.
From iris.prelude Require Import options.
From iris.proofmode Require Import tactics.
From iris.algebra Require Export auth numbers.
From iris.base_logic.lib Require Import iprop own.

Import uPred.


(** ** Non-negative real numbers with addition as the operation. *)
Section NNR.
  Canonical Structure nonnegrealO : ofe := leibnizO nonnegreal.

  Local Instance R_valid_instance : Valid (nonnegreal)  := λ r, (r < 1)%R.
  Local Instance R_validN_instance : ValidN (nonnegreal) := λ _ r, (r < 1)%R.
  Local Instance R_pcore_instance : PCore (nonnegreal) := λ _, Some nnreal_zero.
  Local Instance R_op_instance : Op (nonnegreal) := λ x y, nnreal_plus x y.
  Local Instance R_equiv : Equiv nonnegreal := λ x y, x = y.

  Definition R_op (x y : nonnegreal) : x ⋅ y = nnreal_plus x y := eq_refl.

  Lemma Rle_0_le_minus (x y : R) : (x <= y)%R -> (0 <= y - x)%R.
  Proof.
    lra.
  Qed.

  Lemma R_included (x y : nonnegreal) : x ≼ y ↔ (x <= y)%R.
  Proof.
    split; intros.
    - destruct x.
      destruct y.
      simpl.
      rewrite /included in H.
      destruct H as ((z & Hz) & H).
      rewrite R_op /nnreal_plus in H.
      simplify_eq.
      lra.
    - rewrite /included.
      destruct x as (x & Hx).
      destruct y as (y & Hy).
      simpl in H.
      eexists ({| nonneg := y - x ; cond_nonneg := Rle_0_le_minus x y H |}).
      rewrite R_op/=.
      rewrite /equiv/R_equiv/=.
      apply nnreal_ext.
      simpl.
      lra.
  Qed.


  (*
  Local Instance RR_valid_instance : Valid (R)  := λ _ , True.
  Local Instance RR_validN_instance : ValidN (R) := λ _ _, True.
  Local Instance RR_pcore_instance : PCore (R) := λ _, Some 0%R.
  Local Instance RR_op_instance : Op (nonnegreal) := λ x y, Rplus x y.
  Local Instance RR_equiv : Equiv R := λ x y, x = y.
  Lemma RR_ra_mixin : RAMixin R.
  *)

  Lemma R_ra_mixin : RAMixin nonnegreal.
  Proof.
    apply ra_total_mixin; try by eauto.
    - solve_proper.
    - solve_proper.
    - intros ? ? ?.
      rewrite /equiv/R_equiv.
      apply nnreal_ext; simpl; lra.
    - intros ? ?.
      rewrite /equiv/R_equiv.
      apply nnreal_ext; simpl; lra.
    - intros ?.
      rewrite /equiv/R_equiv.
      apply nnreal_ext; simpl; lra.
    - intros ? ? ?.
      apply R_included; simpl; lra.
    - rewrite /valid/R_valid_instance.
      rewrite /op/R_op_instance /=.
      intros ? ? ?.
      pose (cond_nonneg y). lra.
  Qed.

  (* Massive hack to override Coq reals *)
  Definition id {A} := (λ (a : A), a).

  Canonical Structure realR : cmra := discreteR nonnegreal R_ra_mixin.

  Global Instance R_cmra_discrete : CmraDiscrete realR.
  Proof. apply discrete_cmra_discrete. Qed.

  Local Instance R_unit_instance : Unit nonnegreal := nnreal_zero.
  Lemma R_ucmra_mixin : @UcmraMixin nonnegreal _ _ _ _ _ R_unit_instance.
  Proof. split.
         - rewrite /valid.
           rewrite /R_valid_instance.
           simpl. lra.
         - rewrite /LeftId.
           intro.
           rewrite /equiv/R_equiv/op/R_op_instance/=.
           apply nnreal_ext; simpl; lra.
         - rewrite /pcore/R_pcore_instance; auto.
  Qed.

  Canonical Structure realUR : ucmra := Ucmra nonnegreal R_ucmra_mixin.

  Lemma nonnegreal_add_cancel_l : ∀ x y z : nonnegreal, nnreal_plus z x = nnreal_plus z y ↔ x = y.
  Proof.
    intros ? ? ?; split; intro H.
    - apply nnreal_ext.
      rewrite /nnreal_plus in H.
      simplify_eq.
      lra.
    - simplify_eq; auto.
  Qed.


  Global Instance R_cancelable (x : nonnegreal) : Cancelable x.
  Proof. by intros ???? ?%nonnegreal_add_cancel_l. Qed.

  (* FIXME: unused (it should factor out the proof in ec_credit_supply) *)
  Lemma R_local_update (x y x' y' : nonnegreal) :
    (y' <= y)%R -> nnreal_plus x y' = nnreal_plus x' y → (x,y) ~l~> (x',y').
  Proof.
    intros ??; apply (local_update_unital_discrete x y x' y') => z H1 H2.
    compute in H2; simplify_eq; simpl.
    destruct y, x', y', z; simplify_eq; simpl.
    split.
    - compute; compute in *.
      eapply Rle_lt_trans; [| eapply H1].
      lra.
    - compute.
      apply nnreal_ext; simpl in *; lra.
  Qed.

  (* This one has a higher precendence than [is_op_op] so we get a [+] instead
     of an [⋅].
  Global Instance nat_is_op (n1 n2 : nat) : IsOp (n1 + n2) n1 n2.
  Proof. done. Qed.
  *)
End NNR.



(** The ghost state for error credits *)
Class ecGpreS (Σ : gFunctors) := EcGpreS {
  ecGpreS_inG :: inG Σ (authR realUR)
}.

Class ecGS (Σ : gFunctors) := EcGS {
  ecGS_inG : inG Σ (authR realUR);
  ecGS_name : gname;
}.

Global Hint Mode ecGS - : typeclass_instances.
Local Existing Instances ecGS_inG ecGpreS_inG.

Definition ecΣ := #[GFunctor (authR (realUR))].
Global Instance subG_ecΣ {Σ} : subG ecΣ Σ → ecGpreS Σ.
Proof. solve_inG. Qed.


(** The user-facing error resource, denoting ownership of [ε] error credits. *)
Local Definition ec_def `{!ecGS Σ} (ε : nonnegreal) : iProp Σ := own ecGS_name (◯ ε).
Local Definition ec_aux : seal (@ec_def). Proof. by eexists. Qed.
Definition ec := ec_aux.(unseal).
Local Definition ec_unseal :
  @ec = @ec_def := ec_aux.(seal_eq).
Global Arguments ec {Σ _} ε.

Notation "'€'  ε" := (ec ε) (at level 1).

(** The internal authoritative part of the credit ghost state,
  tracking how many credits are available in total.
  Users should not directly interface with this. *)
Local Definition ec_supply_def `{!ecGS Σ} (ε : nonnegreal) : iProp Σ := own ecGS_name (● ε).
Local Definition ec_supply_aux : seal (@ec_supply_def). Proof. by eexists. Qed.
Definition ec_supply := ec_supply_aux.(unseal).
Local Definition ec_supply_unseal :
  @ec_supply = @ec_supply_def := ec_supply_aux.(seal_eq).
Global Arguments ec_supply {Σ _} ε.


Section error_credit_theory.
  Context `{!ecGS Σ}.
  Implicit Types (P Q : iProp Σ).

  (** Later credit rules *)
  Lemma ec_split ε1 ε2 :
    € (nnreal_plus ε1 ε2) ⊣⊢ € ε1 ∗ € ε2.
  Proof.
    rewrite ec_unseal /ec_def.
    rewrite -own_op auth_frag_op //=.
  Qed.

  Lemma ec_zero : ⊢ |==> € nnreal_zero.
  Proof.
    rewrite ec_unseal /ec_def. iApply own_unit.
  Qed.

  Lemma ec_supply_bound ε1 ε2 :
    ec_supply ε2 -∗ € ε1 -∗ ⌜(ε1 <= ε2)%R⌝.
  Proof.
    rewrite ec_unseal /ec_def.
    rewrite ec_supply_unseal /ec_supply_def.
    iIntros "H1 H2".
    iDestruct (own_valid_2 with "H1 H2") as "%Hop".
    iPureIntro. eapply auth_both_valid_discrete in Hop as [Hlt _].
    by eapply R_included.
  Qed.

  Lemma ec_decrease_supply ε1 ε2 :
    ec_supply (ε1 + ε2)%NNR -∗ € ε1 -∗ |==> ec_supply ε2.
  Proof.
    rewrite ec_unseal /ec_def.
    rewrite ec_supply_unseal /ec_supply_def.
    iIntros "H1 H2".
    iMod (own_update_2 with "H1 H2") as "Hown".
    { eapply auth_update. eapply (R_local_update _ _ ε2 nnreal_zero); [apply cond_nonneg|].
      apply nnreal_ext; simpl; lra. }
    by iDestruct "Hown" as "[Hm _]".
  Qed.

  Lemma ec_increase_supply (ε1 ε2 : nonnegreal) :
    ⌜(ε1 + ε2 < 1)%R ⌝ ∗ ec_supply ε1 -∗ |==> ec_supply (ε1 + ε2)%NNR ∗ € ε2.
  Proof.
    rewrite ec_unseal /ec_def.
    rewrite ec_supply_unseal /ec_supply_def.
    iIntros "[%Hsum H]".
    iMod (own_update with "H") as "[$ $]"; [|done].
    eapply (auth_update_alloc _ ). (* (ε1 + ε2)%NNR ε2%NNR). *)
    apply (local_update_unital_discrete _ _ _ _) => z H1 H2.
    split.
    - compute. done.
    - compute. apply nnreal_ext. simpl.
      compute in H2.
      simpl in H2.
      rewrite Rplus_comm.
      apply Rplus_eq_compat_l.
      rewrite H2 /=.
      lra.
  Qed.



  Lemma ec_split_supply ε1 ε2 :
    ec_supply ε2 -∗ € ε1 -∗ ∃ ε3, ⌜ε2 = (ε1 + ε3)%NNR⌝.
  Proof.
    rewrite ec_unseal /ec_def.
    rewrite ec_supply_unseal /ec_supply_def.
    iIntros "H1 H2".
    iDestruct (own_valid_2 with "H1 H2") as "%Hop".
    iPureIntro. eapply auth_both_valid_discrete in Hop as [Hlt _].
    apply R_included in Hlt.
    eexists (nnreal_minus ε2 ε1 Hlt).
    apply nnreal_ext.
    simpl; lra.
  Qed.

  Lemma ec_weaken {ε1 : nonnegreal} (ε2 : nonnegreal) :
    (ε2 <= ε1)%R → € ε1 -∗ € ε2.
  Proof.
    intros H.
    set diff := mknonnegreal (ε1 - ε2) (Rle_0_le_minus ε2 ε1 H).
    assert (ε1 = nnreal_plus ε2 diff) as H2.
    { apply nnreal_ext; simpl; lra. }
    rewrite H2.
    rewrite ec_split. iIntros "[$ _]".
  Qed.

  Lemma ec_spend (ε : nonnegreal) : (1 <= nonneg ε)%R -> € ε -∗ False.
  Proof.
    iIntros (Hge1) "Hε".
    rewrite ec_unseal /ec_def.
    iAssert (✓ (◯ ε))%I with "[Hε]" as "%Hε" ; [by iApply own_valid|].
    apply auth_frag_valid_1 in Hε.
    exfalso; destruct ε; compute in *.
    lra.
  Qed.

  Global Instance ec_timeless ε : Timeless (€ ε).
  Proof.
    rewrite ec_unseal /ec_def. apply _.
  Qed.

  Global Instance ec_0_persistent : Persistent (€ nnreal_zero).
  Proof.
    rewrite ec_unseal /ec_def. apply _.
  Qed.

  Global Instance from_sep_ec_add ε1 ε2 :
    FromSep (€ (nnreal_plus ε1 ε2)) (€ ε1) (€ ε2) | 0.
  Proof.
    by rewrite /FromSep ec_split.
  Qed.

  Global Instance into_sep_ec_add ε1 ε2 :
    IntoSep (€ (nnreal_plus ε1 ε2)) (€ ε1) (€ ε2) | 0.
  Proof.
    by rewrite /IntoSep ec_split.
  Qed.

  Global Instance combine_sep_as_ec_add ε1 ε2 :
    CombineSepAs (€ ε1) (€ ε2) (€ (nnreal_plus ε1 ε2)) | 0.
  Proof.
    by rewrite /CombineSepAs ec_split.
  Qed.

End error_credit_theory.

Lemma ec_alloc `{!ecGpreS Σ} (n : nonnegreal) :
  ⌜(nonneg n < 1)%R ⌝ ⊢ |==> ∃ _ : ecGS Σ, ec_supply n ∗ € n.
Proof.
  iIntros.
  rewrite ec_unseal /ec_def ec_supply_unseal /ec_supply_def.
  iMod (own_alloc (● n ⋅ ◯ n)) as (γEC) "[H● H◯]".
  - apply auth_both_valid_2.
    + compute. destruct n; simpl in H. lra.
    + apply R_included; lra.
  - pose (C := EcGS _ _ γEC).
    iModIntro. iExists C. iFrame.
Qed.
