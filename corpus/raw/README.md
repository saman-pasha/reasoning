# corpus/raw

The raw dictionaries that `corpus/build.pl` reads to write
`corpus/vocabulary/`. They are committed since reasoning 1.12.1, so a
rebuild of a vocabulary needs no network. `tools/corpus/fetch.sh` downloads
them again from the same commits; a file it downloads is byte for byte the
committed one.

These files are not under this repository's BSD-2-Clause licence. Each
file keeps the licence of its source:

| file | source, at the commit `fetch.sh` names | licence |
|---|---|---|
| `apertium-eng-spa.eng-spa.dix` | apertium/apertium-eng-spa `b29ae922acd04a7542b44e36e3084e76698b5775` | GPL-2 (`COPYING.GPL-2`) |
| `apertium-spa.spa.metadix` | apertium/apertium-spa `a904c4aba3bb13406ebeb85617c9cc665a582986` | GPL-2 (`COPYING.GPL-2`) |
| `convert-metadix-dix.py` | apertium/apertium-spa, the same commit | GPL-2 (`COPYING.GPL-2`) |
| `apertium-spa.spa.dix` | made by `fetch.sh` from `apertium-spa.spa.metadix` with `convert-metadix-dix.py`, numeric character references decoded | GPL-2 (`COPYING.GPL-2`) |
| `apertium-eng-ita.eng-ita.dix` | apertium/apertium-eng-ita `2939c046d00ff4342d43c9f0573433c1434e8641` | GPL-2 (`COPYING.GPL-2`) |
| `apertium-ita.ita.dix` | apertium/apertium-ita `33a81de08fd6ca54f4463b41639e00cec4867325` | GPL-2 (`COPYING.GPL-2`) |
| `en-verbs.txt` | clips/pattern `af754685cca3713db0abc4f020f2e94467c19d85`, `pattern/text/en/en-verbs.txt` | the University of Pennsylvania notice at the head of the file, and pattern's BSD-3-Clause licence (`LICENSE.pattern.txt`) |

`COPYING.GPL-2` is the GNU General Public License, version 2.
`LICENSE.pattern.txt` is pattern's `LICENSE.txt` at the same commit.
