#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║ test-wiki-tree — the folder tree IS the Cloud Wiki (#1867)        ║
# ╚══════════════════════════════════════════════════════════════════╝
#
#   T1  wiki.json is exactly what tools/gen-wiki.py makes of the tree (no hand edit, no stale file)
#   T2  the generator is deterministic: two runs, and a copy of the tree created in reverse order, give the same bytes
#   T3  the tree equals the menu: every numbered folder with an index.md is in wiki.json once (menu, hubs, topics, pages, projects),
#       nothing in wiki.json lacks its folder, and the three parents are Modern Science | Arcanum Science | Projects, in that order
#   T4  Arcanum Science follows the taxonomy: families A, B, C with sections I-III, I-V, I-III holding 4/4/3, 13/3/7/3/6 and 14/9/13
#       leaf pages; every page has tags and a short Markdown text (80-700 characters)
#   T5  the other consumers keep their paths: the Library board (index.html, topics.md at the root, Cloud KG Store Me) and the
#       Pages assembly (.github/workflows/ship.yml copies folders that exist)
# then plants a mutation per rule in a scratch copy and requires RED for each. Python 3 stdlib and bash only.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
GEN="$HERE/gen-wiki.py"
command -v python3 >/dev/null || { echo "ERROR: python3 is required"; exit 1; }

check() {   # check <repo copy> -> prints FAIL lines, exit 1 on any
  local r="$1" bad=0
  if ! out="$(python3 "$GEN" --root "$r" --check 2>&1)"; then echo "FAIL T1 $out"; bad=1; fi
  a="$(python3 -c 'import importlib.util,sys;s=importlib.util.spec_from_file_location("g",sys.argv[1]);g=importlib.util.module_from_spec(s);s.loader.exec_module(g);print(g.render(sys.argv[2]))' "$GEN" "$r" 2>&1)"
  b="$(python3 -c 'import importlib.util,sys;s=importlib.util.spec_from_file_location("g",sys.argv[1]);g=importlib.util.module_from_spec(s);s.loader.exec_module(g);print(g.render(sys.argv[2]))' "$GEN" "$r" 2>&1)"
  [ "$a" = "$b" ] || { echo "FAIL T2 two runs of the generator differ"; bad=1; }
  python3 - "$r" <<'PY' || bad=1
import json, os, re, sys
r = sys.argv[1]
bad = []
try:
    d = json.load(open(os.path.join(r, "wiki.json"), encoding="utf-8"))
except Exception as e:
    print("FAIL T1 wiki.json does not parse: %s" % e); sys.exit(1)
NODE = re.compile(r"^\d+(?:\.\d+)*\.[A-Za-z]")
folders = set()
for dp, dn, fn in os.walk(r):
    dn[:] = [x for x in dn if not x.startswith(".")]
    rel = os.path.relpath(dp, r).replace(os.sep, "/")
    if rel != "." and "index.md" in fn and all(NODE.match(seg) for seg in rel.split("/")):
        folders.add(rel)
paths = []
def walk(ms):
    for m in ms:
        paths.append(m["path"]); walk(m.get("children", []))
walk(d.get("menu", []))
paths += [p["path"] for t in d.get("topics", []) for p in t.get("pages", [])]
for x in sorted(set(paths) - folders): bad.append("T3 wiki.json names %s, which is not a folder with an index.md" % x)
for x in sorted(folders - set(paths)): bad.append("T3 folder %s is not in wiki.json" % x)
if len(paths) != len(set(paths)): bad.append("T3 a folder is in wiki.json twice")
if [(m["id"], m["label"]) for m in d.get("menu", [])] != [("modern", "Modern Science"), ("arcanum", "Arcanum Science"), ("projects", "Projects")]:
    bad.append("T3 the parents are %s, not Modern Science | Arcanum Science | Projects" % [m["id"] for m in d.get("menu", [])])
hubs = {h["id"]: h for h in d.get("hubs", [])}
topics = {t["id"]: t for t in d.get("topics", [])}
arc = next((m for m in d.get("menu", []) if m["id"] == "arcanum"), {"children": []})
shape = [[len(topics.get(t["id"], {}).get("pages", [])) for t in f.get("children", [])] for f in arc["children"]]
if [f["id"] for f in arc["children"]] != ["arcanum-a", "arcanum-b", "arcanum-c"]: bad.append("T4 Arcanum's families are not A, B, C")
if shape != [[4, 4, 3], [13, 3, 7, 3, 6], [14, 9, 13]]: bad.append("T4 Arcanum's sections hold %s pages, the taxonomy %s" % (shape, [[4, 4, 3], [13, 3, 7, 3, 6], [14, 9, 13]]))
for t in topics.values():
    for p in t["pages"]:
        if not p.get("tags"): bad.append("T4 page %s has no tags" % p["id"])
        if not 80 <= len(p.get("md", "")) <= 700: bad.append("T4 page %s is not a short text (%d characters)" % (p["id"], len(p.get("md", ""))))
for f in ("index.html", "topics.md"):
    if not os.path.isfile(os.path.join(r, f)): bad.append("T5 the Library board's %s is gone from the root (Cloud KG Store Me clones it)" % f)
ship = open(os.path.join(r, ".github/workflows/ship.yml"), encoding="utf-8").read()
for src in re.findall(r"cp -a (\S+)/\. ", ship):
    if not os.path.isdir(os.path.join(r, src)): bad.append("T5 the Pages assembly copies %s, which does not exist" % src)
for b in bad: print("FAIL " + b)
sys.exit(1 if bad else 0)
PY
  return $bad
}

FAILS=0
ok()  { echo "  PASS: $1"; }
bad() { echo "  FAIL: $1"; FAILS=$((FAILS + 1)); }

echo "[wiki-tree] the repo"
out="$(check "$REPO")" && ok "T1-T5 hold on the real tree" || { bad "the real tree is red"; echo "$out"; }

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
copy() { rm -rf "$W/r"; mkdir -p "$W/r"; (cd "$REPO" && git ls-files -co --exclude-standard -z | xargs -0 -I{} cp --parents {} "$W/r/"); }

# T2 again: the same tree created in REVERSE order (another directory order on disk) gives the same bytes
copy; rm -rf "$W/rev"; mkdir -p "$W/rev"
(cd "$W/r" && find . -type f | sort -r | while read -r f; do mkdir -p "$W/rev/$(dirname "$f")"; cp "$f" "$W/rev/$f"; done)
if cmp -s <(python3 "$GEN" --root "$W/r" >/dev/null && cat "$W/r/wiki.json") <(python3 "$GEN" --root "$W/rev" >/dev/null && cat "$W/rev/wiki.json"); then ok "T2 a tree created in reverse order gives the same bytes"
else bad "T2 the output depends on the order the folders were created in"; fi

mutant() {   # mutant <name> <shell edit run in a copy of the repo> <needle expected in the output>
  copy; ( cd "$W/r" && eval "$2" )
  if out="$(check "$W/r" 2>&1)"; then bad "mutant '$1' stayed green"; elif grep -q -- "$3" <<<"$out"; then ok "mutant '$1' is red ($3)"; else bad "mutant '$1' is red for the wrong reason: $out"; fi
}
ALG="1.Modern-science/1.0.Science/1.0.0.Math/1.0.0.0.Algebra"
TAROT="2.Arcanum-science/2.1.Magic-and-grimoires/2.1.0.Divination-systems-and-epistemic-arts/2.1.0.0.Tarot"
ORACLES="2.Arcanum-science/2.1.Magic-and-grimoires/2.1.0.Divination-systems-and-epistemic-arts/2.1.0.3.Oracles"
mutant "wiki.json edited by hand"     "sed -i 's/\"Algebra\"/\"Algebra!\"/' wiki.json"                                 "T1"
mutant "a page loses its index.md"    "rm $ALG/index.md"                                                               "T1"
mutant "a page loses its index.md (tree vs menu)" "rm $ALG/index.md; python3 tools/gen-wiki.py --root . >/dev/null 2>&1; true" "T1"
mutant "a folder is misnumbered"      "git mv -k $ALG 1.Modern-science/1.0.Science/1.0.0.Math/1.0.7.0.Algebra 2>/dev/null || mv $ALG 1.Modern-science/1.0.Science/1.0.0.Math/1.0.7.0.Algebra" "is not numbered as a child"
mutant "two pages share an id"        "sed -i 's/^id: math.calculus/id: math.algebra/' 1.Modern-science/1.0.Science/1.0.0.Math/1.0.0.1.Calculus/index.md" "id math.algebra is used by"
mutant "a link dangles"               "sed -i 's/\\[\\[math.number-theory\\]\\]/[[math.nothing]]/' $ALG/index.md"     "links to unknown page math.nothing"
mutant "a page is filed as a hub"     "sed -i 's/^kind: page/kind: hub/' $ALG/index.md"                              "is a 'hub' inside a topic"
mutant "a page has no tags"           "sed -i 's/^tags: .*/tags: /' $ALG/index.md"                                    "missing \\['tags'\\]"
mutant "an unknown front matter key"  "sed -i 's/^kind: page/kind: page\\ncolour: red/' $ALG/index.md"              "unknown front matter keys"
mutant "front matter is missing"      "sed -i '1d' $ALG/index.md"                                                     "does not start with a front matter"
mutant "a stray folder in a topic"    "mkdir -p 1.Modern-science/1.0.Science/1.0.0.Math/notes && touch 1.Modern-science/1.0.Science/1.0.0.Math/notes/x.md" "has no index.md"
mutant "an Arcanum leaf is dropped"   "rm -r $ORACLES; python3 tools/gen-wiki.py --root . >/dev/null"                   "T4 Arcanum's sections hold"
mutant "a page text grows too long"   "python3 -c \"p='$TAROT/index.md';s=open(p).read();open(p,'w').write(s+'x'*700)\"; python3 tools/gen-wiki.py --root . >/dev/null" "is not a short text"
mutant "a parent is renamed"          "sed -i 's/^label: Modern Science$/label: Science/' 1.Modern-science/index.md; python3 tools/gen-wiki.py --root . >/dev/null" "T3 the parents are"
mutant "the Library board is moved"   "git mv -k index.html 3.Projects/board.html 2>/dev/null || mv index.html 3.Projects/board.html" "T5 the Library board's index.html"
mutant "Pages copies a moved folder"  "sed -i 's#3.Projects/3.0.Chronos/\\. #Chronos/. #' .github/workflows/ship.yml"   "T5 the Pages assembly copies Chronos"

[ "$FAILS" -eq 0 ] && echo "ALL GREEN" || { echo "$FAILS FAILED"; exit 1; }
