# Projects-Library-KG

(Renamed from HardTech-Chronos, #1609. The Library board is the root index.html + topics.md, cloned by Cloud KG Store Me. #1867: this repository is the content of Cloud Wiki, one numbered folder per page, mirroring the app's side menu.)

## Layout (#1867)

| Folder | In Cloud Wiki |
|---|---|
| `1.Modern-science/` | Modern Science: `1.0.Science`, `1.1.Humanities`, `1.2.Arts`, `1.3.Explore` (Graph), each topic a folder, each subpage tab a folder below it |
| `2.Arcanum-science/` | Arcanum Science, after the Esoteric Arcanum master taxonomy: `2.0` A Architecture of Sacred Sciences & Wisdom, `2.1` B Interactions: Magic & Grimoires, `2.2` C Esoteric Schools & Traditions; sections I-V are topics, their leaves are pages |
| `3.Projects/3.0.Chronos/` | Projects > Chronos: the simulators site (`index.html` and its numbered sections) plus the Chronos era pages |
| `3.Projects/3.1.Sacred-geo/` | Projects > Sacred Geometry: `index.html` (3D explorer), `topics.md` (curriculum) |

Every node folder holds an `index.md` with a front matter block (`kind`, `id`, `label` or `title`, `icon`, `tags`) and its Markdown text. `wiki.json` at the root is GENERATED from the tree by `tools/gen-wiki.py` (never edit it); `tools/test-wiki-tree.sh` (CI: `.github/workflows/wiki-tree.yml`) checks that it equals the tree, that the generator is deterministic and that Arcanum follows the taxonomy. Cloud Wiki clones this repository at run time, reads `wiki.json` and serves the two sites from its clone.

Interactive HTML simulators of cycles across scales. Live: https://diegonmarcos.github.io/Projects-Library-KG/

| # | Project | Path |
|---|---|---|
| 0 | Humansphere - Circadian | `3.Projects/3.0.Chronos/0.Humansphere-Circadian/` |
| 1 | Earthsphere - Cycles | `3.Projects/3.0.Chronos/1.Earthsphere-Cycles/` |
| 2 | Milkwaysphere - Orbits | `3.Projects/3.0.Chronos/2.Milkwaysphere-Orbits/` |
| 3.0 | Quantum Decoherence Cycle | `3.Projects/3.0.Chronos/3.Quantum-Cycles/3.0.Quantum-Decoherence-Cycle/` |
| 3.1 | Quantum Gravity Cycle | `3.Projects/3.0.Chronos/3.Quantum-Cycles/3.1.Quantum-Gravity-Cycle/` |
| 4 | Astronomy - Astrological Sphere | `3.Projects/3.0.Chronos/4.Astronomy-Astrological-sphere/` |

Deploy: every push to `main` publishes `3.Projects/3.0.Chronos/` (site root) and `3.Projects/3.1.Sacred-geo/` (`/Sacred-geo/`) to GitHub Pages (`.github/workflows/ship.yml`).

Sibling project: Sacred Geometry in `3.Projects/3.1.Sacred-geo/` (index.html is the 3D explorer, topics.md the curriculum).
