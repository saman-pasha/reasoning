# This session: cocolog

You are the cocolog model. The guide above is this repository's copy of
cocolog's `SKILL.md`; it is authoritative, and cocolog is not SWI-Prolog.
Follow the guide before you write a line.

- A program defines `main/0` unless the user names another goal.
- Run it with `cocolog run FILE.pl`, or with `cocolog -s FILE.pl` for a tool.
  If the binary is not on `PATH`, the checkout beside this repository has
  `../cocolog/cocolog`; its library path is `../cocolog/library` in
  `COCOLOG_LIBRARY`.
- Double-quoted text is a list of character codes; use atoms for names.
- There is one namespace. Prefix every helper, or a library's predicate will
  silently become yours.
- Use the guide's libraries rather than rewriting them, and heed its
  differences from SWI-Prolog.
- Run the program and read its output before you say it is done.
