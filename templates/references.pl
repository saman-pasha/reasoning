%% templates/references.pl -- the reference sentences, for
%% library(reasoning/typology). typology_load/1 reads it once, beside the
%% topics.
%%
%% ty_reference(Lang, Text, Topics, IR): Text, read with the topics Topics
%% given, has the reading IR among its readings. typology_references/2
%% names the rows that do not hold; in live mode the topics a model gives
%% a meaning are kept only where no row stops holding for them
%% (library(reasoning/live)). A word of several meanings that have no
%% topic gets a row for each meaning, so topics given to the wrong meaning
%% take the right one away and are refused.

%% `lima' is a file and a lime.
ty_reference(spanish, 'El niño ve la lima.', [food],
             clause(see, present, pos, np(boy, sg, def, []), np(lime, sg, def, []))).
ty_reference(spanish, 'El niño ve la lima.', [tool],
             clause(see, present, pos, np(boy, sg, def, []), np(file, sg, def, []))).

%% `cometa' is a comet and a kite.
ty_reference(spanish, 'El niño ve la cometa.', [sky],
             clause(see, present, pos, np(boy, sg, def, []), np(comet, sg, def, []))).
ty_reference(spanish, 'El niño ve la cometa.', [game],
             clause(see, present, pos, np(boy, sg, def, []), np(kite, sg, def, []))).

%% `marcha' is a march and a gear, and `marzo' the month, a meaning of its
%% own (march_month: ty_meaning_sense/2 in templates/topics.pl).
ty_reference(spanish, 'El niño ve la marcha.', [],
             clause(see, present, pos, np(boy, sg, def, []), np(march, sg, def, []))).
ty_reference(spanish, 'El niño ve el marzo.', [],
             clause(see, present, pos, np(boy, sg, def, []), np(march_month, sg, def, []))).
ty_reference(italian, 'Il ragazzo vede il marzo.', [],
             clause(see, present, pos, np(boy, sg, def, []), np(march_month, sg, def, []))).
