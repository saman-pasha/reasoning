# Reasoning library

<!-- Moved verbatim from cocolog's CLAUDE.md, section "The reasoning library and the translator"
     (lines 4459-11710 at cocolog commit b9c48e8), on 2026-11-13, when the library
     became this repository. Paths in the text are as they stood in cocolog's
     checkout: `library/reasoning/X` is `X` at this repository's root; `test/X`,
     `tutorials/library/X` and `tools/X` keep their paths here. -->

## The version

`reason_version/3`, a fact at the top of `reason.pl`, is the ONE place;
`reason_version/1` answers it as an atom (`X.Y.Z`). A change to anything in
this repository -- the code, `corpus/`, `lexicon/`, `generated/`,
`model.rows` -- moves that number in the same commit, and `cocolog --version`
stays unless the binary or another library changed too. The patch is the
default; a minor (something new reachable from a program) or a major (a
program that worked stopping) is PROPOSED and used by the proposer; a
documentation-only commit does not bump; a message names the number that
moved (`reasoning X.Y.Z`). `test/reason.pl` (section `version`, four arms
red) and lesson 43 pin the shape of the answer, deliberately not the number.

## The reasoning library and the translator

`library/reasoning/`: `reason.pl` (controlled English as a DCG, questions,
explanations, topics), `normalise.pl` (the generator of tagged training
pairs), `tagger.pl` (a GRU tagger over `tensor_expr`, plus the deterministic
judge `tagger_sane/2` and repair `tg_repair/3`), `translate.pl` (sentences
read into an English-worded IR and written into any lesson's language),
`teach.pl` and `page.pl`. Cases: `test/reason.pl`, `normalise.pl`,
`tagger.pl`, `translate.pl`; lessons 43-46 in `tutorials/library/`.

**Where the data is, and who reads it:**

| path | what | rebuilt by |
|---|---|---|
| `corpus/*.txt` | hand lessons, one sentence a line -- **the TAGGER's corpus** | hand |
| `corpus/extra/<lang>.txt`, `extra/eng-*.dix` | lines and dictionary entries Apertium lacks or gets wrong -- vocabulary only, never read by the tagger, written FIRST | hand |
| `corpus/vocabulary/*.txt` | ~110k Italian and ~139k Spanish lesson lines, committed | `corpus/build.pl` from `corpus/raw/` (`tools/corpus/fetch.sh`, not committed) |
| `generated/`, `model.rows` | the training pairs and the shipped model, committed | `tools/tagger/train.sh` |
| `lexicon/*.txt` | WordNet and census words, committed | `tools/lexicon/build.sh` |

* **A change to `corpus/*.txt` is a data change for the tagger**: regenerate
  `generated/` and `model.rows`, and expect a minority shape to re-roll. A
  word that is vocabulary rather than a shape goes in `corpus/extra/`. A
  training is deterministic, so retraining unchanged data fixes nothing.
* **Rebuild the vocabularies after the LAST line of `extra/`**:
  `test/translate.pl`'s `build` section rebuilds the Spanish file in a scratch
  corpus (with `raw/` and `extra/` symlinked) and requires it byte for byte.
  Read a rebuilt vocabulary for what it LOST (a set diff), not only what it
  gained.
* **A line of `extra/` has two readers**: it comes first for its WORD and
  for its MEANING, so it moves the reader of one language and the writer of
  the other. Say the dictionary's own word again first where the line must
  not become the word written. **A line that gives a COMMON word a second
  meaning makes every sentence with that word read it twice over** (`The word
  "che" means "which".` made the old translator 11.2 % dearer over the
  controls on the new store and the six heaviest sentences 2.6 times, and the
  factor multiplies: cecchi 8 has two `che` and rose 3.9 times, the other
  meaning being tried again on every failing road): find such a line by
  teaching a store without each group of the new lines (50 s a store) and
  counting the heaviest sentences, and where the second sense reads as the
  first, let the code take it from the first (`tr_which_asks/2`). **An
  elision a lesson states is read AND
  written**: `"dev'" is the elision of "deve".` makes the reader take `dev'essere`
  apart (tr_expand/3, for a verb form or a question word only: an article's,
  a pronoun's and a preposition's keep theirs, which their readers ask for),
  and made the Italian writer elide every `come` before a vowel -- the data
  column found `com'assicurano i palestinesi`, `paesi com'Alemania` and
  `considerato com'il Van Gogh` in ten sentences of the old controls. The
  writer elides such a word only where the lesson says what the elided form
  comes before (`"com'" comes before "è".`, as for a pronoun's;
  tr_elision_written/3), which no lesson says yet.
* **A store learns only the lines it lacks**, appended: an ORDER is a
  property of a teach, not of a line. A data fix is proved on a store taught
  from the rebuilt vocabulary. Teaching both languages into one fresh
  `--embed` store takes ~40 s on 1.10.0 (18 s and 23 s, four vCPUs; it took
  ~11 and ~18 minutes), so **try an ORDER effect on a fresh store before an
  `extra/` line is final**: a working store that had lines appended in
  another order showed a first meaning the fresh one did not (`de riesgo`,
  `cualquiera`).
* **The reasoning libraries read both text units** (1.13.2; bytes were the
  default through 1.x, characters are since 2.0.0). Every
  clause that names an accent or a mark by its UTF-8 BYTES (`[195, B]`,
  `[226, 128, 156]`, `[194, 171]`) has a TWIN that names the CODE POINT
  (`rt_upper_cp/1`, `[8220]`, `[171]`) in reason.pl (the tokeniser,
  `rt_tokens/2`, `rt_run/3`, `rt_letter_next/1`, `rt_word_case/2`,
  `rt_lowers/2`, `rl_vowel/1`, `rl_letter/1`), translate.pl (`tr_cap/2`,
  `tr_cap_head/2`, `tr_lower_codes/2`, `tr_capitals/3`, `tr_capital_start/1`,
  `tr_small_code/2`, `tr_unaccent_codes/2`, `tr_quote_mark/4`,
  `tr_speech_mark/4`, `tr_has_dash/1`, `tr_mid_marks/2`, `tr_inside_dashes/2`,
  `tr_pre_words/2`, `tr_written_number/4`, `tr_number_written/4`),
  normalise.pl (`ng_cap/2`) and corpus/build.pl (`cb_lower_codes/1`). **A twin
  on a code past 255 needs no test** (no byte is so big); **a twin on a code
  of 128..255 asks `rt_chars/0` AFTER its numbers matched**, because there the
  readings meet: 195 is the lead byte of `é` and the code point of `Ã`, and
  226, the lead byte of every dash and quotation mark, the code point of `â`.
  Where a clause can be written with a constant head, the twin is one (no
  inference is spent in bytes). **A new clause that names an accent or a mark
  by a number gets its twin in the same edit**, and a probe in
  test/translate.pl's `newspaper_units` (two children, one per unit; 49
  probes, an arm per rule, 25 of them, each red). The controls on ONE binary
  (1.13.0, KB86, 87 files, 2016 sentences): the translator as it was changed
  208 sentences under characters (188 refused, 20 other texts, +20.7 % of the
  inferences); the one with the twins changes none in either unit, +0.052 % of
  the inferences in bytes and +0.026 % in characters. NOT migrated, and the
  controls found no difference: `atom_length/2` and `sub_atom/5` over an
  accented word count characters in one unit and bytes in the other (the
  thresholds on a stem's length in the clitic rules), and
  `upcase_atom/2`/`downcase_atom/2` change an accented capital in characters
  only (`tr_city_name/1`, `tr_abbreviation_end/1`). Characters is the
  default since cocolog 2.0.0, so the byte clauses and the tests of
  `rt_chars/0` can go -- the reasoning library's change, on its own number;
  until then a program that asks for bytes reads them as before.
* **Find a translator cost with the flow profile, then bisect it** (1.11.4).
  `cocolog -s tools/flow/debug.pl -- GOAL library/reasoning/translate.pl BASE
  embed=STORE cache=DIR profile=true txt=true from=I to=J` over several
  windows of a few thousand steps spread along a run (a refusal of
  65 million steps, say) gives BASE.prof, and a call there is ONE
  step, which is its whole self cost: rank the predicates by CALLS, then
  by their callers. (The library's unit is the STEP, its texts say so since
  1.13.6, and each profile view says how many of a window's steps were
  inferences: a call of true/0 or =/2 is a step and no inference.) Since
  1.11.10 `profile=all` writes the callers, the goals asked again and the
  steps by what took them (constructs included) into BASE.prof -- no script
  over BASE.txt -- and `windows=N` records N windows along the run, J at a
  time, their profiles added up; `svg=false xml=false` for a profile alone.
  Since 1.13.3 `profile=time` (and `all`) writes where the window's TIME
  went, the probe run under a clock read at every step: a count finds the
  cheap step taken a million times, time the one step that costs a
  thousand (a sort, a findall/3's copying, a store's lookup); since 1.15.0
  each row ends ` @W:S`, where its largest call is (window W, step S: a
  window of a few thousand steps recorded around S reads the call with its
  arguments), and `profile=run` (asked by name; not in `all`) writes each
  predicate's self time over the WHOLE run, a probe of its own under the
  clock from the first step, about twice the run's time. A window of
  100 000 steps far along the translator takes ~30 s that way (100 s with every document
  through 1.11.9, whose matcher alone took 36). Half of the inferences were the lexicon lookup layer
  (tr_solve/1, tr_memo/4 and what they call), and its four wastes were each a
  few per cent: `member/2` on a LIST WALKS IT (a clause per element) where the
  first argument is given -- tr_class_of/2 over its fourteen classes, 4 % of
  all inferences; tr_memo/4 read the generation through a predicate and
  compared what a unification does; the lesson's predicate name was built
  through four calls; tr_language/1 is three inferences where the read in
  place is one. An edit that replaces calls by an if-then-else moves nothing
  (the construct is a step too: tr_solve/1's rewrite saved +0), and the
  controls say so in inferences, not the clock -- ask the clock afterwards
  (five alternating pairs, 6 % less user time).
  **Round two (1.11.5) took the layer's idioms, and found them in the same
  windows**: BASE.txt parsed for the CALLERS of a predicate (the parent is the
  nearest line above with a smaller indent) and for the goals ASKED AGAIN --
  in a window of 100 000 inferences 1 528 tr_solve/1 calls were 391 distinct
  goals (74 % repeats) and 648 tr_class_of/2 calls were 71 pairs of a word
  and a class. A repeat is not a memo's to catch: a hit of tr_memo_w/5 costs
  11-13 inferences against 19 for the lesson, and a memo of tr_class_of/2 cost
  37 where the lesson's own answer costs 35 -- it was tried and left out.
  What paid was the idioms: `tr_language/1` is 7 inferences (the if-then-else,
  the catch/3, the read, the `true`), the plain read is 1, and
  `catch(nb_getval(K, V), _, R)` is 3. So the language and the generation are
  MADE WHEN THE LIBRARY LOADS (`:- nb_setval('$tr_language', none),
  nb_setval('$tr_gen', 0).`; tr_memo_reset/0 checks the language too) and the
  hot sites read them plain: tr_solve/1, tr_is/3, tr_lexeme/4, tr_form/5,
  tr_coord/2, tr_memo_w/5. A site that may meet a machine that never loaded
  the library keeps tr_language/1, which answers `none`. tr_prove/2 is gone
  (tr_lesson/2's first clause is `none`); the rule lookup is a plain call of
  the dynamic `lesson/2`, which never raises; the fact call is its own
  catch/3, not tr_solve_plain/1's two steps; the three wrappers are clauses
  with head patterns where an if-then-else asked `atom/1` of what the head
  already holds. A failed lookup went from 29 to 19 inferences, a found one
  from 28 to 20: the 87 controls 4 879 595 021 -> 3 448 261 913 (-29.3 %),
  every status and text the same. **The clock fell less than the count**: the
  eco control 214 939 001 -> 146 057 424 inferences (-32 %) and 17.44 -> 15.77
  s of user time (-9.6 %, five pairs of five), because what is left is a
  memo table COPIED out of its global at every hit (below) and not a step.
  tools/flow/chart.pl finds the clauses an insertion splits (`not together`:
  tr_time_phrase/1, tr_comps_out/7 were found so, 38 old ones remain).
* **Find which piece of a refused sentence fails with the flow record**
  (the owner's ask, 2026-10-28). Run `cocolog -s tools/flow/debug.pl --
  "reason_translate('TEXT', spanish, english, T)"
  library/reasoning/translate.pl BASE embed=STORE cache=DIR svg=false
  xml=false txt=true` once, which says `false at step N`, and again with
  `from=1 to=N`: the window then holds the whole run. The satanic report's
  17th sentence, 1 532 822 steps, took 7 minutes, 8.8 GB and a BASE.txt of
  144 MB; a refusal of 8 million steps does not fit this box. **The
  furthest path at the foot of BASE.txt can name a scan**: it ranks a
  clause by the calls of its body that exited, and tr_read0/4's clause for
  a quotation that opens inside the sentence walks every position with
  append/3, three calls exiting at each, so it was the path (58 calls) and
  had read nothing. **Rank by the steps each clause spent** (a script over
  BASE.txt: a line a call, its depth the indent) and read the arguments on
  the way: the colon's clause spent 648 153 of 1 297 196 steps, its left
  side read and its right side did not, and the right side's words held
  `'$aside1'` where `, Templo Tezcat,` stood -- tr_asides/3's comment of a
  verb in the first person, taken from a name's first word (`templo`, I
  temper), so `Los Satanistas Setumismo` was one phrase. The steps alone do
  not name a cause either: in the right side the most went to the front
  search of tr_read0/4's clause 56. Two probes settle it: without the name
  the sentence reads.
* **Memory**: a teach sat at 4-9 GB resident before the heap collector of
  1.8.36 and peaks near 1 GB since (the Spanish pass, measured on 1.8.40), a
  tagger training is near 10 GB, `test/tagger.pl` alone; on a 14-16 GB box run
  the big ones apart -- a cocolint run
  beside a teach was OOM-killed (exit 137) when the linter still reached
  10 GB; the corpus lint peaks near 3.5 GB now. A killed process never
  flushes. **An arm that removes half of a coupled change can loop and grow
  its heap past 13 GB** (a clause left with an unbound variable): run arms
  under `ulimit -v`, and never beside a teach -- the OOM killer took both.
  `tagger_tag_all/3` keeps a batch's intermediate tensors: tag big grids a
  sentence at a time.
* **A small case lesson reproduces a fault only when it gives the word every
  role the vocabulary does** (and every form: a lesson with one participle
  form cannot test agreement). A guard is proved by an ARM that puts the
  first cut back and goes red; a guard whose arm is green proves nothing.
* **A right text is not a right IR.** English IS the IR; translate into
  English to see what crossed. A refusal with `unknown: []` is a missing
  SHAPE; one that reads into English and refuses into the target is a target
  vocabulary gap.
* **The owner's sample loop** (one article at a time, alternating directions,
  until an article needs no change): build the shapes; add `extra/` lines;
  rebuild and teach a fresh store; then the CONTROLS -- every earlier article
  plus Tatoeba's 400, this translator against the last version's on the one
  store, twice -- and the DATA COLUMN, the last version's translator on its
  own store against the new store, the only place a line of data shows. Fix
  every regression, find every cost by hunk bisection (the heaviest sentences
  of a pass, written to a file and counted over a copy of the library per
  rule: two seconds a copy, where a pass of the controls is two and a half
  minutes), add a section to `test/translate.pl` and to lesson 46, record the
  stated costs. An arm is the same copy run through the section: **one whose
  removal makes the section RAISE has no FAIL line**, so read the last line
  (`GREEN` or `RED`) and count the `ERROR` lines as well. Controls run
  BEFORE the commit. **Merge `origin/master` before the teach** when it moved
  the engine, so the numbers belong to the binary that is committed, and **run
  the whole `test/translate.pl` (half a minute on 1.15.0) before it**: a section
  alone cannot see an older section's check -- the Cecchi section was green for
  days and the whole case had eight red, and the Tempi section's `Persino ...`
  before a subject read `Hasta entonces el perro duerme` as `even the dog`.
  Read the controls' TEXTS, not only their counts: they found a pronoun lost
  (`lo`), a committee made the object, `ma non` written last, a sentence that
  ran to the 300 M inference limit and `l'anima` as `lo anima`; and sum the
  counts by hunk -- a clause that reads the phrase's words a second time at
  every place that read nothing cost 3 %.
  **A refusal can hide a wrong reading**: English refused a clause with no
  subject, and giving it `they` for a verb of saying turned `dijo el
  presidente de la Generalitat, que inauguró` (the speaker read as an object)
  into `they said the chairman` -- look at the IR of what a fix now writes,
  not only at its text, and at a sentence the fix was not made for.
  **Diff the first word of every meaning** between the committed vocabulary
  and the rebuilt one (class and English meaning to first word, gender
  ignored: the writer takes the first noun of a meaning whatever its gender):
  an `extra/` line, a dictionary entry marked `RL` among them, is the first
  word of its meaning wherever it lands in the file. The Abogacía report's
  lines made a feminine `consigliera` the first Italian noun for an adviser
  (every `conseller` was `la consigliera`; the feminines mean a `councilwoman`
  now, so a woman crosses as a woman and the masculine is the adviser),
  `letrado` the first Spanish noun
  for a lawyer (`su letrado`), `president` the first for a chairman, and
  `The word "quienes" follows the preposition.` the relative a Spanish writer
  puts after EVERY preposition (`en el que` was `en quienes`, in 19 sentences
  of the data column); the dictionary's own word is said again first, and a
  line that a reader needs and a writer must not use stays unsaid.
* **Open leads, recorded and not done**: the builder calls a noun a person
  only by its first English word; the upstream verb table
  has `scaping`/`leaved`; `No comas el pan.` reads the subjunctive before the
  negative imperative; `pronto` after a verb crosses as `immediate`; `ir a`
  and an infinitive is the near future and reads as a verb of motion, with
  the infinitive's clitic on it (`nos vamos a quedar` is `ci andiamo a
  rimanere`); Spanish `advertir a los suyos` takes a direct object in
  Italian (`avvertì ai suoi`); `da` before a bare noun is `desde` (`una fama
  desde hábil niño`); `portarsela dietro` is an idiom and crosses word by word
  (`traersela atrás`); a contraction before a quoted article drops
  the opening mark (`de "la casa"` is `della casa"`); a lesson line gives a
  word ONE sense in both numbers (`competencias` are powers, `la competencia`
  the rival firms, and the line for the first moved the second); `su` for the
  owners of a plural crosses as `il suo` (`su futuro` of the shops);
  `afectar a` keeps its `a` (`influire negativamente alle centrali`); an
  adjective after two coordinated nouns agrees with the nearest (`centrali e
  gruppi di spesa spagnola`); `se si elevasse` crosses as `si se elevó`, the
  imperfect subjunctive written as a past indicative; `del quale` is `de
  quién`; `un altro milione` is `un otro millón`; `insomma` at the head of a
  clause is written at its end (`en resumen`); `in termini percentuali` is
  `en porcentajes plazos`; the clitic `ne` crosses as `lo` (`ne potranno
  beneficiare` is `lo podrán beneficiar`); `da` after coordinated participles
  is `desde`; an adjective after a quoted noun agrees with the nearest noun
  outside the marks (`"reddito minimo di inserimento" francese` is
  `francesa`, `si chiama "minimo vitale"` is `se llama "mínima vital"`);
  English writes `Non sono pochi` as `Few are not` and moves a quotation's
  marks to the edges of its phrase; a name of one capital word and an
  adjective (`Roma antica`) is not read; `participar en` is `partecipare
  nel` (`partecipò nell'attentato`) and `a poca distancia de` `a poca
  distanza di`; `fue abatido` is `era abbattuto` (the lesson's past of `è`
  is `era`); `cerca de su casa` is `vicino la sua casa` (the hand lesson's
  `vicino` first, the `de` dropped) and `dentro de` a vehicle `entro`; `su
  esposa` is `la sua moglie`; `huían del lugar` is `fuggirono del luogo`
  (`de` after a verb of motion is not `da`); `pasado` before a day is
  `passata domenica`; `ayer` after the verb is written last (`in questa
  zona ieri`); `heridas` after `causando` is the singular `ferita`; `de
  gravedad` is `di gravità`; `murió un joven` reads the subject as an
  object, as the lesson does not call `morir` intransitive: Italian writes
  it as read and English refuses it (17 and 21 of the Israel report); a day
  fronts a relative clause only as an article and its noun (`que todos los
  domingos visita`, `que cada domingo visita` and `que el 12 de enero
  compró` are refused); `su` after a verb of writing is `en` (`scritto su
  Montanelli`, not `sobre`); the imperfect crosses as the preterite
  (`sapevo` is `supe`, `mi piaceva` `me gustó`); `lo conosco` is `lo sé`
  (the clitic does not say whether it stands for a person or a fact), and so
  is the object of a relative (`il giornalista che io abbia conosciuto` is
  `he sabido`); `la prima di molte lezioni` reads `prima di` as the
  preposition `before` and `il primo era buono` reads `era` as a noun;
  `Dare ordini` reads the infinitive as a subject and `ordini` as its verb
  (`Dar ordena`); `piano` is `plan` after an ordinal (`al terzo piano`, `al
  tercer plan`) and `campioni alimentari` `campeones`; `darsi da fare`,
  `darlo a vedere`, `non ci sono riuscito`, `adesso che ci penso`, `passare
  per la testa`, `in fondo` and `all'opera` cross word by word; a clitic
  cluster is not rewritten (`decirlelo`, `se la ricordava` is `si la
  recordó`); `dei libri da non scrivere` is `desde no escribir`; `Sapendo
  che dorme, lui mangia` reads `lui` as the gerund's object clitic; `ancora
  quindi più cara` after a comma reads `ancora` as the noun (`ancla`); the
  role after `da` is written `as student` into English, with no article; an
  apposition keeps no gender (`la sua compagna` is `su compañero`); `tutti
  quelli` is `everyone those` into English, never `all of those`; `esperar
  que` is `attende che` (hopes that) and `apostar por` `scommettere per`;
  `gran` before a vowel is written whole (`gran asse`, where Italian has
  `grande asse`); a subjunctive after `impiden que` is written as the
  indicative (`che ... è continuo`, `che si permette`); `también` and
  `siempre` are written last (`il passaggio di Vintró anche`); a dash aside
  inside a quotation is written after the whole sentence, outside its mark
  (`"La peatonalización - añade - complementará ..."`); `fincas` are farms,
  `acogerse a` is `riceversi a` and `contar con` `contare con`; `Rambla` at
  the head of a sentence is the common noun (`Passeggio senz'ostacoli`); a
  capital word the lesson knows as an adjective crosses by its meaning unless
  the lesson says it is a name (`"meridiana" is a name.`); English refuses a
  null third-person subject (`asegura`, `añade`), and does not write a
  relative clause `en que esté permitida` or one with a participle and its
  agent after `contará con`: four of the Clot report's sentences stay out of
  English; from the Quartieri report (Italian into Spanish): the words
  `linguaggi` (`idiomas`), `laboratori` (`laboratorios`), `strada` after
  `teatro di` (`carretera`), `sfilata` (`intestino`), `palco` (`etapa`),
  `costumi` (`costumbres`), `opere` (`óperas`), `pannelli` (`tableros`),
  `tele` (`lonas`), `svolgersi` (`actuar`), `contributo libero`
  (`contribución gratuita`), `impegneranno` (`comprometerán`), `saranno
  insieme` (`serán juntos`), `per una settimana` (`para una semana`) and
  `ragazzi` (`niños`; `chico` first broke `bambino`) are the dictionary's
  first word, not the news's; `a` before a place keeps its `a` (`a Harlem`,
  `a Tor Bella Monaca`, where Spanish says `en`: the lesson has no notion of a
  place), a country keeps its article (`desde la Italia`) and a name is
  translated word by word where its words are common (`Alta tensione` is
  `Alto voltaje`, `Sud Africa` `Sur Africa`); a quotation, its verb and then
  the speaker (`..." spiega Nicoletta Gaida`) writes the speaker as an object
  (`explica a Nicoletta Gaida`) and the apposition after it keeps no gender
  (`ideatrice` is `creador`); a quotation inside a quotation (`come
  "delinquenti"`) loses its place; `che da anni coinvolge ... e dal Sud
  Africa l'amajica ...` is one relative clause to the end of its bracket, so
  `desde hace años` is written at the end of the bracket; `nuovi linguaggi del
  disagio giovanile in cui immergersi` attaches `in cui` to `disagio`
  (`en el que`); `"quartieri"` in lowercase marks is translated (`"barrios"`)
  where the lesson names it only with a capital; a name that begins with a
  word the lesson knows (`Lord of the Rings`) is still refused, and `&`
  between lowercase words is dropped (`pane & vino`). A bare noun before
  `di` no longer takes the gender of the noun after it unless it says a part
  (`tasse d'iscrizione` is `impuestos de inscripción`, like the first
  `tasse`; it was `tasas`, by the gender of `inscripción`). English writes
  a weekday with no capital (`thursday 20`), and refuses sentence 20 (`Inoltre un convegno
  (giovedì 20), proiezioni, la mostra dei Murales, ...`: a heading made of
  `La mostra` alone is refused into English).
  The Abogacía report (Spanish into Italian and into English) is read and
  written whole, and its leads are fixed (1.10.3, 172 checks over it). What
  it still leaves: `Se la cava.` has no `cavare` in either dictionary (and an
  idiom of several words crosses word by word); `Os lo digo` was `Ti lo dico`
  -- the lesson language had no second person plural (`coméis` was no word,
  `os` and `vi` were `you`, and the IR's `you` had no number: settled by the
  Tatarella interview below); English writes
  `Lo dejo comer` as `I leave him to eat`, `Lo veo venir` as `I see him to
  come` and `Hago comer el pan al perro` as `I make to eat the bread to the
  dog`: what makes, lets or watches somebody do something is a construction
  of its own -- the doer of the infinitive has no term in the IR (the clitic
  or the `a` phrase stands beside the infinitive), a lesson names no such
  verbs, and `dejar` has no meaning of its own before an infinitive;
  `se limitó a decir` is `limited to say` (English wants `himself` and `to
  saying`, and the IR's noun carries no gender for the pronoun); `más de lo
  que recibe ahora` is `more than the one that receives` (the IR does not
  tell `lo que`, what, from `el que`); the clitic after another clitic or a
  reflexive is read as a thing in English (`me lo apunto` is `I note it`,
  `te lo digo` `I say it to you`), which a person is not (`se lo llevaron`,
  took him away); the Spanish `-ra` form is read as the imperfect it stands
  for after `si`, `como si`, `sin que`, and so it is in the literary
  indicative past of a relative clause or after `después de que` (`donde en
  1988 lograra`, `después de que la lista acusara`: `otteneva`, `accusava`
  where the preterite was; two sentences of the controls, against the many
  it mends: `como si eran pocos`, `si teníamos más`, `sin que figuraban`);
  and the comma before a preposition and its relative is lost
  where the piece has other commas (`reivindicó, ayer, un trato mejor para
  los abogados, a quienes ...` reads `... per gli avvocati a cui ...`:
  keeping it was tried twice and costs the Valencia report's second 1.7
  million of its 9 and the festival report's last 0.4 million of its 3.5).
  The rest of its English is the dictionary's (`a favor de` is `to favour
  of`, `desleales` `disloyals`, `efectuadas` `effected`). **English writes a
  number in its own style** between itself and a language of the decimal
  comma (`tr_decimal_comma/1`: `5.000 millones` is `5,000 million`, `3,5` is
  `3.5`, `10.30` an hour stays; the reader notes the text's style in
  `$tr_numsrc`, the writer swaps the marks of a NUMBER only, and two such
  languages keep their digits), a magnitude after a count singular with no
  `of` (`tres millones de perros` is `three million dogs`), no article before
  a percentage, the adverbs of time and focus before the verb (`also`,
  `always`, `never`: `en_mid_adverb/1`; after a copula or a modal that stands
  alone, in the tail of a question) and `more than`, `about`, `only` before
  the phrase they say how much of (`en_object_adverb/1`). A word with two
  meanings that no SHAPE chooses between still has one: `justamente` is
  justly before an adjective or a participle (`The adjectival adverb
  "justamente" means "justly".`) and precisely elsewhere, as `supone` is
  supposes before `que`; **a meaning the lesson gives a class of its own
  (`intransitive`, `progressive`, `clausal`, `adjectival`) is linked to the
  word's class too, in the order it is said, so the plain meaning is said
  first (again), or the class's meaning becomes the default**
  (`tr_mean_links/3`).
  The Makula interview (VIT-9381..9414, Italian into Spanish: 34 of 34 on a
  fresh store, 16 of 34 before; into English 26 of 34, 15 before) leaves: `per tirar su
  una persona che sta per annegare` is `estirar en una persona que está para
  ahogar`; `fuori dall'acqua` is `fuera desde el agua`; `che ti possa salvare`
  after a negation is `que te puede salvar` (the relative clause's
  subjunctive); `sia stata colta anche lei da sincope` is `la haya sido
  sorprendida también desde síncope`; `non conta nulla che dopo venga portata
  nel miglior ospedale al mondo` is `no cuenta nulo que es traída en el
  hospital mejor al mundo después`; `entro un minuto` is `antes de un minuto`;
  `anche`, `sicuramente` and `también` stand last where Spanish puts them
  after the verb; `Cos'altro le devo dire?` (what else) is REFUSED now -- the
  `¿Cosa debe otro decir?` it was had `otro` for a subject, and a question
  word with `altro` is a shape of its own (`qué más`); English refuses eight
  (4, 5, 7, 10, 11, 12, 27, 32), most for the third person nobody names,
  which it refuses on purpose. The angled marks come back mixed, an opening `«`
  and a closing `”` (`«Il cane dorme”, dice il gatto.`), in bytes and in
  characters alike (the cause is not looked for).
  The Hotel Arts auction (CESS-CAST-P-20011202-66, 17 sentences, Spanish into
  Italian: 15 of 17 on a fresh store, 6 before; into English 15 of 17, 5
  before; reasoning 1.0.1). It needed these SHAPES, each with its arm red:
  a one of a plural for a subject (`Uno de sus principales accionistas es La
  Caixa`: `uno` is the first person of `unir` too, `tr_part_of_subject/1`); a
  phrase with no article between two dashes after a noun or a name, a name
  with a bracket in it (`- - Strategic Hotel Capital (SHC) - -`), the closing
  dash that ends the sentence, a relative clause between dashes that ends it;
  who said so right after a bracket, and the relative clause after the
  comment taken into it (`(288,4 millones de euros), según informó ayer la
  agencia Efe, que cita fuentes`); an adjective before a date's day (`el
  pasado 11 de septiembre`) and the article chosen for the DAY (`dell'8
  settembre`, `del 1 settembre`); a silent h (`l'hotel`, `nell'hotel`,
  `l'ha`: Italian and Spanish only, English keeps `a hotel`); a list that a
  `between` opens keeps its commas together; a noun the lesson states in both
  genders is written in the gender of its meaning (`el capital` the money,
  `la capital` the city: `tr_meaning_gender/5`, the writer's half of
  `tr_gender_links/3`); an adjective after a name that stands right after its
  determiner is the name's (`la Barcelona olímpica`); a word that begins the
  purpose, straight before an infinitive and after a noun or an adjective, is
  no verb (`un solar apto para levantar otro hotel`); an adjective that does
  not agree with its noun in number keeps its own (`agrd/3`: `un espacio de
  oficinas anexo`, `fuentes del sector conocedoras`); a word the lesson says
  is a name is one with its capital inside a phrase (`el grupo inversor
  catalán Metrópolis`). It needed these WORDS in `extra/` (the two readers: a
  line moves the reader of one language and the writer of the other):
  `inmueble`/`immobile` (real estate), `hotelero`/`alberghiero`,
  `preacuerdo`/`preaccordo`, `fondo` (fund, not the background), `fuente`
  (source, not the fountain), `inversor`/`investitore`, `conocedor`, `cinco
  estrellas`, the masculine `capital`/`capitale` (share capital), `anexo`,
  `solar`/`terreno edificabile`, `apto`/`idoneo`, `aspira` (aspires),
  `empresaria`/`imprenditrice`, `sede` before `quartier`, `albergo`, `banca`
  before `argine`, `acquisto` before `spesa`, `edificio`, `gestione`,
  `filiale`, `passato` after its noun, and the two names `Hotel Arts` and
  `Metrópolis`. The CONTROLS (cocolog 1.13.6, store KB93, 89 count files, 2 050
  sentences): the last version's translator against this one, 24 sentences in
  8 files read differently -- 16 in the report's two files, and 8 elsewhere
  (carrefour 22 and 23, e_senegal 26, fiat 11 and 16, israel 15, mobile 9,
  senegal 23: an adjective agreeing with its noun, `gruppi d'acquisto
  spagnoli`, `forze di sicurezza palestinesi`; `l'hanno`; `del capitale più
  prezioso`; English `a competitive Senegal`), all better -- and the
  inferences fall 0.89 % (3 595 025 781
  to 3 563 106 210), 0.0056 % without the report's files; bytes and characters
  read every sentence alike (0 differ, the characters 0.024 % fewer). **The
  binaries of 1.13.3 and 1.13.6 give the same texts and the same inference
  counts to the unit on both translators** (1.13.4's catch/3 frame, 1.13.5's
  `=/2`, 1.13.6's names changed nothing the translator counts). The report's
  tenth sentence costs what it did, 119.9 million inferences to its refusal
  (119.1 for the last version); an alternative that let a comma follow the
  closing dash made it 42.0 and was taken out, below. The DATA COLUMN (the
  last version's translator on its own store, KB86, against this one on the
  new): 51 sentences in 20 files, 27 outside the report's, each a word of the
  report's lines said first -- `fuentes` are sources (5 English sentences, not
  fountains), `fondo` is a fund (4: e_clinton 5 and 12, e_lotr 4, e_mobile 3),
  `acquisto`/`d'acquisto` (3 and the purchasing groups of carrefour), `passato`
  after its noun (clot 6, puigbo 4 and 7), `empresaria` (letter 3), `capital`
  (e_fiat 5 and 16) -- and the 8 of the code. THE STATED COSTS: eco 11,
  `Ma immobile non voleva dire piatta`, was `inmóvil` and is `inmueble` (and
  English `real estate`): the line that makes `immobile` the noun the report
  writes makes a bare `immobile` the noun in the reader as well -- a bare word
  is read as a noun where the lesson has one, and the adjective said first
  (the dictionary's own, `motionless`) was tried and changes nothing; and the
  masculine `capital` is `share capital` in English. **A comma right after the
  closing dash is NOT let through** (the guard's sentence, B6): the first cut
  took `- -,` and the Spanish store read `el fondo - - Strategic - -, aliado
  con un consorcio, duerme` as a piece with no verb and `duerme` its
  imperative -- `dormi` -- where the last version refused it; no hand lesson
  reproduces it (it has no imperative), the guard pins the refusal. The
  report LEAVES: sentence 10 (`el fondo participado por Prudential y
  Goldman Sachs - - Strategic Hotel Capital (SHC) - -, aliado con un
  consorcio español integrado por ... Metrópolis (en el que participa la
  familia Lara, propietaria del grupo editorial Planeta)`), refused: a dashed
  aside followed by an adjective or a participle phrase, with or without the
  comma, is no noun phrase (`tr_np/3` takes an aside token only last, and the
  gloss clause for a bracket before an adjective would write the name between
  the participle and its complement; the aside after it, `app(app(NP,
  dashed, N), aside, Comps)`, is the shape to build), and a bracket after a
  name that opens on a relative clause loses its marks (`Metrópolis in cui
  partecipa la famiglia Lara proprietaria del gruppo editoriale Pianeta`,
  where `Planeta` is a name and is written as the planet); sentence 14 is a
  defect of the source, two of its four dashes are lost (`en España - - más
  de 80.000 millones de pesetas (...) a finales de 1998 como al valor
  contable de los activos 68.700 millones (...) - -`) and no reading puts
  them back. Of the 15 it reads, what is not right: `Londres` stays (a
  capitalised word the lesson knows after a preposition is a name, and there
  is no city by the vocabulary; `in Londres` is `a Londra`), `in Stati Uniti`
  is `negli Stati Uniti` (a country keeps its article in Italian), `cambiar
  de propietario` is `cambierà di proprietario` (Italian says `cambierà
  proprietario`) and `comprar a` writes `al gruppo` (`dal`), `uno de los
  mayores` after `banco` is `uno dei maggiori` where `banca` is feminine (the
  gender of an elided `uno` follows the noun the sentence names, which the
  lesson does not carry), `otro hotel` after a verb is `altro albergo` (`un
  altro`), `terreno inmobiliario` is `terreno immobiliare` (`campo`), a
  relative clause between dashes in a subject writes the pronoun again in
  English (`that they house`), `anexas` after a plural subject is read as a
  verb form (`Las galerías anexas son grandes` is `Le gallerie attaccano sono
  grandi`), `una casa de Pedro cansada duerme` is refused, and a weekday
  before a date's day in front of the clause (`El jueves 9 de marzo el hotel
  cambió de dueño`) is written after the clause with the day and no article
  (`... 9 marzo giovedì`).
  The Tempi del governo report (VIT-9673..9712, 40 sentences, Italian into
  Spanish: 39 of 40 on a fresh store, 28 with the new store alone, 13 before;
  into English 36 of 40, 25 and 11; reasoning 1.0.2). It needed these SHAPES,
  each with its arm red (test/translate.pl's `newspaper_tempi`: 60 checks, 48
  arms; a guard stays only where its arm goes red, and the guards of the
  reporting clause before a colon and of the perfect cleft had none): a name
  the lesson states, before a comma, takes no comma into its run of words
  (`dei cristiano democratici Casini, Mastella, D'Onofrio e del popolare
  Sanza`: `tr_stated_run` asked each word through `forall(member(w(X, C),
  Run), ...)`, whose pattern a comma does not match, so the comma was never
  asked); a capital `D'` before a capitalised word is a surname's particle
  (`Massimo D'Alema`, `Tommaso D'Aquino`, `tr_elision_names0/2`; the small
  `d'` is the preposition still, `il governo d'Alema`); two names with a dash
  between them after a noun are one name (`colloquio Berlusconi - D'Alema`,
  `tr_dash_names/3`), and a bare noun and a name are a heading; a
  demonstrative and an article at the head of a piece have their copula read
  in (`Questo il testo del documento`, `tr_demonstrative_copula/3`; a
  demonstrative that a verb follows is the subject); a quotation right after a
  verb of saying, with no mark between them, is what the verb says (`il Polo
  ha risposto "vedo"`); the word for `all` before a bare singular noun is one
  phrase with it (`con tutta evidenza`, `tr_np/3`; before an article it is the
  pronoun, as it was); a noun that is the first person of a verb, before
  `che`, starts a clause (`credo che stavolta ...`, `tr_first_person_that/2`);
  a day opens the clause of `quando` (`tr_nested_front/3`), `quando` is no
  adjective of the day after it (`tr_adj_word/2`), and an adverb right before
  `quando`, or before the `o` of an either-or, leads the sentence in; a
  heading of bare nouns in a list (`Forzatura, distinguo e bacchettata.`,
  `tr_bare_title/3`; two nouns joined by `e` are no list); among nouns that
  are adjectives too, the one that has a plural to be heads a phrase that a
  plural numeral opens (`due sole alternative`, `tr_plural_hint/4`); an adverb
  between the auxiliary and its participle keeps a perfect infinitive (`di non
  aver affatto abbracciato`), and `già` is an adverb of degree before a
  participle; a day and a phrase that names, the verb left out (`Martedì tutti
  attorno al tavolo.`); a bare noun and an adjective with its intensifier
  (`Mediazione particolarmente faticosa se ...`, which joins the clause after
  it, `tr_join_left/5`; `Big house.` stays refused); a plural noun and its
  phrase of `of`, at the head of a piece with no other verb (`Sviluppi delle
  trattative in atto ...`, `tr_noun_heading_start/1`: `sviluppi` is a command
  too); a verb of two words with an adverb between them (`risente invece del
  punto di vista`, `tr_multi/2`; before an infinitive `invece di` is the
  preposition); a verb of saying and its speaker before the colon are the
  reporting clause (`Spiega il popolare Sanza: "..."`, `tr_colon_left/4`), and
  a quotation that closes at the first comma with only a reporting clause
  after it divides before it is read whole; a phrase that is not `of`, after a
  participle with no adjunct of its own, is the participle's (`Il Comunicato
  diramato dopo quasi tre ore`, `tr_participle_adjunct/4`); a verb of several
  words is shaped by its first (`gives credence to` for `accredita`,
  `tr_phrasal_shaped/1`); the word for `all` before the shape of a phrase has
  its shape (`Tutti gli altri hanno perplessità`, `tr_subject_shape/4`);
  `anche`, `persino` and `solo` before the subject are said of it (`Anche
  Gianni Letta ha parlato` is `También Gianni Letta ...`, where it was `... ha
  hablado también`), English keeping `even` in front and writing `also` with
  the verb, never `Also the dog sleeps` (`en_subject_adverb/4`: the controls
  found six such sentences); never a word that is a preposition too
  (`tr_focus_front/1`: `hasta` is `until` before it is `even`, and `Hasta
  entonces el perro duerme`, the radio section's guard, was red in the whole
  case only -- the adverb `entonces` lifted out of the words left `hasta el
  perro` to read as `even the dog`, which no section of the new report could
  see; its arm is that guard); a cleft whose infinitive is in the perfect (`è
  il solo Segni ad aver sposato questa opzione`), `solo` before the name of a
  cleft (`tr_cleft_who/4`), an article before a perfect infinitive (`l'aver
  ceduto`); a verb of beginning with an infinitive after it takes `has` for
  its perfect (`ha iniziato a raccogliere`, `tr_beginning_verb/1` in the
  writer: the lesson's `"è" is the auxiliary of "inizia".`, which `È iniziato
  il vertice` needs, had made it `è iniziato a raccogliere`, carrefour 7);
  `più` in a denied clause is English `anymore`, written last (`Non ci sarà
  più spazio per i bluff`, `Non la ricorda più nessuno`); `si fa` before an
  adjective is English `becomes`; and `solo che` is `only that`.
  It needed these WORDS in `extra/` (the two readers: a line moves the reader
  of one language and the writer of the other; where a word must stay the one
  written, the dictionary's own line is said again first -- Italian `emette`,
  `teme`, `distinzione`, `ritorna`, `amministra`, `unisce`, `riflette`,
  `episodio`, `ammonimento`, `convenzionale` and `superficiale`, Spanish
  `linterna`): `dirama` (issues, and its participles), `paventa` (fears),
  `distinguo`, `vertice` (a summit, not the peak), `rimette` (gives back),
  `bacchettata`, `puntata`, `stavolta`, `decina`, `oppure`, `eppure`, `melina`
  (stalling), `bluff` (a poker bluff; Spanish `farol`), `leghista` and `par
  condicio` (kept as they are), `dita` (the feminine plural of `dito`),
  `accredita` (gives credence to), `risente di` (reflects), `scosta` and
  `apparta` (moves aside), `aggrega` (joins), `affatto`, `va in scena` (takes
  place), the adverbs, prepositions and adjectives of several words (`l'altro
  ieri`, `subito dopo`, `ogni giorno`, `per strada`, `da una parte`, `da
  l'altra parte`, `attorno a`, `in atto`, `di destra`, `di maniera`, `a doppio
  turno`; Spanish `anteayer`, `justo después de`, `por el camino`, `por la
  otra parte`, `alrededor de`, `en absoluto`, `en curso`, `de derechas`, `a
  doble vuelta`), `cristiano democratico` and `cristianodemócrata`, `centro
  destra` and `centroderecha`, `solo che` and `sólo que`, the auxiliaries of
  `inizia` and `comincia` (the copula), `o` and `ad` that begin a choice and a
  cleft, `popolare` a title, and the names `Fini`, `Polo`, `Olivo`, `Massimo`,
  `Letta`, `Segni`, `Bianco` and `Casini`; and in the two dictionaries' extras
  `matchstick` (`fiammifero` first both ways, `cerino` read only, `cerilla`
  left to right only), `short`/`corto` and `issue`/`questione` (both ways),
  `burn`/`scottare`, `forcing`, `promulgate`/`varare`, `presidentialism`,
  `attainment`, `sensation`, `stalling`/`dilación`, and the adjectives
  `punitive`, `unconstitutional`, `laborious`, `distrustful`, `constituent`
  and `Berlusconian`.
  The CONTROLS (cocolog 1.15.0, store KB107, 93 count files, 2 198 sentences):
  the last version's translator against this one, 21 sentences in 20 files
  outside the three newest reports (this one, the Makula interview and the
  Hotel Arts) read differently (carrefour 7, cecchi 7, eco 21 and 26, fregene
  10, giglio 6, livata 8, lotr 11, montanelli 20 and 28, salvini 9, senegal 1
  and 6, tat 4, twelve 9, valencia 3: the focus adverb before the subject,
  `D'Aquino`, `ha iniziato`, `scosta`, `anymore`, `become`, `give credence
  to`, one that failed and reads), all better -- and the inferences fall 5.148
  % (4 484 481 501 to 4 253 601 294), 0.278 % outside those three (3 221 894
  127 to 3 212 933 629), and 43.0 % in the Hotel Arts report's two files,
  whose tenth sentence is refused after 46.6 million inferences where it took
  120.0 (not looked for); the file that rises most is solana's, +2.5 % of 15
  million. Bytes and characters read every sentence alike (0 differ, the
  characters 0.021 % fewer). The binaries of 1.13.7 and 1.15.0 give the same
  texts and the same inference counts to the unit on both translators
  (1.14.0's shifts and 1.15.0's clock and error names changed nothing the
  translator counts). The DATA COLUMN (the last version's translator on its
  own store, KB93, against this one on the new): 32 sentences in 21 files
  outside those three, each a word of the report's lines or a shape of its
  code -- the focus adverb before the subject (8: eco 26, fregene 10, giglio
  6, montanelli 20, salvini 9, senegal 1, valencia 3 and the English of
  valencia 3), `subito dopo` (4: eco 6 and twelve 8, in both languages), and
  by twos `vertice` (cecchi 21: `cumbres`), `da l'altra parte` (eco 19),
  `D'Aquino` (eco 21), `scosta` (lotr 11), `give credence to` (twelve 9) and
  the place of `certainly` (livata 8), and one each `Marco Polo` (astro 4),
  `anymore` (montanelli 28), `become` (senegal 6), `el asunto` for the issue
  (eco 15), `en torno` (fregene 19), `Move aside` (tat 4), `por` for `per
  strada` (livata 15) and a comma (cecchi 7). THE STATED COST: eco 6, `Salvo
  che subito dopo i due dialoganti hanno osservato che erano state perdute
  ...`, was `los dos dialogantes han observado inmediatamente después que` and
  is `han observado justo después de los dos dialogantes que` (English `have
  observed right after the two dialoguing ones that`): `subito dopo` is the
  adverb there, and the line that makes it a preposition, which `subito dopo
  la fine del vertice` needs, takes the two interlocutors for its object and
  leaves the verb a subject nobody names; the sentence costs 1.08 million
  inferences and now 1.31.
  Written, found to move no sentence of the controls and no check, and taken
  out (each hunk reversed over the full controls): the `fo_np_number`
  alternative, a heading of a choice in `tr_verbless0`, `tr_skip_adverbs`, a
  first-person guard in `tr_conjunction_split`, an English writer clause for
  the connector `cmid/1`, `tr_time_adverb_comp/1` and a split of a quotation's
  number; a fix for English `"X", dice Y, "verb ..."` (refused) went the same
  way, no sentence reaches it. **A clause added to `tr_read0` costs about five
  inferences a call before its first test fails**, so the first cut of the
  shapes cost +0.54 % outside the new reports; what paid was a memo for
  `tr_focus_adverb/1`, the selective test first in `tr_complements0/4` (the
  article before a perfect infinitive) and the question words of
  `tr_adj_word/2` folded into the test they were added to. The report LEAVES:
  sentence 20 (the communiqué's second quotation, `"al tavolo non può trovare
  spazio", prosegue il comunicato, "l'individuazione della maggioranza ... e
  men che meno la durata del medesimo, essendo compito esclusivo del
  parlamento, ..., fornire al capo dello stato tutti gli elementi ..."`),
  which runs to the limit of 300 million inferences in both languages, as it
  did at the start (22 s); and English refuses 17, 31 and 39, the third person
  nobody names, on purpose. Of the 39 it reads into Spanish, what is not
  right: a predicate after a heading takes the heading's gender (`Melina tra
  Polo e Olivo e il voto è più vicino` is `Dilación ... el voto es más
  cercana`); `a Montecitorio` and `al tavolo` keep their `a` (`en`), `sul
  conflitto` is `en el conflicto` (`sobre`) and `varare in parlamento sugli
  stessi argomenti norme punitive` is `promulgar en parlamento en los mismos
  normas argumentos punitivos`; `sia andato in scena un classico` is `ha
  tenido lugar a un clásico` (the subject after the verb has an `a`); `quando
  ... torneranno` keeps the future (`cuando ... regresarán`, where Spanish
  wants the subjunctive) and `convinto che` is `convencido que` (`de que`);
  the time adverbs stand last (`l'altro ieri` in 12, `ieri` in 13, `Ora` in
  36); `non lasciano ben sperare` crosses word by word; sentence 16's list of
  names loses its order (`dei cristiano democratici Casini, Mastella,
  D'Onofrio e del popolare Sanza` is `de los cristianodemócratas Casini para
  simplicidad, a Mastella, D'Onofrio y Sanza`, with `del popolare` left behind
  as `del poblar`, the verb, and English `Casino`), `sposare` is `casar` and a
  quotation inside a quotation leaves a stray mark; `da una parte ...
  dall'altra` is `por la otra por una parte`; `un alleato come segni` is `como
  signos` (a name written small); `senza par condicio niente elezioni` is `sin
  par condicio nada elecciones`; `parla invece di Mario` is `habla en vez de
  Mario` (`invece di` the preposition, the verb being `parla di`); `Hasta mi
  mamá lo sabe` stays `My mum knows him even` (`tr_focus_front/1` leaves out a
  word that is a preposition too; to have both, `tr_adverbs_off/4` would keep
  a preposition's adverb, where it lifts `entonces` out of `hasta entonces`
  and leaves `hasta` bare). English: `spazio` is `blank` (`no blank for the
  poker bluffs anymore`), `incontrarsi` is `find` (`return to find tuesday`),
  `elezioni` were `choices` (settled by the Tatarella interview below), a
  relative clause with no subject of its own
  writes `they` (`an interview in which they clarified`) and `a quell'ora`
  stands last (`to that hour`).
  The PSOE and PNV report (AnCora CESS-CAST-P-20000903-30, 21 sentences,
  Spanish into Italian and English: 21 of 21 and 18 of 21 on a fresh store, 17
  and 14 with the new store alone, 8 and 7 before; reasoning 1.0.3). It needed
  these SHAPES, each with its arm red (test/translate.pl's `newspaper_psoe`: 38
  checks, 21 arms): a pronoun joined to the infinitive after the word for
  `upon` (`al reclamarle que mantenga ...`: the clause is `upon(cl(L, Cls),
  Cs)`, and `tr_cross_comp/2` and both writers know it -- Italian puts the
  pronoun on the gerund, `chiedendogli`, English after it, `on demanding him`;
  four arms, the reader, the cross and each writer) and an `upon` clause that
  reads to no comma is read whole (`fue más lejos al precisar que esa actitud,
  "que no tuvo el PP en su día", es la que ...`: the first comma is the
  apposition's, `tr_upon_rest/5`); a verb of saying takes a person and then a
  clause whether or not the lesson says it takes the clause (`replicó a
  Ibarretxe que ...`: `tr_person_words/3` asks `tr_saying_verb/1`), `retorts`,
  `demands`, `asks`, `requests` and `urges` being verbs of saying to English
  (`en_saying/1`, which the Spanish reader asks as well); the clause after a
  person may open on a pronoun of its verb, on a conjunction of its own or on
  a phrase set in front of its subject (`avisó a Ibarretxe de que a su Gobierno
  el tiempo se le acaba`, `tr_clause_after_person/1`); English `bets on` and
  `distances from` (`en_governs/2`); an insertion with an adjective phrase and
  no verb (`Zapatero, aunque fiel a su consigna de no arremeter contra el PP,
  sí se permitió ...`, the fragment a headline is) and what stands between its
  closing comma and the verb, adverbs, which become the clause's complements,
  and pronouns, which stay with the subject's side (`tr_insertion_off/4`,
  `tr_insertion_tail/3`); `fue` is the preterite of `ser`, not of `ir`, when
  nothing goes (`fue una equivocación`, `ayer fue ...`: `tr_ser_not_ir/4`,
  asked in the clause that takes its subject after the verb and in the
  fronted inversion; with a place or a phrase of `to` after the traveller it
  is the verb that goes); the word for `that` after a verb of saying is no
  `than` (`fue más lejos al precisar que esa actitud ...`:
  `tr_compared_before/2` takes the `que` it is asked about by the words that
  follow it and not the first of the piece, looks back no further than the
  `que` before it, and asks `tr_that_follows_saying/2` -- three arms, and the
  one for the place is a relative `que` and then a real comparison, `La casa
  que duerme es más grande que el perro`, which the controls broke in two
  sentences without it, mobile 7 and salvini 28); a copula reports nothing
  (`La casa, que compró Pedro, es la mejor` has no comment at its end,
  `tr_reporting/3`: football 10 falls 42 % and cecchi 24 2 % for it, the
  clause of who said so no longer read for a copula); a verb among the words
  before a phrase set in front of the pronoun that takes it up again makes
  them a clause of their own (`Dijo que el perro lo come`, which the cut after
  the dislocation's condition refused, `tr_read_statement0/4`; the cost
  below); and the tonic `sí`, which the lesson says never precedes the verb,
  is an adverb before it (`Pedro sí duerme`, `tr_clitic/2`).
  It needed these WORDS in `extra/` (the dictionary's own word said again first
  where it must stay the one written: Spanish `acuerda`, Italian `chiede` asks
  before it demands): Italian `discorso` (a speech, not an address), `al
  momento di`, `chiude la porta`, `come si evince da`, `chiede` (demands, and
  takes the clause), `concorda` (before the dictionary's `accorda`), `auspica
  di`, `punta` (bets, `su`), `distanzia` (`da`), `critica velata`, and in
  eng-ita.dix `distanziare`, `antiterrorista`, `schizzinoso`, `tessere`,
  `disposto`, `potenziare`, `sabotare` for torpedo, `errore`, `sottolineare` and
  `confronto` (written only); Spanish `a la hora de`, `avisa` (the clause and
  `de`), `velada crítica`, `conviene` (suits, and the clausal agrees with
  `en`), `según se desprende de`, `da portazo`, `aboga` (`por`), `apuesta`
  (`por`), `distancia` (`de`), `confrontación`, the name `Mayor Oreja`, and in
  eng-spa.dix `distanciar`, `antiterrorista`, `remilgado`, `torpedear`, `tejer`
  and, read only, `arremeter`, `tremendismo`, `recomponer`, `espetar`, `senda`,
  `crispación`, `consigna`, `precisar` (specifies), `trasladar` (conveys) and
  `potenciar`. The first word moved in 7 Italian and 4 Spanish meanings
  (speech, agrees, bets, boosts, demands, distances and weaves in Italian;
  boosts, conveys, rebuilds and weaves in Spanish), and the first meaning of
  5 Spanish words and 1 Italian word moved too (`confrontación`, `potencia`,
  `precisa`, `teje`, `traslada`; `tesse`).
  The CONTROLS (cocolog 2.0.0, store KB116, 95 count files, 2 240 sentences:
  every earlier article, Tatoeba's 400 and the new report, both directions):
  the last version's translator against this one, on the one store, 4
  sentences in 2 files read differently (clot 14 in English, `bets on` for
  `bets for`; tat 69, 222 and 278, `fue` as was and not went: `Tom was`, `It was
  your idea`), all better -- and the inferences fall 1.273 % (4 574 388 857 to
  4 516 160 393), 0.0007 % outside the new report (4 253 642 195 to 4 253 610
  973, the Hotel Arts report in), that report's two files rising 0.012 %. The
  file that rises most is senegal's, +1.5 % of 123 million (its second
  sentence, below), and the one that falls most football's, -1.2 % (its tenth,
  a copula that reported). Bytes and characters read every sentence alike (0
  differ, the bytes 0.021 % more). The DATA COLUMN (the last version's
  translator on its own store, KB107, against this one on the new): 14
  sentences in 6 files, each a word of the report's lines: `reclamar` is
  `chiedere` (abogacia 1, basque 3, carrefour 4, 5, 6, 14 and 20, clot 20,
  football 13: `reclamò` is `chiese`, and the clause after it is in the
  subjunctive now, `chiese che il Tribunale ... intervenga`), `scommette per`
  is `punta su` (clot 14, and English `bets on`), and the three of `fue` above.
  THE STATED COSTS: `precisar` is `specifies` before it is `requires` and
  `trasladar` `conveys` before it is `moves` -- the dictionary's lines marked
  for reading come first, and the article needs both (`al precisar que`,
  `trasladará al lehendakari la posición del PSOE`) -- so `La empresa precisa
  más tiempo` is `L'impresa specifica più tempo` and a man `trasladado` to a
  hospital is conveyed: no sentence of the controls has either, and a lead;
  and the dislocation's own cost, FOUND BY TAKING EACH RULE OUT (the fourteen
  heaviest sentences counted over a copy of the library per rule, two seconds a
  copy): the first cut, the cut moved after the subject read, cost +21.1 million
  inferences outside the new report and the Hotel Arts one (+0.52 %), all of it
  in four sentences (eco 15, 22 and 25, senegal 2). When the words before the phrase read as no
  subject the clause failed with the condition's choices kept, and the long
  front was parsed again at every other determiner (eco 25: 2.8 million), and
  the clauses after it were asked of sentences none of them reads (eco 22,
  `Che poi queste cose le sapessero i dotti ...`, whose `che poi` has no verb:
  2.5 million). The first front is taken once now (`once/1`, as the cut did),
  and the cut stays unless a verb stands among the words before the phrase.
  What is left is eco 15 and senegal 2, 1.7 million inferences each (a 42 % and
  a 7 % rise of the sentence), where the words hold a verb and read as no
  subject and the clauses after the dislocation are asked and read neither.
  Written and taken out: a test that the words before the phrase end on `que`
  after a clause (free of cost, and it fixed `Dijo que el perro lo come`, but
  sentence 20's words end on `a`: `avisó a Ibarretxe de que a su Gobierno ...`);
  the pronoun's agreement asked before the subject (the cost did not move); and
  the soft failure for any unreadable subject (+0.14 %, eco 22's `che poi`). **An arm
  that makes the section RAISE is red with no FAIL line** (the English writer's
  clause for `upon(cl(...))` taken out: a `type_error` out of reason_translate/4
  ends the section) -- the arm driver counts `ERROR` lines and reads the last
  line, `GREEN` or `RED`. The report LEAVES, of the 21 into Italian:
  `partido` is the match before it is the party (`tutte le partite democratiche`,
  `la sua partita`); the quotation `se "digan las cosas claras"` loses its
  opening mark (8); in 5, `di non d'assalire contro il PP` (a second `di`,
  elided, before the infinitive), `si permise fare` (no `di` before the
  infinitive of `permitirse`) and the comma after the insertion lost;
  `avvertì a Ibarretxe` (Italian says `avvertì Ibarretxe`) and English `warned
  to`; `de haber sido votado` is `d'avere stato votato` (the perfect passive
  infinitive); `dispuestos a buscar` is `avuti a cercare` (the participle of
  `dispone`, which has); `fue más lejos` is `fu più lontano` (went further:
  the copula); `sí` is written last (`non contribuisce ... sì`); `se le acaba`
  is `si gli finisce` (the idiom is `gli si sta esaurendo`); `digan` and
  `gobierne` in a clause of `que` are written in the indicative; `unidad de fondo
  sólidamente arraigada` keeps its Spanish between marks; `senda` is `traiettoria`
  and English writes `cuidadoso` as `accurate` (12: `showed very accurate`),
  `aboga` as `advocate` (2: `Advocate to weave a solid unit and of fund`) and
  `warned to Ibarretxe` (20); English refuses 5, 11 and 13 for the third person
  nobody names, on purpose (`aunque ... sí se permitió ... al reclamarle que
  mantenga`; `espetó al presidente que es la hora de que "gobierne"`; `Anunció
  que trasladará al lehendakari ... pero evitó`).
  The Tatarella interview (VIT-9714..9749, 36 sentences, Italian into Spanish
  and English: 36 of 36 and 36 of 36 on a fresh store, 25 and 25 with the new
  store alone, 16 and 16 before; reasoning 1.0.4). It needed these
  SHAPES, each with its arm red (test/translate.pl's `newspaper_tatarella`: 34
  checks, 19 arms and 5 guards, each guard red when its rule is made too wide): a
  pronoun and a phrase of `of` for a subject (`qualcuno di voi sta giocando con
  carte truccate`: `qualcuno` is a pronoun and no determiner, as `nessuno`,
  `uno` and `alcuni` are, and the subject shape wanted a noun, a name or a
  determiner, `tr_subject_shape/4`'s last alternative); THE PLURAL OF `YOU`,
  which the IR never had outside a subject (`Hablo de tú`, `te acusa`, `ninguno
  de tú`, the lead of the Abogacía report): a word of the IR where it is no
  subject, `you all`, made by `tr_pronoun_across/6` for a pronoun the lesson
  says is the plural of one that means `you` (`tr_plural_you/1`: `"voi" is the
  plural of "tu"`, `"vi" is the plural of "ti"`, Spanish `vosotros` and `os`, in
  corpus/extra), written `you` by English and as the plural of the pronoun the
  role takes by the lesson's language (`voi`, `vi`), the reflexive of a plural
  subject (`voi vi lavate`, `tr_personal_object/3`) and the plural subject
  itself (`voi direte elezioni`, `tr_subject_pronoun/4`) following it -- six
  arms; a question is no command (`Sembra poco?` has the spelling of an
  imperative, whose clause took the sentence and, its cut kept every other
  reading from it, left the question refused, `tr_read/4`); a clause of `that`
  and nothing else is a fragment (`che è stato un incidente di percorso`, the
  line after `diciamo che ...`, `tr_that_fragment/4`: asked for the WHOLE piece
  after every other reading, because as a clause of `tr_read0/4` it took the
  first half of eco's `Che poi il cane dorma, guardate che ...` apart and the
  whole case found it) and one left open (`diciamo che ...`, `that_open/0`); a
  name before a colon is a heading (`Tatarella: i trucchi sono vietati`,
  `tr_heading_left/3`); a participle and an infinitive with no subject are said
  of the infinitive (`con un patto: vietato truccare` took the gender of the
  table before the colon, `prohibida amañar`, `tr_gap_comps_out/3`); an article
  and a possessive before a noun that is a participle too are no reduced
  relative (`la loro proposta` was `el ellos propuesta`, `tr_np/3`: asked after
  the participle test, before it +0.8 % of the heaviest sentences); which with
  a verb of the first or the second person asks for its object (`Quale libro
  leggi?`, `fo_question_word/3`); a word the lesson gives `what` asks with the
  phrase after it as `quale` does (`e che colpa ha se la loro proposta è
  interpretata ...?` is which fault; `tr_which_asks/2`), with a NOUN OR AN
  ADJECTIVE at the head of the phrase and no determiner -- `cosa le posso dire?`
  has `le` for the clause's own, and the first cut, any phrase word, refused
  sentence 3 of the article and no sentence of the 18 probed with `cosa` showed
  it (the re-run of the article did; the guard is `cosa il cane vede?`); two
  questions with a comma between them (`e perché mai, e chi lo dice?`,
  `tr_question_half/2`); a question with no mark, a comma and a statement
  (`cosa le posso dire, sarà stato un equivoco`: the question half is marked
  `qh/1`, and the join writes it as a question -- the first cut wrote any join
  whose first clause asked for something so, and Cecchi's `che, dicono a Raidue,
  è raggiante` became `what do they say`, the one text the controls found);
  `se e in che modo` opens an indirect question (`tr_indirect_word/3`); and THE
  FORM OF A COMMAND, which Italian's second person plural of the present
  indicative is (`aprite`, `guardate che ...`, `non pensate che ...`) and
  Spanish's present subjunctive its negative one (`no miréis`): the builder
  states a person for every tense of the second person plural now (Italian 9 798
  lines of `is the second person of` to 17 998, Spanish 14 775 to 27 435)
  except a form the language commands with (`cb_command_plural/3`), because
  stated a person too those five commands of the controls became `abrís`,
  `miráis` and `sois`, and the participle's feminine plural (`proibite`,
  `studiate`, `annegate`: the same spelling) made three headlines clauses --
  they are the statement only where the sentence says so: a plural `you` named
  at the head (`e voi rispondete col presidenzialismo`, whose group is the plural
  form's with the second person the pronoun gives it) or a form of `stare` with
  a gerund after it (`state proseguendo nel cosiddetto gioco del cerino`,
  `state attenti` stays the command), `tr_read_statement0/4`.
  It needed these WORDS in `extra/` (the dictionary's own word said again first
  where it must stay the one written: Italian `deputato` and `deputata` for the
  deputy `onorevole` is read as, `ipocrita` for the hypocrite `doppiogiochista`
  is read as, and the identity `"con il" is the contraction of "con il"` before
  `"col" is the contraction of "con il"`, so that `col` is read and the print
  writes `con il`): Italian `malafede`, `incidente di percorso`, `bacchetta`
  (rebukes), `aspetta al varco`, `dal momento che`, `perché mai`, `il giorno in
  cui`, `in che modo`, `se e in che modo`, `a tutela di`, `elezione` (an
  election first, the dictionary's choice second), `per l'ultima volta`, `voi`
  and `vi` (the plurals of `tu` and `ti`), and in eng-ita.dix `rig`, `intend`
  (read only), `trace`, `resign` (`dimettere`: the bilingual dictionary's
  `dimettire` is no word, and its thirty-six lines of forms are gone from the
  vocabulary), `bloc`, `hypocrite` and `deputy` (read only); Spanish `mala fe`,
  `vosotros` and `os`, `acecha` (lies in wait for, before threatens), `si y
  cómo`, `de forma realista`, `para la protección de`, `por última vez`, and in
  eng-spa.dix `rig` (`amañar`) and `hypocrite`. The first word moved in 2
  Italian meanings and 1 Spanish one (bloc is `schieramento` and no `bloc`,
  traces `traccia` and no `localizza`, rigs `amaña` and no `apareja`), the first
  meaning of 3 words moved (`elezione` is an election, `acecha` lies in wait,
  `amaña` rigs and no longer alters: that line is lost, as is Italian
  `localizza` = traces) and `hypocrite` moved too until `ipocrita` was said
  again: the read-only line for the word the text had was written first.
  The CONTROLS (cocolog 2.1.2, store KB126, 97 count files, 2 312 sentences:
  every earlier article, Tatoeba's 400 and the interview, both directions): the
  last version's translator against this one, on the one store, 31 sentences in
  5 files read differently -- 28 in the interview's two files, and 3 elsewhere
  (eco 16, `no creerte` is `no creeros`; fregene 30, `hablar con tú` is `con
  vosotros`; tat 346, refused before and `That Dios pays it to him` now), all
  better -- and the inferences fall 0.267 % (4 589 831 928 to 4 577 556 536),
  0.038 % more outside the interview (4 516 197 717 to 4 517 921 885, the Hotel
  Arts report in). The files rise 0.44 % at most (pacifist's, of 5 million; lotr's
  0.43 % of 71) and the one that falls most is eco's, -1.8 % (its twenty-third,
  5.3 million to 2.7: a question that was read as a command first). Cecchi 25,
  the one text the first cut changed (`what do they say`), reads as it did.
  Bytes and characters read every sentence alike (0 differ, the bytes 0.021 %
  more). The DATA COLUMN (the last version's translator on its own store, KB116,
  against this one on the new): 52 sentences in 8 files, 43 of them the
  interview's and 9 elsewhere -- `elezioni` are `elections` where the dictionary
  gave `choices` first (bovalino 12 and 14, tempi 38 and 40, wapo 3: English),
  the three of the code above, and tat 192 (`¿Por qué estáis enfadadas?`, `Why
  are you angered?`), which the store alone reads now: `estáis` is a person it
  states. The inferences fall 1.946 % (4 668 389 400 to 4 577 556 536), rise
  0.039 % outside the interview (4 516 160 393 to 4 517 921 885), and the
  interview's two files fall 61 % (76 million to 30 each) for the 40 sentences
  that refused after long searches. THE STORE ALONE COSTS NOTHING outside the
  interview (the last version's translator on the old store and on the new: 4 516
  160 393 to 4 516 197 717, +0.0008 %), though it states 8 200 lines of the
  second person plural more in Italian and 12 660 in Spanish, and that
  translator reads 25 and 25 of the interview's 36 on it. **A FIRST STORE WAS
  11.2 % DEARER FOR ONE LINE**: `The word "che" means "which".`, which first
  made `e che colpa abbiamo se ...` read, cost the last version's translator
  alone 4 978 433 218 inferences over the 95 files against 4 475 127 352, the
  six heaviest sentences 2.6 times (cecchi 8, with two `che`, 49.3 to 192.2
  million; cecchi 9, tempi 17, eco 8 and 22, letter 8 the others), found by
  teaching a store without each group of the new lines -- the second person
  lines, the phrases, the verbs and nouns, the plurals of `you`: nothing; this
  line: all of it -- and the line went out of the data and into the code
  (`tr_which_asks/2`, above). The binaries of 2.0.0 and 2.1.0 give the same
  counts to 48 inferences in 4.32 billion, and one text differs (fiat 6); those
  of 2.1.0 and 2.1.2 give the same counts and texts to the unit, on both
  translators and both stores (master moved to 2.1.2 while the controls ran, and
  they were taken again on it).
  THE STATED COSTS: `col` is read, and written `con il` (the writer takes the
  first contraction a lesson states, and the identity line first makes `col`
  read only; the seven sentences of the controls, Spanish into Italian, that
  came out `col` came back); a command stays a command -- `Siate`, `processate`, `guardate che ...`,
  `non pensate che ...`, `No miréis`, `State attenti`, which reads as the
  participle of `essere` as before -- and is a statement only after a plural
  `you` or as `stare` with a gerund; and the inferences, +0.038 % outside the
  interview. THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT (the sixteen
  heaviest sentences counted over a copy of the library per rule, on the new
  store): the first cut was +0.457 % of them over the last version's, and four
  rules were all of it -- the plural of `you` asked of every pronoun that is a
  subject (0.227 %), the two clauses of the command, each reading the piece's
  denial again (0.18 %), `that_open` (0.034 %, a lone `che` at the end of a piece
  read as other things first) and the possessive guard (0.009 %). The plural of
  `you` is asked of a pronoun that means `you` now (`E == you` before
  `tr_plural_you/1`), and the two commands are one clause with the form of the
  command asked first, before the pronoun's lexeme: +0.163 % of the sixteen, 0.096
  of it the clause's own reading of the denial (`tr_negation/4` walks the whole
  piece, in every clause of `tr_read_statement0/4`), and every text of the 2 312
  the same as the first cut's. Its cost outside the interview is a few
  sentences: e_eco 16 (+0.87 million of 6.5, a sentence English refuses, and the
  search that refuses is longer), lotr 11 (+0.25 of 31.7) and cecchi 8 (+0.18 of
  49.3), against eco 23's 2.65 million.
  The interview LEAVES, of the 36 into Spanish (English alike unless it says):
  `vi accusa di fare` is `os acusa hacer` and `accuses you to make` (7), and
  `nell'attesa di vedere` `en la espera ver` (11) -- after a pronoun or a phrase
  the infinitive loses its `di`, and nothing in a lesson says which verbs take
  one; `passa di mano` is `happens of hand` and `chi provoca` `al que provoca`
  (11); `ci siamo basati` is `nos hemos basado` (10), `ci siamo intesi` `nos
  hemos pretendido` and `il potere` `la fortaleza` (21, and `poteri forti` are
  `fortalezas fuertes`, 18), `il valore` is `la valentía` (24: `dandogli` is
  `dandole`, `pare proprio di no` `me parece justamente de no`), `registro` is
  `récord` and `buoni` `cupones` (13), `il confronto` `la comparación` (31),
  `fare i nomi` `hacer los nombres` (17); `Null'altro` is `Nada otros` and
  `nothing others` (25); `ci ha mai creduto` is `nos ha creído nunca` (27: the
  `ci` that stands for `in it`), and Spanish writes `sulle riforme` as `en las
  reformas` (English has `on`); `siamo disposti a` is `somos colocados a` (28), `crediamo al`
  `creemos al` (no `en el`) and `mettiamola` `Pongamosla` (no accent); `non hanno
  capito ancora cosa` keeps `cosa` as a noun at the end of its clause
  (`han entendido todavía cosa`, 29: the question word of an indirect question
  with nothing after it, unread) and `vogliono altro` is `quieren otros`;
  `se fossi in malafede` is `si estaba en mala fe` and `If I was` (12: the
  imperfect subjunctive is written as an indicative, as in the PSOE report),
  `Il giorno in cui Dini si dimetterà` `Cuando Dini se dimitirá` and `When Dini
  will resign` (33: Spanish wants the subjunctive after `cuando`, English the
  present); a passive `si` before the verb is lost in English (`il voto non si
  decide` is `the vote does not decide`, 32; `Le mele si mangiano` `The apples
  eat`; `Si possono fare le cose` `The things are caned make`; `che
  realisticamente si possono fare` `that realistically can make`, 15); English
  writes the clitic of a question as a thing (`what can I say her`, `who says
  him`, 3 and 6); Italian `te` is no word of the lesson (`Parlo di te` is refused,
  `Te lo dico io` is `I say it to You I`: the dictionary gives `ti` only);
  `state attenti` and `state grandi` read as the participle of `essere`, as
  before (`Cuidadosos han sido sido`); `acecharemos el Pds` has no `al`.
  The basketball report (AnCora CESS-CAST-P-20001201-176, 17 sentences, Spanish
  into Italian and English: 17 of 17 and 17 of 17 on a fresh store, 14 and 15
  with the new store alone, 10 and 7 with the new code on the old store, 9 and 6
  before; reasoning 1.0.6). It needed these SHAPES, each with its arm red
  (test/translate.pl's `newspaper_basket`: 34 checks, 21 arms and 7 guards, each
  guard red when its rule is made too wide; an arm is a library directory of
  symlinks whose reasoning/translate.pl is the edited copy, `COCOLOG_LIBRARY=ARM
  cocolog query "use_module('test/translate.pl'), newspaper_basket,
  checks_done"`, about a second a run): an adverb and a participle after a name
  are the clause's own (`Con Rimac excesivamente apagado en tareas ofensivas,
  fueron César Sanmartín y Jofresa los jugadores ...`:
  `tr_adverb_before_participle/3` asked for a noun at the end of the front, and
  the plural clause after it had no reading); an adjective straight after a name
  that `con` governs is an absolute phrase, at the head (`Con Rimac apagado,
  ...`, `tr_adjuncts_after/2`) and between commas (`los azulgranas, con Rentzias
  convaleciente, se vieron ...`, `tr_insertion_comps/1`, with `tr_means_with/1`)
  -- two arms; a modal and an infinitive with the reflexive joined, nobody
  named, is the impersonal `se` (`como podía esperarse de los dos equipos`,
  `tr_modal_se_fix/3`: English refused it and Italian wrote a second person,
  `come poteva aspettarsi`; the guard is a named subject, `Pedro puede
  esperarse`); a phrase a comma parts from the clause after it (`Un bloque de
  una tremenda consistencia, y los azulgranas ... se vieron obligados a un
  tremendo derroche`: the commas were taken out in two places and block and
  players were one plural subject -- `tr_comma_and_parted/2` stops both, and
  `tr_join_left/5` reads the phrase as a heading before `, y`; THREE arms, none
  green with another out, and two guards: a comma after the pair is an aside's,
  `El presidente, y los ministros, firmaron`, and the right side of a
  coordination after a statement is no fragment); the dative pronoun the phrase
  of `a` says again (`Pedro le dio un libro a María` gave María a book, `estuvo
  a punto de complicarle la vida al Joventut`: `tr_dative_double_fix/3`, three
  arms -- the pronoun before the verb, joined to an infinitive and after a
  preposition, `sin darle un libro al gato` -- and a guard, the phrase of `a`
  before any infinitive: `le permitiría dedicarse de lleno a Ona Catalana`
  allows HIM); what something costs somebody is the person and the price with no
  `to` (`le ha costado al club 75 millones`, a clause of `tr_comps_out/7` that
  asks for the price after the person; guards: the price before it, and no price
  at all, `Al Sud le università costano meno che al Nord`); an ordinal before a
  noun that is a noun too is its adjective (`el segundo cuarto`, `tr_noun/5`);
  the English plural of a demonym in `-ño` is `-ños` (`en_irregular_plural/2`);
  `prevails over` and `ousts from` (`en_governs/2`); two phrases after a copula
  with nobody named are what is and what it is (`Fueron César Sanmartín y
  Jofresa los jugadores que ...`, `tr_ident_fix/3`, a pair of names or a phrase
  with its article -- two arms -- and an indefinite phrase first keeps the old
  reading, a guard); an English verb of several words that ends in a preposition
  takes the gerund (`took charge OF CARRYING`, `tr_verb_ends_in_preposition/0`);
  a purpose governs the phrase after it (`para descabalgar a los malagueños del
  liderato`, `tr_governing_verb/3` looks at `purpose(IL)` too -- which also made
  Tatoeba's `per partecipare ... alle nozze` `to participate in the wedding`); a
  word the lesson says is NOT feminine beside a feminine one clashes in the
  person rule of `tr_noun/5` (`la directiva azulgrana` was `the managerial Barça
  player`: `azulgrana`, a Barça player, masculine though it ends in `a`, is
  stated "not feminine" and so has no gender of its own for
  `tr_genders_differ/2` to set against the feminine `directiva` --
  `tr_genders_clash/2` asks for the statement too); and the verb of knowing
  takes `how to` before the infinitive that stands first among its complements
  (`el Unicaja supo contrarrestar la apuesta` knew HOW TO, `tr_write/4` and
  `hinf/1`; `non so cosa fare` has the question word first and keeps its `to`, a
  guard).
  It needed these WORDS in `extra/` (the two readers: a line moves the reader of
  one language and the writer of the other; the dictionary's own word is said
  again first where it must stay the one written): Italian `tripla` (a
  three-pointer), `mordente` (hitting power), `blaugrana` (the players, and the
  adjective), `in procinto di`, `contrariamente a`, `spegne` (switches off), `si
  occupa` (takes charge of, with `di` before the infinitive and the phrase),
  `direttivo` (the board), `lascia partire` (releases), `si impone` (prevails,
  `a`), `overtime`, `tarda a` (takes long), `si riorganizza` (regroups),
  `protagonismo` (prominence), `compito` (a task), `leadership`, and `spodesta`
  taking `da`; Spanish `cuarto` (a quarter), `triple` (a three-pointer),
  `pegada`, `malagueño` (a person), `azulgrana` (a Barça player, not feminine, a
  person, and the adjective), `con mayúsculas` (magnificent), `a punto de` and
  `en contra de`, `pulso` (a duel, the pulse second), `apaga` (switches off),
  `se encarga` (takes charge of, `de`), `directiva` (the board), `deja marchar`,
  `se impone`, `equilibrio` (equilibrium), `tarda en`, `se rehace` (regroups --
  `recovers` is the other verb's, `recupera`, and a shared pivot made
  `recuperaron` unwritable in Italian), `protagonismo`, `descabalga` taking `de`
  and the name `Caja San Fernando`; and in the dictionaries' extras
  `tremendous`, `oust` (`spodestare`; `descabalgar` read only), `antagonistic`,
  `tie`, `pivot`, `quarter`/`quarto`, `victorious`, `rebound`, `tactical`,
  `alleged` (`presunto`, and `supuesto` too in Spanish), `expenditure`
  (`dispendio`, `derroche`), `dignify` (`engrandecer`, read only), `consecutive`
  (`seguido`, read only), `tone`, `overtime` (`prórroga`) and `contract`. The
  first word moved in 15 Spanish meanings and 4 Italian ones (`azulgrana`,
  `presunta`, `presunto`, `supuesta`, `supuesto`, `contrato`, `cuarto`,
  `derroche`, `directiva`, `equilibrio`, `protagonismo`, `prórroga`, `pulso`,
  `tono`, `apaga`; `presunta`, `presunto`, `tripla`, `spegne`), and none was
  lost.
  THE CONTROLS ARE A RECONSTRUCTION. The box was reset before this sample and
  the scratchpad with the 97 count files of the Tatarella round went with it:
  these are the 22 AnCora documents (CESS-CAST-P-19981202-34, 19990202-16,
  19990601-13 and 23, 19990701-130 and 83, 19990802-48, 19990901-75,
  19991001-61, 20000102-120, 20000701-80, 20000802-31, 20000903-30, 20010102-25,
  20010103-120 and 139, 20010202-169, 20011202-66, 20020102-112, 20020301-125,
  20020601-51 and 20020801-17, all in the dev file of UD's es_ancora), the 21
  VIT ranges of UD's it_vit test file (9270..9295, 9381..9414, 9450..9464,
  9465..9470, 9472..9484, 9540..9566, 9637..9672, 9673..9712, 9714..9749,
  9750..9762, 9763..9774, 9775..9780, 9781..9791, 9792..9799, 9800..9814,
  9816..9850, 9851..9925, 9926..9946, 9947..9966, 9967..9998, 10059..10095) and
  a Tatoeba-style 400 (Spanish sentences of 3 to 8 words of manythings' spa.txt,
  every (length/400)th): 1 264 lines, 88 count files (the Spanish ones into
  Italian and English, the Italian ones into Spanish and English), 2 528
  sentences, so no figure below compares with an earlier sample's, and the
  baseline is the committed library (reasoning 1.0.5) on a store taught from the
  committed vocabulary (it reads the Tatarella interview 36 of 36 into both, as
  sample 41 said). The next sample's controls take this report in. The CONTROLS
  (cocolog 2.2.5, store KB150): the last version's translator against this one,
  on the one store, 5 sentences in 3 files read differently (it_9637_9672 13,
  `The most numerous families are the struckest`; it_9800_9814 4, `to
  participate in the wedding` and `en la boda`; tat 291, `Algo le ha pasado a mi
  coche` is `Something has happened to my car` where the clitic had made the
  verb `spend`), all better -- and the inferences fall 0.063 % (4 689 505 132 to
  4 686 547 092). The file that rises most is es_20010103-120's, +0.1 % of 23.6
  million, and the ones that fall most es_19981202-34's, -8.7 % (its eighth, 3.5
  to 2.3 million), and es_19990601-13's, -3.6 %. Bytes and characters read every
  sentence alike (0 differ, the bytes 0.018 % more). The DATA COLUMN (the last
  version's translator on its own store, KB142, against this one on the new): 7
  sentences, the 5 above and 2 of the words, `liderazgo` as `la leadership`
  (es_20010102-25, Italian) and `se encargó de demostrarle` as `si occupò`
  (es_20020601-51, Italian); THE STORE ALONE costs +0.198 % of the inferences (4
  680 224 596 to 4 689 505 132), all of it the Tempi report's sentence 20, which
  runs to the inference limit in both stores (468.6 to 472.7 million), and the
  new code on the old store -0.063 %. THE FIRST CUT'S REGRESSIONS, found by the
  controls and read from the IR, not bisected (the guess,
  `tr_comma_and_parted/2`, never fires in them -- a probe on the sentence
  answered `no`): `... no es un punto de llegada, sino el inicio de una nueva
  etapa, y concluyó` and `acusó a Aznar de lanzar un "mensaje basado en la
  confrontación y la ausencia de diálogo", pero aseguró ...` (es_19990701-83 9,
  es_20000903-30 21) gained a `they`, because the fragment clause of
  `tr_join_left/5` took the right side of a `sino` or `y` division for a
  fragment and a clause and the last verb had nobody before it -- the right side
  of a coordination after a statement is read with `$tr_no_command` set, and the
  clause now stands down there; `le permitiría dedicarse de lleno a Ona
  Catalana` (es_19990701-130 6) lost its `le`, the infinitive's `a` taken for
  the pronoun's phrase; and the bare dative of `costs` turned `all'anno` (11),
  `al Nord` (27), `a Catania` and `al politecnico` (28) bare (it_9816_9850),
  which was the writer's clause for any phrase of `to` after the verb and is now
  the one with the price after it. THE STATED COSTS: a first meaning that serves
  the news and not every text -- `pulso` is a duel (the pulse is the second),
  `cuarto` a quarter (a room second), `contrato` a contract (an agreement
  second), `prórroga` overtime (an extension second), `apaga` and `spegne`
  switch off (extinguish second), `presunto` and `supuesto` alleged, `tono` a
  tone (a key second), `directiva` the board (a directive second),
  `protagonismo` prominence, `derroche` expenditure -- and the controls'
  sentences with them are the two of the data column above; and `non so cosa
  fare` is still `I do not know thing to make`. The report LEAVES, of the 17
  into English: `una sola concesión` is `an alone concession`, `ayer` stands
  last (1, 14), `todavía` after the names (4), `se vieron obligados` after a
  long insertion is `they saw obliged` with the subject written twice (4: the
  subject and an insertion of two phrases, pre-existing), `últimamente` stands
  last in its clause (5, `two antagonistic characters lately`), `entre` is
  `among` and `se emplearon` `employed` (5), `apuesta por la velocidad` is `bet
  for the speed` (6), `alzarse con la victoria` is `heave with the victory`
  (10), `complicarle la vida al Joventut` is `complicating the life to the
  Joventut` (11: the pronoun went, the phrase of `a` stayed), `acabara empatado
  a 72` is `tied to 72`, `llegó a un acuerdo` `arrived to an agreement` and
  `cantidad cercana a` `a near quantity to` (14), `expedientes` are `files`
  (16); Italian: `se emplearon` is `si impiegarono`, `efectivos` `effettive`,
  `esperarse de` `attendere delle` (`da`), `in quelli istanti` (`quegli`),
  `finiva pareggiata` (the subjunctive written as an indicative), `in Badalona`
  (`a`), `In altra partita` (`In un'altra`), `Quell'era` (`Quella era`), `fu il
  primo che` (`la prima`: the Spanish `equipo` is masculine and the Italian
  `squadra` is not) and `archivi` for `expedientes`; sentence 8 has no `con` in
  the source (`rehacerse, protagonismo de Digbeu y la eficacia de
  Jasikevicius`), and it is written as it stands.
  The Rosi report (VIT-9567..9604, 38 sentences, Italian into Spanish and
  English: 37 of 38 and 34 of 38 on a fresh store, 28 and 23 with the new store
  alone, 10 and 9 before; reasoning 1.0.7).
  It needed these SHAPES, each with its arm red (test/translate.pl's
  `newspaper_rosi`: 82 checks, 69 arms, 4 of them guards that go red when their
  rule is made too wide; an arm is a library directory of symlinks whose
  reasoning/translate.pl is the edited copy, `COCOLOG_LIBRARY=ARM cocolog query
  "use_module('test/translate.pl'), newspaper_rosi, checks_done"`, about a
  second a run, and every arm of this sample is run in a minute, four at a
  time): a piece in quotation marks from its first word to its last is a title
  the paper quotes (`"verdetto casareccio".`: a bare noun and its adjective
  begin no sentence, `tr_quoted_whole/1`, `tr_as_title/1`, tried after every
  other reading found nothing and for a piece of eight words at most, which is
  the cost: a refused sentence quoted whole was read twice, 473 and 18 million
  inferences more); a phrase of `to` before a city the lesson names, after a
  verb that does not go, is a phrase of `in` (`al termine del match ... a
  Perugia`, `tr_city_in/3`; a verb of going or bringing keeps its `to`,
  `tr_motion_verb/1`, a guard) and a name's particle is none before a city
  (`Ruggisce Rosi da Perugia` is Rosi roaring from Perugia,
  `tr_particle_names/4`); `roars` is a verb of saying to English
  (`en_saying/1`); a reporting clause between two dashes with a clause on each
  side (`sono l'unico ad aver consigliato l'Egibren - conferma Casotto - Rosi
  sapeva del farmaco`: a clause of `tr_read0/4`; the other readings find the
  same text 14 million inferences later, so no arm goes red and the clause
  stays for its cost, with its guard, that the right side opens on no
  preposition), a name between commas and the noun that says what he is, to the
  end of the piece with no verb (`Alessandro Casotto, medico di Rosi fino al
  match con Phillips`, a clause of `tr_list_commas/5`), and a name, a bare noun
  and what is added with no comma (`Rosi vittima quindi`, `tr_verbless0/3`); a
  word that begins the cause before a perfect infinitive says why (`Innocente,
  per aver assunto la sostanza` is innocent FOR HAVING taken it,
  `tr_complements0/4` and `tr_cause_word/1`; the group travels whole as
  `pinf(Word, perf(Lexeme, Pronouns))`, crossed by `tr_cross_comp/2` and
  written by two clauses of `tr_comp_out/7`, English `for having eaten`, the
  lesson's language its cause word, `por`, where the purpose word `para` was
  written -- five arms), an adjective and the `of` it takes before a perfect
  infinitive (`Colpevole di esser risultato positivo al controllo antidoping`
  is guilty OF HAVING TESTED positive, a clause of `tr_complements0/4` and the
  line of `tr_verbless0/3` for a heading, two arms) and a date after the
  adjective is when, never what it is said of (`il 17 maggio`, `oc/2` asks
  `tr_date_phrase/1`); a second participle joined to the first with its own
  agent (`il farmaco prescritto da Casotto e assunto da Rosi`:
  `tr_reduced_agent/3` reads `cpart/3`, `tr_cross_comp/2` crosses it,
  `tr_comp_out/7` writes it agreeing with the noun, and
  `tr_conjunction_split/5` no longer divides at the coordinator that a
  participle with an agent follows -- four arms); an insertion of the word for
  `if` and a participle (`una teoria che, se accettata, potrebbe modificare`:
  `tr_insertion_off/4` and the relative clause with commas,
  `tr_participle_gap/2`, two arms); the word for `thus` and a clause with its
  verb first between commas (`L'utilità dell'Egibren, così si chiama il farmaco
  ..., è stata una delle colonne`: `tr_insertion_off/4` reads it with its
  subject after the verb, the clause travels as `mid(sub(so(Word), S))` and
  `tr_cross_connector/3` and `tr_connector_out/3` carry the adverb -- three
  arms -- and English writes the reflexive of `calls` as the passive it is,
  `en_group/9`); a phrase with a series of relative clauses, a comma between
  them (`la gente che mi stringe la mano ogni giorno, che mi fa coraggio, che
  mi dimostra il suo affetto`: `tr_np/3` hangs each later clause on the phrase
  before it, as `nrc/3`, and `tr_verbless0/3` reads the whole heading of
  three); the comment of `come` whose actor stands after its verb (`(e non dopo
  le controanalisi, come prescrive il regolamento)`: `tr_relative_wh_after/3`
  after a phrase of a preposition and after the comma that parts it in a
  bracket, and `tr_rel_subject_fix/2`, which gives a clause with nobody named
  and a phrase for its first object that phrase for its subject, kept in its
  place with `subj_here` -- the same fix is what a relative clause after a
  preposition needed, `la casa in cui dorme Pedro`); the actor after the verb
  of an indirect question is its subject (`sa cosa mangia il gatto`,
  `tr_wh_subjects/3`) and a place's clause stands in front as an adjunct (`alla
  riunione romana dove ha combattuto Parisi`, `tr_adjunct(rwh(where, _))`); a
  demonstrative after the word for `like` is the pronoun (`verdetti alla
  casereccia come questo`, `tr_like_word/1` in `tr_subject_shape/4`); a series
  of predicates after a plain comma (`Rosi ora è furioso, promette vendetta,
  vuole riprendersi il titolo`: the reader no longer takes the second for a
  command, `tr_read_joined/5`, and the English writer elides the subject of the
  second and the third clause, never of the second of two: a comma splice keeps
  its pronoun, `The dogs sleep, they are tired`, `tr_write/4`); the word for
  `to` before an infinitive stops the phrase before it, though it is a noun too
  (`sono l'unico ad aver consigliato l'Egibren`, `tr_phrase_words0/4`); a modal
  and the copula, a phrase and the infinitive that says what it does (`Dovrebbe
  essere la gente a giudicarmi` is it should be the people to judge me,
  `en_null_it/2` for the modal and for the copula, `en_cleft_infinitive/1`, and
  the noun's preposition is written `to` after a modal, `tr_comp_out/7` --
  three arms); a relative clause with two verbs (`un processo che avrebbe
  accolto in pieno la linea difensiva e nonostante ciò avrebbe condannato
  l'imputato`: `tr_relative_clause/4` joins the halves, `tr_front_verb/1` lets
  the second open on adjuncts, and `tr_dangling_coordinator/2` stops
  `tr_read_generic/4` from taking the second verb for the sentence's -- guarded
  by a relative word before the coordinator and by a first word of the front
  that the clause has not met, two guards: `L'azione combinata del sole e di
  una bibita ghiacciata causa il blocco del cuore` and `contro le armi e contro
  il nucleare ha osato` lost their verbs to the first cut); an existential
  clause of `that` after a noun has no subject before its verb (`la conclusione
  che non ci fu dolo`, `tr_np/3`); the phrase after the word for `what` is an
  object, and what follows it is read as after one (`che strano modo di
  salutare`, `tr_complements0/4`); a count of time and what it is for, before
  the comma and the coordinator (`Due anni al pugile positivo per amfetamine,
  ma il giudice ammette`, a clause of `tr_join_left/5` and
  `tr_comma_and_parted/2` in `tr_read0/4`); an exclamation with a comma is read
  when the clause of `that` before it has failed (the cut moved after
  `tr_that_clause/3`, `Che ambiguità, una squalifica di due anni ...!`); a
  quotation that opens on the verb and closes in the subject (`"è sufficiente
  la mera assunzione" della sostanza proibita`: the copula's subject with its
  own `of` phrases, `with/2`, English opens the mark on the subject and the
  lesson's language puts the marks of the clause where they stood,
  `tr_open_first/2` -- three arms); a word that begins the relative is a
  subject with its clause (`chi ruba miliardi`, `tr_subject/6`); an adverb that
  is nothing else ends a phrase unless it grades the adjective after it (`Come
  nasce una sentenza così?`, `fo_adverb_ends/2`, a guard: `la stampa piuttosto
  tiepida`); and the English the sentences needed: `why` takes the bare
  infinitive (`en_assemble/9`), `does nothing but` a bare infinitive
  (`tr_modal_verb/0`), the collective plurals take the plural verb (`the people
  sleep`, `the people that sleep`, `en_collective_plural/1`, two arms), `uno`
  alone is `one` (two arms), `never` and the positive pronoun after it (`non ho
  mai scritto niente` is I have never written anything, three arms), the
  pronoun of the verb's own person after it is the subject said again (`sono
  arrivato io alla conclusione`, `tr_dislocation_fix/3`), `instead of` and
  `not` before the phrase of a preposition they are said of (`tr_comps_out/7`),
  the capital an adverb had at the head of the sentence goes with it (`Anche
  Rosi cade` is `Rosi also falls`, not `Rosi Also`: `anche` is the plural of
  `anca` in the store too, and a noun before a name keeps its capital as the
  first word of a name, `tr_write/4`), `or else` stays in front as `otherwise`
  does (`Altrimenti mi dedicherò al mondiale Wba` is `Or else I will dedicate`,
  the lesson's word for `altrimenti` where the dictionary's is `differently`:
  `en_conjunctive/1`) and `is about` takes `to`
  (`tr_verb_ends_in_preposition/0`). Four rules have no arm that goes red and
  stay for what the controls showed: the clause of the dashes, its guard
  against a preposition, the title's limit of eight words and the grading guard
  of `fo_adverb_ends/2` (without it `la stampa piuttosto tiepida` loses the
  adverb of its adjective, it_9781_9791 9 into English: `The press testifies to
  it enough lukewarm`).
  It needed these WORDS in `extra/` (the two readers: a line moves the reader
  of one language and the writer of the other; the dictionary's own word is
  said again first where it must stay the one written): Italian `The word "per"
  begins the cause.` and twenty cities for the city rule (`Perugia`, `Bari`,
  `Cagliari`, `Catania`, `Verona`, `Padova`, `Trieste`, `Brescia`, `Parma`,
  `Modena`, `Pisa`, `Ancona`, `Pescara`, `Trento`, `Bolzano`, `Livorno`,
  `Taranto`, `Messina`, `Lecce`, `Salerno`; Spanish `por` for the cause and `de
  lo contrario`), `amfetamina`, `metilamfetamina`, `neurotraumatologia`,
  `microtrauma`, `dopa` (dopes), `funesta` (afflicts), `fan` (an apocope of
  `fanno`), `ko`, `ring`, `casareccio` and `casareccia` (homespun; `alla
  casereccia` too), `dà fastidio` (bothers, which the Spanish `molesta` is
  written as now), `beffa` (a mockery, where the dictionary's first noun is a
  fool), `furioso`, `legale` (a lawyer, a person), `modo` (a manner, not a
  mode), `volontà` (a will), `compie` (commits), `altrimenti` (or else, a gloss
  of its own, and Spanish `de lo contrario`: `otherwise` stays `per il resto`'s
  and `por lo demás`'s, one writer word each), `invece che` (an adverb, so that
  the phrase after it keeps its own `alla`), `assume` (takes), the name
  `Parisi`, `ci fu`/`c'è stato`/`ci furono` (there was), `dolo` (criminal
  intent), `illecito`, `forzatura` (abuse), `a livello federale`, `per ora`,
  `si riprende` (regains), `trentottenne`, `sa di` and `sa tanto di` (smacks
  of), `benservito` (dismissal), `processo` (a trial, not a process), `non fa
  che` (does nothing but), `uso`, `al termine di`, `ci vuole` (is needed) and
  `ben altro`, `conclusione` (takes its clause), the name `Casotto`, `sostiene`
  (maintains), `accoglie` (accepts), `antidoping` (a noun), `primario` (head
  physician, a person), `sta per` (is about) with its forms, `ricorre`
  (appeals), `fa venire voglia` (inspires), `responsabile`, `al corrente`,
  `prodotto di scarto`, `libera` (releases), `quindi` (therefore, where the
  dictionary's first is `then`), `assunzione` (intake, not acceptance),
  `utilità`, `impianto difensivo`, `gente` (a person), `stringe la mano`, `fa
  coraggio`, `voglia`, `fa progetti`, `va in galera`, `si vede concedere` (is
  granted), `libertà provvisoria`, and `combatte` (fights); Spanish
  `metilanfetamina`, `neurotraumatología`, `contraanálisis`, `ko`, `ring`,
  `dolo`, `ilícito`, `a nivel federal`, `por ahora`, `hombre de 38 años`,
  `huele a` and `despido`, `no hace más que`, `antidopaje`, `médico jefe` (a
  person), `está a punto de` and its forms, `responsable`, `al corriente`,
  `producto de desecho`, `prohibido`, `ingesta` (intake), `gente` (a person),
  `estrecha la mano`, `estrategia de defensa`, `hace planes`, `va a la cárcel`,
  `recibe` (said again first, so that it stays `receives`, and `is granted`),
  `libertad provisional`, `falta` (lacks) and `sostiene` (maintains: the
  Italian `sostiene` says it first now, and the Spanish word written for it
  stays its own, not the dictionary's `mantiene`); and in the dictionaries'
  extras `suspension` (`squalifica` first, `sospensione` stays the one
  written), `suspend`, `antidoping`, `doping`, `match`, `testimony`, `boxing`,
  `positivity`, `encephalic`, `performance`, `administer`, `counteranalysis`,
  `revenge`, `regain`, `jail`, `affair` and `homespun`, and for Spanish
  `antidoping` (`antidopaje`), `positivity`, `microtrauma`, `encephalic`,
  `homespun` and `safeguard`. Said again first, so that they stay the words
  written: Italian `fanno`, `avvocato`, `commette`, `licenziamento` (the
  Spanish `destitución` and `despido` stay `licenziamento`), `accetta`,
  `consapevole` and `incoraggia`. The first word moved in 19 Italian meanings
  and 2 Spanish ones (`consapevole` aware; `furioso`, `furiosa` furious;
  `altrimenti` or else; `quindi` therefore; `assunzione` intake; `beffa`
  mockery; `benservito` dismissal; `forzatura` abuse; `modo` manner; `processo`
  trial; `utilità` usefulness; `accoglie` accepts; `assume` takes; `combatte`
  fights; `compie` commits; `libera` releases; `ricorre` appeals; `sostiene`
  maintains; Spanish `ingesta` intake and `sostiene` maintains), and none was
  lost.
  The CONTROLS (cocolog 2.2.5, store KB170, 92 count files, 2 638 sentences:
  the earlier set with the basketball report (es_20001201-176) and this one in,
  both directions): the last version's translator against this one, on the one
  store, 73 sentences in 22 files read differently -- 42 in the report's two
  files and 31 in 20 files elsewhere, all better but two (below) -- `never`
  (it_10059_10095 4 and 6, it_9270_9295 14: `I have never written anything on
  Montanelli`), the collective plurals (es_20010102-25 3, `The police suspect`;
  it_9967_9998 5 and 22), `are called` (it_9472_9484 9, it_9637_9672 25), `in`
  before a city (it_9270_9295 6, and it_9540_9566 11 and 25 in both languages:
  `come si dice a Napoli` is `in Napoli`), the `it` of a modal and the copula
  (it_9381_9414 10 and 12, it_9816_9850 24, it_9851_9925 56 and tat 303:
  English refused four of them and wrote the fifth with nobody to be it), `why
  return` (it_9673_9712 34), `is about to drown` (it_9381_9414 14), the marks
  of `se "digan las cosas claras"` (es_20000903-30 8, both languages), `and are
  not` (es_20020102-112 11), `I have won!` (tat 1), `that our atlases make
  today` (it_9967_9998 25), and three sentences English reads for the first
  time (es_20020601-51 20, it_9926_9946 7, it_9967_9998 15) -- and the
  inferences fall 1.216 % (4 964 274 025 to 4 903 910 067) and rise 0.111 %
  outside the report (4 776 346 010 to 4 781 654 737). The file that rises most
  is it_9465_9470's, +2.9 % of 2.4 million, then es_19981202-34's, +2.0 % of
  12.5, and the ones that fall most are es_20020102-112's, -5.1 % of 71.6 (its
  eleventh, 32.0 to 28.3 million), it_9540_9566's, -3.6 %, and it_9926_9946's,
  -3.4 %; Tempi's twentieth, the sentence that runs to the limit in both
  languages, rises 0.7 % (473.0 to 476.5 million). Bytes and characters read
  every sentence alike (0 differ, the bytes 0.018 % more), and the new code on
  the old store (KB150) differs from the last version's in 38 sentences, 8 in
  the report's files and 30 elsewhere, +0.111 % outside the report, the same
  cost as on the new.
  The DATA COLUMN (the last version's translator on its own store, KB150,
  against this one on the new): 151 sentences, 62 in the report's two files and
  89 in 39 files outside them, the store's 60 and the code's 31 (two are both),
  and the inferences fall 6.564 % (5 248 400 886 to 4 903 910 067) and rise
  0.136 % outside the report (4 775 147 082 to 4 781 654 737). THE STORE ALONE
  (the last version's translator on the old store and on the new) differs in 60
  sentences in 30 files outside the report, +0.025 % of the inferences (4 775
  147 082 to 4 776 346 010), each a word of the report's lines: `quindi` is
  `therefore` and `por lo tanto` where the dictionary's first is `then` and
  `entonces` (23 texts in 12 files: it_10059_10095 26 and 31, it_9270_9295 21,
  it_9637_9672 30 and 33, it_9673_9712 19, it_9714_9749 30, it_9792_9799 3,
  it_9800_9814 1, it_9851_9925 15, it_9967_9998 20 and 28), `processo` a trial
  (8 texts: it_9926_9946 8, 9, 10 and 21, it_9851_9925 61), `forzatura` an
  abuse (6: it_9673_9712 14, 15 and 16), `modo` a manner (4: it_10059_10095 9,
  it_9673_9712 27), `combatte` fights (4: it_9763_9774 5 and 6), `sostiene`
  maintains (5, English: es_19981202-34 3 and 10, it_9637_9672 26, it_9967_9998
  5 and 28; Spanish keeps its `sostener`), `sta per` is about (it_9381_9414
  14), `uso` for `utilizzo` (es_19990802-48 6, es_20000701-80 25), `dà
  fastidio` for `molesta` (es_20020801-17 22), `estrecha la mano` for `aprieta`
  (it_9851_9925 20), `gente` a person (`descubría a gente`, it_10059_10095 28),
  `assunto` as `taken` for `assumed` (it_9714_9749 28, a participle where the
  sentence has the noun, as it did), and tat 157, `Huele a mil rayos aquí`,
  which was `Puzza a migliaio raggi qui` in Italian and is `Sa di migliaio
  raggi qui` now, and which English refuses (the verb of two words with nobody
  named). THE LINES' OWN REGRESSIONS, found in the data column of the first
  stores and mended: a line that gives a word its meaning comes first for the
  writer of the other language, so the dictionary's own word is said again
  first for Italian `fanno`, `avvocato`, `commette`, `licenziamento` (the
  Spanish `destitución` was written `benservito`), `accetta`, `consapevole` and
  `incoraggia`; the seven lines of the tenses and plurals of `ci vuole` refused
  the sentences with `ci vogliono dire` and are out; `dimostra` and `mostra`
  are the dictionary's again (below); `sostiene` has its Spanish line; and
  `altrimenti`, which first took the gloss `otherwise` of `per il resto` and
  `por lo demás`, wrote `per il resto` as `de lo contrario` (it_9967_9998 31)
  until `or else` became its own, with the fact of `en_conjunctive/1` that
  keeps it in front.
  THE FIRST CUT of the code cost 21.4 % outside the report (4 786 328 606 to 5
  811 772 493 on KB166) and was nearly all five sentences, found by counting
  the heaviest of a pass over a copy of the library per rule: Tempi's
  twentieth, 473.0 to 962.1 million inferences in each language, es_20020801-17
  22, 18.3 to 36.7 (the two relative-clause rules, the join of a relative
  clause with two verbs and the series of relative clauses, whose questions
  were asked at every relative word and every comma of a long sentence),
  it_9775_9780 3, 0.8 to 15.1 (`Quest'Uomo che una volta, a fianco di Marco
  Pannella, si batteva contro tutte le guerre, contro le armi e contro il
  nucleare ha osato`: the second verb taken for the sentence's, the two guards
  of `tr_dangling_coordinator/2`), it_9926_9946 16, 1.7 to 5.3 (the clause of
  the dashes, whose guard against a preposition was a variable the clause had
  already bound), and es_20000903-30 18, +2.1. What paid was the question asked
  ONCE a sentence and not at every word (`$tr_front_coord` and `$tr_comma_rel`,
  set in `tr_into_ir/4` and made when the library loads, or a sentence read
  before the first `tr_into_ir/4` found no flag and was refused:
  es_20000102-120 1); a pre-filter for the join of a relative clause that asked
  `tr_gap_verb_next/2` first cost 1 000 inferences a call and was taken out.
  The five stand at 476.5, 18.33, 0.80, 1.67 and 79.15 million. The English
  writer's first cut elided the subject of every clause after a plain comma and
  wrote `The violins cannot be copied, are only`: it elides in a series of
  three and keeps the pronoun of a comma splice (D13 of the section), and a
  failed write left the elision set for the next sentence (`$tr_elide`,
  `$tr_chain`) until it was put back.
  THE STATED COSTS: Tempi's twentieth rises 0.7 %; `Se Montanelli sapesse che
  gli ho dato del sentimentale, si arrabbierebbe` (it_10059_10095 25) read `one
  would anger` in English, the reflexive as the impersonal, and is refused now
  (`Montanelli si arrabbierebbe` and `Si arrabbierebbe` read as before: a
  conditional and a reflexive verb with nobody named); `adesso` of a clause
  with two verbs is written after both of them in Spanish (it_9851_9925 44:
  `que no hay más y no siente nada ahora`); es_20020601-51 20 reads in English
  where it was refused, `It had to be, in Seúl, the city curiously where this
  country attained in 1988, ...`; the first meaning that serves the news and
  not every text -- `forzatura` is an abuse (Tempi's three sentences are a
  forcing), `sostiene` maintains (`to maintain the destitute citizens` for
  `sostenere i cittadini indigenti`), `assunto` is taken, `quindi` is
  therefore; and `dimostra`, whose line (`shows`) cost four sentences their
  `demostrar` (it_9781_9791 4 and 7, it_9967_9998 12, it_10059_10095 18) and is
  the dictionary's again: `che mi dimostra il suo affetto` is `who demonstrate
  me his affection` in English, as the writer puts a clitic dative before the
  object for every verb (`Mi spiega il problema` is `They explain me the
  problem`).
  The report LEAVES, of the 38 into Spanish: `es furioso ahora` (`está`), `ha
  per ora smentito la voce di una sua denuncia` is `ha negado por ahora la voz
  de su queja` (10: a rumour, a complaint), `fa venire voglia di continuare` is
  `me inspiran continuar` (14), `non si occuperà mai più` is `no se encargará
  nunca más` and `se accettata` `si aceptada` (20), `l'unico responsabile` is
  `el único director` (25: the noun is read before the adjective), the
  subjunctive written as an indicative in 25, 26 and 30 (`dejó marchar`, `es
  divulgado`, `yo disputo`), `condannato l'imputato` has no `a` (28), `seré
  listo a recuperar` (`estaré listo para`, 30), `miliardi` are `millardos`
  (35), and 38, the lead line, is refused in both languages -- the source lost
  the colon after the sport (`Pugilato - la vicenda del pugile squalificato per
  due anni per doping il medico che gli prescrisse il farmaco prende le sue
  difese`); of the 34 into English: `removed him` for `gli ha tolto` (8),
  `resulted positive` for `risultato positivo` (12), `has not ended up` for
  `non è finita` (15), `I have arrived to the conclusion` (26), `lacks me` and
  `belongs me` for the verbs of the dative (30, 31), `make to start the
  positivity` for `fanno scattare` (21), `I will dedicate to the world cup`
  with no reflexive (31), `I bothered to a system` for `davo fastidio ad un
  sistema` (34), `Rosi Also, known for ...` for `Anche Rosi, conosciuto ...`
  (32: the capital goes with the name), `thus` last in 7, `his affection` for
  the people's (36), and the null third person that English refuses on purpose
  in 20 (`che non si occuperà`), 24 (`così come ha accettato`) and 25 (`che
  liberasse amfetamine`). The next sample's controls take this report in.
  The Miss World feature (AnCora CESS-CAST-P-20001201-199, 16 sentences,
  Spanish into Italian and English: 16 of 16 and 15 of 16 on a fresh store, 13
  and 12 with the new store alone, 7 and 8 with the new code on the old store
  and before; reasoning 1.0.8).
  It needed these SHAPES, each with its arm red (test/translate.pl's
  `newspaper_miss`: 68 checks, 65 arms, the guards among them; an arm is a
  library directory of symlinks whose reasoning/translate.pl is the edited
  copy, `COCOLOG_LIBRARY=ARM cocolog query "use_module('test/translate.pl'),
  newspaper_miss, checks_done"`, under a second a run, and every arm of this
  sample is run in twenty seconds, three at a time; the one that stays green
  there, the bytes twin of `tr_skip_inverted/2`, is red in `newspaper_units`,
  whose probes are 51 now): `lo que` is `what`, not `the one that` (`lo que
  interesa hoy es la belleza del espíritu`; the word that replaces a noun and
  says no gender is an article of no lesson, so the crossing keeps `what` and
  English writes it with its clause and no `that` -- `tr_np/3`,
  `tr_cross_det/2`, `tr_np_out/5`, an arm each); `lo` and an adjective that
  judges is what is so (`lo cierto es que las candidatas sólo han tenido 10
  minutos`, `tr_np/3` and `tr_subject_shape/4`, `en_judging/1`; a guard, `lo
  mismo` is the same thing and stays unread); a purpose in front keeps what it
  takes (`Para celebrar este 50 aniversario no se ha escatimado en gastos`: the
  anniversary was the subject of the rest, `The anniversary did not skimp in
  costs to celebrate`, `tr_read0/4`; a guard, a rest with nobody named is none
  for a front with an object, `Para sobrevivir el perro come`); a gerund after
  a subject's phrase is a relative clause on it (`100 jóvenes de 18 a 25 años
  rivalizando hasta el último minuto por un título merecen una audiencia`,
  `tr_subject/6`: the sentence's gerunds are noted when it is read, `$tr_ger`,
  the phrase before one is twelve words at most, holds no verb of its own and
  ends on a noun, an adjective, a number or a name, and what the gerund takes
  is ten words at most -- the first cut asked it of every phrase the search
  tried and cost the long sentences 5 %, a refusal of 476 million inferences
  rising 25); an adjective with a phrase of its own stands after its noun in
  English (`una audiencia digna de una Copa del Mundo`, `tr_comps_out/7`,
  `tr_adj_takes_phrase/3`, a subject's `tr_with_adj/5`, the writer's
  `postadj/2`: three arms); a thing's reflexive is a passive where the lesson
  says `"celebra" takes the passive.` (`el concurso que anoche se celebró en
  Londres`, `tr_se_passive/2` and, in a relative clause, `tr_se_passive_rc/4`,
  a name for the thing included, `Miss Mundo`: three arms, and a guard, a
  person's reflexive is none); a quotation closed before the clause that
  says it (`¿"Cómo podrán conocer nuestra personalidad ...?", se preguntaba
  Michaela`: the mark that closes stands at the head of the piece after it,
  with a comma or none, and was read as the OPENING mark of its first word,
  `tr_quote_pieces/2`, `tr_closing_comma/3`, `tr_skip_inverted/2`, with its
  code-point twin: four arms); `by the time` (`en_connector/1`); a decade
  after a preposition (`en los 70` is `in the 70s` and `negli anni 70`,
  `tr_cross_decade/2` from `tr_cross_comp/2` and `tr_np_out/5`; a guard, a
  pair is none, `tra le 70 e le 90 mila lire`, which the controls found at
  once); `last` and `next` for the adjective of a day, a month or a year
  (`el año pasado`, `el pasado noviembre`, `tr_np_out/5`, `en_time_noun/1`),
  the capital of an English day, month or nationality wherever it stands
  (`en_nationality/1`, `en_calendar_word/1`, `tr_cap/2`) -- SPELLED IN THE
  WORD, never in its case: the first cut set the case to `upper` and lost the
  closing mark of a quotation that ended on the word, `"controlará entre el
  60% y el 70% de los hipermercados catalanes"`, in three sentences of the
  controls (three arms for the marks), and a word that came with its capital
  keeps its small letters, `los Juegos Olímpicos` --; a time that says which
  one after an intransitive verb is when (`Murió la semana pasada`,
  `tr_time_which/1`), `fallecido el pasado noviembre` is no absolute clause
  (`tr_time_deictic/1`, `tr_month_which/1`, three arms); who died (`Eric
  Morley, fallecido el pasado noviembre` is `Eric Morley, who died last
  November`, `en_active_participle/1` in `tr_comps_out/7`, and the phrases
  between the person and the comma come after the clause, a guard that the
  clause has no adverb of its own: three arms); `no longer` is the denial and
  `più` in the lesson's languages and `simply` stands with the verb
  (`tr_write/4`, `en_mid_adverb/1`: three arms); `to begin with` and `in
  reality` stay in front (`en_conjunctive/1`) and `in reality` stands with the
  verb where the source has it inside the clause (`salvaguardano in realtà dai
  microtraumi`, which the new line for `in realtà` wrote last, `on the
  shoulders in reality`: the controls found it); `each` after the count it says
  how much of and `only` before a count of time (`tr_comps_out/7`); the
  adverbs after the word for `that` are the clause's own (`Es cierto que las
  candidatas sólo han tenido 10 minutos`, `tr_advs_into_clause/6`,
  `tr_adv_in_clause/3`: a guard, an adverb right after the RELATIVE `que` is
  the sentence's, `Lo que sí reconoció es que ...` put `sí` inside a quotation
  of the clause, found by the controls) and, of the two clauses a `that`
  joins, those of the first when they stand before the connector (`que esa
  unidad sólo será posible si los nacionalistas aceptan ...` wrote its `sólo`
  at the end of the second, `that never have had the Basques only`,
  `tr_adv_in_first/4`: two arms, and a guard, one after the connector is the
  second's); a participle's agent ends at a comma (`lagrimones vertidos por la
  elegida, en este caso la india Yukta Mookhey`, `tr_phrase_words0/4`); a noun
  and then adjectives alone are no list (`contra un espectáculo, vulgar y
  degradante`, `tr_adjectives_after_noun/3`) and the adjectives after a comma
  agree with the phrase before it (`tr_adj_after_comma/2`, asked once of the
  clause's complements whole, from `tr_write/4` and from its clause for a
  subject after the verb, which takes the complements apart: `Volaron bombas
  de harina contra un espectáculo, al parecer de muchas, vulgar y degradante`
  was `volgari e degradanti`, the bombs', in the controls' own sentence and in
  none of the hand lesson's until a check had the subject after the verb; asked
  of each tail the writer took, the comma before an aside of its own was gone;
  two guards found by the controls, a phrase between commas of its own, `no
  son, en consecuencia, reales`, and a source adjective that says its gender
  for a subject that gives none, `sagr/1`, `Alle spalle ha una vita
  movimentata, quasi avventurosa`); and the small ones: `medio siglo` is `half
  a century`, `este 50 aniversario` is `this 50th anniversary`, `el mismo` is
  not `the same one`, `para qué engañarnos` is `why deceive us`, `escatima en`
  is `skimps on` (`"escatima" takes "en" before the phrase.`, `en_governs/2`),
  and the adverb the lesson says goes with the verb stands with it in the
  lesson's language (`The adverb "ya" precedes the verb.`, `The adverb "già"
  follows the verb.`; `el mundo ya tendrá una nueva miss` is `il mondo avrà
  già`, `tr_pull_foreign_adverb/3`, `tr_fo_mid_insert/4`: before the participle
  of a verb with its auxiliary, after a verb of one word, never between a
  clitic and its verb, and before the impersonal word too, `ya se puede
  decir`: three arms).
  It needed these WORDS in `extra/` (the two readers: a line moves the reader
  of one language and the writer of the other; the dictionary's own word is
  said again first where it must stay the one written): Spanish `miss` (a
  beauty queen, a person), `lagrimón`, `circo` before `tinglado`, `unas
  cuantas`, `sin pena ni gloria` (undistinguished, with its own plural),
  `vuela` (intransitive), `frena` (curbs), `pretende` (intends), `para
  cuando`, `para qué`, `un tanto`, `cada una` and `cada uno` (each), `de
  paso`, `de entrada`, `protagoniza` (stars in), `descubrimiento` before
  `hallazgo`, `capacidad` (a capability), `celebra` (takes the passive), the
  names `miss mundo`, `miss república checa`, `islas maldivas` and `miss mundo
  2000`, `elegida`, `destronado` and `destronada` with their plurals, `capaz`,
  `en realidad`, `echa a rodar` (gets going), `liga bronceado` (gets a tan),
  `sala de juego`, `candidata`, `jurado` (a person), `al parecer de`, `muchas`
  (a pronoun, with `muchos` said first), `ya` (precedes the verb), `se lleva`
  (takes along) and `escatima` (takes `en`); Italian the same words (`miss`,
  `lacrimone`, `senza infamia e senza lode`, `frena`, `recita in`, `per
  quando`, `alquanto`, `a testa`, `di passaggio`, `per cominciare`,
  `prescelta`, `detronizzato` and `detronizzata`, `capace`, `caritatevole`,
  `concorso` first for `contest`, `in realtà`, `parte` (gets going, with the
  dictionary's own `splits` said first), `prende la tintarella`, `sala da
  gioco`, `candidata`, `a parere di`, `già` -- it follows the verb --,
  `deceduto` and its forms, and `porta` (brings, then takes along), said again
  first where the Spanish `lleva` needs it); and in the dictionaries' extras
  `dethrone`, `outgoing`, `dated`, `skimp`, `vie`, `goldmine`, `crown`, `gaze`
  and, for `charity`, `caridad` first and `beneficencia` after it. The first
  word moved in 10 Spanish meanings and 3 Italian ones (Spanish `capaz` is
  capable, `saliente` outgoing, `candidata` a female candidate, `capacidad` a
  capability, `hallazgo` a discovery, `mirada` a gaze, `tinglado` a circus,
  `corona` crowns, `frena` curbs and `pretende` intends; Italian `alquanto` is
  somewhat, `candidata` a female candidate and `frena` curbs), and none was
  lost.
  The CONTROLS (cocolog 2.2.5, store KB177, 94 count files, 2 670 sentences:
  the earlier set with the Rosi report in and this one, both directions): the
  last version's translator against this one, on the one store, 153 sentences
  in 49 files read differently -- 21 in the report's two files and 132 in 47
  files elsewhere, 91 of those by a capital alone (an English nationality, day
  or month: `French`, `Basque`, `Palestinian`, `Sunday`, `September`) and the
  other 41 all better -- `lo que` as `what` (13: es_19981202-34 10,
  es_19990802-48 10, es_19990901-75 8, es_19991001-61 7, es_20000903-30 14,
  es_20020601-51 6, es_20020801-17 9, and six of Tatoeba's, tat 121, 227, 261,
  334, 339 and 366), `last` and `next` (10: es_19981202-34 11, es_19990701-130
  4 and 7, es_20000701-80 6, es_20010102-25 2, es_20011202-66 3, es_20020301-125
  12, it_9816_9850 5, it_9967_9998 4, tat 313), the adverb that goes with the
  verb, `ya` and `già` (es_20010103-120 5 and 16, es_20020102-112 13,
  es_20020601-51 6, it_9763_9774 10, it_9926_9946 13 and 14), `no longer`
  (it_9637_9672 27), `at least` before its count (it_9381_9414 17), `a kit full
  of photographs` (it_9851_9925 68), the adjectives after a comma
  (it_9851_9925 49 and 72: `amigo`, `profundas`), a quotation with its adverb
  inside and `only if` (es_20000903-30 18, in both languages), `anche`
  (es_20020601-51 19) and `in reality safeguard` (it_9567_9604 21) -- and the
  inferences fall 0.944 % (5 006 946 087 to 4 959 655 531) and rise 0.115 %
  outside the report (4 906 098 706 to 4 911 754 432). The file that rises most
  is it_9775_9780's, +7.1 % of 5.0 million (its second sentence, 0.82 to 1.17),
  then it_9567_9604's and es_20020301-125's, +0.6 %; the ones that fall most
  are it_9947_9966's, -1.7 % of 29 million (its twentieth, 4.10 to 3.67
  million, and its eleventh, 1.17 to 1.05: `il prossimo 24 gennaio` and `il
  prossimo febbraio`, which the month's guard, `tr_month_which/1`, reads at
  once), and the report's own; Tempi's twentieth, the sentence that runs to the
  limit, rises 0.03 % (476.49 to 476.62 million). Bytes and characters read
  every sentence alike (0 differ, the bytes 0.018 % more). The DATA COLUMN (the
  last version's translator on its own store, KB170, against this one on the
  new): 163 sentences, 29 in the report's two files and 134 in 49 files
  elsewhere, the 132 of the code and three of the words (es_20010202-169 10,
  `capaz` is `capable`; tat 47, `Devono avere deceduto`, where it was
  `decesso`; it_9567_9604 21, once more), and the inferences fall 6.881 % (5
  326 137 108 to 4 959 655 531) and rise 0.160 % outside the report (4 903 910
  067 to 4 911 754 432). THE STORE ALONE (the last version's translator on the
  old store and on the new) differs in 26 sentences, 23 of them the report's
  and 3 elsewhere, +0.045 % outside it (4 903 910 067 to 4 906 098 706), and
  THE CODE ALONE (the new translator on the old store) in 131, 7 in the
  report's files and 124 in 43 files elsewhere, +0.115 % outside it (to 4 909
  564 479), where the report reads 7 and 8 as before. Eleven expectations of
  the older sections of test/translate.pl and six of lesson 46 were written in
  the old English and changed with the capitals, `last` and `what` (`saturday`,
  `sunday morning`, `next february`, `the next year`, `roman`, `the olympic
  Barcelona`, `the catalan board`, `The one that makes them wished`).
  THE FIRST CUTS' REGRESSIONS, found by the controls and mended: the capital
  set as the word's case lost the closing mark of a quotation (above, three
  sentences) and the small letters of `los Juegos Olímpicos` (`Games Olympic`,
  `Commission European` -- the order asks whether the lesson knows a word with a
  capital); `last` and `next` lost the marks a quotation had on their noun; a
  plural nationality (`los catalanes`) had no capital; `tra le 70 e le 90 mila
  lire` was a decade (the guard, a pair of counts); `Lo que sí reconoció es que
  ...` put `sí` inside the quotation of its clause; the adjectives after a comma
  were the aside's (`no son, en consecuencia, reales`) and a feminine
  adjective's with nobody named (`quasi avventurosa`: two guards); the gerund
  rule cost the long sentences 5 %; and the last two, found by the final
  round, a focus adverb in a clause a `that` joins to another (`sólo` at the
  end of the sentence, where the last version wrote it after the verb of
  saying) and `in realtà` written last once the line made it an adverb. One
  more stayed hidden until the end, in the report's own tenth sentence: the
  hand lesson's check of the adjectives after a comma had the subject before
  the verb, and the real sentence has it after, which the writer takes apart
  (`volgari e degradanti`, the bombs'). THE LINES' OWN REGRESSIONS, found in
  the store alone (25 sentences outside the report on the first store, 3 on the
  last): Italian `parte` as `leaves` first wrote every Spanish `dejar` as
  `partire` and `parte` as `deja` (`nos han dejado` was `ci hanno partito`,
  `Dejé el país` `Partii il paese`, `Parte martedì il corso` `Deja el martes`:
  11 sentences) -- the dictionary's `splits` is said first now, and `gets
  going` after it; the intransitive `espera` (waits) read `esperarse de` as
  `wait` and `Pedro espera a María` as `waits to María` -- out; the pronouns
  `muchas` and `molte`, said first, made every Italian `molti` the Spanish
  `muchas` and read `molte altre cose` as a pronoun and its object (`Many liked
  him other things`) -- `muchos` is said first now and `muchas` after it, and
  the Italian `molte` is out.
  THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT (the five heaviest rises
  counted over a copy of the library per rule, on the new store): two rules are
  all of it. The participle's agent ending at a comma is 0.30 of the 0.31
  million that Rosi's sixth sentence rose, 0.22 of the 0.23 of es_20020301-125 4
  and 0.47 of the 0.50 of the Hotel Arts tenth (+1.1 %, a refusal of 47
  million): the whole rest is asked as the agent first and, when it reads as
  none, the part up to the first comma again. The gerund after a subject's
  phrase is 0.35 of the 0.35 million of it_9775_9780 2 (+43 % of a sentence of
  0.82 million, where `il cuore leggendo nella cronaca ...` is asked as a
  relative clause and the complements of the gerund are read, to be read
  otherwise). `lo` and the adjective that judges (+1 100 to +32 000 a
  sentence), the month's guards and the noun's capital are under 250 each. THE
  STATED COSTS: a first meaning that serves the news and not every text --
  `tinglado` is a circus (a shed second), `frena` curbs (a car brakes second),
  `pretende` intends, `capaz` capable, `capacidad` a capability, `hallazgo` a
  discovery, `mirada` a gaze, `corona` crowns, `candidata` a female candidate,
  `concorso` a contest (the archaic `agone` stays read only), `alquanto`
  somewhat -- and the controls' sentences they change are the three of the data
  column above.
  The report LEAVES, of the 16 into Italian: `per quando leggono queste linee`
  (the subjunctive written as an indicative, `righe`), `in Londres` and `Islas
  Maldivas` (names the lesson knows no city for), `ha rimesso l'immagine`
  (`riproposto`), `l'indiano Yukta Mookhey` and `a parere di molti` (the IR
  keeps no gender for an apposition or a pronoun: `l'indiana`, `molte`, the
  women), `non si è economizzato in costi` (`risparmiato sulle spese`), `50
  anniversario` (`50º`), `di 18 a 25 anni` (`dai 18 ai 25`), `udienza`
  (`pubblico`), `nell'inizio` and `per dei giorni` (`all'inizio`, `per qualche
  giorno`), `il novembre passato` (`lo scorso novembre`), `un eco` (`un'eco`),
  `decise allocare` (`di destinare`), `lavori di beneficenza` (`opere`),
  `potettero` (`poterono`), `ha preteso` for `ha pretendido` (`ha cercato di`),
  `togliere lucentezza al suo affare` for `sacarle lustre a su negocio` (an
  idiom crosses word by word, with no `di` before the infinitive), `un bel
  annuncio` (`un bell'annuncio`), `insiste che` (`sul fatto che`), the
  coordination after `podrán conocer` in 15 (below), `Si chiedeva` with a
  capital after the closing mark, and `attende ancora` for `aún espera` (16);
  of the 15 into English: `a Cup of the World of football` (`a football World
  Cup`), `youngsters of 18 to 25 years` (`aged`), `One has not skimped`
  (`No expense has been spared`), `in the beginning of` (`at the start of`),
  `what wanted was` (6; a relative clause nobody names a subject for is
  written with none, `what he wanted`; `more than what receives`,
  es_19991001-61 7, is the same), `has returned the image` (`brought back`),
  `the new promise` (`hopeful`), `a part of the profits` (`some of`), `to remove
  shine to his business` (`its`), `an ad of bikinis` (`a bikini ad`) and, in 15,
  `How will our personality and our capability be able to know` (a
  coordination after a verb group and its infinitive is read as the subject
  when it agrees with the plural verb, so the infinitive loses its object:
  with one phrase it reads, `How will they be able to know our personality`;
  `¿Cómo comen el pan y la casa?` is `How do the bread and the house eat?`, the
  last version's reading too), `The answer still expects` (16: `espera` is the
  verb of expecting whether or not it has an object, and the line that made it
  wait took `esperarse de` and `espera a María` with it); English refuses 7 for
  the third person nobody names, on purpose (`Pero encontró un filón ...`). The
  next sample's controls take this feature in.

  The review's fixes (an outside review of 283997b, checked by the engine
  session; reasoning 1.0.9, cocolog stays 2.2.5; no new article). Four small
  things, three of them in code or data:
  WHICH, AND WHO DOES IT. `¿Qué libro lee el gato?` was `Which book reads the
  cat?`: `fo_question_word/3` took the phrase asked for as the subject unless a
  name or a pronoun stood alone after the verb, and `¿Qué perro come el pan?`
  has the same shape. `fo_which_object/3` settles it by two things and no
  more: the verb's number (`¿Qué libros lee el gato?`, `¿Qué medidas tomará el
  Gobierno?`: the phrase asked for has no reading in the verb's number and the
  phrase after the verb is one the verb agrees with) and a doer after the verb
  when the phrase asked for is none (a name, a pronoun, a noun the lesson calls
  `person` or `animate`); two doers, or none, are read as before. `animate` is
  a bare-class line like `"amigo" is a person.`, new here: corpus/extra states
  119 Spanish and 109 Italian animals, the nouns whose meaning in the
  vocabulary is `cat`, `dog`, `horse`, ... (found by a script, the false
  friends out: a calf of the leg, a stamp, a drink, a sip, a bat, a game).
  corpus/spanish.txt and italian.txt are the tagger's corpus and are untouched,
  so the hand lesson alone still reads `gato` as no doer; a taught store reads
  it. On the stores: `¿Qué medidas tomará el Gobierno?` was `Which
  measures will take the Government?` and is `Which measures will the
  Government take?`, `¿Qué libro recomienda el autor?` `Which book does the
  author recommend?`, `¿Qué ley firmó el presidente?` `Which law did the
  chairman sign?`, Italian `Quale libro consiglia il medico?` `Which book does
  the doctor advise?`; `¿Qué presidente firmó la ley?`, `¿Qué jugador marcó el
  gol?` and `¿Qué perro come el pan?` read as they did. `test/translate.pl`'s
  `question_roles` (17 checks) and lesson 46's section 72 hold it, with an arm
  for each of the seven rules and five for the guards: a name that goes on is
  not read (`fo_name_goes_on/2`: `¿Qué libro lee Maria Lopez?` is still `Which
  book reads Maria Lopez?`, because `fo_np_words_after/3` ends a bare name at
  its first word -- `¿Qué come Maria Lopez?` is `What does Maria eat Lopez?`
  by the same fault, older than this), two doers, a verb with no subject
  after it (`¿Qué libros hay en la casa?` is `Which books there is in the
  house?`, the old text, which is not a good one). STATED LIMITS: an
  institution is no doer (`¿Qué medida tomó el Gobierno?` is `Which measure
  took the Government?`, `¿Qué partido ganó el equipo?` `Which match won the
  team?`: `"gobierno" is animate.` would mend them, and a list of such nouns
  is the next step), and a noun with the same form in both numbers
  (`crisis`) never clashes with a verb.
  A STATED GENDER MEETS AN ENDING RULE (`tr_gender/2`): feminine was asked
  first, so `"leche" is feminine.` beat the masculine rule and `"mapa" is
  masculine.` lost to the feminine one and wrote `La mapa`. A masculine the
  lesson states now wins unless it states the feminine too (`"mar"`: the
  feminine, as it always was); a denial still wins over a rule. Only
  `tr_gender/2` has the order: the 23 other places that ask
  `tr_holds(feminine(...))` -- participles, adjective forms, a few nouns --
  still ask the rule, and the reasoner holds both genders true as before. It
  costs one fact lookup for a word the rule calls feminine (+0.022 % of the
  inferences of the files into Italian, +0.014 % into Spanish, +0.005 % into
  English). The `stated_gender` section (10 checks, two
  arms) also scans both vocabularies for a masculine noun in `a` whose denial
  is missing: Spanish 166 nouns, none; Italian 90, four, which are
  `caposquadra`, `centro destra`, `centro sinistra` and `microtrauma`
  (corpus/extra/italian.txt, copied as they stood by `cb_extra/1`, so
  `La microtrauma è grande.` was the Italian writer's text): the four lines
  `"X" is not feminine.` are in, and the Italian vocabulary rebuilt.
  THE CONTROLS (cocolog 2.2.5, 94 count files, 2 670 sentences, the last
  version's translator on KB177 against this one; KB178 taught from the
  rebuilt vocabularies): the CODE ALONE changes no sentence (+0.011 % of the
  inferences, 4 959 655 531 to 4 960 191 126), the DATA COLUMN none (KB177 and
  the old code to KB178 and the new: +0.011 %), the STORE ALONE none (with the
  old code -0.000 %, with the new -0.000 %), and bytes and characters read
  every sentence alike (the bytes +0.018 % more). The controls cannot see these
  fixes: not one of their sentences asks `qué` and a noun before a doer, and the
  vocabularies already fenced every masculine noun in `a` they use. The fixes
  stand on their sections and on the stores' own sentences above. THE
  TAGGER'S COMMENT said six rules over eight bullets where the code has
  eleven (library/reasoning/tagger.pl, above `tagger_sane/2`): it lists the
  eleven now; a comment, and the reasoning number moves with it as any change
  under library/reasoning/ does. `lo` is `him` before `it`, as the lesson
  states them, and stays so (the README says it).
  The Lazio football report (VIT-9511..9539, 29 sentences, Italian into Spanish
  and English: 28 of 29 and 26 of 29 on a fresh store, 21 and 20 with the new
  store alone, 14 and 13 with the new code on the old store, 13 and 12 before;
  reasoning 1.0.10). The sample was taken on the cocolog 2.3.0 binary, as the
  owner asked, and every figure below is that binary's. Master's 2.4.0 was
  merged into the branch after the sample; the merge touched nothing under
  library/reasoning/, and the next sample's controls are taken on 2.4.0. The
  article's sentences fall from 209.5 to 24.9 million
  inferences in each language (a refusal is a long search).
  It needed these SHAPES, each with its arm red (test/translate.pl's
  `newspaper_lazio`: 77 checks, 59 arms, the guards among them; an arm is a
  library directory of symlinks whose reasoning/translate.pl is the edited copy,
  `COCOLOG_LIBRARY=ARM cocolog query "use_module('test/translate.pl'),
  newspaper_lazio, checks_done"`, under a second a run, and every arm is run in
  24 seconds, three at a time): `if not` and a phrase (`una curiosità maliziosa,
  se non una vera e propria pressione`: the word for `if` and a denial before a
  phrase travel as they do before an adjunct, the denial and its phrase one
  complement, neg/1, tr_complements0/4; read as a condition the clause had no
  verb and the sentence was refused); an adverb before a purpose in front, at
  the top of a sentence and inside a clause (`quando invece per contestare
  arrivano in tanti`: tr_front_skip_adverbs/2, and a clause of tr_nested_front/3
  for the purpose, which a nested front did not read -- three arms); `when` and
  `where` right after a verb that asks nothing are the relative words (`il cane
  dorme quando il gatto mangia` is `duerme cuando`, where it was the question's
  `cuándo`, tr_relative_wh/3, rwh/2), and `how` with a verb of saying and its
  speaker is `as` (`se "cambiare è migliorare" come dicono i giocatori
  all'unisono`, tr_how_as_saying/2, cmtc/1, past a complement of the verb as
  well, tr_relative_wh_after/3), a verb that takes the question keeping it --
  whether the lesson says so (`"sa" takes the question.`) or not, for the verbs
  of asking, seeing, finding out and saying (tr_asks_question_here/0, en_asks/1:
  `vede quando il gatto mangia` is `ve cuándo`) -- six arms; a name and an
  adjective with the copula left out (`Signori ottimista, Zeman velenoso`,
  tr_verbless0/3); a front that ends on an absolute clause with no comma leaves
  the rest its subject (`Dopo una rivoluzione mancata la Lazio si è ritrovata
  uguale a sé stessa`: longest first the front took `mancata la Lazio` for a
  clause of its own and the `si` of the rest was the impersonal one, `One has
  found equal to itself after a revolution lacked the Lazio` -- two arms, the
  rule and its guard against an impersonal subject, whose check is `il cane si
  mangia il pane`); the word for `same` after a reflexive pronoun is its
  emphasis in English (`equal to itself`, tr_comps_out/7); a headline after a
  section's name and a dash that opens on a plural noun and its adjective is the
  noun first (`Calcio - dichiarazioni varie del giocatore e del Ct della Lazio`:
  `varie` is what `variare` says as well, tr_read0/4); a question after an
  infinitive that takes it, and the word the infinitive puts before it (`si è
  limitata a macerarsi su chi dovesse vendere` is agonises OVER who:
  tr_relative_wh_after/3, tr_question_after_inf/4 for the infinitives with `a`
  and the bare ones, tr_wh_verb_set/1, tr_wh_preposition/2, en_governs/2 -- six
  arms), and `chi` after a verb that takes the question asks (`non so chi
  vende`, tr_who_gap/2 -- two arms); three names and an adverb that closes them
  (`Stoichkov, Baggio, Lombardo eccetera`, tr_list_closer/2, and a comma after
  the adverb); `non solo,` a comma and a clause with no partner said (the two
  words are an adverb of the clause after the comma, nonly/0, read, written and
  crossed -- three arms); `mentre` as a connector is not lifted as the adverb it
  is also (tr_head_connector_lifted/3); the future after `if` (`se riusciremo a
  giocare` is `if we succeed in playing`, `si logramos`: tr_if_future/4, and
  tr_clause_present/2 for both clauses of a condition joined by `and`; of an
  Italian text only, because Spanish's `si vendrá` is a question and keeps its
  future, tr_future_protasis_language/1; and never of the clause an `if` joins
  to a clause that asks, a copula with nothing after it or a verb of asking,
  saying and knowing, tr_whether_governor/1: `Il dubbio è se il cane verrà o se
  il gatto dormirà` is the doubt is if the dog WILL come, and the `or` clause
  after it is a question as well, '$tr_whether', tr_write_second/4 -- six arms);
  `secondo me` is `según yo` in Spanish (tr_subject_form_preposition/1); `lo`
  after a verb of saying is what is said (`A dirlo è Giuseppe Signori` is
  Signori says IT) -- never a dative (`gli ho chiesto` is I asked HIM) and never
  the pronoun after an infinitive (`le ha detto di essere stata lei` is said to
  her to have been HER), three arms; the partitive after a verb of having,
  buying and eating (`il torneo ha delle novità` has novelties: Italian only,
  the first complement, a definite article and a common noun, after the verbs of
  tr_partitive_verb/1 -- `parla dei gatti` is of the cats, and `della piccola
  Sofia` and `di una domenica` are phrases of `of` -- three arms); the perfect
  gerund is the auxiliary's (`avendo mantenuto` is `habiendo mantenido`, not
  `teniendo`, and the participle agrees with nobody -- two arms); a pronoun
  after `di` that a preposition takes (`senza di lui`, the lesson line `"senza"
  takes "di" before the pronoun.`); a plural of the first person names a team in
  the singular (`Siamo una squadra`, tr_null_copula_agrees/4); `una delle
  quattro squadre` is no ratio (tr_phrase_words0/4) and Spanish has the gender
  of the noun the phrase names (`uno de los cuatro equipos`, tr_ell_gender/2);
  two next numbers with a dash between them are either (`una delle quattro -
  cinque squadre`, tr_number_ranges/2, and `los cuatro o cinco equipos`,
  tr_elided_count/2, which leaves `21 nuove e 12 rinnovi` alone); one of the
  teams is no person (tr_of_class/2); `né ... né` is `neither ... nor` and one
  denial in English (`non è né stanco né caldo`, `non dorme né con il gatto né
  con il pane`, tr_nor_list/3); two connectors of several words (`premesso che`,
  `tanto è vero che`, en_connector/1); a Bohemian has his capital
  (en_nationality/1); the verb of a relative clause whose word is its object has
  an object (`l'allenatore che ora conosciamo` is `conocemos`, not `sabemos`,
  tr_passive_object/3); and a verb of several words that begins with the copula
  is no comment (`in un certo senso sono troppi, sono d'accordo, ma non pensate
  che ...`: between two commas a verb in the first person is the writer's own
  comment, tr_asides/3, "never the copula", and `sono d'accordo`, stated as the
  verb `è d'accordo`, took the sentence away -- the data column found it,
  tr_copula_group/1).
  It needed these WORDS in `extra/` (the two readers: a line moves the reader of
  one language and the writer of the other; the dictionary's own word is said
  again first where it must stay the one written): Italian `buriana` (storm),
  `offusca` (overshadows, with its forms), `a l'unisono`, `autocritica`, `boemo`
  (a person), every number from twenty-one to ninety-nine the lesson lacked (70
  lines), `valore` (a value, where the dictionary's first meaning is courage),
  `si macera` (agonises, `su` before the question), `premesso che` and `tanto è
  vero che`, `è d'accordo` (is in agreement, with its forms and `su` before the
  phrase), the prepositions that take `di` before a pronoun (`senza`, `contro`,
  `verso`, `su`, `sopra`, `sotto`, `dentro`, `fuori`, `dietro`, `tra`, `fra`),
  the names `signori`, `scala`, `lombardo`, `romano` and `esposito`, `mancato`
  (failed, where the participle read as lacked), `vero e proprio`, `in tanti`
  and `in tanti di più`, `allenatore` and `ct` (a coach, a person), `di primo
  piano` and `di vertice`, `malizioso`, `lato` (a side, not a canton), `per poi`
  (begins the purpose) and `parte` (departs, where the dictionary's first is
  splits); Spanish the same (`autocrítica`, `al unísono`, `bohemio`, `se
  atormenta` with `por`, `dado que`, `tanto es así que`, `está de acuerdo` with
  `con`, `conmigo` and `contigo` as contractions, `fallido`, `en gran número`
  and `en mayor número`, `de primera línea` and `de primer nivel`, `malicioso`,
  `para luego`, and `habiendo` as the gerund of the auxiliary); and in the
  dictionaries' extras `reinforcement`, `bizarre`, `supporter`, `merit`,
  `renewal`, `dismember`, `recommence`, `hoard`, `upset`, `Bohemian` and
  `improve` (`migliorare`, both ways: the dictionary's first English for it is
  `enhance`) for Italian, and `dismember`, `recommence`, `overshadow` and
  `spring` (`primavera`: the dictionary's first Spanish noun for it is a coil)
  for Spanish. The first word moved in 6 Italian meanings and 3 Spanish ones
  (Italian `maliziosa` and `malizioso` malicious, `lato` side, `valore` value,
  `migliora` improves, `parte` departs; Spanish `maliciosa`, `malicioso` and
  `parte`), and none was lost.
  THE CONTROLS (cocolog 2.3.0, store KB187, 94 count files, 2 670 sentences:
  every earlier article and Tatoeba's 400, both directions; this report is not
  among them): the last version's translator against this one, on the one store,
  20 sentences in 12 files read differently, all better -- `it` for `him` after
  a verb of saying (es_20000701-80 20, it_9465_9470 4, it_9714_9749 6 and
  it_9926_9946 6, English), the future after `if` (it_9567_9604 30, it_9800_9814
  10, it_9851_9925 57, it_9947_9966 11 and 15), `for itself` for `for itself
  same` (es_20000903-30 19), `conocido` for `sabido` (it_10059_10095 35),
  `hacemos errores` for `hacemos de los errores` (it_9816_9850 25), and three
  sentences the last version's translator did not read on this store:
  it_9816_9850 11 in both languages (below) and es_20020601-51 13 into English
  -- and the inferences fall 1.472 % (5 023 520 002 to 4 949 559 324) and rise
  0.077 % outside the four sentences that fall by over a million (3.77 million
  of 4.89 billion). The files that rise most are it_9781_9791's, it_9763_9774's
  and it_9450_9464's, +0.2 %, and the sentences that rise most it_9673_9712 27
  (+75 thousand of 20.4 million), it_9967_9998 22 and 25 (+74 thousand each) and
  it_9270_9295 8 (+40 thousand); the ones that fall are it_9816_9850 11 (37.6
  million to 4.6, read) and 25 (30.3 to 24.4). Bytes and characters read every
  sentence alike (0 differ, the bytes 0.018 % more). The DATA COLUMN (the last
  version's translator on its own store, KB179, against this one on the new): 33
  sentences, the 20 of the code and 13 of the words -- `valore` is `value`
  (it_10059_10095 30, it_9714_9749 24), `parte` departs where it split
  (it_9967_9998 32, it_9714_9749 28), `migliorare` improves (it_9567_9604 24
  into Spanish), `sono d'accordo` is `estoy de acuerdo` (it_9816_9850 15),
  `conmigo` (tat 380, into both) -- and the inferences fall 0.214 % (4 960 189
  446 to 4 949 559 324) and rise 0.076 % outside the four. THE CODE ALONE (this
  translator on the old store): 18 sentences, -0.162 %, +0.077 % outside the two
  falls. THE STORE ALONE (the last version's translator on the old store and on
  the new): 15 sentences, +1.277 % of the inferences (4 960 189 446 to 5 023 520
  002), all of it one sentence: it_9816_9850 11, 5.3 million inferences on the
  old store and refused after 37.6 on the new (+64.5 million in the two
  languages, the rest of the files falling by 1.2 million together) -- the one
  sentence of the data column that went from read to refused, found by teaching
  the old store with each group of the new Italian lines (19 groups, 13 seconds
  a store). The line `"sono d'accordo" is the first person of "è d'accordo".`
  makes `sono d'accordo` a verb in the first person, which the writer's-comment
  clause of tr_asides/3 took between its two commas (it leaves the copula alone
  by name, and its comment says why: this very sentence), and this translator
  reads it in 4.6 million (tr_copula_group/1).
  THE FIRST CUTS' REGRESSIONS, found by the controls and mended: the partitive
  took the contraction of every kind (Spanish `El perro tiene del pan`, `di una
  domenica`, `della piccola Sofia`, `in compagnia della moglie`, `dare del
  sentimentale`), and is Italian's alone now, the first complement, a definite
  article and a common noun, after a short list of verbs; `it` after a verb of
  saying changed three datives (`gli ho chiesto`, `se lo pide`, `le ha detto`: a
  dative sets '$tr_opron_dat'); the count in its noun's gender regendered `21
  nuove e 12 rinnovi` (a number and no adjective now); a trial round found `lei`
  after an infinitive written `it` (`le ha detto di essere stata lei ad
  avvertire il bagnino`), and `La duda es si el portero recuperará hoy mismo la
  titularidad o si el técnico optará` and `El perro pregunta si el gato vendrá`
  read as conditions (the future after `if` is Italian's alone now, and a clause
  that asks keeps its future); the first cut of `when` made `Il cane chiede
  quando arriva il gatto`, `Vedremo quando arriva il treno` and `Mi chiedo
  quando il cane mangia` relatives -- the whole case's old guard (`Il cane vede
  quando il gatto dorme`) found one and the real vocabulary the rest, because
  the lessons say a verb takes the question for a handful of verbs only; and the
  second cut of the future after `if`, restricted to the condition in front,
  lost the article's own sentence 21 (`Possiamo vincere se riusciremo a giocare
  il nostro calcio`), which the clause that asks decides now. Four guards were
  taken out because their arms moved nothing in the controls, in the article or
  in the section: the verb-form guard of `se non` and a phrase and of a name and
  an adjective (tr_denied_verb_form/1), and the capital guard of the noun-first
  headline and of the headline after a dash. THE COST OF THE CODE, FOUND BY
  TAKING EACH RULE OUT (the five heaviest rises counted over a copy of the
  library per rule, on the new store): three rules are 98 % of the 299 thousand
  inferences the five rose -- the clause of tr_nested_front/3 for a purpose,
  asked at every nested clause (217 thousand, 73 %), `chi` after a verb that
  takes the question (46 thousand) and a pronoun after `di` (30 thousand); every
  other rule is under a thousand.
  THE STATED COSTS: es_20020601-51 13 is read into English (`Step by step, one
  shows proud to the elite, without asking who has in front`: the `se` of `se
  asoma` is the impersonal one, and the sentence was refused); the first meaning
  that serves the news and not every text -- `parte` departs (`partido` is the
  participle of `partir`, `departed` where it was `split`, es_20010102-25 11,
  and `parte civile` is `departs civil`, it_9926_9946 9: a noun the lesson does
  not state), `valore` a value, `lato` a side, `malizioso` malicious,
  `migliorare` improves; and the verbs of asking, seeing, finding out and saying
  keep the question after them (`Ricordo quando eravamo giovani` is still
  `Recuerdo cuándo`: `ricorda` is a verb of saying), a short table and not a
  measure of the verb. The report LEAVES, of the 29 into Spanish: 2, the
  headline `Signori ottimista, Zeman velenoso: assurdo, Balbo italiano"` (a lone
  adjective, a comma and a name with its adjective: `Zeman velenoso, assurdo,
  Balbo italiano` reads, `Assurdo, Balbo italiano` is refused, in both
  languages); `Giappone` and `Italia` stay (no lesson states a country), and 4
  writes `vederne` as `verlo los lados` (the clitic `ne`); 7 `gran parte` is
  `grandes parte` (and English puts the relative clause before `says it`); 8
  `che ne è seguita` is `que lo es seguida`; 10 the marks of `se "cambiare sia
  davvero migliorare"` are moved and its subjunctive written as an indicative;
  11 `Lo stesso` is `El mismo`, `di questi molti sono` `muchos son ... desde
  cerca de éstos` and `si porta dietro` `se trae atrás`; 14 `secondo me` is last
  and `non sono cambiati molto` is `no son cambiados muy`; 16 `lo meritava di
  più Beppe` is `lo merecía más a Beppe`; 17 `per la prima volta` stands last;
  18 `essendosi trovato` is `siendose encontrado` (the perfect gerund of a
  reflexive verb); 21 `riuscire a` is `attain to` in English; 24 and 26 write
  the subjunctive as an indicative, and `giochi` is the noun in 26 (`juegos para
  el Argentino`); 27 `ha fatto sapere` is `ha hecho conocer` and `offerte`
  `intentos`; English refuses 23 and 24, the third person nobody names, on
  purpose, and writes `each federation has his regulations` in 25. The next
  sample's controls take this report in.
  The Inter feature (AnCora CESS-CAST-P-20011002-160, 14 sentences, Spanish into
  Italian and English: 14 of 14 and 13 of 14 on a fresh store, 10 and 8 with the
  new store alone, 5 and 6 with the new code on the old store, 3 and 4 before;
  reasoning 1.0.11). The sample was taken on the cocolog 2.4.0 binary, master's
  (the Lazio report is in master with it), and cocolog stays 2.4.0. The
  article's sentences fall from 587.7 to 46.0 million inferences into Italian
  and from 587.3 to 45.3 into English (a refusal is a long search: the first
  sentence alone was 527 million inferences and refused); its second sentence is
  20 million of the 46.
  It needed these SHAPES, each with its arm red (test/translate.pl's
  `newspaper_inter`: 64 checks, 67 arms, the guards among them, and one rule,
  `nothing-of-shape`, with no arm that goes red, below; an arm is a library
  directory of symlinks whose reasoning/translate.pl is the edited copy,
  `COCOLOG_LIBRARY=ARM cocolog query "use_module('test/translate.pl'),
  newspaper_inter, checks_done"`, three seconds a run, and every arm is run in
  under a minute, three at a time): the doer after a relative clause's verb (`el
  pan que come el perro` is the bread the dog eats, and read with the relative
  word for the subject it was `the bread that eats the dog`: Spanish marks an
  animate object with `a`, so a definite phrase right after the verb that names
  a doer -- a name, a team's name, a noun the lesson calls a person, an animal
  or a group -- and no `a` in the clause is the clause's subject and the
  relative word its object, tr_rc_role/7's clause for tr_rel_doer/2; `"equipo"
  is a group.` is new, 42 Spanish and 43 Italian nouns of the kind, the next
  step the review's stated limit of reasoning 1.0.9 named, and `partido` is no
  group: it is a match; the guards, one arm each: an `a` in the clause, an
  indefinite phrase (`un jugador que busca un entrenador`), a name where the
  phrase it hangs on is a doer itself (`el técnico que dirige el Inter`), a
  copula for any relative word but `lo que` (`la ciudad que es la capital`), an
  infinitive before the phrase (`Craxi che minaccia di regolare i conti con i
  magistrati`: `conti` are also counts, persons, and the sentence was refused),
  the phrase of a pronoun before it (`cuenta con 19 emisoras de toda Catalunya`
  made Catalunya the doer), and for a lesson with no word before a person,
  Italian's, the rule only where the phrase it hangs on is no doer: `il pane che
  mangia il cane` is the bread the dog eats, `una madre che ha perso la figlia`
  still lost her daughter; with the copula, `lo que hoy es el equipo` is what
  the team is today; the question words take a group for a doer too, `¿Qué
  medida tomó el Gobierno?`, fo_animate_phrase/1); an adverb before the verb of
  an object relative is one of its complements (`el pan que siempre come el
  perro`, tr_relative_clause/4); a verb of saying with nothing after it has its
  object in the relative word (`con lo que dice`, tr_rc_role/7 and
  tr_object_verb/1, English writes `they`; `hace` is not one of them: `lo que
  hace es "desacreditar"` is what the insistence does, and with a null subject
  English refused Conyers' sentence of the controls); a connector of three words
  with no comma before it and a verb straight after it is a preposition and its
  relative (`no convence a nadie con lo que dice`, tr_unjoin_relative/3 in
  tr_joined_words/3, tr_comma_connector/1; the comma keeps the consequence,
  `Pedro duerme, con lo que dice`, and so does a phrase and its verb, `...
  estuvieron en Gandía con lo que esa elección resulta más que cuestionable`),
  and `de lo que` after a word of quantity is not the `than what` of a
  comparison (`nada de lo que`, tr_quantity_word/1); `pero sí` before a
  preposition is a contrast and the stress is dropped (tr_drop_contrast_yes/3),
  and a relative clause ends at the comma of a contrast with no verb
  (tr_contrast_cut/4); a verb before an infinitive crosses by the meaning the
  lesson gives it there (`The infinitival verb "trata" means "tries".`, with the
  plain `The verb "trata" means "treats".` said first, tr_mean_links/3,
  tr_verb_across/5; before a phrase it is `treats` still, `se trata de un
  perro`); an animal is a person for the word before one -- a definite animal
  only, `preparar un "cocodrilo"` is an obituary (`coccodrillo`) and takes none
  (tr_of_class/2, tr_marker/3), and `nadie`, `alguien`, `nessuno`, `qualcuno`
  are persons; `desde` and a date is since, and a present that has gone on is
  the perfect in English (`no gana el scudetto desde 1989` has not won the title
  since 1989, tr_cross_comp/2, tr_since_phrase/1, en_since_comp/1): a year, a
  month, a day of the week or a time with a PAST adjective, never a place, a
  range (`dal 24 luglio al 25 agosto` is from July 24 to August 25,
  tr_cross_comps/2, tr_date_range/1), a time to come (`dalla settimana prossima`
  is from next week, and the lesson's own `since` keeps the present, `fin dalla
  prossima riunione`) or a phrase after a comma, which is the aside's (`Pratesi,
  amico da anni della coppia` is a friend for years, and the interview had not
  `paralysed` for years); `todo lo que`, all that (tr_np/3's all/2 with ell/4,
  tr_subject_shape/4, tr_np_out/5), `nada de lo que`, nothing of what (tr_np/3
  -- with the verb `nada` swims in the hand lesson, or a lesson that has it
  reads the verb -- and tr_subject_shape/4, the one rule with no arm that goes
  red: without it the text is the same and the Inter's eighth sentence costs 7.5
  % more) and `lo más ADJ de ...`, the most ... thing ABOUT it (tr_np/3 over the
  unfolded words of a subject and over the degree the complements fold, `colocar
  al club en lo más alto`, tr_subject_shape/4, tr_with_adj/5; a lesson in which
  `lo` is no pronoun after a preposition, `"lo" means "him"`, is what shows the
  folded one; the six clauses of the three, in tr_np/3 and tr_subject_shape/4,
  are asked in a sentence that has a word that replaces a noun with a relative
  word or a degree word right after it and in no other, `$tr_replacer`,
  tr_replacer_note/1: each asked the lexicon first at every phrase, which was
  1.2 million of the 2.1 million inferences the fourteen heaviest risers of the
  controls rose, and the note makes the arm `replacer-note` red by always saying
  no); a capital name the lesson states after an article that is not its noun's
  gender is the name (`el Valencia`, tr_np/3; `la Valencia` keeps the noun), and
  a noun of several words that opens on a nationality has its capital (`Italian
  football`, tr_np_out/5, en_nationality/1); `must` has no perfect, `has had to`
  (en_group/9); `Hace dos años que el Inter no ocupaba ...` is `It has been two
  years since ...` (tr_write/4); the doer after a preposition's relative (`un
  ataque con el que sueñan los interistas`, tr_rel_doer_fix/3, and the
  preposition is the English verb's own, `dream OF`, en_governs/2), and a second
  relative clause joined to the first by a coordinator whose doer follows its
  verb (`... Y QUE han truncado las constantes lesiones`, tr_np/3's nrc/3 with
  ro/2, tr_nrc_head/2, tr_np_out/5; inside a clause of `that` the whole is one
  clause, tr_second_relative/4; the reader runs in a sentence that has the
  pattern only, `$tr_second_rel`, tr_second_rel_note/1); the phrase that is not
  `of` after the participle of a predicate is the participle's (`un delantero
  forjado en la cantera del Inter`, tr_participle_predicate/3); a relative
  clause with two fronts, each set off by commas (`la gestión que ahora, con su
  noveno proyecto, parece ...`, tr_relative_clause/4) and the aside after the
  word right after the opener (tr_clause_mids/4: set apart first and, if the
  sentence then reads nothing, left among the words); the second of two
  adjectives before their noun (`un largo y duro periodo`, tr_phrase_words0/4);
  a word that is a preposition and a verb (`para`) is the preposition before a
  person (`un largo periodo para su propietario y accionista`,
  tr_read_generic/4; `"accionista" is a person.` is a line of corpus/extra); an
  adverb of manner right after a participle stays with it (`organizado
  tácticamente y unido`, tr_comps_out/7) and the participles and adjectives
  after the comma agree with the noun written (`una squadra compatta,
  organizzata ... e unita`, tr_adj_after_comma/2, tr_agreeing_run/3, only after
  an object: after the phrase of a preposition they are the subject's, `in piena
  libertà, regolamentate`); and the builder's: an adverb that is its adjective
  written again (the dictionary's musical `largo` and `allegro`) is no entry
  (corpus/build.pl's cb_stray_adverb/2: `un largo y duro periodo` read `largo`
  as the adverb).
  It needed these WORDS in `extra/` (the two readers: a line moves the reader of
  one language and the writer of the other; the dictionary's own word is said
  again first where it must stay the one written): Spanish `interista` (an Inter
  fan, a person, not feminine), `scudetto` (a title, with the dictionary's
  `título` said first before it, or every Italian `titolo` was written
  `scudetto`), `ataque` (said again first) and `delantera` (an attack), `en
  cambio` (said again first) and `en su lugar` (instead), `vestuario` (a
  changing room), `cantera` (a youth academy), `sensatez` (good sense),
  `nerazzurro` and the paper's `neriazzurro` (black-and-blue), `calcio` (Italian
  football), the names `Valencia` and `Sierra Leona`, `trata` before an
  infinitive (tries, with the plain `treats` said first before it, or `se trata
  de un perro` was `one tries of a dog`), 42 groups (`equipo`, `club`,
  `gobierno`, `empresa`, ...), `nadie`, `alguien` and `accionista` (persons),
  `fracaso` (a failure, where the dictionary's first Spanish noun for it is
  `fallo`), `trayectoria` (a trajectory), `corbata` (a necktie, below) and
  `tiene que ver` (has to do); Italian `appare` and `riconquista` (said again
  first), `ha a che fare` (has to do), `spogliatoio` (a changing room),
  `tatticamente`, `interista`, `invece` (said again first) and `al suo posto`
  (instead), `vivaio` (a youth academy), `sensatezza` (good sense),
  `nerazzurro`, `calcio` (the football said again first, the Italian football
  after it, the kick last), 43 groups, `nessuno` and `qualcuno` (persons),
  `fallimento` (a failure), `traiettoria` (a trajectory), `acquisto` (the
  purchase first, the signing after it, the shopping last) and `cravatta` (a
  necktie); and in the dictionaries' extras, for Italian `sconvolgere`
  (convulse), `indisciplinato` (unruly), `avallare` (endorse), `pareggio` (a
  tie, where the dictionary's first Italian noun for it is the necktie),
  `efficace` (effective) and `forgiare` (forge), and for Spanish `convulsionar`,
  `díscolo`, `taciturno`, `tácticamente` and, read only, `recobrar` (regain).
  The first word moved in 7 Spanish meanings and 5 Italian ones (Spanish
  `calcio` Italian football, `cantera` a youth academy, `corbata` a necktie,
  `delantera` an attack, `trayectoria` a trajectory, `vestuario` a changing room
  and `tiene que ver` has to do; Italian `cravatta` a necktie, `fallimento` a
  failure, `traiettoria` a trajectory, `vivaio` a youth academy and `ha a che
  fare` has to do), and two were lost, the adverbs `largo` and `allegro`, the
  dictionary's musical ones that mean themselves (the builder's rule, above).
  THE CONTROLS (cocolog 2.4.0, store KB195, 96 count files, 2 728 sentences: the
  earlier set with the Lazio report in, both directions; this report is not
  among them): the last version's translator against this one, on the one store,
  21 sentences in 14 files read differently, all better -- the doer after the
  verb of a relative clause (es_19990601-23 5, es_20000802-31 3, es_20000903-30
  10 and 18, es_20001201-176 10, es_20010103-120 4, es_20020801-17 8, and
  Tatoeba's 227, 334 and 339: `the majority backing that Solana has obtained`,
  `what Tom said was certain`, `what they were saying`), `since` (es_20010102-25
  4 and it_9750_9762 3: `Since Sunday`, `since 1992`), `had to` for `musted`
  (it_10059_10095 2), a participle and its phrase (es_20010202-169 6, `a
  stradivarius known like Golden Bell`; it_9637_9672 8, `the dramatic picture
  contained in the report`), `definitively` before the date (it_9926_9946 12),
  the capital of `Christian` (it_9673_9712 16) and the animal that needs no
  second reading as a phrase of `to` (tat 107, `The cat ate the mouse`, in both
  languages) -- but one of them, es_20010102-25 4 into Italian, only different:
  `Fin da domenica` for `Da domenica`, the Italian writer's first word for
  `since` -- and the inferences rise 0.177 % (5 000 350 488 to 5 009 219 484).
  The sentences that rise most are Tempi's twentieth, the one that runs to the
  limit in both languages (476.70 to 477.02 million, +0.07 %), es_20020301-125 1
  (+0.25 million of 1.29: the doer after `que encabeza Jordi Porta`, the clause
  read both ways), es_20000903-30 18 (+0.13 of 79.2) and es_20001201-176 10
  (+0.12 of 4.4, a better reading: `el aire que necesitaba el equipo de Aíto`);
  the files that rise most are es_20020301-125's, +0.7 % of 44 million, then
  it_9465_9470's (2.5), es_20010103-139's (9) and Tatoeba's (43), +0.4 %; no
  file falls, and the one sentence that does is tat 107 (134 509 inferences to
  102 471, the animal). Bytes and characters read every sentence alike (0
  differ, the bytes 0.018 % more). The DATA COLUMN (the last version's
  translator on its own store, KB188, against this one on the new): 31 sentences
  in 18 files, the 21 of the code and 10 of the words, and the inferences rise
  0.199 % (4 999 257 736 to 5 009 219 484). THE CODE ALONE (this translator on
  the old store): 19 sentences in 12 files, the same 19, +0.172 %. THE STORE
  ALONE (the last version's translator on the old store and on the new) differs
  in 10 sentences in 9 files, +0.022 % of the inferences (4 999 257 736 to 5 000
  350 488), each a word of the report's lines and one of them worse: `tiene que
  ver` and `ha a che fare` have to do (es_19981202-34 9 and it_9270_9295 17,
  English), `aparecer` is `apparire` where the dictionary's first Italian verb
  for it was `figurare` (es_19981202-34 7, es_20000102-120 7, es_20010102-25 16,
  es_20020102-112 2), `trayectoria` a trajectory (es_20000903-30 14, English),
  `efficace` for `effettive` (es_20001201-176 5), `corbata` a necktie (tat 50,
  English) -- and `no figuran ni Rivaldo` is `non appaiono` (es_20010103-120 5),
  where `figurano` was right.
  THE LINES' OWN REGRESSIONS, found in the store-alone column of the first store
  (25 sentences, 14 of them worse) and mended: `The masculine noun "scudetto"
  means "title".` came first for the Spanish writer, so every Italian `titolo`
  was written `scudetto` (`el scudetto mundial`, `los scudettos` for the
  headlines: it_9567_9604 8, 30 and 32, it_9637_9672 15, it_9714_9749 4 and 10)
  -- the dictionary's own `título` is said again first; the English `tie` for
  `pareggio` came first for the Italian writer, so `su corbata` was `il suo
  pareggio` (tat 50) -- the necktie has a word of its own in both languages
  (`corbata`, `cravatta`) and the draw keeps the tie; and `The infinitival verb
  "trata" means "tries".` said first made `tries` the verb's meaning anywhere,
  so `se trató de unos 10 kilos` (es_20010102-25 7 and 9, es_20000802-31 9, both
  languages) was `one tried of about 10 kilos` and `si tentò di circa 10 chili`
  -- the plain `treats` is said first, as the hand lesson of the section had it
  all along (the vocabulary check had the order backwards, and the section was
  green). It is the reason to read the texts of the store alone, not its count:
  +0.022 % of the inferences hid 14 worse sentences in 25.
  THE FIRST CUTS' REGRESSIONS, found by the controls (the texts of every
  sentence that differs, not the counts) and mended: the first pass changed 42
  sentences, refused 3 that the last version read (es_19981202-34 10,
  it_9781_9791 6 and it_9967_9998 32, all into English) and cost +1.019 % of the
  inferences (5 000 357 282 to 5 051 321 327; it_9270_9295 rose 9.7 % of 137
  million). `hace` among the verbs that leave their object in the relative word
  refused Conyers' sentence (`lo que hace es "desacreditar"`, the insistence
  does it); an infinitive after the verb was not looked at, so `Craxi che
  minaccia di regolare i conti con i magistrati` had `conti` for the doer of the
  threat; the aside right after a clause's opener was kept among the words only
  when nothing else read, and `Salvo che lui, a differenza di Agostino, era
  disposto ...` read `lui` as the pronoun of a clause with no verb (the
  extraction is the first try now, and the unextracted words the fallback: a cut
  in the else branch of a condition cuts the clause in cocolog, so the condition
  decides it, tr_clause_mids/4) -- the first cut of that rule moved the aside of
  `Quest'Uomo che una volta, a fianco di Marco Pannella, si batteva`
  (it_9775_9780 3) and lost the comment between the dashes of `Gallo - continua
  - mi ha lasciato` (it_9540_9566 21); `desde` made every phrase since -- `dal
  24 luglio al 25 agosto` (it_9472_9484 12), `dalla settimana prossima`
  (it_9270_9295 10), `fin dalla prossima riunione` (it_9673_9712 18), `desde el
  primer momento` (es_20000903-30 16) and `amico da anni della coppia`, whose
  friend had paralysed the interview for years (it_9851_9925 49); `preparare un
  coccodrillo` (it_10059_10095 4) was a man's crocodile; a connector of three
  words took a phrase and its verb after it (`Rivaldo y Overmars tampoco
  estuvieron en Gandía con lo que esa elección resulta más que cuestionable`,
  es_20010103-120 8); the doer was the name in the phrase of a pronoun (`cuenta
  con 19 emisoras de toda Catalunya`, es_19990701-130 6) and the daughter of a
  mother who lost her (`una madre che ha perso la figlia`, it_9851_9925 6); the
  participles after a comma agreed with the nearest noun after a phrase of a
  preposition (`in piena libertà, regolamentate`, it_9792_9799 2) and `fallecido
  el pasado noviembre` with the days before it (`deceduti`, es_20001201-199 4).
  The cost was one rule, the second relative clause, asked of every long
  sentence with a coordinator: +12 million in two sentences of it_9270_9295
  alone. `$tr_second_rel` is set once a sentence from a test of its words (a
  coordinator, a relative word and a doer after a verb, tr_second_rel_note/1)
  and the reader asks only where it is `yes`; its first test took the verb form
  of `truncado`, which is a noun too, and the section's own sentence lost its
  second relative clause (tr_verb_form_any/1 asks the participles as well).
  THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT (a copy of the library per
  rule, on KB195: first the 14 heaviest risers of the controls, then 56
  sentences of 0.2 to 2 million inferences, every k-th of the class, 28 of each
  language, into English): the second cut was +0.319 % of the controls (5 000
  350 488 to 5 016 313 242), and the 14 rose 2.1 million of 399.5 (+0.528 %), 58
  % of it six clauses of three rules -- `todo lo que` (tr_np/3 395 thousand
  inferences, tr_subject_shape/4 103), `nada de lo que` (287 and 85) and `lo más
  ADJ` (156 and 199) -- each asking the lexicon first, at every phrase of every
  sentence (a memo hit is 11 to 13 inferences), and the rest the doer after a
  relative clause's verb (365: es_20020301-125 1 is read both ways, 1.29 to 1.54
  million, and es_20001201-176 10 reads `que necesitaba el equipo` as it should,
  +0.12), the two fronts (228), a participle's phrase (96), a preposition that
  is a verb (50) and a name's gender (35). What paid was a note made once a
  sentence: `$tr_replacer` (a word that replaces a noun with a relative word or
  a degree word right after it, tr_replacer_note/1) is asked first by the six
  clauses, one inference where it says no, and costs its own scan, 218
  inferences in a sentence of five words and 2 700 in fifty -- every sentence
  read alike (0 differ), -0.133 % of the controls, so +0.186 % -- and three
  idioms: `sub_atom/5`, which walks every position, asked of every noun English
  writes for a nationality (`atomic_list_concat/3` splits it), and two walks of
  every word for `sí` and for a connector (`memberchk/2` and the connector
  facts): -0.009 %, so +0.177 %. What is left is no rule: over the 56 sentences
  +0.353 % (47.74 to 47.91 million), the largest `desde` (tr_since_phrase/1
  asked of every phrase of a preposition: 0.033 % in tr_cross_comp/2 and 0.029 %
  in tr_cross_comps/2, some 300 inferences a sentence each), a participle's
  phrase 0.017 %, a preposition that is a verb 0.016 %, a name's gender 0.016 %
  and the two fronts 0.012 %, no other over 0.01 %. The notes, measured on a
  copy that prints the inferences each one spends: `$tr_replacer` 1 149 a
  sentence (0.139 % of these 56), `$tr_second_rel` 384 (0.046 %) and
  `$tr_comma_rel` 55, beside the older ones' 4 242 (the agent first, 0.495 %), 1
  153 (a participle after a determiner, 0.140 %) and 1 115 (a coordinator with
  an adjunct, 0.135 %). The arms of a rule written too wide
  (`named-gender-wide`, `participle-predicate-wide`, `animal-person-wide`) are
  no measure of its cost: the clause they leave open reads other sentences or
  refuses them sooner (the first spends 417 thousand inferences less in
  it_9673_9712 17, which is refused both ways).
  THE STATED COSTS: a first meaning that serves the news and not every text --
  `calcio` is Italian football (a Spanish text on calcium is football),
  `vestuario` a changing room, `cantera` a youth academy, `delantera` an attack,
  `trayectoria` a trajectory (the Italian vocabulary has one noun for a path,
  `traiettoria`, so `en el buen camino` is `nella buona traiettoria`), `fracaso`
  a failure, `corbata` a necktie, `tiene que ver` has to do, `appare` appears
  (the four sentences it mends, and `no figuran ni Rivaldo` it does not),
  `valencia` a name, `trata` tries before an infinitive (and `treats` still
  everywhere else); the draw is the tie, so every Spanish noun for a tie but the
  necktie (`lazo`) is `pareggio` in Italian; `desde` and a date is the Italian
  writer's first word for since, `fin da`; the stray-adverb rule drops the
  dictionary's two musical adverbs and nothing else; the 42 and 43 nouns of the
  group are an institution first (`dirección`, `banco`, `junta` and `rosa` have
  other senses, which matter only straight after the verb of a relative clause
  with no `a` and no other doer); `nothing-of-shape` has no arm that goes red
  (the eighth sentence of the article costs 510 783 inferences with it into
  English and 550 827 without, 535 499 and 575 543 into Italian, the text the
  same); the article's second sentence is 20 million inferences, 2.96 with the
  arm `mids-open-skip` (the aside after the word right after the opener is set
  apart first and the unextracted words are the fallback, as `Salvo che lui, a
  differenza di Agostino, era disposto ...` and `Quest'Uomo che una volta, a
  fianco di Marco Pannella, si batteva` need, while `la gestión que ahora, con
  su noveno proyecto, parece ...` reads only in the fallback, after the
  extraction has failed on a long sentence; with no fallback, `mids-open`, it is
  refused); and the doer rule reads a relative clause twice where its shape
  allows both (es_20020301-125 1 rises 19 %). The article LEAVES, of the 14 into
  Italian: `primo luogo` for `primer puesto` (1), `una lunga e dura epoca` for
  `periodo`, `l'olio imprenditore` for the oil man, `porta quasi un decennio
  versando denaro` for `da quasi un decennio versa`, `disporre al club nella
  cosa più alta` (`colocar` is `disporre`, and the lesson has no `ai vertici`),
  `con quelle che trionfò` for `con le quali ha trionfato` (3), `in Milán` (a
  name the lesson has no city for), `ha agito il miracolo` (4), `adesso` last
  (5), `in cinque giorni` for the rounds (6), `nel campo` (7), `ha arrivato`
  (10: the auxiliary of a verb of arriving), `e efficace` (11), `quest'anno
  dell'Atalanta` for `dall'Atalanta` (12) and `altro tempo` for `un'altra volta`
  (13); of the 13 into English: `his proprietary and maximum shareholder` (1:
  `propietario` read as the adjective before the noun it is), `the oil richest
  employer`, `place to the club in the highest thing`, `form her` (12: the
  clitic `la` of a thing is written `her`), `the Turkishes` and `the own Kallon`
  (13), `now` and `today` last (13 and 14), `inter fans` in small letters (10:
  `Inter` is a name, `interista` is not) and `with what they say` (7: the third
  person nobody names, written `they`); the third sentence is refused, on
  purpose, for the null third person of `con las que triunfó`. The next sample's
  controls take this feature in.
  The Rognoni interview (VIT-9605..9636, 32 sentences, Italian into Spanish and
  English: 31 of 32 and 31 of 32 on a fresh store, 26 and 25 with the new store
  alone, 19 and 19 with the new code on the old store, 18 and 17 before;
  reasoning 1.0.12). The sample was taken on the cocolog 2.11.0 binary,
  master's, and cocolog stays 2.11.0. THE BINARIES OF 2.4.0 AND 2.11.0 give the
  same texts on the controls (96 count files, 2 728 sentences: 0 differ) and
  2.11.0 counts 5.896 % more inferences (5 009 219 484 to 5 304 565 743): since
  2.5.0 `atom_concat/3` is a clause over `$atom_concat`, four or five inferences
  a call where it was one, and the translator calls it often; the clock does not
  move (three alternating pairs of one control file, medians 16.99 s on 2.3.0,
  whose texts and counts are 2.4.0's, and 16.55 s on 2.11.0). So no count of
  this sample compares with the Inter's, and the baseline is the committed
  library on KB195 on 2.11.0. The article's sentences fall from 872.7 to 807.5
  million inferences in each language, and 773.1 million of them are its
  nineteenth, refused (below).
  It needed these SHAPES, each with its arm red (test/translate.pl's
  `newspaper_rognoni`: 40 checks, 31 arms, the guards among them; an arm is a
  library directory of symlinks whose reasoning/translate.pl is the edited copy,
  `COCOLOG_LIBRARY=ARM cocolog query "use_module('test/translate.pl'),
  newspaper_rognoni, checks_done"`, two seconds a run, and every arm is run in
  under a minute, three at a time): a name apposed to a name between commas is
  no word of the subject's shape (`Carlo Rognoni, Pds, parla dell'intreccio ...`
  is a man and his party, tr_subject_shape/4, as an aside, a bracket and a dash
  are), and in a reporting clause the apposed name is the speaker's (`Commenta
  Carlo Rognoni, Pds, vicepresidente del senato:` was `Comenta a Carlo Rognoni`,
  tr_reporting/3), and English writes what the speaker is with the speaker,
  before the verb (`Carlo Rognoni, Pds, vice-president of the senate,
  comments:`, where it was `Carlo Rognoni comments, vice-president of the
  senate`, tr_write/4 -- the controls' `Claude Lebet, one of the most
  acknowledged luthiers, said` and `Filippo Graziani, dean of the school ...,
  underlines` with it); `among` before a pair of phrases joined by `and` is
  `between` (`l'intreccio tra le nuove regole e le trattative`, tr_comp_out/7;
  among three it stays `among`, a guard); `more than` and `less than` before a
  count (`di cui nessuno abbia più di una rete` is more than one network -- read
  as the adverb and a phrase of `of`, English wrote `has of a net more`, and
  denied `anymore`: the lesson states `più di` and `meno di` as one adverb, as
  Spanish's `más de`, and where the second word is also the lesson's word for
  `than`, Italian's `di`, the reader takes the pair apart again unless a number,
  an indefinite article or an article and a number follows, tr_than_split/3, a
  guard `mangia più di me`; and `more than` before `a` is before `one`,
  tr_comps_out/7 -- three arms); `very` before a comparative is `much` (`Molto
  meglio, pensare con intelligenza al futuro` is much better, `basta assai meno
  del 50,1%` much less than it, `molto più grande` much bigger: tr_much_before/3
  in the crossing of an intensified adverb and of an intensified comparative,
  which the crossing folds into the adjective, and the English writer puts `much
  less than` before the object it says how much of -- three arms, and the guard
  `molto grande` is very big); `makes` with nothing made is `does` (`chi compra
  ... lo fa a suo rischio` does it, `Che dovrebbe fare Berlusconi?` what should
  he do, `non fa niente` does nothing: the lesson's `fa` and `hace` mean makes,
  and English says that only of a thing made -- an object, an infinitive, a
  predicate -- tr_makes_does/3, with `lo` as `it` there, and its past and
  participle are `did` and `done`, en_past_of/2 and en_participle_of/2: the
  controls' first round wrote `they have doed it` -- four arms, two guards); an
  adverb between a question's verb and its subject stays where it is (`Che
  dovrebbe fare, allora, Berlusconi?` -- nothing agreed after the verb,
  Berlusconi was the object and the subject a third person nobody named, `¿Qué
  debería hacer entonces a Berlusconi?`, and refused in English:
  fo_adverb_subject/5, asked only by fo_unfront/3, the question's reader -- in
  fo_subject_after/5, which the statements' readers ask too, it changed four
  inverted statements of the controls, below); no phrase with its phrases of
  `of` before `there is` is what there is (`Dopo la sentenza della corte c'è
  stato il referendum` was `The judgment of the court thered is the referendum
  after`, tr_read_generic/4's guard, with/2 as np/5); a preposition before an
  article and a phrase that runs to a comma governs it and is not lifted as an
  adverb (`Secondo la corte, è necessario un vero pluralismo` -- `secondo` is
  also the adverb `second`, and lifted it left the court for the subject and the
  copula's own subject an object, `The court, is necessary a true pluralism
  second`: tr_governs_adverb/3, and the reader that lifts the adverbs of a piece
  with its commas taken out asks it of the head word with the commas, two arms);
  an infinitive after the copula and its adjective is written after them in
  English, with `it` before (`è necessario evitare che ...` was `To avoid that
  ... is necessary`, tr_write/4, where the source had the subject after the
  copula: `Mangiare il pane è facile` keeps its order, a guard); `insofar as`
  and `unless` are English connectors (en_connector/1), and the denial before
  the first verb of a clause of `unless` denies nothing (`a meno che non si
  liberi` is unless he frees himself, Italian's expletive `non`:
  tr_expletive_off/3 in tr_joined_words/3 -- three arms); a verb the lesson's
  language governs with a preposition takes its phrase bare in English where the
  English verb does (`incidere sulle scelte` is influencing the choices,
  en_bare_object/1); `whether` and an infinitive (`dovrà scegliere se fare
  l'uomo di governo o mantenere il controllo delle sue tv` is choose whether to
  be ... or to keep, and with no clause after `se` there was no question:
  whinf/1, read after a verb that takes the question and after the bare
  infinitive of one, `"sceglie" takes the question.`, and written with `to`
  under a modal, whose infinitive English writes bare -- three arms); a day or
  an adverb alone between a participle and its agent (`il disegno ... varato
  giovedì dal senato` was `desde el senado`, tr_reduced_agent/3); two
  prepositions joined before one phrase (`leggere tutto pro o contro
  Berlusconi`, `con o senza il gatto`: pp2/4, read, crossed and written, the
  first a word the lesson gives an English preposition for -- `colocados cerca o
  dentro de un vehículo` has `cerca`, a wall as a noun, and the controls' first
  round wrote `placed wall or within`; two arms); the word that begins the
  relative and its clause have a subject's shape (`Chi dorme mangia` was
  refused: with no noun in the clause, `chi dorme bene` read only because `bene`
  is a noun, tr_subject_shape/4); and a denial after a relative clause inside a
  clause of `that` is that clause's (`prevede che chi ha partecipazioni ... non
  possa essere membro del governo` -- the relative clause's verb was counted as
  the clause's, the denial went to `prevede`, and the sentence was refused:
  tr_negation/4 and tr_relative_opener/1; a guard, `Il cane che mangia non
  dorme`).
  It needed these WORDS in `extra/` (the two readers: a line moves the reader of
  one language and the writer of the other; the dictionary's own word is said
  again first where it must stay the one written): Italian `intreccio` (an
  interweaving, Spanish `entramado`), `holding` (the holding company, feminine,
  as Spanish's masculine `holding`), `vicepresidente` (a person), `oligopolio`,
  `pro` (in favour of, a preposition, with `a favore di` said first and Spanish
  `a favor de`), `cassa` (quashes, with its forms -- the dictionary has the noun
  only -- and Spanish `anula`, its plain `cancels` said first), `cordata` (a
  consortium, `consorzio` said first), `votante` (a voter, a person), `quota
  azionaria` (a shareholding, Spanish `participación accionarial`), `incide`
  (influences, `su` before the phrase, `influenza` said first), `management`,
  `tivù` (`televisione` said first), `cerca` before an infinitive (tries,
  `tenta` said first as the word written for it and its plain `searches` first),
  `provvedimento` (a measure, `misura` said first), `via etere` (terrestrial, an
  adjective of two words), `sulla base di` (on the basis of, Spanish `sobre la
  base de`), `nella misura in cui` (insofar as, Spanish `en la medida en que`),
  `elegge` (elects, where the dictionary's first was chooses, `sceglie` said
  first), `potere` (power, where the dictionary's first was a fortress -- the
  Tatarella interview's `poteri forti` were `fortalezas fuertes`), `disegno` (a
  drawing before the dictionary's cartoonist, a person: `il disegno sul
  conflitto d'interessi` was `el dibujante`), `interlocutore` and Spanish
  `interlocutor` (an interlocutor, where both dictionaries have a speaker),
  `rete` (a network first, the net after it: the controls' `rete 4`, `la rete
  commerciale`), `prende di mira` (targets), `ha in mano` (holds), `si tiene`
  (keeps, `mantiene` said first), `sbagliato` (wrong, an adjective; the
  dictionary has the participle only), `a suo rischio` (at his own risk, Spanish
  `a su riesgo`), `più di` and `meno di` (more than, less than, one adverb, as
  Spanish's `más de`; Spanish `menos de`), `a meno che` (unless, Spanish `a
  menos que`), and `"sceglie" takes the question.` (Spanish `elige` and
  `escoge`); and Spanish `tiene` (holds, its plain `has` said first: the
  writer's first Spanish verb for it was `aguanta`, endures) and `sujeto` (a
  subject, said again first: the writer's first Spanish noun for it was `tema`,
  a topic). The first meaning moved in 6 Italian words and 1 Spanish one
  (Italian `disegno` a drawing, `interlocutore` an interlocutor, `potere` power,
  `provvedimento` a measure, `rete` a network, `elegge` elects; Spanish
  `interlocutor`), and none was lost.
  THE CONTROLS (cocolog 2.11.0, store KB201, 98 count files, 2 756 sentences:
  the earlier set with the Inter feature in, es_20011002-160, both directions;
  this interview is not among them): the last version's translator against this
  one, on the one store, 38 sentences in 19 files read differently, all better
  -- `between` for a pair (21: `the fusion between Carrefour and Promodès`,
  `between Meridiana and Aragó`, `between the three and the five of the
  afternoon`, `asymmetries between accusation and defence`), the speaker's
  apposition with the speaker (5: es_20010202-169 12, `Claude Lebet, one of the
  most acknowledged luthiers, said`; es_20020601-51 14, a piece of a sentence
  refused, `Roger Lemerre, the French technician, said`; it_9851_9925 2,
  it_9926_9946 16, it_9947_9966 14), `does it` and `did it` for `makes him` (5:
  es_19990802-48 9, `they have done it`; it_10059_10095 7 and 8, `I do it
  voluntarily`; it_9967_9998 25; tat 283), `It is not possible to make a
  replica` (es_20010202-169 11) and `it was crazy to attempt` (it_9967_9998 28),
  `whether it is legitimate to write` (it_9775_9780 1), the agents of
  it_9637_9672 8 (`presided by Pierre Carniti and presented by the minister`, in
  both languages; English writes the sentence `The dramatic picture ... is
  this.`, where the last version wrote `It is this the dramatic picture ...`),
  and it_9637_9672 7, refused before and read now in both languages (`menos de
  la mitad de lo que gasta`) -- and the inferences rise 0.050 % (5 403 216 416
  to 5 405 933 404). The sentences that rise most are it_9567_9604 20 (+0.78
  million of 6.26 in each language), it_9851_9925 32 (+0.14 of 38.2),
  it_9673_9712 20 (the one that runs to the limit, +0.07 of 516.7), it_9472_9484
  10 and it_9270_9295 9 (+0.06 each); the ones that fall most are it_9637_9672 7
  (8.67 million to 6.26, read) and 8 (1.70 to 0.55). Bytes and characters read
  every sentence alike (0 differ, the bytes 0.018 % more). The DATA COLUMN (the
  last version's translator on its own store, KB195, against this one on the
  new): 59 sentences in 26 files, the 38 of the code and those of the words, and
  the inferences rise 0.096 % (5 400 766 799 to 5 405 933 404). THE CODE ALONE
  (this translator on the old store): 36 sentences in 19 files, +0.112 %. THE
  STORE ALONE (the last version's translator on the old store and on the new)
  differs in 25 sentences in 12 files, +0.045 % of the inferences, each a word
  of the interview's lines, all better but one: `potere` is power (it_9714_9749
  18 and 21, `the strong powers`, `los poderes fuertes`, where they were
  fortresses), `rete` a network (it_9270_9295 11 and 26), `provvedimento` a
  measure (it_9750_9762 10, `ninguna otra medida`), `cerca di` tries
  (it_9673_9712 13, it_9781_9791 5, it_9511_9539 4: `has tried to close the
  games`), `più di` more than before a count (it_9637_9672 13 and 17, `more than
  65 years`; es_19990901-75 17 has Spanish's `menos de`), `a favor de` in favour
  of (es_19991001-61 20), Italian `teneva` and `tenere` as `tenía` and `tener`
  where they were `aguantaba` and `aguantar` (it_9851_9925 55 and 65,
  it_9947_9966 6 and 20) -- and it_9637_9672 7, refused with the old code: the
  line joins `meno di` and only the new code takes it apart before `la metà`.
  THE FIRST ROUND'S REGRESSIONS, found by reading the texts of every column and
  mended. Of the store alone (42 sentences): four of the interview's lines came
  first for the writer of the other language -- `si tiene` (keeps) made every
  Spanish `mantener` the Italian `tenersi` (`mantener a Reina` was `tenersi
  Reina`, `la posición que mantiene` `che si tiene`) and three sentences of the
  controls were refused (es_19990601-23 1, es_20000802-31 4, es_20010103-139 7),
  `pro` was the Italian for `a favor de` (`si votò pro la proposta`), `tivù` for
  `televisión` and `cerca di` for `trata de` (`non cerca di convincere`, where
  it was `tenta di`) -- and the dictionary's own word is said again first for
  each: `mantiene`, `a favore di`, `televisione`, `tenta`; a line for `soggetto`
  as an entity was taken out, because an earlier sample's line says it is a
  subject first (the people of `molto attento verso i soggetti`), and `sujeto`
  is the Spanish writer's word for a subject now. Of the code (49 sentences):
  the question's adverb before its subject, first written in fo_subject_after/5,
  changed four inverted statements its other readers read with it -- `Fue
  entonces el momento de homenajear a dos personajes ...` was `The moment went
  moment of honouring` (es_19990701-83 7, both languages), `si chiama infatti
  assistente ai bagnanti` (`se llama ayudante a ayudante`, it_9381_9414 11),
  `deve finire in tribunale l'arcivescovo di Monreale` (`the archbishop must
  finish of Monreale ... in court`, it_9465_9470 3), `Godranno ... soltanto
  quelli che hanno scelto` (`Those will enjoy ... only that they have chosen`,
  it_9472_9484 9) -- and it stands in fo_unfront/3 now, the question's reader,
  where the comma form of it went (a question is read with its commas out, and
  its arm was green); `does` had no past and no participle of its own, `they
  have doed it`; and the pair of prepositions took `cerca` for one, `placed wall
  or within a vehicle` (es_20010102-25 6). A clause for `whether` after an
  infinitive that takes the question (tr_complements_after_inf/5) had no arm
  that went red, nor changed a sentence, and is gone.
  THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT (the nine sentences that
  rose most on the one store, into English, over a copy of the library per rule
  on KB201): they rose 1.25 million inferences, and three rules are 90 % of it
  -- the taking apart of `più di` (0.77 million, 0.75 of it in it_9567_9604 20,
  `Casotto, che ora giura che non si occuperà mai più di boxe, sostiene una
  teoria ...`: 7.01 million inferences on the old store, 6.26 with the new line,
  which joins `più di`, and 7.04 now, the two words read as they were before the
  line -- +0.4 % against the old cost, and refused all the way), a denial after
  a relative clause inside a clause of `that` (0.23 million: it_9851_9925 32
  +0.12 of 38.2, it_9472_9484 10 and it_9673_9712 10 +0.05 each, where the
  denial stays with the clause and more readings are tried) and `whether` and an
  infinitive (0.16 million, a few thousand a sentence, asked at every word for
  `if` after a verb that takes the question); the rest is under 0.02 million
  each (`unless`'s expletive 18 thousand, a day before the agent 13 thousand).
  THE STATED COSTS: a first meaning that serves the news and not every text --
  `rete` is a network (a football report's goal is a net second), `disegno` a
  drawing (the bill is `disegno di legge`, and a bare `disegno` for it is still
  `dibujo`), `potere` power, `provvedimento` a measure, `elegge` elects,
  `interlocutore` an interlocutor, Spanish `tiene` the writer's word for holds
  (`teneva` is `tenía`, and `si terrà un'iniziativa` is `se tendrá`); the
  inferences, +0.050 % on the one store; and the nineteenth sentence, refused
  after 773.1 million inferences in each language as it was (`bisognerà
  impegnarsi per una legge che disciplini il mondo ... tenendo conto sia della
  corte costituzionale, sia dell'esito dei referendum sia infine delle reali
  condizioni del mercato, ..., figuriamoci se potrà farlo per 15.`): `tenere
  conto di` is no word of the lesson, `sia ... sia ... sia infine` is three, and
  `figuriamoci se` is an idiom; a line for `tiene conto di` read `tenendo conto
  del gatto` and left the sentence refused, so it is not in -- the next sample's
  controls carry its 1.5 billion inferences. The interview LEAVES, of the 31
  into Spanish (English alike unless it says): `rapporto` is a report, never the
  relationship between two things (3); `Nei giorni "caldi" delle trattative` is
  `"Calienten" de las negociaciones ... en los días` (4: an adjective in
  quotation marks after its noun is read as a verb); `il disegno sul conflitto
  ... varato giovedì dal senato` after the verb is `el dibujo en el conflicto
  ... desde el senado` (5: with the subject after the verb the agent is not
  read); `grande esperto di media` is `gran experto de media` and `big expert of
  average` (6), and `definire delle regole` keeps the partitive (`definir de las
  reglas`); `com'è naturale` stands last and `chi ha in mano` is `de quién
  tiene` (7); `Sarebbe sbagliato leggere` is `To read ... would be erred` in
  English (8: the participle is read before the adjective); `pensare ... al
  futuro` is `pensar al futuro` and `think to the future` (9), and `valori
  democratici` `valores demócratas`; 10 (`Generali per quanto siano, le regole
  investono adesso proprio le tv Fininvest`) is word by word, `Generales para
  cuanto son ... invierten ... propias`; `ci siano, nelle mani di un unico
  soggetto, tre reti` is `hay` and `they there is` (13); `un vero pluralismo` is
  `un cierto pluralismo` (15); `tanti soggetti` is `so much subjects` (16); `c'è
  stato` is `había` (17); 20 moves `come suggerisce il "progetto Bogi"` to the
  end in English; `lo fa a suo rischio` puts `at his own risk` last (22); `lo
  risolverebbe` is `resolve him` (24, the clitic of a thing); `resta azionista`
  is `queda a accionista` and `influencing on the choices` (26: the infinitive
  is a noun's complement there, and the governing verb is not found);
  `continuare a controllare` is `continuar a controlar` (27) and `una società` a
  society; `¿Qué debería Berlusconi hacer entonces?` (28) and `hacer al hombre
  de gobierno` (29); `entro un anno` is `I enter a year` in English and `entro
  un año` in Spanish (30: in the long sentence `entro` is read as the verb,
  where `si liberi entro un anno` alone reads it as the preposition), and `si
  liberi` is the impersonal `one releases`; `eletto` is `elegida` and
  `segretario di partito` `secretario de fiesta` (31: the Spanish writer's first
  noun for a party is a fiesta, and `partido` is a match first); and
  `l'Antitrust proyecto de ley`, `iniciadas desde el presidente` (32: the agent
  after a coordinated object is not read). The next sample's controls take this
  interview in.
  The Rognoni interview's faults (reasoning 1.0.13; cocolog stays 2.11.0; no new
  article). Four faults the interview left, fixed in code and data, each with
  its arm red (test/translate.pl's `rognoni_faults`: 14 checks, 7 arms that go
  red and 3 rules that have none, below; lesson 46's section 76): A NOUN THAT
  CAN SAY A RELATION SAYS ONE BEFORE `between` OR `with` (`Milano - rapporto
  difficile, tra Berlusconi e le regole` was `difficult report`, `informe
  difícil`: a noun whose first meaning is no relation and that has
  `relationship` or `relation` among its other meanings, en_relational_noun/1,
  crosses by it before a phrase of `among`, `between` or `with`,
  tr_relational_np/3 -- in the complements, tr_cross_comps/2, in a phrase with
  its phrases, with/2, a subject's too, and in a headline's two halves,
  tr_cross/3's gap/2: four arms, and the first meaning's own guard has none; `Il
  rapporto della commissione` is the report still); A PREPOSITION IS NEVER
  ELIDED BEFORE A DEFINITE ARTICLE (`sin el gato` was `senz'il gatto`: `"senz'"
  is the elision of "senza".` in the vocabulary, and a preposition elides before
  any article, `d'un buon stradivari`, which stays; tr_opens_next/2); A MAIN
  CLAUSE NEVER STARTS AT A WORD THAT IS A PREPOSITION TOO (sentence 30's `e a
  meno che non si liberi entro un anno` took `entro`, I enter, for the main
  clause after the clause of `unless` with no comma, `I enter a year` and `entro
  un año`: tr_main_start/2, which both readers of that shape ask, the sentence's
  and a nested clause's), and the right side of a coordinator inside a clause
  may be a subordinate clause alone (tr_nested_right/3: with no main clause
  after it the clause of `unless` had no reading inside the clause of `that`,
  and the sentence was read again from the top, 11.0 million inferences where it
  is 3.5 -- the rule has no arm that goes red and stays for that cost, as the
  text is the same; its guard, a word that asks as well, `perché`, was found by
  the controls: `può essere che Margherita abbia avuto un malore ma perché
  nessuno le ha viste?` became `can it be ... but because nobody has seen her?`,
  it_9851_9925 56, and no hand lesson reproduces it, so the guard stays for what
  the controls showed); English elides no subject of a subordinate clause
  standing alone after `and` (`and unless eats`: tr_write/4's elision, and
  English refuses the third person nobody names, on purpose); and THE PARTY'S
  WORD, data: the Spanish writer's first noun for a party was `fiesta` (`hacer
  política como secretario de fiesta`, 31) -- `"partido" means "match".` said
  again first, so that it stays a match to the reader, and `"partido" means
  "party".` after it, so that it is the party's word (Italian news has `partito`
  115 times in UD's VIT training file and `festa` 22, and every `festa` is a
  `partido` now, a STATED COST; the Spanish reader still reads `el secretario
  del partido` as `della partita`, `partido` being a match in half of AnCora's
  sentences and a party in the other half, a lead). Two lines more: the writer's
  first Spanish verb for releases was the idiom `deja marchar` (`a menos que se
  deja marchar`, and the Rosi report's `non era al corrente che liberasse
  amfetamine` was `dejó marchar`), and `"libera" means "frees".` and `...
  "releases".` are said first; and `"a menos que" takes the subjunctive.` and
  `"a meno che" takes the subjunctive.`, as the lessons say of `antes de que`
  and `prima che`, so that the clause is read and written in the subjunctive (`a
  menos que se libere`). The vocabularies lost no line and moved no word's first
  meaning; the writer's first Spanish word moved for two meanings (party,
  releases). THE CONTROLS (cocolog 2.11.0, store KB203, 100 count files, 2 820
  sentences: the earlier set with the Rognoni interview in, it_9605_9636): the
  last version's translator against this one, on the one store, 4 sentences read
  differently, all the interview's and all better -- the headline's
  `relationship` and `relación` (3), sentence 30's `before a year` and `a menos
  que se libere antes de un año` (where it was `I enter` and `entro un año`) --
  and the inferences rise 0.016 % (7 020 760 360 to 7 021 882 676), 0.006 %
  outside the interview (5 406 061 909 to 5 406 388 556): sentence 30 is 3.14
  million inferences and 3.54 now, in each language, the rest of the rises under
  2 500 a sentence. Bytes and characters read every sentence alike (0 differ,
  the bytes 0.014 % more). THE STORE ALONE (the last version's translator on
  KB201 and on KB203) differs in 3 sentences, all better, +0.0004 %: `secretario
  de partido` (it_9605_9636 31), `a menos que se lib...` (30) and the Rosi
  report's `liberaba anfetaminas` (it_9567_9604 25); THE CODE ALONE (this
  translator on KB201) in the 4 of the controls, +0.016 %; THE DATA COLUMN in 6,
  +0.016 %. The interview reads 31 of 32 into both, as it did; its nineteenth
  sentence is still refused after 773.1 million inferences in each. What is left
  of sentence 30: `si liberi` is the impersonal `one releases` in English,
  `dall'assunzione della carica` is `from the intake of the charge` and `de la
  ingesta del cargo`, and `eletto` is still `elegida` in 31.
  The banks' Saturdays report (AnCora CESS-CAST-P-19990601-98, 12 sentences,
  Spanish into Italian and English: 12 of 12 and 11 of 12 on a fresh store, 11
  and 10 with the new store alone, 9 and 9 with the new code on the old store, 9
  and 9 before; reasoning 1.0.14). The sample was taken on the cocolog 2.11.1
  binary, master's 870bcb9 merged as 3e3e83a, and cocolog stays 2.11.1: the
  binaries of 2.11.0 and 2.11.1 give the same texts and counts to the unit on
  the controls (7 021 882 676 inferences, 0 differ). Master's 2.11.2 (dd53f69,
  Cicili 3.1.0's `(cold)`) came during the sample; it needs Cicili 3.1.0, the
  checkout here is 3.0.0 and cicili is frozen, so it is not merged, and the next
  sample takes it. The article's sentences fall from 26.0 to 15.0 million
  inferences into Italian and from 25.5 to 14.5 into English.
  It needed these SHAPES, each with its arm red (test/translate.pl's
  `newspaper_bank`: 30 checks, 33 arms, the guards among them, and two arms more
  that are red in the whole case alone, below; an arm is a library directory of
  symlinks whose reasoning/translate.pl is the edited copy, `COCOLOG_LIBRARY=ARM
  cocolog query "use_module('test/translate.pl'), newspaper_bank, checks_done"`,
  three seconds a run): a verb with its own pronoun crosses by the meaning the
  lesson gives it so (`la apertura se ha convertido en el elemento negociador`
  has BECOME it, and it was `has converted in`: `The reflexive verb "convierte"
  means "becomes".`, the class linked in tr_mean_links/3 as the infinitival and
  adjectival ones are, tr_verb_across/5), and the phrase it governs is that
  meaning's (tr_cross/3's `$tr_gov_sense`), which English writes bare
  (en_bare_object/1) and Italian with no preposition where the verb written
  states none (`è diventata un problema`, tr_comp_out/7) -- five arms;
  `converts` governs `into` and `centres` `on` (en_governs/2); a comparison
  whose second term is an adverb (`en las mismas condiciones que en la
  actualidad` is in the same conditions as currently: `en la actualidad` is one
  adverb, and with no preposition after `que` the comparison had no reading,
  tr_complements0/4 and cmpp/3 with adv/1, two arms); a participle and its
  phrase right after the verb say how the verb leaves the phrase (`que mantiene
  bloqueado el convenio colectivo del sector bancario` keeps the collective
  agreement OF THE BANKING SECTOR blocked, `una estatua tiene levantado el brazo
  izquierdo` has the left arm raised: tr_abs_first/2 makes the clause's first
  absolute clause abso/2, which English writes phrase first, its phrases of `of`
  with it, tr_of_run/3 -- three arms, and two guards: the first complement only,
  or `dopo aver mandato in onda l'ultimo punto` is `after having the last dot
  broadcasted`, and never a participle English puts before a phrase as a
  preposition, en_prepositional_participle/1, `given`, `seen`); a day of the
  week alone is `on` it (`los sábados`, tr_comp_out/7's at_time/1); `the
  employers` take the plural verb (en_collective_plural/1); an intransitive verb
  has its subject after it in a relative clause (`la hora y media que duró el
  encuentro` is the hour and a half the meeting lasted, tr_rel_doer/2, `"dura"
  is intransitive.`), never after `lo que`, the subject itself (`lo que ocurrirá
  esa fecha`, a guard the controls found); an aside between dashes that ends the
  sentence may follow an adverb (`por las tardes - - iniciativa que consiguió
  pactar con la dirección - -`, tr_asides/3); `attains` before an infinitive is
  `manages` (`consiguió pactar`, `riesce a giocare`, tr_verb_out/4); `al que`
  after an adjective that takes the word for `to` is the adjective's phrase (`un
  horario similar al que desarrollan las cajas de ahorros` is similar to the one
  the savings banks keep, tr_np/3 with ell/4, and a guard, `la casa a la que va
  el perro`); the adverbs English writes last stay inside a quotation that
  closes on the last complement (tr_close_after_advs/3); the adjectives the
  source put after its noun are written the other way round in English (`la
  patronal bancaria española` is the Spanish banking employers, en_adj_order/3:
  a degree and an adjective the source put before its noun come first, as they
  stood, `un mejor trato fiscal`, `un nuevo acuerdo laboral colectivo`, and a
  list with a name, a coordinator, a quoted word, a noun that says what kind or
  an adjective that keeps a number of its own keeps its order -- three arms, the
  guards the controls found), and the lesson's language writes the plain
  adjectives an ENGLISH source put before its noun the other way round, so that
  a round trip comes back as it went (`the big red house` is `la casa roja
  grande`, which is the big red house again, where `la casa grande roja` was the
  red big house: tr_foreign_adj_order/3, an arm red in the whole case) -- asked
  of the side the text was READ on, `$tr_read_side`, because every writer finds
  `$tr_from` set to english, and asked of that the first cut turned 25 sentences
  of the controls round between Spanish and Italian (`la televisione catalana
  pubblica`, `la terapia psiquiátrica médica`); an object after the phrase of a
  preposition, last in its clause, comes before it (`que denunció ante la
  Audiencia Nacional este acuerdo`, tr_comps_out/7: a phrase or a name after the
  preposition, never `of`, and an object with a determiner or a count -- four
  arms, three of them the guards the controls found, and a fifth red in the
  whole case: never after the phrase of `to` of a verb English writes with a
  bare dative, or the basketball report's rule, `costs the dog a book`, wrote
  `costs a book to the dog`); a unit of time after a time is how often (`una
  tarde a la semana` is an afternoon a week); and an adverb between commas right
  after an apposition is an insertion (`El portavoz demócrata, John Conyers, por
  su parte, criticó`: the apposition took the comma that opens it, and `por su
  parte`, one adverb now, went to the end of the clause, tr_insertion_off/4 --
  found in the store-alone column). A guard for a linking verb's auxiliary
  (en_linking_verb/1) had a green arm and changed no text and no count on the
  store, and was taken out.
  It needed these WORDS in `extra/`: Spanish `convierte` (converts, and becomes
  with its pronoun; `en` before the phrase), `negociador` (negotiating),
  `sucursal` (a branch office), `sindicato` (a trade union), `caja de ahorros`
  (a savings bank, a group), `flexibiliza`, `pacta` (agrees), `no obstante`
  (nevertheless), `por su parte` (for its part), `así` (thus), `cuenta con`
  (has, with its forms), `denuncia` (denounces), the name `Audiencia Nacional`,
  `centra` taking `en`, `dura` (intransitive), `de forma que` (so that, with the
  subjunctive), `por las tardes`, `por las mañanas`, `por las noches`, `mesa de
  negociación` (a negotiating table) and `consigue` (achieves, and attains
  before an infinitive); Italian `negoziale`, `negoziatore` and `negoziatrice`,
  `filiale` (a subsidiary said again first, then a branch office), `sindacato`,
  `cassa di risparmio`, `flessibilizza`, `da parte sua`, `centra` taking `su`,
  `in modo che` and `senza che` with the subjunctive, `di pomeriggio`, `di
  mattina` and `tavolo delle trattative`. The first meaning moved for 4 Spanish
  words and 1 Italian one (Spanish `así` thus, `sindicato` a trade union,
  `sucursal` a branch office, `denuncia` denounces; Italian `sindacato`), the
  writer's first word for no meaning, and none was lost.
  THE CONTROLS (cocolog 2.11.1, store KB206, 100 count files, 2 820 sentences:
  the earlier set with the Rognoni interview in, both directions; this report is
  not among them): the last version's translator against this one, on the one
  store, 55 sentences in 37 files read differently, 47 better and 8 no worse --
  the English adjective order (29, 22 better: `the Catalan public television`,
  `the free juridical assistance`, `the already existent pedestrian zone`, `the
  Basque socialist leader`, `the German financial institution`, `the European
  Space Agency`, `the American daily newspaper`, `the French nuclear
  experiments`, `a frightful public debt`, `the richest oil employer`), `on`
  before a day (7: `begins on Thursday`, `celebrated on Monday at night`, `On
  Tuesday everyone around the table`), the object before a phrase (7, 6 better:
  `will watch this operation "with special attention"`, `has demanded the
  maximum concentration from the players`, `would have accepted the defensive
  line in full`), the adverbs inside their marks (2), `manages to` (4), `has the
  left arm raised`, `convert into`, `will become a ballast` and `diventeranno
  una zavorra`, and `John Conyers, for its part, criticised` in both languages
  -- and the inferences rise 0.002 % (7 022 280 308 to 7 022 430 135). No worse,
  and no better (8): a participle with its phrase reversed with the adjectives
  (`the realised murderous crimes against`, `a priced economic value in`, `an
  addrest symbolic initiative to`, `the proprietary French groups of Pryca`),
  `the norman Arab cathedral`, `the psychiatric medical therapy`, `the medicine
  jurisprudence university didactic improvement`, and tat 350, `You should give
  him your son more freedom` (`more freedom your son`). Bytes and characters
  read every sentence alike (0 differ, the bytes 0.014 % more). The DATA COLUMN
  (the last version's translator on its own store, KB203, against this one on
  the new): 84 sentences in 54 files, +0.008 % (7 021 882 676 to 7 022 430 135).
  THE CODE ALONE (this translator on KB203): 50 sentences in 34 files, +0.037 %
  (to 7 024 469 047), every one of them among the 55; the five left need the new
  lines (`por su parte`, `convierte`). THE STORE ALONE (the last version's
  translator on KB203 and on KB206): 31 sentences in 23 files, +0.006 % (to 7
  022 280 308) -- the subjunctive after `para que` and `sin que` (`acceleri`,
  `possa`, `causi`, `noti`, `apparissero`), `thus` for `así` where it was
  `thereby`, `While the jobs last`, `the trade union of the togas`, `has 3,000
  subscribers` and `will have bonuses` (es_20000701-80 18, read into English
  now), the Spanish writer's `conseguir` for Italian's `riuscire` where it was
  `lograr` (8, no better and no worse), and two worse: `por su parte` after an
  apposition went to the end of its clause (es_19981202-34 9, both languages:
  the shape above mends it) and `pueden contar con su colaboración` is `they can
  have their collaboration` and `possono avere` (es_19991001-61 17, a stated
  cost).
  Seven expectations of the older sections of test/translate.pl and two of
  lesson 46 were written in the old English or the old order and changed with
  the rules (`on Saturday` in both files, `bought on Sunday`, `that on Sunday
  eats`, `On Tuesday the summit.` in both files, `put the house in danger`, and
  the round trip's `la casa roja grande`, twice).
  THE FIRST CUTS' REGRESSIONS, found by reading the texts of the controls and
  mended: the object before a phrase took the phrase of `of` (`Roma of Corrado
  Sannucci`, five bylines; `to hold the pools of eye`; `for the leader an
  important stage of the olive`), a bare number (`I will not go 4 to the Tg`,
  three) and a bare noun (`without more company`, `knew how to face serenity
  with more`) and an adverb after the preposition (`be able to know little time
  in so`); the adjectives reversed with a degree (`a fiscal better treatment`,
  `his liceistic best nights`) and with a noun that says what kind (`the
  magistrate national association`); the absolute clause written phrase first
  anywhere (`advances the choices in Euskadi the situation of minority of his
  Executive given`, `the very critical opinion seen`, `after having the last dot
  broadcasted`); and the intransitive doer after `lo que` (`what that date will
  occur`). THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT (the seven
  heaviest rises of the controls, into English, over a copy of the library per
  rule): the first cut was +0.693 % of the controls, and one rule was all of it
  -- the clause of tr_np/3 for `al que` after an adjective, whose search for a
  preposition, an article and a relative word walked every phrase it was asked
  and parsed the words before them as a phrase (the seven 52.98 million
  inferences to 60.41; without the clause 52.99). A note made once a sentence,
  `$tr_adj_rel` (an adjective, a preposition, an article and a relative word,
  tr_adj_rel_note/1), and the adjective's test before the parse leave the seven
  at 53.01 million (+0.04 %), the note itself and the clause in the one sentence
  that has the pattern (`con el grupo social al que pertenece`: 1.20 million to
  1.21) and the comparison with an adverb most of it (10 thousand). The second
  cut was +0.027 %, and nearly half of it one sentence that the seven did not
  hold, found by the same arms over it: es_20000903-30 18 rose 0.88 million
  inferences of 85 in each language, the comparison with an adverb read in a
  piece cut after `que jamás` (`el instrumento más amplio de convivencia que
  jamás han tenido los vascos`), a reading the long search then gives up, the
  text the same. An adverb that a verb follows in the piece is no term now (a
  guard with no arm that goes red, which stays for its cost; a guard on the
  words after the adverb in the cut piece moved nothing, as there were none),
  and the sentence is +0.011 %. What is left is +0.002 % on the new store and
  +0.037 % on the old: every sentence rises, by 12 inferences at least and by 36
  thousand at most (it_9605_9636 19, a refusal of 773 million), 2.58 million in
  all, and on the new store es_19981202-34 9 falls 1.21 and 1.22 million in the
  two languages (`por su parte` read at once).
  THE STATED COSTS: `contar con` is `has` (the newspaper's sense: `cuenta con
  3.000 abonados`, `cuenta con la oposición de la UGT`), so where it relies on
  someone it is `can have their collaboration`, and English refuses
  es_20000102-120 6, which it read as the imperative `count on` (now the third
  person nobody names); `for its part` for a person too; the Spanish writer's
  `conseguir` for attains; and the inferences, +0.002 % on the new store and
  +0.037 % on the old.
  The report LEAVES, of the 12 into Italian: `i sabati` (il sabato),
  `mantennero` (tennero), `il beneficio del servizio` (la prestazione), `auspica
  per la situazione` and `che attualmente`, `la sua volontà a flessibilizzare`
  (di), `in España`, `Eppure` (Tuttavia), `un prossimo appuntamento ... per l'8
  giugno prossimo`, `risposta positiva alcuno` (an adjective after its noun with
  `alguna` does not agree), `fino al momento` and `dall'inizio delle trattative`
  written after the purpose; of the 11 into English: `Thus one checked in the
  meeting ... yesterday` (the impersonal `se`, and `ayer` last), `the editorial
  of a new labour agreement` (the drafting), `the closure of the Saturdays`,
  `the benefit of the service`, `for the banking`, `realising their managements
  ... Saturday morning`, `advocate for the situation`, `like alternative to
  close`, `the instauration`, `the one that develop the savings banks` (the doer
  after a relative clause with a comma before it), `his willingness` (CCOO's),
  `the labour schedule`, `initiative that managed to agree` (the relative word
  is the infinitive's object), `in front of the Audiencia Nacional`, `The
  managers of banking` and `have summoned a next appointment`; English refuses
  12 for the third person nobody names, on purpose. The next sample's controls
  take this report in.
  The Venice canals report (VIT-9999..10010, 12 sentences, Italian into Spanish
  and English: 12 of 12 and 12 of 12 on a fresh store, 12 and 12 with the new
  store alone, 3 and 3 with the new code on the old store, 3 and 3 before;
  reasoning 1.0.15). The sample was taken on the cocolog 2.11.2 binary, master's
  dd53f69 merged as d67fb41 with Cicili pulled to 3.1.0 (cc24ae0), which its
  `(cold)` needs, and cocolog stays 2.11.2: the binaries of 2.11.1 and 2.11.2
  give the same texts and counts to the unit on the controls (7 022 430 135
  inferences, 0 differ); master's next two commits, documentation only (97445a2,
  STATUS.md; 6f1f18d, bench/README.md), were merged as 7498830 and c989b20. The
  new store alone reads every sentence -- its words were all that refused them
  -- and with the old code writes 10 of the English texts and 7 of the Spanish
  wrong in the ways the shapes below mend (`rests on the fund of the canals,
  which result more polluted of those of the close industrial zone ... even`,
  `have found you the presence of good 11 different poisons: 8,737 kiloes of
  nickel, 7.496 of chromium`, `Still seem, far anyway when one will be able to
  return swim in the canals like forty years, ago when`; `como cuarenta años
  hace`, `os han encontrado la presencia de bien 11 venenos`). The article's
  sentences fall from 3 872.8 million inferences in each language (the base
  capped at 3 billion a sentence: its eighth ran past 25 billion uncapped and
  was refused) to 603.0 into Spanish and 602.8 into English, of which the eighth
  is 394.2 million and the fourth 124.4. It needed these SHAPES, each with its
  arm red (test/translate.pl's `newspaper_venice`: 77 checks, 79 arms, the
  guards among them; an arm is a library directory of symlinks whose
  reasoning/translate.pl is the edited copy, `COCOLOG_LIBRARY=ARM cocolog query
  "use_module('test/translate.pl'), newspaper_venice, checks_done"`, a second a
  run, and every arm is run in two minutes, four at a time): `del` after a first
  name and a surname, before an acronym, is the preposition and its article
  (`Roberto Zonta del Cnr e Mario Scattolin del comune` are of the Cnr and of
  the town council, and joined it was one name, tr_particle_names/4; before a
  word with a vowel after its capital it stays the name's, a guard, `Joseph
  Guarnerius del Gesù`, tr_acronym_word/1); a connector the lesson states as an
  article, a noun, a preposition and the relative (`il giorno in cui`, `el día
  en que`, the lesson's `when`) is taken apart after a verb into the phrase and
  its relative clause (`Sembra ancora lontano, comunque, il giorno in cui si
  potrà tornare a fare il bagno` was `Still seem, far anyway when one will be
  able`, tr_unjoin_when/3), never at the head of a clause or after a conjunction
  (two guards), and the time's reader leaves the relative to the phrase's
  readers (tr_complements0/4) -- four arms; English writes `when` after a time
  for `in which` (tr_relative_out/5); a verb of seeming with its predicate, and
  an adverb between commas, before its subject (`Sembra lontano, comunque, il
  giorno ...` seems far, anyway: a clause of tr_read_statement0/4, and the
  adverb with its comma written last, tr_comps_out/7 -- three arms); `ends up`
  with nowhere to end up is `ends` (`le sorprese non finiscono qui` do not END
  here, the lesson's intransitive `finisce` being `ends up`, which `deve finire
  in tribunale` needs: tr_write/4 for the verb and its infinitive,
  tr_ends_up_where/1 for a phrase, a predicate, an adverb of place of several
  words -- four arms, two of them guards); a reflexive verb that shows what one
  is, with a predicate, is `appears` (`i Tecnici ... si mostrano ottimisti` was
  `display optimistic`), and with nobody named after `e` no passive whose
  subject is the bare adjective (`optimists are displayed`,
  tr_predicate_after_reflexive/2) -- two arms; `results` before a predicate is
  `turns out` (`i quali risultano più inquinati`); a verb of several words that
  ends in a preposition takes its phrase bare (`si occupa della sistemazione`
  was `takes charge of of the arrangement`, en_bare_object/1), and no phrase of
  an insertion is one the clause's verb governs (a guard the controls found:
  `Navarro, en un momento de forma excepcional, se encargó de` was `in a moment
  exceptional form`, tr_ungoverned/2); no article before a percentage in words
  (`pari all'87 per cento del totale`, tr_det_out/6); a range of years between
  two commas is from and to (`per dieci anni, dal 1994 al 2004, hanno scavato`
  was `since 1994 to 2004`, tr_cross_comps/2); a count of time after a
  preposition takes its `ago` with it (`come quarant'anni fa, quando c'era` was
  `like forty years, ago when there was`, and Spanish, whose `hace` begins the
  time, `como cuarenta años hace`: tr_ago_phrase/2, ago/2, crossed and written
  by each language, the marks of a quotation that closes on the time moved to
  its last word -- six arms), in the phrase of `of` of a phrase whose noun is
  left out too (`inferiore a quello di trenta anni fa`, `al de hace treinta
  años`); `ben` before a count says how many (`la presenza di ben 11 veleni
  diversi` is as many as 11, and read as the noun `bene` the presence was of a
  good: tr_complements0/4 for an object and for the phrase of a preposition,
  tr_count_adverb/1, advp/2 -- an adverb the lesson says means `as many as` too,
  Spanish's `nada menos que`, which was `finds 11 poisons as many as` -- crossed
  as `as many as` and written by the lesson's word for it, or the count alone
  where it states none: six arms); a noun that can say the bottom of a thing
  says it before a phrase of `of` with a determiner (`giace sul fondo dei
  canali` rests on the BOTTOM of the canals, `fondo` a fund first:
  tr_relational_np/3 in the phrase of a preposition and in the phrase of `of` of
  a phrase whose noun is left out, `qual'è quella del fondo dei rii`, and the
  phrase of `of` definite with its relative clause, tr_head_definite/1 -- five
  arms, one a guard: `il fondo di investimento`, with no determiner, is a fund);
  the copula left out after a comma (`i motori sono più efficienti, le benzine
  senza piombo, gli antivegetativi meno dannosi, i detersivi quasi tutti
  biodegradabili` -- read as the copula's objects, English wrote `the least
  harmful antifouling paints` and `the detergents everyone biodegradable
  almost`: tr_gapping/2, gapc/2, the last adjective of a phrase with nothing
  after it its predicate and its superlative the comparative it says, `tutti`
  all of them -- four arms); the partitive after the impersonal `si` is what is
  done (`si stanno installando delle fosse settiche` was `are installing of the
  septic tanks`, tr_si_partitive/2), and English elides no subject before such a
  clause after `e` (`the detergents were installing septic tanks`, tr_write/4)
  -- two arms; the word that begins the cause, an adjective and a clause of
  `che` are a concession (`Per strano che possa apparire` was `For strange that
  can appear`: conc/3, crossed by tr_cross_comp/2, English `however strange it
  may appear` with the modal `may`, the lesson's language as it stood with the
  clause in the subjunctive, `Por extraño que pueda aparecer` -- two arms); a
  thing's reflexive in the perfect is the passive's perfect, in a relative
  clause and after a comma (`tonnellate di piombo ... che si sono depositati`
  was `have deposited`: tr_se_passive_rc/4, tr_phrase_nrc/3, and fo_group/8
  writes the reflexive's perfect, `se han depositado` -- three arms); a phrase
  of `of` right after a participle English writes with one is the participle's
  (`altre città europee dotate di canali` are endowed WITH canals, `un "tesoro"
  tossico fatto di tonnellate di piombo` was `a made toxic treasure of tons of
  lead`: tr_of_participle/2, en_of_participle/1, tr_participle_adjunct/4 for a
  subject's phrase, en_governs/2 -- three arms); an adverb before the word for
  `than` (`più inquinati persino di quelli della vicina zona` was `more polluted
  of those ... even`, tr_comparison_seps/3); `vi` before a verb with an object
  of its own is `there` (`e vi hanno trovato la presenza di ben 11 veleni` was
  `have found you the presence`: tr_there_clitic/3, never with a verb of giving
  or telling, en_dative_verb/1, nor with no object -- three arms, two of them
  guards); in a denied clause `tanto ... quanto` is `not so much ... as` (`would
  not derive both from ... and from` said it came from neither, tr_both_pair/3),
  and the two halves are the verb's when each opens on the preposition it takes
  (`no derivaría tanto de los vertidos como de una contaminación`, where Spanish
  wrote `desde`, tr_governed/3) -- two arms; `even` before the phrase of a
  preposition is said of it (`e persino di arsenico`, tr_comps_out/7), and so is
  `also` that opens an insertion on one (`tende, anche con l'aiuto dell'acqua
  salmastra, a facilitare` was `also tends, with the help`: tr_pull_adverb/3 and
  a clause of tr_comps_out/7 -- two arms); `therefore` stands with the verb
  (en_mid_adverb/1); a participle and the adverb that says how stand before the
  noun (`su una superficie sostanzialmente limitata`,
  tr_pre_participle_adverb/2), an adverb in `-ly` or `already`, `newly`,
  `often`, never `well`, `ever` or `never` (a guard the controls and the whole
  case found: `el Mundial más exótico jamás organizado` was `the most exotic
  never organised World cup`, and the Salvini report's `75 anni ben portati` `75
  well brought years`); a phrase whose noun is left out with a phrase of `of` is
  `that of` (`del tutto simile a quello di altre città` was `the one of`,
  tr_np_out/5), and an adjective with its phrase and the word that says how much
  before it stands after its noun (`completely similar to that of`,
  tr_adj_with_intensifier/2); `close` before a noun is `nearby` (`la vicina zona
  industriale`, tr_adjective_out/5); a number that is the phrase's head, its
  noun left out, takes English's marks (`7.496 di cromo` stayed `7.496`,
  tr_percent_style/3); a noun in `o` takes `s` (`8,737 kiloes`, `the studioes`),
  but for the few English writes with `es` (en_oes_plural/1, a guard); a
  language whose `there is` takes no definite phrase says the thing is there
  with its state copula (`non c'è più il carbone` was `no hay más el carbón`:
  `"hay" takes the indefinite.`, the writer of tr_write/4 -- three arms, two of
  them guards: an indefinite phrase keeps `hay`, and so does the past, `c'è
  stato il referendum`, which the controls found as `estuvo el referéndum`); an
  adverb the IR has after the complement that closes a quotation stood outside
  it (`mentre oggi l'inquinamento "è inferiore a quello di trenta anni fa"` was
  `... ago today"`, tr_write/4); `until` after `from` is `to` in English (`dal
  lido fino a San Marco`, tr_comps_out/7); an infinitive the one before it takes
  with its word is `to` and the verb under a modal too (`si potrà tornare a fare
  il bagno` was `return swim`, tr_comp_out/7); `many of which` is its clause's
  subject (`molti dei quali non venivano ripuliti` was `many of which they were
  not cleaned`, tr_quantity_gap/4); and two rules the store-alone column found,
  below: a word that is a noun too is no command where a third person is read
  (tr_third_person_command/3 asks tr_verb_form_any/1), and no two names are
  joined across a dash after a verb's third person (tr_dash_names/3). Three
  pieces of code written for the article had arms that stayed green and are
  gone: an English writer's clause for an adverb in a clause with its copula
  left out (the general one writes it in place), a guard that the impersonal
  partitive's verb takes no `di` (a verb that takes it has the phrase it
  governs, gov/2, which the rule's pattern does not match) and a guard against a
  subject in the second person plural for `vi` as `there` (its `vi` is read as
  its reflexive before the rule); a guard that kept `results` before a phrase of
  `from` was taken out unmeasured, `turns out polluted by` being the better
  text. It needed these WORDS in `extra/` (the two readers: a line moves the
  reader of one language and the writer of the other; the dictionary's own word
  is said again first where it must stay the one written): Italian `confeziona`
  (prepares, with its forms; `prepara` said again first), `policlorobifenile`,
  `antivegetativo` (an antifouling paint), `bracciata` (a swimmer's stroke),
  `zattera` (a raft, with its gender and plural), `fossa settica`, the elisions
  `trent'` and `qual'` (the source's `qual'è`), `sulle orme di` (in the
  footsteps of), `studio`, `ricerca` and `gruppo` (a study, research and a
  group, where the dictionary's first were a studio, a search and a cluster),
  `fondo` (a fund, where its first was the background; the bottom of a thing is
  the code's), `canale` (a canal, the channel second), `in fondo` (after all),
  `alla ricerca di`, `da tempo` (for a long time), `nel corso degli anni` (over
  the years), `"deposita" takes the passive.`, `metro cubo`, `d'intesa tra` (in
  agreement between), `fa il bagno` (swims; `nuota` said again first), the name
  `Consiglio Nazionale delle Ricerche`, `progetto` (a project, not a blueprint),
  `diverso` and `diversa` (different), `simile` (similar, not alike), `scarico`
  (a discharge, before the unloading), `"deriva" takes "da" before the phrase.`
  and `"viene" takes "da" before the phrase.` (so that Spanish writes `de`,
  where it wrote `desde`), and `traccia` (a trace, before the dictionary's
  stroke: below); Spanish `desastre` (said first, before `descalabro`),
  `contaminado` and its forms (polluted), `policlorobifenilo`,
  `antiincrustante`, `fosa séptica`, `tras las huellas de`, `grupo` (said again
  first, before `conjunto`), `desde hace tiempo`, `a lo largo de los años`,
  `metro cúbico`, `de acuerdo entre`, `nada menos que` (as many as), `extensión`
  (said first, where the writer's word was `prórroga`, a match's overtime),
  `"hay" takes the indefinite.`, and `"deriva"` and `"viene"` taking `de` before
  the phrase; and in the dictionaries' extras, for Italian `rest` (`giacere`,
  read only: English's `lie` is also to tell one), `pollute` and `polluted`
  (`inquinare`, `inquinato`, both ways), `pesticide`, `canal` (`rio`, read
  only), `brackish`, `continuation` (`prosecuzione`), `clean` (`ripulire`),
  `harmful` (`dannoso`), `detergent` (`detersivo`) and `footprint` (`orma`), the
  five read only, `fearless` (`impavido`), `swimmer` (`nuotatore`), `mighty`
  (`possente`), `confirmation` (`conferma`), `accumulation` (`accumulo`) and
  `curator` (`curatore`), and for Spanish `pesticide`, `fearless` (`impávido`),
  `stroke` (`brazada`), `discharge` (`vertido`) and `curator` (`curador`). The
  first meaning moved for 12 Italian words and no Spanish one (Italian `diverso`
  and `diversa` different, `simile` similar, `canale` a canal, `curatore` a
  curator, `fondo` a fund, `gruppo` a group, `progetto` a project, `ricerca`
  research, `scarico` a discharge, `studio` a study, `traccia` a trace), the
  writer's first word for 8 Italian meanings and 6 Spanish ones (Italian
  different `diverso`, fearless `impavido`, accumulation `accumulo`,
  confirmation `conferma`, discharge `scarico`, stroke `bracciata`, swimmer
  `nuotatore`, pollutes `inquina`; Spanish fearless `impávido`, disaster
  `desastre`, discharge `vertido`, extension `extensión`, group `grupo`, stroke
  `brazada`), and none was lost. THE CONTROLS (cocolog 2.11.2, store KB212, 102
  count files, 2 844 sentences: the earlier set with the banks' Saturdays report
  in, es_19990601-98, both directions; this report is not among them): the last
  version's translator against this one, on the one store, 52 sentences in 28
  files read differently, all better but three that are no worse -- `that of`
  for `the one of` (9: `that of the lifeguard`, `that of Berlusconi`, `That of
  the Tuscan archipelago`), the English plural in `-os` (7: `kilos`, `videos`,
  `virtuosos`, `violoncellos`, `euros`, `photos`), `therefore`, `also` and
  `even` where they stand (10: `would therefore transfer`, `has the right duty
  of favouring, also with coercive measures`, `even inside the roof`), no
  article before a percentage in words (`they represent 11.5 per cent`, `only 1
  per cent`, `assigns 2 per cent`), `appeared` (`the Spanish Government has
  appeared cold and reluctant`, `Rodríguez Zapatero appeared very accurate`),
  `turned out injured`, `has not ended`, `to obtain`, `to intervene`, `to
  judge`, `the bottom of the hole`, `2,000` and `2.3`, `for the first time,
  yesterday` with the source's comma, `the recently constituted town councils`,
  `moments when`, `from the day when` (`dal giorno in cui`, both languages), `or
  they lose`, `And in fact they confirm`, Spanish `están las voces`, `No están
  las sillas altas` and `"Está el jefe del estado afortunadamente"` (the state
  copula, three), and the Rosi report's 25th, refused by the last version on
  this store and read -- and the three no worse: `they have dumped him to the
  last world cups down, for this reason where` for `... cups, down for this
  reason where` (it_9540_9566 14, the adverb between commas at the end of a
  clause: the IR has `per questo` after its comma, a misreading both texts
  carry), Spanish `ni siquiera si está el asentimiento` and `¿No está el riesgo
  de discriminaciones?` for `hay el` (it_9450_9464 12, it_9816_9850 14: Spanish
  says `¿No hay riesgo ...?`, with no article). The inferences fall 0.216 % (7
  075 042 579 to 7 059 726 041) and rise 0.096 % outside the four sentences the
  code reads faster (the Rosi report's 25th, 9.9 million inferences to 1.6, and
  29th, 3.4 to 0.6, in each language). Bytes and characters read every sentence
  alike (0 differ, the bytes 0.014 % more). The DATA COLUMN (the last version's
  translator on its own store, KB206, against this one on the new): 78 sentences
  in 32 files, +0.110 % (7 051 992 814 to 7 059 726 041). THE CODE ALONE (this
  translator on KB206): 45 sentences in 28 files, every one among the 52, +0.016
  % (to 7 053 094 325); the seven left need the new lines (`"hay" takes the
  indefinite.`, `conferma` as a noun). THE STORE ALONE (the last version's
  translator on KB206 and on KB212): 34 sentences in 14 files, +0.327 % (to 7
  075 042 579), all better but the two of `conferma`, below -- `project` (6:
  `the "project Bogi"`, `a rejected project at birth`, where they were
  blueprints), `different` (6: `two different people`, `the different souls of
  the pole`), `research` and `study` (8: `the Scientific Research`, `bags of
  study`), `funds` (`with own funds`, `the necessary funds ... through a
  national fund`, where they were backgrounds), `group` for a cluster, `after
  all` and `al fin y al cabo` for `in background` and `en fondo`, `similares`,
  `wanted to swim` and `quería nadar` (`fare il bagno`), `si deriva
  dall'accordo` (`deriva` takes `da`, where Italian wrote `dell'accordo`),
  `diverse proposte`, and `leaves its traces` and `deja sus rastros`
  (`traccia`). Its cost is two sentences: the Rosi report's 25th (+8.3 million
  inferences in each language, to its refusal) and it_9270_9295 9, `Cecchi Paone
  conferma che ...` (+3.0 million, 41.9 to 44.9, the text the same), both
  `conferma` read as a noun too. THE FIRST ROUND'S REGRESSIONS, found by reading
  the texts of every column and mended. Of the code (the one store): an
  insertion's phrase was governed by the clause's verb, which English now wrote
  bare after a verb of several words that ends in its preposition (`Navarro, en
  un momento de forma excepcional, se encargó de llevar el peso` was `in a
  moment exceptional form`: no phrase of an insertion is governed now,
  tr_ungoverned/2, a guard); `del` before a capitalised word split a name (`su
  constructor, Joseph Guarnerius del Gesù, de Cremona` was `his builder Joseph
  Guarnerius of the Gesù`: only before an acronym now, tr_acronym_word/1, a
  guard); `ever` and `never` went before the noun with their participle (`el
  Mundial más exótico jamás organizado` was `the most exotic never organised
  World cup`), and so did `well`, which the whole case found in an older check
  (`75 anni ben portati`, `75 well brought years`: none of the three now, a
  guard); and the state copula wrote a past event (`c'è stato il referendum` was
  `estuvo el referéndum`: never in the past now, a guard). Of the store (the
  store-alone column): `lascia le sue tracce` was `deja sus brazadas`, the
  writer's word for a swimmer's stroke being Spanish's word for any stroke now
  and `traccia` a stroke first in the dictionary (`traccia` is a trace first
  now, a line of corpus/extra, and the sentence is `deja sus rastros`); and the
  dictionary line that gives the report's `La conferma di un sospetto` its noun
  made `conferma` a noun everywhere, so that `E infatti conferma indirettamente
  le voci` was `And in fact confirm the voices` -- the third person was turned
  down where a form is a noun too, and the command, read after it, took the
  sentence (tr_third_person_command/3 asks tr_verb_form_any/1 now) -- and the
  Rosi report's `l'Egibren - conferma Casotto - Rosi sapeva del farmaco` was
  refused, `Casotto - Rosi` read as one name after the noun (tr_dash_names/3
  refuses a word that is a verb's third person too): two rules, each with its
  arm red. THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT (thirteen
  sentences of the controls into English, eleven of 0.2 to 3 million inferences
  picked at random and two risers of 12 and 52 million, over a copy of the
  library per rule on the new store): the first cut was +0.297 % of the controls
  outside the four sentences it reads faster, and 2 840 of the 2 844 sentences
  rose, a few thousand inferences each -- a cost every reading pays, +0.74 % of
  the sentences under 0.2 million. The statement reader's clause for a verb of
  seeming was 18 % of what the thirteen rose, tr_complements0/4's two clauses
  for `ben` and a count 16 %, and the crossing's two for the bottom of a thing 5
  %: the first asked tr_form/5 of the first word of every piece (300 to 650
  inferences a call) and the second two the lexicon at every complement. What
  paid was a list made once a sentence (tr_into_ir/4): the lexemes whose meaning
  is `seems` or `appears` and those whose meaning is `well` or `as many as`,
  found by their meanings (52 inferences: the store keys the call on its second
  argument), each clause asking the word's lexeme against its list first
  (tr_count_lexeme/1). Two notes tried before it -- whether a sentence has a
  verb of seeming, or a count adverb before a count, asked of every word -- cost
  more than they saved (10 000 inferences a sentence for the first, tr_form/5 at
  every word), and the cheaper question first inside each clause saved nothing:
  the cost was the clauses being entered. The bottom clause asks the noun's
  meaning before its phrase's determiner, which moves nothing measurable. The
  final cut is +0.096 % outside the four (7 048 448 093 to 7 055 197 021, the
  first 7 069 393 361), every text of the 2 844 the first cut's: +0.36 % of the
  sentences under 0.2 million, +0.27 % of 0.2 to 1 million, +0.18 % of 1 to 5
  million, +0.10 % of 5 to 20 million; the largest rises are the Rognoni
  interview's nineteenth (+0.23 million of 773, refused both ways) and
  it_9714_9749 24 (+0.13 million of 3.7, `we must learn to judge`). THE STATED
  COSTS: the dictionary's line that gives the report's `La conferma di un
  sospetto` its noun makes `conferma` a noun everywhere, and `Cecchi Paone
  conferma che ...` (it_9270_9295 9) costs 3.0 million inferences more in each
  language, its text the same (the two readings it broke are mended by the two
  rules above); a first meaning that serves the news and not every text --
  `fondo` is a fund (the background second; the bottom of a thing is the
  code's), `canale` a canal (a television channel is one now; no sentence of the
  controls has it), `progetto` a project, `studio` a study, `ricerca` research,
  `gruppo` a group, `scarico` a discharge, `diverso` different, `simile`
  similar, `traccia` a trace, Spanish `desastre` a disaster, `extensión` an
  extension, `grupo` a group, and the writer's `bracciata` and `brazada` for any
  stroke and `impavido` and `impávido` for fearless -- and the controls'
  sentences they change are the store's 34 above; Spanish's state copula after
  `c'è` and a definite phrase in a question (`¿No está el riesgo de
  discriminaciones?`, as wrong as the `hay el riesgo` it was); the adverb
  between commas at the end of a clause moves the comma of a misread sentence
  (it_9540_9566 14); and the inferences, +0.096 % outside the four sentences the
  code reads faster, and the store's +0.327 %. The report LEAVES, of the 12 into
  English: `Venezia`, `Stoccolma` and `Porto Marghera` as the source spells them
  (no lesson states a city's English name); `the ambient direction of the town
  council` (the environment department) and `the muds of the numerous canals`
  (3); `the group "Insula" that takes charge` (the comma before the relative
  clause lost) and `an "integrated project prepared canals"` (4: a title in
  quotation marks read as the lesson's words, `rii` as canals, and its
  participle after it); `that, represent just ten per cent` (8: the comma after
  the relative word, and the verb in the plural where its subject is the
  bottom); `the Technicians therefore, that they promise to remove "all the
  remaining poisons"` (9: a quotation that closes before the comma ending the
  subject's relative clause leaves the clause with nobody named, where `who
  promise` is the text); `while the pollution "is inferior to that of thirty
  years ago" today` (10: `oggi`, before the subject in the source, is written
  last in both languages); of the 12 into Spanish: `desde 1994 a 2004` (3, `de
  1994 a 2004`) and `los barros` (`los lodos`); `el Ministerio del Entorno` (4,
  `del Medio Ambiente`); `Y entonces` (5, `Y luego`); `ciudades europeas dotado
  de canales` (8: the participle after its noun's phrase agrees with nothing,
  `dotadas`) and `y desde el hecho de que` (8: the third `da` after
  `deriverebbe` is no half of the pair the verb governs, `del hecho`); `muchos
  de los que` (9, `de los cuales`); `los estudios en los sedimentos ya
  consideran el pasado` (10, `sobre`, `se refieren al pasado`); and `no está más
  el carbón` (11, `ya no hay carbón`). The next sample's controls take this
  report in.
  The Yeltsin report (AnCora CESS-CAST-P-19991202-35, 16 sentences, Spanish into
  Italian and English: 16 of 16 and 13 of 16 on a fresh store, 16 and 14 with
  the new store alone, 8 and 11 with the new code on the old store, 8 and 11
  before; reasoning 1.0.16). The sample was taken on the cocolog 2.11.2 binary,
  and cocolog stays 2.11.2; master's 2.11.3 (5164d48, the step answers a read
  predicate's clause count inline, and inference counts do not move) came during
  the sample and is not merged: the next sample takes it. The article's
  sentences fall from 15.7 million inferences into Italian and 15.1 into English
  to 6.8 and 6.1. The new store alone reads 14 into English where the new code
  reads 13: its old reading of the colon's side (`Yeltsin mantiene un régimen
  ...: recibe correo y estudia documentos`) was the commands `receive mail and
  study documents`, and the new reading is Yeltsin's own present, which English
  refuses for the third person nobody names, on purpose (3, 4 and 9). It needed
  these SHAPES, each with its arm red (test/translate.pl's `newspaper_yeltsin`:
  48 checks, 51 arms, the guards among them; an arm is a library directory of
  symlinks whose reasoning/translate.pl is the edited copy, `COCOLOG_LIBRARY=ARM
  cocolog query "use_module('test/translate.pl'), newspaper_yeltsin,
  checks_done"`, two seconds a run, and every arm is run in two minutes, four at
  a time): `se trata de` is `it is` (`Se trata de la segunda hospitalización del
  líder del Kremlin` was `One treats of`, tr_write/4); a singular subject that
  is no person owns what its complements' possessive names, `its` (`la vida
  política en Moscú continúa su curso` continues ITS course,
  tr_thing_possessor/2, tr_cross_det/2), and not where a person or a name stands
  among the clause's complements, nor where a pronoun stands for a person (`El
  viento le voló su sombrero` blew HIS hat, `avisó a Ibarretxe de que a su
  Gobierno el tiempo se le acaba` is his Government: tr_person_clitic/1, both
  found by the controls), and the writer takes the words for `his` after the
  lesson's words for `its` where none has the noun's gender (tr_det_meanings/3:
  a store taught before `"suo" means "its".` wrote no sentence that had it --
  the code alone on the old store refused 8 of the controls -- and one with the
  masculine alone wrote `la suo porta`); a connecting word the lesson also gives
  as an adverb that stays in front, with a comma straight after it at the head,
  is the adverb (`Mientras, la campaña militar en Chechenia también prosigue` is
  Meanwhile, tr_read0/4); a name of one word that ends the piece after a noun in
  small letters, a name the lesson states, is apposed to it (`sobre la capital,
  Grozni`, and with the comma the city was an object of the verb of its own, `on
  the capital, Grozni yesterday`: tr_list_commas/5), crosses by its meaning and
  is written in each language's word (tr_cross_adjective/2, tr_adjective_out/5);
  a day's adverb the source put right after its verb stands before the verb
  where the clause runs long (`El jefe guerrillero ... lanzó ayer un llamamiento
  ..., según la cadena ... RTR` YESTERDAY launched an appeal, and written last
  it came after the network that told of it: tr_write/4, en_day_adverb/1,
  en_long_tail/1), and after a copula that stands alone (`son hoy el exponente`
  ARE today the exponent, found by the controls); a manner adverb in `-ly` right
  after its verb, before an object, a clause or an infinitive, goes with the
  verb (`el Kremlin confirmó ayer oficialmente los temores` officially confirmed
  them, tr_pull_adverb/3), never `awfully`, a degree (`No, sería mucho pedir`
  was `it would awfully be to ask`, en_not_manner_ly/1), and an adverb of how
  sure stands before a denied group (`non pensavo certo di incontrare` is I
  certainly did not think, and it was `I did not certainly think`:
  tr_mid_insert/3, en_sentence_adverb/1); an adverb that ends the subject's
  words, right before the verb, is the clause's (`la campaña militar en
  Chechenia también prosigue` -- Italian wrote it before the verb, `in Cecenia
  anche continua`: tr_subject_adverb_out/4), an adverb of one word or one
  English writes with the verb (`ya no`, no longer), never one of several words
  that is the phrase's own (`Las previsiones de evolución de este mercado a
  corto-medio plazo no son optimistas` was `non sono a breve-medio termine
  ottimiste`) and never the word that denies (`Un dato confortante del quale non
  ci si può rallegrare` was `se nos puede no alegrar`: a guard with no arm that
  goes red, which no hand lesson reproduces and which stays for what the
  controls showed); the side after a colon goes on saying what the subject
  before it does (`Yeltsin mantiene un régimen ...: recibe correo y estudia
  documentos` is what Yeltsin does, and read as commands it was `receive post
  and study documents`: tr_read_after_colon/5); a date is when after a verb that
  takes no object (`la primera vuelta tendrá lugar el 4 de junio` takes place ON
  June 4: tr_complements0/4, tr_date_adjunct_here/1); a verb left out after its
  coordinator, with a time for what is said (`la primera vuelta ... tendrá lugar
  el 4 de junio y la segunda vuelta, tres semanas más tarde`, cnj/1 and gapc/2,
  tr_gap_time/2); a name the source apposed to the noun among its adjectives
  stays after them, and English turns the adjectives round (`El jefe guerrillero
  checheno Chamil Basayev` is the Chechen guerrilla chief, en_adj_order/3,
  en_nationality/1); the phrase a participle's verb governs is marked as a
  clause's is (`un régimen calificado de "semilaboral"` is described AS one,
  `"califica" takes "de" before the phrase.`, tr_ptc_governed/4, en_governs/2);
  a name the lesson gives a meaning crosses by it and each language writes its
  own (`The name "moscú" means "Moscow".`, mean_as/3 under the class name; `en
  Moscú` is in Moscow and `a Mosca`: tr_cross_np/2, tr_cross_subject/3,
  tr_subject_out/6, tr_np_out/5, tr_named_words/3, tr_city_name/1) -- and the
  controls' first round found five faults of it, each mended with its arm red:
  the lesson's word is written only for a name the source crossed (`los
  argentinos Guglielminpietro (Milan)` is the club, a name the Spanish lesson
  does not state, and the IR's `Milan`, spelled as the English city is, came out
  `(Milano)`: tr_name_word_out/2, the names a sentence crossed noted as it is
  read, '$tr_xnames'); a city's name after an article is the club named after it
  and crosses as itself (`contro il Napoli` was `against the Naples`, `contra el
  Nápoles`); a word the lesson knows as a name and as nothing else is a name in
  quotation marks too, its marks off for the lesson and back on its word
  (`señaló que "España ve con simpatía la candidatura"` was refused once
  `España` was a word the lesson knows, and `analizado por Bruselas".` was `by
  brussels`: tr_only_name/2, tr_quote_names/3, tr_tail_mark/5, tr_unmark/4); a
  name after an elided article takes the gender the lesson states of it, asked
  in small letters (`L'Italia che soffre` was `El Italia que padece`,
  tr_name_gender/5); and a name of several words has a capital on each (`(New
  York, 1991)` was `(Nueva york, 1991)`, tr_cap_words/2); a person the source
  names in the feminine is one in the other language too (`la diplomática
  norteamericana Cheri Leberknight` was `il diplomatico americano`:
  tr_fem_person_note/3, tr_noun_lexeme0/5), never an animal, whose gender is its
  word's (`è come cavalcare una tigre` was `cabalgar a una tigresa`), and noted
  with its number (`dai 70 studenti iscritti ...: una studentessa che indossa la
  tuta` -- noted by the noun alone the 70 were `las 70 alumnas inscritas`); a
  word the lesson states in both genders agrees with either (`militare` is a
  soldier of either sex, and as the adjective it was masculine to the writer,
  `la campagna bellica`: tr_stated_both/1), and among nouns that are adjectives
  too a person stated in both genders is no head by being one (`l'aeronautica
  militare` was `el aeronáutico soldado`, tr_noun/5); and a preposition that
  contracts with the article is said again before the second of two definite
  phrases (`los ataques de la artillería y la aviación` are `gli attacchi
  dell'artiglieria e dell'aviazione`, tr_comp_out/7, tr_prep_contracts/1). It
  needed these WORDS in `extra/` (the two readers: a line moves the reader of
  one language and the writer of the other; the dictionary's own word is said
  again first where it must stay the one written): Spanish `fija` (sets, where
  it was fixes, which Italian's writer took for a repair, `ripara`),
  `presidente`, `presidenta` and `president` (a president first, as Italian's
  `presidente` is), `primera vuelta` and `segunda vuelta`, `elección
  presidencial` and the noun `presidencial` (the presidential election, the noun
  left out), `"recupera" is reflexive.`, `semilaboral`, `allegado` and
  `allegada` (close associates, persons), `"califica" takes "de" before the
  phrase.`, `espaldarazo` (a boost), `fiscal general`, `cargo` (a post, where
  its first meaning was a charge) and `se hace cargo` (takes charge of, with its
  forms and `de`), `pariente` (said again first) and `familiar` (relatives),
  `alto funcionario`, `asunto` (an affair, where it was a subject),
  `diplomático` and `diplomática`, `americano` (said again first) and
  `norteamericano`, `más tarde`, the tenses of `tiene lugar`, `indiferente`
  (said again first) and `ajeno` (indifferent), `liderazgo` (said again first)
  and `cúpula` (the leadership, where it was a dome), `para fin de año`, `dura`
  (lasts, said again first) and `prolonga` (prolongs, and lasts as a reflexive),
  `guerrilla` (said again first) and `guerrillero`, `checheno`, `cadena de
  televisión`, `apelación` (said again first) and `llamamiento` (an appeal,
  where it was a call), `defensa` and `exteriores` (institutions), `correo`
  (mail, where it was the British post), `espera` (expects, and hopes before an
  infinitive), `finaliza` (completes, and ends with no object), `ministerio de
  exteriores` and `ministerio de asuntos exteriores`, `jefe` and `jefa` (a
  chief, where it was a boss), `"releva" takes "de" before the phrase.`,
  `"pívot" is a person.`, the 24 nouns in `-ción`, `-sión`, `-dad`, `-tud` and
  `-umbre` whose gender the dictionary leaves unsaid, each stated feminine, and
  37 names with their English meaning (`Moscú`, `Rusia`, `Chechenia`, `Grozni`,
  `Kremlin`, and the cities and countries the controls name, `Londres` to
  `Israel`, `Cataluña` said before `Catalunya`); Italian `fissa` (sets), `primo
  turno` and `secondo turno`, `elezione presidenziale`, `semilavorativo`,
  `stretto collaboratore` and `stretta collaboratrice`, `procuratore generale`,
  `incarico` (a task, then a post, where the writer's word for a post was
  `carico`, a load), `alto funzionario`, `vicenda` (an affair), `più tardi`, the
  tenses of `ha luogo`, `entro la fine dell'anno`, `guerrigliero`, `ceceno`,
  `rete televisiva`, `suo` and `sua` (its), `"spera" takes "di" before the
  infinitive.`, `solleva` (poses, and relieves, taking `da`), `spionaggio`
  (espionage, where the first noun for it was `spia`, a spy), `ministero degli
  esteri`, `"descrive" takes "come" before the phrase.`, `"militare" is
  feminine.`, the 148 nouns in `-zione`, `-sione` and `-tà` whose gender the
  dictionary leaves unsaid, each stated feminine (`il secondo
  ospedalizzazione`), and 36 names, the 14 cities that take `a` stated so
  (`mosca`, `russia`, `cecenia`, `grozny`, `cremlino`, and the controls' cities
  and countries); and in eng-ita.dix `cool` (`raffreddare`, where the
  dictionary's verb was `rinfrescare`). The first meaning moved for 14 Spanish
  words and 2 Italian ones (Spanish `ajeno` and `ajena` indifferent, `asunto` an
  affair, `cargo` a post, `correo` mail, `cúpula` the leadership, `jefe` and
  `jefa` a chief, `llamamiento` an appeal, `president`, `presidente` and
  `presidenta` a president, `fija` sets, `finaliza` completes; Italian `spia` a
  spy, `fissa` sets), the writer's first word for 6 Spanish meanings and 7
  Italian ones (Spanish later `más tarde`, mail `correo`, post `cargo`,
  completes `finaliza`, fixes `arregla`, sets `fija`; Italian later `più tardi`,
  affair `vicenda`, espionage `spionaggio`, post `incarico`, cools `raffredda`,
  relieves `solleva`, sets `fissa`), and none was lost. THE CONTROLS (cocolog
  2.11.2, store KB219, 104 count files, 2 868 sentences: the earlier set with
  the Venice report in, it_9999_10010, both directions; this report is not among
  them): the last version's translator against this one, on the one store, 194
  sentences in 75 files read differently, all better but the stated costs below
  -- the names a lesson now gives a meaning (`England`, `Germany`, `Spain`,
  `Catalonia`, `London`, `Florence`, `Seoul`, `Rome`, `Milan`, `Italy`, `Japan`,
  `Europe`, `Brussels`; Italian `Inghilterra`, `Germania`, `Spagna`,
  `Catalogna`, `Barcellona`, `a Londra`, `a Firenze`, `a Seul`; Spanish `Milán`,
  `Cerdeña`, `Japón`, `Atenas`, `Nápoles` for the city and `el Napoli` for the
  club), `yesterday`, `today` and `last night` before the verb of a long clause,
  `its` (`the Unicaja ... confirmed its enormous potential`, `the compact disk
  continues increasing its penetration`, `each federation has its regulations`,
  `the organisation of Miss Mundo 2000 ... its business`), the adverbs in `-ly`
  with the verb (`officially`, `recently approved`, `radically exclude`,
  `normally have need`, `indirectly confirm`, `I certainly did not think`), `it
  was about 10 kilos` (`se trata de`), `is no longer synonymous` and `non è più
  sinonimo`, `risultarono anche ferite` and `caricò anche`, the women
  (`l'incaricata del Governo, Julia García-Valdecasas`, `presidentessa`, `su
  compañera de otoño`, `L'infermiera gli raccomandò`), `dall'impegno e dalla
  volontà` and `sull'industria e sul settore agricolo`, `the military
  aeronautics` and `la aeronáutica militar`, `L'Italia che soffre` as `La Italia
  que padece`, and the Matutes sentence, which the last version refuses on this
  store and this one reads (es_19990601-23 10, `"Spagna vede con simpatia la
  candidatura"`) -- and the inferences fall 0.026 % (8 269 449 520 to 8 267 295
  355) and rise 0.013 % outside four sentences: the Matutes sentence, 2.2
  million inferences fewer in each language, and `l'aeronautica militare`
  (it_9947_9966 9), 0.62 million more in each, the reading the person rule mends
  being the longer one. Bytes and characters read every sentence alike (0
  differ, the bytes 0.012 % more). The DATA COLUMN (the last version's
  translator on its own store, KB212, against this one on the new): 219
  sentences in 76 files, +0.022 % (8 265 461 199 to 8 267 295 355), +0.036 %
  outside es_20020601-51 6, which the store reads 0.56 million inferences faster
  in each language. THE CODE ALONE (this translator on KB212): 45 sentences in
  34 files, +0.015 % (to 8 266 667 554), and it reads every sentence the last
  version reads. THE STORE ALONE (the last version's translator on KB212 and on
  KB219): 53 sentences in 30 files, +0.048 % (to 8 269 449 520), +0.023 %
  outside six sentences, each a word of the report's lines (`president`,
  `affair`, `posts`, `mail`, `Defence`, `Difesa`, `set`, `a Tokyo`, `si occupa
  di Paral.lel` for `se haga cargo de`) or a fault of the old code on the new
  store that the new code mends (`El Italia que padece`, `by brussels`, `the
  naples`, `el aeronáutico soldado`, and the Matutes sentence refused). A FIRST
  STORE WAS 0.124 % DEARER FOR EIGHT LINES: the rules `Every noun that ends in
  "zione" is feminine.` (and `"sione"`, `"tà"`, Spanish's `"ción"`, `"sión"`,
  `"dad"`, `"tud"`, `"umbre"`), asked of the gender of every noun, cost the old
  translator on that store +0.172 % where this one costs +0.048 %, the
  translation from Spanish into Italian +0.57 % of it -- found by teaching a
  store without each group of the new lines and counting twenty of the controls'
  risers whose texts were the same (the Italian rules were 78 % of what the
  store cost into Italian, the Spanish ones 83 % into English, the names
  nothing) -- and they decide the gender of 148 Italian nouns and 24 Spanish
  ones, which are each stated now: the same texts, every one of the 2 868, for
  0.124 % fewer inferences. THE FIRST ROUNDS' REGRESSIONS, found by reading the
  texts of every column (three rounds and a word-by-word scan of the last data
  column) and mended, each with its arm red: `its` for a person (`El viento le
  voló su sombrero` was `its hat`, `avisó a Ibarretxe de que a su Gobierno` `its
  Government`, `Rony Seikaly ... rescindir su contrato` `its contract`, which
  wanted `"pívot" is a person.`); `its` where the lesson has no word for it (the
  code alone refused 8 sentences into Italian); the club (`against the Naples`,
  `contra el Nápoles` in 12 sentences); the uncrossed `Milan` (`(Milano)`); a
  stated name in quotation marks (the Matutes sentence refused, `by brussels`,
  and a closing mark on a name, `could erase the naples`); `El Italia que
  padece`, `del Italia`, `al Italia` (5); `una tigresa`; `las 70 alumnas
  inscritas`; `el aeronáutico soldado` and `the aeronautical soldier`, from
  `"militare" is feminine.`; `ha prolongado tan poco`, `que prolonga 5 años`,
  `Prolonga 6 meses` and `si prolongaba indefinidamente`, from the reflexive
  `prolonga` said first; `se haga cargo de` as `one makes post of` and `si fa
  incarico di`; the subject's adverb of several words (`non sono a breve-medio
  termine ottimiste`) and its denial (`se nos puede no alegrar`), and the guard
  for one word that lost `ya no` (`non più è sinonimo`, the second round);
  `today are the exponent`; `I did not certainly think`; `it would awfully be to
  ask` and `One awfully seems his parent`; and `(Nueva york, 1991)`. THE COST OF
  THE CODE, FOUND BY TAKING EACH RULE OUT (the twenty heaviest risers of 0.2 to
  3 million inferences on the one store, ten from Spanish and ten from Italian,
  into English, over a copy of the library per rule on KB218): the ten from
  Spanish rose 21 717 inferences of 10.3 million (+0.21 %), of which the
  feminine-person note was 9 173 and the `its` rule 8 248, each asked at every
  phrase the crossing meets, and the colon's rule 1 201; the ten from Italian
  rose 648 540 of 15.9 million, 620 233 of it the person rule in `l'aeronautica
  militare` (above), the `its` rule 12 376 and the note 9 161; no other rule
  over 2 600. THE STATED COSTS: `cargo` is a post, so `buscar otros cargos para
  fortalecer el proceso` is `other posts`, where it was the charges, and
  `actuales cargos de RTVE` `current posts`; `presidente` is a president, and
  `su presidente, Henry Hyde` of the judicial committee is `his president`;
  `asunto` is an affair (`in this affair`, `una vicenda`); `fissa` and `fija`
  set, so `le due delegazioni fissate per martedì` are `the two set
  delegations`; the preposition said again shows a misreading that the old text
  hid (`Dove è l'imperturbabile signore della bombetta e dell'ironico umorismo`,
  the gentleman of the bowler hat and the ironic humour read inside one phrase
  of `of`); `se haga cargo de Paral.lel` is refused into English, a third person
  nobody names (on purpose; it was `one makes charge of`); and a feminine person
  noted by its noun and number makes every woman of that noun and number in the
  sentence one (`la diplomática ... la diplomática` is right, two such of
  different sexes are not). The report LEAVES, of the 16 into Italian: `soffre
  di nuovo una "polmonite"` (`di una`), `di cui si recupera soddisfacentemente`
  (`da cui si sta riprendendo`), `continua il suo andamento` (`corso`), `d'EEUU`
  (`degli Stati Uniti`), `sott'accusa di spionaggio` (`con l'accusa di`), `il
  ministro di Difesa` (`della Difesa`), `un appello all'inizio d'una nuova
  ondata` (`per l'inizio`); of the 13 into English: `the embassy of EEUU`,
  `under accusation of espionage`, `the minister of Defence`, `an appeal to the
  beginning of a new wave`, `a boost on the part of the Constitutional Court, on
  considering compatible ...`, and `has officially asked the diplomat to abandon
  the country` (to leave it); English refuses 3, 4 and 9 for the third person
  nobody names, on purpose (`de la que se recupera`, `recibe correo y estudia
  documentos`, `Este fue relevado de su cargo en el momento en que
  investigaba`). The next sample's controls take this report in.
  The islands report (VIT-9485..9510, 26 sentences, Italian into Spanish and
  English: 24 of 26 and 24 of 26 on a fresh store, 18 and 17 with the new store
  alone, 7 and 7 with the new code on the old store, 6 and 5 before; reasoning
  1.0.17). The sample was taken on the cocolog 2.11.3 binary, master's 5164d48
  and the three documentation commits after it merged as bd5803f, and cocolog
  stays 2.11.3: the binaries of 2.11.2 and 2.11.3 give the same texts and counts
  to the unit on the controls (8 267 295 355 inferences, 0 differ). The
  article's sentences fall from 297.1 million inferences into Spanish and 297.2
  into English to 100.3 and 100.1, of which the tenth, refused, is 19.6 million
  in each. It needed these SHAPES, each with its arm red (test/translate.pl's
  `newspaper_isole`: 76 checks, 81 arms, the guards among them; an arm is a
  library directory of symlinks whose reasoning/translate.pl is the edited copy,
  `COCOLOG_LIBRARY=ARM cocolog query "use_module('test/translate.pl'),
  newspaper_isole, checks_done"`, a second a run, and every arm is run in forty
  seconds, four at a time; 77 are red in the section, two more in the whole case
  and two in the controls alone, below): a street's name is a word the lesson
  says begins one and a capitalised word after it (`e Via Krupp, resa più
  agibile dopo il restauro, è frequentata come mai` is the street, and read as
  words `Via` was the adverb `away`, `y Fuera Krupp`: tr_stated_names0/2, `The
  word "via" begins the name.`, and `viale`, `piazza`, `corso`, `vicolo`); the
  first of a month is its day one (`dal primo luglio al 31 agosto` is from July
  1 to August 31, and read as an adjective of the month it was `from the first
  July`: tr_first_days/3); a preposition and a demonstrative the lesson joins
  into an adverb are the preposition and its determiner before a noun (`per chi
  ha scelto Cortina per questo fine settimana` is for this weekend, and read as
  the adverb `for this reason` the weekend was a bare noun the verb chose:
  tr_unjoin_demonstrative/3); a preposition and a free relative in front of the
  clause (`E per chi viola il divieto ci saranno multe` is fines for whoever
  breaks the ban, and the front's verb was taken for the clause's, so the
  sentence was refused: tr_read0/4, asked where the sentence has a word that
  begins the relative, `$tr_free_rel`) and a heading and the one it is for
  (`Cattive notizie, infine, per chi ha scelto Cortina per questo fine
  settimana: ...`, tr_heading_for_whom/2, asked of a statement only, `$tr_kind`)
  -- four arms, the notes among them; a participle at the head, its phrase and a
  comma, then a clause that names its subject (`Dimenticate le polemiche e messe
  da parte le idee ..., il sindaco si è dato ai servizi` -- the controversies
  forgotten, and read as the command `dimenticate` also is it was `Forget the
  controversies`: tr_read0/4), read before anything takes the commas out (with
  them out the relative clause took the mayor for the object of its intransitive
  verb, `to pause the mayor in square`), English writing the phrase and then the
  participle, the phrases of `of` and `like` after the phrase with it (`The
  ideas put aside of iron ordinances`, tr_abs_phrases/2) -- three arms; a front
  with a relative word in it is no command's (`Nessun caso a parte, invece, a
  Ponza dove la proibizione ... resta valida` is where the ban stays valid, and
  longest first the front took `resta` into the relative clause and left
  `valida`, the adjective, for the command validate!: tr_read0/4), where the
  command's word is an adjective too (a guard, below); a headline's phrase with
  its participle before a connector (`Un esodo annunciato con dovizia di cifre,
  tanto che l'osservatorio prevede ...`, and read as the clause's own
  `annunciato` had nobody to be said of: tr_join_left/5,
  tr_participle_headline/5); a main clause may open on the verb's own pronouns
  (`se i cellulari non smettono di trillare neppure in spiaggia si sono placati
  almeno i clacson dei turisti` -- with no start at `si` the piece had no
  division and was refused: tr_main_start/2); who a thing is for, and the thing
  (`A voi il calcolo del numero di cene al ristorante ...`, over to you the
  reckoning: a phrase of a preposition with a person or a pronoun, then a phrase
  with its article, tr_verbless0/3); a verb of saying with a gerund that says
  how is a reporting clause (`... primo tra tutti Emilio Fede - commenta ridendo
  -.` -- he comments, laughing, and read as a command it was `comment laughing`:
  tr_read_reporting/3); a passive with nobody named has its subject after it
  (`vengono vietati ai turisti i mezzi a motore` -- the motor vehicles are
  forbidden to the tourists, and read as an object English wrote `they are
  forbidden to the tourists the motor vehicles`: tr_passive_subject_fix/3), with
  the phrases of `of` after it (`siano esclusi dal divieto ... anche i veicoli
  (uno per nucleo familiare) di persone che ...`, tr_fo_of_run/3) -- two arms; a
  verb of saying that is also a command, with its speaker and a clause of `that`
  after it (`Assicura il sindaco Costantino Federico (e c'è da credergli) che in
  piazzetta si vede ...` -- read as the command the mayor was told to assure,
  `Asegura al alcalde`: tr_report_inv_fix/3, en_saying/1's `assures`), the
  clause's reflexive with an object the impersonal one, as after `dice che`
  (tr_report_impersonal/2), and the one who says it last, after what is said and
  a comma (`Conferma il popolare ritornello "tutti al mare, tutti al mare",
  l'analisi svolta dall'osservatorio di Milano` -- the analysis confirms the
  refrain, and it was the command `Confirm the popular refrain ..., the
  analysis`) -- five arms; a modal and an intransitive infinitive take no object
  (`Dovrebbero transitare più o meno 290 mila vetture` is the cars that should
  pass, and read by the generic reader they were what somebody should transit,
  `They should transit 290 thousand cars`: tr_read_generic/4), and a subject
  that ends at a comma, the rest read with the comma (`..., tra cui 40 mila di
  stranieri`: with the comma in no subject was found, tr_read_statement0/4) --
  two arms; digits and a number word are one count after an adverb (`più o meno
  290 mila vetture`, where `mila` read as an adjective of the noun came out `290
  miles coches`) and with nothing after them a count with its noun left out
  (`mentre altri 70 mila lasceranno la città` -- read as the noun `a thousand`
  the plural verb had no subject: tr_np/3), never where the number word is a
  noun too (a guard, below), and `another` before a count stays `another` in the
  plural (`Other 70 thousand`, tr_det_out/6) -- four arms; a command in the
  plural tries each plural the lesson states of the word (`E non contate sulla
  probabilità ...` is `no contéis` -- `cuenta` is a bill as well as counts, and
  with the bill's `cuentas` taken first the command had no Spanish:
  tr_imperative_form/4); the copula agrees with the phrase after it past an
  adverb (`Per il momento sono solo stime` is THEY are only estimates, and with
  `solo` first it came out `Soy sólo estimaciones`: tr_null_copula_agrees/4,
  tr_past_adverbs/2), a plural predicate only (a singular one says nothing of
  the subject: `erano solo un centinaio i tifosi a salutare la partenza`, the
  Lazio report's thirteenth sentence, was refused) -- two arms; the partitive
  after an infinitive of a verb of having or making is its object (`abbiamo
  cominciato a installare delle macchinette` -- some machines, and read as a
  phrase of `of` it was `to install of the machines`: tr_partitive/3, `installs`
  and `distributes` among the verbs), and the phrase with its relative clause
  (`delle macchinette che distribuiscono sacchetti`, tr_partitive_np/2) -- three
  arms; an infinitive after `di` hangs on a noun in a phrase of any preposition
  but `to` (`E non contate sulla probabilità di farla franca` is the probability
  of getting away with it, and read as the verb's the infinitive lost its `de`:
  tr_after_phrase/5, tr_noun_takes_inf/3), where the verb governs the phrase
  (`"conta" takes "su" before the phrase.`: `consentire a lupi, volpi e topi di
  fogna di circolare` was `mice of sewer of circulating` and `non mi è mai
  passato per la testa di preparare` `for the head of preparing`,
  tr_governed_here/1) -- three arms; English writes the person a verb forbids
  with no `to` before the infinitive (`proibire ai cani di passeggiare` forbids
  the dogs to stroll, and it was `forbid to the dogs to stroll`: tr_comps_out/7,
  en_person_before_inf/1), after an infinitive too -- two arms; a verb of saying
  with a person's pronoun is `tells` (`gli esperti ci dicono che ...` TELL us
  that, and English wrote `say us that`: tr_write/4), before a clause of `that`
  or an object only (a guard, below); a perfect with a time that is over is
  English's past (`una frana ... è caduta ieri pomeriggio` fell yesterday
  afternoon, and it was `has fallen`: tr_write/4, en_past_time/1), and
  `yesterday afternoon` is a day's adverb, before the verb where the clause runs
  long (en_day_adverb/1) -- two arms; a verb English too says of oneself writes
  its reflexive pronoun (`il sindaco si è dato ai servizi di pubblica utilità`
  has dedicated himself to them, and with the pronoun dropped it was `has given
  to the services`: tr_verb_across/5, tr_write/4, en_true_reflexive/1), a plural
  subject's `themselves` (en_reflexive_of/2), and a verb whose meaning the
  lesson states as a reflexive one is written with its pronoun (`si sono
  rassegnati a muoversi` is `se han resignado a moverse`, and written plain it
  was `han resignado`: tr_verb_out/4) -- four arms; a verb that ends in `to`
  takes the gerund (became resigned to MOVING, never `to to move`:
  tr_verb_ends_in_preposition/0), with the infinitive's own pronoun (infx/3),
  and a verb of stopping or keeping on takes the gerund (`i cellulari non
  smettono di trillare` do not stop RINGING, and it was `do not quit to ring`:
  en_gerund_verb/1), the clause's own infinitive only, after its adverbs (below)
  -- three arms; the adjectives after a comma agree with what there is (`ci
  saranno multe, addirittura "salate"` is `incluso "caras"`, where they agreed
  with nothing, `caros`: tr_adj_after_comma/2); an adverb of how sure stands
  after the auxiliary that opens a denied group (`non diventeranno certo aree
  pedonali` will certainly not become them, and it was `will not certainly
  become`: tr_mid_insert/3) and with the verb where nothing is denied
  (en_mid_adverb/1's `certainly`) -- two arms; an adjective of several words
  that opens on a preposition stands after its noun (`le isole in questione` are
  the islands in question, and it was `the in question islands`:
  tr_names_last/3); `some` and `no` in a denied clause are `any` (`non subirà
  alcun calo` will not undergo ANY decline: tr_det_out/6), and the lesson's
  language writes its word for `no` (`no experimentará ningún descenso`, where
  it was `algún`) -- two arms; `not even` before a phrase of a preposition is
  said of it, `even` in a denied clause (`non smettono di trillare neppure in
  spiaggia` do not stop even on the beach, and it was `in beach not even`),
  `only` the same (`soltanto nel week end`, which was written last), and `while`
  and `not` right before a gerund are the gerund's (`persone che pur non essendo
  residenti pagano la tassa` pay it while not being resident, and the two came
  last, `being resident while not`: tr_comps_out/7) -- three arms; a range takes
  the word the lesson begins it with (`dal 10 marzo al 31 ottobre` is `del 10 de
  marzo al 31 de octubre`, where the lesson's word for `from` wrote `desde`:
  `The word "de" begins the range.`), a range with `and` before its `until`
  (`già dal 14 aprile e fino al 30 settembre` is from April 14 to September 30,
  where the first phrase was `since`: tr_date_range/1), in front of the clause
  with no comma, written after the verb, in front with a comma (each front
  crossed on its own, it was `Since April 14 and until September 30`:
  tr_cross_comps/2, tr_fr_items/2, tr_fronts_out/5), with no `and`, `fino a`
  with no `and` as `to` after `from`, and between two commas (tr_mid_items/2) --
  eight arms; the adverb of a day before this one after `da` is `since` (`da
  ieri abbiamo cominciato` is since yesterday, and it was `from yesterday`:
  tr_cross_comp/2); `like` and the word for `ever` in a clause that denies
  nothing are `like never before` (`Via Krupp ... è frequentata come mai`, where
  it was `like ever`: tr_comp_out/7), and `ever` before a participle that stands
  alone in an aside is `never` (`come quella dell'estate scorsa (mai passata)`
  was `(ever happened)`: tr_aside_out/6) -- two arms; the plural of `lira` is
  `lire` (`da un minimo di 540 mila lire`, and it was `liras`:
  en_plural_pair/2), a people's name in `-ese` is its own plural (`130 mila
  milanesi` are 130 thousand Milanese, and it was `Milaneses`:
  en_plural_same/1), and `Lombard` and `Bellunese` take their capitals
  (en_nationality/1) -- three arms; two cities joined after a verb that does not
  go are `in` (`a Linate e Malpensa si aspettano 80 mila partenze`, where it was
  `to Linate and Malpensa`: tr_cities_in/2); a participle with the adjective it
  makes of its noun, between commas (`Via Krupp, resa più agibile dopo il
  restauro, è frequentata come mai` -- read as the sentence's own the street was
  set apart from its verb, `it is beautiful`: tr_asides/3), agreeing with its
  noun (where it was `rendido`, tr_aside_inner0/2), and an aside a dash opens
  and a comma closes where the sentence has no other dash (`c'è da giurare che
  Capri - off limits per i "motorizzati" dal 10 marzo al 31 ottobre, non subirà
  alcun calo` -- the comma stands for the closing dash, and the sentence was
  refused) -- three arms; and a list of bare nouns right after a preposition
  (`la proibizione per auto, moto e motorini resta valida` is the ban on cars,
  motorbikes and mopeds, and with the comma the clause's the first two were
  `motorbike car`: tr_list_commas/5) and names to the end of the piece with no
  coordinator (`nelle isole di Capri, Procida, Ischia, Giglio, Eolie` -- one by
  one the names after the first were objects of the verb, and the sentence was
  refused: tr_bare_tail/4, tr_bare_item/2), which Spanish wrote with the `a` of
  a person, `a Procida, a Ischia` -- three arms. Four arms are green in the
  section. Two are red in the whole case: an absolute clause of a perfect
  infinitive keeps its order in English (the Cecchi section's `Cioè dopo aver
  mandato in onda l'ultimo "punto di svolta".`: the first cut wrote every
  absolute clause's phrase first, and the controls had `after having the "last
  dot broadcasted of turning"`, it_9270_9295 20 -- the phrase goes first in a
  front only, tr_abs_phrases/2), and `tells` stands only before a clause of
  `that` or an object (three older checks: `te lo digo` is `I say it to you`, `A
  dirlo è Giuseppe Signori` Signori says IT, `una amichetta le ha detto di
  essere stata lei ad avvertire` she said to be HER; and the controls had `...,
  tells it` and `And why, and who tells it?`). Two are red in the controls
  alone, which no hand lesson reproduces: a count with its noun left out never
  ends on a number word that is a noun too (es_20000701-80 7, `Las obras, que
  costarán 230 millones de pesetas`, was `230 million of pesetas` and Italian
  `230 milione di pesete`, and es_20010103-139 1 `63,168 million of pesetas`),
  and the command after a front with a relative word is refused only where its
  word is an adjective too (with every such command refused, `Perché in casi
  come questi conta soprattutto il primo soccorso` -- `come` for `like` -- had
  no reading in either language, it_9381_9414 9, and the Venice report's eighth
  sentence was read again 40.2 million inferences later, `to facilitate him, I
  accumulate of the sediments`). Two guards of the first rounds had arms that
  stayed green in the section, in the whole case and in the controls (0
  sentences differ), and are gone: the main start at the reflexive word only
  (written for that Venice sentence, whose fault was the command's) and the
  command guard's verb after the relative word (written for `in casi come
  questi`, which the adjective settles); with both out the controls read every
  sentence alike and count 12 054 inferences fewer. It needed these WORDS in
  `extra/` (the two readers: a line moves the reader of one language and the
  writer of the other; the dictionary's own word is said again first where it
  must stay the one written): Italian `targa` (a number plate), `trasporto
  merci` (freight transport) and `merce` (a commodity, where the dictionary has
  the old `mercanzia` alone), `bel pò` (the source's spelling of `po'`),
  `vespaio` (an uproar), `macchinetta` (a machine; `macchina` said again first),
  `paletta` (a shovel, where the dictionary's was a bricklayer), `segatura`,
  `clacson` (one word in both numbers), `rassegna` (resigns, and becomes
  resigned to with its pronoun; `dimette` said again first), `minitaxi`,
  `vetturetta` and `a tre ruote`, `mezzo a motore` (a motor vehicle), `nettezza
  urbana` (street cleaning), `pernottamento` (an overnight stay), `depenna`
  (crosses off), `prefetto` and `milanese` (persons), `fine settimana` and `week
  end` (a weekend, not feminine), `dovizia` (abundance; `abbondanza` said again
  first), `tra cui` (among them, one preposition of two), `bellunese`, the words
  that begin a street's name (`via`, `viale`, `piazza`, `corso`, `vicolo`),
  `lira` (the currency, before the dictionary's lyre), `presto` (soon, before
  early), `a tutti i costi`, `più o meno` (one adverb of three), `comporta`
  (entails, where the dictionary's was `comports`), `svolge` (carries out,
  before performs, and takes place with its pronoun), `oscilla` (ranges),
  `transita` (transits, intransitive), `nucleo familiare` (a household), `budget
  vacanze` (the holiday budget), `la fa franca` (gets away with it), the name
  `Eolie` (the Aeolian Islands), `caso a parte` (a special case), the places
  that take `a` for `in` as a city does (`capri`, `ischia`, `procida`, `ponza`,
  `linate`, `malpensa`), `partenza` (a departure, before the exit), `tra oggi e
  domani` and `fra oggi e domani`, `senz'altro` (certainly, where `senz'` and
  `altro` were without others), `per il momento` (where Spanish wrote `para el
  momento`), `calo` (a decline, where the dictionary has the first person of
  `cala` alone), `motorizzato` (a motorist, a person; `automobilista` said again
  first), `mette da parte` (puts aside, with its forms, where `messe` was the
  masses), `dà` (gives, and dedicates with its pronoun; `dedica` said again
  first), `placa` (appeases, and calms down with its pronoun), `ha presente`
  (knows, with its forms; `sa` said again first), `smette` (stops, where the
  dictionary's was quits), `in questione` (an adjective of two words), `circola`
  (intransitive), `residente` and `invalido` (persons, and nouns, where the
  dictionary has the adjective alone), `pubblica utilità` (public utility) and
  `ieri pomeriggio` and `ieri mattina`; Spanish `matrícula`, `transporte de
  mercancías`, `bolsa` (a bag, said first), `suena` (sounds, said first, and
  rings), `claxon`, `resigna` (resigns, and becomes resigned to with its
  pronoun; `dimite` said again first), `minitaxi`, `cochecito` (a pram, said
  first, and a small car), `de tres ruedas`, `limpieza urbana`, `pernoctación`,
  `tacha` (crosses off), `prefecto` (a person), `estribillo` (a refrain, before
  the chorus), `milanés` (a person, and the adjective), `bellunés`, `fin de
  semana` (not feminine), `entre los cuales` (among them, one preposition of
  three), `lira`, `a toda costa`, `más o menos`, `conlleva` (entails), `medio
  ambiente` (the environment), `realiza` (realises, said first, and carries
  out), `recoge` (collects), `núcleo familiar`, `presupuesto de vacaciones`, `se
  sale con la suya`, the name `islas eolias`, `caso especial`, `entre hoy y
  mañana`, `peaje` (a toll, said first, and a tollgate), `por el momento`, `The
  word "de" begins the range.`, `aparta` (puts aside), `férreo`, `calma` (calms,
  and calms down with its pronoun), `"para" takes "de" before the infinitive.`
  (`no paran de sonar`), `en cuestión`, `utilidad pública` and `ayer por la
  tarde` and `ayer por la mañana`; and in the dictionaries' extras, for Italian
  `piazzetta` (square), `agibile` (accessible), `sacchetto` (bag), `trillare`
  (ring), `rassegnare` (resign), `motorino` (moped), `salato` (expensive, of a
  price: the dictionary has no `salato` at all), `vettura` (car) and `montano`
  (mountainous), read only, and `sbarco` (disembarkment), `prefetto`,
  `ritornello` (refrain) and `milanese` both ways, and for Spanish `resignar`
  (read only), `transitar` (transit, where the Italian dictionary's `passes` is
  Spanish's `transcurre`, time passing) and `ordenanza` (an ordinance, which the
  bilingual dictionary lacks). The first meaning moved for 9 Italian words and 4
  Spanish ones (Italian `presto` soon, `lira` the lira, `paletta` a shovel,
  `partenza` a departure, `comporta` entails, `oscilla` ranges, `smette` stops,
  `svolge` carries out, `transita` transits; Spanish `estribillo` a refrain,
  `lira`, `conlleva` entails, `tacha` crosses off), the writer's first word for
  5 Italian meanings and 4 Spanish ones (Italian commodity `merce`, decline
  `calo`, household `nucleo familiare`, shovel `paletta`, ranges `oscilla`;
  Spanish bag `bolsa`, environment `medio ambiente`, household `núcleo
  familiar`, collects `recoge`), and none was lost. THE CONTROLS (cocolog
  2.11.3, store KB226, 106 count files, 2 900 sentences: the earlier set with
  the Yeltsin report in, es_19991202-35, both directions; this report is not
  among them): the last version's translator against this one, on the one store,
  42 sentences in 22 files read differently, all better but one that is no worse
  -- `lire` (8: `500 thousand lire to the month`, `the million and 200 thousand
  lire the year`), Spanish's range word (8: `del 30 al 90%`, `del 24 de julio al
  25 de agosto`, `de las 500 a las 600 mil liras`, `del estado a las regiones`,
  `de juez de legitimidad a juez de mérito` twice, `de las comunicaciones al
  coche`, and the one no worse, it_9605_9636 5, `promulgado el jueves del senado
  a la Cámara`, where `varato giovedì dal senato` is passed by the senate and
  `desde el senado` was as wrong), English's past with a finished time (5: `took
  him in exam for the first time, yesterday`, `the sensation that took place ...
  yesterday`, `the Pole tried`, `Bianco remembered yesterday`, `Then the Olivo
  proposed`), `tells` (3: `I am telling you the truth`, `They have told me
  immediately`, `his friend has told her`), `any` (3: `I have not signed any
  contract`, `any other choice`, `You will not have any problem anymore`),
  `another` before a count (2: `another twenty years`, `another two, three
  years`), `certainly` with the verb (2: `It can certainly be`, `They are
  certainly too much`), `only` before its phrase (2: `only in Italy`, `only to
  the 1.4`), the gerund (2: `He also risked dying`, `Tom enjoyed playing
  baseball`), `since yesterday` and Italian `fin da ieri` (es_20010202-169 1),
  `the Japanese`, `the Lombard ones`, `does not burn even on the altar`, `the
  categories at risk` and `the motivation of both sides` -- and the inferences
  rise 0.065 % (8 282 142 493 to 8 287 552 417). Every sentence rises but 14,
  +0.37 % of the sentences under 0.2 million inferences, +0.16 % of 0.2 to 1
  million, +0.13 % of 1 to 5 million and +0.09 % of 5 to 20 million; the largest
  rises are Tempi's twentieth (+0.11 million of 517.0 in each language) and the
  Rognoni interview's nineteenth (+0.09 of 773.5), both refused, and the Venice
  report's eighth (+0.07 of 394.3), and the sentences that fall most are
  es_20000701-80 20 (`"Lo estamos reclamando desde hace 15 años", asegura.`,
  0.24 million inferences to 0.09 in each language, its text the same),
  it_9637_9672 5 (2.47 to 2.35) and the Venice report's fourth (124.5 to 124.3).
  Bytes and characters read every sentence alike (0 differ, the bytes 0.013 %
  more). The DATA COLUMN (the last version's translator on its own store, KB219,
  against this one on the new): 60 sentences in 30 files, +0.091 % (8 280 031
  535 to 8 287 552 417). THE CODE ALONE (this translator on KB219): 26 sentences
  in 16 files, +0.065 % (to 8 285 445 636), every one of them among the 42; the
  16 left are Spanish's range word and `lire`, which need the new lines. THE
  STORE ALONE (the last version's translator on KB219 and on KB226): 27
  sentences in 15 files, +0.025 % (to 8 282 142 493), all better, each a word of
  the report's lines: the Aeolian Islands (6, where `Eolie` stayed as it was),
  `medio ambiente` (3: `el director del medio ambiente`, `leyes en el medio
  ambiente`, `el Ministerio del Medio ambiente`, where it was `entorno`),
  `liras` (9, English, where they were lyres, and with the code `lire`),
  `departure` (2: `to greet the departure`, `The departure of the mission Marco
  Polo`, where it was the exit), `carry out` and `realizar` (5, where they were
  `perform` and `actuar`), `las bolsas de estudio` (where they were handbags)
  and `successivi cali`. THE FIRST ROUNDS' REGRESSIONS, found by reading the
  texts of every column and mended, each with its arm red. Of the code (the
  first round, 82 sentences in 41 files, 4 fewer read, +1.150 %): the count with
  its noun left out took a number word that is a noun too (`230 million of
  pesetas`, `63,168 million of pesetas`, `230 milione di pesete`: the guard
  above); the English absolute clause written phrase first took a perfect
  infinitive's (`after having the "last dot broadcasted of turning"`); `tells`
  was written with nothing said (`the developments of the failed renewal, tells
  it`, `who tells it?`); the gerund after a verb of keeping on was asked of
  every infinitive the clause holds (es_19990601-98 2, `la reunión que
  mantuvieron ayer con la AEB para intentar avanzar`, whose verb is `mantener`,
  keeps: `to try advancing`) and is the clause's own infinitive alone now, after
  its adverbs (tr_write/4); the noun's infinitive took a phrase its verb does
  not govern (`mice of sewer of circulating`, `for the head of preparing`:
  tr_governed_here/1); and two sentences were refused in both languages, `Perché
  in casi come questi conta soprattutto il primo soccorso` (the command guard)
  and the Lazio report's thirteenth, `erano solo un centinaio i tifosi a
  salutare la partenza` (the copula past an adverb, which agrees now with a
  plural predicate only). Of the second round (44 sentences, +1.192 %): the
  Venice report's eighth sentence, `to facilitate him, I accumulate` and 40.2
  million inferences more in each language, which the arms put on the command
  guard. Of the store (45 sentences in 26 files on the first two stores, +0.052
  %): a reflexive sense said first is the word's meaning everywhere -- `dà` as
  dedicates made every `dare` dedicate (`dargli questa soddisfazione` was
  `dedicate him this satisfaction`, `darò tutto` `I will dedicate everything`),
  and `placa`, `rassegna`, Spanish `resigna` and `calma` were the same -- so the
  plain meaning is said first now (`gives`, `appeases`, `resigns`, `calms`),
  after the dictionary's own word where the writer's word must stay (`dimette`,
  `dimite`); and `entre ellos`, the first Spanish line for `tra cui`, joined was
  read as one word, and `cuatro palestinos, entre ellos un niño de 10 años, y
  dos israelís` lost its commas (es_20010102-25 4, both languages): the line is
  `entre los cuales` now. The whole case found two more, its scans of the
  vocabularies: `fin de semana` and `fine settimana` are masculine nouns in `a`
  whose denial was missing. THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT
  (a copy of the library per rule): with the command guard mended the third
  round was +0.129 % of the controls, and its five heaviest risers into English
  (it_9637_9672 15, it_9270_9295 9, es_20020801-17 22, es_19990802-48 5,
  es_20020601-51 11, 1.7 to 45 million inferences each) rose 3 763 793
  inferences of 89.6 million (+4.20 %), 97 % of it three rules, each asked at
  every piece of every sentence: the participle at the head (2 575 609, and
  it_9637_9672 15 2.44 million to 4.68), the headline's phrase before a
  connector (843 830) and the reporting gerund (247 260). Each asks now a cheap
  test first -- the participle's front is one phrase with no mark in it and the
  rest opens on its subject (tr_opens_on_subject/2), the headline's side stands
  at the head of the piece (`$tr_piece`) with its participle among the first
  four words, the reporting clause has a gerund right after its group -- and the
  five rose 103 601 (+0.116 %). Over 24 sentences of 0.06 to 2.5 million
  inferences picked at random (10 Italian, 14 Spanish, into English) the code
  then rose 19 355 (+0.136 %), most of it two rules asked of every word of every
  sentence: the first of a month (14 964, the lexicon asked of each word for a
  month) and the preposition and demonstrative (11 427, sub_atom/5, which walks
  every position, asked of each adverb for its space). The months are a list
  made once a sentence (findall/3), and so are the words that begin the relative
  for `$tr_free_rel`, and the adverb is split with atomic_list_concat/3: the
  fourth round rose 0.065 %, where the third rose 0.129 %. What is left is no
  rule: the 24 rise 0.198 % without the one that falls (it_9967_9998 17, `80
  mila stadi`, which the count reads at once, 2.49 million to 2.45), and their
  largest rules are the first of a month (2 634 inferences in all, in 24 of
  them), the preposition and demonstrative (2 421, in 24), the count with its
  determiner (2 063, in 17), the list of bare nouns (1 641, in 11), the noun's
  infinitive (1 490, in 17), the reporting gerund (1 161, in 3), the participle
  at the head (960, in 23) and the heading for whom (879, in 23), none other
  over 600. THE STATED COSTS: a first meaning that serves the news and not every
  text -- `presto` is soon (early second), `lira` the currency (a lyre second),
  `paletta` a shovel, `partenza` a departure (an exit second), `svolge` carries
  out (performs second), `oscilla` ranges (swings second), `smette` stops (quits
  second), `comporta` entails, Spanish `estribillo` a refrain (a chorus second),
  `tacha` crosses off (lines second) -- and the writer's first word for a
  household is `nucleo familiare` and `núcleo familiar`, where it was `casa` (no
  sentence of the controls has it); Spanish writes every range with the lesson's
  word for it, `de`, so a phrase of `from` misread as a range's start is `del`
  where it was `desde` (it_9605_9636 5); and the inferences, +0.065 % on the one
  store. The report LEAVES, of the 24 into Spanish: `trascorrono` is `gastan`
  (1: the time is spent, `pasan`); the marks of `così "ammorbidito"` are lost
  and `non convince ancora i più pigri` is `no convence todavía los más
  perezosos` (2: a person's object with no `a`), and `c'è il sacrosanto diritto`
  is `hay el sacrosanto derecho` (the state copula is written after a phrase
  that opens the clause only); `in piazzetta` is `en plaza` (4 and 5: no
  article), `resa` is `rendida` and `frequentata` `es atendido` (4: frequented,
  and the street's gender lost); `se la presero tutti a male, primo tra tutti
  Emilio Fede` is `se la tomaron todos a mal, primero entre todos` (6); `da
  ieri`, in front of the clause, is written last (7: `desde ayer`), and so are
  `Presto` (8: `pronto"`), `qui` (11: `aquí`), `Per il momento` (19) and `a
  Linate e Malpensa` (23); `sebbene qui siano esclusi dal divieto` is `Aunque
  son excluidos por la prohibición` (11: the subjunctive written as an
  indicative, and excluded FROM it) and `pur non essendo residenti` `mientras no
  siendo residentes`; `per auto, moto e motorini` is `para coche, moto y
  ciclomotores` (12: the bare nouns in the singular); `l'esecuzione dei decreti
  e la sorveglianza ... è assicurato` is `la ejecución de los decretos y de la
  vigilancia` (16: the second subject read inside the phrase of `of`, which
  Spanish says again before it); `cene al ristorante` is `cenas al restaurante`
  and `da depennare sul budget vacanze` `para tachar en el presupuesto` (15);
  `diretti al Sud` is `directos al Sur` (21: heading South); `È previsto` is `Es
  previsto` (23); `ha scelto Cortina` is `ha escogido a Cortina` (24: the `a` of
  a person before a city) and `isolandola` is `aislandola`, with no accent;
  `disagi` are `malestares` (25); and `nelle isole di Capri, ..., Eolie` writes
  the name's own `Islas Eolias` after `islas` (26). Of the 24 into English: the
  subject's list after the verb is split, its first item before the verb and the
  rest after it, and `vi` is `there` at the end (1: `the vehicles of the
  residents can circulate, of those that spend ..., the cars ... utilised by
  invalids there`); `does not convince the laziest still there is` (2: no comma
  before the main clause, `yet`); `in square` (4, 5); `attended like never
  before` (4: frequented); `(never happened)` (5: an ordinance that never
  passed); `they took it everyone to badly, among everyone Emilio Fede first`
  (6: everyone took it badly, Emilio Fede first of all); `we have commenced to
  install machines that distribute bags of plastic and shovel to collect ...
  since yesterday` (7: began installing, plastic bags and scoops, `since
  yesterday` last); `one for household` and `excluded by the ban` (11: per
  household, from it), and `here` last; `in Ponza instead` (12: `instead` moved
  from its commas) and `for car, motorbike and mopeds`; `for the one that
  violates` (13, 24: whoever); `To you the calculation ... dinners to the
  restaurant ... in hotel to cross off on the holiday budget` (15); `in the
  weekend` (19); `40 thousand of direct foreigners to the South` (21: `diretti`
  agrees with the cars); `A 5 per cent of increase` (23); `finally` last of the
  heading and `isolating her yesterday afternoon` (24: it, and the time last);
  `strong unrests to the motorists` (25); and `the islands of Capri, Procida,
  Ischia, Giglio, Aeolian Islands` (26). Into both languages 9 and 10 are
  refused: 9, `Pulizia e tranquillità.`, two bare nouns joined by `e`, which the
  pinned `Pane e vino.` guard refuses on purpose, and 10, the inverted subject
  whose relative clause has a front and then an aside (`si sono placati almeno i
  clacson dei turisti che a Ischia e Procida, già dal 14 aprile e fino al 30
  settembre, si sono rassegnati a muoversi in minitaxi (...) o in autobus`; a
  reading through tr_subject/6 was tried and did not help). The next sample's
  controls take this report in.
  The satanic groups report (AnCora CESS-CAST-P-19991102-2, 17 sentences, Spanish
  into Italian and English: 15 of 17 and 13 of 17 on a fresh store, 13 and 11
  with the new store alone, 11 and 10 with the new code on the old store, 9 and
  8 before; reasoning 1.0.18). The sample was taken on the cocolog 2.11.4
  binary, master's fbda058 merged as 57f9ff2, and cocolog stays 2.11.4: the
  binaries of 2.11.3 and 2.11.4 give the same texts and counts to the unit on
  the controls (8 287 552 417 inferences, 0 differ). Master's 2.11.5, 2.11.6 and
  2.12.0 (a27ea39 to d71af1e) came during the sample; from 2.11.5 they take
  `realpath` from Cicili 3.2.0 (a9e2dcf), the checkout here is 3.1.0 (cc24ae0)
  and cicili is frozen, so they are not merged, and the next sample takes them
  when the owner moves cicili. The article's sentences fall from 59.5 million
  inferences into Italian and 59.3 into English to 20.2 and 19.9, of which the
  thirteenth, refused, is 8.2 million in each. It needed these SHAPES, each with
  its arm red (test/translate.pl's `newspaper_satan`: 37 checks, 43 arms, the
  guards among them; an arm is a library directory of symlinks whose
  reasoning/translate.pl is the edited copy, `COCOLOG_LIBRARY=ARM cocolog query
  "use_module('test/translate.pl'), newspaper_satan, checks_done"`, under a
  second a run, and every arm is run in eleven seconds, four at a time; 39 are
  red in the section, and the four that stay green are guards that stay for
  their cost, below): a participle and its agent after a noun and a phrase of
  the noun's own agree with the noun (`En la Red existen páginas en castellano
  abiertas por miembros de estas sectas` are pages in Spanish opened by members
  -- hung on the nearest noun, the language was what the members opened, the
  subject after `existen` had no reading, and the sentence was refused: tr_np/3
  with with/2 as the participle's head, and fo_np_number/2 reads its number from
  the noun), asked where the sentence has a noun or an adjective right before a
  participle with the word for `by` after it, the two disagreeing in number or
  gender (`$tr_ptc_agent`, tr_ptc_agent_note/1) -- three arms, and the note's two
  tests are guards of cost; a second agent joined to the first (`abiertas por
  miembros de estas sectas o por las mismas hermandades` -- read on as the first
  agent's adjuncts, the second was a phrase of `for`: tr_reduced_agent/3), and a
  day's adverb right after the participle stays before both agents (`il
  drammatico quadro ... presentato ieri dal ministro della famiglia ... Adriano
  Ossicini e dal direttore generale del dicastero` was `... Adriano Ossicini
  yesterday and by the general director`, tr_ptc_day_first/4, found by the
  controls) -- two arms; a modal and an infinitive with the reflexive joined, in
  the plural, with a bare phrase after it, is the reflexive's passive (`En
  algunas de ellas pueden encontrarse chats` -- chats can be found there, and it
  was `they` who could find chats:
  tr_modal_se_fix/3), never with a phrase with its article (`pueden lavarse las
  manos` is their own hands, tr_bare_head/2, a guard), and English writes a
  modal's reflexive passive as the modal and the passive infinitive (`Se pueden
  encontrar chats` -- written as the passive of the modal it was `Chats are
  caned find`: tr_write/4) -- three arms; the clause of `where` of the phrase
  after the verb, and a second phrase joined to it, are the subject's too
  (`chats (páginas de conversación) donde los adeptos se comunican y un tablón
  donde dejar anuncios diversos` can be found, each phrase with its clause:
  rc(Phrase, where, Clause), tr_where_rc/4, tr_bare_head/2 for the pair), a
  phrase's clause of `where` with an infinitive is English's `in which`
  (tr_np_out/5), and the lesson's language writes its own relative word for it,
  `dove` (tr_relative_out/5) -- six arms; a clause of `where` ends at a
  coordinator and a phrase after it (`donde los adeptos se comunican y un
  tablón`: read to the end of the words, the clause had `y un tablón` in it and
  nothing read, tr_complements0/4, cnj/1), asked where the sentence has the word
  for `where` with no comma after it and a coordinator after that
  (`$tr_where_co`, tr_where_co_note/1) and the phrase after the coordinator has
  four words at most or ends at its own word for `where` (tr_where_tail/1) --
  one arm, and the note and the tail are guards of cost; a question word before
  an infinitive asks with it (`No sé dónde dormir` is where to sleep, and read
  as the adverb `where` beside an infinitive it was `I do not know to sleep
  where`: tr_complements0/4), after a phrase English says it with `in which`
  (`un tablón donde dejar anuncios diversos` is a noticeboard in which to leave
  ads, tr_comp_out/7), and the word for `how` is the word for `like` too, and
  asks only after a verb that takes the question (`Ma parlare con Diego era
  come parlare con due persone diverse` was LIKE speaking with two different
  people, and read as the question it came out `how to speak` and `cómo
  hablar`: tr_asks_question_here/0, found by the controls; a guard, `Il cane non
  sa come dormire` is how to sleep, where it was `like sleeping`) -- four arms;
  the word for `for` after an infinitive and before one is the purpose, no verb
  (`quisiera saber qué hacer para iniciarme en el satanismo` is what to do in
  order to begin, and with `hacer` the subject and `para` the verb of `parar` it
  was `what to do stops beginning`: tr_purpose_as_verb/3), `makes` with nothing
  made is what to DO (tr_comp_out/7), and the word that asks with no phrase,
  before an infinitive, is `what` (the lesson's `qué` is `which` and `what`, and
  the infinitive's question was `which to eat`: tr_what_to/4) -- three arms; an
  infinitive with no object takes the verb of no object, where the lesson gives
  the meaning a transitive word of its own (`quisiera saber qué hacer` is
  `sapere cosa fare`, as the clause `sabe qué hace` is `sa cosa fa` -- the
  infinitive took `conoscere` whatever followed: tr_inf_lexeme/2); the past
  subjunctive of the verb of wanting, as a sentence's own verb, is a polite wish
  (`quisiera saber qué hacer` is I would like to know, and read as the imperfect
  it stands for after `si` it was he wanted to: tr_polite_wish/4), its first
  person spelled as its third (tr_form0/5), and the first person where the
  sentence names it by another word, a verb in the first person (`pues siento
  que me atrae`), English's wish `would like` (tr_write/4) and Italian's
  `vorrei`, never after a word that opens a clause (`Si quisiera dormir` is if
  he wanted, a guard) -- five arms; an adverb of time or focus after what there
  is stands with the verb (`También hay escritos de personas de Barcelona` --
  there are also writings, where `There are writings ... also` was written, and
  `ci sono anche scritti`: tr_write/4); `defines` governs `as` (`Aquelarre
  Infernal, que se define como "un punto de encuentro"` is defined AS one,
  en_governs/2), with the passive the lesson states (`"define" takes the
  passive.`); the impersonal `se` with a thing after its verb is the passive,
  where the lesson says the verb takes one (`En Internet se publica una revista
  para sus adeptos` -- a magazine is published, and English had somebody nobody
  named publish it, `One publishes a magazine`: tr_se_passive/2); English says
  what is on the Internet, a page or a site with `on` (`En esta página se
  ofrecen textos` are offered on this page, `En la Red existen páginas` exist on
  the Net: tr_comp_out/7, en_on_noun/1), and English's `the Internet`, which the
  lesson's languages name with no article (tr_np_out/5) -- two arms; an abstract
  noun in `-ism` is English's with no article (`con links contra el nazismo y el
  racismo` are links against nazism and racism, where `the nazism and the
  racism` was written: tr_write/4, en_ism_np/2), and a phrase of `of` after it
  keeps the article (`the optimism of the Russian military`, a guard) -- two
  arms; a word of two joined by a hyphen that opens on a nationality has its
  capital (`los satanistas hispanohablantes` are the Spanish-speaking satanists,
  en_nationality/1); `has` and a count of years is an age (`Tengo 14 años` is I
  am 14 years old, where English wrote `I have 14 years`: tr_write/4, age/1);
  `lleva` and a count of time is how long one has been somewhere (`Blackefer
  lleva tres años en la Red` has been on the Net for three years -- the lesson's
  `lleva` is `carries`, and English wrote `Blackefer carries three years in the
  Net`: tr_carries_time/3, the phrase of `for the past` that `desde hace`
  crosses to), and the lesson's language writes the copula and its own word for
  it (`è nella Rete da tre anni`, where it was `porta tre anni`); and a relative
  clause's plural phrase owns what its possessive names (`organizaciones
  luciferinas que tienen sus propias páginas oficiales` have THEIR own pages,
  and the lesson's first meaning wrote `his own official pages`:
  tr_plural_possessor/1). It needed these WORDS in `extra/` (the two readers: a
  line moves the reader of one language and the writer of the other; the
  dictionary's own word is said again first where it must stay the one
  written): Spanish `satánico` and `satánica` (satanic, and a satanist, a
  person), `satanista` (a satanist, a person, not feminine), `satanismo`, `cada
  vez más` (increasingly), `hispanohablante` (Spanish-speaking), `luciferino`
  and `luciferina`, `u` (or, the word for `or` before an o), `adepto` (a
  follower, a person; the dictionary has the adjective alone), with `seguidor`
  said again first, its own first meaning (a fan) and then the follower, so that
  it stays the word written for one, `hola` and `bienvenido` (the greetings, as
  interjections), `pues` (since, the conjunction, first), `web` (a website, where
  the dictionary's web is a spider's), `punto de encuentro` (a meeting point),
  `tablón` (a noticeboard, before the plank), `"define" takes "como" before the
  phrase.`, and the passive of `define`, `publica`, `ofrece` and `lee`; Italian
  `satanico` and `satanica`, `satanista` (not feminine, a person), `satanismo`,
  `sempre più` (increasingly), `ispanofono` and `ispanofona`, `luciferino` and
  `luciferina`, `ciao` and `benvenuto`, `sito web`, `visita` (visits, where the
  dictionary's verb tours), `punto di incontro`, `chat` (one word in both
  numbers, where the dictionary's plural was `chats` and its first noun for a
  chat `ciarla`), `bacheca`, `rivista` (a magazine, where the dictionary's first
  noun for one was a gun's, `caricatore`), `"definisce" takes "come" before the
  phrase.`, and the passive of `definisce`, `pubblica`, `offre` and `legge`. The
  first meaning moved for 2 Spanish words and 2 Italian ones (Spanish `tablón` a
  noticeboard, `web` a website; Italian `rivista` a magazine, `visita` visits),
  the writer's first word for 1 Spanish meaning and 4 Italian ones (Spanish
  website `web`; Italian chat `chat`, magazine `rivista`, visits `visita`,
  increasingly `sempre più`, where it was `vieppiù`), and none was lost.
  THE CONTROLS (cocolog 2.11.4, store KB230, 108 count files, 2 952 sentences:
  the earlier set with the islands report in, it_9485_9510, both directions;
  this report is not among them): the last version's translator against this
  one, on the one store, 29 sentences in 19 files read differently, all better
  but two that are no worse -- a noun in `-ism` with no article (10:
  `terrorism`, `francoism`, `nazism` and six `presidentialism`: `you answer with
  presidentialism`, `like an opening to presidentialism`), `which restated their
  basic agreement` and `il loro accordo basico` (es_20000802-31 8), the verb of
  knowing for an infinitive with no object (`ha hecho saber`, `Esperamos saber`,
  `Necessito sapere più`, `Vuoi sapere se il tuo matrimonio avrà successo?`, and
  Tatoeba's `Neither I know what to do` and `Neanche io so cosa fare`), the
  polite wish (`neither I would like to trample the feet to nobody`, Italian
  `Vorrebbe una coppa di caffè`, English `They would want`), `their problems
  can be understood only speaking with the common people` and `Can the names be
  changed of user?`, `there is also disparity` and `hay también disparidad`
  (it_9926_9946 9), `I have ended up on first page`, and the second agent with
  its day (`presented yesterday by the minister ... and by the general director`
  and `y por el director general`, where it was `desde`, it_9637_9672 8) -- and
  the two no worse: `Non posso cessare` for `No puedo parar` (Tatoeba 6, where
  `Non posso fermare` was written; neither is `fermarmi`) and `sapere` in the
  Miss World report's fifteenth sentence, whose misreading takes the object for
  the subject in both texts (`Come potranno la nostra personalità e la nostra
  capacità sapere`). The inferences rise 0.115 % (7 701 216 890 to 7 710 041
  276), 0.125 % outside the two sentences the new store reads faster (below);
  every sentence rises but four, and the largest rises are the Hotel Arts
  report's tenth (+0.19 million of 49.98, refused both ways), the Rognoni
  interview's nineteenth (+0.10 of 387.29, refused) and the Venice report's
  eighth (+0.07 of 394.36); the files that rise most are Tatoeba's into English,
  +0.46 % of 45.5 million, and the Yeltsin report's into English, +0.45 % of 6.2,
  and the sentences that fall most are the Rosi report's 26th (8.17 million to
  8.10) and it_9637_9672 14 (0.28 to 0.24). Bytes and characters read every
  sentence alike (0 differ, the bytes 0.014 % more). The DATA COLUMN (the last
  version's translator on its own store, KB226, against this one on the new): 32
  sentences in 20 files, -9.164 % (8 487 898 521 to 7 710 041 276), +0.146 %
  outside the two sentences the new store reads faster. THE CODE ALONE (this
  translator on KB226): the same 29 sentences, +0.106 % (to 8 496 894 113),
  +0.125 % outside the two. THE STORE ALONE (the last version's translator on
  KB226 and on KB230): 3 sentences in 3 files, -9.268 % (to 7 701 216 890),
  +0.021 % outside the two -- `sempre più` is one adverb now, increasingly: the
  Rognoni interview's nineteenth sentence (`il mondo sempre più complesso delle
  tv`), refused both ways, falls from 773.61 million inferences to 387.29 in
  each language, and it_9637_9672 19 from 18.2 million to 10.5, where `la
  maggioranza dei poveri sta andando sempre più sotto` is `is going ...
  increasingly below` and `está yendo cada vez más abajo`, where it was `always
  ... more below` and `siempre más abajo`; and `visited` for `toured`
  (it_9947_9966 16).
  THE FIRST ROUNDS' REGRESSIONS, found by reading the texts of every column and
  mended, each with its arm red. Of the code (the first round, 32 sentences in 21
  files, +0.519 %): the word for `how` before an infinitive asked after any verb,
  and Italian's `come`, which is `like` as well, turned two similes into
  questions (`Ma parlare con Diego era come parlare con due persone diverse` was
  `was how to speak` and `era cómo hablar`, and `È come cavalcare una tigre` `Es
  cómo cabalgar`, it_9540_9566 8 and 15: a verb that takes the question now,
  tr_asks_question_here/0); and the second agent wrote the day's adverb after
  the first (`presented by the minister ... Adriano Ossicini yesterday and by the
  general director`, it_9637_9672 8: tr_ptc_day_first/4). Of the store (a
  first store, KB229): the line that keeps `seguidor` the Spanish writer's word
  for a follower, said first, made the follower its first meaning to the reader,
  and every `seguidores` was followers (`the English followers` and `gli adepti
  inglesi` for the English fans, es_19990601-13 5; `In front of followers of the
  match` and `Davanti a adepti della partita`, es_20020801-17 5): its own first
  meaning, a fan, is said first now, and the follower after it. THE COST OF THE
  CODE, FOUND BY TAKING EACH RULE OUT (the twelve heaviest risers of the first
  round, six from Spanish and six from Italian, into English, over a copy of the
  library per rule): the first cut rose 15.04 million inferences of 232.42
  (+6.47 %), and two rules were 98 % of it -- the participle and its agent after
  a noun and its phrase, asked of every phrase with a participle in it (13.43
  million: the Hotel Arts report's tenth sentence rose 8.14 million, 49.98 to
  58.13, and its fourteenth 3.27, both refusals), and the clause of `where`
  that ends at a coordinator, asked of every word for `where` (1.25
  million: it_9472_9484 10 rose 1.19 of 5.00). What paid was a note made once a
  sentence for each (`$tr_ptc_agent`, `$tr_where_co`) and two cheap tests first:
  the participle's clause is asked only where a noun or an adjective right before
  a participle disagrees with it in number or gender (12.48 million of the
  13.43; the first note took any noun before a participle, and `debería ser
  refrendada por` fired it, so an infinitive is no noun there: 0.69 million),
  and the clause of `where` only where no comma comes after the word and the
  phrase after the coordinator has four words at most or ends at its own word
  for `where` (2.05 million; the note 0.60). The four arms that take the tests
  out stay green in the section, as a guard of cost does. The final cut rises
  0.39 million of the twelve (232.42 to 232.81, +0.17 %), the second agent most
  of it (the Hotel Arts tenth sentence +0.19 million of 49.98, its refusal the
  same). THE STATED COSTS: a first meaning that serves the news and not every
  text -- `web` is a website (a spider's web second), `tablón` a noticeboard (a
  plank second), `rivista` a magazine (a journal second), `visita` visits (tours
  second) -- and the writer's `web`, `chat`, `rivista`, `visita` and `sempre
  più` for those meanings; Italian `Non posso cessare` for Tatoeba's `No puedo
  parar` (`fermare`, the transitive word, was the one written: neither says
  `fermarmi`); `sapere` in the Miss World report's fifteenth sentence, whose
  misreading takes the object for the subject in both texts; and the inferences,
  +0.115 % on the one store and +0.106 % on the old. The report LEAVES, of the 15
  into Italian (English alike unless it says): `dalle stesse fratellanze` and
  `the same fraternities` (2: the fraternities themselves); `in alcuni di loro`
  for the pages (3: `in alcune di esse`, the pronoun's gender is the phrase's it
  stands for, which the IR does not keep), written last where the source has it
  first, and `diverse ads`; `Vorrei` with a capital after the dots (4); `Vivo`
  read as a name (5: the source has the capital); `in uno di quelli assi` and
  `that one reads in one of those boards` (6: `quelle bacheche`, that is read on
  one of those noticeboards); `scritture` for `escritos` (7: `scritti`);
  `allacciare` for `enlazar` and `in questa pagina` written last (10: link, and
  in English `curiously` last and `nazism` in small letters); `prega il suo
  androne` and `his entrance prays` for what its entrance reads, and `qui`
  written last (12); `in Internet` (14: `su Internet`) and English's `his
  followers` (its); `La Hermandad di Satán` and `His title is Pulp Fiction ...
  of La Hermandad of Satán` (15: a name of two words with its article, kept in
  Spanish, and its title); and in 16 `della Chiesa del Virus` for the third of
  the list and `Rilascio` for the liberation, English `luciferian` in small
  letters, `who has 20,000 followers` and `Release`. Into English, 8 is `who is
  defined` (which). Into English 4 and 9 are refused for the third person nobody
  names, on purpose (`me atrae poderosamente la atención` takes the attention for
  its object, and `Está abierta por un miembro` names the page by nothing), and
  into both languages 13 and 17: 13, a list with `además de` and a bracket that
  holds a clause (`(uno de ellos es de Catalunya)`), and 17, a list of names
  after a colon (`Otras webs sobre el tema son: Los Satanistas, Templo Tezcat,
  ...`). The next sample's controls take this report in.
  The Caetano Veloso interview (VIT-9225..9269, 45 sentences, Italian into
  Spanish and English: 45 of 45 and 40 of 45 on a fresh store, 34 and 31 with
  the new store alone, 18 and 18 with the new code on the old store, 17 and 16
  before; reasoning 1.0.19). The sample was taken on the cocolog 2.12.0 binary,
  master's d71af1e merged as 1fe7ecb and built with Cicili a9e2dcf from a copy
  (the owner, 2026-10-28: no pull of ../cicili, the last Cicili commit), and
  cocolog stays 2.12.0: the controls read every sentence alike on 2.11.4 and
  2.12.0 (2 952, 0 differ), 0.292 % fewer inferences (sub_atom/5's one scan).
  The article's sentences fall from 245.0 million inferences in each language to
  91.1 into Spanish and 91.2 into English, of which the fourth (`Va sottobraccio
  ...`) is 14.6 and 14.7 million. It needed these SHAPES, each with its arm red
  (test/translate.pl's `newspaper_veloso`: 71 checks, 78 arms, the guards among
  them -- 75 red in the section, one red in newspaper_units, and two guards of
  cost that stay green, below; an arm is a library directory of symlinks whose
  reasoning/translate.pl is the edited copy, `COCOLOG_LIBRARY=ARM cocolog query
  "use_module('test/translate.pl'), newspaper_veloso, checks_done"`, three
  seconds a run, and every arm is run in a minute, four at a time): a byline
  before its dateline (`Dal nostro inviato Giacomo Pellicciotti Perugia -
  passeggiando di sera ...` is the correspondent who signs the report and the
  city it comes from, with no comma between them, and the city was read as the
  name's third word: tr_byline/3); a street's name whose first word the paper
  writes small, right after a preposition (`per corso Vannucci`, where `corso`
  was the course: tr_stated_names0/2, `The word "corso" begins the name.`), and
  a name in small letters right after a common noun, which takes its capital
  (`al teatro morlacchi`); any capitalised word the lesson states as a
  contraction begins a surname before a capital (`il generale Dalla Chiesa`,
  where `de`, `del`, `di` and `da` alone did) and ends one after a first name
  (`Lucio Dalla mi ha invitato a Napoli` -- read as `da la`, from the, with
  nothing after it, the sentence was refused: tr_particle_names/4), never inside
  a title the paper writes in capitals (`il Presidente Della Repubblica` is the
  president of the Republic, a guard the controls found); an article and the
  word for `first` before the relative are a phrase and its clause (`è stata la
  prima che ho sentito` is the first one I heard, and `prima che` was the
  conjunction: tr_unjoin_ordinal/3); a phrase with no article that opens on a
  focus adverb, between two commas after a noun, is an aside, the adverb at its
  head in every language (`il boss della compagnia discografica Paramount, anche
  produttore cinematografico, ...` is the boss, also a film producer:
  tr_asides/3, advnp/2, tr_aside_out/6) -- three arms; the copula and a subject
  pronoun alone are no comment between commas (`ed è lui, senza dubbio, il
  trionfatore incontrastato del festival` says who the victor is), and a third
  person's pronoun after the copula, before a phrase with its article, is the
  subject (`è lui il trionfatore`); the word for `all` before a phrase is a
  list's word (`Pinelli, Flaiano, Zavattini e tutti gli sceneggiatori di quei
  film` is one list of four), and opens a phrase of its own number (`tutti il
  pane` is none); with nothing before the phrase a pronoun takes up again, the
  words after the verb may be its subject (`l'italiano me l'hanno insegnato
  Pinelli, Flaiano, ...` is they taught me Italian); a partitive pronoun beside
  a subject of quantity is said once (`Oggi non ce n'è rimasto più nessuno`,
  where `ne` crossed as `it`); a person named by a noun with no gender of its
  own, after a feminine article or possessive, is a woman (`la versione di una
  cantante`, `una nostra collega`); a decade named in words (`alla fine degli
  anni cinquanta` is the end of the 50s, where it was `the fifty years`); a name
  the source kept as itself is written as it stood, though English knows the
  word (`la compagnia discografica Paramount`, `kept/1`); a pronoun of quantity
  after the verb, with the partitive said once (`ne ho visti tanti fino
  all'ossessione` is I have seen so many), and the determiner `tanti` is `so
  many`; a name after the word for `with` and a bare noun for a person right
  after it say what the ones named are (`con Lucio Dalla, Fiorella Mannoia,
  Renzo Arbore e lo stilista Romeo Gigli promotori di un immaginario fanclub`
  are the promoters, role/1); a word that says how likely the sentence is stays
  in front (`Forse non le era piaciuto` is maybe she had not liked it); a
  subject before the question word, and a phrase set in front and its subject
  (`Ma la musica italiana Caetano come l'ha scoperta?` is how Caetano discovered
  Italian music, where the music, the name apposed to it, had discovered him:
  tr_dislocation_fix/3); a phrase with its relative clause set in front has the
  phrase's number (`il pane che ho, l'ho mangiato`, tr_fronted_np_number/2 --
  asked there alone: a phrase's number through its clause everywhere, the first
  cut, let `es el mensaje que ha repetido con insistencia` have the message for
  the subject of `es`, `the message that they have repeated is with insistence`,
  and read three more sentences of the controls wrong, a guard), and a phrase,
  its phrase of `of` and a relative clause said of the whole (`quel po'
  d'italiano che so, l'ho imparato al cinema`, tr_front_phrase/3); the verb of
  being about to takes its infinitive as a modal does, and the phrase after an
  intransitive one is its subject (`stava per uscire Transa` is the record that
  was about to come out) -- never between an article with its adjective and
  their noun, nor at a name apposed to a person's noun, nor at an article right
  after a name (`Va sottobraccio alla bella moglie Paola`, `con Gilda l'ex
  compagna di Vinicius De Moraes al fianco`), and only for a phrase for a
  person, as an apposition is (`circolava in Brasile la versione di una
  cantante`) -- three guards; the pronoun of the verb's own person right after
  the copula is the subject (`Ero io il re`, `decise che dovevo assolutamente
  essere io il San Francesco del film di Zeffirelli`); a count above one makes
  plural a noun that is its own plural (`Tre recital di straordinaria malia`),
  never the unit of a percentage (`pari all'87 per cento`, a guard the whole
  case found); a relative clause after the comma that closes a participle's
  aside is the phrase's (`con quella sua voce lieve, sussurrata, che è già
  musica`); a language after a verb of learning, teaching or speaking takes no
  article in English (`l'italiano me l'hanno insegnato` taught me Italian) and
  no `a` in Spanish; a verb that says what its subject remains takes no `a`
  before the phrase (`Il regista favorito resta comunque Federico Fellini`,
  `queda Federico Fellini`, en_copular/1); the word for `all` after the verb of
  a plural subject nobody names is the subject's (`Così partimmo tutti` is so we
  all left); THE ONE WHO LIKES IS ENGLISH'S SUBJECT (`Forse non le era piaciuto`
  is maybe she had not liked it, `Il cane mi piace` I like the dog: the lesson's
  languages make the thing liked the subject, and English wrote `The dog pleases
  me` or refused a clause with nobody named), the person a phrase of `to` names
  being the one the pronoun says again (`A Tom le gustan las morenas` is Tom
  likes them, where it was `He likes the dark ones to Tom`: tr_liker_phrase/2,
  found by the controls), and an infinitive liked written after `likes` (`a me
  piace stare in mezzo alla gente` is I like to be among the people -- refused,
  the infinitive having no writer as an object -- and with nobody named no `it`,
  `Me gusta comer` is I like to eat) -- five arms; A COUNTRY TAKES NO ARTICLE IN
  ENGLISH (`l'Italia è un sentimento` is Italy is a feeling, `"italia" is a
  country.`, tr_country_det/4) nor in Spanish, whose lesson does not say its
  article takes the country, as Italian's does (`"il" takes the country.`), and
  a country a relative clause hangs on keeps it (`l'Italia che soffre`,
  '$tr_keep_det'); a possessive after its noun is the phrase's determiner (`a
  casa sua`), and after another determiner `of` and the pronoun (`quella sua
  voce` is that voice of his, Spanish `esa voz suya`, tr_poss_after/3); `not
  even` stands before the phrase it is said of (`neanche uno strapuntino
  libero`), and before the object of a denied clause it is `even` (`non si trova
  nemmeno un trafiletto` does not find even a snippet, the controls' double
  denial); `big` and `small` said of a brother or a sister are `older` and
  `younger` (`mia sorella più grande`); THE PLACE ONE ARRIVES OR STAYS AT IS A
  PHRASE OF `at` (`arrivammo nel tardo pomeriggio all'Excelsior`, `i passaporti
  erano rimasti all'Excelsior`; a city or a country `in`), never a number, a
  time or a person (`rimase dal 1990 al 1995` is a range), `time` (`Tom llegó a
  tiempo`) and the phrase of the adjective of `remains` (`era rimasto ignoto al
  medioevo occidentale` is unknown TO the Middle Ages) -- guards the controls
  found; an adverb that comments on the whole clause after it is set off by its
  comma (`..., chissà`, who knows); `can` has no perfect, `has been able to`
  says it, and its participle is `been able` (`non ho potuto mangiare per un
  giorno intero`, `di non aver mai potuto incontrare Fellini`, where it was
  `caned`); `attests` governs `to`, `answers` takes its phrase bare (`ha
  risposto al telefono` answered the phone), never a bare singular noun, which
  says how (`abbiamo risposto a tema` answered to the point, a guard both
  writers keep); and `asks` takes `for` before its object (`chiedeva una copia
  del mio disco`), never before the one asked (`el gato pide que Pedro duerma`,
  a guard the whole case found) nor before the object of an infinitive after it
  (`mi ha chiesto di indicargli un'edicola` asked me to indicate a kiosk, and
  with the verb of asking still the one written it came out `to indicate him for
  a kiosk`: tr_comps_out/7 writes the object after an infinitive under the
  infinitive's verb, a rule the controls found). It needed these WORDS in
  `extra/` (the two readers: a line moves the reader of one language and the
  writer of the other; the dictionary's own word is said again first where it
  must stay the one written): Italian `natio` (native), `paesino` (a village),
  the names `Santo Amaro`, `morlacchi` and `Luna Rossa` (the song, `rossa` being
  the colour), `sottobraccio a` (arm in arm with), `incrocia` and `incontra`
  (meets, before finds), `fastidiosamente`, `trionfatore` (a victor, a person),
  `incontrastato`, `incanto` and `malia` (charm), `strapuntino` (a folding
  seat), `cantautore` (a singer-songwriter), `fanclub`, `sussurra` (whispers)
  and its participles, `sceneggiatore` (a screenwriter), `indimenticabile`,
  `regista` (a director, not feminine), `capita` (happens, intransitive, its
  perfect with the copula), `auditorio`, the copula as the auxiliary of `piace`
  and `dispiace`, `recapita` (delivers), `passeggiatrice` (a streetwalker),
  `gradisce` (appreciates), `napoletano` (Neapolitan, the adjective and the
  noun), `tragicomico`, `esule`, `boss`, `schiaffa` (throws), `mattino`,
  `provvidenziale`, `maestoso`, `cogli` (the contraction of `con gli`, read and
  not written: the identity first), the adverbs `nel tardo pomeriggio`, `per la
  seconda volta`, `per la terza volta`, `chissà` (who knows, before the
  dictionary's maybe), `a memoria` (by heart) and `di sera` (in the evening),
  the pronouns `tanti` and `tante` (so many, after the verb), `recital` (its own
  plural), `inviato` (a correspondent, a person), `per conto di` (on behalf of),
  `ce` the particle of `è`, `n'` the elision of `ne`, `po` (a bit: the tokeniser
  drops the apostrophe of `po'`), the countries, regions and continents
  (`italia`, `francia`, `germania`, `inghilterra`, `spagna`, `giappone`,
  `brasile`, `grecia`, `russia`, `israele`; `cecenia`, `catalogna`, `sardegna`,
  `sicilia`; `europa`, and `asia`, `africa` and `america` with their English
  names), `"il" takes the country.`, `"risponde" takes "a" before the phrase.`,
  `"testimonia" takes "di" before the phrase.` and `"sang" is the past of
  "sings".` (the upstream verb table's past of sing is `sung`); Spanish `del
  brazo de`, `de forma molesta`, `triunfador`, `indiscutible`, `traspuntín`,
  `cantautor`, `club de fans`, `prostituta callejera`, `napolitano`,
  `tragicómico`, `exiliado`, `providencial`, `majestuoso`, `a última hora de la
  tarde`, `por segunda vez`, `por tercera vez`, the pronoun `tantos`, `quién
  sabe`, `libre`, `corresponsal`, `en nombre de`, `de memoria`, `poco` (a bit),
  the same countries, regions and continents (`catalunya` too, and `áfrica` and
  `américa`), `ladrón` (a thief: the dictionary has the feminine `ladrona`
  alone), `natal` (native, where the writer's first was `indígena`), `por la
  noche` (in the evening), `"sang" is the past of "sings".`, and `policía` with
  a gender per sense (the police, feminine, and the policeman, masculine: the
  dictionary gives the noun no gender of its own and the builder denied the
  feminine, so the force was `el policía`). The first meaning moved for 5
  Italian words and 3 Spanish ones (Italian `chissà` who knows, `incanto` a
  charm, `inviato` a correspondent, `incontra` meets, in a line of its meaning
  alone, and `consegna` delivers, the verb's meaning said again first, its
  noun's links keeping `the delivery`; Spanish `indiscutible` undisputed,
  `natal` native, `pizca` a bit), the writer's first word for 3 Italian meanings
  and 6 Spanish ones (Italian exiled `esule`, charm `incanto`, meets `incontra`;
  Spanish free `libre`, as an adjective and as an adverb, native `natal`, bit
  `pizca`, thief `ladrón`, meets `encuentra`), and none was lost. Said again
  first, each in a line of its meaning alone, so that they stay the words
  written: Italian `nativo`, `borgo`, `bisbiglia`, `direttore`, `auditorium`,
  `consegna`, `apprezza`, `getta`, `mattina`, `corrispondente` and `pezzetto`;
  and Spanish `encuentra`, finds and then meets, so that the writer's verb for
  meets is no longer the dictionary's `conoce`; and `pizca`, not `poco`, is the
  Spanish bit. THE CONTROLS (cocolog 2.12.0, store KB236, 110 count files, 2 986
  sentences: the earlier set with the satanic report in, es_19991102-2, both
  directions; this interview is not among them): the last version's translator
  against this one, on the one store, 62 sentences in 24 files read differently,
  all better but five that are no worse -- a country, a region or a continent
  with no article (19: `Italy has had four governments`, `if Europe, in name of
  a "peace"`, `while France assigns 2 per cent ... and Germany between`, `of
  Sardinia`, `The discovery of America`, Spanish `Italia está viviendo`, `entre
  Europa y Asia`, `El descubrimiento de América`), `asks for` and the object of
  an infinitive written under the infinitive's own verb (8: `You should ask for
  the repayment`, `is also asking for the vote`, `has asked ... for a new
  deliberation`, `must search for a cause`, `I will search to illustrate a space
  mission`, where it was `to illustrate for`), the one who likes as English's
  subject (9: `he likes the good football`, `He liked this, I must say`, `Do you
  like the music?`, `She likes the freezing ones`, `Tom likes the dark ones`, `I
  like to be among the people`, `I like to walk in train`), `so many` (4),
  `arrived at` (4: `arrived at an agreement`, `if one arrives at the
  signature`), `Al Fatah` (2, where it was `To the Fatah`), `would have been
  able to` (2, where it was `caned`), `maybe` and `perhaps` in front (4), `they
  all took it`, `one does not find even a snippet` (where it was `a snippet not
  even`), and Spanish `esta negociación mía`, `queda accionista`, `nuestra
  colega` and Italian `un'applicazione Android` -- and the five no worse: `su
  asistenta de siempre` and `la boda de su parienta` (it_10059_10095 22,
  it_9800_9814 4: a woman the source names in the feminine, where `ayudante` and
  `pariente` were written), `return to his house` (it_9851_9925 48, `hers house`
  before, where `her` is the text), `I like solo only` and `Would you like the
  White House White some day?` (tat 118 and 394, as wrong as `Solo pleases me
  only` and `Would the White House please you White`). The inferences rise 0.109
  % (7 731 781 045 to 7 740 206 054); the sentence that rises most is
  it_9967_9998 22 (+1.28 million of 38.4 in each language, below), then Tempi's
  twentieth (+0.14 of 517.2, refused both ways), and the files that rise most
  are es_19991202-35's and Tatoeba's, +0.6 %. Bytes and characters read every
  sentence alike (0 differ, the bytes 0.009 % more). The DATA COLUMN (the last
  version's translator on its own store, KB230, against this one on the new): 76
  sentences in 27 files, +0.165 % (7 727 434 145 to 7 740 206 054). THE CODE
  ALONE (this translator on KB230): 44 sentences in 20 files, every one among
  the 62, +0.109 % (to 7 735 859 984). THE STORE ALONE (the last version's
  translator on KB230 and on KB236): 15 sentences in 8 files, +0.056 % (to 7 731
  781 045), all better but one -- `Africa` for `África` (5, both languages),
  `meet` for `find` (4, English: `to meet the students`, `will return to meet on
  Tuesday`, `I certainly did not think to meet the professor`, `Then I meet him
  with Cesare`), `the correspondents of "La Repubblica"` and `los
  corresponsales`, where they were envoys, `el tiempo libre`, where it was
  `gratuito`, and `del América` -- and `alle otto di sera di una domenica`, now
  `to the eight of a Sunday ... now in the evening` (it_10059_10095 7: the line
  that makes `di sera` one adverb lifts it out of the time), a stated cost. A
  FIRST STORE WAS 2.36 % DEARER FOR ONE LINE: `The article "il" takes the
  country.` teaches `article(il)` beside `take(il, country)`, and the store held
  `article(il)` three times already (the lines of the possessive and the year
  among them); tr_class_of/2 asks `G =.. [C, W], tr_solve(G)` with no once/1, so
  each copy of a class fact is one more whole reading of every `il` -- found by
  teaching KB230 with each of 17 groups of the new Italian lines and counting
  six heavy sentences of the store's risers (+20.6 % for that line, +0.8 % for
  the pronouns `tanti` and `tante`, nothing for the rest), and the line is `"il"
  takes the country.` now, which teaches `take(il, country)` alone. The words
  said again first are lines of a meaning alone for the same reason
  (`"direttore" means "director".`: no class taught twice). AN OPEN LEAD:
  tr_class_of/2 made deterministic for a bound word, and the store's two other
  copies of `article(il)` taken out, would take a large part of the cost of
  every Italian sentence away; it changes every count, and is a commit of its
  own. THE FIRST ROUNDS' REGRESSIONS, found by reading the texts of every column
  and mended, each with its arm red (test/translate.pl's 11 checks at the end of
  the section): the number of a phrase through its relative clause, asked
  everywhere (a clause of fo_np_number/2), made `es el mensaje que ha repetido
  con insistencia` `the message that they have repeated is with insistence`
  (es_20010103-120 16), Millàs' `a quien ... está "abierto"` `aperta` and an
  English with the quotation's halves out of order (es_20020301-125 13), `qué
  consecuencias` `cose conseguenze` (9) and `promesse ingannevoli` `have been
  promised` (it_9800_9814 14), and is asked of the phrase set in front alone now
  (tr_fronted_np_number/2, a guard); the liking rule wrote `He likes the dark
  ones to Tom` and refused `a me piace stare in mezzo alla gente` and `Me gusta
  andar en tren`, the infinitive liked having no writer as an object
  (tr_liker_phrase/2, an infinitive subject, and with nobody named no `it`:
  three arms); `asks for` came before the object of the infinitive after it
  (`asked me to indicate him for a kiosk`, it_9800_9814 4: tr_comps_out/7 writes
  that object under the infinitive's verb); `answers` took a bare singular noun
  bare (`we have answered topic`, `hemos contestado tema`, it_9714_9749 4: both
  writers keep its preposition, two arms); `at` after `remains` took the
  adjective's phrase (`remained unknown at the western middle ages`,
  it_9967_9998 14) and a time (`Tom arrived at time`, tat 76); `does not find
  not even a snippet` (it_9851_9925 32); a capitalised contraction inside a
  title was a name (`the president Della Repubblica`, it_9926_9946 5, both
  languages); the store's words came first for the writers -- Italian `regista`
  for every director, `incrocia` for meets, `schiaffare` for throws (which
  refused `No nos echaremos al monte`, es_20020801-17 11), `paesino` for a
  village and the bare `po` for a bit, Spanish `poco` as a noun (which refused
  es_20011002-160 5, `como pocos`) and `conoce` for meets once `incontra` meant
  it (`regresarán a conocerse`) -- now the dictionary's words said again first,
  `pizca` for the bit and `encuentra` for meets; and bytes and characters read
  five sentences apart, downcase_atom/2 leaving the accented capital of `África`
  alone under bytes (tr_downcase_units/2, and a probe in newspaper_units, its
  arm red there). THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT (the
  thirteen sentences of 0.3 to 3.6 million inferences that rose most, Italian
  into English, over a copy of the library per rule on KB230): the second cut
  was +0.566 % of the controls, and the thirteen rose 415 thousand inferences of
  12.7 million (+3.26 %), 90 % of it one rule, the pronoun of the first or the
  second person after the copula (`Ero io il re`), a clause of
  tr_read_statement0/4 that walked every piece it was asked; with a note made
  once a sentence (`$tr_pron_copula`, tr_pron_copula_note/1: the copula, such a
  pronoun and a determiner) they rose +0.47 %, and with the inverted subject of
  a phrase set in front asked only on a subject's first word
  (tr_subject_opener/1) and for sixteen words at most +0.32 % (the note's own
  scan 18 thousand of the 40 thousand left, the unjoined ordinal 8, the role
  after `with` 6). The cap was found by it_9967_9998 22, `Che poi queste cose le
  sapessero i dotti e i semplici no, guardate che ...`, whose 28 words after the
  verb were parsed for a subject at every reading: +3.14 million inferences of
  38.4 in each language, and +1.28 with the cap, the shorter pieces, the text
  the same. Both guards stay for their cost, their arms green in the section.
  THE STATED COSTS: `di sera` lifted out of a time of day (above); `"encuentra"
  means "meets".` writes `incontrare Fellini` as `encontrar a Fellini`, where it
  was `conocer`, right for a first meeting; the pronouns `tanti` and `tante`
  (+0.67 million inferences on it_9851_9925 32, `tanti altri nel nostro campo`);
  and the inferences, +0.109 % for the code and +0.056 % for the store. Master's
  2.12.1 (1c25b57, the trail and the variable map's words widened to 64 bits, in
  master as 8e63396) came during the sample; the next sample takes it. The
  interview LEAVES, of the 45 into Spanish (English alike unless it says): `amor
  para el cine` (1: `por`); `paseando por la noche para Corso Vannucci` and
  `strolling for` (3: `por`), `se encuentra a casa suya` and `finds to his
  house` (at home), `en el natal pueblo` (`en su pueblo natal`); `con Gilda a la
  ex compañera` (4: no `a`), `encuentra cariciosamente el amigo` (`saluda con
  cariño a su amigo`) and `a esposa y niños`; `like an old and expensive friend
  ever annoyingly` (5: `mai fastidiosamente` is never annoyingly, and `caro`
  dear); `al teatro Morlacchi` and `to the theatre` (7: `en el`), `tantas
  personas quedadas fuera` and `so many remained people away`; `del criticismo`
  (8: `de la crítica`); `ha sido siempre presente` and `since boy` (9); `los he
  visto todas estas películas` and `I, then, I have seen them all these films`
  (12: the object said twice); `que conozco` (14: `que sé`), `al cine` and `to
  the cinema`, `listening the dialogs`; `A 15 años` and `To 15 years` (17: `a
  los 15`), and `La strada`, a film, read as the road; 18, `Le notti di Cabiria
  è una delle cose più belle`, a film's title read as a plural phrase and set
  last (`que ha visto nunca las noches de Cabiria`); `El único grueso dolor` and
  `thick pain` (19); 20 out of order (`"Time Zones" me ha pasado cantar ... en
  Bari para el festival`); `destination` for `destino` (21); `A Voice of woman
  ... to her dedicated` (23); `Le he hecho entregar el disco a casa desde un
  amigo` and `I have made her to deliver the disc to house from a friend` (24: I
  had a friend deliver it to her home); `he sentido` and `felt` for heard (29,
  31); 33 out of order in both (`La canto aquí desde vosotros antes en Nápoles
  ... por eso hoy`, `a hopelessly mine song`); `The tale ... curious and
  tragicomic` (34: the predicate set first in the source); `the discographic
  Paramount company` (35); `desde un par de horas` and `from a pair of hours`
  (38: for a couple of hours), `quedado al Excelsior` (`en el`); `They put us to
  the six of the morning ... away` (40: let us out at six); `en Nápoles` (41:
  `a`), `they would also want` (he would like), `adesso` last; `Soy como en
  cielo` (42: `Estoy como en el cielo`); `devuelvo a niño` and `I return boy`
  (43: `vuelvo a ser niño`); `arranca al mismo` (44: `salta igualmente`); and
  `atestigua de su gran amor para Italia` (45). Into English 4, 8, 26, 28 (its
  reporting clause) and 29 are refused for the third person nobody names, on
  purpose (`Va sottobraccio ...`, `Ha vinto anche ...`, `Era stato anche
  proibito ...`, `Sorride ricordando:`, `perché è stata la prima che ho
  sentito`). The next sample's controls take this interview in.
  The Corsica report (AnCora CESS-CAST-P-20000802-26, 13 sentences, Spanish into
  Italian and English: 10 of 13 and 8 of 13 on a fresh store, 8 and 6 with the
  new store alone, 4 and 4 with the new code on the old store, 4 and 5 before;
  reasoning 1.0.20). The sample was taken on the cocolog 2.13.0 binary, built
  with Cicili 9b825b7 from a copy (master's b208233 merged as 6d98d68), and
  cocolog stays 2.13.0: the controls read every sentence alike on 2.12.1 and
  2.13.0 (3 076 sentences, 0 differ, 7 922 477 800 inferences on both). The
  article's sentences fall from 107.0 million inferences into Italian and 106.6
  into English to 37.9 and 37.5, of which the sixth, refused, is 13.4 million in
  each and the fifth, refused, 9.7. The new code on the old store reads one
  English sentence fewer than the old code, the eleventh: its clause of `that'
  is the verb's with nobody named now, which English refuses on purpose, where
  the old text was `who did not have "anything that to add"'. It needed these
  SHAPES, each with its arm red (test/translate.pl's `newspaper_corsica': 40
  checks, 34 arms, the guards among them -- 33 red, and one guard of cost that
  stays green, below; an arm is a library directory of symlinks whose
  reasoning/translate.pl is the edited copy, `COCOLOG_LIBRARY=ARM cocolog query
  "use_module('test/translate.pl'), newspaper_corsica, checks_done"', under a
  second a run, and every arm is run in four seconds, four at a time): AN
  APPOSITION WITH AN ARTICLE THAT ENDS ON A NAME, AFTER A NOUN OR AN ADJECTIVE
  IN SMALL LETTERS (`El presidente francés, el gaullista Jacques Chirac, lanzó
  ayer una seria advertencia' -- read as a heading up to the first comma, the
  clause had nobody named, which English refused: tr_asides/3), the name at its
  end what makes it one (`El perro, el gato, duerme.' stays refused, a guard),
  and `Gaullist', `Corsican' and `Mediterranean' take their capitals
  (en_nationality/1) -- three arms; A COUNTRY OR A REGION TAKES ITS ARTICLE IN A
  LESSON'S LANGUAGE THAT SAYS IT DOES (`"il" takes the country.'): `las reformas
  preconizadas para Córcega' are `per la Corsica' and `entre Inglaterra y
  Alemania' `tra l'Inghilterra e la Germania', where the bare name the source
  gave was written (tr_country_articles/2, from tr_from_ir/5 into the lesson's
  language), only for a name whose gender the lesson states (`"corsica" is
  feminine.'; `Israele' takes none), never after `in', names joined there too
  (`in Francia e Germania', which the first cut wrote `nella Francia e nella
  Germania'), after a verb of going its `to' is `in' and the name bare (`va in
  Francia', where it was `va a Francia' and the first cut wrote `va alla
  Francia'; a thing given keeps the article, `dà un libro alla Francia':
  tr_country_motion/2), the name stays bare after a phrase whose noun has its
  capital, a name's own (`el 50 aniversario de Radio Nacional de España' is `di
  Radio Nazionale di Spagna', `los elegidos de la Asamblea de Córcega' are of
  the `Assemblea di Corsica'; after a common noun it has one, `la capitale della
  Francia'), after a superlative (`el empresario petrolero más rico de Italia'
  is the `più ricco d'Italia') and alone in a bracket (`de Cremona (Italia)':
  tr_country_seq/3, tr_bare_country_after/1), and a quotation that opens on the
  name opens on the article (`sólo señaló que "España ve con simpatía la
  candidatura"' is `che "la Spagna vede', where the first cut wrote `che la
  "Spagna') -- ten arms, the guards among them; the rule is asked only of a
  sentence that crossed a name the lesson gives a meaning ('$tr_xnames'), a
  guard of cost whose arm stays green: an English text reads `Italy' as a noun
  and never meets the rule (`Italy is beautiful' is `Italia è bella' still, a
  lead); a participle between commas with its agent (`Córcega, sacudida desde
  hace años por los atentados nacionalistas, ...' was shaken BY them --
  `sacudida' is a noun too, and read as an adjunct the agent was `for the
  attacks', `per gli attentati': tr_aside_inner0/2) -- two arms; a participle
  between commas after a phrase and its phrases of `of' is the head's where it
  agrees with the head (`El plan de autonomía para Córcega, propuesto por el
  Gobierno de Jospin ...' was proposed, and hung on Corsica it was `la Corsica,
  proposta': tr_aside_head_fix/3, tr_ptc_fits/2; a guard that it must not agree
  with the last noun as well had a green arm and is gone); a quotation that
  opens on the modal (`las medidas que se adopten "deben respetar los
  principios"' must respect them, where English said they `owe to respect', and
  Italian's `"bisogna leggere ..."' is `"hay que leer"', as with no marks:
  tr_inf_after_advs/2); a small word after the first of a name of several stays
  small (`durante la reunión del Consejo de Ministros' is the Council of
  Ministers and the `Consiglio dei Ministri', where every word took its capital:
  tr_cap_words/2) -- two arms; a share of a plural after the verb agrees with a
  plural verb (`que "se imponen" una serie de reformas', which had no reading:
  tr_subject_after/5); two participles and their agents, the first agent with
  phrases of its own (`propuesto por el Gobierno de Jospin y aprobado por la
  Asamblea corsa el pasado viernes', which was refused: tr_reduced_agent/3); two
  clauses of `that' joined by a coordinator keep the comma before it (`que "se
  imponen" una serie de reformas, pero que, en todo caso, ...' lost it:
  tr_complements0/4); A VERB OF SAYING, ITS COMMA AND ONE PHRASE SET IN, THEN
  THE CLAUSE OF `que' (`al afirmar, durante la reunión del Consejo de Ministros,
  que no tenía "nada que añadir"' affirmed that he had nothing to add -- read
  left to right, the clause was the council's relative clause, `who did not
  have': tr_saying_that_fix/3), a clause with nobody named (which English
  refuses, on purpose) or with a subject of its own (`que el perro duerme' was
  `which the dog sleeps', tr_saying_that_clause/3), after `al' and its
  infinitive too, and only after a verb of saying -- four arms; an object's
  clause with an infinitive and nobody in it is `to' (`no tenía "nada que
  añadir"' has nothing to add, where English wrote `anything that to add', and
  Tatoeba's `Tom does not have anything that to lose'), and the lesson's
  language begins it with the word it states (`The word "da" begins the
  gerundive.': `niente da aggiungere', `certi lavori da fare'; tr_np_out/5) --
  two arms; a year takes no article in English (`de aquí al 2002', `hasta el
  2019' are until 2002 and until 2019: tr_year_word/1); `included' and
  `excluded' before their phrase are `including' and `excluding' (`a los
  representantes corsos, incluidos los nacionalistas':
  en_participle_preposition/2); `for the past' before a bare plural is `for'
  (`desde hace años' is for years, it_9851_9925's `amico da anni' a friend for
  years; with a count it stays, `for the past three years'); this moment, that
  one or the one takes `at' (`en este momento' is at this moment; `Navarro, en
  un momento de forma excepcional' stays in a moment of it, which the first cut
  wrote `at a moment') -- two arms; and an island takes `on' (`en la isla',
  `nelle isole del sole': en_on_noun/1).
  It needed these WORDS in `extra/' (the two readers: a line moves the reader of
  one language and the writer of the other; the dictionary's own word is said
  again first where it must stay the one written): Spanish `gaullista' (a
  Gaullist, a person of either sex), `preconiza' (recommends, with its forms;
  `recomienda' said again first), `córcega' (Corsica, a region) and `elíseo',
  `consejo de ministros' and `consejo constitucional' (names), `corso' and
  `corsa' (Corsican, the adjective and the person), `garante' (a guarantor),
  `restablecimiento' (a re-establishment), `unidad' (unity, before the unit),
  `vuelta' (a return, before the turn; `regreso' said again first), `en
  suspenso' (pending), `a fin de que' (so that, with the subjunctive), `de cara
  a' (with a view to), `de aquí a' (until), `en el transcurso de' (during;
  `durante' said again first), `eventual' (possible; `posible' said again
  first), `elegido' (an elected representative), `hace saber' (announces, with
  its forms), `sujeto' and `sujeta' (subject to), `"adopta" takes the passive.',
  `"se impone" is intransitive.', `"asamblea" is a group.', `duradero' and
  `duradera' (lasting), `señala' (signals, and indicates before a clause),
  `papel' (a role, before the paper), `desempeña' (performs, before exerts), `en
  este sentido' (in this respect) and `en todo caso' (in any case, before if
  anything); Italian `gollista', `corsica' (a region), `eliseo', `consiglio dei
  ministri' and `consiglio costituzionale', `corso' and `corsa' (Corsican; the
  dictionary's `corso', a course, said again first), `garante',
  `ristabilimento', `unità' (unity), `in sospeso' (pending), `in vista di',
  `eletto', the genders of the countries, the regions and the continents the
  lessons name (`corsica', `francia', `germania', `inghilterra', `spagna',
  `grecia', `russia', `cecenia', `catalogna', `sardegna', `sicilia', `europa',
  `asia', `africa' and `america' feminine, `giappone' and `brasile' masculine),
  `"promette" takes "di" before the infinitive.', `in ogni caso', `The word "da"
  begins the gerundive.', `in questo senso', `avvertimento' (a warning, said
  first: the dictionary's first is `ammonizione', a reprimand) and
  `trasferimento' (a transfer, before the house removal `trasloco'); and in
  eng-ita.dix `shake' (`scuotere') and, written only, `deficiency' (`carenza').
  The first meaning moved for 10 Spanish words and 2 Italian ones (Spanish
  `desempeña' performs, `duradero' and `duradera' lasting, `elegido' an elected
  representative, `en todo caso' in any case, `eventual' possible, `papel' a
  role, `sujeta' subject, `unidad' unity, `vuelta' a return; Italian `eletto' an
  elected representative, `unità' unity), the writer's first word for 3 Spanish
  meanings and 4 Italian ones (Spanish pending `en suspenso', role `papel',
  performs `desempeña'; Italian pending `in sospeso', course `corso', transfer
  `trasferimento', warning `avvertimento'), and none was lost.
  THE CONTROLS (cocolog 2.13.0, store KB244, 112 count files, 3 076 sentences:
  the earlier set with the Caetano Veloso interview in, it_9225_9269, both
  directions; this report is not among them): the last version's translator
  against this one, on the one store, 33 sentences in 20 files read differently,
  all better but one that is no worse -- the countries' articles (15: `tra
  l'Inghilterra e la Germania', `L'Inghilterra, il paese che ha prodotto la
  minigonna', `con il fermo sostegno della Germania e della Francia', `che "la
  Spagna vede con simpatia la candidatura"', `Paesi come la Germania', `altri
  luoghi della Spagna', `Anche l'Africa esiste nel calcio', `fino all'Asia',
  `svestirono la Francia', `la crescita dell'Africa', `La Francia era
  affondata', `il calcio è arrivato anche in Africa', `Con la Francia', `che ha
  vinto la Francia', Tatoeba's `La Francia confina con la Spagna'), an object's
  clause with an infinitive (5: `the temptations to resist', Tatoeba's `anything
  to lose', `some works to make', `niente da perdere', `certi lavori da fare'),
  the year with no article (3: `of 2000', `in 2001', `until 2019'), `on the
  islands' (3), `"must read"' and `"hay que leer"' for `"bisogna leggere"',
  `"must not affect"' for `"no debe afectar"', `Mediterranean', `for years' and
  `at this moment' -- and the one no worse, es_19990701-130 6, `di tutto la
  Catalogna': `de toda Catalunya' is read as `of everything' and an object, as
  before, and the object takes its article now. The inferences rise 0.006 % (7
  916 542 512 to 7 917 044 053): 2 919 sentences rise, by 80 to 200 inferences
  each, and +0.037 % of the sentences under one million; the largest rises are
  the Venice report's eighth (+16 093 of 394.5 million in each language) and
  Italian sentences with a country (es_19990601-13 1, +12 502 of 0.41 million;
  Tatoeba's 298, +10 154 of 31 263), whose cost is the articles written: counted
  over the rule's arm, six such sentences come back to within 0.02 % of the old
  counts, and writing any Italian article costs 4 500 inferences (`la') to 12
  500 (`il') -- the walk of the IR costs about 200, the writer's article the
  rest, as it costs `la casa' (a lead: tr_det_out/6 for an article is the price
  of every Italian phrase that has one). The sentences that fall most are
  it_9270_9295 9 and 24 (-25 thousand of 46 million and -17 of 14). Bytes and
  characters read every sentence alike (0 differ, the bytes 0.008 % more). The
  DATA COLUMN (the last version's translator on its own store, KB236, against
  this one on the new): 50 sentences, -0.069 % (7 922 477 800 to 7 917 044 053).
  THE CODE ALONE (this translator on KB236): 16 sentences, all better and all
  among the 33 but `anche in Africa' (the old store states no gender for a
  country, so the articles need the new lines), +0.005 % (to 7 922 890 869). THE
  STORE ALONE (the last version's translator on KB236 and on KB244): 18
  sentences, -0.075 % (to 7 916 542 512), each a word of the report's lines:
  `indicated' and `indicarono' for `señalaron que' (3), `unity' for `unidad'
  (3), `In this respect' for `En este sentido' (2), `In any case' and `En todo
  caso' for `"in ogni caso"' (2), `il suo corso' for `su curso', `le competenze
  in sospeso', `papel' for `ruolo' (2), `señalarle un quiosco' for `indicargli',
  Tatoeba's `of return' (`de vuelta') and `Mi prometteresti di seguire', and one
  worse, es_20010103-139 5, `the figure of sold unities ... 61.9 million
  unities' (a lesson line gives a word one sense in both numbers, and `unidades'
  are units); es_19990901-75 falls 6 % in each language for `en este sentido'
  read at once. THE STORE'S FIRST ROUNDS' REGRESSIONS, found by reading the
  texts of the store alone and mended: the Italian line that makes the noun
  `corso' Corsican came first for the reader, and `in corso', `nel corso della
  conferenza', `il corso di laurea' were `in Corsican' and `en corso' (13
  sentences; the dictionary's `corso' is said again first now); `"desempeña"
  means "plays".' made `desempeñar' the Spanish writer's word for every play
  (`conseguimos desempeñar nuestro fútbol', `está desempeñando con cartas', six
  sentences): the meaning is performs now, which Italian writes `svolgere'
  (`possano svolgere tutto il loro ruolo', where it was `giocare') and English
  `perform'; `en el transcurso de' was the Spanish writer's word for during (`en
  el transcurso del juicio', two sentences), and the writers' first words found
  `preconiza' the word for recommends (`El médico preconiza el descanso') and
  `vuelta' the word for a return: `durante', `recomienda' and `regreso' are said
  again first; and a line that said `pendiente' again first changed no text and
  is gone. THE CODE'S FIRST ROUNDS' REGRESSIONS, found by the one store and by
  probes of the rule, and mended, each with its arm red: the country's article
  stood outside the mark of a quotation that opened on the name (`che la "Spagna
  vede'), took the bracket of a place (`di Cremona (l'Italia)'), a name's own
  phrase (`di Radio Nazionale della Spagna'), a superlative's (`più ricco
  dell'Italia'), names joined after `in' (`nella Francia e nella Germania') and
  a verb of going's `to' (`va alla Francia'); and `at' took an indefinite moment
  (`at a moment of exceptional form', es_20001201-176 6). Two clauses of
  tr_names_only/1 in the first cut repeated an existing definition word for
  word, which the load joins to it: the arm builder found them, the edit it was
  to make occurring twice. THE COST OF THE CODE is +0.006 % on the one store,
  and its largest part is the articles the country rule writes (above); the rest
  is 80 to 200 inferences a sentence, the readers' new clauses asked and
  failing. THE STATED COSTS: a first meaning that serves the news and not every
  text -- `papel' is a role (`El papel es blanco' is `The role is white', and
  `Pedro lleva papel' `Pedro carries role'), `unidad' unity (`unidades vendidas'
  are `sold unities'), `vuelta' a return, `eventual' possible, `elegido' an
  elected representative (the participle is still `chosen') -- and the writers'
  `en suspenso' and `in sospeso' for pending (`Le questioni pendenti' is `Los
  asuntos en suspenso'), `papel' for a role and `desempeña' for performs; the
  eleventh sentence is refused into English, on purpose; and the inferences,
  +0.006 % on the one store and -0.069 % in the data column. The report LEAVES,
  of the 10 into Italian: `non devono questionare l'unità' (2: `mettere in
  discussione'); `si impone una serie di riforme' with the marks of `"se
  imponen"' lost (3, both languages: the subject read after the quoted verb
  takes it out of its marks); `rimarrà entro lei' and `remain within her' (4:
  `dentro di essa', the pronoun of a thing written as a woman's); `venerdì
  passato' (8: `lo scorso venerdì') and English `an only territorial
  collectivity' (a single); `il buon uso che fa l'Assemblea corsa dei
  trasferimenti' is right in Italian, and English writes the transfers inside
  the Assembly's phrase, `the good use that the Corsican Assembly of the
  transfers of competences makes' (9); `ai rappresentanti corsi inclusi i
  nazionalisti ha annunciato' (12: the commas around the absolute clause and the
  relative clause's close are lost -- the apposition took the comma before
  `quien', and the clause was read as a restrictive one). Into both languages 5,
  6 and 7 are refused: 5, a phrase of a preposition clefted with `es al
  Parlamento ... al que deberán ser sometidas' and `a emprender'; 6, `para ser
  deseables y necesarias' inside the quoted subject; and 7, `Poder
  legislativo.', a bare noun and an adjective, which the pinned `Big house.'
  guard refuses on purpose. English refuses 11 (`que no tenía "nada que
  añadir"') and 12 (`ha hecho saber que no defenderá') for the third person
  nobody names, on purpose. The next sample's controls take this report in.
  The child-cost report (VIT-10011..10058, 48 sentences, Panorama's report on what a child costs, Italian into Spanish
  and English: 38 of 48 and 39 of 48 on a fresh store, 33 and 32 with the new store alone, 24 and 24 with the new code
  on the old store, 20 and 20 before; reasoning 1.0.21). The sample was taken on the cocolog 2.13.0 binary, built with
  Cicili 9b825b7 from a copy (master's b208233, and the owner's merge of the Corsica report, dd8b35f, the same tree),
  and cocolog stays 2.13.0. The article's sentences fall from 312.6 million inferences into Spanish and 312.5 into
  English to 238.4 and 238.1, of which the forty-third, refused, is 66.5 million in each. It needed these SHAPES, each
  with its arm red (test/translate.pl's `newspaper_figli': 41 checks, 45 arms, 40 of them red and five guards of cost
  that stay green, below; an arm is a library directory of symlinks whose reasoning/translate.pl is the edited copy,
  `COCOLOG_LIBRARY=ARM cocolog query "use_module('test/translate.pl'), newspaper_figli, checks_done"', two seconds a
  run, and every arm is run in twenty seconds, four at a time): a word that says how plain the sentence is stays in
  front (`Naturalmente il conto sale con l'aumentare del reddito' is naturally the bill rises, and put after the verb it
  came out `The account rises ... naturally': en_head_maybe/1, `obviously' with it); a word the lesson says does not
  follow an article takes its place (`su un altro campione' is `en otro campeón', and the Spanish writer wrote `un
  otro': `"otro" does not follow "un".', tr_contract/3), and English's `an other' is `another' (en_another/2) -- two
  arms; a unit of time after `to' and its article is how often (`una famiglia che guadagna 3.500 euro netti al mese'
  earns them A MONTH, where English wrote `to the month': tr_comp_out/7), with a bracket after the unit too, and a bare
  noun and its participle alone in a bracket are said noun first (`circa 580 euro al mese (baby sitter esclusa)' is a
  month (babysitter excluded), where it was `to the month (excluded babysitter)': tr_aside_out/6) -- three arms; `takes
  into account' takes its phrase bare (`Non tengono conto per esempio della mancanza cronica di posti' does not take
  into account the lack, and the governed `of' came out `take into account of': en_bare_object/1), and so does Spanish's
  `tener en cuenta', which the lesson states with no preposition, and so is a second phrase joined to the first on the
  same preposition (`del pane o del vino' takes into account the bread or the wine, and the second kept its `of':
  tr_gov_second/4) -- two arms; `MAKES' AND AN INFINITIVE BEFORE ITS OBJECT ARE THE OBJECT AND THE BARE INFINITIVE
  (`tutti fattori che fanno impennare la bolletta figlio' make the bill soar, where English wrote `make to soar the son
  bill': tr_comps_out/7, binf/1), where the phrase is the one that does it -- the infinitive's verb, or one with its
  meaning, is one the lesson calls intransitive or whose perfect takes the copula (`fanno scattare la positività', `ha
  fatto passare la protezione'; `Le ho fatto recapitare il disco a casa da un amico' had the disc delivered, and the
  controls' first round wrote `made her the disc deliver': en_causee_infinitive/1, `The intransitive verb "impenna"
  means "soars".') -- and the phrases of `of' after the phrase go with it (`made the protection of this disease happen',
  where it was `the protection happen of this disease': tr_en_of_run/3) -- three arms; the participle of a verb English
  says with `is' is its second word, after a noun (`Cifre nate da un'indagine' are figures born of a survey, and it was
  `been born from': en_reduced_participle/2) and alone after a comma (`Cifre impressionanti, nate da un'indagine lunga e
  affidabile'), and the phrase its verb governs is marked after a participle whose perfect takes the copula, as after
  any other (Spanish's `nacidas de', where the lesson's `from' wrote `desde': tr_ptc_complements/4), and after the
  participle alone (tr_pred_governed/3) -- four arms; `it becomes' an adjective to do something (`in questo progetto
  diventa fondamentale stabilire quanto costa' -- it becomes essential to establish it, and with nobody named English
  refused it: en_null_it/2); a verb whose subject is an infinitive has none after it (`Quanto costa mantenere un
  figlio?' is how much does it cost to keep a son, and the phrase after the infinitive was the verb's subject, `How much
  does a son cost to keep?': fo_inf_subject_verb/1, en_null_it/2), where Spanish says it as Italian does -- three arms;
  the one who is fed is the object of `feeds' (`per dare da mangiare al bambino' is to feed the child, and the lesson's
  `to' came out `to feed to the boy': tr_comp_out/7), after a purpose that is the verb as well (tr_comps_out/7) -- two
  arms; THE INFINITIVE OF A VERB THAT TAKES NO OBJECT, WITH ITS PHRASE OF `OF', IS A CLAUSE OF `AS' (`con l'aumentare
  del reddito familiare cresce la spesa' as the family income increases, and read as a phrase it was `with increasing of
  the income'; `al crescere del reddito' as the income grows, where it was `to the growing of the income':
  tr_as_inf_fix/3, asked of the sentence's own clauses as the polite wish is, tr_into_ir/4), a verb the lesson calls
  intransitive or whose auxiliary is the copula, which every writer puts after the main clause with its word for `as'
  (`a medida que', `man mano che') -- two arms; an adverb at the head before a clause of `if' (`Poi se c'è bisogno della
  baby sitter, il conto sale' -- then, if there is need of one, the bill rises; the condition's reader wants its word
  first, and the sentence was refused: tr_read0/4); an adverb before a line of adjuncts (`In particolare al Nord.' -- in
  particular in the North, after the sentence that said what; an adverb and a phrase of a preposition were refused:
  tr_verbless0/3), or before a phrase that says something (`in media 230 mila euro per mantenerlo fino a 24 anni', the
  headline: tr_predicated/2), and an adverb and a phrase alone stay refused (`In media 230 euro.') -- two arms; what a
  man is and how many children he has, after the age (`il lavoro di Marino Maglietta, 64 anni, docente di fisica
  all'università di Firenze, due figli' -- his age, his post and his two children, and read as the clause's own the post
  was refused: tr_asides/3, tr_count_tail/2) -- two arms; two things a person is, joined, after the name (`Secondo
  Enrico Finzi, sociologo e presidente della società Astra, è così' -- according to him, a sociologist and president, it
  is so; read as the clause's own the two were its subject and the copula plural: tr_roles_apposition/1), the
  preposition before a name and its comma is not lifted as the adverb `second' (tr_governs_adverb/3), and the copula
  with nobody named before `thus' is `it is thus' (en_null_it/2) -- three arms; a word after a noun that is its
  adjective as well as a verb, with nothing after it but a comma, is the adjective (`Una spesa media, per una famiglia
  dell'Italia centrale ...' is an average expense, and read as the verb `media', mediates, the expense mediated:
  tr_adjective_not_verb/3, which asks the piece with its commas, '$tr_piece'), and a last word that is a noun as well as
  a verb, after an adjective it agrees with, is the noun (`E per almeno cinque buone ragioni:' is five good reasons, and
  read as `ragioni', you reason, the five were goods), where that word is the reading's own verb (a guard: `ma cambia la
  sua composizione' and `ma mangia cinque buone ragioni' end on their objects) -- three arms; the others do what a
  relative clause says (`comprare "quello che hanno anche gli altri"' is to buy what the others have too, and read with
  the relative word for the subject it was `what also have the other ones': tr_doer_np/1); the first coordinator after
  the word for `among' joins the two it takes (`Le differenze tra Nord e Sud sono tutto sommato limitate' are between
  the two, and split at `e' the South was a second subject beside the differences, whose participle took the masculine,
  `limitados': tr_conjunction_split/5), after a word of the phrase's own and in a sentence with such a word (two guards
  of cost, below); an amount after a verb of rising or falling is what it changes by (`il conto sale di circa 130 euro
  al mese' rises BY about 130 euros, and it was `rises of': tr_comp_out/7, tr_amount_np/1); a count of years after `to'
  is an age (`a 16 anni il conto mensile è di 200 euro in più' -- at 16, where English wrote `to 16 years':
  tr_comp_out/7), never in a range (`100 jóvenes de 18 a 25 años' are of 18 to 25 years, and the controls' first round
  wrote `of 18 at 25': tr_comps_out/7, rng/1) -- two arms; a phrase with one relative clause after its comma (`il
  crescente conformismo sociale, che obbliga i figli e i genitori a comprare ...' is the conformism, which obliges them,
  and divided at the comma the clause was one of `that' with nobody named, which English refused: tr_verbless0/3); and
  `spends' governs `on' (`spende in svaghi e vacanze per il figlio', where English wrote `spends in': `"spende" takes
  "in" before the phrase.', en_governs/2). The five guards of cost, their arms green: the `among' guard asked in a
  sentence with a word for `among' only ('$tr_among', tr_among_note/1) and never where the word opens the words before
  the coordinator, and the heading rule's phrase that opens on a determiner, holds no comma and has a verb in its clause
  (the cost, below). A guard that the adjective before the last word is no determiner had a green arm (`cambia la sua
  composizione' is kept by the verb's own word alone) and is gone. It needed these WORDS in `extra/' (the two readers: a
  line moves the reader of one language and the writer of the other; the dictionary's own word is said again first where
  it must stay the one written): Italian `in media' and `mediamente' (on average), the full infinitives `crescere' and
  `provenire' (the dictionary marks them read only and gives the cut forms for writing), `crescente' (increasing: the
  builder wrote it `crescee'), `mal' (badly, `male' said again first), `tutto sommato' (all in all), `fin qui' (so far),
  `di parecchio' (considerably, `considerevolmente' said again first), `aumenta' (rises, said again as a line of its
  meaning alone: the entry for `salire' in eng-ita.dix drops the dictionary's own), `retta' (a fee, with `costo' said
  again first, its own first meaning and then the fee), `porta a casa' (takes home), `riparatorio' (reparative),
  `videogioco' and `telefonino' (a form of `telefona' alone before), `metter' (the cut infinitive, the full one said
  first), `studioso' and `studiosa' (scholars, persons: the dictionary has the adjective alone), `affidamento' (custody,
  where the dictionary's first is trust; `custodia' said again first), `mancanza' (a lack, where its first is a fault;
  `carenza' said again first), `trasporto' (transport, before the carriage), `risorsa' (a resource, before the resort),
  `statistica' (statistics, the noun), `tabella' (a chart, where its first is a picture and a table is a piece of
  furniture to the Spanish writer, `mesas'; `grafico' said again first), `punto di riferimento', `fuori sede' (away from
  home), `asilo nido' (a nursery: the writer's nursery was `vivaio', a nursery of plants), `tiene conto' (takes into
  account, with `di' before the phrase), `tira su' (raises, `alza' said again first), `dà da mangiare' (feeds,
  `alimenta' said again first), `al primo posto' (in first place, `in primo luogo' said first), `sempre meno' (less and
  less), `"nasce" takes "da" before the phrase.', `svizzera' and `danimarca' (countries), `eventuale' (possible, where
  its first is eventual, a line of its meaning alone: the writer, which takes an adjective's word from a line of its
  class, wrote `sólo será posible' as `sarà soltanto eventuale' with one, passing over `possibile' for a feminine noun
  as the dictionary states it a masculine noun too), `sul campo' (in the field), `cresce' (grows with no object, and
  brings up), `uniforme' (the adjective: the dictionary has the noun alone), the association's name `crescere insieme',
  `nord' and `sud' (names that cross by their meanings), `cambia' (intransitive, and the transitive verb as well:
  below), `sale' and `impenna' (intransitive), `familiare' (family, where its first is familiar, and the noun, a
  relative, with `parente' said again first), `"spende" takes "in" before the phrase.', `nel tempo' (over time), `mette
  al lavoro' (puts to work, and sets to work with its pronoun), `tiene duro' (holds out) and `in meno' (less); Spanish
  `se dispara' (soars), `videojuego', `teléfono móvil', `en definitiva', `en promedio', `hasta aquí', `reparador',
  `lleva a casa', `tiene en cuenta', `sobre el terreno', `correctivo', `suiza' and `dinamarca', `cada vez menos', `en
  primer lugar', `punto de referencia', `fuera de casa', `"nace" takes "de" before the phrase.', `"otro" does not follow
  "un".' and `"otra" does not follow "una".', `cría' (brings up, where its first is a pup), `norte' and `sur', `con el
  tiempo', `pone a trabajar' (puts to work, and sets to work with its pronoun) and `aguanta' (holds out, its own `holds'
  said again first); and in eng-ita.dix `rise' (`salire'), `digest' (`digerire'), `mediator' (`mediatore'), `compile'
  (`compilare'), `soar' (`impennare') and `kid' (`ragazzino': `capretto', a young goat, was the Italian written for
  one), and, read only, `minor' (`minorenne'), `objective' (`oggettivo'), `suppose' (`presumere'), `house' (`ospitare')
  and `prove' (`provare'). The first meaning moved for 16 Italian words and 4 Spanish ones (Italian `affidamento'
  custody, `alza' raises, `eventuale' possible, `familiare' family, `male' badly, `mancanza' a lack, `nord' and `sud'
  North and South, `risorsa' a resource, `statistica' statistics, `studioso' and `studiosa' a scholar, `svizzera'
  Switzerland, `tabella' a chart, `trasporto' transport, and the verb `cresce' brings up beside its intransitive grows;
  Spanish `cría' brings up, `norte' and `sur', `suiza' Switzerland), the writer's first word for 4 Italian meanings and
  no Spanish one (Italian increasing `crescente', kid `ragazzino', nursery `asilo nido', scholar `studioso', where it
  was `dotto'), and none was lost (the Italian vocabulary lost `The verb "aumenta" means "rises".', which `extra/' says
  as a line of its meaning alone). THE CONTROLS (cocolog 2.13.0, store KB254, 114 count files, 3 102 sentences: the
  earlier set with the Corsica report in, es_20000802-26, both directions; this report is not among them): the last
  version's translator against this one, on the one store, 18 sentences in 16 files read differently, all better -- `a
  month', `a week' and `a year' (4: `an article a week', `500 thousand lire a month', `the twenty million a year',
  `6,000 traditional shops a year'), `another' and `otro' (6: `another million of poor', `otro millón', `otro
  continente', `otro holocausto', `one finds it another one', `se lo encuentra a otra'), `at 15' for `to 15 years',
  `obviously' and `naturally' in front (5, both languages: `Obviously one will have to read the motivations',
  `Evidentemente habrá que leer', `and naturally Vittori will be one of the lecturers', `Naturalmente ni Colombo ni sus
  enemigos'), `spends on consumptions', the causative (`which make the positivity start', `which has made the protection
  of this disease happen'), and es_20020601-51 18, refused by the last version and read now (`They thought that there is
  life without Zidane, but Senegal took charge of showing him that it is not thus') -- and the inferences rise 0.041 %
  (7 937 885 155 to 7 941 149 072). Bytes and characters read every sentence alike (0 differ, the bytes 0.009 % more).
  The DATA COLUMN (the last version's translator on its own store, KB244, against this one on the new): 34 sentences in
  24 files, -0.641 % (7 992 419 484 to 7 941 149 072). THE CODE ALONE (this translator on KB244): 15 sentences in 14
  files, every one among the 18, +0.041 % (to 7 995 685 260); the three left need the new lines (`"otro" does not follow
  "un".'). THE STORE ALONE (the last version's translator on KB244 and on KB254): 16 sentences in 14 files, all better,
  -0.682 % (to 7 937 885 155), each a word of the report's lines: `telefonino' for a mobile phone, where it was
  `telefono mobile', `over time' and `nel tempo' for `con el tiempo', `tenendo conto' for `teniendo en cuenta', where it
  was `avendo in conto', `to raise a person' and `levantar' for `tirar su', where they were `pull on' and `estirar en',
  `his relatives' and `sus parientes' for `dei suoi familiari', `the family cheques', `on average', `between North and
  South' and `entre Norte y Sur', `in the field' and `sobre el terreno' for `sul campo', where it was `on the
  countryside', and `nace del hecho'; the Rognoni interview's nineteenth sentence, refused both ways, falls 26.5 million
  inferences in each language (`tenendo conto' is a verb of the lesson now), `En primer lugar, todavía no sé si ...' 3.7
  million (one adverb now), and `con el tiempo' costs `Como prueba de que los violines ...' 1.4 million more in each,
  read as the adverb it is. THE FIRST ROUNDS' REGRESSIONS, found by reading the texts of every column and mended. Of the
  code (the one store, the first round, 20 sentences, +0.164 %): the age in a range (`100 jóvenes de 18 a 25 años' was
  `of 18 at 25'), the causative with a verb that takes an object (`Le ho fatto recapitare il disco a casa da un amico'
  was `I have made her the disc deliver') and its phrases of `of' (`made the protection happen of this disease'), each
  now with its arm red. Of the store (the store alone of the second round, 22 sentences): `cambiare' was `capsize' in
  four sentences (`must have made him capsiz idea', `The football capsized its rules', `the values are not capsized') --
  the intransitive line made `changes' the intransitive meaning, and a use with an object took the next one, so `The
  transitive verb "cambia" means "changes".' says it, as `firma''s line does for `signs'; `En primer lugar, todavía no
  sé si ...' was `Al primo posto' (`in primo luogo' said first); `dei suoi familiari' was `his families' and `sus
  familias' (the noun, a relative); and `sólo será posible' was `sarà soltanto eventuale' (the line of its meaning
  alone, above). A name line, `"mezzogiorno" is a name.', changed nothing (`rispetto al Mezzogiorno' stays the noun
  after its article, and is `frente al Mediodía' and `compared with the Midday') and is gone. THE COST OF THE CODE,
  FOUND BY TAKING EACH RULE OUT (the heaviest risers of the first round and a dozen sentences picked at random, into
  English, over a copy of the library per rule): the first cut was +0.164 % of the controls, and two rules were most of
  it -- the `among' guard, whose split blocked at `Entre la Meridiana y la calle del Coronel Sanfeliu habrá dos carriles
  ...' had failed at once, and blocked, the split at the next coordinator read left words that held the verb (2.6
  million inferences more in each language, to the same refusal in English and the same text in Italian), and whose walk
  of every preposition at every split cost long sentences 0.1 to 0.2 million; and the heading with one relative clause,
  which read every piece with a comma and a relative word after it as one phrase (0.6 million in `Ma come è accaduto, si
  dirà, che tutte le rappresentazioni ...', 0.19 in `Casotto, che ora giura ...', and `Mio dio, che tristezza!' at 1.6
  times its cost). What paid was the note made once a sentence, no guard where the word for `among' opens the left
  words, and the heading's three cheap questions first. The final cut is +0.041 %: the adverb before `if' 0.28 and 0.09
  million in two sentences (`Comunque se mai ci sarà una causa ...', a failed search before the old reading, the text
  the same), the `among' guard's changed search 0.11 and 0.05 million (`crea "delle asimmetrie tra accusa e difesa"',
  `Melina tra Polo e Olivo e il voto è più vicino'), the heading rule 0.1 million in `Lo stesso per Zdenek Zeman, che si
  dice soddisfatto ...', the adjective rule 40 thousand in a sentence of 39 million, the two roles after a name 43
  thousand, and 100 to 800 inferences a sentence elsewhere (twelve sentences picked at random). THE STATED COSTS: a
  first meaning that serves the news and not every text -- `affidamento' is custody (trust second), `mancanza' a lack (a
  fault second), `tabella' a chart (a picture second), `risorsa' a resource, `trasporto' transport, `familiare' family
  and a relative, `eventuale' possible, `studioso' a scholar, `cría' brings up (a pup second) -- and the writer's
  `ragazzino' for a kid and `studioso' for a scholar; the inferences, +0.041 % on the one store; and `tenendo conto la
  sua scarsa altezza', which Italian says `tenendo conto della' (the writer puts no `di' before the object of a verb the
  lesson says takes it, a lead). The report LEAVES, of the 38 into Spanish (English alike unless it says): `Lo pone en
  evidencia' (3: `lo revela'); `Caros niños' and `Expensive boys' (5: dear children, the pun lost); `¿Se hace pronto a
  decirlo, pero son "caros" los niños cuanto exactamente?' and `Does one make to say him soon' (6: the idiom `si fa
  presto a dirlo', it is easy to say, crosses word by word, and `quanto' is `as much'); `de la Italia central' and `of
  the central Italy' (9); `entradas netas para 5.200 euros' and `net entrances for' (11: income of); `son la fruta del
  trabajo' (15: `el fruto') and `docente de física a la universidad' and `to the university'; `who involves 40 thousand
  families' (21: the survey's clause hung on the Italians); `They add a proof on another champion of 3 thousand families
  in the field' (22: a test on another sample) and `Compare the own ones' and `Apply several statistical correctives'
  (23, 24: read as commands, and Spanish `Compara a las propias'); `the heaviest voice ... is the feeding, while there
  is the house among the indirect costs in first place, that one supposes it must be bigger' (27: the item, and `which
  is supposed to'); `asciende de aproximadamente 130 euros' (28: `en'); `the monthly account is of 200 euros compared
  with a child of 3 years at 16 extra' (29: the order of `a 16 anni' and `in più'); `brought up to the North ...
  compared with the Midday on average extra' and `criado al Norte' (31: in the North, the Mezzogiorno); `or of the
  distance of the grandfathers' (33: the second phrase after phrases of the first's own keeps its `of'), and Spanish
  `hacen dispararse el proyecto de ley hijo' (a parliamentary bill: `la factura'); `To the North in particular' (34);
  `his composition' (35: its); `while the costs of the transports rise, of the vacations, of the instruction quickly'
  (36: the phrases of `of' parted by the verb); `the parents invest you being a scarce resource more' and `os invierten'
  (42: `vi', there, read as you); and `in favour of giving to the sons too' (45: too much) and `"what the other" ones
  also have'. Into both languages 8, 17, 38, 43, 44, 46, 47 and 48 are refused: 8, the second person plural's commands
  and conditions (`Beh, se state programmando ... preparatevi a investire ... se dovrete affidarvi'); 17, a heading and
  its infinitives (`Obiettivo: modificare la normativa e introdurre in Italia ...'); 38, two sentences the source runs
  together with no full stop (`ne spende oltre 150 fin qui la fotografia, anzi il conto'); 43, the idiom `non ce la si
  fa' (refused at `ce'); 44, `Ancora e: siamo in una cultura del nuovo' (the source's `e'); 46 and 47, a colon's long
  right side (`non solo godono di ... ma hanno anche ...', `Quindi tenete duro, non spaventatevi, possibilmente non
  fermatevi a un figlio:'); and 48, Churchill's quotation (`"non c'è per nessuna comunità investimento migliore del
  metter latte dentro ai bambini"'), after `Y recordados de eso que decía Winston Churchill:' for the source's
  `ricordatevi vi'. Spanish refuses 18 and 19 as well (`diventa fondamentale stabilire quanto costa davvero crescere un
  bambino: una richiesta avanzata ...', `E un'esigenza sentita da tutti quelli che lavorano ...', which English reads),
  and English refuses 25 for the third person nobody names, on purpose (`E alla fine mette a punto un sistema ...'). The
  next sample's controls take this report in.
  The New Year's Eve report (AnCora CESS-CAST-P-20010103-85, 20 sentences, the paper's report on the night in the
  Plaza de Catalunya, Spanish into Italian and English: 19 of 20 and 19 of 20 on a fresh store, 16 and 16 with the new
  store alone, 5 and 7 with the new code on the old store, 5 and 6 before; reasoning 1.0.22). The sample was taken on
  the cocolog 2.13.0 binary, built with Cicili 9b825b7 from a copy (the branch's 292cd02, the child-cost report's
  binary), and cocolog stays 2.13.0. The article's sentences fall from 50.6 million inferences into Italian and 50.4
  into English to 20.9 and 20.3, of which the fifth (`A través de emisoras de radio, destacó que la Guardia Urbana - -
  desbordada - - solicitó en vano ...') is 6.5 million in each.
  It needed these SHAPES, each with its arm red (test/translate.pl's `newspaper_noche': 37 checks, 38 arms, 37 of
  them red in the section and one red on the store alone, below; an arm is a library directory of symlinks whose
  reasoning/translate.pl is the edited copy, `COCOLOG_LIBRARY=ARM cocolog query "use_module('test/translate.pl'),
  newspaper_noche, checks_done"', two seconds a run, and every arm is run in thirty seconds, four at a time): AN HOUR
  AFTER `to' IS `at', WITH NO ARTICLE (`que seguían en la plaza a las dos' were there at two, and English wrote `to
  the two': en_clock/2), two hours after `among' are `between' them (`entre las 4.30 y las cinco', where it was `between the 4.30
  and the five'), and the part of the day after an hour is said with its own preposition (`de la mañana' is in the
  morning, `de la madrugada' too, where it was `of the morning': en_day_part/2) -- three arms; `LA UNA' IS ONE
  O'CLOCK (`entre la una y la 1.30 de la madrugada' -- the indefinite article after the definite one had no reading as
  a count, and the sentence was refused: one/1, tr_cross_num/2, asked only of a word in a list made once a sentence of
  the words that mean the article `a', '$tr_a_lexemes'), the lesson's feminine article for `a' writes it (Spanish's
  `un' is the number one, and the count was `la un'; Italian's generic number writer took the pronoun `si' for one,
  `alla si'), elided as before a noun (`all'una', which came out `alla una': tr_the_before_one/2 in tr_opens_next/2),
  and a time in digits beside it keeps the hour's gender (`tra l'una e l'1.30', where the noun of `la 1.30' gave the
  pair no gender and Italian wrote `tra il si e l'1.30': red on the store alone, no hand lesson has the digits' noun)
  -- four arms; `TAMPOCO' IS `NOT ... EITHER' (`Tampoco ayudó el dispositivo', `pero tampoco insistimos en ella' --
  English wrote `but neither we insist on her', and Tatoeba's `Neither I know what to do': tr_write/4 writes the
  denial and `either' last); `DE FORMA' AND AN ADJECTIVE SAY HOW (`el sarao transcurrió de forma "intensa y alegre"'
  went off in an intense and cheerful manner, and English wrote `of "intense and cheerful" form': tr_comp_out/7), and
  Italian writes `in modo' (where it wrote `di forma') -- two arms -- and after a phrase of a preposition, in the
  clause or in an insertion, they are that phrase's (`Navarro, en un momento de forma excepcional, se encargó' is in a
  moment of exceptional form, and the controls' first round wrote `in a moment in an exceptional manner':
  tr_form_of_phrase/2, nform/1) -- two arms; after the verb, its adverbs or its object they still say how (`asomándose
  de forma definitiva', `come el pan de forma alegre'); A PARTICIPLE ALONE BETWEEN TWO DASHES (`la Guardia Urbana - -
  desbordada - - solicitó en vano la presencia de la policía' -- overwhelmed, it asked in vain; the one word between the
  dashes had no reading: tr_asides/3, tr_dash_phrase_end/1), after a noun and after an adjective, the last word of its
  phrase, and never a verb form, which reports the sentence (`Gallo - continua - mi ha lasciato', which the controls'
  first round read as the adjective `continuous' and lost its comment) -- three arms; A PHRASE OF `of' AFTER A PASSIVE,
  A PREDICATE OR A PARTICIPLE ENGLISH WRITES WITH `with' IS THE VERB'S (`la plaza, cubierta de botellas rotas' is
  covered WITH them, and English wrote `covered of': tr_of_passive/4, tr_of_pred/2, tr_ptc_governed/4 for a participle
  between commas, en_of_participle/1, `plants' among them) -- four arms; a phrase of `like' with no determiner right
  after a participle is the participle's (`botellas rotas utilizadas como arma' are bottles used as a weapon, where the
  phrase stood after the noun, `used bottles like weapon': tr_like_participle/2), and English writes `como' and a
  phrase with no determiner as `as', the article `a' before a thing (`as a weapon', `as an alternative', `as a
  consequence') and none before a person (`as teacher', `as barça player') -- three arms; A PARTICIPLE AFTER A COMMA
  AGREES WITH WHAT THE SOURCE SAYS IT AGREES WITH: with the phrase of a preposition, and not with the subject (`Los
  perros comen el pan de la plaza, cubierta de botellas' is the square covered, and agreeing with the subject Italian
  wrote `coperti': tr_pred_after_phrase/4, phagr/0), and an adjective with the subject, and not with the phrase
  (`Otros 20 operarios ... debían llegar entre las 4.30 y las cinco de la mañana, provistos de dos camiones' -- the
  workers are equipped, and agreeing with the morning Italian wrote `attrezzata': tr_adj_subject_comma/3, suagr/0) --
  two arms; an adjective English says with `with' takes its phrase of `of' so (`equipped with', where it was `equipped
  of': en_with_adjective/1); `AL' AND AN INFINITIVE WITH ITS REFLEXIVE PRONOUN JOINED AND A PHRASE AFTER IT (`La
  situación se complicó al generarse un círculo vicioso' -- on a vicious circle being generated; the words had no
  reading: uponse/3, read by tr_complements0/4, crossed by tr_cross_comp/2), which English writes `on', the phrase,
  `being' and the participle, and a lesson with no word for the moment writes with its gerund, the pronoun joined
  (`generandosi un circolo'); THE REFLEXIVE BEFORE A MODAL WITH A THING FOR ITS SUBJECT IS THE MODAL'S PASSIVE (`el
  tráfico no se pudo normalizar' could not be normalised, and English wrote `could not normalise'; the controls'
  `Los violines no se pueden copiar' cannot be copied: tr_modal_se_fix/3), and a person's stays his own (`Pedro no se
  pudo lavar', tr_doer_np/1) -- two arms; THE WORD FOR `everything' RIGHT AFTER THE COPULA IS ITS SUBJECT (`porque
  estaba todo sembrado de desperdicios rotos' -- because everything was strewn with them; read with nobody named, the
  copula had `todo' for its object and English refused it: tr_all_copula_fix/3, every/1), which Italian writes in front
  (`tutto era') -- two arms; THE REFLEXIVE OF THE VERB OF SEEING AND A PARTICIPLE IS A PASSIVE (`la recogida también se
  vio afectada por el accidente' was affected by it, and read as it stood the sentence had no reading or saw itself:
  tr_see_passive/2), with the adverbs before the participle the clause's and the phrase of `by' its agent -- three
  arms; `asks' for something of somebody is `asks somebody for it' (`El Ayuntamiento ha pedido un informe a la
  concesionaria FCC' asked the contractor for a report, where English wrote `asked for a report to the contractor':
  tr_comps_out/7); `other' before a count is `another' (`Otros 20 operarios' are another 20 workers: tr_det_out/6); the
  word for `even' that ends the front, right before a subject with no determiner, is said of the subject (`Ante el
  pobre despliegue, incluso representantes municipales ... mostraron su desaprobación' -- even municipal
  representatives, where English wrote `even,' between commas of its own), and the subject inside it still owns what
  its possessive names (`their': tr_focus_subject/3, tr_plural_possessor/1) -- two arms; and a noun that can say a lack
  says it before a phrase of `of' with no determiner (`La falta de agentes hasta última hora' is the lack of agents,
  where `falta' is a fault first: tr_relational_np/3).
  It needed these WORDS in `extra/' (the two readers: a line moves the reader of one language and the writer of the
  other; the dictionary's own word is said again first where it must stay the one written): Spanish `fiesta' and
  `sarao' (a celebration: the dictionary's party is the political one to the Italian writer, and `Después de la
  fiesta' was `Dopo il partito'), `concesionaria' (a contractor), `barredora' (a sweeper, the machine), `a la vista de'
  (in view of), `al margen de' (apart from, with `aparte de' said again first), `operativo' (an operation, the noun,
  with `operación' said again first), `revela' (reveals, and turns out as a reflexive: as `results' it was the word
  written for every Italian `risulta'), `grueso' (the bulk, where it was the thickness), `hasta última hora' (until the
  last moment), `según lo previsto' (as planned), `en la práctica' (in practice), `accidentado' and `accidentada'
  (eventful, where it was rugged, with `movido' and `movida' said again first), `roto' and `rota' (broken, the
  adjectives), `concejala' (a councilwoman, a person, where it was an alderwoman), `agrava' (worsens, as a reflexive),
  `activa' (activates, where it was actuates), `desalojase' (the past subjunctive in `-se', which the dictionary gives
  for reading only and the builder leaves out), the name `Cuerpo Nacional de Policía', `emisora de radio' (a radio
  station), `recogida' (a collection, the noun: the dictionary has the participle alone, and `la recogida' had no
  reading), `"desaloja" takes the passive.', `falta' (a fault, said again first, and a lack; `culpa' said again first,
  so that it stays the word written for a fault: `e che colpa abbiamo' was `qué falta tenemos'), `en vano' (in vain)
  and `trabajador' (a worker, said again first: `i lavoratori autonomi' were `operarios autónomos'); Italian `festa'
  (a celebration), `spazzatrice' (a sweeper, the noun and the adjective), `alla luce di', `fino all'ultimo momento',
  `come previsto', `in pratica', `grosso' (the bulk), `invano' (in vain: the dictionary gives it for reading only and
  wrote `in inutile'), `agente' (an officer, said again first, and an agent, where the writer's agent was
  `concessionario', a dealer), `aggrava' (worsens, as a reflexive, with `peggiora' said again first), `passa' (passes,
  its `happens' said again first: the dictionary's only verb for passes was `transita', `la festa transitò'), `stazione
  radio', `attiva' (activates), `rotto' and `rotta' (broken), `allegro' and `allegra' (cheerful: the dictionary's first
  is `allegre' of no gender, which wrote `in modo allegre'), `raccolta' (a collection, where the writer's was
  `collezione', an art collection), `incidente' (an accident, where the writer's was `accidente', bad luck) and
  `rivela' (reveals, and turns out as a reflexive); and in the dictionaries' extras, for Spanish `overwhelm'
  (`desbordar'), `sweeping' (`barredor'), `equipped' (`provisto'), `cistern' (`cisterna') and `harshly' (`duramente'),
  and, read only, `favour' (`propiciar'), `unbalance' (`descompensar'), `worker' (`operario'), `evacuate'
  (`desalojar'), `gradually' (`escalonadamente') and `slow' (`ralentizar'); for Italian `equipped' (`attrezzato'),
  `vicious' (`vizioso') and `unbalance' (`squilibrare'). The first meaning moved for 7 Spanish words and 6 Italian
  ones (Spanish `accidentada' eventful, `activa' activates, `concejala' a councilwoman, `fiesta' a celebration,
  `grueso' the bulk, `operativo' an operation, `propicia' favours; Italian `allegro' and `allegra' cheerful, `attiva'
  activates, `festa' a celebration, `grosso' the bulk, `rotta' broken), the writer's first word for 7 Spanish meanings
  and 7 Italian ones (Spanish harshly `duramente', celebration `fiesta', collection `recogida', contractor
  `concesionaria', lack `falta', overwhelms `desborda', slows `ralentiza'; Italian cheerful `allegro', accident
  `incidente', agent `agente', celebration `festa', collection `raccolta', sweeper `spazzatrice', passes `passa'), and
  none was lost.
  THE CONTROLS (cocolog 2.13.0, store KB260, 116 count files, 3 198 sentences: the earlier set with the child-cost
  report in, it_10011_10058, both directions; this report is not among them): the last version's translator against
  this one, on the one store, 29 sentences in 23 count files read differently, all better but one that is no worse --
  `as' for `como' and a phrase with no determiner (12: `as an easy explanation', `as an alternative to close on
  Saturdays', `as a signal of opening', `as a consequence of the changes', `as leader in sales', `as fatuous fires',
  `as barça player', `as a reprisal', `as a "nostalgic of the francoist regime"', `as a background', `as a maximum
  amount', `as a place of work'; and the one no worse, it_9673_9712 35, `lose an ally as signs', where both texts read
  the name Segni as a noun), `either' (5: `but we do not insist on her either', `Rivaldo and Overmars were not in
  Gandía curiously either', `but we do not go to remain like silly either', Tatoeba's `I do not know what to do
  either' and `They do not remain us eggs to us either', where it was `Neither I know what to do'), the hours (3:
  `between three and five in the afternoon', `at eight', `at six in the morning', where they were `between the three
  and the five of the afternoon', `to the eight', `to the six of the morning'), the manner (4: `in a definite manner'
  and `in modo definitivo' for `de forma definitiva', `in modo straordinario', `in modo semplice', where they were `of
  definite form' and `di forma'), `The violins cannot be copied', `is also asking the associates for the vote', and
  `everything has been clearer' and `todo ha sido más claro' for `è stato tutto più chiaro' -- and the inferences rise
  0.016 % (8 420 036 704 to 8 421 382 441). Bytes and characters read every sentence alike (0 differ, the bytes
  0.008 % more). The DATA COLUMN (the last version's translator on its own store, KB254, against this one on the
  new): 35 sentences in 28 count files, +0.046 % (8 417 506 712 to 8 421 382 441). THE CODE ALONE (this translator on
  KB254): the same 29 sentences with the same texts, +0.016 % (to 8 418 852 457). THE STORE ALONE (the last
  version's translator on KB254 and on KB260): 6 sentences in 5 count files, +0.030 % (to 8 420 036 704), each a word
  of the report's lines, all better but two that are no worse: `di raccolta di fondi elettorali' for `de recaudación
  de fondos', where it was a `collezione', and `nella raccolta' and `una raccolta d'archi' for `colección' (the two no
  worse), `la falta crónica' for `la mancanza cronica', where it was `carencia', `must be activated' for `vanno
  attivate', where it was `actuated', and Tatoeba's `un lieve incidente', where it was `accidente'. THE FIRST ROUNDS'
  REGRESSIONS, found by reading the texts of every column and mended. Of the store (round a's store alone, KB258, 25
  sentences, and round b's, KB259, 23): a line said first is the reader's word and the other language's writer's, so
  `revela' as `results' was the Spanish written for every Italian `risulta' (the plain `reveals' is said first now,
  and the reflexive `turns out' after it), and `aggrava' was written for `peggiora' (`potrebbe aggravare le cose'),
  `falta' for a fault (`qué falta tenemos' for `e che colpa abbiamo'), `operativo' for an operation, `operario' for a
  worker (`i lavoratori autonomi' were `operarios autónomos') and `accidentado' for eventful -- each now after the
  dictionary's own word said again; and the verb of passing: with `trascorre' said first for passes, Italian wrote
  `Trascorrimi il coltello', `trascorrere una macchina' and `trascorreva a guidare' for the Spanish `pasar', and
  English passed what the Italian `trascorre' spends (`to pass the own holidays', `those that pass at least seven
  days'), and a Spanish line for `pasa' passes, which round a's store needed, made English pass the evening and many
  difficulties: the Italian writer's word for passes is `passa' now, its `happens' said again first, and the other two
  lines are gone. Of the code (round a's one store, 33 sentences, +0.053 %, and round b's data column): `de forma'
  after a phrase of a preposition was the manner (`Navarro, en un momento de forma excepcional' was `in a moment in an
  exceptional manner', and round b found it again inside the insertion, whose phrases come apart), and a verb alone
  between dashes was read as the adjective it is too (`Gallo - continua - mi ha lasciato' lost its comment), each now
  with its arm red; and an arm found the first cut of the manner rule too wide, as after an object `come el pan de
  forma alegre' was `of cheerful form'. THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT (twenty sentences of the
  controls of 0.1 to 2 million inferences picked at random, ten from Spanish and ten from Italian, into English, over a
  copy of the library per rule on KB259): the first cut rose 13 490 inferences of 11.82 million (+0.114 %), and three
  rules were 84 % of it -- `la una' (6 039: tr_np/3's clause asked the determiner of the second word of every phrase of
  two), the lack (3 898: the lexeme of every noun before a phrase of `of', a determiner or not) and the phrase a
  participle's verb governs (1 356). What paid was a list made once a sentence of the words that mean the article `a',
  asked first ('$tr_a_lexemes'; asking the store of each word's meaning first left 2 544), and the lack's test of the
  phrase's determiner before the lexeme: the final cut rises 5 380 inferences (+0.046 %), `la una' 477 of them, the
  lack 910 and the governed phrase 1 356, every text of the twenty the same. THE STATED COSTS: a first meaning that
  serves the news and not every text -- `fiesta' and `festa' are a celebration (the party second: the Italian
  writer's word for a party is the political `partito'), `grueso' and `grosso' the bulk (thick second), `operativo' an
  operation, `accidentado' eventful (rugged, of ground, second), `rotta' broken (the route second) -- and the writers'
  `fiesta' and `festa' for a celebration, where they were `celebración' and `celebrazione', `concesionaria' for a
  contractor (`contratista'), `recogida' and `raccolta' for a collection (`cobro', `collezione'), `agente' for an agent
  and `passa' for passes, the store alone's 6 sentences above; `de forma' after a phrase of a preposition is that
  phrase's, so `trabaja en la empresa de forma eficaz' is `of efficient form'; the hour's gender in digits has no
  hand lesson that shows it (its arm is red on the store alone); and the inferences, +0.016 % on the one store and
  +0.030 % for the store alone. The report LEAVES, of the 19 into Italian (English alike unless it says): `la nulla
  presenza' and `the invalid presence' (1: none at all), `nella piazza della Catalogna' and `in the square of
  Catalonia' (the square's name), and `the eventful end of celebration of Nochevieja'; `the operation of cleaning of
  the square' (2: the cleaning operation); `Neanche aiutò il dispositivo' (3: `Non aiutò neanche') and `tre ore e
  mezza Dopo la festa' (the source's capital); `they highlighted' (5: the councilwoman, and English writes the subject
  nobody names as `they') and `in vain' written last; `Il 61' and `The 61' for `El 061' (7: the number loses its
  zero), `di tutto tipo' and `realised' (carried out); `The situation complicated' (8: became complicated), `non si
  potette normalizzare' (`poté'), `piantato di cascami rotti' and `planted with broken wastes' (strewn with broken
  rubbish) and `per il conflitto che registrava la piazza' and `for the conflict that registered the square' (the
  doer after a relative clause's verb: a square is no doer, and the relative word stays the subject); `il piano lavorò'
  (10: `funzionò'); `dell'alba' (11: `della notte', the dictionary's dawn for `madrugada'); `La sua funzione' and `His
  function' (12: theirs) and `quando questo si evacuava' and `when this evacuated' (the square: `questa', the
  subjunctive and the passive, which the demonstrative pronoun does not reach); `Davanti alla povera distribuzione'
  (13: `dispiegamento') and `che seguivano nella piazza' and `that followed in the square' (who were still there);
  `segnalò Frigola' written last (14), `Frigola signalled' (pointed out) and `two trucks of collection'; `in Ciutat
  Vella' written last (17) and `a truck of rubbishes'; `Le denunce civiche' (18: the citizens' complaints) and `the
  morning of the day 1'; and `dell'accadimento popolare' (20: `dell'evento'). Into Italian 16 is refused and into
  English it is `They had served the 10 installed containers in the zone of little': the idiom `De poco habían servido'
  (were of little use), read with `servir' transitive and nobody named. English refuses 3 for the third person nobody
  names, on purpose: the subject after the verb (`Tampoco ayudó el dispositivo de Mantenimiento y Servicios, que ...')
  is read as its object. The next sample's controls take this report in.
  The Spoleto and Torvaianica reports (VIT-9205..9224, 20 sentences: the Spoleto festival's closing concert and a
  hearing of the trial for a girl run over in Torvaianica, Italian into Spanish and English: 17 of 20 and 14 of 20 on a
  fresh store, 15 and 12 with the new store alone, 10 and 8 with the new code on the old store, 8 and 7 before;
  reasoning 1.0.23). The sample was taken on the cocolog 2.13.0 binary, master's 450b7a0 merged as 50e0b01 (CI, its
  verdict script and the install scripts, no change to the binary), and cocolog stays 2.13.0; master's b8812f4 and
  d06692a (the Intel Mac's CI job and its record, no change to the binary) came during the sample and are merged after
  it. The article's sentences fall from 35.1 million inferences in each language to 10.8 into Spanish and 10.9 into
  English, of which the tenth, refused, is 4.0 million in each.
  It needed these SHAPES, each with its arm red (test/translate.pl's `newspaper_spoleto': 21 checks, 19 arms, 17 red in
  the section, one in newspaper_wapo and one guard of cost that stays green, below; an arm is a library directory of
  symlinks whose reasoning/translate.pl is the edited copy, `COCOLOG_LIBRARY=ARM cocolog query
  "use_module('test/translate.pl'), newspaper_spoleto, checks_done"', two seconds a run): A VERB WITH A PERSON FOR ITS
  OBJECT CROSSES BY THE MEANING THE LESSON GIVES IT THERE (`la Bx ha investito la ragazza' ran the girl over, and with
  `investe' `invests' first it was `has invested the girl' and `ha invertido la niña': `The personal verb "investe"
  means "runs over".', a class linked as the infinitival one is, tr_mean_links/3, tr_verb_across/5, the lesson's verbs
  that have one found once a sentence, '$tr_personal'), never with a thing for its object (`Il dottore investe il
  denaro' invests it, tr_person_object/1, a guard), and the participle said of a person crosses so too (`la ragazza
  investita a Torvaianica', tr_cross_np/2) -- four arms; English writes the participle of a verb of several words after
  its noun (`the girl run over in Torvaianica', where it was `the run over girl': tr_np_out/5); a phrase with its
  participle after it is of its head's class, so the person keeps the `a' Spanish puts before one (`ha atropellado a la
  niña quinceañera molestada poco antes': tr_of_class/2), never a word that replaces the noun (`ve el conducido por el
  gato', which the whole case found as `al conducido', its arm red in newspaper_wapo) -- two arms; ITALIAN'S ORDINAL IN
  DIGITS IS ONE WORD WITH ITS SIGN (`la 38-ma edizione del festival' is the 38th edition, and the tokeniser dropped the
  hyphen and left `ma', the word for `but', `el 38 pero edición': tr_number_written/4, `-ma' and `-me' `ª', `-mo' and
  `-mi' `º', the sign's codes the atom's own in each unit, a probe in newspaper_units); the word for `more' between an
  article and a participle, in a phrase of a preposition, the noun left out (`è stata fra le più eseguite' is among the
  most performed, and the phrase of `fra' ended at its article: tr_phrase_words0/4); A RUN OF CAPITALISED WORDS THAT
  OPENS ON A NAME IS ONE NAME, whatever the words after it are (`La Spoleto Festival Orchestra sarà diretta da ...',
  refused, `orchestra' a noun of the determiner: tr_np/3), the name first a guard of cost (an arm that takes any run of
  capitals reads every sentence of the controls alike for 0.35 % more inferences) and the second word's capital asked
  before the name's lookup (below); the copula with `thus' alone in front and nobody named is `it is thus' in English
  (`se così fosse stato, la Bx ... avrebbe subìto una decelerazione' is if it had been thus, and with the front written
  apart English refused it: tr_write/4); a verb of saying with a person's pronoun and an infinitive right after it is
  `tells' (`il mio fratellino mi disse di stare attento' told me to take care, where it was `said me to'); THE AGENT
  BEFORE ITS PARTICIPLE, WITH NO PHRASE BEFORE THEM, IS A FRAGMENT (`C'era la ragazza. da me vista troppo tardi".' --
  seen by me too late, and read as a statement `vista' was what `vistare' says, `Aprueba demasiado tarde desde mí':
  tr_read0/4 asks it first for such a piece, tr_verbless0/3 takes the participle by its form, `vista' the view too) --
  two arms; a capitalised word after a title is the name's though the lesson knows it (`il dottor Lombardi' is the
  doctor, `lombardi' the plural of `lombardo', and it was `the Lombard doctor': tr_stated_names0/2, `"dottore" is a
  title.'); a phrase after the comma that closes the subject set after a passive verb is the subject's apposition (`Sarà
  ascoltato il dottor Lombardi, il primo medico ad intervenire dopo la tragedia' -- a passive takes no object, and read
  as one it was `al primer médico' and `to the first doctor', and `la tesi del perito della difesa, a Italo Fainelli':
  tr_passive_subject_fix/3, appos/1); and the event one is at is a phrase of `at' (`Al processo di Torvajanica smentito
  Said' was denied AT the trial, where it was `to the trial': tr_comp_out/7, en_event_noun/1), never after a verb that
  goes there (`va al concerto', tr_motion_verb/1, a guard).
  It needed these WORDS in `extra/' (the two readers: a line moves the reader of one language and the writer of the
  other; the dictionary's own word is said again first where it must stay the one written): Italian `messa da requiem'
  (a requiem mass, one noun of three words: as two the mass was the dough, `la masa desde réquiem'), `domani sera'
  (tomorrow evening), `imponenza' (magnificence), `lavavetri' (a windscreen washer, a person, its own plural),
  `semaforo' (a traffic light, where it was a semaphore), `si guadagna da vivere' (earns a living), `quindicenne'
  (fifteen-year-old), `fratellino' (a little brother), `sta attento' (takes care), `perito' (an expert, a person;
  `esperto' said again first), `stritola' (crushes, with its forms; `schiaccia' said again first), `in aula' (in court),
  `sbanda' (skids, intransitive), `ribatte' (retorts; `replica' said again first), `urto' (an impact; `impatto' said
  again first), `subìto' (the participle of `subisce' with its accent), `dottor' (the apocope of `dottore') and
  `"dottore" is a title.', `prossimo' and `prossima' (next before forthcoming), `udienza' (a hearing before an audience;
  `udito' said again first), `The personal verb "investe" means "runs over".' (`invests' said first), `nel momento in
  cui' (when), `non a caso' (not by chance), `concerto di chiusura' (a closing concert, not feminine), `muove i primi
  passi' (takes the first steps), `poco prima' (shortly before), the cities `Spoleto', `Torvajanica', `Torvaianica' and
  `Casalpalocco', and the name `colonia' (Cologne, a city); Spanish `misa de réquiem', `mañana por la noche',
  `limpiacristales', `semáforo' (a traffic light), `se gana la vida', `quinceañero' and `quinceañera', `hermanito',
  `tiene cuidado', `derrapa' (skids), `atropella' (runs over, with its forms: the dictionary's entry is of two English
  words, which the builder takes none of), `audiencia' (a hearing, after the audience), `no por casualidad', `concierto
  de clausura' (not feminine), `da los primeros pasos', `desaceleración' (the dictionary has none), `poco antes' and the
  name `colonia' (Cologne; Spanish states no city). The first meaning moved for 5 Italian words and 2 Spanish ones
  (`colonia' Cologne, `prossimo' and `prossima' next, `semaforo' a traffic light, `udienza' a hearing; `colonia' and
  `semáforo'), the writer's first word for 1 Spanish meaning (a hearing, `audiencia', where it was `oído'), and none was
  lost.
  THE CONTROLS (cocolog 2.13.0, store KB265, 118 count files, 3 238 sentences: the earlier set with the New Year's Eve
  report in, es_20010103-85, both directions; these reports are not among them): the last version's translator against
  this one, on the one store, 1 sentence reads differently, and better (it_9567_9604 10, `at the Roman meeting where
  Parisi has fought', where it was `to the Roman meeting') -- and the inferences rise 0.025 % (8 463 428 563 to 8 465
  515 390). Bytes and characters read every sentence alike (0 differ, the bytes 0.008 % more). The DATA COLUMN (the last
  version's translator on its own store, KB260, against this one on the new): 17 sentences in 8 files, +0.035 % (8 462
  547 227 to 8 465 515 390). THE CODE ALONE (this translator on KB260): 1 sentence, the one above, +0.025 % (8 462 547
  227 to 8 464 630 962), the largest rises Tempi's twentieth (+0.28 million of 517.5, refused both ways), the Venice
  report's eighth (+0.10 of 394.6) and it_9816_9850 25 (+0.05 of 26.6), the 3 232 others under 50 000 each. THE STORE
  ALONE (the last version's translator on KB260 and on KB265): 16 sentences in 7 files, +0.010 % (to 8 463 428 563), all
  better: `next' for `forthcoming' (14: `from next week', `in the next weeks', `to the next tournament in Japan', `in
  the next days', `from the next legislature', `before the next elections', `next Tuesday', `next February', `until the
  next "invitation"', `next January 24') and `Cologne' (es_19990601-23 3, `the European summit of Cologne', and
  it_9947_9966 14, `in Cologne', where it was `to Colonia').
  THE FIRST ROUNDS' REGRESSIONS, found by the whole case and by reading the texts of every column, and mended: the
  marker through a participle gave a word that replaces the noun its `a' (`El perro ve al conducido por el gato',
  newspaper_wapo), and `concierto de clausura' and `concerto di chiusura' end in `a' with no denial, so the ending rule
  made them feminine (stated_gender's scan of the vocabularies); `"colonia" is a city.' in Spanish, where no city is
  stated, wrote `duerme a Colonia' for in Cologne, and is out; and `udienza' said first for a hearing made it the
  writer's word for the sense, `tengo dos oídos' (Tatoeba 377) `ho due udienze' where it was `due uditi', until `udito'
  was said again first.
  THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT (four risers of the first round, then 40 control sentences of 0.1
  to 2 million inferences, 20 from each language, into English, over a copy of the library per rule on KB262): the first
  round was +0.058 % on the one store, and 0.74 of the 0.81 million inferences the four rose was the name run, which
  asked the name's lookup of every phrase that opens on a name word (`L'Italia ha avuto quattro governi ...' +9.4 %);
  every capital asked first cost three control files +0.84 % (a run with a name first and small letters after), the
  second word's capital first +0.09 %, which is the rule now. The 40 sentences rise 3 130 inferences (+0.026 %), no rule
  over 700: the title 654, the marker through a participle 361, the superlative participle 336, the verb before a person
  128, the fragment 80, and the name run saves 163.
  THE STATED COSTS: a first meaning that serves the news and not every text -- `prossimo' is next (forthcoming second:
  the store alone's 16 texts of `next'), `udienza' a hearing (an audience second), `semaforo' a traffic light, the
  writer's `audiencia' for a hearing of a trial -- and `colonia' with a capital is Cologne (`a Colonia' in Italian is in
  Cologne); and the inferences, +0.025 % on the one store.
  The reports LEAVE, of the 17 into Spanish (English alike unless it says): 1 (`38 Spoleto festival.', a count, a name
  and a noun) and 7 (`Bianca nera.', two adjectives) are refused, and 10 (`riesce a contraddire sé stesso e le parole
  dell'imputato': a pronoun and a phrase joined, which no phrase reads; and `accusato di aver investito e ucciso Sara
  Folino', `acusado haber matado' with no `de' and English refused); `en la plaza Catedral' (2: `piazza Duomo' is a
  name, which the street rule takes only after a preposition), `tomorrow evening' last in English (2); `para la
  magnificencia' and the comma after `El Réquiem' lost (3: `per' says why, `por'), `intencionadamente' (`a propósito');
  `entre las más ejecutadas' (4: `interpretadas'), English refused for the third person nobody names, on purpose (3, 4,
  17); `toca' for `suona' is `juega' (5, the probes), `a Spoleto' kept after `che proprio a Spoleto ha mosso i primi
  passi' (5: the city rule does not go into a relative clause of a phrase's apposition, `to Spoleto precisely'); `negado
  al juicio' (8: smentito is proved wrong, `en el juicio'); `haciendo al limpiacristales a los semáforos' and `making
  the windscreen washer to the traffic lights' (9: `fare il' and a trade is working as one, and `14 years' old);
  `molestada' and `annoyed' (11: harassed), `para miedo' (`por miedo'), the quotation's opening mark lost and `says to
  have closed the eyes'; `me dijo tener cuidado' (12: `que tuviera'); `Había la niña' (13: `c'era' is the past of `c'è'
  in the vocabulary, so the state copula, which no past takes, is not written: `Estaba'); `ante los tribunales' last and
  `ha golpeado la niña' (15: `la ragazza' read as the subject after the verb, `the girl has struck', where two fronts
  with their commas stand before it), `The first car' (`prima' the adverb) and `skiding' (English's verb table has no
  `skid'); `Si así había sido' (16: `hubiera'); `a 70 a la hora' (17: `por hora'); `el médico Lombardi' (19: the title
  `doctor') and `will be listened' (`heard'); and `Proceso para la muerta de Folino, a la niña atropellada' and `I
  process for the dead one' (20: a heading read as the first person of `processa'). The next sample's controls take
  these reports in.
  The Spoleto faults (reasoning 1.0.24; cocolog stays 2.13.0; no new article). The three sentences of the Spoleto and
  Torvaianica reports that both languages refused -- 1 (`38 Spoleto festival.'), 7 (`Bianca nera.') and 10 (`Per
  difendere il fratello, Said, accusato di aver investito e ucciso Sara Folino a Torvajanica, riesce a contraddire sé
  stesso e le parole dell'imputato.') -- fixed in code and data. The reports read 20 of 20 into Spanish and 16 of 20
  into English on a fresh store, 17 and 14 with the new store alone, 19 and 15 with the new code on the old store, 17
  and 14 before, and their sentences fall from 10.8 million inferences into Spanish and 10.9 into English to 8.4 and
  8.5. English refuses 10 for the third person nobody names, on purpose, as it refuses 3, 4 and 17. Each rule has its
  arm red (test/translate.pl's `spoleto_faults': 38 checks, 37 arms, 35 red in the section, one red in newspaper_lazio
  and one guard of cost that stays green, below; lesson 46's section 87; an arm is a library directory of symlinks whose
  reasoning/translate.pl is the edited copy, `COCOLOG_LIBRARY=ARM cocolog query "use_module('test/translate.pl'),
  spoleto_faults, checks_done"', two seconds a run).
  A NUMBER, A NAME AND A NOUN ARE AN EDITION (`38 Spoleto festival.' heads the report on the festival's 38th edition,
  `la 38-ma edizione del festival' the line after it: the paper writes the name before the noun in English's way, and a
  count stands right before its noun, never before a name before it -- read as a count of festivals the heading had no
  reading; tr_read0/4, the number the ordinal, its sign the noun's gender, `38º' or `38ª', the name the noun's phrase of
  `of', and each writer says it as its own, `38º festival de Spoleto', `38th festival of Spoleto': two arms); A NAME OF
  SEVERAL WORDS THE LESSON STATES IS A HEADING (`Bianca nera.' is the paper's column of crime news, before each report
  of a crime, and it crosses as it stands, `"Bianca nera" is a name.': tr_stated_names/3 joins it into one word, and as
  one word the heading had no reading, while read as its words it is a bare noun and an adjective, `Big house.', which
  stays refused -- tr_verbless/3), a name the lesson states only (`Cuida de Tom.' joins as a name of two capitals and a
  particle, and is a command: Tatoeba's 35 was copied as it stands in the first round) -- two arms; A PURPOSE IN FRONT
  WITH ITS OBJECT, A NAME APPOSED TO IT AND A PARTICIPLE BETWEEN COMMAS (`Per difendere il fratello, Said, accusato di
  aver investito e ucciso Sara Folino a Torvajanica, riesce a contraddire ...' -- to defend his brother Said, accused of
  having run her over, he manages: the commas around the name go into the apposition before the reading, w(_, appos),
  and refused, the shortest front was taken, `Per difendere' alone, and the brother was the one who manages; tr_read0/4,
  tr_front_aside_comps/1), and a name after a participle or an infinitive is their object, never a name apposed to the
  front's noun (`accusato di aver ucciso Sara, riesce a dormire' -- Sara is whom he killed: tr_front_name_apposed/2), a
  word that is an adjective too among them (`dei cristiano democratici Casini, Mastella, D'Onofrio e del popolare
  Sanza', it_9673_9712 16: `popolare' is also the infinitive of `popola', and with Sanza apposed `del popolare' was left
  to read as the verb, `y Sanza ... del poblar' and `of the populating', where it is `y del popular Sanza' and `of the
  popular Sanza' now) -- three arms; a city in a front is `in' (`a Torvajanica' is `en Torvajanica', and it_9947_9966
  20's `a Roma' between commas `in Rome': tr_cities_in/2); THE PERSONAL MEANING REACHES THE OBJECT TWO PARTICIPLES SHARE
  (`ha investito e ucciso Sara Folino' ran her over and killed her, where it was `ha invertido y matado':
  tr_personal_obj/2), and an infinitive, a perfect one and a second participle with a person after it cross so too
  (`vuole investire la ragazza', `accusato di aver investito e ucciso Sara Folino', crossed by the first meaning
  `invertir a la niña' and `invested and killed': tr_personal_comp/3 in tr_cross_comps/2), inside a front as well, whose
  complements travel as fr/1 -- six arms; THE WORD A PARTICIPLE TAKES BEFORE THE INFINITIVE AFTER IT (`accusato di aver
  ucciso' is `acusado de haber matado', `"acusa" takes "de" before the infinitive.', and written bare it was `acusado
  haber matado': the participle a list of complements has just written is noted, '$tr_last_pred', tr_note_pred/1, for a
  predicate, a participle after its noun and one that agrees with the object, and none is noted as a clause starts,
  tr_write/4; the clause's own verb takes its word where no participle stands before, tr_infx_lead/1, which gives
  Italian's `permette ai cantanti di concentrarsi', `evitò di pronunciarsi' and `tentò di consolarlo', where the
  infinitive with a pronoun joined to it had none), a denied infinitive with its word before the denial (`de no haber'),
  and a word the source kept as a complement of its own before the infinitive written once (nprep/1,
  tr_with_infx_kept/1) -- seven arms; English's `accused OF HAVING killed' (`accused to have killed' before:
  en_prep_gerund/2, `accuses' and `suspects'), after the participle the participle's, and of the clause's own verb for
  its first infinitive alone (`acusó a la mayoría de buscar por todos los medios hacer daño' is accused of seeking to do
  harm, and the first round wrote `of searching of making', es_19981202-34 12) -- four arms; A QUOTATION THAT OPENS ON
  THE INFINITIVE AFTER THE VERB'S OWN WORD OPENS THERE (`acusara a Millàs de "hacer trampa"' came out `di fare
  trappola"' and `of making trap"' once the lesson said `"acusa" takes "de" before the infinitive.', found by the store
  alone: qm/2 on inf/1 -- the infinitive stops the walk for an object of the verb, or the person was the indirect one,
  `accusa al gatto' and `accuses to the cat', tr_verbal_comp/1 -- and the mark goes on the infinitive after the word its
  writer put before it, asked before the infinitive is written, which sets the verb being written to its own,
  tr_inf_lead_word/2) -- three arms; AN EMPHATIC REFLEXIVE HEADS THE WORDS BEFORE A COORDINATOR (`contraddire sé stesso
  e le parole dell'imputato' is to contradict himself and the defendant's words, one object of two; `sé stesso' is a
  pronoun of no role, and with nothing to head the words before `e' the split was refused and the sentence with it:
  tr_headed/2) and is a person, which Spanish marks (`contradecir a sí mismo': tr_of_class/2) -- two arms; such a
  pronoun is of two words, the pronoun and the word for `same' (tr_two_words/1), asked before the lexicon: a guard of
  cost, below, whose arm stays green; TWO OBJECTS JOINED, ONE OF THEM A PERSON, TAKE THE PERSON'S WORD BEFORE THAT ONE
  ALONE (`contradecir a sí mismo y las palabras del imputado' -- asked of the pair, neither took it: tr_comp_out/7),
  never before a name (`tempi e Modi della terapia' was `tiempos y a Modi', it_9450_9464 10, found by the controls) nor
  before a phrase whose noun is left out, which is of the class of the other one and alone of any (`vede due stanche e
  tre gatti' was `ve a dos cansadas', which the Lazio section's guard found in the whole case: its arm is red there) --
  three arms; a pronoun a coordinator joins to a phrase after it is one object of two (`vede lui e il gatto' sees him
  and the cat, and taken alone the pronoun left `e il gatto' to read as nothing: tr_pronoun_joined/2), and a personal
  pronoun of English's IR is a person (`ve a él y al gato') -- two arms; and English writes a participle after a name
  apposed to its noun as the source has it (`the brother, Said, accused of having killed her', where it was `the accused
  brother, Said, of having killed': tr_np_out/5).
  It needed these WORDS in `extra/': Italian `"Bianca nera" is a name.' and `"accusa" takes "di" before the
  infinitive.', Spanish `"acusa" takes "de" before the infinitive.'. No first meaning and no writer's first word moved,
  and none was lost.
  THE CONTROLS (cocolog 2.13.0, store KB268, 120 count files, 3 278 sentences: the earlier set with the two reports in,
  it_9205_9224, both directions): the last version's translator against this one, on the one store, 17 sentences read
  differently, all better -- the five of the reports, Italian's `di' before an infinitive with a pronoun joined to it
  (5: `gli permetterebbe di dedicarsi', `permette ai cantanti di concentrarsi', `evitò di pronunciarsi', `si occupò di
  mostrargli', Tatoeba's `Lei tentò di consolarlo'), English's `accused Aznar of launching', `accused Millàs of "making
  trap"' and `accuses you of making' and Italian's `accusava Millàs di "fare trappola"' (4), `in Rome' (it_9947_9966 20)
  and `del popular Sanza' and `of the popular Sanza' (it_9673_9712 16, 2) -- and the inferences fall 0.052 % (8 487 227
  077 to 8 482 795 922) and rise 0.0040 % outside the reports (8 465 513 101 to 8 465 852 648): every sentence rises but
  four, by 48 inferences at the median, +0.035 % of the sentences under 0.1 million and +0.0014 % of those over 10
  million, the largest it_9999_10010 8 (+4 764 of 394.7 million in each language); it_9673_9712 16 falls 9 400 in each.
  Bytes and characters read every sentence alike (0 differ, the bytes 0.008 % more). The DATA COLUMN (the last version's
  translator on its own store, KB265, against this one on the new): 15 sentences, the 17 less the three that the old
  store already read so, and Spanish's `os acusa de hacer' (it_9714_9749 7), -0.053 % and +0.0040 % outside the reports.
  THE CODE ALONE (this translator on KB265): 12 sentences, all better, +0.0040 % outside the reports; Spanish's `acusado
  de haber' and `Bianca nera.' need the new lines. THE STORE ALONE (the last version's translator on KB265 and on
  KB268): 4 sentences, one better (`"El Olivo os acusa de hacer', it_9714_9749 7) and three worse, which the code above
  mends -- the old reader took `de' and its infinitive for a phrase of `of', and with `"acusa" takes "de" before the
  infinitive.' it read the verb's word and wrote `accused Aznar to launch' (es_20000903-30 21) and, the quotation's
  opening mark lost, `accused Millàs to make trap"' and `accusava Millàs di fare trappola"' (es_20020301-125 4); -0.0004
  %. KB268 is taught from the same vocabulary as the KB267 of the first rounds, and the last version's translator reads
  both alike, to the unit.
  THE FIRST ROUNDS' REGRESSIONS, found by reading the texts of every column, the whole case and the probes, and mended,
  each with its arm red: `Cuida de Tom.' (Tatoeba's 35, a name heading), `tiempos y a Modi' (it_9450_9464 10), `of
  searching of making' (es_19981202-34 12), `ve a dos cansadas' (the Lazio guard) and the lost mark of `de "hacer
  trampa"' (above). The first round also narrowed the apposed name's guard to keep the old text of it_9673_9712 16,
  which the final rounds read as better without it. A STORE DOES NOT SURVIVE A SECTION: the second round's last three
  sentences and its count of the reports were void, because a run of the sections with `--embed KB267' wrote their hand
  lessons into the store; the round was taken again on a fresh KB268, and a section is run with no store.
  THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT (28 control sentences of 0.1 to 2 million inferences picked at
  random, 14 from each language, into English, over a copy of the library per rule): the first cut of the emphatic
  reflexive took the clitic `se' for one, and four sentences rose 77 000 inferences each (`se ne trova un'altra' split
  at its `e'), where three others fell 42 000 to 87 000, a split that failed at once, every text the same; with the
  clitic kept out, the 28 sentences rose 3 598 inferences (+0.034 %), 2 507 of them the emphatic reflexive's two rules,
  which asked the lexicon of every phrase of one word and of every phrase's noun. The two-word test first leaves +1 481
  (+0.014 %), of which the emphatic person rule is 302, the personal meaning in the complements 195, English's gerund
  after `accused' 138, the emphatic head 88 and the reset of the noted participle 63, no other rule over 50; a list of
  the reflexive lexemes made once a generation saved 57 of the 2 507 and was taken out.
  THE STATED COSTS: the inferences, +0.0040 % outside the reports; English's `it is' after the subject's relative clause
  in it_9673_9712 16 (`... D'Onofrio and of the popular Sanza, it is to have made'); and a lesson's emphatic reflexive
  of one word is none (no lesson states one).
  The reports LEAVE, of the three: English's `38th festival of Spoleto' (`the 38th Spoleto festival'); `Bianca nera.'
  crosses as it stands, its name untranslated, as the paper's column has one; and 10 into Spanish, `al hermano' (`a su
  hermano') and `consigue contradecir a sí mismo y las palabras del imputado' (`logra contradecirse a sí mismo'). What
  the Spoleto record says the reports leave stays as it is. The next sample's controls take this fix in.
  The Salou report (AnCora CESS-CAST-P-19990301-37, 21 sentences, the paper's report on the bombs on the beaches of the
  Costa Daurada, Spanish into Italian and English: 21 of 21 and 19 of 21 on a fresh store, 16 and 14 with the new store
  alone, 9 and 9 with the new code on the old store, 8 and 9 before; reasoning 1.0.25). The sample was taken on the
  cocolog 2.14.1 binary, master's e2239ea merged as bd5188f and built with Cicili 9b825b7 from a copy, and cocolog stays
  2.14.1: the binaries of 2.13.0 and 2.14.1 give the same texts and counts to the unit on the controls (3 278 sentences,
  0 differ, 8 482 795 922 inferences on both); master's 9c1c838 to bb80ca6 (test cases for the Apple silicon CI and
  documentation, no change to the binary or the library) came during the sample and are not merged, and the next sample
  takes them. The article's sentences fall from 67.6 million inferences into Italian and 67.3 into English to 37.7 and
  37.1, of which the fifteenth is 12.2 million in each. English refuses 5 and 17 for the third person nobody names, on
  purpose (`La mujer asegura que ha cambiado sus hábitos' names nobody in its clause of `that', and `las negativas
  consecuencias que pudiera tener' nobody in its relative clause).
  It needed these SHAPES, each with its arm red (test/translate.pl's `newspaper_salou': 54 checks, 58 arms, all red in
  the section; an arm is a library directory of symlinks whose reasoning/translate.pl is the edited copy,
  `COCOLOG_LIBRARY=ARM cocolog query "use_module('test/translate.pl'), newspaper_salou, checks_done"', two seconds a
  run): THE FIRST PERSON OF AN IMPERFECT OR A CONDITIONAL IS SPELLED AS ITS THIRD, and the subject pronoun says which
  (`Yo bajaba cada día a pasear a los perros' is I went down, and read as the third person with `yo' beside it the
  clause had no reading: tr_form0/5, under '$tr_first'; Tatoeba's `Yo os amaba', `Yo no quería el trabajo' and `que yo
  creía' read with it, which were refused); a denied clause whose subject says `more' denies in its subject (`No
  aparecen más artefactos' is no more devices appear, where it was `more devices do not appear': tr_write/4); `more' and
  a noun are a determiner and its noun, never a preposition and its phrase (`que haya más bombas enterradas', where the
  word was read as `plus': tr_determiner_before_noun/3), and `more' and a plural noun after a verb that takes an object
  are the object, the word the lesson's determiner (`Pondrán más explosivos' was `They will put more explosive', the
  comparative of the adjective), the word read as the adverb before a bare noun too, the adverb anywhere among the
  complements, where the reader moves it last, and the noun right after it in the words (`reclaman más ayudas para
  asegurar su futuro' and `darle más libertad a tu hijo' were `demand helps to ensure their future more' and `give
  freedom to your son more', found by the controls: tr_more_noun/4) -- three arms; the beach and the sand are what one
  is on (en_on_noun/1) -- two arms; `until' is a connector (en_connector/1), the denial right after it denies nothing
  (`hasta que no se haya resuelto el caso' is until it has been solved, as Italian's `a meno che non' is unless:
  tr_unless_word/1), and the impersonal `se' with a thing after its verb is the passive in the perfect too, where it was
  `until one has resolved the case' (tr_se_passive/2) -- three arms; an infinitive after the copula takes its meaning
  with no object, the phrase before it the copula's (`Es una locura bajar a la playa' is to GO DOWN, and with `una
  locura' taken for the infinitive's object it was `to drop': tr_cross_inf_comps/3); `must' in the past with a perfect
  infinitive is `should have' (`debían haber avisado a la población', where it was `had to have warned': tr_write/4);
  THE VERB OF RESULTING, A PARTICIPLE AND A PHRASE AFTER IT ARE THE PHRASE AND ITS PREDICATE (`resultó herido el
  artificiero de la Guardia Civil' -- read as an absolute clause after a verb with nobody named, the expert was what the
  injury left: tr_results_subject/5), the phrases of `of' with it (tr_fo_of_run/3), and English writes it as the
  participle's passive, never `turned out injured' (`también resultaron heridas' were also injured, `se reveló
  descompensado' was unbalanced: tr_write/4) -- three arms; the phrase after the infinitive of `upon' that the lesson
  calls intransitive is its subject (`al estallarle una bomba colocada en la arena' is a bomb exploding, and read as its
  object English wrote `on bursting him a placed bomb on the sand': upons/3, tr_upon_subject/4); the impersonal `se'
  with a person warned is English's passive (`no se les hubiera alertado', `si se hubiera advertido a la gente' --
  written as read, `one had not alerted them': tr_write/4, en_person_passive/1); a relative clause set off after two
  phrases joined hangs on both (`el Ayuntamiento de Salou y la policía, que conocían las amenazas' -- the plural clause
  disagrees with the last phrase, and read as its object relative the threats knew the police: tr_coord_rc_fix/4), and
  one after the phrases of `of' of a plural head, its verb in the plural, hangs on the head (`los artificieros de la
  Guardia Civil y del Ejército que han peinado las playas' -- hung on the Army, the clause took the beaches for its
  subject: tr_with_number/2) -- two arms; the doer right after the verb of a clause with a front is its subject (`en
  Cala Crancs juegan familias enteras en la arena' is whole families playing, and read with nobody named it was `they
  play whole families': tr_front_doer_fix/6); a phrase after the verb of a comment at the end of its clause, with nobody
  named, is its subject (`..., como indicaban los anónimos' is as the letters indicated: tr_cmt_subject_fix/2); a day
  the source names by `the day' and its number is the ordinal in English (`la bomba del día 21' is the bomb of the 21st,
  where `the day 21' was written: tr_np_out/5, tr_day_number/2), as when `on' it (`murió el día 13', and the controls'
  `la mañana del día 1' the morning of the 1st: tr_comp_out/7), and a participle and the day after it are no absolute
  clause (`el jubilado fallecido el día 13 al manipular un artefacto', where the day lost its `on': tr_day_label/1) --
  three arms; the main clause of a condition in the pluperfect is the conditional perfect (`si se hubiera advertido a la
  gente ..., no hubiera muerto aquel anciano' is that old man would not have died, where it was `had not died':
  tr_counterfactual/3); `hace' and a time after the verb is `ago', the time read as the verb's and the word for `ago'
  after it (`echó en cara hace una semana a Esteve Ferran' was `reproached a week to Esteve Ferran ago', and the
  controls' `vent'anni fa, nella direzione del "giornale"' was `twenty years ... ago' at the end: tr_ago_phrase/2); a
  verb of reproaching takes the person bare before its clause of `that' (`echó en cara ... a Esteve Ferran ... que no se
  hubiese alertado', where it was `reproached to Esteve Ferran': tr_comps_out/7, en_person_that/1), and the clause after
  the person may open on a denial and the pronouns of its verb (`han recriminado a las autoridades que no se les hubiera
  alertado', which read as the authorities' relative clause: tr_clause_after_person/1) -- two arms; a participle in the
  subject's phrase of `of' takes the phrase after it (`algunos habitantes de las localidades incluidas en la campaña de
  amenazas' -- with the campaign the inhabitants', English wrote `the included localities in the campaign':
  tr_inner_participle_adjunct/2); `last' and `first' stand before the count in English (`en las últimas tres semanas',
  where it was `the three last weeks', and the controls' `the last two years': tr_np_out/5, en_order_adjective/1); a
  demonstrative after the verb and the noun after it are one subject (`no hubiera muerto aquel anciano' is that old man,
  and read as the pronoun `aquel' for the subject the noun was left for a predicate: tr_demonstrative_subject/4); A
  WOMAN'S POSSESSIVE IS `her' (`La mujer asegura que ha cambiado sus hábitos', where the lesson's first meaning wrote
  `his', and the controls' `stretta alla sua tata' of a daughter: tr_female_possessor/1, '$tr_poss', tr_cross_det/2),
  and a husband's (`Marta Toledo, ..., y su marido' is her husband: tr_cross_np/2) -- three arms; a determiner the
  lesson says takes the indefinite takes it (`voy a otro sitio' is `vado in un altro luogo' (`"altro" takes the
  indefinite.'), where it was `altro luogo', and the controls' `appoggiare a un'altra candidatura', `In un'altra
  partita', `un altro albergo': tr_det_out/6); a determiner in the singular loses its ending where the lesson states its
  apocope (`no han localizado ningún artefacto' is `nessun dispositivo', where it was `nessuno dispositivo', and
  Spanish's `cualquier' is the short form of `cualquiera': tr_det_form/6, tr_det_apocope/3); a name the lesson gives a
  meaning has the gender the lesson states of it (`en los Alpes' is `nelle Alpi', and with Spanish's masculine it was
  `negli Alpi': tr_crossed_name_gender/2); a quotation that closed on a subject set last closes where the clause ends
  (the passive writes the case first, and the mark stayed on it, `until the case" has been resolved': tr_write/4); a
  word that is a person's noun and an adjective, after the comma that closes a subject set after the verb, is what the
  subject is (`sostiene Rebeca López, vecina de Cala Crancs' -- read as the adjective it was `maintains, neighbouring of
  Cala Crancs': tr_person_appos/2); a name with what it is set between commas, after a verb of saying with nobody named,
  is the speaker -- the commas made the name an aside and the verb's object, and English refused it (tr_aside_speaker/2)
  -- and the place apposed to the apposition's last phrase is the speaker's too (`vecina de Cala Crancs, el lugar donde
  ...': tr_appos_tail/1) -- two arms; an item of a list with its bracket is an item (`las playas de Tarragona, Salou
  (Tarragonès) y Cambrils (Baix Camp)' -- with the bracket the comma stayed the clause's, and the sentence was refused:
  tr_bare_tail/4), and a bracket right after a name that ends a relative clause is the name's, never the phrase's with
  its clause, which kept the clause from the head it hangs on (tr_np/3) -- two arms; a bare plural is a speaker (`según
  explicaron fuentes de los turoperadores de la zona', and with a determiner asked for the comment was refused:
  tr_report_subject/5); a thing's reflexive is the passive with its phrases of `of' too (`que las explosiones de Salou
  no se vincularan con una actuación terrorista', where it was `did not link': tr_thing_phrase/1); a name and its
  relative clause before a colon are a heading (`Todo lo contrario de Rebeca, que augura:' is quite the opposite of
  Rebeca, who predicts it -- the clause was one of `that' with nobody named, which English refuses: tr_verbless0/3), and
  so is a phrase whose phrase of `of' has the name and its clause -- two arms; a person's name after a phrase that ends
  on capitals the lesson knows is apposed as it is after a comma (`el artificiero de la Guardia Civil Luis Marfil' --
  with the capitals run together the phrase had no reading: tr_np/3); a word a quotation mark closes on keeps its
  pronouns (`hacerlo"' was a word no lesson knows: tr_enclitics/3), a mark on an infinitive the clause ends on closes
  where the clause ends, never after the verb group (tr_vq_close/4), the mark is no first complement, so the verb
  crosses by its meaning before an infinitive, `intends' (tr_front_comp/1), and `makes' with nothing made is `does', its
  pronoun `it' (`"No pienso hacerlo"' is I do not intend to do it: tr_write/4) -- four arms; a group after a verb of
  warning is its object, marked as a person is (`debían haber avisado a la población' should have warned it, and read as
  a phrase of `to' English wrote `warned to the population', and the controls' `Advirtió a sus antiguos socios', `avisó
  a Ibarretxe', `previno a los suyos': tr_warned_group/3), and after the infinitive of one, read with the modal's group
  (tr_warned_infinitive/2) -- two arms; and a verb before an infinitive with the word it takes crosses by its meaning
  there (`han renunciado a visitar las playas' have GIVEN UP, where it was `renounced to visit', and the controls'
  `cercherò di illustrare' I will try to illustrate: tr_verb_across/5), English's `gives up' taking the gerund
  (en_gerund_verb/1), after the word too -- three arms. Three rules of the first cut changed nothing in the article, the
  section or the controls, their arms green, and are gone: a bracket in a list of words, a bracket after the last name
  of a bare list and an English determiner `more' for a denial.
  It needed these WORDS in `extra/' (the two readers: a line moves the reader of one language and the writer of the
  other; the dictionary's own word is said again first where it must stay the one written): Spanish `anónimo' (an
  anonymous letter, the noun: the dictionary has the adjective alone), `artificiero' (a bomb disposal expert, a person:
  the dictionary has the word and no meaning), `patronato de turismo' (a tourist board), `turoperador' (a tour
  operator), `viuda' (a widow, where the first was the widower), `vecino' and `vecina' (persons), `anciano' (an old man,
  the noun, a person), `artefacto' (a device, before the artefact), `arena' (the sand, before the arena), `a raíz de'
  (as a result of), `con anterioridad' (beforehand), `piensa' (thinks said again first, and intends before an
  infinitive), `baja' (drops said again first, and goes down with no object), `pasea' (strolls with no object, and
  walks), the name `Costa Daurada', `echa en cara' (reproaches, with its forms, taking the clause), `hasta que' (until),
  `todo lo contrario' (quite the opposite), `poco probable' (unlikely), `toca' (touches, before plays), `queja'
  (complains, reflexive, taking the clause and `de' before it), `población' (a group), `desde entonces' (since then),
  `"resuelve"', `"justifica"' and `"vincula" take the passive.', `"reina"' and `"aparece" are intransitive.', `renuncia'
  (renounces said again first, and gives up before an infinitive), the determiner `más' (more), `"recrimina" takes the
  clause.', `autoridad' (a person), `"marta" is a name.', `manifiesta' (states, before manifests), the name `alpes' (the
  Alps) and `estalla' (explodes, intransitive); Italian `estorsione' (extortion, said before `concussione', a public
  official's), `artificiere' (a bomb disposal expert, a person), `ente turistico' and `operatore turistico', `lettera
  anonima', `anziano' (elderly said again first, and an old man), `allarme' (the writer's first was `avvisatore', an
  alarm device), `in seguito a', `in anticipo', `scende' (descends said again first, and goes down with no object),
  `bar' (the writer's first was `barra', a rod), `accade' (happens said again first, and occurs: the writer's first was
  `occorrere', to be needed), `muore' (the writer's first was `decedere'), `riferimento' (the writer's first was
  `benservito', a dismissal), `finché' (until), `tutto il contrario', `da allora', `vicino' and `vicina' (persons),
  `rinuncia' (renounces, and gives up before an infinitive, with `a' before it), `altro' and `altra' (take the
  indefinite), `autorità' (a person), the name `alpi' (the Alps, feminine), `esplosione' (the writer's first was
  `deflagrazione', a word of chemistry) and `esplode' (explodes, intransitive); and in the dictionaries' extras
  `renounce' (`rinunciare': the Italian dictionary has the verb and no meaning) and, read only, `return' (`volver': the
  dictionary gives it only verbs of two English words, which the builder takes none of), `reproach' (`recriminar'),
  `manage' (`regentar'), `predict' (`augurar') and `pensioner' (`jubilado'). The first meaning moved for 10 Spanish
  words and 2 Italian ones (Spanish `anciano' an old man, `anónimo' an anonymous letter, `arena' the sand, `artefacto' a
  device, `baja' drops, `manifiesta' states, `pasea' walks, `renuncia' renounces, `toca' touches, `viuda' a widow;
  Italian `artificiere' a bomb disposal expert, `esplosione' an explosion), the writer's first word for 6 Spanish
  meanings and 8 Italian ones (Spanish unlikely `poco probable', device `artefacto', drops `baja', reproaches `echa en
  cara', states `manifiesta', walks `pasea'; Italian beforehand `in anticipo', alarm `allarme', bar `bar', explosion
  `esplosione', extortion `estorsione', reference `riferimento', dies `muore', occurs `accade'), and none was lost.
  THE CONTROLS (cocolog 2.14.1, store KB274, 120 count files, 3 278 sentences: the earlier set with the Spoleto faults
  in, both directions; this report is not among them): the last version's translator against this one, on the one store,
  29 sentences in 18 files read differently, all better but two that are no better -- `un altro' and `un'altra' (5:
  `appoggiare a un'altra candidatura', `un'altra brillante pietra miliare', `In un'altra partita', `un altro albergo',
  and Kallon's `un altro tempo' for `otra vez', as wrong as the `altro tempo' it was), the person warned bare (3: `They
  warned his ancient associates', `they warned Ibarretxe', `warned the theirs ones'), `were also injured' and `was
  unbalanced', `the last two years', `the morning of the 1st', `the steps that should have given', `twenty years ago' in
  its place, `who says satisfied', `her babysitter', `I will try to illustrate' and `intentaré ilustrar', and Tatoeba's
  `I loved you', `I did not want the job' and `You are simply not the person that I believed', read for the first time
  in both languages, `on the beach', `give more freedom to your son' and `più libertà al tuo figlio', and `nessun
  problema' -- and Tatoeba's `Tom said that I seemed wearied very', read where it was refused, the other one no better.
  The inferences fall 1.267 % (8 490 790 587 to 8 383 235 662), 0.432 % outside the twenty sentences that fall by over a
  million, every one of them Italian and its text the same (the Venice report's fourth 124.6 million to 114.2 in each
  language, Tempi's twentieth 517.8 to 507.4 and the Rognoni interview's nineteenth 361.0 to 358.0, both refused,
  Salvini's tenth 4.7 to 0.9); 2 947 sentences rise, by 279 inferences at the median, the largest the Venice report's
  eighth (+0.11 million of 394.8) and the Lord of the Rings' third and eleventh (+0.10 of 13.7 and of 30.4). Bytes and
  characters read every sentence alike (0 differ, the bytes 0.008 % more). The DATA COLUMN (the last version's
  translator on its own store, KB268, against this one on the new): 57 sentences, the code's 29 and the store's 28,
  -1.174 % (8 482 795 922 to 8 383 235 662). THE CODE ALONE (this translator on KB268): 22 sentences, every one among
  the 29, -1.271 % (to 8 375 003 041); the seven left need the new lines (`"altro" takes the indefinite.', the
  determiner `más'). THE STORE ALONE (the last version's translator on KB268 and on KB274): 28 sentences, +0.094 % (to 8
  490 790 587), each a word of the report's lines, all better but the five of the stated costs below -- `stated' and
  `dichiarò' for `manifestó' (7, where it was `manifested'), `accaduti', `accadrà', `accadendo', `esplosioni', `morire',
  `morì', `morirono', `morto' and `morti' where Italian wrote `occorsi', `occorrerà', `occorrendo', `deflagrazioni',
  `decedere', `decedette', `decedettero', `deceduto' and `avere deceduto' (11), `nude' (`appeared nude', where it was
  `nudes'), Spanish `bajar' for `scendere' (2, where it was `descender'), and Tatoeba's `We should return soon' and
  `Dovremmo ritornare presto', read for the first time.
  THE FIRST ROUND'S REGRESSIONS, found by reading the texts of every column and mended. Of the store (the store alone,
  KB273, 45 sentences): the Italian determiner `più', which a line made for the writer of `más bombas', read `non lo
  vide più nessuno' as more of nobody (`más ninguno', and `Oggi non ce n'è rimasto più nessuno' was `Today no more no
  has remained it'), and `a chi più guadagna' lost its adverb (`the one that earns ... more more'); the writer finds
  `più' as the adverb's word with no line, and the line is out; `accade' as occurs, said first, made `come è accaduto'
  `how has it occurred' and English refused it and the garrisons' sentence of it_9781_9791 (`come, peraltro, accadde in
  passato'), and happens is said again first now; and the verb of walking a dog, `portare a spasso', said for `pasear a
  los perros', was the writer's word for every walk (`Me gusta andar en tren' was `Mi piace portare a spasso in treno'),
  and is out. Of the code (the one store): `más' read as an adverb before its noun, which the reader moves last, made
  `reclaman más ayudas para asegurar su futuro' and `darle más libertad a tu hijo' `demand helps ... more' and `give
  freedom to your son more' (tr_more_noun/4 now takes the adverb anywhere, the noun right after it in the words: an arm
  red); and of the whole case, two older expectations written in the old English: `The dogs had to have eaten the
  bread.' is `... should have eaten ...' (in both files) and `The dog warns to the coaches that ...' is `The dog warns
  the coaches that ...'.
  THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT (the five sentences of the code's second round that rose most on
  the one store, three from Spanish and two from Italian, into English, over a copy of the library per rule on KB274):
  they rose 4.05 million inferences of 47.60 (+8.5 %), and two rules were all of it -- the bare plural speaker, 4.48
  million (Kallon's sentence, es_20011002-160 13, 1.54; Rimac's, es_20001201-176 12, 0.86; the Middle Ages' thirteenth,
  it_9967_9998 13, 1.63; Venice's ninth, it_9999_10010 9, 0.45: the phrase was read at every place a speaker could
  begin, `los argentinos Guglielminpietro (Milan) y Vivas (Arsenal), los turcos ...', `jugadores que asumieron la
  responsabilidad ...', `teorie pagane sulla rotondità della terra e la rappresentavano ...'), and the name after an
  institution, 0.46 million (`un violín llamado Ex Von Szerdahely VieuxTemps', es_20010202-169 4, 1.37 million where it
  was 0.98) -- no other rule over 0.01 million. What paid was the cheap questions first: the bare plural speaker holds
  no comma, no bracket or aside, no relative clause and no verb, has no name right after its noun, its noun is no
  adjective, and no speaker begins right after a determiner, inside the phrase it opens; the name's capitals come right
  after a determiner, as an institution's do. The three sentences that rose most after that (the poor's fifth,
  it_9637_9672 5, `vivono 6 milioni e 458 mila poveri', 0.39 million of 2.36; es_20010102-25 2, `con tres explosiones',
  0.20; es_20010103-85 14, `provistos de dos camiones', 0.20) were the same rule, the phrase read after a count, and no
  speaker begins after a count either. Without the questions the section is green as well (it was so before they were
  written), as it is for a guard of cost. The five then stand at 46.69 million, 1.9 % under the last version's, and the
  three at 3.797, 0.07 % over it, every text the same.
  THE STATED COSTS: the store's intransitive `baja', `reina' and `pasea', which the report needs (`Yo bajaba cada día a
  pasear a los perros', `en la zona reina la tranquilidad'), cost three sentences of the controls a reading for nothing,
  the texts the same, each found by learning its line alone into the old store: `Bajo la dirección de Bertrand de Billy,
  ...' 1.87 million inferences in each language (0.75 to 2.62: `bajo' is the first person of the verb too, and the long
  phrase after it is asked for its subject), `esa reina destronada y saliente' 1.0 million of 10.5 and `cuando paseaba
  en la zona de La Recoleta' 0.37 of 0.49; the reflexive `queja' makes `"No hay derecho", se quejó' a third person
  nobody names, which English refuses on purpose, where it was `one complained'; Tatoeba's `Volveré a llamar a las dos y
  media', `Creo que deberíamos volver a Boston' and `Tom dijo que yo parecía muy cansado', refused before, read now and
  wrong (`I will return to call the two and a half ones', `I believe that we should return Boston' and Italian
  `rimettere Boston', `I seemed wearied very'): `volver' is read now, a dictionary line read only, with no word for
  `again' before an infinitive, and `a Boston' is the `a' of a person, which a line `"vuelve" is intransitive.' did not
  change; a first meaning that serves the news and not every text -- `toca' touches (`toca la guitarra' plays it),
  `arena' the sand, `artefacto' a device, `manifiesta' states, `anónimo' an anonymous letter, `anciano' an old man --
  and the writer's `artefacto' for a device (where it was `aparato'), `pasea' for walks (`anda'), `echa en cara' for
  reproaches, `poco probable' for unlikely and `manifiesta' for states, and Italian's `esplosione', `allarme',
  `riferimento', `muore', `accade', `in anticipo', `bar' and `estorsione'; and the inferences, -1.267 % on the one
  store, +0.094 % for the store alone.
  The report LEAVES, of the 21 into Italian: `non gli avvertiva del rischio dopo ricevere le lettere anonime' (1: `li
  avvertisse', the subjunctive written as an indicative and the object as a dative, and `dopo aver ricevuto'); `nelle
  tre ultime settimane' and `molti di cui' (2: `nelle ultime tre settimane', `molti dei quali'; English's order rule is
  English's alone); `non pretendo farlo' (4: the writer's word for intends, `ha intenzione di'), `ritornato' (a woman
  speaks), `esplodendo una bomba disposta nella sabbia' (`quando gli è esplosa una bomba collocata sulla sabbia') and
  `Guardia Civile'; `a camminare ai cani' (5: `a portare a spasso i cani'); `spagnolo d'origine peruviana' (7:
  `spagnola', an apposition keeps no gender) and `anche' last; `finché si è risolto il caso' (8: `finché non si sarà
  risolto', the expletive `non' and the future perfect); `Anche si lamenta che' (9: `Si lamenta anche del fatto che');
  `nella sabbia' and `potette' (10: `sulla', `poté'); `non ha variato' (11: `non è cambiato'); `dovessero avere
  avvertito' (14: `avrebbero dovuto avvisare'); `Se si era avvertito alla gente che non toccavano oggetti sospettosi'
  (15: `Se si fosse avvertita la gente di non toccare oggetti sospetti') and `manipolando un dispositivo' (`mentre
  maneggiava un ordigno'); `inizialmente' last (17); `Il rotante britannico' (18: `rotativo' is a daily paper, `il
  quotidiano'), `fecero sapere degli accadimenti' (`informarono degli avvenimenti') and `gli dedicarono' (`vi
  dedicarono'); `non si allacciavano con' (19: `non fossero collegate a'); and `credono inverosimile che ci sono più
  bombe' (21: `ci siano'); of the 19 into English: `many of which' (2: whom); `the danger that they ran beforehand' (3:
  `beforehand' last); `on a bomb placed on the sand exploding' (4: when a bomb placed on the sand exploded); `spaniard'
  and `they manage a bar and they have also taken precautions' (7: a Spaniard, the subject said again); `One also
  complains' (9: she, the reflexive read as the impersonal `se'); `the tranquillity reigns' (11: all is calm); `The Town
  council of Salou' (14); `affirm David' and `the pensioner died on the 13th on manipulating a device that had found'
  (15: David affirms, who died, that he had found); `that one had not alerted of the danger' (16: that no warning had
  been given of it); `The rotary British The Times ... reported of the events, although they did not devote him
  excessive space' (18: the British daily, reported on, devote it); and `The managers of the research believe unlikely
  that' (21: those in charge of the investigation believe it unlikely). The next sample's controls take this report in.
  The Grazioli trial report (VIT-9310..9323, 14 sentences, the prosecutor's requests at the trial for the kidnapping and
  death of Duke Massimiliano Grazioli Lante, Italian into Spanish and English: 14 of 14 and 14 of 14 on a fresh store,
  11 and 10 with the new store alone, 3 and 3 with the new code on the old store, 2 and 2 before; reasoning 1.0.26). The
  sample was taken on the cocolog 2.14.1 binary, master's fcde058 (test and documentation, fast-forwarded onto the
  branch), and cocolog stays 2.14.1; master's 887a472, 541fe10 (cocolog 2.15.0, async_workers/1) and 273585f (the token
  benchmark) came during the sample, change nothing under library/reasoning/, and are not merged: the next sample takes
  them. The article's sentences fall from 513.0 million inferences in each language to 44.2 into Spanish and 44.1 into
  English, of which the ninth is 20.5 million in each.
  It needed these SHAPES, each with its arm red (test/translate.pl's `newspaper_grazioli': 25 checks, 28 arms, all red
  in the section, and a guard that is red in the controls alone, below; an arm is a library directory of symlinks whose
  reasoning/translate.pl is the edited copy, `COCOLOG_LIBRARY=ARM cocolog query "use_module('test/translate.pl'),
  newspaper_grazioli, checks_done"', under a second a run, and every arm is run in seven seconds, four at a time): TWO
  VERBS IN THE SIMPLE PAST JOINED BY A COORDINATOR SHARE THE SUBJECT AND THE OBJECT (`la banda che rapì e uccise nel
  1977 il duca' kidnapped and killed him -- `uccise' is the feminine plural participle too, and read as one it was said
  of the gang, `secuestró y matada': cverb/1, after a verb that is no copula, in a simple tense, where an object
  follows, and each writer writes it in the clause's tense and person, tr_cverbs/6) -- two arms; A NOUN THAT CAN SAY A
  MEMBER SAYS IT BEFORE A PHRASE OF `of' WHOSE NOUN IS A GROUP (`i componenti della banda' are the gang's members, where
  `componente' is a component first, and a component of a thing stays one: tr_relational_np/3, tr_group_head/1); a topic
  is no front of a first person nobody names whose verb is a noun too (`Processo Grazioli, sconto al pentito Abbatino'
  is the trial and a discount, two headings, and read as `sconto', I discount, English wrote `I discount to the
  informer': tr_read0/4); only a verb that can report has a speaker after it (`La banda, dopo il rapimento, uccise il
  nobile romano' is the gang killing him, and the Roman after the verb was the speaker of a clause that reports, `The
  gang, after the abduction, the noble Roman one killed': tr_reporting/3, a verb of saying or one that takes the
  clause); a heading that opens on a count, with a relative clause after its comma (`Otto anni e sei mesi per il pentito
  Maurizio Abbatino, che con le sue confessioni ha consentito ...' -- eight years for the informer, who allowed it; read
  as a clause of `that' with nobody named English refused it: tr_verbless0/3, the count word and the count of time read
  as a phrase of time: an arm and its two halves, each red); A CLAUSE RIGHT AFTER AN INFINITIVE TAKES THE INFINITIVE'S
  MOOD (`ha consentito di stabilire che la banda uccise il nobile romano' established that it killed him, and with the
  mood of `permitir', which takes the subjunctive, Spanish wrote `que la pandilla matara': tr_write/4 -- and the
  controls' `Non possiamo pensare che questo sia già vinto', where it was `è', and `los lombardos saben ser' and `como
  la iglesia se había equivocado', where the matrix verb's subjunctive was written, below); an insertion between commas
  after the participle's adjunct, before its agent (`le richieste fatte ieri, a conclusione della requisitoria, dal pm'
  were made yesterday, at the end of the closing speech, by the prosecutor -- the participle took `ieri' alone, and `dal
  pm' was a phrase of `from', `del fiscal': tr_reduced_agent/3); AN ARTICLE, AN ADJECTIVE OF ORDER AND A COUNT ARE A
  PHRASE WHOSE NOUN IS LEFT OUT (`(gli ultimi tre, esponenti della banda di Montespaccato)' are the last three, and the
  phrase had no reading: tr_np/3), and English puts the adjective before the count with no `ones' (`the last three',
  where it was `the three last ones': tr_np_out/5; the controls' `The first two have remained', below) -- two arms; A
  NAME MAY CARRY ITS BRACKET ON IN A LIST OF NAMES (`per Antonio Montegrande, Giorgio Paradisi, Marcello Colafigli,
  Emidio Castelletti (tutti della banda della Magliana), Enrico Mariotti, ...' -- with the bracket after the fourth name
  the names did not go on, the second was apposed to the first, and the commas after them stayed the clause's:
  tr_names_go_on/2, tr_list_word/2 and tr_list_commas/5, three arms and the three together), the bracket a list item
  before its comma only where a name follows the comma, never a phrase (a guard the controls found, its arm red there
  alone: `17 nuevos fichajes, entre ellos el portugués Conceiçao (Parma), los argentinos Guglielminpietro (Milan) y
  Vivas (Arsenal), los turcos ...' was 178.8 million inferences and refused in both languages, where it was 4.1 million
  and read; the hand lesson reproduces no list of three such groups); a preposition and its infinitive between commas is
  an insertion, and the noun the copula is too never divides the sentence after it (`Abbatino, prima di essere arrestato
  e di decidere di collaborare con l'autorità giudiziaria, era uno dei più noti malviventi' is the man who was one, and
  divided at `era', an era, he was a heading and the copula had nobody named: tr_insertion_comps/1, tr_read0/4) -- two
  arms; a passive infinitive of a preposition is a front of a relative clause, with the infinitives joined to it (`per
  Abbatino, che prima di essere arrestato e di decidere di collaborare ... era uno dei più noti malviventi della
  capitale, il pm ha chiesto' -- with the participle and the second infinitive no adjuncts it was no front, and the
  sentence was refused: tr_adjuncts_after/2); an infinitive joined to a preposition's infinitive is under the same
  preposition in English, both gerunds (`before being arrested and before deciding to collaborate', where it was `and to
  decide': tr_comps_out/7); `asks' takes `for' before its object and never before a count, which is how much is asked
  (`il pm ha chiesto la condanna a otto anni e sei mesi di reclusione' came out `has asked eight years and six months
  for the conviction': en_counted/1); THE CLEFT WITH ITS COPULA FIRST IN THE PERFECT, AND AN ADVERB BETWEEN COMMAS AFTER
  WHO IT IS (`È stato lui, infatti, a rivelare tutti i retroscena della vicenda' -- it was he, in fact, who revealed
  them; with the simple tenses alone it was a copula with nobody named, `It has been him, to reveal':
  tr_read_statement0/4) -- two arms; A DATE IN FRONT OF A RELATIVE CLAUSE'S VERB (`i componenti della banda che il 7
  novembre del settantasette, rapì il duca' -- the date was the clause's subject, and in a heading none had a verb:
  tr_relative_clause/4), the comma between the date and the verb none of the clause's, the paper's slip, which in a
  heading parted the clause from its verb and refused the sentence (tr_rel_time_comma/3), the year after the date's `of'
  the date's own (`on November 7, seventy-seven', where it came out `of the seventy-seven, on November 7':
  tr_date_year/2), and English's `on' before a date with its year (tr_comp_out/7) -- four arms; and adjuncts after the
  comma that closes the subject's relative clause, right before the verb (`Abbatino, che ha dato tutta una serie di
  indicazioni ..., per il pm è "pienamente affidabile"' -- for the prosecutor he is fully reliable; with no comma before
  the verb the phrase was read into the subject, and the long sentence was refused: tr_insertion_off/4). The first cut's
  comma branch of the date's front in a relative clause had a green arm once tr_rel_time_comma/3 took the comma, the
  article the same and 75 inferences fewer, and is gone.
  It needed these WORDS in `extra/' (the two readers: a line moves the reader of one language and the writer of the
  other; the dictionary's own word is said again first where it must stay the one written): Italian `sequestro' (a
  kidnapping), `pentito' (an informer, a person), `ergastolo' and `condanna a vita' (a life sentence), `requisitoria' (a
  closing speech), `corte di assise' (a court of assizes), `malvivente' (a criminal, a person; `delinquente' said again
  first), `retroscena' (an inside story, its own plural, not feminine), `processo' and `dibattimento' (a trial),
  `riscatto' (a ransom), `difensore' (a defender, a person), `telefonata' (a phone call), `discordanza' (a discrepancy,
  where the dictionary's first is a geologist's unconformity; `discrepanza' said again first), `alle porte di' (on the
  outskirts of), `a partire da' and `a cominciare da' (starting from), `alla fine di' and `a conclusione di' (at the end
  of), `quanto a' and `per quanto riguarda' (as for), `mette in luce' (brings to light, with its forms), `"banda" is a
  group.', `componente' (a component said again first, and a member, with `membro' said again first), `"franco" is a
  name.' (`Franco Catracchi', where it was `Frank'), `lungo' (along, the preposition: the adjective's `long' was its
  first meaning too), `tutta una' and `tutto un' (a whole, one determiner of two words), `rapito' (a kidnap victim, a
  person) and `alla fine' (in the end); Spanish `revela' (reveals, said first: the writer's word for it was `pone en
  evidencia', which has no participle, and the Spanish perfect `ha puesto en evidencia' was refused), `arrepentido' (an
  informer, a person), `cadena perpetua', `requisitoria', `tribunal penal', `entresijo' (an inside story), `llamada
  telefónica', `a las puertas de', `saca a la luz' (with its forms), `banda' (a band said again first, and a gang),
  `"banda"' and `"pandilla" is a group.', `defensor' (a campaigner said again first, and a defender), `al final de', `a
  lo largo de' (along: the Spanish writer had no word for it, and the sentence was refused), `toda una' and `todo un',
  `secuestrado' (a kidnap victim, a person) and `al final'. The first meaning moved for 2 Italian words and 1 Spanish
  one (Italian `discordanza' a discrepancy, `lungo' along; Spanish `entresijo' an inside story, where it was a secret),
  the writer's first word for 3 Spanish meanings and none Italian (a defender `defensor', where it was `zaguero', a
  football back; a gang `banda', where it was `pandilla'; reveals `revela'), and none was lost.
  THE CONTROLS (cocolog 2.14.1, store KB279, 122 count files, 3 320 sentences: the earlier set with the Salou report in,
  es_19990301-37, both directions; this report is not among them): the last version's translator against this one, on
  the one store, 7 sentences in 7 files read differently, 5 better -- the mood of a clause after an infinitive (3: `Non
  possiamo pensare che questo sia già vinto', where it was `è'; `los lombardos saben ser poco sentimentales' and `como
  la iglesia se había equivocado', where the matrix verb's subjunctive was written), `The first two have remained', and
  `ha golpeado a la niña' -- and two that are no better: the Spoleto report's fifteenth into English (`poi, sbandando,
  ha colpito la ragazza' is the car striking the girl, where the girl struck, and English refuses the third person
  nobody names, on purpose; its Spanish is the better text above) and the Veloso interview's fourth into Spanish (`con
  Gilda l'ex compagna di Vinicius De Moraes al fianco, incrocia affettuosamente l'amico Gilberto Gil' was read with the
  friend as the speaker of a reporting clause, `encuentra cariciosamente el amigo Gilberto Gil', and is read now with
  the ex-partner for the subject and `con Gilda' moved after the object, `la ex compañera ... encuentra cariciosamente
  al amigo Gilberto Gil con Gilda': both wrong). The inferences fall 0.073 % (8 447 504 598 to 8 441 365 137), 0.171 %
  outside those two sentences, whose new readings cost 2.4 and 1.7 million inferences more in each language; 3 098
  sentences rise, by 653 inferences at the median, the largest the Rognoni interview's nineteenth (+0.11 million of
  358.0, refused both ways), and the ones that fall most are the Rosi report's 21st (1.40 million to 0.50 in each
  language) and Tempi's seventeenth, the communiqué (it_9673_9712 17, 20.1 to 19.3), where a verb that cannot report is
  asked no speaker now. Bytes and characters read every sentence alike (0 differ, the bytes 0.009 % more). The DATA
  COLUMN (the last version's translator on its own store, KB274, against this one on the new): 13 sentences in 12 files,
  -0.197 % (8 458 039 233 to 8 441 365 137), the 7 of the code and the 6 of the store. THE CODE ALONE (this translator
  on KB274): the same 7 sentences, -0.073 % (to 8 451 900 194). THE STORE ALONE (the last version's translator on KB274
  and on KB279): 6 sentences in 5 files, all better, -0.125 % (to 8 447 504 598), each a word of the report's lines: `a
  whole' for `tutta una', `tutto un' and `toda una' (3: `A whole exploit', `It has been a whole ambiguity', `A whole
  series of problems', where it was `All an exploit'), `in the end' and `al final' for `al final' and `alla fine' (2,
  where it was `to the end' and `al fin'), and `Lo revela' for `Lo rivela' (where it was `Lo pone en evidencia').
  THE FIRST ROUNDS' REGRESSIONS, found by reading the texts of every column, the whole case and the writers' first
  words, and mended. Of the code (round a's data column, KB277): the bracket counted as a list item before its comma
  whatever followed it, and the Kallon sentence of the Inter feature (es_20011002-160 13, `... 17 nuevos fichajes, entre
  ellos el portugués Conceiçao (Parma), los argentinos Guglielminpietro (Milan) y Vivas (Arsenal), los turcos Emre y
  Okan (Galatasaray), ...') was 178.8 million inferences in each language and refused, where it was 4.1 million and
  read; a name must follow the comma now (the guard's arm is red there, and no hand lesson reproduces the three groups
  it needs). Of the store: the line that said the dictionary's `entresijo' as a secret again first made it the Spanish
  writer's word for every secret (writerword2.py: `secreto' to `entresijo'), and is out -- no sentence of the controls
  has one; and the whole case's scan of the vocabularies found `retroscena', a masculine noun in `-a', with no line
  `"retroscena" is not feminine.' (stated_gender). Each mend took a fresh store: KB277 the first, KB278 the second,
  KB279 the final.
  THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT (the data column's three heaviest risers, into English, over a
  copy of the library per rule on KB279): the Spoleto fifteenth (+2.41 million) and the Veloso fourth (+1.74 million)
  are the reporting rule's, a verb that can report alone with a speaker after it, whose readings are the new texts
  above; and Tempi's 27th (`Quando infatti nella "sala delle firme" è iniziato il vertice, Berlusconi era già convinto
  che l'apertura dell'Olivo fosse solo un modo per prendere tempo', 21.2 million inferences to 23.1, its text the same)
  was the date's front in a relative clause, 1.83 million: each reading of a relative word that an article follows asked
  the six words after it for a month, as a lexeme each. Whether a month is among the sentence's words is a note made
  once a sentence now (`$tr_month', in tr_into_ir/4, asked first by the clause and by tr_rel_time_comma/3), and the
  sentence is 21.25 million (+0.14 %); the whole controls fall 0.228 % against the round before the note, every text the
  same. No other rule moved any of the three by more than 7 600 inferences (the joined past verbs 7 570, the order
  adjective's count 4 800).
  THE STATED COSTS: the reporting rule's two readings, the Spoleto fifteenth refused into English (on purpose: the car
  that struck the girl is a third person nobody names) and the Veloso fourth's `con Gilda' moved, 2.4 and 1.7 million
  inferences more in each language; the writer's first word for a defender is `defensor' (a football back is `zaguero',
  which a report of a match would want: no sentence of the controls has one) and for a gang `banda'; and a bracket in a
  list is an item only before a name, which a hand lesson does not show.
  The report LEAVES, of the 14 into Spanish (English alike unless it says): `Juicio Grazioli' and `Trial Grazioli' (3:
  the Grazioli trial, the name after the noun of a heading); `de setenta y siete' and `seventy-seven' (4: of '77); `con
  sus confesiones' written last (5: the phrase in front of the relative clause's verb, `che con le sue confessioni ha
  consentito'), `tras la abducción' (`el secuestro') and `the noble Roman one' (the Roman nobleman), and English `who
  has allowed to establish' (made it possible to establish); English `has been never found' (6: has never been found);
  `Son éstos las peticiones' (7: `Éstas son', the pronoun's gender), `a finales de la requisitoria' (`al final'), `al
  juicio' (`en el juicio') and `en tribunal penal' and `in court of assizes' (the article), and English `The requests
  ... are these' (These are the requests); English `everyone of the gang of the Magliana' (8: all of the Magliana gang);
  English `asked for the conviction to eight years' (9: a sentence of eight years, `condanna' a conviction to the
  lesson); `Ha revelado él' (10: the cleft's statement, `Fue él quien reveló'), `pasado' for `avvenuto' (occurred) and
  `de hecho' written last; `ancho crédito' (11: `amplio') and English `who believes fully reliable' (whom he believes)
  and `they have also admitted his position' (he has: the clause after `visto che' has nobody named); `sobre la base de
  las que' (12: `de las cuales'), `en el curso del juicio' and `in the course of the trial in the end' written last, and
  English `the made phone calls' (the phone calls made), `to hold the contacts' (to keep in touch) and `to attain the
  ransom' (to obtain it); and `el 17 de julio próximo' (13: `el próximo 17 de julio'). The next sample's controls take
  this report in.
  The ceramist report (AnCora CESS-CAST-P-20011202-118, 26 sentences, the paper's report on the ceramist of Gràcia who
  keeps the lower panels of Salvador Seguí's plaque and offers them to the `Comando Ciudadano Justiciero' that kidnapped
  it, Spanish into Italian and English: 26 of 26 and 19 of 26 on a fresh store, 17 and 10 with the new store alone, 6
  and 5 with the new code on the old store, 5 and 4 before; reasoning 1.0.29). The sample was taken on the cocolog
  3.18.0 binary, master's 914e98a merged as 3f471ba, and cocolog stays 3.18.0; master's 0979598, b35b25b and 81579bd
  (cocolog 3.19.0, 3.19.1 and 3.19.2) came during the sample, change nothing under library/reasoning/, and are not
  merged: the next sample takes them. The article's sentences fall from 54.6 million inferences into Italian and 54.4
  into English to 23.9 and 23.3. English refuses 5, 7, 13, 14, 16, 22 and 26 for the third person nobody names, on
  purpose: `A Xavier Oliveras le encargó el monumento Enric Ángela, ...' and `Al nutrido acto inaugural asistió incluso
  el comisario de policía del Raval' take the subject after the verb for an object, `Después telefoneó sin éxito al
  ayuntamiento', `"No conseguí averiguar con quién tenía que hablar"' (the imperfect's first person is spelled as its
  third, and no pronoun says which), `recuerda', `Ahora los ofrece ...' and the middle piece of 26, `Me da risa'.
  It needed these SHAPES, each with its arm red (test/translate.pl's `newspaper_ceram': 40 checks, 48 arms, 43 red in
  the section, one red in newspaper_es and four guards of cost that stay green, below; an arm is a library directory of
  symlinks whose reasoning/translate.pl is the edited copy, `COCOLOG_LIBRARY=ARM cocolog query
  "use_module('test/translate.pl'), newspaper_ceram, checks_done"', under two seconds a run, and every arm is run in
  twenty seconds, four at a time): a participle after the copula's phrase of `of' takes the phrase after it (`Xavier
  Oliveras es el autor de la placa original dedicada al Salvador Seguí' is the plaque devoted TO him, and with the
  phrase the copula's English wrote `the devoted plaque to': tr_participle_predicate/3); AN ARTICLE BEFORE A FIRST NAME
  THE LESSON STATES, WITH CAPITALS AFTER IT, IS NO NOUN'S ARTICLE (`dedicada al Salvador Seguí' is to Salvador Seguí --
  `salvador' is a noun too, and it was `the Saviour Seguí': tr_np/3), never before a name the lesson does not state
  (`Pedro ve la Tate Gallery' keeps its article, a guard) -- two arms; a participle after a comma with nothing to close
  it takes its agent (`la placa ..., secuestrada por el comando' was kidnapped BY it, where the phrase of `por' was the
  clause's, `for the commando': tr_phrase_aside/4); A HEADING IN CAPITALS AT THE HEAD OF A SENTENCE IS A PIECE OF ITS
  OWN (`EL ENCARGO La historia de estos plafones es genuinamente kafkiana' is the heading and then the sentence, and
  read as one piece it had no reading: tr_caps_heads/2), and so are `LA PERIPECIA' and `EN EL TALLER'; a count after the
  verb opens its subject (`La placa la forman cuatro plafones' is four panels forming it, and with a count no subject's
  first word the sentence was refused: tr_subject_opener/1); `se' before an object pronoun is the verb's own where the
  lesson states its reflexive meaning (`Un camión de reparto apuró el giro en la calle de la Cadena y se los cargó'
  wrecked them, `The reflexive verb "carga" means "wrecks".', and taken for the dative of `le los' it was `loaded them
  to her': tr_expand/3), and a verb with no reflexive meaning keeps the dative (`Pedro se los da' gives them to her, a
  guard) -- two arms; A CAPITALISED WORD AFTER A STREET'S NOUN AND ITS `of' IS THE STREET'S NAME (`en la esquina de la
  calle de la Cadena' -- `cadena' is a chain to the lesson, and it was `of the Chain': tr_stated_names0/2, `"calle" is a
  street.', and `plaza', `avenida', `paseo', `rambla' and `carretera', Italian's `via', `piazza', `corso', `viale',
  `vicolo' and `strada'); the corner of a street is where one is AT (`en la esquina de la calle' was `in the corner':
  tr_comps_out/7), and the corner of a house one to be in (a guard) -- two arms; the person after the infinitive of a
  verb of taking is a phrase of `from' (`para saber el coste de la placa ... y reclamarlo a la aseguradora del camión'
  is to demand it FROM the insurer, where English wrote `to': tr_comps_out/7), after the infinitive's pronoun and after
  its object (`reclamar el coste a la aseguradora') -- three arms; `returns' and an infinitive is the infinitive's verb
  done again (`volvió a hacer los plafones dañados' made them again, where English wrote `returned to make':
  tr_write/4); A PREPOSITION AND THE QUESTION WORD FOR WHO OPEN AN INDIRECT QUESTION (`no conseguí averiguar con quién
  tenía que hablar' is with whom I had to speak, and the words had no reading: tr_complements0/4, after a verb that
  takes the question and after the infinitive of one, `"averigua" takes the question.') -- two arms -- asked in a
  sentence with a word the lesson gives `who' only ('$tr_who_word', made once a sentence in tr_into_ir/4: a guard of
  cost, whose arm stays green), and English writes `whom' (tr_comp_out/7); THE PRETERITE OF `ir' IS THE VERB OF GOING
  WHERE A PHRASE OF `to' FOLLOWS IT (`el ceramista ... fue a la plaza de Sant Jaume' went to the square, and read as the
  copula's past it was `was to the square', where Italian has no `fu' for it, `andò': tr_copula_goes/4), in a clause a
  coordinator joins, and with no phrase of `to' it stays the copula (`La casa fue de Pedro', a guard) -- three arms; a
  preposition and `quien' open a free relative (`entregarlos en el ayuntamiento a quien correspondiera' is to the one it
  was due to, and `quien' was read as the relative of the phrase before it, which no phrase took: tr_np/3,
  tr_phrase_words/4, tr_complements0/4) -- two arms, and the word's own relative test asked before its lexeme's, in a
  sentence with such a word ('$tr_free_rel'), a guard red on the store alone; English writes `whom' after a preposition,
  for a person (`el hombre con quien habla Juan' was `with which': tr_relative_out/5); A PERSON MARKED AFTER AN
  ACCUSATIVE PRONOUN IS THE ONE IT GOES TO (`Ahora los ofrece desinteresadamente al comando' offers them TO it --
  Spanish marks no second object with `a' -- and read as the person object the commando was what was offered, `Li offre
  il commando': tr_accusative_dative/4), with adverbs between the pronoun and the person, and only where the person's
  marker stands among the source's words (`Se les llamará chicos', whose `les' a lesson may leave no dative, was `Li si
  chiamerà a ragazzi': a guard red in newspaper_es, which the whole case found) -- three arms; `in case' is an English
  connector (`por si desea reponerlos': en_connector/1); THE WORD FOR `like' AND A CLAUSE THAT NAMES ITS SUBJECT IS A
  COMMENT OF `as' (`que el monumento a Seguí quede como él se merece' is as he deserves, where it was `like he
  deserves': tr_complements0/4), a subject after its verb too, read with nobody named and an object (`como dice el
  ceramista': tr_rel_subject_fix/2) -- two arms -- asked only where a verb form stands among the first four words after
  it, with only words that may go before a verb before it (tr_like_head/3, tr_like_pre/1: a guard of cost, whose arm
  stays green; with a verb form anywhere, `como "un punto de encuentro"' was read for the verb `encuentro'); A PRONOUN
  OF SOMEBODY OR NOBODY WITH ITS PHRASES IS A SUBJECT (`Por fin alguien con sensibilidad se ha preocupado de que ...' --
  the phrase reader reads no pronoun: tr_subject/6, tr_subject_shape/4), an object pronoun after its phrases the verb's,
  and never before a phrase of `of', which says how many of them (`se nessuno di voi ci ha mai creduto' is none of you,
  a guard) -- three arms, and the subject reader's clause a rule whose arm stays green, which stays for its cost
  (without it the shape's reading is asked again further on); an object before the infinitive is the verb's, never one
  after it (`Creo que van a restaurar la parte de arriba' had the part for the restoring, and taken for the verb's
  object it left nobody to go: tr_read_generic/4), and THE VERB OF GOING IN THE PRESENT BEFORE `a' AND AN INFINITIVE IS
  THE NEAR FUTURE (`"va" takes the future.': `they will restore', `restaureranno', where it was `they go to restore' and
  `vadano a restaurare': tr_near_future/3), in a clause of `that' too -- three arms; THE SIDE AFTER A COLON MAY BE A
  CLAUSE OF `that' ALONE, A COMMA, A COORDINATOR AND A CLAUSE (`Pensé: que se vayan al carajo, y me volví con los
  plafones' is what I thought and then what I did, and no clause read the first half: tr_read_after_colon/5); an adverb
  at the head, its comma, a coordinator and the rest (`En todo caso, y aunque no soy restaurador, me pongo a su
  disposición' -- a coordinator after the front's comma opened a second clause with nothing before it: tr_read0/4); A
  NOUN'S OWN CLAUSE AFTER AN INSERTION BETWEEN COMMAS (`En cuanto al anuncio por parte del Ayuntamiento, tras el
  publicitado robo, de que habían empezado hace dos meses los trámites para restaurarla' is the announcement THAT they
  had begun, and read after the insertion it was a relative clause on the theft, `of which': tr_read0/4, tr_that_set/1);
  `puts' with its own pronoun and nothing put is putting oneself somewhere (`me pongo a su disposición' is I put myself
  at his disposal, and with the pronoun dropped it was `I put at his disposal': tr_write/4); `al' AND THE INFINITIVE OF
  A VERB WHOSE MEANING THE LESSON STATES WITH ITS PRONOUN (`Al enterarse de la acción del Comando ...' is on finding out
  about it, and the front had no reading: tr_complements0/4, upon(reflexive(F), Cs)), its governed phrase marked
  (tr_ptc_governed/4) and crossed by that meaning (tr_cross_comp/2, '$tr_gov_sense'), and the lesson's language writes
  its gerund (`Venendo a sapere della azione') -- three arms; and a relative clause between its commas after the front
  of `al' is its last phrase's (`Al enterarse de la acción del Comando Ciudadano Justiciero, que secuestró la placa ...'
  is the commando that kidnapped it, and with the front ended at the comma the clause was one of `that' with nobody
  named: tr_upon_rest/5).
  It needed these WORDS in `extra/' (the two readers: a line moves the reader of one language and the writer of the
  other; the dictionary's own word is said again first where it must stay the one written): Spanish `ceramista' (a
  ceramist, a person of either sex), the name `Comando Ciudadano Justiciero' and `justiciero' (a vigilante, a person),
  `frecuenta' (frequents, with its forms: the dictionary has no `frecuentar'), `placa' (a plaque, the plate second),
  `plafón' (a panel, with `junta' and then `tablero' said again first, so that they stay the words written for a board
  and a panel), `semirrelieve' (a half-relief), `genuinamente', `"coloca" takes the passive.', `despacho' (an office,
  with `oficina' said again first), `camión de reparto' (a delivery truck), `apura el giro' (cuts the corner, with its
  forms), `carga' (loads, and wrecks with its own pronoun), `servicio jurídico' (the legal service), `de inmediato'
  (immediately, `inmediatamente' said again first), `averigua' (finds out, with its forms, taking the question), `de
  Herodes a Pilatos' (from pillar to post), `harta' (satiates, and gets fed up with its pronoun; `sacia' said again
  first), `al carajo' (to hell), `desidia' (neglect, `negligencia' said again first) and `mala educación' (bad manners),
  `entera' (informs, and finds out about with its pronoun, taking `de'; `informa' said again first), `peripecia' (a
  misadventure), `artículo de regalo' (a gift item), `desinteresadamente' (selflessly), `por si' (in case), `a
  disposición de' (at the disposal of) and `a su disposición' (at his disposal), `por fin' (finally, `finalmente' said
  again first), `de arriba' (upper, `superior' said again first), `publicitado' (publicised), `da risa' (amuses,
  `divierte' said again first), `a buenas horas' (belatedly), `fija' (notices with its pronoun, taking `en'), `"calle"
  is a street.' and the other five, the tenses and persons of `tiene que' (the dictionary gives the modal no imperfect,
  no future and no first person, and `tenía que hablar' had no reading), `preocupa' (concerns, said again first, and
  worries with its pronoun, taking `de' before the clause; `concierne' said before it), `"va" takes the future.' and
  English's `wrapped' (the upstream verb table's row for `wrap' is broken, and the writer made `wraped'); Italian
  `ceramista', `giustiziere', `frequenta' (frequents, `attends' said again first), `targa' (a plaque, the number plate
  first still), `mezzorilievo', `primavera' (the writer's word for spring was `fonte', a spring of water), `angolo' (a
  corner, the angle said again first: the writer's word was `angoletto'), `bancone' (a counter, where the writer's word
  was `contatore', a meter), `colloca' (places, where the writer's word was `dispone'), `camion delle consegne',
  `stringe la curva' (with its forms), `sfascia' (wrecks, with its forms), `servizio legale', `scopre' (finds out,
  `discovers' said again first, taking the question), `da Erode a Pilato', `stufa' (gets fed up with its pronoun,
  `stews' said again first), `al diavolo', `maleducazione', `viene a sapere' (finds out about, with its forms and
  gerund, taking `di'), `peripezia', `articolo da regalo', `disinteressatamente' (`disinterestedly' said again first),
  `nel caso che' (in case, with the subjunctive: `nel caso' alone joined `nel caso di', in the case of), `a disposizione
  di' and `a sua disposizione', `pubblicizzato', `diverte' (amuses, with its forms: the dictionary has no `divertire'),
  `kafkiano', `laboratorio' (a workshop, the lab said again first: the writer's word was the English `workshop'), the
  past and the participles of `spacca' (the dictionary gives `spaccare' none, and the Italian was refused), the six
  streets, `chiamata' (a call, where the writer's word was `richiamo', a recall), `assicuratrice' (an insurer: the
  Italian had no word for one, and the sentence was refused), `ceramica' (pottery: the dictionary's noun is mud),
  `accuratamente' (carefully), `preoccupa' (worries, with its forms: the dictionary has no `preoccupare'),
  `restauratore' and `restauratrice' (a restorer, persons), `formalità' (formalities) and English's `wrapped'. The first
  meaning moved for 4 Spanish words and 6 Italian ones (Spanish `carga' loads, `despacho' an office, `entera' informs,
  `placa' a plaque; Italian `accuratamente' carefully, `bancone' a counter, `ceramica' pottery, `chiamata' a call,
  `colloca' places, `stufa' stews), the writer's first word for 1 Spanish meaning and 7 Italian ones (Spanish genuinely
  `genuinamente'; Italian call `chiamata', corner `angolo', counter `bancone', spring `primavera', workshop
  `laboratorio', places `colloca', worries `preoccupa'), and none was lost.
  THE CONTROLS (cocolog 3.18.0, store KB287, 124 count files, 3 348 sentences: the earlier set with the Grazioli trial
  in, it_9310_9323, both directions; this report is not among them): the last version's translator against this one, on
  the one store, 13 sentences read differently, all better -- the near future (9: Tatoeba's `I will sleep in the flat',
  `What will I do with his letter?', `Do you doubt that he will win?', `you will fatten', and Italian `Dormirò
  nell'appartamentino', `Cosa farò', `Dubiti che lui vincerà?', `ingrasserai' and `Non durerà', where they were `I go to
  sleep', `What do I go to make' and `vado a dormire'), `whom' after a preposition (2: `for the lawyers, to whom one
  retains 20% of the incomes', `to whom an objective and uniform reference point is needed') and `again' (2: `And the
  panther sharpens the claws again', `I will call the two and a half ones again') -- and the inferences rise 0.152 % (6
  637 129 931 to 6 647 206 601): 3 338 sentences rise, by 1 021 inferences at the median, and the ten that fall are
  Tatoeba's near futures (784 at most). Bytes and characters read every sentence alike (0 differ, the bytes 0.011 %
  more). The DATA COLUMN (the last version's translator on its own store, KB279, against this one on the new): 26
  sentences, the code's 13 and the store's 13, +0.178 % (6 635 403 451 to 6 647 206 601). THE CODE ALONE (this
  translator on KB279): 4 sentences, all among the 13 (the near future needs `"va" takes the future.'), +0.152 % (to 6
  645 470 382), and every sentence rises. THE STORE ALONE (the last version's translator on KB279 and on KB287): 13
  sentences, +0.026 % (to 6 637 129 931), 10 better, each a word of the report's lines -- `collocata' and `collocare'
  for `colocada' and `colocar' (3, where it was `disposta' and `disporre'), `un angolo molto solitario' (where it was
  `angoletto'), `would have amused him' and `lo habría divertido' for `l'avrebbe divertito' (where it was `would have
  him fun' and `lo tendría divertido'), `could place between the 70 and the 90 thousand lire', `Era preocupado
  sinceramente de que', and Tatoeba's `They put to work immediately' and `si misero a lavorare subito' (where it was `of
  immediate' and `d'immediato') -- and three that are the stated costs below. KB287 and the KB285 before it read every
  sentence of the controls alike, with either translator (the lines that keep the writers' words move no sentence of
  them).
  THE FIRST ROUNDS' REGRESSIONS, found by reading the texts of every column, the whole case and the writers' first
  words, and mended. Of the store (the store-alone columns of the first stores, KB281 to KB285): `"anuncio" means
  "announcement".', said for the report's `En cuanto al anuncio', made every ad an announcement (`un tablón donde dejar
  anuncios diversos', `un bonito anuncio de biquinis'), and is gone (the report's `the ad on the part of the town
  council' is the cost); `por fin' and `de inmediato' said first were the Spanish writer's words for finally and
  immediately (`Por fin, la reprimenda', `Me ha dicho de inmediato', `desde de inmediato' for `da subito', five
  sentences), and `da risa' its word for amuses, which has no participle, so that `la cosa l'avrebbe divertito' was
  refused: the dictionary's `finalmente', `inmediatamente' and `divierte' are said again first; Italian `nel caso', a
  conjunction with the subjunctive, took `nel caso di' for it, and five sentences were refused in both languages (`Nel
  caso di un bambino, poi, è ancora meglio', `tre nel caso delle Eolie', `nel caso del Giglio'): it is `nel caso che'
  now; and the writers' first words of the last store found six Spanish words the new lines had moved (informs `entera',
  concerns `preocupa', satiates `harta', upper `de arriba', neglect `desidia', panel `plafón'), and saying `tablero'
  again first moved the word for a board from `junta' to `tablero': the dictionary's words are said again first, `junta'
  before `tablero' (KB287, the final store). Of the code: the dative rule took `Se les llamará chicos', whose hand
  lesson leaves `les' no dative (`Li si chiamerà a ragazzi', the whole case's newspaper_es), and asks the person's
  marker among the words now; a pronoun's phrases kept as one term inside a phrase of `of' broke the crossing, and the
  clitic guard of tr_subject_shape/4 stands in its place; the reflexive `puts' cut its search before its test, and
  `Pedro se pone en la casa' was refused (once/1 now); and the comment of `as' cut the reader around it where its test
  held and its reading failed (once/1 now).
  THE COST OF THE CODE, FOUND BY TAKING EACH HUNK OUT (twenty sentences of the controls of 0.3 to 3 million inferences,
  Spanish into English, over a copy of the library per hunk on the old store, KB279): the first cut rose 42 731
  inferences of 14.53 million (+0.294 %), and the comment of `as' was 26 598 of it, its clause asked of every word for
  `like' with a verb form anywhere after it -- the four words, the words before the verb form and a reading that names
  its subject leave 100 --; and taking each rule out of the next cut, the question word after a preposition was 11 500
  (two clauses, 6 900 and 4 600, that asked the lexicon of the word after every preposition: they are asked now in a
  sentence with a word the lesson gives `who' only, a note made once a sentence), the heading in capitals 4 200, the
  noun's own clause after an insertion 2 300, the pronoun's shape 1 500 and the verb of going 500, no other rule over
  500. The final cut rises 32 748 (+0.225 %, 14 567 146). Over the whole controls every sentence rises, by 1 017
  inferences at the median, and the code alone is +0.152 %: the largest rises are the Rognoni interview's nineteenth
  (+0.12 million of 176.1, refused both ways), the Venice report's eighth (+0.09 of 250.5) and es_20001201-176 5 (+74
  736 of 3.39 million, +2.2 %: `como podía esperarse de los dos equipos' is asked as the comment of `as' and read as
  before), the text the same.
  THE STATED COSTS: a first meaning that serves the news and not every text -- `placa' is a plaque (a plate second),
  `despacho' an office (the dispatch second), `entera' informs (whole, the adjective, second), `carga' loads (the load,
  the noun, second), Italian `bancone' a counter (a bar second), `chiamata' a call, `colloca' places (disposes second),
  `stufa' stews (the stove second) -- and the writers' `genuinamente' for genuinely, `primavera', `angolo', `bancone',
  `laboratorio', `colloca', `chiamata' and `preoccupa'; the store alone's three: `Era sinceramente preoccupato che ...'
  (it_10059_10095 29) is refused into English, where it was `It was worried earnestly that ...' (`preoccupato' is a
  verb's participle now, and English refuses its passive with nobody named, on purpose), and Tatoeba's `No tienes que
  decírselo a tus padres', refused before, is read now in both languages and wrong (`You must not say him your parents',
  `Non devi dirselo i tuoi genitori': the persons of `tiene que' read it, and no rule reads the person a dative pronoun
  joined to an infinitive says again); `En cuanto al anuncio ...' is the ad (above); and the inferences, +0.152 % on the
  one store and +0.152 % for the code alone.
  The report LEAVES, of the 26 into Italian: `rapito dal commando' (2: the plaque's `rapita', the participle agreeing
  with no noun after the apposition) and `davanti al loro abissale stato' (its: `en vista del suo pessimo stato');
  `salva' for `guarda' (3: keeps) and `inferiori' (lower); `Gli commissionò il monumento Enric Ángela ... a Xavier
  Oliveras' (5: the dative said twice, and the subject after the verb), `dopo fissarsi in una targa' (`dopo aver notato
  una targa'), `Sindacato di Cuadros' and `nella strada di Balmes' (`in via Balmes'); `si collocò' (6: `fu collocata')
  and `nell'angolo della strada della Cadena con Sant Rafael'; `per conoscere il costo' (11: `sapere'); `la
  rimpiazzerebbe subito ritornò a fare' (12: `l'avrebbe sostituita', `rifece'); `dopo' written last (13); `con chi
  doveva parlare' (14: `dovevo', the first person); `Quello fu d'Herodes Pilatos' (16: the adverb of the lesson's line
  not read after the copula, `da Erode a Pilato'); `d'un luogo a altri' (18: `da un posto all'altro'); `che si vanno al
  diavolo' and `mi ritornai' (19: `vadano', `tornai'); `miscelata' (20: `mischiata'); `gli tolse la polvere ai pannelli'
  (21: `spolverò i pannelli', the dative said twice), `così salvati' (kept), `in Gràcia' (`a Gràcia') and `che gli costò
  trovarli' (which he had trouble finding); `adesso' written last (22); `infine' and `rimane' (23: `finalmente', the
  subjunctive `rimanga'); and `che anche è danneggiata' (24: `che è anche'). Of the 19 into English: `in front of their
  abysmal state' (2: given its dreadful state); `saves the inferior panels' (3: keeps the lower ones); `the street of
  the Cadena' (6, 10, 12: Cadena Street) and `with Sant Rafael'; `a pair of years' (9: a couple); `a call of the legal
  service' and `to know the cost' (11: from, find out); `would replace her immediately made the damaged panels ... to
  substitute them again' (12: it, and `again' after the purpose); `to hand them in the town council to the one that
  corresponded' (15: to whoever it concerned); `I conserve' and `many doors of office' (17: keep, office doors); `Nobody
  knew nothing' and `of a place to others' (18: anything, from one place to another); `and mixed bad manners with
  bureaucracy' and `they regret' (20: bad manners mixed with bureaucracy, he complains); `to restore her', `removed him
  the dust to the panels', `saved in the bottom of his workshop of ceramist of gift item so' and `who cost him to find
  them' (21); `they say' and `remains' (23); `that also is damaged' (24); and `I am not restorer' and `at his disposal'
  (25: a restorer, theirs). The next sample's controls take this report in.
  The two television reports (VIT-9296..9309, 14 sentences: Alba Parietti's interview on Danish and Swedish television,
  and a parliamentary question on the RAI programme `generale per una sera', Italian into Spanish and English: 14 of 14
  and 14 of 14 on a fresh store, 10 and 12 with the new store alone, 3 and 3 with the new code on the old store, 3 and 3
  before; reasoning 1.0.31). The sample was taken on the cocolog 3.19.2 binary, master's 81579bd merged as 2bfab94, and
  cocolog stays 3.19.2; master's 51833fe and f7b0389 (cocolog 3.19.3 and 3.19.4) came during the sample, change nothing
  under library/reasoning/, and are not merged: the next sample takes them. The commit before this one (c4b9894, the
  load with no warning) counted 167 warnings: they were 177, the 167 blocks and ten warnings of 11 variables a clause
  names once, in 10 clauses. The article's sentences fall from 35.4 million inferences in each language to 31.8 into
  Spanish and 31.7 into English.
  It needed these SHAPES, each with its arm red (test/translate.pl's `newspaper_tv': 44 checks, 36 arms, all red in the
  section; an arm is a library directory of symlinks whose reasoning/translate.pl is the edited copy,
  `COCOLOG_LIBRARY=ARM cocolog query "use_module('test/translate.pl'), newspaper_tv, checks_done"', under a second a
  run, and every arm is run in twenty seconds, two at a time): A NAME AND A NUMBER OF ONE OR TWO DIGITS ARE ONE NAME
  (`"cinici e diseducativi" i film - Wargames di rai 1' is the channel Rai 1, as `Canale 5' and `Tg 4' are names; read
  apart, the number was a count with no noun and the headline was refused: tr_name_numbers/3, a name the lesson states,
  in small letters too, `"rai" is a name.', or a capital word the lesson does not know), never a count, where a noun
  follows the number (`a Roma 24 anni fa' is in Rome 24 years ago, and joined as the name `Roma 24' the Veloso
  interview's 34th sentence was refused in both languages: found by the controls) -- two arms; TWO ADJECTIVES JOINED
  BEFORE A DETERMINER SAY WHAT THE PHRASE IS (`"cinici e diseducativi" i film' heads the films that are cynical and
  miseducative, and the coordination, read before the clause of one adjective can be and cut, refused the piece:
  tr_read0/4), in a piece of ten words at most with no comma (a guard of cost, whose arm stays green: `Lapidario ma
  significativo il commento del primo presidente ..., Nicola Marvulli:' was asked as one and cost 67 thousand inferences
  more, its text the same), and a quotation that closes inside the sentence before a determiner is no mark of the
  sentence (with the mark the sentence's it came out `"The films are cynical and miseducative".': tr_head_mark/4) --
  never a quotation the speaker's verb follows (`"in ogni caso" puntualizza lui, "comincerò ...' kept its comma and its
  marks, which the first cut, any word after the close, lost in six texts of the controls: `"He clarifies, in any case"
  I "will commence', `"Hablará tras el 21 de julio" dice', and two refused), the lesson of the side the text is read on
  asked (tr_from_side/3 before tr_head_mark/4: with the target's language set, Spanish took no Italian determiner and
  wrote `"Las películas son cínicas y deseducativas"') -- four arms; a demonstrative and an article at the head of the
  side after a colon have their copula read in (`un'iniziativa "cinica e diseducativa": questo il giudizio dei deputati'
  -- this IS the judgement, and read without its verb English wrote `this the judgement': tr_demonstrative_copula/3); A
  BARE NOUN THAT IS ITS OWN PLURAL TAKES THE NUMBER OF THE PARTICIPLE AFTER IT (`un ciclo di film dedicati' is a cycle
  of FILMS, `"film" is the plural of "film".', and read in the singular it came out `un ciclo de película dedicadas':
  tr_cross_np/2, agrn/1); A PARTICIPLE IN THE OBJECT'S PHRASE OF `of' TAKES THE PHRASE AFTER IT WHERE ENGLISH SAYS THE
  PARTICIPLE WITH THAT PREPOSITION, after any verb (`Il programma propone un ciclo di film dedicati alle grandi
  battaglie' is a cycle of films DEDICATED TO them, and with the phrase of `to' the clause's English wrote `a cycle of
  dedicated film to the big battles': tr_participle_predicate/3, en_ptc_takes/2, `dedicates', `devotes', `addresses',
  `links', `destines', `assigns'), never a phrase English does not say the participle with, which may be the verb's
  (`compró un coche usado en Madrid') -- two arms; A SINGULAR NOUN THAT IS A COMMAND TOO, BEFORE A PHRASE OF `to' OR
  `of', HEADS A HEADING (`Intervista alle televisioni danese e svedese' is the interview, and read as the command
  `intervista!' English wrote `Interview to the Danish and Swedish televisions' or refused it: tr_noun_heading_start/1),
  and AN INTERVIEW IS WITH SOMEBODY (`In un'intervista a una tv danese' -- the Italian and the Spanish say the one
  interviewed with `to', and the phrase of `to' right after the noun is `with', the Spanish writer's `con':
  tr_cross_comps/2, tr_interview_comp/1), only after the noun for an interview (`dà un libro a una donna' gives it TO
  her) -- three arms; AN INFINITIVE WITH ITS REFLEXIVE PRONOUN CROSSES BY THE MEANING THE LESSON GIVES IT SO, as the
  verb of a clause does (`la libertà delle donne di denudarsi davanti ai telespettatori' is their freedom to STRIP, `The
  reflexive verb "denuda" means "strips".', and crossed by the plain `bares' it came out `to bare', which Spanish has no
  verb for, and the sentence was refused: tr_cross_comp/2), the pronoun going with the reading unless English too says
  the meaning of oneself (en_true_reflexive/1), and the lesson's writer puts its own back where its verb states the
  meaning as reflexive (`desnudarse', tr_comp_out/7) -- two arms; A SECOND AGENT AFTER THE COMMA, WITH ITS OWN TIME, IS
  THE PARTICIPLE'S (`in una intervista trasmessa giovedì sera dalla tv danese, e ieri da quella svedese' is broadcast by
  the Danish television, and yesterday by the Swedish one, the participle left out; read as the clause's, the second was
  a phrase of `from': tr_second_agent/2); a day and its part before the agent (`trasmessa giovedì sera dalla tv danese'
  was broadcast on Thursday evening BY it, and with the time read alone the agent was `from the Danish television':
  tr_reduced_agent/3), in a subject too, where the phrase ended at the participle (tr_phrase_words0/4,
  tr_time_before_agent/2), and English says a weekday and its part with `on' (tr_comp_out/7) -- four arms; TWO HEADINGS
  PARTED BY A DASH ARE EACH READ AS A PIECE OF ITS OWN (`"cinici e diseducativi" i film - Wargames di rai 1' -- the
  readers of a heading ask for the whole piece, which neither half was, and the headline was refused: tr_read0/4,
  tr_as_piece/2), each half eight words at most with no comma and no verb in the second; a name with its phrase of `of'
  is a heading (`Wargames di rai 1': tr_verbless0/3); A HEADING WITH ITS PURPOSE, THE RELATIVE CLAUSE ON ITS LAST PHRASE
  (`Una interrogazione parlamentare per denunciare il cinismo della trasmissione "generale per una sera", che esalta la
  cultura della guerra' -- the programme, which exalts it; divided at the comma, the clause was one of `that' with
  nobody named, which English refused: tr_verbless0/3), asked only where a word that begins the purpose stands before
  the comma (a guard of cost); a second noun that is a preposition too says no kind (`al ministro delle poste contro
  "generale per una sera"' is the question against the programme, and `contro' is a noun too, the con of pros and cons
  -- read as the kind of mail, English wrote `the con mails': tr_np/3); A DEMONSTRATIVE THE COPULA SAYS IS A NOUN TAKES
  THE NOUN'S GENDER (`questo il giudizio' is `este es el juicio', `Esa es la principal conclusión' `Quella è la
  principale conclusione', and written as the lesson's own neuter it was `esto es el juicio', `Quello è':
  tr_subject_out/6, the lesson's first demonstrative in the noun's gender, never one of no gender); a title's words are
  no verb's complements (`il cinismo della trasmissione "generale per una sera"' came out `de la transmisión a "general
  durante una noche"', the general marked as the clause's object: tr_np_out/5); A DENIED INFINITIVE'S `still' IS ITS
  `yet', inside it (`di non aver ancora sviluppato un sentimento comune' is of not having YET developed one -- pulled to
  the clause's verb, English wrote `has still accused': tr_comps_out/7, and tr_pull_adverb/3 takes no adverb right after
  a denied infinitive), and English's `not' stands after the preposition a gerund takes (`of not having evolved', where
  it was `not of having evolved': tr_comp_out/7) -- three arms; A SERIES OF INFINITIVES AFTER A COMMA ARE ALL THE
  VERB'S, EACH WITH ITS PREPOSITION (`ha accusato le donne di non essersi evolute ..., di non aver sviluppato' accused
  them of not having evolved, of not having developed, and with the verb's preposition for its first infinitive alone
  the second came out `not to have developed': tr_comps_out/7), and the lesson's writer gives each its word (`de no
  dormir, de no comer', where it was `no de dormir, no comer': the plain and the denied infinitive after a comma, and
  the word before a denied plain infinitive, `de no dormir', tr_comp_out/7) -- five arms; A DENIED INFINITIVE AFTER THE
  WORD THE SOURCE KEPT BEFORE IT TAKES NO OTHER (`fiel a su consigna de no arremeter' is `fedele alla sua direttiva di
  non assalire', where it was `di non d'assalire', and the first cut's word before a denied infinitive wrote `di di non
  assalire': tr_comps_out/7, found by the controls), the plain infinitive's writer asking what the one with its pronouns
  asks (tr_infx_lead/1: the word a kept word leaves out, and the participle's word); A PRONOUN ON A MODAL'S INFINITIVE
  IS THE OBJECT OF THE INFINITIVE AFTER IT (`vuole poterlo mangiare' wants to be able to eat it -- Italian and Spanish
  put the pronoun of the second infinitive on the modal before it, `poterlo', `doverlo', `volerlo', `poderlo', and
  written where it stood English said `to can him to eat': tr_comps_out/7), a purpose's too; and English says what is on
  television with `on' (`le donne che si spogliano in tv', en_on_noun/1).
  It needed these WORDS in `extra/' (the two readers: a line moves the reader of one language and the writer of the
  other; the dictionary's own word is said again first where it must stay the one written): Italian `movimento' (a
  movement, where the dictionary's first is a motion, which the Spanish writer wrote `mociones'), `spoglia' (strips, and
  undresses with its pronoun, with its forms), `denuda' (bares, and strips with its pronoun, with its forms),
  `telespettatore' and `telespettatrice' (television viewers, persons), `soubrette' (a showgirl, a person, its own
  plural), the infinitive and the participles of `evolve' (the dictionary has none) with the copula its auxiliary and
  its reflexive meaning, `sul piano di' (in terms of), the copula as the auxiliary of `cambia' (`l'uomo italiano non è
  cambiato' has not changed; the Lazio report's `i valori non sono cambiati molto' was `no son cambiados'), `"alba" is a
  name.' (a first name, where the word is the dawn), `divertito' and `divertita' (amused, where the dictionary's
  adjective is fun), `intervistatore' and `intervistatrice' (interviewers, persons), `maschilista' (sexist), `mammone'
  (mother-fixated), `cinico' and `cinica' (cynical: the dictionary has the noun, the cynic, alone), `diseducativo' and
  `diseducativa', `progressista' (progressive, with `progressivo' said again first, so that it stays the word written
  for a gradual increase), `interrogazione' (an interpellation, a parliamentary question), `cambia canale' (changes the
  channel, with its forms), `esalta' (exalts, with its forms), the name `copenaghen' (Copenhagen, a city), English's
  `broadcast' as the past and the participle of `broadcasts' (its rule made `broadcasted'), `trasmette' (broadcasts,
  where the dictionary's verb conveys it, with its participles), `"rai" is a name.', `The word "tale da" begins the
  purpose.' and `come se niente fosse' (as if it were nothing); Spanish `desnuda' with its pronoun (undresses, then
  strips), `telespectador' and `telespectadora', `vedette' (a showgirl), `divertido' and `divertida' (fun said again
  first, then amused), `entrevistador' and `entrevistadora', `machista', `enmadrado' and `enmadrada', `deseducativo' and
  `deseducativa', `cambia de canal' with its forms, `exalta' with its forms, the name `copenhague', `broadcast', `en
  términos de' (in terms of: the Spanish writer had no word for it, and the sentence was refused) and `como si nada'.
  The first meaning moved for 5 Italian words and 1 Spanish one (Italian `cinico' cynical, `divertito' and `divertita'
  amused, `movimento' a movement, `trasmette' broadcasts; Spanish `telespectador' a television viewer), the writer's
  first word for 1 Italian meaning and no Spanish one (an interpellation, `interrogazione', where it was
  `interpellanza'), and none was lost.
  THE CONTROLS (cocolog 3.19.2, store KB293, 126 count files, 3 400 sentences: the earlier set with the ceramist report
  in, es_20011202-118, both directions; these reports are not among them): the last version's translator against this
  one, on the one store, 12 sentences in 12 count files read differently, all better -- the demonstrative in its noun's
  gender (4: `Quella era la condizione', `Quella è la principale conclusione', `Quella è una buona risposta', `Este es
  el texto del documento'), the agent after a day or an adverb (4: `promulgated on Thursday by the senate' and `por el
  senado', where it was `from the senate' and `del senado'; `a request advanced by the magistrates', and the Spanish of
  that sentence, it_10011_10058 18, refused before, is read now), `on Saturday morning', `on television', `la sua
  direttiva di non assalire' (es_20000903-30 5, where it was `di non d'assalire') and `podrán tener lugar' for `potranno
  svolgersi' (it_9792_9799 2, where it was `realizarse': the reflexive meaning, takes place) -- and the inferences fall
  0.031 % (6 697 195 993 to 6 695 124 592) and rise 0.032 % outside the two sentences that fall by over a million
  (it_9270_9295 8 in each language, 44.3 million to 42.2, its text the same: `Tg 4' is one name). 3 390 sentences rise,
  by 333 inferences at the median, the largest it_10011_10058 18 (+0.26 million of 1.97 into English, a new reading),
  it_9605_9636 5 (+0.10 of 2.10, the agent), Tempi's twentieth (+0.07 of 339.2, refused both ways) and it_9763_9774 12
  (+28 775 of 86 755, `Monica Ferretti Genova - Sestri P pacifismo "mascalzone".': the two headings of the dash asked
  and failing, its text the same). Bytes and characters read every sentence alike (0 differ, the bytes 0.011 % more).
  The DATA COLUMN (the last version's translator on its own store, KB287, against this one on the new): 16 sentences,
  +0.011 % (6 694 395 669 to 6 695 124 592), +0.074 % outside the two. THE CODE ALONE (this translator on KB287): the
  same 12 sentences, -0.031 %, +0.032 % outside the two. THE STORE ALONE (the last version's translator on KB287 and on
  KB293): 4 sentences, all better, +0.042 % (to 6 697 195 993), 2 871 sentences rising by 275 inferences at the median
  -- `spogliarono la Francia' for `desnudaron a Francia' (es_20020601-51 3, where it was `svestirono'), `after having
  broadcast' (it_9270_9295 20, where it was `broadcasted') and the Lazio report's `the values have not changed' and `no
  han cambiado' (it_9511_9539 14, where they were `are not changed' and `no son cambiados').
  THE FIRST ROUND'S REGRESSIONS, found by reading the texts of the one store and mended, each with its arm red: the word
  before a denied infinitive wrote `alla sua direttiva di di non assalire' after the source's kept `de' (the kept word's
  clause takes the plain and the denied infinitive now, tr_comps_out/7); `a Roma 24 anni fa' was the name `Roma 24' and
  the Veloso interview's 34th sentence was refused in both languages (no name before a noun's count); and the head mark
  of a quotation that closes before more words, first asked of any word after the close, lost the marks and the comma of
  Cecchi Paone's quotations (it_9270_9295 10 in both languages, `"He clarifies, in any case" I "will commence', 15 and
  19 in Spanish, `"Esta negociación mía con la Fininvest" dice que Cecchi Paone', and 14 refused in both): only a
  determiner after the close takes the mark from the sentence now, asked with the side already set. The hand lesson
  showed one more: the lesson's neuter `esto', a demonstrative of no gender, came first for `Questa è la casa', and the
  writer takes the first demonstrative in the noun's gender, never one of no gender. Two older checks changed with the
  rules: the Bovalino section's `The dog sleeps Sunday morning.' is `on Sunday morning', and the bank section's guard
  that a bare number is no object asks `El perro va al Tg 444.' (in test/translate.pl and in lesson 46's section 77):
  `Tg 4' is one name now, and in that section's lesson a name after `al' is the object of `va', `The dog goes the Tg 4.'
  -- the guard's arm is red on `Tg 444'. The section's insertion first dropped `newspaper_grazioli_checks_2' from
  test/translate.pl, which the whole case found (`Unknown procedure'), and it is back.
  THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT (18 control sentences of 0.1 to 2 million inferences picked at
  random and the riser it_9926_9946 17, into English, over a copy of the library per rule on KB293): the first cut rose
  79 961 inferences of 10.19 million (+0.78 %), and 67 456 of them were the two adjectives joined, which asked the
  heading reader of `Lapidario ma significativo il commento del primo presidente della suprema corte di Cassazione,
  Nicola Marvulli: ...' (+6.5 % of the sentence, its text the same), and the rest the name and its number (6 891, the
  digits asked of every word), the interview (2 246), the heading with its purpose (1 634) and the noun heading (985).
  What paid was the cheap tests first: the joined adjectives in a piece of ten words at most with no comma, the length
  of the word after a name before its digits, the shape of the phrase of `to' before the interview's noun, a word that
  begins the purpose before the comma, and the preposition before the noun heading's verb form; the nineteen rise 8 547
  (+0.084 %), every text the same, and the guards of cost' arms stay green.
  THE STATED COSTS: a first meaning that serves the news and not every text -- `movimento' is a movement (a motion
  second), `trasmette' broadcasts (conveys second), `cinico' cynical (the cynic second), `divertito' amused (fun
  second), Spanish `telespectador' a television viewer -- and the writer's `interrogazione' for an interpellation
  (`interpellanza' before); `potranno svolgersi' is `podrán tener lugar' (above); `tale da poterci giocare' is `to be
  able to play us' (the pronoun goes after the infinitive, and `ci' is still read as `us', where it says `with it'); the
  dash rule's failed reading of a byline (+28.8 thousand inferences, above); and the inferences, +0.032 % outside the
  two that fall, +0.042 % for the store alone.
  The reports LEAVE, of the 14 into Spanish: `la libertad de las mujeres italianas desnudarse' (4, 8: the word before an
  infinitive after a noun's phrase of `of', `de desnudarse'); `El que no quiere ver' (5: `Quien'); `que se define ex
  feminista' (6: `como ex feminista'), `en términos de la solidaridad' (the article) and `una sensación común' (`un
  sentimiento'); `Interpelación en "general durante una noche"' (9: `sobre', `por una noche'); `los diputados
  progresivos' (11: `progresistas', the Spanish writer's word for progressive), `al ministro de los correos' (`de
  Correos') and `la transmisión' for the programme; `a finales de los que huéspedes famosos al público, releen' (12: `al
  final de los cuales invitados conocidos por el público releen') and `un juego de simulacro' (`de simulación'); and
  `postula una accesión ... para podernos jugar como si nada' (13: `presupone una adhesión ... tal como para poder jugar
  con ella'); of the 14 into English: `All the movements among the televisions' (1: the moves between the channels);
  `and by the Swedish one yesterday' (4: the adverb last); `The one that does not want to see, can change the channel'
  (5: whoever); `The Parietti, which defines ex feminist' (6: who calls herself one -- a name with its article is no
  person by its shape, as a club's is not) and `in terms of the solidarity'; `It is still sexist and mother-fixated' (7:
  he, the man before the colon not carried after it); `the minister of the mails' (11: the minister of Posts) and `the
  transmission' (the programme); `famous guests to the public, reread' (12: guests known to the public); `posits an
  accession to a culture of the war, to be able to play us' (13); and `the culture of the war' (14: the article). The
  next sample's controls take these reports in.
  The IOC report (AnCora CESS-CAST-P-20020301-99, 17 sentences: the IOC's investigation of the medical material the
  Austrian cross-country team left in a rented house near Salt Lake City, and the Spanish laboratory IMIM, Spanish into
  Italian and English: 17 of 17 and 15 of 17 on a fresh store, 15 and 12 with the new store alone, 10 and 12 with the
  new code on the old store, 9 and 10 before; reasoning 1.0.32). The sample was taken on the cocolog 3.19.5 binary,
  master's a71af87 merged as ed72782, and cocolog stays 3.19.5: the controls read every sentence alike on 3.19.2 and
  3.19.5 (3 400 sentences, 0 differ, 6 695 124 592 inferences on both). The article's sentences fall from 38.6 million
  inferences into Italian and 38.2 into English to 14.1 and 13.7. English refuses 15 for the third person nobody names,
  on purpose (`Reiteró, también, que se iban a endurecer las medidas'), and 3 (below).
  It needed these SHAPES, each with its arm red (test/translate.pl's `newspaper_coi': 31 checks, 28 arms, 27 red in the
  section and one guard of cost that stays green, below; an arm is a library directory of symlinks whose
  reasoning/translate.pl is the edited copy, `COCOLOG_LIBRARY=ARM cocolog query "use_module('test/translate.pl'),
  newspaper_coi, checks_done"', under a second a run, and every arm is run in seven seconds, three at a time): A
  RELATIVE CLAUSE WITH TWO VERBS, THE SECOND RIGHT AFTER THE COORDINATOR (`La oficina del sheriff, que declinó hacer
  comentarios y dirigió cualquier pregunta al COI, reconoció ...' -- the office that declined to comment and directed
  every question to the IOC; read to its coordinator the clause left `y dirigió ...' to the sentence, which was divided
  there, and English refused the half with nobody named: tr_relative_clause/4), the second verb in the first one's
  tense, person and number, each a verb's or a modal's form (tr_verb_lexeme/1: tr_form/5 gives any word as itself, a
  present third person singular, and the first cut took `il' and `vi' for the second verb of `che si occupa ... e il
  Ministero'), asked in a sentence that has the pattern only ('$tr_rel_two_verbs', tr_rel_two_verbs_note/1, a guard of
  cost whose arm stays green) -- two arms; a word that is a noun as well as a participle is the noun after a verb of
  suffering, receiving or causing (`sufrieron heridas al manipular el material' suffered wounds, and read as the
  participle said of the subject it was `suffered injured' and `soffrirono feriti': tr_ptc_noun_here/2); THE WORD FOR
  `nor' AND A PHRASE, SET OFF AFTER THE SUBJECT (`Ningún deportista español, ni ninguna federación, envía muestras a su
  laboratorio' -- no sportsman, nor any federation, sends them; read as a coordinated subject the halves had no reading
  with their commas, and the sentence was refused: tr_insertion_off/4), the phrase travelling as mid(nor(Phrase)) and
  written after the subject between its commas, with English's `any' where the source denied it again (`nor any
  federation') -- two arms; a word after a noun that is its adjective as well as a verb is the adjective only where it
  is the verb the reading took (the guard of `Una spesa media, per una famiglia ...' refused any piece that opens on a
  determiner, a noun, an adjective and a comma, and `Ningún deportista español, ni ...' had no reading:
  tr_adjective_not_verb/3); THE NEAR FUTURE IN THE PAST IS THE CONDITIONAL (`Reiteró que se iban a endurecer las
  medidas' -- that they would be tightened, and word by word it was `si andavano a indurire': tr_near_future/3, the
  imperfect's conditional beside the present's future), the reflexive the infinitive's and a thing's reflexive the
  passive, the thing after the verb its subject -- three arms; an English name the source's lesson calls an acronym goes
  out in capitals (`El COI' is the IOC, `"ioc" is an acronym.', and it came out `The Ioc': tr_word_text/4), with a
  quotation's closing mark on it too (tr_name_caps/2) -- two arms; `Nordic' takes its capital (en_nationality/1); a
  reporting clause between two quotations, the first closing on a word with its capital (`"Ignoro de qué está hablando
  el COI", dijo Mayer, "pero ...' -- with the small word's marks alone the reporting clause was read into the sentence
  and written after the second quotation: cmid/1, tr_closes_quote/1); `WHAT' AFTER A PREPOSITION OPENS AN INDIRECT
  QUESTION (`Ignoro de qué está hablando el COI' is what the IOC is talking about, and read with `qué' for the
  determiner of the word after it -- `habla' is speech too -- it was `of what speech': wh(pp(Preposition, what),
  Clause), read in a sentence with a word that asks `what' only, '$tr_what_word'), English putting the preposition after
  the clause (`what the IOC is speaking of') and the lesson's language before the word that asks (`de qué', `di cosa'),
  the doer after its verb the subject (tr_rel_subject_fix/2), and the quotation's closing mark the source's last word
  carried after the preposition, on the word or as its case (`"I ignore what the dog speaks" of' was written:
  tr_what_mark_off/4) -- six arms; a relative clause set off on the subject's last phrase of `of' keeps its commas (`La
  oficina del sheriff, que declinó ..., reconoció', where it was `the office of the sheriff that declined':
  tr_set_off_subject/5), its closing comma before the verb in the lesson's language too -- two arms; a noun that can say
  a sample says it in the plural with no determiner (`envía muestras a su laboratorio' are samples, where `muestra' is
  the newspaper's exhibition first, which `la muestra' keeps: tr_sample_noun/1); an activity English names with no
  article, as an -ism (`con el dopaje' is with doping: en_mass_activity/1); THE EVENT ONE IS IN IS A PHRASE OF `at'
  (`Segura estuvo presente ... en los Juegos de Salt Lake' was present AT the Games, where it was `in the Games':
  tr_comp_out/7, en_event_noun/1), the games in the plural only (`state proseguendo nel cosiddetto gioco del cerino' is
  continuing in the game, and the first cut wrote `at the so-called game') -- three arms; and the verb of enjoying takes
  its phrase bare in English (`goza, también, de una enorme fama' was `enjoys, of an enormous fame': en_bare_object/1).
  Two guards of the first cut, the question of `what' read to the end of the words with no comma, and never past a
  quotation's mark, had arms that stayed green and changed no text, the article's fifth sentence 21 and 102 inferences
  dearer with them, and are gone: the reporting clause's reader (cmid/1, above) sets the quotation apart with its
  commas.
  It needed these WORDS in `extra/' (the two readers: a line moves the reader of one language and the writer of the
  other; the dictionary's own word is said again first where it must stay the one written): Spanish `investigación' (an
  investigation, said before the research), the name `coi' (the IOC) and `"coi" is an acronym.', `por orden de' (by
  order of), `por casualidad' (by chance), `muy cerca de' (very near), `equipo de fondo' (a cross-country team) and
  `esquí de fondo', `esquí' (skiing, before the ski), `nórdico' (Nordic, before Norse), `director' (a director, before
  the conductor), `vínculo' (a link, before the bond, with `enlace' said again first), `utilizase' (the past subjunctive
  in `-se', which the dictionary gives for reading only), `perfusión', `a la vez' (at the same time), `mujer de la
  limpieza' (a cleaning woman, a person), `positivo' (a positive test, the noun), `contundente' (forceful, before
  conclusive), `censura' (censure, the noun and the verb), `borrón' (a blot), `indefensión' (helplessness), `tal como'
  (just as), `antidopaje' (its own plural), `puede que' (maybe, with `quizás' said again first), `"ignora" takes the
  question.', `"utiliza" takes the passive.', `The verb "viene" marks the passive.' (`viene dada por' is is given by, as
  Italian's `venire'), `"goza" takes "de" before the phrase.' and `"disfruta" takes "de" before the phrase.'; Italian
  the name `cio' and `"cio" is an acronym.', `per ordine di', `per caso', `molto vicino a', `squadra di fondo' and `sci
  di fondo', `sci' (skiing), `nordico' (Nordic, before a northerner), `legame' (a link, with `collegamento' said again
  first), `perfusione', `allo stesso tempo', `donna delle pulizie' (a person), `positivo' (a positive test), `incisivo'
  (forceful), `censura' (censure, the noun and the verb), `macchia' (a blot, before the stain), `impotenza'
  (helplessness), `antidoping' (its own plural), `affitta' (rents, where the dictionary's verb hires, and a writer with
  no word for `rented' refused it), `vuote' (the plural of the adjective, said before the verb's, `vuotano'), `"ignora"
  takes the question.', `campione' (a sample, with the champion said again first) and `"gode" takes "di" before the
  phrase.'. The first meaning moved for 10 Spanish words and 11 Italian ones (Spanish `censura' censure, `contundente'
  forceful, `director' a director, `esquí' skiing, `investigación' an investigation, `nórdico' and `nórdica' Nordic,
  `positivo' a positive test, `quizás' maybe, before perhaps, `vínculo' a link; Italian `affitta' rents, `censura'
  censure, `impotenza' helplessness, `incisivo' and `incisiva' forceful, `legame' a link, `macchia' a blot, `nordico'
  and `nordica' Nordic, `positivo' a positive test, `sci' skiing), the writer's first word for 1 Spanish meaning and 2
  Italian ones (Spanish forceful `contundente'; Italian forceful `incisivo', sample `campione', where it was
  `dimostrazione', a demonstration), and none was lost.
  THE CONTROLS (cocolog 3.19.5, store KB300, 128 count files, 3 428 sentences: the earlier set with the television
  reports in, it_9296_9309, both directions; this report is not among them): the last version's translator against this
  one, on the one store, 19 sentences in 14 files read differently, all better -- `at' the meeting, the funeral and the
  trial (5: `Thus one checked at the meeting', `At a second meeting among representatives', `The participants at the
  funeral', `prosecutor at the trial', `the positions of the parts at the trial'), the relative clause set off on the
  last phrase of `of' (4: `the Lebanese player, who signed for 350 million pesetas,' and `il giocatore libanese, che
  siglò ...,'; `the group "Insula", which takes charge of ...' and `el grupo "Insula", que se encarga ...,'), the verb
  of enjoying (3: `will enjoy a discount of 30%', `they have enjoyed days of rest', `will enjoy some puff of oxygen'),
  the near future in the past and the present (2: `but we will not remain like silly either' and `ma neanche rimarremo
  come tonti', where it was `we do not go to remain' and `ci andiamo a rimanere'), the noun after a verb of causing (2:
  `without that causes descents of prices' and `retrocessioni di prezzi', where it was `dropped' and `calato'),
  Tatoeba's `No entiendo de qué hablan', refused before and `I do not understand what they speak of' and `Non capisco di
  cosa parlano' now (2), and it_9947_9966 6, refused before and read into English now (`The ambitious project will
  depart next Tuesday with the course "human missions in the blank", the first one of the gender in Europe, which will
  be held by the astronaut Roberto Vittori, beside the "school of aerospace engineering" of the university La Sapienza')
  -- and the inferences fall 0.595 % (6 759 647 265 to 6 719 429 906) and rise 0.073 % outside the four sentences that
  fall by over a million (the Lord of the Rings' eleventh, es_20020102-112 11, 24.4 million inferences to 3.0 in each
  language, and the Veloso interview's tenth, it_9225_9269 10, 1.7 to 0.5, both relative clauses with two verbs read at
  once, the texts the same). Every sentence rises but ten, by 636 inferences at the median, the largest the Rognoni
  interview's nineteenth (+0.13 million of 176.3, refused both ways), es_20000802-31 4 (+0.13 of 5.1) and es_20020801-17
  14 (+0.12 of 2.4), the texts the same. Bytes and characters read every sentence alike (0 differ, the bytes 0.011 %
  more). The DATA COLUMN (the last version's translator on its own store, KB293, against this one on the new): 43
  sentences in 18 files, -0.580 % (6 758 601 876 to 6 719 429 906), +0.089 % outside the four. THE CODE ALONE (this
  translator on KB293): 16 sentences in 11 files, every one among the 19, -0.595 % (to 6 718 386 451), +0.073 % outside
  the four; the three left are the verb of enjoying, which needs `"goza" takes "de" before the phrase.' and its kin. THE
  STORE ALONE (the last version's translator on KB293 and on KB300): 24 sentences in 6 files, +0.015 % (to 6 759 647
  265), all better but two -- `investigation' for `investigación' (16: `The investigation of the Congress of EEUU
  against the president Bill Clinton', `L'investigazione del Congresso', `The managers of the investigation', where it
  was the research) and `director' for `director' (6: `The director of RNE', `general director of RTVE', `the theatrical
  director Lluís Pasqual', Tatoeba's `I knew the director in person', where it was the conductor) -- and the two of the
  stated costs below.
  THE FIRST ROUND'S REGRESSIONS, found by reading the texts of every column and mended. Of the store (KB299, the store
  alone, 33 sentences): a line said first is the reader's meaning and the other language's writer's word, so `puede que'
  was the Spanish written for every Italian `forse' and `magari' (8: `Puede que no le había gustado', `puede que
  Giulietta no ha apreciado', `Y para hoy, puede que, un nuevo atisbo', `salvarla puede que,'), `legame' the Italian for
  every link (`con legami contro il nazismo' for `con links contra el nazismo'), and `vínculo' the Spanish for one: the
  dictionary's `quizás', `collegamento' and `enlace' are said again first now. Of the code (the one store, KB299, 20
  sentences): the games read as an event in the singular too (`You are continuing at the so-called game of the
  matchstick', it_9714_9749 11: the plural only now, its arm red), and Italian's `godere di', governed now, wrote the
  Spanish `disfrutar' bare (`Disfrutarán alguna bocanada de oxígeno', it_9472_9484 9: `"disfruta" takes "de" before the
  phrase.' says the Spanish writer's word). The first cut's arms found three green: the event arm was never built (its
  edit's text stood twice in the file, and the builder stopped; the runner now refuses an arm with no library), and the
  two guards above.
  THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT (27 control sentences into English, the three heaviest risers of
  the first round -- the Venice report's fourth, 85.4 million inferences, es_20020601-51 2, 20.2, and it_9967_9998 25,
  19.7 -- and 24 picked at random of 0.1 to 2 million, over a copy of the library per rule on KB300): the first cut was
  +0.560 % of the controls outside the four, and +3.202 % of the 27 (137.4 million inferences to 141.8), 96 % of it the
  relative clause with two verbs (4.22 million): the reflexive verb `si occupa' is one word, and tr_form/5, which gives
  any word as itself, a present third person singular, took `il' and `vi' after `e' for the second verb, so the clause
  read its first half and failed on the second 234 times in the Venice sentence (+2.70 million), and as often in the
  other two (+0.99 and +0.69). The rule's own note first, made once a sentence in place of the wider note of a
  coordinator and a verb's form, saved 0.11 % of the 27; the verb's class asked of both verbs (tr_verb_lexeme/1) saved
  the rest. The final cut is +0.085 % of the 27 (to 137.5 million), the texts the first cut's, and the note is a guard
  of cost (+0.162 % without it): of the 117 thousand inferences left, the reader of the aside of `nor' is 38.6 thousand,
  the reader of `what' after a preposition 31.2 and its note 22.5, the noun after a verb of suffering 15.6, the two-verb
  note itself 13.2 and the adjective's guard 8.9, no other rule over 800. Over the whole controls the code is +0.073 %
  outside the four.
  THE STATED COSTS: a first meaning that serves the news and not every text -- `investigación' is an investigation
  (research second: `"Stradivari desarrolló su técnica a través de la investigación' is `through the investigation' and
  `tramite l'investigazione', es_20010202-169 14, the two texts of the store alone that are worse), `muestra' a sample
  only in the plural with no determiner, `positivo' a positive test as a noun, `esquí' skiing, `director' a director
  (the conductor second), `censura' censure (censorship second), `macchia' a blot (a stain second), `campione' the
  writer's word for a sample -- and the writer's `contundente' and `incisivo' for forceful; `quizás' is maybe before
  perhaps to the reader, which no sentence of the controls shows; it_9947_9966 6, refused before, is read into English
  with `the blank' for space and `beside' for at; and the inferences, +0.073 % outside the four on the one store and
  +0.015 % for the store alone.
  The report LEAVES, of the 17 into Italian (English alike unless it says): `un'investigazione scoprendo, per caso,
  materiale medico' and `on discovering, material medical ... by chance' (1: `al descubrir' is when it discovered, the
  adverb written last in English, `medical material'), `per la squadra di fondo' and `for the cross-country team' (the
  house rented BY the team: the agent after a participle and its place is a phrase of `for'), `d'Esquí' and `of Esquí'
  (the name keeps the source's word) and `il contenzioso dei recenti JJOO' and `the dispute of the recent JJOO' (the
  holding of the recent Games); `2 d'oro' and `2 of gold' (2: gold); `La sospetta del CIO' (3: `Il sospetto', the noun's
  gender taken from the verb's form), `sospetto che' (the verb after a subject with its relative clause, `sospetta
  che'), `potettero' (`poterono') and `sommamente pericolosi' (`estremamente pericolosa', the adjective's agreement with
  the practice lost), and English refuses it: a clause of `when' with `todo el material' inside the subject's relative
  clause has no reading (tr_read_nested/4 for the relative clause fails); `Il suo laboratorio Istituto Municipale
  d'Investigazione Medica (IMIM-IMAS) riconosciuto dal CIO gode, anche,' and `His Institute Municipal laboratory of
  Medical Investigation ... acknowledged by the IOC also enjoys,' (7: the apposition's commas lost and the name's words
  reordered in English, its laboratory, `recognised', the comma after `enjoys'); `come esperto nella materia' and `as
  expert in the matter' (8: `as an expert on the subject'); `di competizioni estere' and `of foreign competitions' (11:
  from); `si potrebbe avere evitato' and `one could have avoided' (12: `si sarebbe potuto evitare', it could have been
  avoided, the passive of the modal's perfect); `affermò' and `they affirmed' (14: he affirmed, the reporting clause's
  subject nobody names); `mercoledì passato' (15: `lo scorso mercoledì'); and `sfruttò l'intervista di TV per chiedere
  "perdono" al ciclista Joan Llaneras, medaglia d'oro in Sydney, per l'impotenza che soffrì' and `exploited the
  interview of TV to ask "pardon" to the cyclist Joan Llaneras, medal of gold in Sydney, for the helplessness that
  suffered' (16: took advantage of the TV interview to apologise to the cyclist, the gold medallist, for the
  helplessness he suffered: `pedir perdón' is an idiom, the doer of the relative clause after its verb is not read, and
  `in Sydney' is `a Sydney'). The next sample's controls take this report in.
  The CNR report (VIT-4883..4900, 18 sentences: the morning the president of the CNR shares out the year's funds among
  its bodies, a trolley of report cards on the institutes beside him, Italian into Spanish and English: 18 of 18 and 16
  of 18 on a fresh store, 17 and 14 with the new store alone, 11 and 11 with the new code on the old store, 10 and 10
  before; reasoning 1.0.33). The sample was taken on the cocolog 3.33.0 binary, master's a605949 merged as e1f8fe4 (the
  controls read every sentence alike on 3.19.5 and 3.33.0, 3 462 sentences, 0 differ, +0.056 % of the inferences), and
  cocolog stays 3.33.0; master's 60fd13c (lesson 51 alone) and d4ad532 (cocolog 3.34.0, format/2's `~@') came during the
  sample, change nothing under library/reasoning/, and are not merged: the next sample takes them. The article's
  sentences fall from 85.7 million inferences in each language to 32.8 into Spanish and 32.9 into English. English
  refuses 17 and 18 for the third person nobody names, on purpose (`Lo aveva fatto con una discreta abilità
  propagandistica ...', `La nota sulla quale aveva maggiormente insistito era stata quella ...').
  It needed these SHAPES, each with its arm red (test/translate.pl's `newspaper_cnr': 58 checks, 59 arms, 57 red in the
  section, one, `wdate-cross', that makes the section raise, and one green, below; an arm is a library directory of
  symlinks whose reasoning/translate.pl is the edited copy, `COCOLOG_LIBRARY=ARM cocolog query
  "use_module('test/translate.pl'), newspaper_cnr, checks_done"', under two seconds a run): A PRONOUN OF QUANTITY AND AN
  ADJECTIVE ARE ONE PHRASE (`C'è qualcosa di nuovo nella sala riunioni' is something new -- `di nuovo' is the lesson's
  `again', an adverb of two words the reader joins wherever they stand, and English wrote `There is something again':
  tr_unjoin_pronoun_adj/3 takes the two words apart after a pronoun that takes the word before an adjective, `"qualcosa"
  takes "di" before the adjective.', and padj/2 carries the pair, crossed and written by each language, `something new',
  `algo nuevo' -- four arms), and a pronoun that denies by itself takes no `no' (`Non c'è niente di nuovo' is there is
  nothing new, and Tatoeba's `No hay nada en la nevera' was `There is no nothing in the fridge'); AN HOUR AND THE ADVERB
  OF A PART OF THE DAY RIGHT AFTER IT (`Alle 9 di mattina' is at 9 in the morning -- `di mattina' is the lesson's `in
  the mornings', and it came out `At 9 in the mornings' and `A las 9 por las mañanas': it crosses as the part's phrase
  of `of', as a Spanish hour has it, en_day_part/2), in front of the clause too -- two arms; THE COPULA'S GERUND, A
  PHRASE AND A PHRASE AFTER IT ARE A SUBJECT AND ITS PREDICATE (`essendo la spartizione dei finanziamenti un momento
  cruciale' is the sharing out of the funds being a crucial moment -- read with nobody named, the sharing was the
  copula's object and the moment a time, `is the partition of the fundings a crucial moment': tr_gerund_subject/5, the
  subject's phrases of `of' with it, the predicate an object or a time, and English's `being' -- four arms); A NAME
  RIGHT AFTER A SUBJECT SET AFTER ITS VERB, A PERSON'S NOUN, IS THE PERSON'S (`entra il presidente Luigi Rossi Bernardi
  e saluta ...' is the president, Luigi Rossi Bernardi, entering, and read as the object the president entered him:
  tr_subject_name_after/5), with the clause's fronts before the verb too -- two arms; a word that is a pronoun and an
  adjective, right after a phrase, is the phrase's adjective (`non è una giornata qualunque' is not an ordinary day, and
  read as the pronoun `anybody' it was `It is not a day anybody': tr_pronoun_as_adjective/2); A DAY OF THE WEEK AND THE
  DATE RIGHT AFTER IT ARE ONE TIME (`È giovedì 6 giugno' is Thursday, June 6, and read as two the copula had a time and
  an object, `It is on Thursday June 6': tr_weekday_date/3, app(Day, wdate, Date), crossed, English's `on' before it
  after any other verb and its comma between them -- four arms, the crossing's arm making the section raise); A
  PARTICIPLE AFTER A PHRASE OF `of' THAT AGREES WITH THE PHRASE BEFORE IT AND NOT WITH THE PHRASE OF `of' IS THAT
  PHRASE'S (`ai circa 300 organi del Cnr sparsi per la penisola' are the bodies scattered across the peninsula, and hung
  on the Cnr it was `del Cnr esparcido': tr_of_participle_head/2 and tr_rel_number/5, the participle's own number
  carried, agrn/1), after a name of several words and after a name (`del San Raffaele', `di Roma'), the phrase the
  participle's verb governs with it (`"sparge" takes "per" before the phrase.', `scattered ACROSS it', en_governs/2,
  where the clause's phrase came out `for the peninsula') -- five arms; and A RELATIVE CLAUSE THERE THE SAME (`Un
  gigantesco carrello carico di documenti che è stato collocato ... alla sinistra del presidente' -- the trolley has
  been placed, and hung on the documents the clause had them for its object and nobody for its subject, which English
  refused: tr_rc_of_head/3); THE PARTICIPLE OF A VERB THAT TAKES NO OBJECT, AND A TIME RIGHT AFTER IT, IS A CLAUSE IN
  THE PAST (`dopo uno "scrutinio" durato mesi' is after an assessment that lasted months, where it was `after a lasted
  assessment months' and `tras una valoración durada meses': tr_lasting_participle/2, `"dura" is intransitive.'), among
  the complements of a participle the clause has too -- two arms; a second participle joined to a reduced relative's,
  with no agent (`i "voti" assegnati e scritti su quei fogli' are the votes assigned and written on those sheets, and
  the second, a noun too, was a second phrase, `the assigned votes and writings': tr_joined_participle/2, cpart/3); A
  COUNT OF TIME AND ITS `before' ARE ONE TIME (`La vicenda era nata sei mesi prima, esattamente il 31 ottobre 1984' was
  born six months before, and apart from the time English wrote it after the date, `six months, exactly October 31, 1984
  before': tr_ago_phrase/2 takes the lesson's word for `before' as it took the one for `ago', ago/2 keeps which, and
  each language writes its own word, the lesson's language its `before' after the time where it writes `ago' first,
  `tres meses antes' -- four arms); A COPULA WITH NOBODY NAMED, A PHRASE OF A PREPOSITION AND A CLAUSE OF `che' WHOSE
  SUBJECT STANDS AFTER ITS VERB IS A CLEFT (`È proprio su quel carrello che si concentra l'imbarazzato interesse dei
  presenti' is it is on that trolley that the interest of those present is concentrated -- read as a relative clause on
  the trolley, its doer after the verb took the trolley for its object, or its reflexive the trolley for its subject,
  and English refused both: tr_cleft_fix/3 and tr_cleft_clause/5, pp/2 and that/1, the doer after the verb its subject,
  and a thing after a reflexive the lesson says takes the passive, `"concentra" takes the passive.', the passive's
  subject with its phrases of `of' -- five arms); an article before a participle and a noun is the noun's (`si concentra
  l'imbarazzato interesse' is the embarrassed interest, and read as the pronoun `lo' and a predicate it came out
  `concentrates him embarrassed interest': tr_article_holds/2); the word for `about' after the article is the count's
  (`ai circa 300 organi' are the about 300 bodies, and `circa' is a preposition too, which ended the phrase at its
  article: adv_num/2, tr_counting_adverb/3); A RELATIVE CLAUSE AFTER JOINED ADJECTIVES IS THE WHOLE PHRASE'S (`un tema
  delicato ma importantissimo sul quale aveva assunto una posizione' -- split at `ma', the clause hung on `importante',
  a person, `pero a importante en el que': tr_conjunction_split/5 and tr_relative_after/2, a relative word or a
  preposition and one), an adverb among them too, which the tokeniser makes of a superlative (`molto importante') --
  three arms; a relative with its article is no noun (`La nota sulla quale aveva insistito era stata quella della
  valutazione' has `la quale' open the relative clause, and read as the noun `who' after `su' the note was on who, `era'
  an era the insisting took for its object: tr_noun/5), and never an indefinite phrase after a verb that takes an object
  is the clause's subject (`un tema delicato sul quale aveva assunto una posizione assai decisa' was `on which a
  position had taked': tr_rel_subject_fix/2 -- a guard, its arm red); an adverb at the head of the rest, set off by its
  comma, stays there in English (`che è stato collocato, bene in vista, proprio alla sinistra del presidente', where
  English wrote `placed, to the left of the president in full view': the gap writer of tr_write/4), and an adjective
  with a phrase of its own after its noun after `there is' too (`ci sono i dati relativi a tutti gli istituti' are the
  data relative to them, where it was `the relative data to', en_adj_takes/2's `relative') -- three arms; `really'
  stands with the verb, in a question too (`Davvero i fondi ottantacinque saranno distribuiti ...?' had it written last,
  `... on those sheets really?': en_mid_adverb/1); the state a verb of posture leaves (`i presidenti dei "comitati",
  seduti nervosamente intorno al grande tavolo' are SEATED around it, where the participle came out `sat':
  en_reduced_participle/2); a number the source put after its noun, in words, is the lesson's number word after the noun
  (`i fondi ottantacinque' are the funds of '85, and the lesson has no adjective for the number, so the sentence was
  refused: tr_adjective_out/5); an adjective the lesson's language says in several words that open on a preposition
  stands after its noun and its other adjectives (`Luigi Rossi Bernardi, cinquantaduenne direttore scientifico' is
  `director científico de cincuenta y dos años', where it was `de cincuenta y dos años director científico': a(postlast,
  Outs), tr_sides/3 -- two arms); the adjectives English says with `with' after their noun, with their phrase (`un
  gigantesco carrello carico di documenti' is a trolley loaded with documents, where it was `a gigantic loaded trolley
  of documents': en_adj_takes/2, en_with_adjective/1 -- two arms); `precisely' before the phrase of a preposition it is
  said of (`proprio alla sinistra del presidente', which was written last: tr_comps_out/7); `like all the years' is `as
  every year' (`È una giornata decisiva, come tutti gli anni, ...': tr_comp_out/7); and Italian's `si tratta di' is `it
  is' where the lesson's first meaning of `tratta' is `deals' (`Si tratta di una sorta di maxipagella della scienza
  italiana', where it was `One deals of a sort': tr_write/4) -- its arm is green in the section, whose hand lessons give
  `tratta' `treats' first, which the Inter feature's rule already writes `it is'; the controls show it, three sentences
  below. THE CONTROLS' FIRST ROUND found three more, each with its arm red: A HEADING'S PHRASE WITH ITS RELATIVE CLAUSE
  BEFORE A SUBORDINATING WORD (`Un dato confortante del quale non ci si può rallegrare perché l'intensità della povertà
  sta crescendo, ...' -- with the relative noun's guard above it was refused in both languages, where the old reading
  took `quale' for the noun `who': tr_join_left/5); `CI SI' AFTER A PREPOSITION'S RELATIVE IS THE IMPERSONAL `si' WITH A
  REFLEXIVE VERB, as a statement's is (the clause is read for a gap, and `ci' was `us' with nobody named, which English
  refused: tr_rel_ci_si/3, `del que uno no se puede alegrar', `of which one cannot gladden' -- two checks); and `have
  to' takes a mid adverb before `have' (`dovrà scegliere davvero' will really have to choose, and the new `really' came
  out `will have really to': tr_mid_insert/3, which wrote `will have also to' and `will have always to' as well, an
  older fault).
  It needed these WORDS in `extra/' (the two readers: a line moves the reader of one language and the writer of the
  other; the dictionary's own word is said again first where it must stay the one written): Italian `carico' and
  `carica' (loaded, the adjective; the dictionary has the noun alone, a charge), `qualunque' (ordinary, the adjective,
  with `ordinario' and `ordinaria' said again first), the participles of `sparge' (scatters; the dictionary gives them
  to `spare', disappears) and `"sparge" takes "per" before the phrase.', `posta in gioco' (the stake), `del solito'
  (than usual), `sala riunioni' (a meeting room) and `centro ricerca' (a research centre, `"centro ricerca" is not
  feminine.'), `bene in vista' (in full view), `minaccioso' (threatening), `pagella' and `maxipagella' (a report card
  and a big one), `scrutinio' (an assessment), `foglio' (a sheet, where the dictionary's first noun is a blade), `fa un
  passo indietro' (takes a step back, with its forms), `cinquantaduenne' (fifty-two-year-old), `propagandistico'
  (propagandistic) and `malcontento' (dissatisfaction), `"qualcosa"', `"niente"' and `"nulla" take "di" before the
  adjective.', `"dura" is intransitive.', `sorta' (a sort; the dictionary has the participle of `sorge' alone) and
  `"concentra" takes the passive.'; Spanish `carrito' (a trolley: the Spanish writer had no word for one, and every
  sentence with it was refused), `apuesta' (a bet said again first, and the stake), `de lo habitual', `sala de
  reuniones', `centro de investigación', `bien a la vista', `boletín de notas' and `gran boletín de notas', `hoja' (a
  leaf said first, where the dictionary's first noun is a blade, and a sheet), `da un paso atrás' with its forms, `de
  cincuenta y dos años', `propagandístico', `"esparce" takes "por" before the phrase.' and `especie' (a species said
  again first, and a sort). The first meaning moved for 4 Italian words and 1 Spanish one (Italian `carico' and `carica'
  loaded, `foglio' a sheet, `qualunque' ordinary; Spanish `hoja' a leaf, where it was a blade), the writer's first word
  for 5 Italian meanings and 3 Spanish ones (Italian assessment `scrutinio', dissatisfaction `malcontento', sheet
  `foglio', where it was `lenzuolo', a bed sheet, sort `sorta', stake `posta in gioco', where it was `partecipazione';
  Spanish sheet `hoja', where it was `chapa', a sheet of metal, sort `especie', stake `apuesta'), and none was lost.
  THE CONTROLS (cocolog 3.33.0, store KB304, 130 count files, 3 462 sentences: the earlier set with the IOC report in,
  es_20020301-99, both directions; this report is not among them): the last version's translator against this one, on
  the one store, 20 sentences in 13 files read differently, all better but two that are no worse -- `it is' for `si
  tratta di' (3: `it is a million of boys in absolute terms', `It is a thought cheque', `That it is a rejected project
  at birth', where it was `one deals of'), `data' for `datas' (2), `at eight in the evening' and `a las ocho de la
  noche' (it_10059_10095 7, where it was `in the evening' written last and `por la noche'), `precisely' before its
  phrase (2: `precisely like the Tuscan ones', `precisely to Spoleto'), `are really in course' (it_9270_9295 9),
  `however,' with its comma (it_9381_9414 8), `instead,' where the source has it (it_9485_9510 12, `No special case,
  instead, in Ponza'), `will really have to choose' (it_9605_9636 29, where `davvero' was written last), `There is
  nobody' and `There is nothing in the fridge' (Tatoeba's 195 and 246, where it was `There is no nothing'), `a
  comforting data of which one cannot gladden' and `del que uno no se puede alegrar' (it_9637_9672 19, where `quale' was
  the noun `who', `of who not can gladden us' and `de quién'), and es_19990901-75 7, refused before and read into
  English now (`The Ministry of Economía has begun to collect information of the effects that can have the fusion ...')
  -- and the two no worse: `a consortium of international, Arab or Australian operators that are' (it_9605_9636 14,
  where it was `of international operators, Arabs or Australians that are': the source's `arabi o australiani' are
  adjectives, and `che siano', whatever they are, is no better either way), and `It seems me precisely of no'
  (it_9714_9749 24, where `precisely' stood after `of no'). The inferences rise 0.117 % (6 754 175 668 to 6 762 110 579)
  and 0.068 % outside one sentence (below): every sentence rises but 22, by 362 inferences at the median. Bytes and
  characters read every sentence alike (0 differ, the bytes 0.011 % more). The DATA COLUMN (the last version's
  translator on its own store, KB300, against this one on the new): 21 sentences, +0.166 % (6 750 906 884 to 6 762 110
  579). THE CODE ALONE (this translator on KB300): the 20 of the one store, +0.117 %. THE STORE ALONE (the last
  version's translator on KB300 and on KB304): 1 sentence, better, `they do it on a sheet to two dimensions'
  (it_9967_9998 25, where it was `a blade'), +0.048 %, nearly all of it `"dura" is intransitive.' in two sentences of
  one file, their texts the same (`è durata così poco' +0.48 million inferences of 11.8 in each language, it_9851_9925
  6, and `Dura 6 mesi' +68 thousand of 49 thousand, 27).
  THE FIRST ROUND'S REGRESSIONS, found by reading the texts of every column and mended, each with its arm red: the
  relative's guard (`la quale' is no noun) left `Un dato confortante del quale non ci si può rallegrare perché ...'
  (it_9637_9672 19) with no reading in either language, where the old one took `quale' for `who' -- the heading's phrase
  with its relative clause before `perché' read then, and English refused its clause until `ci si' after the
  preposition's relative was the impersonal (the two rules above); and the new `really' wrote `will have really to
  choose' (it_9605_9636 29), the place `have to' gave `also' and `always' before, which the same fix mends. The whole
  case found two more: the islands section's `Nessuna casa, invece, a Roma dove ...' is `No house, instead, in Rome
  where ...' now, the adverb set off by its commas kept there by this sample's rule (the gap writer's, its arm red in
  that section too), and the expectation is the new text in test/translate.pl and in lesson 46; and its scan of the
  vocabularies found `centro ricerca', a masculine noun in `-a' whose denial was missing, which the writer would have
  written `la centro ricerca': `"centro ricerca" is not feminine.' is in, and KB304 is taught with it (KB303 without it
  read every sentence of the controls alike, with either translator).
  THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT: the one store's largest rise is one sentence, the child-cost
  report's nineteenth (`E un'esigenza sentita da tutti quelli che lavorano alla costruzione di accordi tra ex coniugi
  (mediatori, avvocati, i genitori stessi) ai quali serve un punto di riferimento oggettivo e uniforme', it_10011_10058
  19), +1.67 million inferences of 4.2 in each language (+40 %), its text the same: all of it the guard that a relative
  with its article is no noun (tr_noun/5), which blocks `i quali' as the noun `who' and leaves the reader a longer way
  to the same reading (shorter, `E un'esigenza sentita dai genitori ai quali serve un punto di riferimento' is the
  heading and `to whom ... is needed' with the guard, 0.78 million inferences, and `who' and the verb `serves' without
  it, 0.48). Asking the guard's cheap test first (a word of two or more) moved nothing, and it stays as written. Over
  twelve sentences of the controls of 0.2 to 0.5 million inferences, six from each language, into English, counted over
  a copy of the library per rule, the first cut rose 6 378 inferences of 4.38 million (+0.146 %), and the hour's part of
  the day was 2 906 of it: the clause crossed the first complement again wherever an adverb followed one. An adverb of
  two words or more and the hour's shape asked first (tr_clock_shape/1, a phrase with its article and no adjectives, or
  two joined) leave the rule 245, and the twelve +0.085 % -- a guard of cost, its arm green; over the controls the cut
  is -0.005 %, every text the same. What is left is the word for `about' after an article (916 of the twelve's), the
  pronoun and its adjective taken apart, a walk of every sentence's words (794), the relative's guard (580) and the
  joined participles (202), no other rule over 80.
  THE STATED COSTS: the relative's guard's 1.67 million inferences in one sentence (above); `"dura" is intransitive.'
  (above); a first meaning that serves the news and not every text -- `foglio' is a sheet (a blade before), Spanish
  `hoja' a leaf and then a sheet, `carico' and `carica' loaded (the noun, a charge, second), `qualunque' ordinary
  (anybody, the pronoun, second) -- and the writers' words: Italian `foglio' and Spanish `hoja' for every sheet (a bed
  sheet was `lenzuolo', a sheet of metal `chapa'), `posta in gioco' and `apuesta' for every stake (a share in a company
  was `partecipazione' and `participación'), `sorta' and `especie' for a sort, `scrutinio' for an assessment and
  `malcontento' for dissatisfaction; `si tratta di' as `it is' has no hand lesson that shows it (the arm is green; the
  controls show three sentences); and the inferences, +0.068 % outside one sentence on the one store, +0.048 % for the
  store alone.
  The report LEAVES, of the 18 into Spanish: `en la sala Enrico Fermi' and `the hall Enrico Fermi' (2: the Enrico Fermi
  hall), English's `the president Luigi Rossi Bernardi enters' and `seated around the big oval table nervously'
  (`nervously' last); `the destined funds' (4: the funds destined); `la partición de las financiaciones' and `the
  partition of the fundings' (5: the sharing out of the funds); English `still taller than usual' (7: higher); `Están
  los datos ... en el carrito' and `There are the data relative to all the institutes ... on the trolley' (11: the
  phrase set in front written last, `hay', and English's data relating to them); `la ciencia italiana' and `the Italian
  science' (12: Italian science); `que se concentra' and `the presents' (13: Spanish's cleft wants `donde', English
  those present); `¿Los fondos ochenta y cinco serán distribuidos ... en esas hojas realmente?' and `Will the
  eighty-five funds be really distributed' (14: `realmente' written last, the funds of '85, and English's `really be');
  `Pero damos un paso atrás' and `But we take a step back' (15: `facciamo' is the exhortation, `demos', let us take);
  `exactly October 31, 1984 when' (16: on), `el hospital mayor de Milán' and `the biggest hospital of Milan' (the
  Ospedale Maggiore, a name) and `the speech of the crown' (the inaugural speech); `insatisfacción para el estado' (17:
  `por') and `hacer gritar a la renovación' (`gridare al rinnovamento', to cry out for renewal, an idiom). The next
  sample's controls take this report in.
  The Air Europa report (AnCora CESS-CAST-P-20000401-85, 19 sentences, the paper's report on an aeroplane seven hours
  late at El Prat, Spanish into Italian and English: 19 of 19 and 19 of 19 on a fresh store, 18 and 17 with the new
  store alone, 6 and 11 with the new code on the old store, 6 and 11 before; reasoning 1.0.34). The sample was taken
  on the cocolog 3.62.0 binary, master's d4b5564 fast-forwarded onto the branch, and cocolog stays 3.62.0; master's
  ed4e4ed (cocolog 3.62.1, the green world reviewed) came during the sample, changes nothing under
  library/reasoning/, and is not merged: the next sample takes it. THE BOX WAS RESET BEFORE THIS SAMPLE, and the
  controls were made again from their sources (the AnCora documents and VIT ranges of UD's es_ancora and it_vit, and
  every (length/400)th Spanish sentence of 3 to 8 words of manythings' spa.txt): 132 count files, 3 498 sentences,
  with the CNR report in, so no count below compares with the CNR sample's, and the baseline is the committed library
  (reasoning 1.0.33) on a store taught from the committed vocabulary. THE BINARIES OF 3.33.0 AND 3.62.0 give the same
  texts on these controls (0 differ) and 3.62.0 counts 0.174 % fewer inferences (6 747 835 285 to 6 736 088 337); a
  store 3.33.0 taught reads the same to the unit on 3.62.0 as one 3.62.0 taught, and 3.33.0 cannot read a store
  3.62.0 taught (3.35.0 writes an atom past ASCII bare, which 3.33.0's reader refuses). The article's sentences fall
  from 26.5 million inferences into Italian and 26.3 into English to 22.0 and 21.6.
  It needed these SHAPES, each with its arm red (test/translate.pl's `newspaper_air': 44 checks, 49 arms, 48 red and
  one that makes the section raise; an arm is a library directory of symlinks whose reasoning/translate.pl is the
  edited copy, `COCOLOG_LIBRARY=ARM cocolog query "use_module('test/translate.pl'), newspaper_air, checks_done"', a
  second a run, and every arm is run in two minutes, four at a time): A CODE WITH DIGITS IN IT IS NO NAME'S FIRST WORD
  (`el vuelo UX-9482 de Air Europa' is Air Europa's flight, and joined it was one name, `UX-9482 de Air Europa', with
  its `de' untranslated: tr_particle_names/4), and WHAT IS ON A FLIGHT OR A VEHICLE ONE TRAVELS IN, WITH ITS
  DETERMINER, IS ON IT (`in the flight', `in the train': tr_comp_out/7, en_on_vehicle/1), a vehicle with no determiner
  never (`andar en tren' is by train) and a plane never, which a film's shot is too (`elementos contemporáneos que se
  cuelan en el plano', found by the controls) -- four arms; A VERB WITH A SPAN OF TIME AND AN OBJECT CROSSES BY THE
  MEANING THE LESSON GIVES IT THERE (`Un centenar de pasajeros esperó siete horas la salida de un avión averiado'
  waited for it, where `espera' is `expects' first, and `expected seven hours the departure' was written: `The durative
  verb "espera" means "waits for".', tr_mean_links/3, tr_verb_across/5), the source's span asked by its noun's
  meaning, as the verb crosses before its complements do (tr_span_source/1), and English writes the span after the
  object and its phrases of `of', with `for' (`waited for the departure of a damaged aeroplane for seven hours':
  tr_comps_out/7), and a span the source put after the object takes its `for' there, `a couple of hours' among the
  spans (`aguantaron con estoicismo su mala suerte un par de horas', tr_span_np/1) -- six arms; A NOUN OF A ROUND
  COUNT BEFORE `de' AND A BARE PLURAL IS ABOUT THAT MANY (`Un centenar de pasajeros' was `A hundred of passengers' with
  the singular verb, `una veintena de viajeros' `a twenty of travellers': tr_cross_np/2, en_round_count/1, as
  `unos cien pasajeros' is, adv_num/2), with the article in English (`about a hundred', tr_num_out/3), after `the' the
  count itself, an object too (`esgrimiendo el centenar de reclamaciones cursadas por el pasaje' is the hundred
  complaints: tr_cross_comps/2, tr_count_head/4 for the participle after the plural's noun), a clause joined after it
  with nobody named the plural's (`una veintena de viajeros rodeó a una azafata y estuvo a punto de lincharla' WERE on
  the verge, and with the singular English refused the clause: tr_count_gap/3), and `almost' before it says how many
  in its place, after the verb and inside the phrase of a preposition (`se compone de casi un millar de sellos
  discográficos' is of almost a thousand record labels, where the count's own word wrote `almost about a thousand',
  found by the controls: tr_cross_comps/2, each clause asking the count's shape before it crosses the adverb) -- eight
  arms; A TIME IN DIGITS AND THE NOUN FOR HOURS AFTER IT ARE THE HOUR (`despegar ayer a las 11.10 horas' took off at
  11.10, and it was `to the 11.10 hours' and `alle 11.10 ore': tr_cross_np/2), and an hour after a preposition of time
  takes no article in English, with the part of the day after it (`el avión no partió hasta después de las seis de la
  tarde' did not depart until after six in the afternoon, where it was `until after the six of the afternoon':
  tr_comp_out/7, en_clock_preposition/1, en_clock_pp/1) -- three arms; A GROUP NOUN THAT DOES SOMETHING IS THE PEOPLE
  IT IS (`el pasaje destiló tanta indignación' is the passengers, and it was `the passage distilled': `The collective
  noun "pasaje" means "passengers".', tr_mean_links/3, tr_cross_np/2), the subject of a verb that is no reflexive, the
  agent of a participle (`reclamaciones cursadas por el pasaje', by/1) and a share of such a subject (`Parte del
  pasaje volaba por placer' was refused, `parte' read as the verb, departs: tr_part_of_group/1, tr_read_generic/4),
  the doer told to the crossing as it goes in and put back as it comes out ('$tr_doer', tr_as_doer/1,
  tr_as_doer_not/1), and never an object, the subject of a reflexive verb, which is a passive, the phrase of `of' of a
  subject that does something (`el perro del pasaje') nor a complement of a clause in such a subject -- ten arms; A
  CLAUSE OF `que' AFTER A PHRASE OF `so much' OR `so many' IS WHAT CAME OF IT (`el pasaje destiló tanta indignación que
  se amotinó' is so much indignation that THEY mutinied, and read as a relative clause on the indignation it was
  `that mutinied': tr_result_clause/4, res/2), English naming the clause's subject the lesson's languages leave out,
  `he' for a person, `it' for a thing -- two arms; A CLAUSE WITH NOBODY NAMED AND TWO OBJECTS, A THING AND THEN A DOER,
  HAS THE DOER FOR ITS SUBJECT (`Los ánimos se calmaron cuando cruzó la puerta de embarque número 24 una patrulla' --
  a patrol crossed the gate, and read as two objects English refused the clause: tr_vos_subject/2, tr_thing_head/2,
  tr_doer_head/2, `"patrulla" is a group.'), the thing's head through its phrases and its number, and a second phrase
  that is no doer the object still (a guard) -- three arms; A NOUN, THE WORD FOR `number' AND DIGITS ARE THE NOUN AND
  ITS NUMBER (`la puerta de embarque número 24' had its digits left a phrase of their own, and the sentence was
  refused: tr_np/3, app/3's numbered, each writer its own word for the number), asked where the sentence has the word
  for `number' with digits after it ('$tr_numbered', tr_numbered_note/1, a guard of cost whose arm stays green, below)
  -- three arms; THE SECOND `ni' OF TWO CLAUSES IS `nor' IN ENGLISH (`Así que ni se cerró el suculento trato ni la
  testigo entregó los anillos' was `neither the witness handed': tr_write/4, tr_opens_neither/1), where the first
  clause opens on its own `neither' and where the first `ni' stands before both -- two arms; A QUOTATION THAT CLOSES
  ON A VERB GROUP AND ITS OBJECT PRONOUNS CLOSES AFTER THEM IN ENGLISH (`"No es la primera vez que Air Europa me toma
  el pelo"' was `fools" me': tr_write/4, tr_vqc_mark/3); A SENTENCE THE SOURCE BEGINS IN SMALL LETTERS WITH A VERB OF
  SAYING IS NO COMMAND (`"¿Por Qué AENA no hace nada en estos casos?", pregunta Camp' is Camp asking, and the present
  `pregunta' read as the command it is too, `Ask Camp': tr_into_ir/4, '$tr_small_head', tr_small_head_note/2), asked
  of the words as the source wrote them, before the capital of a sentence's first word is taken off, in both ways a
  sentence is read (tr_read_ir/5, and the page's tr_each/3), of a verb of saying alone (`"mettiamola la così: noi
  crediamo ...', the treebank's own sentence in small letters, is the command it was, a guard the controls found) --
  five arms; `makes' with nothing made is `does' in a question that asks why, when, where or how too (`"¿Por Qué AENA no
  hace nada ...?"' was `not make anything': tr_makes_does/3); and `takes off' governs `from' (`despegar ... de
  Barcelona', en_governs/2). A clause for a thing the reader made the subject, with the doer after it among its
  complements, had an arm that stayed green on the section and on the store, the clause with nobody named reading the
  article's sentence, and is gone.
  It needed these WORDS in `extra/' (the two readers: a line moves the reader of one language and the writer of the
  other; the dictionary's own word is said again first where it must stay the one written): Spanish `espera' (expects
  said again first, and waits for with a span: the durative class, new here), `despega' (takes off, an English verb of
  two words the builder takes from no entry, with its forms, intransitive, `de' before the phrase), `asegura' (ensures
  said again first, and assures before a clause), `azafata' (a flight attendant, a person), `veintena' (twenty),
  `cabreo' (anger, `rabia' said again first), `presa de' (in the grip of), `verbalmente', `avería' (a breakdown,
  before the failure), `envía' said again first and `manda' (sends), the name `Palma de Mallorca', `rumbo a' (bound
  for), `puerta de embarque' (a boarding gate), `a cambio' (in return), `"patrulla" is a group.', `así que' (so),
  `hasta después de' (until after), `mal tiempo' (bad weather), `pasaje' (a passage said again first, and the
  passengers, its collective meaning, the collective class new here, and a group), `reclamación' (a complaint, then a
  claim; `queja' said again first, and `entrega' hands, then submits), `millonario' and `millonaria' (multimillion),
  `"masa" is a person.', `toma el pelo' (fools, with its forms), `agua la fiesta' (spoils the party, with its forms),
  the intransitive `tarda' (is late), `"cierra" takes the passive.', the name `Baleares' and the determiner `un par de'
  (a couple of); Italian `aereo' (an aeroplane: no Italian word meant one), `passeggero' (a passenger, where the
  writer's word was a cruise passenger, `crocierista'), `anello' (a ring), `guasto' (a breakdown), `hostess' (a flight
  attendant, a person, its own plural), `ventina', `in preda a', `alla volta di', `porta d'imbarco', `in cambio',
  `"pattuglia" is a group.', `considerevole' (considerable: the dictionary's `considerabile' is no word, and has no
  plural), `matrimonio' (marriage said again first, and a wedding: the dictionary's `nozze' says no number, and the
  writer wrote `un nozze'), `fino a dopo', `maltempo', `reclamo' (a complaint), `milionario' and `milionaria', `"massa"
  is a person.', `prende in giro' (fools, with its forms), `guasta la festa' (with its forms), the intransitive `tarda',
  `"chiude" takes the passive.', `un paio di', `decolla' (takes off, with its forms, intransitive, `da' before the
  phrase) and `attende' (expects, and waits for with a span); and in the dictionaries' extras, for Italian `lynch'
  (`linciare'), `mutiny' (`ammutinare') and `reposition' (`ricollocare'), and for Spanish `lynch' (`linchar'),
  `mutiny' (`amotinar') and, read only, `submit' (`cursar') and `shout' (`vociferar'). The first meaning moved for 6
  Spanish words and 5 Italian ones (Spanish `avería' a breakdown, `manda' sends, `millonario' and `millonaria'
  multimillion, `reclamación' a complaint, `tarda' is late; Italian `aereo' an aeroplane, where it was an airplane,
  `milionario' and `milionaria' multimillion, `reclamo' a complaint, `tarda' is late), the writer's first word for 1
  Spanish meaning and 5 Italian ones (Spanish breakdown `avería', where it was `desglose'; Italian complaint `reclamo',
  where it was `denuncia', considerable `considerevole', passenger `passeggero', ring `anello', where it was
  `anellino', wedding `matrimonio'), and none was lost.
  THE CONTROLS (cocolog 3.62.0, store KB_a4, 132 count files, 3 498 sentences: the earlier set with the CNR report in,
  it_4883_4900, both directions; this report is not among them): the last version's translator against this one, on
  the one store, 3 sentences in 3 files read differently, all better -- `almost a thousand record labels' and `quasi
  mille etichette discografiche' (es_20010103-139 14, where they were `almost a thousand of' and `quasi un migliaio
  d'') and Tatoeba's `You are on the mistaken train' -- and the inferences rise 0.033 % (6 736 866 187 to 6 739 058
  634), the largest rises the Venice report's eighth (+14 463 of 251.3 million) and the Rognoni interview's nineteenth
  (+9 586 of 176.4, refused both ways). Bytes and characters read every sentence alike (0 differ, the bytes 0.014 %
  more). The DATA COLUMN (the last version's translator on its own store against this one on the new): 17 sentences in
  14 files, all better but the two of `tardar' below, no worse, +0.044 % (6 736 088 337 to 6 739 058 634), and 3 114
  read in both. THE CODE ALONE (this translator on the old store): the same 3 sentences, +0.033 % (to 6 738 286 465).
  THE STORE ALONE (the last version's translator on the old store and on the new): 14 sentences in 11 files, +0.012 %
  (to 6 736 866 187), each a word of the report's lines -- `assured' for `aseguró que' (6, where it was `ensured'), `a
  couple of' (2: `shattered a couple of years after', `a couple of counters', where it was `a pair of'), `anelli' (2:
  `il signore degli anelli', `la comunità dell'anello', where it was `anellini'), `multimillion bribes', `tardato' and
  `have been late' for `han tardado' (where it was `preso' and `taken', no better and no worse: `tardar en' with `más
  que nosotros' between is `took longer'), and Italian's `reclamo' for a complaint (`I reclami civici', `Il suo
  principale reclamo', where it was `denuncia').
  THE FIRST ROUNDS' REGRESSIONS, found by reading the texts of every column and mended, each with its arm red. Of the
  code: the rule for a sentence in small letters first asked the words after the capital of a sentence's first word
  was taken off, so it held for every sentence, and every command of the controls was refused (3 114 read to 3 077:
  `Compare the own ones with analogous compiled charts', `Apply several statistical correctives', `If I err correct
  me', `Therefore be consistent', `Let us talk again it among a year', `Give the impression that they wish ETA to
  act', and the islands report's `Assicura il sindaco Costantino Federico ...' refused into English), and asked of any
  word it refused the treebank's own sentence in small letters, `"mettiamola la così: noi crediamo al
  presidenzialismo ...' (it_9714_9749 28, both languages); the vehicles took the film's shot, `que se cuelan en el
  plano' (`sneak on the plane', es_20020102-112 1); and the count wrote `almost about a thousand' (es_20010103-139 14,
  both languages). Of the store: `cabreo' became the Spanish writer's word for anger, `reclamación' for a complaint
  and `cursar' for submits -- the dictionary's `entregar' for submits is an entry read only from English (r="LR"),
  and with a line for submits from `cursar' the builder wrote it no more -- and the dictionary's words are said again
  first now.
  THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT (23 sentences of the controls into English, the four heaviest
  Italian risers of the first round and 19 picked at random of 0.1 to 2 million inferences, over a copy of the library
  per rule on the new store): the first cut rose 250 090 inferences of 145.5 million (+0.172 %), and one rule was 91 %
  of it, the noun and its number, whose clause of tr_np/3 walked every phrase it was asked with append/3 (226 486); its
  last word asked first with last/2 saved nothing measurable, the clause being entered at each phrase, and a note
  made once a sentence ('$tr_numbered') leaves +27 290 (+0.019 %), the note's own walk 11 193 of it, the doer told to
  the crossing 1 372, the group's crossing 943, the doer put out of an infinitive's complements 568, the swap of a
  thing and a doer 692, `almost' 402 (each clause asked the adverb's meaning before the count's shape, 7 657), no
  other rule over 300. The note's arm, always yes, is +249 255 and green on the section, a guard of cost. Over the
  controls the code alone is +0.033 %.
  THE STATED COSTS: a first meaning that serves the news and not every text -- `avería' is a breakdown (a failure
  second), `manda' sends (commands second), `millonario' multimillion (a millionaire second), `reclamación' and
  `reclamo' a complaint (a claim second), `tarda' is late (takes second) -- and the writers' `avería' for a breakdown
  (`desglose', a breakdown of figures, before) and Italian's `reclamo' for a complaint (`denuncia' before);
  `pasaje' is a group now, so the Inter feature's doer rule reads `El perro que ve el pasaje duerme' as the dog that
  the passengers see; the store's lines cost three sentences of the controls a reading for nothing, the texts the same
  (it_9763_9774 10, +73 374 of 3.12 million, es_19991202-35 6, +46 556 of 0.27, Tatoeba's 383, +21 493 of 0.20); and
  the inferences, +0.033 % on the one store and +0.012 % for the store alone.
  The report LEAVES, of the 19 into Italian (English alike unless it says): `trattamenti milionari' and `multimillion
  treatments' (3: `tratos' are deals) and `pretendevano chiudere' (`intendevano'); `In preda al nervosismo e della
  rabbia' (10: the second phrase of a preposition of several words keeps the `of' it was read with, `alla rabbia');
  `Gli incoraggiamenti' and `The encouragements' (11: `Los ánimos' are tempers), `con la sua sola presenza' and `with
  his alone presence' (its mere presence) and `che placò le masse' after `guardie civili' (the relative clause hangs
  on the patrol); `il danno era fatto' is right, and English writes `the damage was made' (12: done); `ebbero in mano'
  and `held' for `aguantaron' (7: endured), `con stoicismo' before the object; `si credettero dopo che bisognasse
  pulire l'aereo' (8: `credettero', the reflexive of `creerse' kept, and `poi'); `difese Hidalgo' and `Hidalgo
  defended' (17: argued) and `senza lei' and `without her' (the piece: `senza di esso', the pronoun of a thing written
  as a woman's); `il pezzo che modificava il fallimento' and `the piece that amended the failure' (16: that fixed the
  fault); `"Perché non
  fa AENA niente in questi casi?" Chiede Camp.' (19: `Perché AENA non fa niente', the subject after the verb, and the
  reporting clause's comma and small letter lost); and English writes `yesterday' last (2, 18). The next sample's
  controls take this report in.
  The physics report (VIT-4860..4882, 23 sentences, the last part of a report on Italian physics and its funds: two
  projects that waited for their money, what high-energy physics costs the fields beside it, and a hopeful view of the
  whole, Italian into Spanish and English: 20 of 23 and 19 of 23 on a fresh store, 20 and 18 with the new store alone,
  10 and 9 with the new code on the old store, 10 and 9 before; reasoning 1.0.35). The sample was taken on the cocolog
  3.62.1 binary, master's a519dde fast-forwarded onto the branch (the controls of the Air Europa sample read every
  sentence alike on 3.62.0 and 3.62.1, the same counts to the unit), and cocolog stays 3.62.1. The article's sentences
  fall from 100.4 million inferences into Spanish and 100.3 into English to 75.7 and 75.5, of which the twelfth,
  refused, is 40.4 million in each (37.1 before). English refuses 3 for the third person nobody names, on purpose (`è
  stato approvato in dicembre e ...').
  It needed these SHAPES, each with its arm red (test/translate.pl's `newspaper_phys': 32 checks, 30 arms, all red in
  the section; an arm is a library directory of symlinks whose reasoning/translate.pl is the edited copy,
  `COCOLOG_LIBRARY=ARM cocolog query "use_module('test/translate.pl'), newspaper_phys, checks_done"', a few seconds a
  run): A NATIONALITY AFTER ANOTHER NOUN IS NO HEAD BY BEING A PERSON (`la fisica italiana' is Italian physics, and
  `italiana' -- an Italian woman, and Italian -- was the head as the one person, `the physical Italian': tr_noun/5,
  tr_nationality_word/1), and the controls' `el rotativo británico The Times' is the British newspaper, where it was
  `the rotary British'; A PERSON AFTER A VERB THE LESSON GIVES A MEANING FOR A PERSON OBJECT IS NO DOER (`i complessi di
  colpa che avevano profondamente turbato i loro maestri' troubled the teachers, and read with the teachers for the doer
  English wrote `that their teachers had troubled': `The personal verb "turba" means "troubles".', tr_rel_doer/2), a
  verb with no such meaning keeping the doer after it (a guard) -- two arms; `too' among a verb's complements is `too
  much', in its place (`si spende troppo per la fisica delle alte energie' was `one spends for the physics ... too':
  tr_comp_out/7), and before an adjective `too' still, `troppo' being an adjective too (`too much national':
  tr_comps_out/7; the controls' `ero troppo giovane, lui troppo intelligente, troppo paterno, troppo tutto' was `I was
  young, him intelligent, paternal, everything too too too too', and Tatoeba's `Estás demasiado tensa' `You are taut
  too') -- two arms; THE COPULA, A PARTICIPLE THAT IS AN ADJECTIVE TOO AND AN INFINITIVE (`Sarebbe più corretto dire che
  in realtà si spende poco' is it would be more correct to say it, and read as the passive it was `To say that ... would
  be more corrected': tr_copula_adj_inf/3, asked before the passive), the lesson's language writing the adjective, and
  the participle alone, which the complement reader reads as the participle it is too -- two arms; the controls'
  `Sarebbe sbagliato leggere tutto pro o contro Berlusconi' is `It would be wrong to read', where it was `To read ...
  would be erred'; `other' alone in the plural is `others' (`si spende poco per gli altri' was `the other ones':
  tr_np_out/5); A MONTH AND THE YEAR AFTER ITS `of' ARE ONE DATE (`nel settembre del settantanove' is in September '79,
  and read as two phrases it was `in the September of the seventy-nine': tr_cross_comps/2), English writing a year of
  two digits said in words as `'79' (en_short_year/2) and the lesson's language its words with no article before the
  month, a month with no day and its year after it taking no article (`nel gennaio 1980' was `in the January 1980' and
  `en el enero de 1980': tr_cross_np/2), and the year keeping the case of its word (the closing mark of `"lo abbiamo
  proposto ... nel settembre del settantanove", ricorda Fiorini' was lost) -- four arms; the controls' `on November 7,
  '77' and `(July 9, '95)'; A VERB OF SEEMING IS NO COMMAND (`Sembra di sentire un'eco dell'apologo di un certo Menenio
  Agrippa' is it seems to hear one, and read as the command English wrote `Seem to feel an echo': tr_read_statement0/4,
  '$tr_seem_lexemes'); a partitive pronoun beside a count is said once, an adverb between them too (`Ne citerei almeno
  tre' was `I would cite it at least three' and `Lo citaría al menos tres': tr_cross_comps/2); AN ADVERB AND A CLAUSE OF
  `che' WITH NOBODY NAMED: THE PHRASE AFTER ITS VERB IS ITS SUBJECT (`È lì che vivevano certi oggetti' was `It is there
  that they lived some objects': tr_cleft_fix/3); A THING BEFORE AN IMPERSONAL `si' THAT A PRONOUN JOINED TO THE
  INFINITIVE TAKES UP AGAIN IS THE INFINITIVE'S OBJECT (`qualche incrinatura si riesce a trovarla' was `some crack
  attains to find her': tr_dislocation_fix/3); `a' AND AN INFINITIVE AT THE HEAD, BEFORE A COMMA, ARE A FRONT, THE
  GERUND (`a scavare bene nella compatta testuggine della fisica italiana, qualche incrinatura ...' had no reading, and
  after an adverb English wrote `to dig ... well', a purpose: tr_read0/4), the lesson's language its gerund, an adverb
  with its comma before them keeping the comma (tr_fronts_out/5) -- three arms; A PHRASE AFTER A COMMA IS AN APPOSITION
  AND NO OBJECT, IN A CLAUSE THAT SHARES THE SUBJECT (`e si riferisce al progetto ..., un tema che riveste ...' was `and
  one refers': tr_shared_subject/5), and English elides the shared subject there -- two arms, red once the hand lesson's
  `riferisce' was the store's, a verb whose reflexive meaning no lesson states; THE PHRASE A SUBJECT'S RELATIVE CLAUSE
  HANGS ON OWNS WHAT ITS POSSESSIVES NAME (`un tema che riveste un'enorme importanza anche per le sue notevoli ricadute'
  is ITS spin-offs, where it was `his': tr_cross_np/2, '$tr_rc_head'), a person's his (a guard) -- two arms; the
  controls' `the economic recession of the biennium 1992/1993 that leaves its traces'; A FRONT'S RELATIVE CLAUSE NEVER
  TAKES A PHRASE AFTER ITS COMMA where no verb follows (`senza la ricerca di punta che si fa nei nostri laboratori,
  tutto il resto crolla' took `tutto il resto' for an apposition and left the command `collapse!', or took `tutto' and
  left `il resto crolla': tr_read0/4), only where the words after the comma open on a pronoun or a subject, and never
  where the rest opens on a subject of its own, so that the phrase is an apposition (the controls' `los pulsos tácticos
  entre Aíto y Majkovic, dos personajes antagónicos, el partido tuvo pasión' was refused there and read again with
  `entre' for the verb, `the tactical duels Aíto enters', 10.6 million inferences more in each language) -- three arms;
  a count of time `ben' stresses, before its `ago', is the when of the clause (`proposto ... ben otto anni fa' was `as
  many as eight years' and `nada menos que ocho años hace': tr_ago_phrase/2), the lesson's language its word for `ago'
  first; after a noun English says with `to', `of' and the -ing form are `to' and the infinitive (`Il tentativo di
  trovare le forze primordiali' was `the attempt of finding': tr_comp_out/7, en_noun_to_inf/1); A WORD THE LESSON CALLS
  AN ACRONYM IS NO NAME'S FIRST WORD BEFORE A PARTICLE (`ai laboratori nazionali Infn di Legnaro' was one name, `Infn di
  Legnaro', its `di' untranslated: tr_particle_names/4), and `"infn" is an acronym.' and `"cnr" is an acronym.' write
  both in capitals; and a group of three words or more takes a mid adverb after its first auxiliary (`ci è stato
  riconosciuto con invidia anche dai colleghi' was `has been also acknowledged': tr_mid_insert/3), the controls' six
  among them (`The body has never been found', `they will also be able to', `will already be institutionalised').
  It needed these WORDS in `extra/' (the two readers: a line moves the reader of one language and the writer of the
  other; the dictionary's own word is said again first where it must stay the one written): Italian `giunta' (a board),
  `"infn"' and `"cnr" is an acronym.', the name `monte bianco' (Mont Blanc), `finalizzato' (targeted), `riveste' (takes
  on, with its forms: the dictionary has no `rivestire'), `ricaduta' (a spin-off), `testuggine' (a tortoise),
  `incrinatura' (a crack), `serafico' (seraphic), `alta energia' (high energy, where `alto' is tall first), `guadagno'
  (a gain), `di punta' (leading), `apologo' (a fable), `ecumenico', `subnucleare', `ciclotrone', `superconduttore', `in
  costruzione' (under construction), `primordiale' (primordial, before the dictionary's overriding), `innanzitutto'
  (first of all), `accoppia' (couples, and joins with its pronoun), `astrofisica' (astrophysics, before the person),
  `ottimistico' (optimistic, with `ottimista' said again first), `riaffida' (entrusts, with `affida' said again first
  and its forms), `quesito' (a question, with `domanda' said again first), `trionfante', `complesso di colpa' (a guilt
  complex, not feminine), `turba' (troubles, with its forms, and a personal verb), `reduce' (a survivor, a person, with
  `sopravvissuto' said again first), `lega' (links, where the dictionary's first is bequeaths), `acceleratore' (an
  accelerator, the noun: the dictionary has the adjective alone), `positivista' (a positivist, a person, not feminine),
  `profondamente' (deeply, before acutely) and `a livello internazionale'; Spanish `específico' (specific, and
  targeted), `reviste' (takes on, with its forms), `repercusión' (a repercussion, and a spin-off), `seráfico', `alta
  energía', `de punta', `ecuménico', `subnuclear', `ciclotrón', `en construcción', `triunfante', `complejo de culpa'
  (not feminine), `perturba' (disturbs, and troubles), `apólogo' (a fable, with `fábula' said again first),
  `positivista' (a person, not feminine) and `a nivel internacional'; and in eng-spa.dix `primordial', written only
  (r="LR"), so that a Spanish `papel primordial' is still read as paramount. The first meaning moved for 5 Italian words
  and no Spanish one (Italian `affida' entrusts, `astrofisica' astrophysics, `lega' links, `primordiale' primordial,
  `profondamente' deeply), the writer's first word for 6 Italian meanings and 2 Spanish ones (Italian board `giunta',
  where it was `asse', a plank, crack `incrinatura', where it was `botto', a bang, gain `guadagno', leading `di punta',
  links `lega', troubles `turba'; Spanish leading `de punta', specific `específico'), and none was lost.
  THE CONTROLS (cocolog 3.62.1, store KB_b4, 134 count files, 3 536 sentences: the earlier set with the Air Europa
  report in, es_20000401-85, both directions; this report is not among them): the last version's translator against this
  one, on the one store, 20 sentences in 14 files read differently, all better -- the mid adverb after the first
  auxiliary (6: `has never been found', `the girl has also been overtaken', `The cores have also been penalised', `they
  will also be able to benefit', `will already be institutionalised', `will also be visited'), `others' (4: `when the
  others were near to the finish', `"all the others" have enormous perplexities', `"what the others" also have',
  Tatoeba's `My mother is not like the others'), `too' before an adjective (3: `"I was too young, him too intelligent,
  too paternal, too much everything"', Tatoeba's `You are too taut', and `We did not go too much in church' for `in
  chiesa non ci siamo andati troppo', where it was `in church too'), the short year (2: `on November 7, '77', `(July 9,
  '95)'), `its traces', `It would be wrong to read' and `Sería incorrecto leer' (2, where it was `would be erred' and
  `equivocado'), and `The British newspaper The Times' and `Il quotidiano britannico' (2, where it was `The rotary
  British' and `Il rotante britannico') -- and the inferences rise 0.039 % (6 786 507 878 to 6 789 121 260): 3 516
  sentences rise, by 257 inferences at the median of the rises, the largest the child-cost report's 43rd (+72 480 of
  47.8 million in each language) and es_19990301-37 18 (+45 thousand of 0.65 million, the newspaper read). Bytes and
  characters read every sentence alike (0 differ, the bytes 0.014 % more). The DATA COLUMN (the last version's
  translator on its own store, KB_a4, against this one on the new): 31 sentences in 20 files, +0.095 % (6 782 646 462 to
  6 789 121 260). THE CODE ALONE (this translator on KB_a4): the same 20 sentences, +0.039 % (to 6 785 259 688). THE
  STORE ALONE (the last version's translator on KB_a4 and on KB_b4): 11 sentences in 7 files, +0.057 % (to 6 786 507
  878), each a word of the report's lines: `lega' links (5: `non si legavano con un intervento terrorista', `segue
  legato', `di legare i passeggi', `Si può legare', and Spanish `enlazadas al turismo' for `legate', where they were
  `allacciare' and `legadas', bequeathed), the CNR in capitals (5), and `in uno di quelle giunte' for `en uno de esos
  tablones', as wrong as the `quelli assi' it was (the writer's word for a board is `giunta' now, and the IR says board
  for the noticeboard).
  THE FIRST ROUNDS' REGRESSIONS, found by reading the texts of every column, the whole case and the writers' first
  words, and mended, each with its arm red: the front's relative-clause guard first refused every phrase after the
  comma, and the Venice report's eighth sentence ran to the limit of 300 million inferences (251 million before),
  narrowed to words that open on a pronoun or a subject; its subject half then refused the basketball report's
  apposition, `Aíto enters' above, narrowed to a rest that names no subject of its own; the first cut of `too much'
  wrote `too much young' and `too much taut'; the report's lines for `riaffida', `reduce' and `apologo' came first for
  the writers (the Italian word for entrusts was `riaffida', for a survivor `reduce', and the Spanish word for a fable
  `apólogo'), and the dictionary's own words are said again first; and Spanish's `primordial' is written only, so that a
  Spanish `papel primordial' is still read as paramount. Two checks of older sections were written in the old English or
  reading: the child-cost section's `what the other ones also have' is `what the others also have', and the Tatarella
  section's guard, `Sembra poco.' refused into Spanish, is `Parece poco.' now that a verb of seeming is no command, so
  the guard is on `Mangia poco.' (a line `"mangia" is the imperative of "mangia".' in that section's lesson), which a
  statement with nobody named still refuses. The whole case's scan of the vocabularies found `positivista', `complesso
  di colpa' and `complejo de culpa', masculine nouns in -a with no denial.
  THE COST OF THE CODE is +0.039 % on the one store, 257 inferences at the median of the 3 516 rises and no sentence
  over 0.2 % but es_19990301-37 18 (+6.9 %, a better reading); it was not taken apart rule by rule. THE STATED COSTS: a
  first meaning that serves the report and not every text -- `lega' links (bequeaths second), `affida' entrusts (trusts
  second), `primordiale' primordial, `profondamente' deeply, `astrofisica' astrophysics (the astrophysicist second) --
  and the writers' words: Italian `giunta' for every board (a plank was `asse'), `di punta' and `de punta' for leading
  (`principale', `puntero'), `incrinatura', `guadagno', `lega' and `turba', Spanish `específico' for specific
  (`concreto'); the twelfth sentence's refusal costs 3.3 million inferences more (the new code on the new store; either
  alone, under 0.06 million); and the inferences, +0.039 % on the one store and +0.057 % for the store alone.
  The report LEAVES, of the 20 into Spanish (English alike unless it says): `El primero considera el experimento Nusex'
  and `regards the experiment Nusex' (1: concerns the Nusex experiment) and `under the Mont Blanc'; English `We have
  proposed him' (2: it); `habíamos ya conseguido los primeros fondos' (3: `ricevuto' is received, `ya habíamos
  recibido'); `nos ha sido reconocido' and `has also been acknowledged us' (4: the dative of a passive); `the
  electronics of the solid state' and `sus relevantes repercusiones' (5: solid-state electronics, `notables'); English
  `digging in the compact tortoise of the Italian physics well' (7: `bene' last, and the testudo is a formation); `para
  la física' and `for the physics' (8: spends on), and the marks on `"Alguien"' and `"Somebody"' alone, where the source
  opens its quotation there; `se gasta poco para los otros en realidad' and `one in reality spends for the others
  little' (9); `También, admitiendo disminuir' and `Also, admitting to diminish' (10: even admitting a cut), `no se
  haría una gran ganancia' and `one would not make a big gain', `que se hace' and `that makes in our labs' (that is
  done) and `colapsa'; `Parece sentir' and `It seems to feel' (11: to hear); `enlazado al sector' (13: `ligado'); `Se
  añade la tendencia ... a la unificación a esto de las fuerzas' and `to the unification to this of the fundamental
  forces' (16: `A questo si aggiunga', to this is added: the subjunctive, and the phrase set in front read into the
  phrase of `to'); English `of which today they search the traces ... lived' (18: the impersonal `si cercano' written
  `they', and the verb last), `monopolios' and `the monopolies' (monopoles) and `either in the caves'; `va a unir con la
  astrofísica' and `goes to join with the astrophysics' (19: the reflexive of `accoppiarsi' lost); `uno se encuentra a
  comparación con' and `one finds to comparison with' (20: finds oneself face to face with) and `in this research'
  written last; `y de la física de los núcleos' (21) and English `among the astrophysics'; `más de un siglo hace' (22:
  `hace más de un siglo') and English `had hoped to make' (to do); and English `They are really far, ..., the times'
  (23: the times are). Into both languages 6, 12 and 15 are refused: 6, a participle in front with its agent and `ben'
  (`Proposto dai fisici del gruppo di struttura della materia ben otto anni fa, è stato approvato dal Cnr solo
  quest'anno'); 12, Ricci's subject and its three insertions before `sembra mettere tutti d'accordo'; and 15, the list
  of three fields, a bracket with a clause in it. The next sample's controls take this report in.
  The lehendakari report (AnCora CESS-CAST-P-19990901-36, 17 sentences, the paper's report on the lehendakari Ibarretxe
  and Herri Batasuna's national executive on ETA's last communique and the peace process, Spanish into Italian and
  English: 17 of 17 and 14 of 17 on a fresh store, 13 and 9 with the new store alone, 10 and 12 with the new code on the
  old store, 9 and 7 before; reasoning 1.0.36). The sample was taken on the cocolog 3.62.1 binary, and cocolog stays
  3.62.1; master's 7e4bac2 (cocolog 3.62.2, read_file_to_codes/2 under the stack limit) came during the sample, changes
  nothing under library/reasoning/, and is not merged: the next sample takes it. The article's sentences fall from 139.5
  million inferences into Italian and 139.0 into English to 59.4 and 58.6, of which the fourth, the sixth and the
  fourteenth are 11.4, 12.2 and 12.5 million in each. English refuses 3, 5 and 9 for the third person nobody names, on
  purpose (`en el que responsabilizaba a un sector del PNV ...', `donde aprovechó para dar su punto de vista', `al que
  aludió con el término "apagón"').
  It needed these SHAPES, each with its arm red (test/translate.pl's `newspaper_lehendakari': 25 checks, 27 arms, all
  red in the section; an arm is a library directory of symlinks whose reasoning/translate.pl is the edited copy,
  `COCOLOG_LIBRARY=ARM cocolog query "use_module('test/translate.pl'), newspaper_lehendakari, checks_done"', a few
  seconds a run): A COMPARATIVE BEFORE `de lo que' COMPARES WITH WHAT FOLLOWS (`el debate va mejor en privado de lo que
  trasciende' goes better in private than what transpires -- `mejor' was no word of the list tr_compared_before/2 asks,
  and the sentence had no reading), the clause after `de lo que' the comparison's with nobody named, which English
  writes `than what' and its verb (tr_comp_out/7), a comparative after a verb that is no copula the adverb (Italian's
  `va meglio', where the comparative of `good' came out `va migliore': tr_comparative_adverb/3), and English's `better'
  in its place, before the phrases between it and the comparison, where it was written last (tr_comps_out/7) -- four
  arms; `a que' AND A SUBJUNCTIVE AFTER A NAME A VERB ENCOURAGES ARE `a' AND THE INFINITIVE (`la coalición radical animó
  al PNV a que acepte los reproches de ETA' encouraged it to accept them, and the clause had no reading:
  tr_a_que_inf/3), the name the verb's object (tr_named_object/3) -- two arms; ITALIAN'S `ad' AND `ed' (`The preposition
  "ad" comes before "a".', `The conjunction "ed" comes before "e".' and before `è': `ad accettare', `il Governo ed ETA',
  `ed è grande', where they were `a' and `e' (`continua a aumentare', `il PNV e ETA'): tr_euphonic_form/3 in
  tr_contract/3, the forms a list made once a lesson changes); a word that is a determiner too, before a noun, is no
  preposition that ends the phrase (`recomendó al PNV "más deportividad"' -- `más' is the preposition `plus' too, with
  no phrase after it, and the words had no reading: tr_more_determiner/2, the degree words a list made once a lesson
  changes, tr_gen_words/2); `ago' IN A COMPARISON IS THE COMPARED PHRASE'S (`Destacó de entrada que "la situación es
  notablemente mejor que la de hace un año"' is better than that of a year ago, and in the clause of `that' the time
  came out after the verb, `è fa notevolmente migliore di quella d'un anno': tr_ago_in_comparison/2), in a clause of
  `that' too -- two arms; an adverb in -ly straight before a comparative is said of it (notably better, where `notably'
  was written last: tr_comps_out/7); `blames' TAKES `for' AND THE GERUND, AND `hinders' ITS PHRASE BARE
  (`responsabilizaba a un sector del PNV de poner trabas a la pacificación' blames it for hindering the pacification,
  where it was `to hinder to the pacification': en_prep_gerund/2, en_bare_object/1), a group after a verb of blaming or
  encouraging is its object, marked as a person is (`incolpava un settore', `incoraggia un settore', where it was
  `incolpava a un settore': en_person_passive/1, tr_warned_group/3, `"sector" is a group.'), AN INFINITIVE AFTER ITS
  PREPOSITION GOVERNS THE PHRASE AFTER IT (with the sector's phrase of `of' between the verb and its `de', the
  infinitive was read after its preposition, pinf/2, and Italian wrote the phrase with its `a', `d'ostacolare alla
  pacificazione': tr_governing_verb/3), and English writes the preposition its verb takes before the gerund, where the
  source's `de' came out `of hindering' (tr_comp_out/7) -- six arms; AN ADVERB, ITS COMMA AND A GERUND CLAUSE ARE ONE
  GERUND CLAUSE WITH ITS FRONT (`..., y, además, teniendo en cuenta que es parte fundamental en este conflicto' -- with
  the comma the gerund was a front with its clause of `that' left open, and the words after `es' a clause of their own,
  `parte' the verb that departs: tr_read0/4); a quotation that opens on a relative word and closes on the verb the
  clause ends on closes where the clause ends (`las críticas, "que en política siempre vienen bien"' -- the words before
  the verb are written after it, and with the mark on the verb they came out outside the quotation: tr_rel_mark/3); the
  reflexive pronoun after a preposition is the subject's (`estas formaciones entre sí' talk among themselves, where it
  was `among itself': tr_write/4); WHAT FOLLOWS A COPULA IS NO THING ITS SUBJECT OWNS (`El diálogo fue su receta' was
  HIS prescription, Ibarretxe's, and it came out `its prescription': tr_cross/3), and after any other verb it is the
  thing's (`La vida continúa su curso', a guard) -- two arms; and A QUOTATION THAT OPENS ON AN INFINITIVE OPENS THERE:
  on its denial (`Ibarretxe recomendó "no cerrar puertas"' -- the mark was taken for the verb group's, `"raccomandò non
  chiudere porte"': qm/2, tr_complements0/4), on the infinitive, where its mark was lost, before English's `to', as no
  word of the source stood before the mark (bare/1, tr_comp_out/7), around every word written for it where the mark
  opens and closes on it (`lo que hace es "desacreditar" la investigación' came out `is "to" discredit', found by the
  controls), and after a preposition (`el futuro del proceso está en "reconocer como válidos ..."' lost its opening
  mark: qinf/2) -- five arms.
  It needed these WORDS in `extra/' (the two readers: a line moves the reader of one language and the writer of the
  other; the dictionary's own word is said again first where it must stay the one written): Spanish `trasciende'
  (transcends, where the dictionary's English is `trascends', and transpires with no object, with its forms),
  `peneuvista' (a PNV member, a person, not feminine: the dictionary has the adjective alone), `culpa' said again first
  and `responsabiliza' (blames, with its forms, `de' before the infinitive), `obstaculiza' and `pone trabas' (hinders,
  with its forms, `a' before the phrase), `reproche' (a reproach: the dictionary has the subjunctive of `reprochar'
  alone), `callejero' and `callejera' (street), `aclara' said again first (clears, then clarifies) and `matiza'
  (clarifies, with its forms, taking the clause), `partido político' and `partido nacionalista' (a party, where
  `partido' is a match first, `"partido nacionalista" is not feminine.'), `proceso de paz', `insulto' said again first
  and `descalificación' (an insult), `mesa nacional' (a national executive), `maduración' (maturation, where the
  dictionary's English is `maduration'), `a juicio de' (in the opinion of), `ayuda' said again first and `viene bien'
  (helps), `"sector" is a group.', `"corresponde" is intransitive.', `"dialoga" is intransitive.', `"influye" takes "en"
  before the phrase.' and `en política' (in politics); Italian `trapela' (transpires, with its forms, intransitive),
  `peneuvista' (a person, not feminine), `sportività' (sportsmanship), `incolpa' (blames, with its forms, `di' before
  the infinitive), `ostacola' (hinders, with its forms), `rimprovero' (a reproach), `di strada' (street), `partito
  politico', `partito nazionalista' (not feminine), `processo di pace', `esecutivo nazionale', `maturazione',
  `formazione' (a formation: the writer's word was `educazione', an upbringing), `a giudizio di', `"ad" comes before
  "a".', `"ed" comes before "e".' and before `è', `comparsa' (an emergence: the Italian writer had no word for one), `in
  politica', and `rottura' (a break said again first, and a split, which the Italian writer had no noun for). The first
  meaning moved for 3 Spanish words and 2 Italian ones (Spanish `descalificación' an insult, where it was a
  disqualification, `maduración' and `trasciende', the spellings mended; Italian `formazione' a formation, where it was
  a training, `maturazione'), the writer's first word for no Spanish meaning and 2 Italian ones (formation `formazione',
  where it was `educazione'; hinders `ostacola', where it was `impaccia'), and none was lost.
  THE CONTROLS (cocolog 3.62.1, store KB_c8, 136 count files, 3 582 sentences: the earlier set with the physics report
  in, it_4860_4882, both directions; this report is not among them): the last version's translator against this one, on
  the one store, 20 sentences in 17 files read differently, all better -- Italian's `ed' and `ad' (12: `Jordi Vilajoana
  ed Enric Sopena', `ampliabile ad altri casi', `"intervenga di lavoro" ed emette', `tra Baleares ed El Prat',
  `mediterraneo ed europeo', `PNV ed EA', `continua ad aumentare', `sorprendente ed efficace', `d'un luogo ad altri',
  `si resiste ad abitare', `tra il PNV ed ETA', `ed è la nostra traiettoria'), a quotation that opens on an infinitive
  (2: `lo que hace es "desacreditar" la investigación' is `quello che fa è "screditare" l'investigazione' and `is "to
  discredit"', es_19981202-34 10), a relative clause's marks (2: `"which they have been torpedoing"' and `"che sono
  stati sabotando"', es_20000903-30 18), `a "ballast" for themselves' (es_20000903-30 19, where it was `for itself'),
  `the possibility of influencing the choices' (it_9605_9636 26, where it was `influencing on'), and `participating in
  the table' and `participar en la mesa' (it_9673_9712 23, where they were `participating to' and `participar a': the
  infinitive after its preposition governs its phrase) -- and the inferences rise 0.033 % (6 941 079 155 to 6 943 367
  822): 3 569 sentences rise, by 267 inferences at the median, +0.029 % of the 1 265 under 0.2 million, the largest the
  Rognoni interview's nineteenth (+34 159 of 176.4 million, refused both ways) and the Venice report's eighth and fourth
  (+27 969 of 251.4 and +18 867 of 85.8), and the four that fall most have `más' and a noun, which the determiner's rule
  reads at once (Tatoeba's `Deberías darle más libertad a tu hijo' and `con más atención', `sin más compañía', `con más
  serenidad', some 30 000 inferences fewer each). Bytes and characters read every sentence alike (0 differ, the bytes
  0.014 % more). The DATA COLUMN (the last version's translator on its own store, KB_b4, against this one on the new):
  the one store's 20 sentences, +0.043 % (6 940 381 150 to 6 943 367 822). THE CODE ALONE (this translator on KB_b4): 9
  sentences in 8 files, +0.032 % (to 6 942 622 018), 8 of them among the 20 and one worse, which the new store's line
  mends: `la possibilità di incidere sulle scelte' is `influir las elecciones' (it_9605_9636 26), where it was `influir
  en las elecciones' -- the infinitive after its preposition governs its phrase now, and with no word stated for
  `influye' the Spanish writer writes it bare; the 12 left are Italian's `ed' and `ad', which need the new lines. THE
  STORE ALONE (the last version's translator on KB_b4 and on KB_c8): 0 sentences, +0.010 % (6 940 381 150 to 6 941 079
  155): the noun `peneuvista' and `"corresponde" is intransitive.' cost four sentences a reading for nothing, the texts
  the same (es_20020801-17 10, `el líder peneuvista', +0.29 million inferences of 5.28 in each language, and three with
  `corresponde' or `correspondiera', +0.05 to +0.08 million each).
  THE FIRST ROUNDS' REGRESSIONS, found by reading the texts of every column, the whole case and the writers' first
  words, and mended. Of the store: the Spanish writer's first words for helps, blames and clarifies were the report's
  `viene bien', `responsabiliza' and `matiza', and the dictionary's `ayuda', `culpa' and `aclara' are said again first;
  the whole case's scan of the vocabularies found `partido nacionalista' and `partito nazionalista', masculine nouns in
  -a with no denial; and two lines, `The reflexive verb "encuentra" means "is".' and its Italian `trova', written for
  `el proceso de paz se encuentra en fase de maduración', which English writes `finds in phase', cost the store alone of
  KB_c7 +4.994 % of the controls and 21 sentences: the Venice report's fourth (it_9999_10010 4) was read in 85.8 million
  inferences in each language and refused after 258.6, `se lo encuentra a otra' was `lo es otra' and `one finds it
  another one' `another one is it', `no se encuentra ni siquiera un fragmento' `no es ni siquiera un fragmento' and `it
  is not even a snippet', and two English sentences were refused (es_20010102-25 12, `Thabet was felled to shots on
  Sunday when one found near his house', and it_9800_9814 4): both lines are out, and `finds in phase' is a stated cost.
  Of the code (the one store): `lo que hace es "desacreditar" la investigación' came out `is "to" discredit' (a mark
  around one word the writer writes as two), and the Spanish of `la possibilità di incidere sulle scelte' `influir las
  elecciones' (the infinitive after its preposition governs its phrase now, and with no word stated for `influye' the
  Spanish writer wrote it bare: `"influye" takes "en" before the phrase.'). The first cut's arms found four green -- the
  name the verb's object, the determiner, `ago' in a comparison and in a clause of `that' -- and the checks were made so
  that each goes red (`ETA animó al PNV a que acepte las críticas' into Italian, `ETA recomienda al PNV más
  deportividad' into English, and the comparison inside a clause of `that' into Italian); a hunk of the determiner's
  rule that changed nothing, not even its cost, is gone.
  THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT (32 control sentences of 0.1 to 0.5 million inferences, 16 from
  each language, into English, over a copy of the library per rule): the first cut was +0.111 % of the controls on
  KB_c7, +0.83 % of the sentences under 0.2 million, some 1 300 inferences a sentence, and the 32 rose 16 533
  inferences: the `a que' rule's scan, asked of every piece the reader reads, asked the lexicon at every position of it,
  and the lists of `that' and of the degree words, kept against '$tr_gen', were made again at every reading -- '$tr_gen'
  moves at every tr_memo_reset/0, every sentence and every piece. What paid was the list of the conjunctions that mean
  `that' alone, the lists kept against a counter that moves only where a lesson is learned or unlearned ('$tr_lessons',
  tr_lessons_moved/0 in reason_learn/3 and reason_unlearn/1), and the cheap tests first in three rules (the name's
  object, the comparative adverb, `ago' in a comparison). A note of the `a que' pattern made once a sentence where its
  words are made ('$tr_a_que', asked by the rule first) paid while the lists were made at every reading, and with the
  lists kept its arm, the note always yes, was green and cheaper: over 300 control sentences picked at random, 150 from
  each language, into English, the note cost 958 inferences more than none and saved 147 at most in one sentence, every
  text the same, and it is gone. The 32 rise 3 846 inferences (+0.044 %, 8 684 101 to 8 687 947), of which the
  determiner's rule is 1 174, the possessive after a copula 212, the reflexive after a preposition 111 and `ago' in a
  clause of `that' 94, no other rule's arm over 50; the rest is the new clauses entered and failing, a few inferences
  each.
  THE STATED COSTS: `el proceso de paz se encuentra en fase de maduración' is `finds in phase' in English (11: the
  reflexive `is' line, above); the store's four sentences read again for nothing (+0.010 % of the controls); `en
  política' as one adverb makes sentence 16's `in politics', where it was `in policy', and costs it 0.58 million
  inferences in each language (3.19 million, where a store with no such line reads it in 2.61); a first meaning that
  serves the news and not every text -- `descalificación' is an insult (a disqualification second), `formazione' a
  formation (a training second) -- and the writer's `formazione' for a formation (`educazione', an upbringing, before)
  and `ostacola' for hinders (`impaccia' before); and the inferences, +0.033 % on the one store and +0.010 % for the
  store alone.
  The report LEAVES, of the 17 into Italian (English alike unless it says): `i peneuvisti' and `the pnv members' (2: the
  acronym in small letters inside the word) and `the criticisms of the band' (ETA, a terrorist band); `i portavoce
  dell'esecutivo nazionale d'Herri Batasuna coincisero' and `in un'analisi ottimista' (3: agreed in an optimistic
  analysis); `sfruttò per dare il suo punto di vista' (5: took the opportunity to give it); `Evidenziò per cominciare'
  and `They highlighted to begin with' (6: he stressed at the outset, the subject the sentence before it names) and
  `Euskadi crosses a good moment' (is going through one); `la pace è sempre più vicino' (7: `vicina', the adjective of
  the comparison agreeing with no noun) and `the peace is increasingly near' (peace); `che descrisse come
  "inaccettabili"' and English `which described as "unacceptables"' (8: which he described as unacceptable, the
  adjective in the plural) and `the split of the conversations' (the breakdown of the talks); `riconoscere come vigente
  parte degli argomenti degli altri' (9: `validi', valid); `la sua prescrizione' and `his prescription' (10: his recipe)
  and `i distinti livelli' and `the distinct levels' (the different levels); `il processo di pace si trova in fase di
  maturazione' is right, and English writes `the peace process finds in phase of maturation' (11: is in a phase), `senza
  "marcia dietro"' and `without "march backwards"' (without a reverse gear) and `would not allow him' (it); `Proprio,'
  and `Precisely,' (12) and `the prominence of the peace process corresponds to the citizens' (belongs to them); `the
  last communiques of ETA' (13: the latest); `la soluzione al conflitto passa per garantire' is right, and English
  writes `spends for guaranteeing' (14: goes through guaranteeing), `due dati futuri' (two future dates, `date':
  `fechas' read as data), `annuncio dell'Assemblea' (the calling of the Assembly) and `Municipii'; `the insults that ETA
  launched to the PNV through his last communique' (15: at the PNV, its last communique); `che in politica sempre
  aiutano' and `which in politics always help' (16: always come in handy, `sempre' after the verb in Italian); and `ETA
  has right to express his opinion' and `it is fundamental part in this conflict' (17: the right, its opinion, a
  fundamental party to the conflict). The next sample's controls take this report in.
  The Eco profile (VIT-10096..10109, 14 sentences, a profile of Umberto Eco at seventy, Italian into Spanish and
  English: 12 of 14 and 12 of 14 on a fresh store, 9 and 9 with the new store alone, 3 and 4 with the new code on the
  old store, 3 and 3 before; reasoning 1.0.37). The sample was taken on the cocolog 3.62.2 binary, master's 7e4bac2
  merged as 92e9e0a, and cocolog stays 3.62.2: the controls read every sentence alike on 3.62.1 and 3.62.2 (3 582
  sentences, 0 differ, the same counts to the unit). The article's sentences fall from 147.9 million inferences in
  each language to 109.0 into Spanish and 108.9 into English, of which the fourth, refused, is 59.1 million in each.
  THE SECTION IS `newspaper_umberto': `newspaper_eco' is the Eco essay's of an earlier sample, and the section
  generator, which takes an old copy of its section out up to `question_roles :-', first cut 9 184 lines of
  test/translate.pl from it (restored from git before anything ran).
  It needed these SHAPES, each with its arm red (test/translate.pl's `newspaper_umberto': 27 checks, 27 arms, 24 red
  in the section and three green that stay, below; an arm is a library directory of symlinks whose
  reasoning/translate.pl is the edited copy, `COCOLOG_LIBRARY=ARM cocolog query "use_module('test/translate.pl'),
  newspaper_umberto, checks_done"', two seconds a run): A MODAL WITH A VERB OF NO AGENT AFTER IT HAS `it' FOR ITS
  SUBJECT (`Oggi può capitare di incontrarlo' is it can happen to meet him, as `Capita di incontrarlo' is it happens
  to, and read with nobody named English refused the modal: en_null_it/2), the modal's first infinitive only (a guard
  the controls found: `Oppure potrebbe seguirne l'esempio e capitare ad altre sponde' was `it could follow his
  example', where English refuses the third person nobody names, on purpose); UNDER A MODAL ONLY THE FIRST INFINITIVE
  IS BARE (`can happen meet him': the infinitive after the first is the first one's, tr_comps_out/7, and the controls'
  `who would have been able to think to mediate with Hitler'), never after a verb that makes, lets or perceives, whose
  infinitive is bare too (a guard the controls found: Tatoeba's `Nadie puede oírte gritar en el espacio' was `hear you
  to shout', and `deve avergli fatto cambiare idea' `made him idea change') -- four arms; WHAT IS LACKING IS MISSING
  FROM WHAT LACKS IT (`al dibattito italiano mancavano gli strumenti analitici' -- the instruments were missing from
  the debate, `"manca" is intransitive.' making them the subject, and with the phrase of `to' the lesson's `lacks'
  came out `lacked to': tr_write/4), in a relative clause too (`uno dei pochissimi Athanasius Kircher che mancano alla
  sua stravagante collezione'), and with an object after a purpose (`per cogliere gli effetti') -- two arms; A NOUN, A
  DASH AND A NOUN IN SMALL LETTERS ARE ONE COMPOUND (`Eco è un intellettuale - puzzle: nessuna tessera, da sola, lo
  definisce', `alcune tessere dell'Eco - puzzle' -- read as the dash that joins two pieces, the second was a noun
  alone and the sentence was cut or refused: tr_asides/3, dash1), never before a word that is a verb form and no
  adjective (a guard the first cut broke: the Lazio report's headline `Calcio - dichiarazioni varie del giocatore',
  whose `varie' is a verb form too) -- two arms; A DETERMINER OF QUANTITY MAY STAND BEFORE A NAME (`uno dei pochissimi
  Athanasius Kircher', which had no reading: tr_np/3, tr_name_pre_det/2); A MARK THAT ENDS A BRACKET ENDS NO SENTENCE
  (`l'augusto compleanno del professore (settant anni!) sorprende tutti' was cut at the `!' and both halves refused:
  tr_split/2, tr_bracket_marks/3); `finds' WITH ITS OWN PRONOUN IS ENGLISH'S `finds oneself' (en_true_reflexive/1: the
  controls' `The fusion will find itself with fetters', `the peace process finds itself', `the two parts "find
  themselves"'), and a name keeps the verb bare, its gender being none the IR carries; A COMPARATIVE IN AN OBJECT
  COMPARES WITH THE PHRASE OF `di' AFTER IT (`alcune tessere ... hanno una rilevanza maggiore di altre', and the
  controls' `his opponents had made more precise calculations than his', where it was `of the hers ones':
  tr_cross_comps/2), a definite phrase's adjective being a superlative to the reader already, whose `di' is `of' (a
  guard whose arm was green as a test in the rule, which is gone); `da' AND A BARE PERSON AFTER AN OBJECT SAY WHOSE
  KIND IT IS (`Ma non sono vezzi da intellettuale affermato' are affectations of an established intellectual, and read
  as a phrase of `from' it was `from established intellectual': tr_cross_comps/2); THE ADJECTIVE AFTER A LINKING
  VERB'S PHRASE IS ITS PREDICATE (`I suoi rimbalzi ... sono diventati in certi casi proverbiali' have become
  proverbial in some cases, and read as the phrase's own it was `have become in some proverbial cases':
  tr_linking_pred/3), never after the copula, whose phrase keeps its adjective, nor with the phrase of `like' (a guard
  the controls found: `sin que ... la ornamentación final aparecieran por allí como fuegos fatuos' was `fatuous as
  fires' and `fatue come fuochi') -- three arms; `at ease' STAYS IN ITS PLACE (`sentirsi a proprio agio nelle
  situazioni' is to feel at ease in them, and written last it was `To feel in the situations at ease': tr_comp_out/7);
  A SUPERLATIVE JOINED TO AN ADJECTIVE AFTER IT IS ONE DEGREE, before the plain adjectives the source put before it
  (`nelle situazioni culturali più variegate e vivaci' are the most varied and lively cultural situations, and with a
  coordinator in the list the source's order stood, `the cultural most varied and lively situations': en_adj_order/3);
  THE WORD FOR `also' OR `even' THAT IS A NOUN TOO, BETWEEN A NOUN AND ITS ADJECTIVE, IS THE ADJECTIVE'S (`per una
  serie di ragioni anche generazionali' -- `anche' is the plural of `anca' as well, the phrase ended at it, the
  adjective had no noun and the front no reading: tr_focus_ints/3, a pass of its own over a phrase that holds one of
  the sentence's such words, and tr_focus_adj_start/2, which lets the phrase go on over it), and English writes such
  an adjective after its noun (the controls' `are a problem also mine', where it was `are also a problem mine', and
  the first cut's `an also mine problem': tr_names_last/3), only after a noun, never after a coordinator, where it is
  the clause's (a guard the controls found: `presidente della società di fisica e anche responsabile del progetto'
  went on over it, and `anche responsabile' was `responsible hips'), nor before the word for `only' (a guard red in
  the store alone: `sono una piccola imprenditrice ..., odio anche solo l'idea della guerra' was `I am also only a
  small businesswoman of 29 pacifist years convinced hate the idea', which no hand lesson reproduces and which stays
  for what the controls show), nor beside a participle (a guard of cost, green: `Era stato anche proibito alla radio
  brasiliana ...' read so again, 6.86 million inferences where it is 5.42, the text the same) -- four arms red, two
  green; and A NAME THE LESSON STATES ENDS NO FRONT BEFORE AN IMPERSONAL VERB (`alla fine degli anni cinquanta Eco si
  è trovato nella posizione migliore' is Eco finding himself there, and longest first the name was apposed to the
  years, `One has found in the best position at the end of the fifty years Eco': tr_read0/4, beside the rule for a
  front that ends on a name before a verb with nobody named), a name the lesson states only, as the impersonal word
  may follow a place's own name (`nel teatro Morlacchi si canta' is one singing there, a guard) -- two arms. Two
  pieces of the first cut had arms that stayed green in the section and changed nothing in the controls, and are gone:
  a clause of tr_rel_doer_fix/3 for the definite phrase after an intransitive verb in a preposition's relative clause
  (`i modi in cui funzionano i segni' reads by tr_rel_subject_fix/2, through `in cui' and `nei quali' alike), and the
  comparison's test of its object's determiner (above). The note `$tr_focusnoun', the sentence's words for `also' or
  `even' that are nouns too, made once a sentence in tr_into_ir/4, is a guard of cost, green (below).
  It needed these WORDS in `extra/' (the two readers: a line moves the reader of one language and the writer of the
  other; the dictionary's own word is said again first where it must stay the one written): Italian `buon compleanno'
  (happy birthday), `compie gli anni' (has a birthday, with its forms, intransitive), `nome della rosa' (the novel's
  title, not feminine), `antiquario' and `antiquaria' (antiquarian), the determiners `pochissimo' and `pochissima'
  (very few), `stravagante' (extravagant: the dictionary's word is the old `estravagante'), `vezzo' (an affectation),
  `affermato' and `affermata' (established), `a proprio agio' (at ease), `esordio' (a beginning, `inizio' said again
  first), `puzzle' (its own plural), `informatica' (computing), `bibliofilia', `augusto' and `augusta' (venerable),
  `settant' (seventy, the paper's form with no apostrophe, `settanta' said again first), `irrequieto' and `irrequieta'
  (restless, `inquieto' and `inquieta' said again first), `consueto' and `consueta' (usual, `abituale' said again
  first), `carica' (a post, where it is a charge first), `rilevanza' (relevance), `teorico' (a theorist, a person),
  `vagito' (a wail), `fondamento' (a basis), `semiologico' and `semiologica', `novecento' (the twentieth century),
  `coglie' (grasps, with its infinitive: the dictionary has none), `tavola rotonda' (a round table), `alla caccia di'
  (in search of), `recentemente' (recently, where the dictionary's first is freshly), `semiotica' (semiotics, the
  noun: the dictionary has the adjective alone), `"funziona" is intransitive.', `da sola' and `da solo' (on its own),
  `"manca" is intransitive.', `"eco" is a name.' and `nei confronti di' (towards); Spanish `feliz cumpleaños', `cumple
  años' (with its forms, intransitive), `nombre de la rosa' (not feminine), `anticuario' and `anticuaria', `poquísimo'
  and `poquísima', `consagrado' and `consagrada' (established), `a gusto', `bibliofilia', `relevancia' (relevance,
  where it was importance), `semiológico' and `semiológica', `siglo veinte', `mesa redonda', `erudición', `semiótica',
  `por sí solo', `a la caza de', `honorífico' and `honorífica', `generacional' (the dictionary has no Spanish
  adjective for generational) and the tenses of `falta' (the dictionary gives `faltar' none, and the Spanish writer
  had no imperfect for `lacks': sentence 13 was refused) with `"falta" is intransitive.'. The first meaning moved for
  3 Italian words and 1 Spanish one (Italian `carica' a post, `coglie' grasps, `recentemente' recently; Spanish
  `relevancia' relevance), the writer's first word for 5 Italian meanings and 1 Spanish one (Italian affectation
  `vezzo', where it was `affettazione', basis `fondamento', where it was `base', extravagant `stravagante', grasps
  `coglie', where it was `abbranca', relevance `rilevanza', where it was `attinenza'; Spanish relevance `relevancia',
  where it was `pertinencia'), and none was lost.
  THE CONTROLS (cocolog 3.62.2, store KB_d5, 138 count files, 3 616 sentences: the earlier set with the lehendakari
  report in, es_19990901-36, both directions; this profile is not among them): the last version's translator against
  this one, on the one store, 8 sentences in 7 files read differently, all better -- `finds itself' and `find
  themselves' (3), `who would have been able to think to mediate with Hitler', `are a problem also mine' and Spanish's
  `un problema también mío' (where it was `míos'), and `more precise calculations than his' in both languages (`than
  the hers ones', the possessive's own fault) -- and the inferences rise 0.055 % (7 065 277 733 to 7 069 153 464): 3
  612 sentences rise, by 286 inferences at the median, the largest the Venice report's eighth (+0.14 million of
  251.5), the physics report's twelfth (+0.05 of 40.5, refused both ways) and it_9967_9998 22 (+0.03 of 32.8), and two
  fall. Bytes and characters read every sentence alike (0 differ, the bytes 0.014 % more). The DATA COLUMN (the last
  version's translator on its own store, KB_c8, against this one on the new): 12 sentences in 11 files, +0.110 % (7
  061 385 771 to 7 069 153 464). THE CODE ALONE (this translator on KB_c8): the same 8 sentences, +0.055 % (to 7 065
  261 706). THE STORE ALONE (the last version's translator on KB_c8 and on KB_d5): 4 sentences in 4 files, +0.055 %
  (to 7 065 277 733), each a word of the profile's lines: `carica' is a post (`with the post of vicedirector', `the
  intake of the post', where it was the charge) and `coglie' grasps (it_9381_9414 29, `has also been grasped her from
  syncope' and `aferrada', where it was `overtaken' and `sorprendida', a stated cost).
  THE FIRST ROUNDS' REGRESSIONS, found by reading the texts of every column and mended, each with its arm red. Of the
  code: the first cut of the word for `also' before an adjective, a pair the intensifier test took wherever it stood,
  cost +0.843 % of the controls on the one store and changed five sentences, three for the worse (`I am also only a
  small businesswoman of 29 pacifist years', `are an also mine problem', `it must be also responsible', and two
  adverbs `still' moved: `believed her still flat', `seems still far'), and the second, which asked a noun before it,
  read the physics report's twelfth sentence with `anche responsabile' as `responsible hips', where it is refused (the
  phrase went on over the word after a coordinator); the null `it' of a modal took any infinitive and read `Oppure
  potrebbe seguirne l'esempio' as `it could follow his example'; the second infinitive under a modal took `to' after a
  verb of hearing and of making; and the linking predicate took the adjective of a phrase of `like'. Of the store: the
  third store (KB_d3) had no tense of `faltar' and no Spanish `generacional', and sentence 13 was refused into
  Spanish.
  THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT (the heaviest risers of each round over a copy of the library
  per rule on KB_d5): the first cut's rule for `anche' was 6.25 million of the 6.38 million inferences seven risers
  rose (`Era stato anche proibito', `odio anche solo l'idea', the Venice eighth's `tende, anche con l'aiuto'): asked
  of every pair of words of every phrase, it opened readings in every sentence that has the word. With a noun before
  it, no participle on either side and the sentence's own such words in the note, nine risers rose 1.36 million of
  395.1; as a clause of tr_intensify/3 it was still tried at every word of every phrase, 0.76 million in the Venice
  eighth alone, and as a pass of its own, asked only of a phrase that holds such a word (memberchk/2, one step), the
  nine rose 0.30 million (+0.075 %). The note pays 1 % of a long Spanish sentence, es_20000903-30 18, which has no
  such word (62.43 million inferences, 63.07 without it), and the participle guard a quarter of the Veloso interview's
  twenty-sixth (above). Over 24 sentences of the controls of 0.1 to 2 million inferences picked at random, 12 from
  each language, into English, the final code rises 11 548 inferences of 8.47 million (+0.136 %): the bracket's walk
  of every sentence's codes 1 987, the determiner before a name 697, the adverb's start 363, the rest under 60 each,
  and the note saves 12 380 of what the rule would cost there.
  THE STATED COSTS: a first meaning that serves the profile and not every text -- `carica' is a post (a charge
  second), `coglie' grasps (`colta da sincope', struck by it, is `grasped' and `aferrada'), `recentemente' recently --
  and the writers' `vezzo' for an affectation, `fondamento' for a basis (no sentence of the controls has one),
  `stravagante', `coglie', `rilevanza' and `relevancia'; English writes `For a series of reasons also generational',
  stiff; the physics report's twelfth sentence stays refused (+0.05 million inferences); and the inferences, +0.055 %
  on the one store and +0.055 % for the store alone.
  The profile LEAVES, of the 12 into Spanish (English alike unless it says): `Profesor fenomenología feliz cumpleaños
  de Umberto Eco' and `Phenomenology professor happy birthday of Umberto Eco' (1: the headline's order, happy
  birthday, Professor Phenomenology); `Cumple años el autor más famoso al mundo' and `has a birthday to the world' (2:
  in the world, `del mundo'), `desde el libro en Mike' (`sobre Mike') and `de Stefano Bartezzaghi' and `of Stefano
  Bartezzaghi' (the byline, by); `Puede pasar encontrarlo' (3: `Puede ocurrir que uno lo encuentre'), `recogida'
  (`colección': the writer's word for a collection, sample 64's stated cost), and `hoy' and English's `possibly today'
  written last; `más varias' (6: `variadas') and `para Umberto Eco' last; `ninguna carta' and `no card' (7: a tessera
  of the puzzle is a piece); `de la erudición a la vida diaria' is right, and English writes `from the erudition to
  the daily life' (8); `sorprende todos' (9: `a todos'), `in his contemporaries' (among them) and `the venerable
  birthday'; `de la Eco – rompecabezas' and `of the Eco – puzzle' (10: the paper's coinage keeps its article, `del
  Eco') and `mayor que otros' (`otras', the pieces); `Entre las primeras cosas que deben ser dichas de Eco es que se
  trata de un semiólogo' and `it is that it is a semiologist' (11: he is); English writes `in which they function the
  signs and the manners in which the people communicate among them' (12: the second phrase with its own relative
  clause is read into the first clause's object, and a guard that refused that reading left the sentence with none;
  `fra di loro' is among themselves); and `en la posición mejor' (13: `en la mejor posición'), `aferrar' (grasp:
  `captar') and English's `Eco has found in the best position' (himself: a name keeps the verb bare) and `at the end
  of the 50s,' with a comma the source lacks. Into both languages 4 and 14 are refused: 4 is a fragment that goes on
  from 3 (`Oppure in una manifestazione pubblica, come la tavola rotonda ... che si terrà al Piccolo di Milano il 21
  gennaio, e in cui si confronterà con ...'), and 14 a front with two dashes (`Con un lavoro su più piani - come
  teorico e come autore televisivo, ... - ha portato in Italia quel che in Italia non c'era ancora: ...'), whose verb
  has a third person nobody names, which English refuses on purpose. The next sample's controls take this profile in.

