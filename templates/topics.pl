%% templates/topics.pl -- the topics of meanings, for
%% library(reasoning/typology). One table for every language: a meaning is
%% the IR's, an English word. typology_load/1 reads it once, and
%% templates/topics-words.pl after it: the rows typology_import(topics)
%% writes from the vocabularies' class lines (`"sábado" is a time.'), a
%% row here never written there again.
%%
%% ty_topic(Meaning, Topic). A meaning is its own topic too, so `knife'
%% needs no row to be about knives. A word with several meanings takes the
%% one whose topics its context has the most of: `hoja' beside `libro' is a
%% sheet, beside `árbol' a leaf, after a sentence about a knife a blade.

%% Plants.
ty_topic(leaf, plant).
ty_topic(tree, plant).
ty_topic(flower, plant).
ty_topic(grass, plant).

%% Paper and writing.
ty_topic(sheet, paper).
ty_topic(book, paper).
ty_topic(page, paper).
ty_topic(letter, paper).
ty_topic(letter, mail).
ty_topic(envelope, mail).

%% Knives and tools.
ty_topic(blade, knife).
ty_topic(blade, tool).
ty_topic(knife, tool).

%% Food and eating out.
ty_topic(menu, food).
ty_topic(restaurant, food).
ty_topic(apple, food).
ty_topic(bread, food).
ty_topic(waiter, food).

%% Games.
ty_topic(card, game).
ty_topic(ball, game).

%% The sky and the weather.
ty_topic(weather, sky).
ty_topic(rain, sky).
ty_topic(rain, weather).
ty_topic(sun, sky).
ty_topic(cloud, sky).
ty_topic(cloud, weather).

%% A MEANING OF ITS OWN FOR ONE SENSE of an English word: ty_meaning_sense(
%% Sense, Meaning) says Sense is a meaning of the IR for one sense of the
%% English word Meaning, given to a word by a hand template's row (Spanish
%% and Italian `marzo', the month, are march_month; `marcha' and `marcia',
%% the walk, are march). The import writes no row of that word with
%% Meaning, and a class line of the word gives its topics to Sense
%% (`"marzo" is a month.': march_month is about months, march is not).
%% English writes Sense by its own row.
ty_meaning_sense(march_month, march).
