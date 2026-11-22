%% templates/roles.pl -- what a verb's roles are, for
%% library(reasoning/typology). One table for every language: a verb is
%% the IR's meaning. typology_load/1 reads it once.
%%
%% ty_role_animacy(Verb, Role, Animacy): the Role (s, the subject) of Verb
%% is animate or inanimate. A noun the vocabulary says nothing of
%% (unknown) fits either. So `Cosa vede il ragazzo?' is what the boy
%% sees: a thing does not see, and `what' is the object.

ty_role_animacy(see, s, animate).
ty_role_animacy(sleep, s, animate).
ty_role_animacy(eat, s, animate).
ty_role_animacy(view, s, animate).
