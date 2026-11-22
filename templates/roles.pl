%% templates/roles.pl -- what a verb's roles are, for
%% library(reasoning/typology). One table for every language: a verb is
%% the IR's meaning. typology_load/1 reads it once.
%%
%% ty_role_animacy(Verb, Role, Animacy): the Role (s, the subject) of Verb
%% is animate or inanimate. A noun the vocabulary says nothing of
%% (unknown) fits either. So `Cosa vede il ragazzo?' is what the boy
%% sees: a thing does not see, and `what' is the object.
%% An Animacy none: the verb takes no such role (`sleep' has no object).

ty_role_animacy(see, s, animate).
ty_role_animacy(sleep, s, animate).
ty_role_animacy(sleep, o, none).
ty_role_animacy(eat, s, animate).
ty_role_animacy(view, s, animate).
ty_role_animacy(think, s, animate).
ty_role_animacy(look, s, animate).
ty_role_animacy(wait, s, animate).
ty_role_animacy(listen, s, animate).
ty_role_animacy(dream, s, animate).

%% ty_kind(Meaning, Kind): the kind of a pronoun that stands for a noun of
%% Meaning, m or f, where the meaning says the sex (an answer's `he' for
%% the boy, `she' for the girl); a person of no row is m, and anything else
%% n (`it').
ty_kind(boy, m).
ty_kind(man, m).
ty_kind(husband, m).
ty_kind(father, m).
ty_kind(son, m).
ty_kind(brother, m).
ty_kind(girl, f).
ty_kind(woman, f).
ty_kind(wife, f).
ty_kind(mother, f).
ty_kind(daughter, f).
ty_kind(sister, f).
