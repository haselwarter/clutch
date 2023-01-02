From Coq Require Import Reals Psatz.
From Coquelicot Require Import Series Hierarchy Lim_seq Rbar.
From stdpp Require Import option.
From stdpp Require Export countable.
From self.prelude Require Import base Coquelicot_ext stdpp_ext classical.
Import Hierarchy.

Open Scope R.

(** A theory of (in)finite series over countable types.  *)
Section countable_sum.
  Context `{Countable A}.

  Implicit Types f g : A → R.

  (** 'Traverses' the type in the order given by decoding [0, 1, 2, ...] *)
  Definition countable_sum (f : A → R) :=
    λ (n : nat), from_option f 0 (encode_inv_nat n).

  Lemma countable_sum_0 f m :
    (∀ n, f n = 0) → countable_sum f m = 0.
  Proof. intros. rewrite /countable_sum. destruct (encode_inv_nat _); eauto. Qed.

  Lemma countable_sum_ge_0 f m :
    (∀ n, 0 <= f n) → 0 <= countable_sum f m.
  Proof. intros. rewrite /countable_sum. destruct (encode_inv_nat _)=>//=. Qed.

  Lemma countable_sum_ext f g m :
    (∀ n, f n = g n) → countable_sum f m = countable_sum g m.
  Proof. intros ?. rewrite /countable_sum. destruct (encode_inv_nat _) => //=. Qed.

  Lemma countable_sum_le f g m :
    (∀ n, f n <= g n) → countable_sum f m <= countable_sum g m.
  Proof. intros ?. rewrite /countable_sum. destruct (encode_inv_nat _) =>//=. Qed.

  Lemma countable_sum_scal c f n :
    countable_sum (λ x, scal c (f x)) n = scal c (countable_sum f n).
  Proof.
    intros. rewrite //= /countable_sum /scal //= /mult //=.
    destruct (encode_inv_nat _) => //=; lra.
  Qed.

  Lemma countable_sum_plus f g n :
    countable_sum (λ x, f x + g x) n = countable_sum f n + countable_sum g n.
  Proof.
    intros. rewrite //=/countable_sum; destruct (encode_inv_nat) => //=. lra.
  Qed.

  Lemma countable_sum_minus f g n :
    countable_sum (λ x, f x - g x) n = countable_sum f n - countable_sum g n.
  Proof.
    intros. rewrite //=/countable_sum; destruct (encode_inv_nat) => //=. lra.
  Qed.

  Lemma countable_sum_mult f g n :
    countable_sum (λ x, f x * g x) n = countable_sum f n * countable_sum g n.
  Proof.
    intros. rewrite //=/countable_sum; destruct (encode_inv_nat) => //=. lra.
  Qed.

  Lemma countable_sum_Rabs f n :
    countable_sum (λ x, Rabs (f x)) n = Rabs (countable_sum f n).
  Proof.
    intros. rewrite //=/countable_sum; destruct (encode_inv_nat _) => //=. rewrite Rabs_R0 //=.
  Qed.

  Lemma countable_sum_scal_l f c n :
    countable_sum (λ x, c * f x) n = c * countable_sum f n.
  Proof. apply countable_sum_scal. Qed.

  Lemma countable_sum_scal_r f c n :
    countable_sum (λ x, f x * c) n = countable_sum f n * c.
  Proof.
    intros. rewrite //=/countable_sum; destruct (encode_inv_nat) => //=. lra. Qed.

  Global Instance countable_sum_Proper:
    Proper (pointwise_relation A (@eq R) ==> pointwise_relation nat (@eq R)) countable_sum.
  Proof. intros ?? ? x. rewrite /countable_sum. destruct (encode_inv_nat _); eauto. Qed.

  Global Instance countable_sum_Proper' :
    Proper (pointwise_relation A (@eq R) ==> eq ==> eq) countable_sum.
  Proof. intros ?? ? ? ??. subst. eapply countable_sum_ext; eauto. Qed.

  (** TODO: more lifted lemmas on [sumC] *)
  Definition sumC_n (f : A → R) := sum_n (countable_sum f).

End countable_sum.


Section series.
  Context `{Countable A}.

  Implicit Types f g : A → R.

  (** Lifting of the Coquliecot predicates for working with series *)
  Definition is_seriesC f := is_series (countable_sum f).
  Definition ex_seriesC f := ∃ a, is_seriesC f a.
  Definition SeriesC f := Series (countable_sum f).

  Lemma is_seriesC_0 f :
    (∀ n, f n = 0) → is_seriesC f 0.
  Proof.
    intros ?. apply is_series_0=> n.
    rewrite /countable_sum. destruct (encode_inv_nat _)=>/=; auto.
  Qed.

  Lemma is_seriesC_ext f g l :
    (∀ n, f n = g n) → is_seriesC g l → is_seriesC f l.
  Proof.
    intros ?. apply is_series_ext=> n. by apply countable_sum_ext.
  Qed.

  Lemma is_seriesC_unique f l :
    is_seriesC f l → SeriesC f = l.
  Proof.
    apply is_series_unique.
  Qed.

  Lemma ex_seriesC_ext f g :
    (∀ n, f n = g n) → ex_seriesC f → ex_seriesC g.
  Proof.
    intros ?. apply ex_series_ext=> n. by apply countable_sum_ext.
  Qed.

  Lemma is_seriesC_chain f g v : is_seriesC g (SeriesC f) → is_seriesC f v → is_seriesC g v.
  Proof.
    intros Hs2 Hs1. apply is_seriesC_unique in Hs1. rewrite -Hs1. done.
  Qed.

  Lemma SeriesC_correct f :
    ex_seriesC f → is_seriesC f (SeriesC f).
  Proof. apply Series_correct. Qed.

  Lemma SeriesC_correct' a v:
    SeriesC a = v → ex_seriesC a → is_seriesC a v.
  Proof. by intros <- ?; apply SeriesC_correct. Qed.

  Lemma SeriesC_0 f :
    (∀ x, f x = 0) → SeriesC f = 0.
  Proof. intros Heq0. apply Series_0=> ?. by apply countable_sum_0. Qed.

  Lemma SeriesC_ge_0 (f : A → R) :
    (∀ x, 0 <= f x) →
    ex_seriesC f →
    0 <= SeriesC f.
  Proof.
    intros Heq0 Hex.
    rewrite -(SeriesC_0 (λ _ : A, 0)); [|done].
    apply Series_le; [|done].
    intros n. split.
    + apply countable_sum_ge_0. intros ?; lra.
    + by apply countable_sum_le.
  Qed.

  Lemma SeriesC_ext f g :
    (∀ n, f n = g n) → SeriesC f = SeriesC g.
  Proof. intros Hext. apply Series_ext => // n. by apply countable_sum_ext. Qed.

  Lemma SeriesC_le f g :
    (∀ n, 0 <= f n <= g n) →
    ex_seriesC g →
    SeriesC f <= SeriesC g.
  Proof.
    intros Hrange Hex. apply Series_le => // n.
    rewrite /countable_sum.
    destruct (encode_inv_nat _) => //=; lra.
  Qed.

  Lemma SeriesC_le' f g :
    (∀ n, f n <= g n) →
    ex_seriesC f →
    ex_seriesC g →
    SeriesC f <= SeriesC g.
  Proof.
    intros ???. apply Series_le' => //= n.
    rewrite /countable_sum.
    destruct (encode_inv_nat _) => //=.
  Qed.

  Lemma SeriesC_scal_l f c :
    SeriesC (λ x, c * f x) = c * SeriesC f.
  Proof.
    intros. rewrite -Series_scal_l. apply Series_ext. apply countable_sum_scal_l.
  Qed.

  Lemma SeriesC_scal_r f c :
    SeriesC (λ x, f x * c) = SeriesC f * c.
  Proof.
    intros. rewrite -Series_scal_r. apply Series_ext. apply countable_sum_scal_r.
  Qed.

  Lemma SeriesC_plus f g :
    ex_seriesC f →
    ex_seriesC g →
    SeriesC (λ x, f x + g x) = SeriesC f + SeriesC g.
  Proof.
    intros. rewrite -Series_plus //. apply Series_ext. apply countable_sum_plus.
  Qed.

  Lemma SeriesC_minus f g :
    ex_seriesC f →
    ex_seriesC g →
    SeriesC (λ x, f x - g x) = SeriesC f - SeriesC g.
  Proof.
    intros. rewrite -Series_minus //. apply Series_ext. apply countable_sum_minus.
  Qed.

  Lemma ex_seriesC_0 :
    ex_seriesC (λ _, 0).
  Proof.
    eexists; by eapply is_seriesC_0.
  Qed.

  Lemma ex_seriesC_le f g :
    (∀ n, 0 <= f n <= g n) →
    ex_seriesC g →
    ex_seriesC f.
  Proof.
    intros Hle Hex.
    eapply @ex_series_le; [|eauto].
    intros n. rewrite /norm//=/abs//=.
    rewrite -countable_sum_Rabs. apply countable_sum_le.
    intros x. destruct (Hle x); eauto. rewrite Rabs_right; eauto; lra.
  Qed.

  Lemma ex_seriesC_scal_l f c :
    ex_seriesC f →
    ex_seriesC (λ x, c * f x).
  Proof.
    intros. eapply ex_series_ext.
    { intros n. rewrite countable_sum_scal_l. done. }
    by eapply @ex_series_scal_l.
  Qed.

  Lemma ex_seriesC_scal_r f c :
    ex_seriesC f →
    ex_seriesC (λ x, f x * c).
  Proof.
    intros. eapply ex_series_ext.
    { intros n. rewrite countable_sum_scal_r. done. }
    apply: ex_series_scal_r; eauto.
  Qed.

  Lemma ex_seriesC_plus f g :
    ex_seriesC f →
    ex_seriesC g →
    ex_seriesC (λ x, f x + g x).
  Proof.
    intros. eapply ex_series_ext.
    { intros n. rewrite countable_sum_plus. done. }
    apply: ex_series_plus; eauto.
  Qed.

  Lemma is_seriesC_scal_l f c v :
    is_seriesC f v →
    is_seriesC (λ x, c * f x) (c * v).
  Proof.
    intros. eapply is_series_ext.
    { intros n. rewrite countable_sum_scal_l. done. }
    apply: is_series_scal_l; eauto.
  Qed.

  Lemma is_seriesC_scal_r f c v:
    is_seriesC f v →
    is_seriesC (λ x, f x * c) (v * c).
  Proof.
    intros. eapply is_series_ext.
    { intros n. rewrite countable_sum_scal_r. done. }
    apply: is_series_scal_r; eauto.
  Qed.

  Lemma is_seriesC_plus f g v1 v2:
    is_seriesC f v1 →
    is_seriesC g v2 →
    is_seriesC (λ x, f x + g x) (v1 + v2).
  Proof.
    intros. eapply is_series_ext.
    { intros n. rewrite countable_sum_plus. done. }
    apply: is_series_plus; eauto.
  Qed.

  Lemma ex_seriesC_Rabs f :
    ex_seriesC (λ x, Rabs (f x)) →
    ex_seriesC f.
  Proof.
    intros. eapply ex_series_Rabs.
    eapply ex_series_ext.
    { intros n. rewrite -countable_sum_Rabs. done. }
    eauto.
  Qed.

  Global Instance is_series_Proper:
    Proper (pointwise_relation A (@eq R) ==> @eq R ==> iff) is_seriesC.
  Proof. intros ?? ? ?? ?; subst; split; eapply is_seriesC_ext; eauto. Qed.

  Global Instance ex_series_Proper:
    Proper (pointwise_relation A (@eq R) ==> iff) ex_seriesC.
  Proof. intros ?? ?; split; eapply ex_seriesC_ext; eauto. Qed.

  Global Instance Series_Proper:
    Proper (pointwise_relation A (@eq R) ==> eq) SeriesC.
  Proof. intros ?? ?; eapply SeriesC_ext; eauto. Qed.

End series.

Section filter.
  Context `{Countable A}.

  Implicit Types P Q : A → Prop.

  Lemma is_seriesC_singleton (a : A) v :
    is_seriesC (λ (n : A), if bool_decide (n = a) then v else 0) v.
  Proof.
    rewrite /is_seriesC.
    eapply is_series_ext; [|apply (is_series_singleton (encode_nat a))].
    intros n =>/=. rewrite /countable_sum.
    case_bool_decide as Hneq=>/=; subst.
    - rewrite encode_inv_encode_nat //= bool_decide_eq_true_2 //.
    - destruct (encode_inv_nat _) eqn:Heq=>//=.
      case_bool_decide; [|done]; subst.
      exfalso. apply Hneq. symmetry. by apply encode_inv_Some_nat.
  Qed.

  Lemma ex_seriesC_singleton (a : A) v :
    ex_seriesC (λ (n : A), if bool_decide (n = a) then v else 0).
  Proof. eexists. eapply is_seriesC_singleton. Qed.

  Lemma SeriesC_singleton (a : A) v :
    SeriesC (λ n, if bool_decide (n = a) then v else 0) = v.
  Proof. apply is_series_unique, is_seriesC_singleton. Qed.

  Lemma SeriesC_ge_elem  (f : A → R) (a : A) :
    (∀ x, 0 <= f x) →
    ex_seriesC f →
    f a <= SeriesC f.
  Proof.
    intros Hf Hex.
    rewrite -(SeriesC_singleton a (f a)).
    apply SeriesC_le; [|done].
    intros a'. specialize (Hf a').
    case_bool_decide; simplify_eq; lra.
  Qed.

  (* These are sometimes convenient *)
  Lemma ex_seriesC_singleton' (a : A) v :
    ex_seriesC (λ (n : A), if bool_decide (a = n) then v else 0).
  Proof.
    apply (ex_seriesC_ext (λ n : A, if bool_decide (n = a) then v else 0)
                          (λ n : A, if bool_decide (a = n) then v else 0)).
    + intro a'; rewrite (bool_decide_ext (a = a') (a' = a)); done.
    + apply ex_seriesC_singleton.
  Qed.

  Lemma SeriesC_singleton' (a : A) v :
    SeriesC (λ n, if bool_decide (a = n) then v else 0) = v.
  Proof.
    rewrite (SeriesC_ext (λ n : A, if bool_decide (a = n) then v else 0)
             (λ n : A, if bool_decide (n = a) then v else 0)).
    + apply SeriesC_singleton.
    + intro a'; rewrite (bool_decide_ext (a = a') (a' = a)); done.
  Qed.

  Lemma is_seriesC_filter_pos f v P `{∀ x, Decision (P x)} :
    (∀ n, 0 <= f n) →
    is_seriesC f v →
    ex_seriesC (λ n, if bool_decide (P n) then f n else 0).
  Proof.
    intros Hge Hconv.
    apply: ex_seriesC_le; last by (exists v; eauto).
    intros n. rewrite /norm /= /abs.
    specialize (Hge n). case_bool_decide; lra.
  Qed.

  Lemma is_seriesC_filter_impl f v P Q `{∀ x, Decision (P x), ∀ x, Decision (Q x)} :
    (∀ n, 0 <= f n) →
    is_seriesC (λ n, if bool_decide (P n) then f n else 0) v →
    (∀ n, Q n → P n) →
    ex_seriesC (λ n, if bool_decide (Q n) then f n else 0).
  Proof.
    intros Hge Hconv Himp. apply ex_seriesC_Rabs.
    apply: ex_seriesC_le; last by (exists v; eauto).
    intros n. rewrite /norm//=/abs//=.
    specialize (Hge n). specialize (Himp n).
    do 2 case_bool_decide; try (rewrite Rabs_right; auto; lra).
    tauto.
  Qed.

  Lemma ex_seriesC_filter_impl f P Q `{∀ x, Decision (P x), ∀ x, Decision (Q x)} :
    (∀ n, 0 <= f n) →
    ex_seriesC (λ n, if bool_decide (P n) then f n else 0) →
    (∀ n, Q n → P n) →
    ex_seriesC (λ n, if bool_decide (Q n) then f n else 0).
  Proof. intros ? [? ?] ?. eapply is_seriesC_filter_impl; eauto. Qed.

  Lemma ex_seriesC_filter_pos f P `{∀ x, Decision (P x)} :
    (∀ n, 0 <= f n) →
    ex_seriesC f →
    ex_seriesC (λ n, if bool_decide (P n) then f n else 0).
  Proof. intros ? [v His]. by eapply is_seriesC_filter_pos. Qed.

  (* TODO: make a [SeriesC_minus] lemma and cleanup proof *)
  Lemma is_seriesC_filter_union f v P Q `{∀ x, Decision (P x), ∀ x, Decision (Q x)} :
    (∀ n, 0 <= f n) →
    is_seriesC (λ n, if bool_decide (P n ∨ Q n) then f n else 0) v →
    SeriesC (λ n, if bool_decide (P n) then f n else 0) +
    SeriesC (λ n, if bool_decide (Q n) then f n else 0) -
    SeriesC (λ n, if bool_decide (P n ∧ Q n) then f n else 0) = v.
  Proof.
    intros Hge Hexists.
    rewrite -SeriesC_plus; last first.
    {apply (is_seriesC_filter_impl  _ _ _ _ Hge Hexists); eauto. }
    { apply (is_seriesC_filter_impl  _ _ _ _ Hge Hexists); eauto. }
    rewrite -SeriesC_minus.
    - rewrite -(is_seriesC_unique _ v Hexists).
      apply SeriesC_ext => n.
      do 2 repeat case_bool_decide=>//=; try tauto; lra.
    - apply: (ex_seriesC_le _ (λ a, scal 2 (if bool_decide (P a ∨ Q a) then f a else 0))).
      + intros a. rewrite /scal /= /mult /=.
        specialize (Hge a). do 3 case_bool_decide => /=; try (lra || tauto).
      + eexists. by eapply is_seriesC_scal_l.
    - eapply (is_seriesC_filter_impl  _ _ _ _ Hge Hexists). intros ? []; auto.
  Qed.

  Lemma ex_seriesC_split_elem f (a0 : A) :
    ex_seriesC (λ a, if bool_decide (a ≠ a0) then f a else 0) → ex_seriesC f.
  Proof.
    intros Ha0.
    eapply (ex_seriesC_ext (λ a, (λ a, if bool_decide (a = a0) then f a else 0) a +
                                   (λ a, if bool_decide (a ≠ a0) then f a else 0) a)).
    { intros a. case_bool_decide; simplify_eq.
      - rewrite bool_decide_eq_false_2; [lra|auto].
      - rewrite bool_decide_eq_true_2 //. lra. }
    eapply ex_seriesC_plus; [|done].
    eapply ex_seriesC_ext; [|eapply (ex_seriesC_singleton a0 (f a0))].
    intros a. simpl. by case_bool_decide; simplify_eq.
  Qed.

  Lemma SeriesC_split_elem f (a0 : A) :
    (∀ a, 0 <= f a) →           (* TODO: this requirements should not be necessary? *)
    ex_seriesC f →
    SeriesC f = SeriesC (λ a, if bool_decide (a = a0) then f a else 0) +
                SeriesC (λ a, if bool_decide (a ≠ a0) then f a else 0).
  Proof.
    intros Hle Hex.
    erewrite SeriesC_ext.
    { eapply SeriesC_plus; [by eapply ex_seriesC_filter_pos|].
      eapply (ex_seriesC_le _ f); [|done].
      intros a'. case_bool_decide; split; (done || lra). }
    intros a. simpl. case_bool_decide as Heq.
    - rewrite bool_decide_eq_false_2; [lra|]. eauto.
    - rewrite bool_decide_eq_true_2 //. lra.
  Qed.

End filter.

(* Section rearrange. *)
(*   Context `{Countable A}. *)

(*   (* TODO: prove this (using the [Series] version from rearrange.v)  *) *)
(*   Lemma SeriesC_rearrange_covering (σ: A → A) (f : A → R) : *)
(*     (* no "collisions" in [f ∘ σ] *) *)
(*     (∀ a a', f (σ a) ≠ 0 → σ a = σ a' → a = a') → *)
(*     (* [σ] is surjective on the support of [f] *) *)
(*     (∀ a, f a ≠ 0 → ∃ a', σ a' = a) → *)
(*     ex_seriesC (λ a, Rabs (f a)) → *)
(*     SeriesC f = SeriesC (f ∘ σ). *)
(*   Proof. Admitted. *)

(* End rearrange. *)

Section strict.
  Context `{Countable A}.

  Implicit Types f g : A → R.

  (** Some extra theorems about strict inequalities, etc. **)
  Lemma SeriesC_lt f g :
  (∀ n, 0 <= f n <= g n) →
  (∃ m, f m < g m) →
  ex_seriesC g →
  SeriesC f < SeriesC g.
  Proof.
    intros Hle Hlt Hg.
    assert (ex_seriesC f) as Hf.
    { apply (ex_seriesC_le f g); auto. }
    destruct Hlt as (m & Hlt).
    assert (g m - f m > 0) as Hgtz ; try lra.
    set (d := g m - f m).
    set (h := (λ n, if bool_decide (n = m) then d else 0) ).
    assert (ex_seriesC h) as Hh.
    { apply ex_seriesC_singleton. }
    assert (SeriesC h > 0) as Hhgt.
    { rewrite SeriesC_singleton; auto. }
    assert (SeriesC f + SeriesC h <= SeriesC g); try lra.
    rewrite <- SeriesC_plus; auto.
    apply SeriesC_le; auto.
    intro n.
    specialize (Hle n) as (Hle1 & Hle2).
    rewrite /h /d.
    case_bool_decide as Hnm; split; try lra.
    rewrite Hnm; lra.
  Qed.

 (* Classical proof. This may be provable constructively, but
  for now this works *)
  Lemma SeriesC_const0 f :
  (∀ n, 0 <= f n) →
  is_seriesC f 0 →
  (∀ n, f n = 0).
  Proof.
   intros Hf Hz n.
   pose proof (is_seriesC_unique _ _ Hz) as Hz'.
   pose proof (Rtotal_order (f n) 0) as Htri.
   destruct Htri as [H1 | [H2 | H3]] ; try lra.
   + specialize (Hf n); lra.
   + assert (0 < SeriesC f); try lra.
     assert (SeriesC (λ _ : A, 0) = 0) as H4.
     { apply SeriesC_0; auto. }
     destruct H4.
     eapply (SeriesC_lt (λ n, 0) f).
     ++ intro n0; specialize (Hf n0); lra.
     ++ exists n; lra.
     ++ exists 0; done.
  Qed.

  Lemma SeriesC_gtz_ex f :
    (∀ n, 0 <= f n) →
    SeriesC f > 0 →
    ∃ n, f n > 0.
  Proof.
    intro Hf.
    eapply contrapositive. intros Hna.
    assert (∀ a, f a = 0) as Hz.
    { intros a.
      pose proof (not_exists_forall_not _ _ Hna a).
      specialize (Hf a); lra. }
    apply Rge_not_gt. rewrite SeriesC_0 //.
   Qed.

End strict.

Section positive.

 (* Results about positive (non-negative) series *)

  Context `{Countable A}.
  Implicit Types f g : A → R.

  Lemma mon_suc_to_mon (h : nat -> R) :
    (∀ p, h p <= h (S p)) ->
    (forall m n, (m <= n)%nat -> h m <= h n).
  Proof.
    intros Hmon m.
    induction m; intro n; induction n.
    - intros; apply Rle_refl.
    - intro. apply (Rle_trans _ (h n)); auto with arith.
    - intro Haux.
      inversion Haux.
    - intro Haux.
      destruct (decide ((S m <= n)%nat)) as [Hle | Hgt].
      + apply (Rle_trans _ (h n)); auto with arith.
      + assert (S m = S n) as ->; [ | apply Rle_refl].
        assert ((n < S m)%nat); auto with arith.
        apply not_le; auto.
  Qed.


  Lemma partial_sum_pos (h : nat → R) p :
    (∀ n, 0 <= h n) ->
    0 <= sum_n h p.
  Proof.
    intros Hpos.
    rewrite /sum_n.
    induction p.
    + rewrite sum_n_n; auto.
    + rewrite sum_n_Sm; auto with arith.
      apply Rplus_le_le_0_compat; auto.
  Qed.


  Lemma partial_sum_elem (h : nat → R) p :
    (∀ n, 0 <= h n) ->
    h p <= sum_n h p.
  Proof.
    intros Hpos.
    rewrite /sum_n.
    induction p.
    + rewrite sum_n_n; auto.
      apply Rle_refl.
    + rewrite sum_n_Sm; auto with arith.
      assert (h (S p) = 0 + h (S p)) as Haux; try lra.
      rewrite {1}Haux.
      Search Rplus.
      apply Rplus_le_compat; [apply partial_sum_pos | apply Rle_refl]; auto.
  Qed.

  Lemma partial_sum_mon (h : nat → R) p q :
    (∀ n, 0 <= h n) ->
    (p ≤ q) →
    sum_n h p <= sum_n h q.
  Proof.
    intros Hge Hpq.
    rewrite /sum_n.
    induction q.
    + assert (p = 0%nat); auto with arith.
      simplify_eq; done.
    + destruct (PeanoNat.Nat.le_gt_cases p q) as [H1 | H1].
      ++ specialize (IHq H1).
         rewrite sum_n_Sm; auto with arith.
         rewrite /plus /=.
         specialize (Hge (S q)).
         lra.
      ++ assert (p = S q); auto with arith.
         rewrite -> H0; auto.
         lra.
  Qed.

  (* TODO: move to [prelude/Coquelicot_ext.v] *)
  (* Strangely, this was not in Coquelicot *)
  Lemma is_series_ge0 (h : nat → R) r:
    (∀ n, 0 <= h n) ->
    is_series h r →
    0 <= r.
  Proof.
    intros Hge Hs.
    erewrite <- (Series_0 (λ y, 0)); auto.
    rewrite  <- (is_series_unique _ _ Hs).
    eapply (Series_le).
    { intro n; split; auto; lra. }
    rewrite /ex_series.
    exists r; auto.
  Qed.

(* Lemma is_series_0 a : *)
(*   is_series a 0 → (∀ n, a n = 0). *)
(* Proof. *)
(*   intros Ha. apply (is_series_ext (λ x, 0)); auto. *)
(*   rewrite /is_series. *)
(*   apply (filterlim_ext (λ x, 0)). *)
(*   - intros m. rewrite sum_n_const Rmult_0_r //. *)
(*   - apply filterlim_const. *)
(* Qed. *)


(*   Lemma Series_0' (f : nat → R) : *)
(*     ex_series f → Series f = 0 → ∀ a, f a = 0. *)
(*   Proof. *)
(*   intros [l Hs] Heq. *)
(*   | *)
(*     => apply is_series_unique, is_series_0. done. *)


(*   Lemma SeriesC_gt_0 f : *)
(*     (∀ n, 0 <= f n) → *)
(*     ex_seriesC f → *)
(*     (∃ n, f n > 0) → *)
(*     0 < SeriesC f. *)
(*   Proof. *)
(*     intros Hf Hex. *)
(*     eapply contrapositive. *)
(*     intros [Hz | Hlt]%Rnot_gt_le [a Hfa]. *)
(*     - admit.  *)
(*     -  *)


(*     assert (SeriesC f = 0). *)
(*     { admit. } *)


(*     assert (∀ a, f a = 0) as Hz. *)
(*     { intros a'. *)


  (*
  Lemma Series_ge0 (h : nat → R):
    (∀ n, 0 <= h n) ->
    0 <= Series h.
  Proof.
  Admitted.
  *)

Lemma bar r :
Rbar_le (Finite 0) r ->
Rbar_le (Finite (real r)) r.
Proof.
  intro Hpos.
  destruct r eqn:Heq; simpl; auto.
  apply Rle_refl.
Qed.

  Lemma lim_is_sup (h: nat -> R) r :
    (∀ n, 0 <= h n) ->
    is_series h r →
    is_sup_seq (sum_n h) (Finite r).
  Proof.
    intros Hge Hs.
    rewrite /is_sup_seq.
    pose proof (is_series_partial_pos h) as Hpart.
    pose proof (is_series_ge0 _ _ Hge Hs) as Hr.
    intro eps; split.
    + intro n.
      specialize (Hpart n r Hge Hs).
      rewrite /Rbar_lt.
      assert (eps > 0); try lra.
      pose proof (cond_pos eps); lra.
    + pose proof (Hs) as Hs'.
      (* rewrite /is_series in Hs.
      rewrite /locally /eventually in Hs.
      rewrite /filterlim in Hs.
      rewrite /filter_le in Hs.
      rewrite /filtermap in Hs. *)
      specialize (Hs (ball r eps)).
      assert (∃ N : nat, ∀ n : nat, N ≤ n → ball r eps (sum_n h n)) as (N & HN).
      {apply Hs. exists eps. auto. }
      exists N; simpl.
      specialize (HN N (Nat.le_refl N)).
      specialize (Hpart N r Hge Hs').
      rewrite /ball /= /AbsRing_ball in HN.
      cut (r - (sum_n h N) < eps); try lra.
      rewrite abs_minus /abs /= in HN.
      assert (Rabs (minus r (sum_n h N)) = minus r (sum_n h N)) as Habs.
      { apply Rabs_right.
        rewrite /minus /plus /= /opp /=.
        lra.
      }
      rewrite Habs in HN.
      rewrite /minus /plus /= /opp /= in HN.
      lra.
  Qed.


  Lemma sup_is_lim (h: nat -> R) r :
    (∀ n, 0 <= h n) ->
    is_sup_seq (sum_n h) (Finite r) ->
    is_series h r.
  Proof.
    intros Hge Hsup.
    (*    rewrite /is_series
       /locally /eventually
       /filterlim
       /filter_le
       /filtermap.*)
    rewrite /is_sup_seq in Hsup.
    intros P (eps & Heps).
    rewrite /ball /= /AbsRing_ball in Heps.
    destruct (Hsup eps) as (HsupFor & (N & HsupN)).
    exists N; intros n Hn.
    specialize (HsupFor n).
    specialize (Heps (sum_n h n)).
    assert (sum_n h N <= sum_n h n) as HNn.
    { by apply partial_sum_mon. }
    apply Heps.
    rewrite /Rbar_lt in HsupFor.
    rewrite /Rbar_lt in HsupN.
    assert (r - eps < sum_n h n); [try lra | ].
    rewrite /abs /= /Rabs /minus /plus /= /opp /=.
    destruct Rcase_abs; lra.
  Qed.

  Lemma eq_rbar_finite x y :
    (Finite x) = y -> x = real(y).
  Proof.
    intro Heq.
    destruct y; simplify_eq; auto.
  Qed.

  Lemma Rbar_0_le_to_Rle x :
    Rbar_le 0 x -> 0 <= x.
  Proof.
    intro Hle.
    destruct x; simpl; auto; lra.
  Qed.


  Lemma Rbar_0_le_to_Rle' x :
    Rbar_le 0 (Finite x) -> 0 <= x.
  Proof.
    intro Hle; auto.
  Qed.

  Lemma lim_is_sup' (h: nat -> R) :
    (∀ n, 0 <= h n) ->
    ex_series h →
    Series h = real (Sup_seq (sum_n h)).
  Proof.
    intros Hpos Hex.
    apply Series_correct, lim_is_sup, is_sup_seq_unique in Hex; auto.
    apply eq_rbar_finite; auto.
  Qed.


  Lemma lim_is_sup'' (h: nat -> R) :
    (∀ n, 0 <= h n) ->
    ex_series h →
    is_series h (real (Sup_seq (sum_n h))).
  Proof.
    intros Hpos Hex.
    rewrite <- lim_is_sup'; auto.
    apply Series_correct; auto.
  Qed.

  Lemma sup_is_upper_bound (h : nat → Rbar) n :
    Rbar_le (h n) (Sup_seq h).
  Proof.
    apply is_sup_seq_major.
    apply Sup_seq_correct.
  Qed.


  Lemma sup_is_upper_bound' (h : nat → R) n r :
    is_sup_seq h (Finite r) ->
    (h n) <= r.
  Proof.
    intro Hr.
    assert (Rbar_le (Finite (real (h n))) (Finite r)); auto.
    assert (real (Finite (h n)) = h n) as ->; auto.
    apply (is_sup_seq_major (fun x : nat => Finite (h x)) (Finite r)); auto.
  Qed.

  Lemma upper_bound_ge_sup (h : nat → Rbar) r :
    (forall n, Rbar_le (h n) r) ->
    Rbar_le (Sup_seq h) r.
  Proof.
    intro H2.
    pose proof (is_sup_seq_lub h (Sup_seq h) (Sup_seq_correct h)) as H3.
    rewrite /Lub.Rbar_is_lub in H3.
    apply H3.
    rewrite /Lub.Rbar_is_upper_bound.
    intros q (n & Hn).
    rewrite Hn; auto.
  Qed.

  Lemma upper_bound_ge_sup' (h : nat → R) r l :
    is_sup_seq h (Finite l) ->
    (forall n, h n <= r) ->
    l <= r.
  Proof.
    intros Hsup H2.
    assert (Rbar_le (Finite l) (Finite r)); auto.
    rewrite <- (is_sup_seq_unique (λ x : nat, h x) l); auto.
    apply (upper_bound_ge_sup (λ x : nat, h x) r); auto.
  Qed.

  Lemma Rbar_le_sandwich p q r :
    Rbar_le (Finite p) r ->
    Rbar_le r (Finite q) ->
    Finite (real r) = r.
  Proof.
    intros Hp Hq.
    destruct r eqn:Hr; auto.
    - destruct Hq.
    - destruct Hp.
  Qed.

  (* Maybe can be proven from partial_summation_R *)
  Lemma ex_pos_bounded_series (h : nat -> R) :
    (∀ n, 0 <= h n) ->
    (exists l, forall n, sum_n h n <= l) ->
    ex_series h.
  Proof.
    intros Hpos (l & Hl).
    exists (real (Sup_seq (λ n, sum_n h n))).
    apply sup_is_lim; auto.
    rewrite (Rbar_le_sandwich 0 l).
    + apply Sup_seq_correct.
    + apply (Rbar_le_trans _ (sum_n h 0%nat)).
      ++ rewrite sum_O.
         assert (0 <= (h 0%nat)); auto.
      ++ apply (sup_is_upper_bound (λ n : nat, sum_n h n) 0%nat).
    + destruct (Sup_seq (λ n : nat, sum_n h n)) eqn:Hsup; simpl; auto.
      ++ assert (Rbar_le (Finite r) (Finite l)); auto.
        rewrite <- Hsup.
        apply upper_bound_ge_sup.
        intro n; auto.
        specialize (Hl n); auto.
      ++ assert (Rbar_le (p_infty) (Finite l)); auto.
        rewrite <- Hsup.
        apply upper_bound_ge_sup.
        intro n; auto.
        specialize (Hl n); auto.
  Qed.

 (*
  Lemma swap_sum_sum (h : nat * nat -> R) n m:
    sum_n (λ p, sum_n (λ q, h (p, q)) n) m =
    sum_n (λ q, sum_n (λ p, h (p, q)) m) n.
  Admitted.


  Lemma swap_sup_sup (h : nat * nat → R) :
    Sup_seq (λ m, Sup_seq (λ n, h (n, m))) =
    Sup_seq (λ n, Sup_seq (λ m, h (n, m))).
  Proof.
    apply Rbar_le_antisym.
    + apply upper_bound_ge_sup.
      intro m.
      apply upper_bound_ge_sup.
      intro n.
      eapply Rbar_le_trans; last first.
      ++ apply (sup_is_upper_bound _ n).
      ++ apply (sup_is_upper_bound (λ x, h(n, x)) m).
    + apply upper_bound_ge_sup.
      intro n.
      apply upper_bound_ge_sup.
      intro m.
      eapply Rbar_le_trans; last first.
      ++ apply (sup_is_upper_bound _ m).
      ++ apply (sup_is_upper_bound (λ x, h(x, m)) n).
  Qed.


  Lemma Sup_seq_plus_r (f : nat -> Rbar) (r : R) :
    Rbar_plus (Sup_seq f) r =
    Sup_seq (λ a, Rbar_plus (f a) r).
  Proof.
  (*
    assert (is_sup_seq (λ a : nat, Rbar_plus (f a) r) (Rbar_plus (Sup_seq f) r)).
    { Search is_sup_seq.
      apply Rbar_is_lub_sup_seq.
      Search Lub.Rbar_is_lub.
      rewrite /Lub.Rbar_is_lub; split.
      - rewrite /Lub.Rbar_is_upper_bound.
        intros x (n & ->).
        apply Rbar_plus_le_compat; [ apply sup_is_upper_bound | apply Rbar_le_refl ].
      - intros b Rb.
        Search Rbar_le.
        apply Rbar_not_lt_le.
        intro.
        rewrite /Lub.Rbar_is_upper_bound in Rb.
        apply Rb.
    }

    symmetry.
    apply Rbar_le_antisym.
    - apply upper_bound_ge_sup.
      intro n.
      apply Rbar_plus_le_compat; [ apply sup_is_upper_bound | apply Rbar_le_refl ].
    - Search Sup_seq.
      Search Rbar_le.
      do 2 rewrite Rbar_sup_eq_lub.
      Search Lub.Rbar_lub.
     - simpl.
     rewrite /Rbar_plus /Rbar_plus'. do 2 case_match; simplify_eq; auto;
     simpl.
     destruct p; }
    Search real.
    apply Rle_antisym.
    - apply upper_bound_ge_sup.
   *)
  Admitted.
*)

(*  Lemma swap_sup_plus (f g : nat -> R):
    (forall a b, (a <= b)%nat -> f a <= f b) ->
    (forall a b, (a <= b)%nat -> g a <= g b) ->
    Rbar_plus (Sup_seq f) (Sup_seq g) =
    Sup_seq (λ a, f a + g a).
  Proof.
    intros Hf Hg.
    apply Rbar_le_antisym.
    - apply (Rbar_le_trans _ (Sup_seq (λ x : nat, Rbar_plus (Sup_seq (λ y : nat, f y)) (g x) ))).
      + admit.
      + admit.
  Admitted.
*)

  Lemma Rbar_le_opp (p q : Rbar) (r : R) :
    Rbar_le (Rbar_plus p r) q <-> Rbar_le p (Rbar_plus q (Finite (-r))).
  Proof.
    split.
    - intro H1.
      destruct p eqn:Hp;
      destruct q eqn:Hq;
      simpl in *; try lra.
    - intro H2.
      destruct p eqn:Hp;
      destruct q eqn:Hq;
      simpl in *; try lra.
  Qed.

 (*
  Lemma swap_sup_plus (h : nat → R) r :
    (exists l, is_sup_seq (λ a, h a) (Finite l)) ->
    Sup_seq (λ a, h a + r) = (Sup_seq (λ a, h a)) + r.
  Proof.
    intros (l & Hl).
    pose proof (is_sup_seq_unique _ l Hl) as Haux.
    apply is_sup_seq_unique.
    apply Rbar_is_lub_sup_seq.
    split.
    - intros x (n & ->).
      simpl.
      apply Rplus_le_compat_r.
      apply (Rle_trans _ l).
      + assert (Rbar_le (Finite (h n)) (Finite l)); auto.
        rewrite <- Haux.
        apply (sup_is_upper_bound (fun a : nat => Finite (h a)) n).
      + rewrite Haux; simpl.
        apply Rle_refl.
    - intros b Hb.
      rewrite /Lub.Rbar_is_upper_bound in Hb.
      assert (∀ x : Rbar, (∃ n : nat, x = h n) → Rbar_le x (Rbar_plus b (opp r))).
      {
        intros x Hx.
        apply Rbar_le_opp.
        apply Hb.
        destruct Hx as (n & ?).
        exists n; simplify_eq; auto.
      }
      assert (Rbar_le (Sup_seq (λ a : nat, h a)) (Rbar_plus b (opp r))).
      {  apply upper_bound_ge_sup.
         intro m.
         apply H0.
         eauto.
      }
      apply Rbar_le_opp in H1.
  Admitted.
 *)

 (*
  Lemma swap_sup_plus (h : nat → R) r :
    (exists l, is_sup_seq (λ a, h a) (Finite l)) ->
    Rbar_plus (Sup_seq (λ a, h a)) (Finite r) =
    Sup_seq (λ a, h a + r).
  Proof.
    intros (l & Hl).
    symmetry.
    pose proof (is_sup_seq_unique _ l Hl) as Haux.
    apply is_sup_seq_unique.
    apply Rbar_is_lub_sup_seq.
    split.
    - intros x (n & ->).
      simpl.
      case_match; simplify_eq; auto.
      + rewrite Haux in H0.
        apply (f_equal real) in H0.
        simpl in H0.
        rewrite <- H0.
        apply Rplus_le_compat_r.
        assert (Rbar_le (Finite (h n)) (Finite l)); auto.
        rewrite <- Haux.
        apply (sup_is_upper_bound (fun a : nat => Finite (h a)) n).
      + rewrite Haux in H0.
        inversion H0.
    - intros b Hb.
      rewrite /Lub.Rbar_is_upper_bound in Hb.
      assert (∀ x : Rbar, (∃ n : nat, x = h n) → Rbar_le x (Rbar_plus b (opp r))).
      {
        intros x Hx.
        apply Rbar_le_opp.
        apply Hb.
        destruct Hx as (n & ?).
        exists n; simplify_eq; auto.
      }
      assert (Rbar_le (Sup_seq (λ a : nat, h a)) (Rbar_plus b (opp r))).
      {  apply upper_bound_ge_sup.
         intro m.
         apply H0.
         eauto.
      }
      apply Rbar_le_opp; auto.
  Qed.
*)

(*
  Lemma swap_sup_sum (h : nat * nat → R) n :
    (forall a, exists r, is_sup_seq (λ b, h (a, b)) (Finite r)) ->
    sum_n (λ a, real (Sup_seq (λ b, h (a, b)))) n =
    Sup_seq (λ b, sum_n (λ a, h (a, b)) n).
  Proof.
    intro Hpos.
    induction n.
    - rewrite sum_O.
      apply f_equal.
      apply Sup_seq_ext.
      intro; rewrite sum_O; auto.
    - rewrite sum_Sn.
      rewrite IHn.
(*      erewrite swap_sup_plus; auto.
      + apply f_equal, Sup_seq_ext.
        intro m.
        rewrite sum_Sn; auto.
      + intro; apply partial_sum_pos; auto.
  Qed.
*)
    Admitted.
*)

  Lemma double_sup_diag (h : nat * nat → R) :
    (forall n m n', (n <= n')%nat -> h (n, m) <= h (n' , m)) ->
    (forall n m m', (m <= m')%nat -> h (n, m) <= h (n , m')) ->
    Sup_seq (λ n, Sup_seq (λ m, h (n, m))) =
    Sup_seq (λ n, h (n, n)).
  Proof.
    intros Hmon1 Hmon2.
    apply Rbar_le_antisym.
    - apply upper_bound_ge_sup.
      intro n.
      apply upper_bound_ge_sup.
      intro m.
      eapply Rbar_le_trans; last first.
      + apply (sup_is_upper_bound _ (n `max` m)).
      + apply (Rbar_le_trans _ (h ((n `max` m), m))).
        * apply Hmon1, Nat.le_max_l.
        * apply Hmon2, Nat.le_max_r.
    - apply upper_bound_ge_sup.
      intro n.
      eapply Rbar_le_trans; last first.
      + apply (sup_is_upper_bound _ n).
      +  eapply Rbar_le_trans; last first.
          * apply (sup_is_upper_bound _ n).
          * apply Rbar_le_refl.
  Qed.


  Lemma series_ge_0 (h : nat -> R):
      (forall a, 0 <= h a) ->
      0 <= Series h.
  Proof.
    intro Hpos.
    rewrite /Series /Lim_seq.
    assert (Rbar_le 0 (LimSup_seq (sum_n h))).
    { rewrite <- (LimSup_seq_const 0).
      apply LimSup_le.
      exists 0%nat; intros.
      apply partial_sum_pos; auto.
    }
    assert (Rbar_le 0 (LimInf_seq (sum_n h))).
    {
      rewrite <- (LimInf_seq_const 0).
      apply LimInf_le.
      exists 0%nat; intros.
      apply partial_sum_pos; auto.
    }
    rewrite /Rbar_div_pos.
    case_match eqn:Heq.
    - apply Rcomplements.Rdiv_le_0_compat; auto.
      + apply Rbar_0_le_to_Rle'.
        rewrite <- (Rbar_plus_0_r 0).
        rewrite <- Heq.
        apply Rbar_plus_le_compat; auto.
      + apply Rlt_R0_R2.
    - apply Rle_refl.
    - rewrite <- Heq.
      apply Rbar_0_le_to_Rle.
      rewrite <- (Rbar_plus_0_r 0).
      apply Rbar_plus_le_compat; auto.
 Qed.

 Lemma fubini_fin_sum (h : nat * nat → R) n m:
    sum_n (λ a, sum_n (λ b, h (a, b)) n ) m
    = sum_n (λ b, sum_n (λ a, h (a, b)) m ) n.
 Proof.
   intros.
   apply sum_n_switch.
 Qed.

 Lemma sum_n_le (h g: nat -> R) n:
   (forall m, h m <= g m) ->
   sum_n h n <= sum_n g n.
 Proof.
   intro Hle.
   induction n.
   - do 2 rewrite sum_O; auto.
   - do 2 rewrite sum_Sn.
     apply Rplus_le_compat; auto.
 Qed.

 Lemma series_pos_partial_le (h : nat -> R) n:
   (forall a, 0 <= h a) ->
   ex_series h ->
   sum_n h n <= Series h.
 Proof.
   intros Hpos Hex.
   rewrite lim_is_sup'; auto.
   destruct Hex as (l & Hl).
   apply lim_is_sup in Hl; auto.
   assert (Rbar_le (Finite (sum_n h n)) (Sup_seq (λ n0 : nat, sum_n h n0))); auto.
   - apply (is_sup_seq_major (λ n0 : nat, sum_n h n0)).
     apply Sup_seq_correct.
   - rewrite (is_sup_seq_unique _ l); auto.
     rewrite (is_sup_seq_unique _ l) in H0; auto.
 Qed.


 Lemma series_pos_elem_le (h : nat -> R) n:
   (forall a, 0 <= h a) ->
   ex_series h ->
   h n <= Series h.
 Proof.
   intros Hpos Hex.
   eapply Rle_trans; [apply partial_sum_elem | ]; auto.
   apply series_pos_partial_le; auto.
 Qed.


 Lemma fubini_fin_inf (h : nat * nat → R) n:
    (forall a b, 0 <= h (a, b)) ->
    (forall b, ex_series (λ a, h (a, b))) ->
    Series (λ a, sum_n (λ b, h (a, b)) n )
    = sum_n (λ b, Series (λ a, h (a, b)) ) n.
 Proof.
   intros Hpos Hex.
   induction n.
   - rewrite sum_O.
     apply Series_ext.
     intro; rewrite sum_O; auto.
   - rewrite sum_Sn.
     rewrite <- IHn.
     rewrite <- Series_plus; auto.
     + apply Series_ext; intro;
       rewrite sum_Sn; auto.
     + apply ex_pos_bounded_series.
       * intro.
         apply partial_sum_pos; auto.
       * exists (sum_n (λ b, Series (λ a : nat, h (a, b))) n).
         intro m.
         rewrite fubini_fin_sum.
         apply sum_n_le.
         intro p.
         apply series_pos_partial_le; auto.
 Qed.

 Lemma fubini_pos_series_ex (h : nat * nat → R) :
    (forall a b, 0 <= h (a, b)) ->
    (forall a, ex_series (λ b, h (a, b))) ->
    (ex_series (λ a, Series (λ b, h (a, b)))) ->
    (forall b, ex_series (λ a, h (a, b))).
 Proof.
   intros Hpos Hex1 Hex2 b.
   apply (ex_series_le (λ a : nat, h (a, b)) (λ a : nat, Series (λ b : nat, h (a, b)))); auto.
   intro a.
   rewrite /norm/=.
   rewrite /abs/=/Rabs/=.
   destruct (Rcase_abs (h (a, b))) as [H1 | H2].
   - destruct (Hpos a b); lra.
   - rewrite <- (Series_bump b (h(a, b))).
     apply Series_le'; auto.
     + intro; case_bool_decide; simplify_eq; auto.
       apply Rle_refl.
     + exists (h(a,b)).
       apply is_series_singleton.
Qed.

 Lemma fubini_pos_series_ex_double (h : nat * nat → R) :
    (forall a b, 0 <= h (a, b)) ->
    (forall a, ex_series (λ b, h (a, b))) ->
    (ex_series (λ a, Series (λ b, h (a, b)))) ->
    (ex_series (λ b, Series (λ a, h (a, b)))).
 Proof.
   intros Hpos Hex1 Hex2.
   pose proof (fubini_pos_series_ex h Hpos Hex1 Hex2) as Hex3.
   pose proof Hex2 as Hex2'.
   destruct Hex2 as (l & Hl).
   apply ex_pos_bounded_series.
   - intro n. apply series_ge_0; auto.
   - exists l; intro n.
     rewrite <- fubini_fin_inf; auto.
     rewrite <- (is_series_unique (λ a : nat, Series (λ b : nat, h (a, b))) l); auto.
     apply Series_le; auto.
     intro m.
     split.
     + apply partial_sum_pos; auto.
     + apply series_pos_partial_le; auto.
 Qed.

 Lemma series_bounded (h : nat -> R) l :
   (forall a, 0 <= h a) ->
   (forall n, sum_n h n <= l) ->
   ex_series h ->
   Series h <= l.
 Proof.
   intros Hpos Hle Hex.
   rewrite lim_is_sup'; auto.
   apply (upper_bound_ge_sup' (λ n : nat, sum_n h n) l); auto.
   assert (Finite (real (Sup_seq (λ n : nat, sum_n h n))) =
             Sup_seq (λ n : nat, sum_n h n)) as ->.
   {
     apply (Rbar_le_sandwich 0 l).
     + apply (Rbar_le_trans _ (sum_n h 0%nat)).
       * rewrite sum_O; simpl; auto.
       * apply (sup_is_upper_bound (λ n : nat, sum_n h n)).
     + apply upper_bound_ge_sup; auto.
   }
   apply (Sup_seq_correct (λ x : nat, sum_n h x)).
 Qed.


 Lemma series_bounded_rbar (h : nat -> R) (l : Rbar) :
   (forall a, 0 <= h a) ->
   (forall n, Rbar_le (sum_n h n) l) ->
   ex_series h ->
   Rbar_le (Series h) l.
 Proof.
   intros Hpos Hle Hex.
   destruct l eqn:Hl; simpl; auto.
   - apply series_bounded; auto.
   - apply (Hle 0%nat); auto.
 Qed.

 Lemma fubini_pos_series (h : nat * nat → R) :
    (forall a b, 0 <= h (a, b)) ->
    (forall a, ex_series (λ b, h (a, b))) ->
    (ex_series (λ a, Series (λ b, h (a, b)))) ->
    Series (λ b, Series (λ a, h (a, b))) =
    Series (λ a, Series (λ b, h (a, b))).
 Proof.
   intros Hpos Hex1 Hex2.
   pose proof (fubini_pos_series_ex _ Hpos Hex1 Hex2) as Hex3.
   pose proof (fubini_pos_series_ex_double _ Hpos Hex1 Hex2) as Hex4.
   apply Rle_antisym.
   - apply series_bounded; auto.
     + intro; apply series_ge_0; auto.
     + intro.
       rewrite <- fubini_fin_inf; auto.
       apply Series_le; auto.
       intro; split; auto.
       * apply partial_sum_pos; auto.
       * apply series_pos_partial_le; auto.
   - apply series_bounded; auto.
     + intro; apply series_ge_0; auto.
     + intro.
       rewrite <- (fubini_fin_inf (λ '(b, a), h (a, b))) ; auto.
       apply Series_le; auto.
       intro; split; auto.
       * apply partial_sum_pos; auto.
       * apply series_pos_partial_le; auto.
 Qed.



(*
Lemma fubini_aux (h : nat * nat -> R) :
  (forall a b, 0 <= h (a, b)) ->
  (forall a, ex_series (λ b, h (a, b))) ->
  (forall b, ex_series (λ a, h (a, b))) ->
  Sup_seq
    (λ m : nat, Finite (sum_n (λ b : nat, real (Sup_seq (λ n : nat, sum_n (λ a : nat, h (a, b)) n))) m)) =
  Sup_seq
    (λ n : nat, Finite (sum_n (λ a : nat, real (Sup_seq (λ m : nat, sum_n (λ b : nat, h (a, b)) m))) n)).
 Proof using A EqDecision0 H.
   intros Hpos HexA HexB.
   (*
   apply Rbar_le_antisym.
   - apply upper_bound_ge_sup.
     intro n.
     induction n.
     + rewrite sum_O.
       eapply Rbar_le_trans.
       * apply bar; admit.
       * apply Sup_seq_le.
         intro m.
         destruct m.
         -- do 2 rewrite sum_O; admit.
         -- do 2 rewrite sum_Sn; admit.
     + rewrite sum_Sn.

       Search Sup_seq.
       eapply (Sup_seq_minor_le _ _ (0%nat)).
       rewrite sum_O.


       apply Sup_seq_le.
   *)
   rewrite foo; auto.
   rewrite foo'; auto.
   rewrite (swap_sup_sup (λ '(n0,n), sum_n (λ b : nat, sum_n (λ a : nat, h (a, b)) n0) n)).
   apply Sup_seq_ext; intros.
   apply Sup_seq_ext; intros.
   rewrite swap_sum_sum.
   auto.
 Qed.

 Lemma tonelli_ex_double (h : nat * nat → R) :
    (forall a b, 0 <= h (a, b)) ->
    (forall a, ex_series (λ b, h (a, b))) ->
    (ex_series (λ a, Series (λ b, h (a, b)))) ->
    (ex_series (λ b, Series (λ a, h (a, b)))).
 Proof.
   intros Hpos Hex1 Hex2.
   pose proof (fubini_pos_series_ex _ Hpos Hex1 Hex2) as Hex3.
   assert (∀ a : nat, is_series (λ b : nat, h (a, b)) (Sup_seq (sum_n (λ b : nat, h (a, b))))) as Ha.
   { intro. apply lim_is_sup''; auto.}
   assert (is_series (λ a : nat, Series (λ b : nat, h (a, b)))
   (Sup_seq (sum_n (λ a : nat, real (Sup_seq (sum_n (λ b : nat, h (a, b)))) )))).
   { admit. }


   apply lim_is_sup' in Hex2; [ | intros; apply series_ge_0; auto].
   assert (∀ a : nat, Series (λ b : nat, h (a, b)) = Sup_seq (sum_n (λ b : nat, h (a, b)))) as Ha.
   { intro a; apply lim_is_sup'; auto. }
   assert (∀ b : nat, Series (λ a : nat, h (a, b)) = Sup_seq (sum_n (λ a : nat, h (a, b)))) as Hb.
   { intro b; apply lim_is_sup'; auto. }
   setoid_rewrite Hb.
   exists (Series (λ a, Series (λ b, h (a, b)))).
   apply sup_is_lim.
   { intro; apply series_ge_0; auto. }


   eapply is_series_chain; last first.
   - Search is_series.
     apply Series_correct; auto.
   - apply Series_correct in H2.
*)










(*
  Lemma fubini_pos_ex_series_r (h : nat * nat → R) :
    (forall n m, h (n, m) >= 0) ->
    (∃ (r: R), ∀ n, sum_n (λ j, sum_n (λ k, Rabs (h (j, k))) n) n <= r) ->
    ∀ b, ex_series (λ a, h (a, b)).
  Proof.
    intros Hpos (r & HDS) b.
    rewrite /ex_series /is_series.

  Lemma fubini_pos_series (h : nat * nat → R) v :
    (forall n m, h (n, m) >= 0) ->
    (∃ (r: R), ∀ n, sum_n (λ j, sum_n (λ k, Rabs (h (j, k))) n) n <= r) ->
    is_series (λ b, Series (λ a, h (a, b))) v ->
    is_series (λ a, Series (λ b, h (a, b))) v .
  Proof.
    intros Hpos (r & HDS) Hse.
    apply sup_is_lim.
    + admit.
    + apply lim_is_sup; auto.
      Search Series.
      { rewrite /Series. admit. }

  Admitted.
*)



  (** Lifting of the Coquliecot predicates for limits *)
  Definition is_sup_seqC f r := is_sup_seq (countable_sum f) r.

  Lemma limC_is_sup (h: A -> R) r :
    (∀ n, 0 <= h n) ->
    is_seriesC h r →
    is_sup_seq (sum_n (countable_sum h)) (Finite r).
  Proof.
    intros Hge Hs.
    rewrite /is_seriesC in Hs.
    eapply (lim_is_sup (countable_sum h) r); auto.
    (* AA: For some reason, Coq is unable to infer the parameters of encode_inv_nat *)
    intro n. rewrite /countable_sum /from_option; edestruct (@encode_inv_nat A _ H n); auto ; lra.
  Qed.

  Lemma sup_is_limC (h: A → R) r :
    (∀ n, 0 <= h n) ->
    is_sup_seq (sum_n (countable_sum h)) (Finite r) ->
    is_seriesC h r.
  Proof.
    intros Hge Hsup.
    rewrite /is_seriesC.
    eapply (sup_is_lim); auto.
    intro n; rewrite /countable_sum /from_option; destruct (encode_inv_nat _); auto; lra.
  Qed.

End positive.


Section mct.

 (*
Lemma sup_mon_seq_plus_k (h : nat -> R) (k : nat) :
  (forall n, (h n) <= (h (S n))) ->
  (Sup_seq h) = (Sup_seq (λ(n:nat), h((n + k)%nat))).
Proof.
  intros Hmon.
  Search Rle.
  Search "is_finite".


Lemma mon_bounded_ex_lim_aux (h : nat -> R) b l r :
  (forall n, (h n) <= (h (S n))) ->
  (forall n, (h n) <= b) ->
  (is_LimInf_seq h l) ->
  (is_LimSup_seq h r) ->
  l = r.
Proof.
  intros Hmon Hb Hinf Hsup.
  apply is_LimSup_seq_unique in Hsup.
  rewrite <- Hsup.
  symmetry.
  apply is_LimSup_seq_unique.
  destruct l eqn:Hl; simpl in *; last first.
  - destruct (Hinf (h 0%nat) 0%nat) as [n [Hn1 Hn2]].
      assert (h 0%nat <= h n); try lra.
      induction n; [ apply Rle_refl | ].
      apply (Rle_trans _ (h n)); auto.
      apply IHn; auto; [apply Nat.le_0_l | ].
      apply (Rle_lt_trans _ (h (S n))); auto.
  - destruct (Hinf b) as [n H2].
    specialize (H2 n (le_refl n)).
    specialize (Hb n); lra.
  - intro eps; split.
    + intro N.
      specialize (Hinf eps) as [H3 [M H4]].
      exists (N `max` M); split; [apply Nat.le_max_l | apply H4, Nat.le_max_r ].
    +




  Search is_sup_seq.

  apply Rbar_le_antisym.
  - rewrite <- (is_LimInf_seq_unique h l); auto.
    rewrite <- (is_LimSup_seq_unique h r); auto.
    apply LimSup_LimInf_seq_le.
  - destruct l eqn:Hl; destruct r eqn:Hr; simpl in *; auto; last first.
    + destruct (Hsup b 0%nat) as [n [Hn1 Hn2]].
      specialize (Hb n); lra.
    + destruct (Hinf (h 0%nat) 0%nat) as [n [Hn1 Hn2]].
      assert (h 0%nat <= h n); try lra.
      induction n; [ apply Rle_refl | ].
      apply (Rle_trans _ (h n)); auto.
      apply IHn; auto; [apply Nat.le_0_l | ].
      apply (Rle_lt_trans _ (h (S n))); auto.
    + destruct (Hsup b 0%nat) as [n [Hn1 Hn2]].
      specialize (Hb n); lra.
    + simplify_eq.


Lemma mon_bounded_ex_lim (h : nat → R) b :
  (forall n, (h n) <= (h (S n))) ->
  (forall n, (h n) <= b) ->
  ex_lim_seq h.
Proof.
  assert (Rbar_le (LimSup_seq h) (LimInf_seq h)) as Haux.
  {
    simpl.

  }
  rewrite /Lim_seq.
  Search LimSup_seq.
  unfold LimSup_seq.
  Search is_sup_seq.
Admitted.
*)

  (* AA: This is quite convoluted, I wonder if it can be simplified *)
  Lemma Sup_seq_bounded_plus_l (f : nat -> R) (b r : R) :
    (forall n, 0 <= f n <= b) ->
    Sup_seq (λ a, r + (f a)) =
    r + real (Sup_seq f).
  Proof.
    intro Hf.
    apply Rbar_le_antisym.
    - apply upper_bound_ge_sup.
      intro n.
      simpl.
      apply Rplus_le_compat; [apply Rle_refl | ].
      + apply sup_is_upper_bound'.
        rewrite -> (Rbar_le_sandwich 0 b); auto.
        * apply Sup_seq_correct.
        * apply (Sup_seq_minor_le _ _ 0%nat), Hf.
        * apply (upper_bound_ge_sup _ b), Hf.
    - rewrite /Sup_seq.
     destruct ex_sup_seq as (p & Hp).
     destruct ex_sup_seq as (q & Hq).
     assert (is_finite p) as Hfinp.
     { apply (Rbar_le_sandwich 0 b).
        + eapply (Rbar_le_trans _ (Finite (f 0%nat))).
          * apply (proj1 (Hf 0%nat)).
          * rewrite <- (is_sup_seq_unique f p); auto.
            apply (Sup_seq_minor_le _ _ 0%nat), Rle_refl.
        + rewrite <- (is_sup_seq_unique f p); auto.
          apply (upper_bound_ge_sup _ b), Hf.
     }
     assert (is_finite q) as Hfinq.
     { apply (Rbar_le_sandwich r (r + b)).
        + eapply (Rbar_le_trans _ (Finite (r + f 0%nat))).
          * assert (r = r + 0) as Haux; [lra | ].
            rewrite {1}Haux.
            apply (Rbar_plus_le_compat r r 0 (f 0%nat)); [apply Rbar_le_refl | ].
            apply (proj1 (Hf 0%nat)).
          * rewrite <- (is_sup_seq_unique (λ a : nat, r + f a) q); auto.
            apply (Sup_seq_minor_le _ _ 0%nat), Rle_refl.
        + rewrite <- (is_sup_seq_unique (λ a : nat, r + f a) q); auto.
          apply (upper_bound_ge_sup _ (r + b)).
          intro n; apply (Rbar_plus_le_compat r r (f n) b); [apply Rbar_le_refl | ].
          apply Hf.
     }
     simpl proj1_sig.
     apply is_sup_seq_lub in Hp.
     apply is_sup_seq_lub in Hq.
     destruct Hp as (Hp1 & Hp2).
     destruct Hq as (Hq1 & Hq2).
     apply is_finite_correct in Hfinp.
     destruct Hfinp as (p' & ->).
     apply is_finite_correct in Hfinq.
     destruct Hfinq as (q' & ->).
     simpl.
     assert (p' <= q' + (opp r)) as H; last first.
     {
       apply (Rplus_le_compat r r) in H; [ | apply Rle_refl].
       apply (Rle_trans (r + p') (r + (q' + opp r)) q'); auto.
       rewrite (Rplus_comm q' (opp r)).
       rewrite <- Rplus_assoc.
       assert (r + opp r = 0) as ->.
       + apply (plus_opp_r r).
       + rewrite Rplus_0_l.
         apply Rle_refl.
     }
     assert (Rbar_le p' (q' + opp r)); auto.
     apply Hp2.
     intros _ (n & ->).
     apply (Rbar_le_trans _ (r + f n + opp r)).
     { simpl.
       rewrite (Rplus_comm r (f n)).
       rewrite (Rplus_assoc).
       assert (r + opp r = 0) as ->.
       + apply (plus_opp_r r).
       + rewrite Rplus_0_r.
         apply Rle_refl.
     }
     simpl.
     apply Rplus_le_compat; [ | apply Rle_refl ].
     assert (Rbar_le (r + f n) q'); auto.
     apply Hq1.
     exists n; auto.
  Qed.

  Lemma Sup_seq_bounded_plus_r (f : nat -> R) (b r : R) :
    (forall n, 0 <= f n <= b) ->
    Sup_seq (λ a, (f a) + r) =
    real (Sup_seq f) + r.
  Proof.
    intro Hf.
    rewrite Rplus_comm.
    erewrite Sup_seq_ext; last first.
    - intro; rewrite Rplus_comm; done.
    - eapply Sup_seq_bounded_plus_l; eauto.
  Qed.


  Lemma Sup_seq_bounded_plus_sup (f g : nat -> R) (b r : R) :
    (forall n, 0 <= f n <= b) ->
    (forall n, 0 <= g n <= b) ->
    (forall n, f n <= f (S n)) ->
    (forall n, g n <= g (S n)) ->
    Sup_seq (λ a, (f a) + (g a)) =
    real (Sup_seq f) + (Sup_seq g).
  Proof.
    intros Hfb Hgb Hfmon Hgmon.
    apply Rbar_le_antisym.
    - apply upper_bound_ge_sup.
      intro n.
      simpl.
      apply Rplus_le_compat.
      + apply sup_is_upper_bound'.
        rewrite -> (Rbar_le_sandwich 0 b); auto.
        * apply Sup_seq_correct.
        * apply (Sup_seq_minor_le _ _ 0%nat), Hfb.
        * apply (upper_bound_ge_sup _ b), Hfb.
      + apply sup_is_upper_bound'.
        rewrite -> (Rbar_le_sandwich 0 b); auto.
        * apply Sup_seq_correct.
        * apply (Sup_seq_minor_le _ _ 0%nat), Hgb.
        * apply (upper_bound_ge_sup _ b), Hgb.
     - rewrite <- (Sup_seq_bounded_plus_r _ b); auto.
       apply upper_bound_ge_sup.
       intro n.
       rewrite <- (Sup_seq_bounded_plus_l _ b); auto.
       apply upper_bound_ge_sup.
       intro m.
       eapply Rbar_le_trans; last first.
       + apply (sup_is_upper_bound _ (n `max` m)).
       + simpl.
         apply Rplus_le_compat.
         * pose proof (mon_suc_to_mon f Hfmon) as Haux.
           apply Haux, Nat.le_max_l.
         * pose proof (mon_suc_to_mon g Hgmon) as Haux.
           apply Haux, Nat.le_max_r.
  Qed.

  Lemma MCT_aux1 (h : nat -> nat → R) (l : nat -> R) (r : R) (M : nat) :
  (forall n a, 0 <= (h n a)) ->
  (forall n a, (h n a) <= (h (S n) a)) ->
  (forall a, exists s, forall n, h n a <= s ) ->
  (forall n, is_series (h n) (l n)) ->
  is_sup_seq l (Finite r) ->
  Finite ((sum_n (λ a : nat, real (Sup_seq (λ n : nat, h n a))) M)) =
  (Sup_seq (λ n, sum_n (λ a : nat, h n a) M)).
  Proof.
    intros Hpos Hmon Hbd Hseries Hsup.
    assert (forall a b, Finite (a + b) = Finite a + Finite b) as Haux; auto.
    induction M.
    - rewrite sum_O.
      destruct (Hbd 0%nat) as (s & Hs).
      rewrite (Rbar_le_sandwich 0 s).
      + apply Sup_seq_ext; intro; rewrite sum_O; auto.
      + apply (Sup_seq_minor_le (λ n0 : nat, h n0 0%nat) 0 0%nat).
        apply Hpos.
      + apply upper_bound_ge_sup; auto.
    - rewrite sum_Sn.
      rewrite Haux.
      rewrite IHM.
      symmetry.
      erewrite Sup_seq_ext; last first.
      + intro; rewrite sum_Sn. done.
      + rewrite Haux; simpl.
        erewrite <- (Sup_seq_bounded_plus_sup _ _ r); auto; intros; try split.
        * apply partial_sum_pos; auto.
        * eapply Rle_trans.
          -- apply series_pos_partial_le; auto.
             exists (l n); auto.
          -- rewrite (is_series_unique _ _ (Hseries n)).
             apply (sup_is_upper_bound'); auto.
        * auto.
        * eapply Rle_trans.
          -- apply series_pos_elem_le; auto.
             exists (l n); auto.
          -- rewrite (is_series_unique _ _ (Hseries n)).
             apply (sup_is_upper_bound'); auto.
       * apply sum_n_le.
         intro m; auto.
  Qed.

  Lemma MCT_aux2 (h : nat -> nat → R) (l : nat -> R) (r : R) :
  (forall n a, 0 <= (h n a)) ->
  (forall n a, (h n a) <= (h (S n) a)) ->
  (forall a, exists s, forall n, h n a <= s ) ->
  (forall n, is_series (h n) (l n)) ->
  is_sup_seq l (Finite r) ->
  Rbar_le (Sup_seq (λ m, sum_n (λ a, real (Sup_seq (λ n, h n a))) m)) r.
  Proof.
    intros Hpos Hmon Hbd Hseries Hsup.
    apply upper_bound_ge_sup.
    intro M.
    erewrite MCT_aux1; eauto.
    apply upper_bound_ge_sup.
    intro n.
    apply (Rbar_le_trans _ (Series (λ a : nat, h n a))).
    - apply series_pos_partial_le; auto.
      exists (l n); auto.
    - apply (Rbar_le_trans _ (l n)).
      + rewrite <- (is_series_unique (λ a : nat, h n a) (l n)); auto.
        apply Rbar_le_refl.
      + erewrite <- is_sup_seq_unique; eauto.
        apply (sup_is_upper_bound (λ x : nat, l x)).
  Qed.


  Lemma MCT_aux3 (h : nat -> nat → R) (l : nat -> R) (r : R) :
  (forall n a, 0 <= (h n a)) ->
  (forall n a, (h n a) <= (h (S n) a)) ->
  (forall a, exists s, forall n, h n a <= s ) ->
  (forall n, is_series (h n) (l n)) ->
  is_sup_seq l (Finite r) ->
  Rbar_le r (Sup_seq (λ m, sum_n (λ a, real (Sup_seq (λ n, h n a))) m)).
  Proof.
    intros Hpos Hmon Hbd Hseries Hsup.
    rewrite <- (is_sup_seq_unique _ _ Hsup).
    apply upper_bound_ge_sup.
    intro n.
    rewrite <- (is_series_unique _ _ (Hseries n)).
    apply series_bounded_rbar; auto; [ | (exists (l n)); auto].
    intro m.
    apply (Sup_seq_minor_le _ _ m).
    erewrite MCT_aux1; eauto.
    apply (sup_is_upper_bound (λ n0 : nat, sum_n (λ a : nat, h n0 a) m)).
  Qed.


  Lemma rbar_le_finite (p : R) (q : Rbar) :
    is_finite q ->
    Rbar_le p q ->
    p <= real q.
  Proof.
    intros Hq Hle.
    rewrite /is_finite/= in Hq.
    destruct q; auto; simplify_eq.
  Qed.

  Lemma finite_rbar_le (p : R) (q : Rbar) :
    is_finite q ->
    Rbar_le q p ->
    q <= real p.
  Proof.
    intros Hq Hle.
    rewrite /is_finite/= in Hq.
    destruct q; auto; simplify_eq.
  Qed.

  Lemma rbar_le_rle (p : R) (q : R) :
    Rbar_le (Finite p) (Finite q) <-> Rle p q.
  Proof.
    auto.
  Qed.

  Lemma is_finite_bounded (p q : R) (r : Rbar) :
    Rbar_le p r ->
    Rbar_le r q ->
    is_finite r.
  Proof.
    intros H1 H2.
    rewrite /is_finite.
    destruct r eqn:Hr; auto.
    - destruct H2.
    - destruct H1.
  Qed.

  Lemma rbar_finite_real_eq (p : Rbar) :
    is_finite p ->
    Finite (real p) = p.
  Proof.
    intro Hfin.
    destruct p; auto.
  Qed.

  Lemma MCT_aux4 (h : nat -> nat → R) (l : nat -> R) (r : R) :
  (forall n a, 0 <= (h n a)) ->
  (forall n a, (h n a) <= (h (S n) a)) ->
  (forall a, exists s, forall n, h n a <= s ) ->
  (forall n, is_series (h n) (l n)) ->
  is_sup_seq l (Finite r) ->
  is_finite
    (Sup_seq
       (λ n : nat,
        Finite
          (sum_n (λ a : nat, real (Sup_seq (λ n0 : nat, Finite (h n0 a)))) n))).
  Proof.
    intros Hpos Hmon Hbd Hseries Hsup.
    apply (is_finite_bounded 0 r).
    - apply (Sup_seq_minor_le _ _ 0%nat).
      destruct (Hbd 0%nat) as (s & Hs).
      rewrite sum_O.
      rewrite (Rbar_le_sandwich 0 s).
      + apply (Sup_seq_minor_le (λ n0 : nat, h n0 0%nat) 0 0%nat).
        apply Hpos.
      + apply (Sup_seq_minor_le (λ n0 : nat, h n0 0%nat) 0 0%nat).
        apply Hpos.
      + apply upper_bound_ge_sup; auto.
    - rewrite <- (is_sup_seq_unique l r); auto.
      apply upper_bound_ge_sup; intro n.
      erewrite MCT_aux1; eauto.
      apply Sup_seq_le; intro m.
      rewrite <- (is_series_unique (h m) (l m)); auto.
      apply series_pos_partial_le; auto.
      exists (l m); auto.
  Qed.


  Lemma MCT_series (h : nat -> nat → R) (l : nat -> R) (r : R) :
  (forall n a, 0 <= (h n a)) ->
  (forall n a, (h n a) <= (h (S n) a)) ->
  (forall a, exists s, forall n, h n a <= s ) ->
  (forall n, is_series (h n) (l n)) ->
  is_sup_seq l (Finite r) ->
  Series (λ a, Sup_seq (λ n, h n a)) = r.
  Proof.
    intros Hpos Hmon Hbd Hseries Hsup.
    rewrite lim_is_sup'; auto.
    - apply Rle_antisym.
      + apply finite_rbar_le; [eapply MCT_aux4 | eapply MCT_aux2 ]; eauto.
      + apply rbar_le_finite; [eapply MCT_aux4| eapply MCT_aux3 ]; eauto.
    - intro n.
      apply Rbar_0_le_to_Rle.
      apply (Sup_seq_minor_le _ _ 0%nat); auto.
      apply Hpos.
    - apply ex_pos_bounded_series.
      + intro.
        apply Rbar_0_le_to_Rle.
        apply (Sup_seq_minor_le _ _ 0%nat); auto.
        apply Hpos.
      + exists r.
        intro m.
        apply rbar_le_rle.
        assert
          (Rbar_le
        (@sum_n R_AbelianGroup (fun a : nat => real (Sup_seq (fun n : nat => Finite (h n a)))) m) r);
          auto.
        erewrite MCT_aux1; eauto.
        rewrite <- (is_sup_seq_unique _ r Hsup).
        apply Sup_seq_le.
        intro n.
        rewrite <- (is_series_unique (h n) (l n)); auto.
        apply series_pos_partial_le; auto.
        exists (l n); auto.
Qed.

(*
Lemma lim_seq_incr: ∀ u : nat → R, (∀ n : nat, (u n <= u (S n))) → (u 0%nat) <= (Lim_seq u).
Proof. Admitted.
*)

(*
  Adapted from
  https://depot.lipn.univ-paris13.fr/mayero/coq-num-analysis/-/blob/LInt_p.1.0/Lebesgue/LInt_p.v#L489)
*)


(*

Lemma Beppo_Levi_aux1 (f g : nat -> R):
    (forall n, 0 <= (f n)) ->
    (forall n, 0 <= (g n)) ->
    (forall n, (f n) <= (f (S n))) ->
    (forall n, (g n) <= (g (S n))) ->
    Sup_seq (λ n, f n + g n) = Sup_seq (λ n, f n) + Sup_seq (λ n, g n).
Proof.
  intros Hposf Hposg Hmonf Hmong.
  apply is_sup_seq_unique.
  rewrite /is_sup_seq; intro eps; split.
  + intro n.
    (* This should be easy *)
    admit.
  + assert (∃ nf : nat, Rbar_lt (Sup_seq (λ n0 : nat, f n0) - eps/2) (f nf)) as [nf Hnf].
    { admit. }
    assert (∃ ng : nat, Rbar_lt (Sup_seq (λ n0 : nat, g n0) - eps/2) (g ng)) as [ng Hng].
    { admit. }
    exists (max nf ng).
    admit.
Admitted.


Lemma Beppo_Levi_aux2 (f : nat → nat → R) (M : nat):
    (forall n m, 0 <= (f n m)) ->
    (forall n m, (f n m) <= (f (S n) m)) ->
    Sup_seq (λ n, (sum_n (f n) M)) = sum_n (λ m, Sup_seq (λ n, f n m)) M.

  assert (Sup_seq (λ n : nat, f n a1) + Sup_seq (λ n : nat, f n a2) <= Sup_seq (λ n : nat, f n a1 + f n a2) /\
            Sup_seq (λ n : nat, f n a1 + f n a2) <= Sup_seq (λ n : nat, f n a1) + Sup_seq (λ n : nat, f n a2)) as H';
  [ | destruct H'; apply Rle_antisym; auto ].
  split.
  + rewrite {3}/Sup_seq.
  +

Lemma Beppo_Levi' `{Countable A} (f : nat -> A -> R) :
    (forall a n, 0 <= (f n a)) ->
    (forall n, ex_seriesC (f n)) ->
    (forall n a, (f n a) <= (f (S n) a)) ->
    (exists l, forall n, (SeriesC (f n)) <= l) →
    let lim_f := λ x, Sup_seq (λ n, f n x) in
    is_seriesC lim_f (Sup_seq (λ n, SeriesC (f n))).
Proof.
  intros Hpos Hex Hmon Hbd lim_f.
  apply sup_is_limC; auto.
  + intro a.
    pose proof (sup_is_upper_bound (λ n : nat, f n a) 0) as Haux1.
    rewrite // in Haux1.
    assert (Rbar_le 0 (f 0%nat a)) as Haux2; [apply Hpos | ].
    admit.
  + rewrite /SeriesC /Series.
    rewrite /is_sup_seq.
    intro eps; split.
    ++ intro n.
       assert (Rbar_lt (sum_n (countable_sum (λ x : A, lim_f x)) n) (Sup_seq (λ n0 : nat, Lim_seq (sum_n (countable_sum (f n0)))))).
       {
         Search Sup_seq.

       }



  split.
  + rewrite /lim_f.
    eapply ex_seriesC_ext; admit.
  + rewrite /lim_f.

Lemma mon_conv_thm `{Countable A} (u : A -> nat → R) :
  (forall a n, Rle (u a n) (u a (S n))) ->
  (forall n, ex_seriesC (λ a, u a n)) ->
  SeriesC (λ a, Lim_seq (λ n, u a n)) = Lim_seq (λ n, (SeriesC (λ a, u a n))).
Proof. Admitted.

Lemma mon_conv_thm_ex `{Countable A} (u : A -> nat → R) b :
  (forall a n, Rle (u a n) (u a (S n))) →
  (forall n, ex_seriesC (λ a, u a n)) ->
  (forall n, Rle (SeriesC (λ a, u a n)) b) ->
  ex_seriesC (λ a, Lim_seq (λ n , u a n)).
Proof. Admitted.

Lemma mon_bounded_lim (u : nat → R) b :
  (forall n, Rle (u n) (u (S n))) ->
  (forall n, Rle (u n)  b) ->
  Rle (Lim_seq u) b.
Admitted.

*)

End mct.
