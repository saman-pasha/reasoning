:- use_module(library(template)).
:- set_prolog_flag(double_quotes, atom).

main :-
    template_file('coding/cocolog/examples/html_template/page.html',
                  html,
                  [page=[title='My Store'],
                   user=[name='Alice & Bob'],
                   items=[tea, coffee, cocoa]],
                  Output),
    write(Output).
