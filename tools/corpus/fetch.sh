#!/bin/sh
# Fetches the raw dictionaries corpus/build.pl reads into
# corpus/raw/ -- they are not committed; what build.pl
# writes from them is. Every source is pinned to a commit, so a rebuild
# gives the same lines.
#
#   apertium/apertium-eng-spa, apertium-spa, apertium-eng-ita, apertium-ita   GPL-2
#   clips/pattern (en-verbs.txt, the English verb table)                     BSD-3
#
# The Spanish monolingual is a METADIX; Apertium's own converter (in that
# repository) turns it into a dix, and its output spells accented letters
# as numeric character references, which are decoded here.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
RAW="$ROOT/corpus/raw"
mkdir -p "$RAW"
GH=https://raw.githubusercontent.com

# the commits the committed vocabulary files were built from (2026-09-21)
ENG_SPA=b29ae922acd04a7542b44e36e3084e76698b5775
SPA=a904c4aba3bb13406ebeb85617c9cc665a582986
ENG_ITA=2939c046d00ff4342d43c9f0573433c1434e8641
ITA=33a81de08fd6ca54f4463b41639e00cec4867325
PATTERN=af754685cca3713db0abc4f020f2e94467c19d85
get() { echo "  $2"; curl -sS -L -o "$RAW/$2" "$1"; }

get "$GH/apertium/apertium-eng-spa/$ENG_SPA/apertium-eng-spa.eng-spa.dix"  apertium-eng-spa.eng-spa.dix
get "$GH/apertium/apertium-spa/$SPA/apertium-spa.spa.metadix"               apertium-spa.spa.metadix
get "$GH/apertium/apertium-spa/$SPA/convert-metadix-dix.py"                 convert-metadix-dix.py
get "$GH/apertium/apertium-eng-ita/$ENG_ITA/apertium-eng-ita.eng-ita.dix"  apertium-eng-ita.eng-ita.dix
get "$GH/apertium/apertium-ita/$ITA/apertium-ita.ita.dix"                   apertium-ita.ita.dix
get "$GH/clips/pattern/$PATTERN/pattern/text/en/en-verbs.txt"              en-verbs.txt

echo "  apertium-spa.spa.dix (from the metadix)"
python3 "$RAW/convert-metadix-dix.py" "$RAW/apertium-spa.spa.metadix" "$RAW/apertium-spa.spa.dix.refs"
python3 - "$RAW/apertium-spa.spa.dix.refs" "$RAW/apertium-spa.spa.dix" <<'PY'
import re, sys
text = open(sys.argv[1], encoding='utf-8').read()
text = re.sub(r'&#(\d+);', lambda m: chr(int(m.group(1))), text)
open(sys.argv[2], 'w', encoding='utf-8').write(text)
PY
rm -f "$RAW/apertium-spa.spa.dix.refs"
ls -la "$RAW"
