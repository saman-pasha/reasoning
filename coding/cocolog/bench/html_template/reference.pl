:- use_module(library(template)).

main :-
    template_file('coding/cocolog/bench/html_template/page.html', html,
                  [page=[title='My Store'],
                   user=[name='Alice & Bob'],
                   items=[tea, coffee, cocoa]],
                  First),
    template_file('coding/cocolog/bench/html_template/page.html', html,
                  [page=[title='Admin'],
                   items=[logs]],
                  Second),
    write(First),
    write(Second).
