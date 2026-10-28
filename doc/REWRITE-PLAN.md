# Book rewrite plan — from port diary to Pharo tutorial

Plan date: 2026-10-03. Decided with the user in the session of 2026-10-03.

The five Markdown files under `doc/` were written as a *port diary*: each chapter opens with the
pages of the 2007 Squeak tutorial it covers, and the prose repeatedly sets what the original did
beside what the port does. That framing has served its purpose and now gets in the reader's way.
This plan replaces it.

## 1. What this book is

A tutorial that teaches **test-driven development on a small game**, for a reader who is new to
Pharo and may be new to programming. Three threads run through it:

1. **Write the test first.** Every behaviour arrives as a failing test, then as the code that passes it.
2. **Name the pattern.** When the code uses polymorphism instead of a case statement, double
   dispatch, lazy initialization, a test fixture, a factory, or a null object, the text says so and
   explains why that shape was chosen.
3. **Hunt the bug you just introduced.** The debugger, `haltOnce`, reading a failing assertion,
   and the discipline of a test that survives a change of constant.

Bloc is the graphics toolkit, taught directly as the way to build a GUI in Pharo.

## 2. What this book is not

The Pharo community already has books for these, and this one links to them instead of repeating
them:

- installing Pharo, setting up an image, preferences, saving an image;
- Git and Iceberg — point at *Managing Your Code with Iceberg*, `http://books.pharo.org`;
- Monticello, SmalltalkHub, `ConfigurationOf`, Versionner — gone from the ecosystem, not replaced
  in this book by an equivalent chapter;
- Metacello baselines as a subject — one short chapter states the game's baseline and moves on;
- packaging and deployment — Section 6 stays cancelled; the empty `doc/section6/` was deleted on
  2026-10-04.

## 3. The two mentions of history

The book acknowledges where it comes from exactly twice, and never again.

1. **In the introduction**, one short paragraph: the Laser Game was written by Stephan Wessels in
   2007 and was a hit in the Squeak community, from which Pharo descends; this book follows his
   teaching sequence in modern Pharo. Carry the CC BY-SA 3.0 licence and the attribution from
   `SectionOne/1-Introduction.pier` here, with the `MyClass >> myMethod` code convention.
2. **At the head of the graphics chapters**, one sentence: Pharo's older graphics framework is
   Morphic, this book uses Bloc, and no knowledge of Morphic is assumed or needed.

Outside those two places the words *Squeak*, *Morphic*, *the original*, *the port*, *2007* and any
reference to a page number do not appear.

## 4. Edit rules

### 4.1 Delete outright

| What | Count | Note |
|---|---|---|
| Chapter openers `*Pages 074 to 077 of the 2007 tutorial.*` | 38 | section2 7, section3 16, section4 6, section5 9 |
| `<!-- http://squeak.preeminent.org/... -->` comments | 167 | section1 28, section2 16, section3 57, section4 19, section5 33 |
| Code fences holding 2007 Squeak source quoted for comparison | 53 | section2 1, section3 18, section4 23, section5 11. Located by: a fence whose code, with Smalltalk comments stripped, names `addMorph`, `SketchMorph`, `LedMorph`, `StringMorph`, `RectangleMorph`, `PluggableButton`, `forMorph`, `allMorphs`, `BitBlt`, `floodFill`, `displayOn:`, `World`, `Cursor`, `Form` or `Display`. Re-run that scan rather than trusting a line number, which every edit moves |
| The prose that introduces each of those fences | — | usually one sentence of the form "The original wrote…" |

### 4.2 Rewrite sentence by sentence

Roughly 5100 lines of prose, after the deletions above. The recurring shapes and what each becomes:

| Pattern now | Becomes |
|---|---|
| "Page 093 warns that…" | the warning itself, stated as fact |
| "The original drew its arrow onto the board form; the port makes an element" | what the code does, in Bloc terms only |
| "This is the method as this chapter writes it; Section 4.3 gives it the comment that…" | nothing, or a forward reference by chapter title, never by section number |
| "None of this is new here. The port wrote it in Section 3.10, because page 114 had already…" | a plain cross-reference to the chapter by name |
| "The 2007 text works with a 30 by 30 cell, so the numbers in the screenshots do not match" | delete; the book has one cell size and no screenshots of another |
| "An addition of the port, after page 204." | delete the line; the chapter stands on its own |

### 4.3 Raise the reading level

The reader may be new to programming, so on first use explain: message send and receiver, class
and instance, `self` and `super`, the class side, a protocol, `^` as answer, cascades and
`yourself`, a test fixture and `setUp`, `assert:equals:`, and each design pattern as it appears.
Prefer adding a short paragraph over assuming. Do not shorten an explanation that already works.

### 4.4 Code blocks still quote the image verbatim

Unchanged rule from `PROJECT_MAP.md` §6. A block shows the method that is in the image, character
for character. So cleaning a method comment is a **code change**, made in the image, and the block
is requoted afterwards — never edited in the Markdown alone.

## 5. The method comments in the image

About 114 references to the original survive inside method and class comments in
`src/Laser-Game/`, which is why 21 code fences still mention Squeak after the Squeak source blocks
are deleted. The user's decision: clean them too, so that a comment explains the code on its own
terms. Highest counts:

| Class | Hits |
|---|---|
| `LaserGameElement` | 21 |
| `LaserGameControlPanelElement` | 18 |
| `LaserGameShapes` | 13 |
| `LaserGameCellElement` | 11 |
| `LaserGameColors` | 8 |
| `CellRenderer` | 8 |
| `LaserGameBoardElement` | 6 |
| `Grid`, `Cell`, `MirrorCellRenderer`, `LaserGameLedElement`, `GridFactory`, and 10 more | 1–5 each |

Rewrite rule for a comment: keep every fact, drop the attribution. `"Answer the width, in pixels,
of the control panel beside the board. The original's number."` becomes `"Answer the width, in
pixels, of the control panel beside the board."` Where the only content was the comparison, the
comment is replaced by one that says what the method answers.

This is a code change and follows the project's rules: compiled in the image through the `pharo`
MCP server, `run_tests` on `Laser-Game-Tests` green, `run_critics` on what changed, then the user
reviews and commits. No behaviour changes and no test should move.

## 6. Chapter disposition

`doc/section1..5/section<n>.md` keep their paths and their chapter order, which is the teaching
order. What changes is that no file or chapter is described by the tutorial section it came from.

### section1 — the model, by test

| Chapter | Fate |
|---|---|
| Introduction | **rewrite.** Delete the five subsections *Backup installation files*, *Image Update*, *Setup*, *A New Project*, *Name the Main Project*. Add the history paragraph of §3, the attribution and licence, the code convention, and the Metacello snippet that loads the finished game |
| Game Overview | **rewrite** for Pharo. Keep the four diagrams of `SectionOne/figures/` (`2-Concept-MirrorRotation.png`, `2-LongerPath{1,2,3}-*.png`), which are clearer than the 2007 screenshots |
| Discovery of Objects | keep; beginner pass |
| Test Driven Development | keep; core chapter |
| Getting Our First Test To Pass | keep; core chapter |
| Saving Your Work | **shrink** to a few lines: commit when the tests are green, and a link to the Iceberg booklet |
| Coding in the Debugger | keep; core chapter |
| Improving Our Model | keep |
| Enhancing MirrorCell | keep |
| Enhancing TargetCell | keep |
| Grid | keep |
| The Path The Beam Takes | **written** in phase 3. `LaserPathElement`, `Grid >> startingCell`, `calculatePath`, `activateCellsInPath` |
| Chasing The Beam | **written** in phase 3. The four bugs of the beam path, and the tool each symptom calls for |

### section2 — the game appears on screen

| Chapter | Fate |
|---|---|
| Game Graphics | keep; carries the one Morphic sentence of §3 |
| Rendering The Cells | keep |
| The Game Board | keep |
| Drawing The Mirror | keep |
| Management of Colors | keep |
| Drawing The Target | keep |
| Progress So Far | **delete.** Its subject is Squeak system categories against Pharo package tags |
| Back to the LaserGame Morph | keep, **retitle** — nothing in it is a Morph. *Assembling the game window* |
| Adding Controls | keep |
| A Unit Test To Demonstrate A Bug | keep; core chapter |

### section3 — interaction

All sixteen chapters keep their place and their titles, except:

| Chapter | Fate |
|---|---|
| Creating Custom Shapes | keep; drop the note that the original chapter was called *Creating Custom Forms* |
| Using "Halt Once" | keep; core chapter. Rewrite the provenance of `haltOnce` as a plain description of what it does |
| Source Management With Monticello | **delete.** Monticello and the 2007 class inventory |

### section4 — feedback and the laser beam

All twelve chapters keep their place. *A window the player can resize* and *Counters The Player
Can Read* lose the line that marks them as additions of the port and become ordinary chapters.

### section5 — polish, and the bugs polish finds

| Chapter | Fate |
|---|---|
| A Missed Bug | keep; core chapter |
| Adding More Game Stats | keep |
| Undo | keep |
| Modify Package Definition | **shrink to one short chapter**: here is `BaselineOfLaserGame`, here is why the tests depend on the model, here is where to read more. Not a packaging guide |
| Reset (and a bug fix) | keep |
| Showing Laser Home Visually | keep |
| A Less Brittle Unit Test Design | keep; core chapter |
| Better Hint Arrows Alignment | keep |
| Minor Cosmetic Tweaks | keep |
| The 2007 Code Leaves The Package | **delete.** Bookkeeping of the port, no teaching content |
| Counters Of One Width | keep as an ordinary chapter |
| Buttons Of One Width | keep as an ordinary chapter |

Net: 55 chapters become 50.

## 7. Order of work

**Phase 0 — the image comments. Done.** The ~114 comments of §5 rewritten class by class, tests
green and critics clean after each class. The `Laser-Game` and `Laser-Game-Tests` packages are
dirty in the user's image and need their own Iceberg commit; no commit here carries code.

**Phase 1 — mechanical strip, one file per pass. Done.** Delete the 38 openers, the 167 HTML comments,
the 53 Squeak source fences with their introducing sentences, and the five chapters marked
**delete**. Retitle *Back to the LaserGame Morph*. Requote the 21 code fences whose comments
changed in phase 0. Verifiable by grep, so it is done first and reviewed quickly.

**Phase 2 — prose rewrite, one chapter per pass. Done.** §4.2 and §4.3 together: a chapter is read whole,
rewritten, and left with no reference to the original and no unexplained vocabulary. Chapter order,
section1 first, so the reader's path is rebuilt from the start. This is the bulk of the work.

**Phase 3 — the missing beam path. Done.** Written new under this plan rather than adapted line by
line, as two chapters, *The path the beam takes* and *Chasing the beam*. Two deviations from the
disposition above, both deliberate:

- They are the **last two chapters of section1**, not the front of section2. The beam path is model
  work and every method in it is tested before anything is drawn; section2 opens with the game
  appearing on screen, and the beam path belongs on the near side of that line.
- There is **no textual representation of the grid**, because the image has none: `Grid` has no
  `printOn:` and no cell answers a `stringRepresentation`. What the finished game has instead is
  `Cell >> printOn:` and the three inspector tabs `inspectionBoard:`, `inspectionCells:` and
  `inspectionBeam:`, all of which are already written up in *Rotate a mirror cell* in section3. The
  end of the *Grid* chapter now points the reader there, where the old text promised a text drawing
  of the board.

The debugging session is the second chapter: a beam that never ends (the forgotten side inversion,
found with the interrupt key), a cell with a `nil` `gridLocation` (found through the senders of the
setter), `self assert: pe cell gridLocation = 2 @ 5` erroring with `False >> #@` (binary precedence),
and the two missing `ifTrue: [ ^ nil ]` guards. Code quoted from the image as always; the first
version of `nextElementIn:` is shown in a plain fence, since the image version is the one *Push A
Cell* arrives at.

**Phase 4 — introduction and overview. Done.** The two chapters of section1 that are still 2007 Squeak
environment text. Last, because the introduction is easiest to write once the rest reads the way it
should.

**Phase 5 — verification. Done.** The five checks of §8, run over the whole book:

1. The legacy grep returns the two sanctioned places and nothing else: the paragraph in
   *Introduction* and the copyright line in *License* (section1), and the one Morphic reminder at
   the head of *Game graphics* (section2). Every other hit is an ordinary English word — "world",
   "display", "cursor" — or the Pharo *World menu*.
2. No fence names a legacy class. Checked with a script that walks each file fence by fence and
   greps the eight names inside fences only.
3. Fence identity, 690 blocks over the five files: section1 60, section2 106, section3 227,
   section4 159, section5 138. Since the *Looking at objects* chapter of 2026-10-04 the gate reads
   734, section5 182. All match the image, apart from the `MyClass >> myMethod`
   placeholder, which resolves to no class on purpose. Five mismatches were found and repaired in
   section3 and one in section4:
   - four fences carried a trailing whitespace-only line that the image does not have
     (`Grid >> canPushCell:fromLocation:`, `CellClickRegionPushNorth class >> containsPoint:`,
     `MirrorCell >> leanLeft`, `MirrorCell >> leanRight`);
   - `Grid >> stackAction:forCell:` was quoted without the method comment it gained in phase 0;
   - section4's `testAGameTakesTheSizeOfWhateverBoardItIsGiven` is the version before the panel
     could stand taller than the board, so it is now an ```` ```st ```` fence with a `> **Note.**`
     pointing at *Adding more game stats*, which holds the version in the image.

   A later pass tagged the 212 fences that carried no language at all, which is where three of those
   five per-file counts grew: 115 of them are method quotes the gate had never seen, and one of the
   115, `CellClickRegionInside class >> pushRegionForPoint:`, turned out to be the image version and
   is now gated. The other 114 are earlier versions and are tagged `st`.
4. `Laser-Game-Tests`: 280 tests, all green, and 301 since the eighteen inspector-view tests of 2026-10-04. `run_critics` on `Laser-Game`: 37 critiques, down from
   the 44 of `PROJECT_MAP.md` §8 — the remainder are the four `GridDirection` subclasses and the
   seven `ReverseLaserGameAction` subclasses, each wanting a class comment, their class-side methods
   wanting a protocol, and `subclassResponsibility` stubs the book deliberately does not write.
5. Every chapter names what it teaches, and since 2026-10-03 in one voice: a blockquote whose bold
   heading *is* the lesson, followed by the explanation. The 23 `> **Lesson.**` blocks of section1
   and section5 lost the generic word and took the lesson as their heading; the 21 lessons that
   sections 2, 3 and 4 wrote as a bold sentence inside a prose paragraph became blockquotes of the
   same shape. Three devices were deliberately left alone, because they are lists and not callouts:
   a run of bold-led paragraphs introduced by a sentence that counts them ("Three things in it are
   worth a paragraph each"), the numbered habit summaries at the end of a chapter, and bold used
   mid-sentence for emphasis.

Phases 1 and 2 can run file by file; phase 0 must land before any block is requoted.

## 8. Done when

1. `grep -niE 'squeak|morphic|the original|the port|2007|page [0-9]{3}' doc/section*/section*.md`
   returns only the two sanctioned places of §3.
2. No code fence names `Morph`, `Form`, `BitBlt`, `Display`, `World`, `Cursor`, `SketchMorph` or
   `floodFill`, in code or in comment.
3. Every code fence carries a language tag, and the tag says what the fence is:

   - ```` ```smalltalk ```` — code that is live in the image. A fence whose first line is a
     `Class >> selector` head is gated against the image; a fence without such a head is a class
     definition, a playground expression or a fragment, and is only read.
   - ```` ```st ```` — a method or fragment the book shows on the way to the final one: an early
     version, a stub, a deliberately wrong line. Not gated, because it is meant to differ.
   - ```` ```text ```` — not code: a class comment, printed output, an error message, a test-runner
     summary, an ASCII board or a measurement table.

   Every method block tagged `smalltalk` matches the image character for character. The gate is in
   two halves: `scratchpad/.../gate.py` reads the ```` ```smalltalk ```` fences of a Markdown file
   and prints `Class|selector|checksum|length` for each one that carries a `Class >> selector` head
   (`Class^` for the class side), and the same checksum is computed in the image over
   `sourceCode trimRight` and compared. The one row that resolves to no class is
   `MyClass >> myMethod`, the placeholder *Conventions used in this book* uses to teach the notation.
4. `run_tests` on `Laser-Game-Tests` is green and `run_critics` is no worse than the 44 known
   critiques of `PROJECT_MAP.md` §8.
5. Every chapter that introduces a pattern names it, in one voice: `> **The lesson as a sentence.**`
   followed by the explanation, in a blockquote of its own. `> **Note.**` stays what it is — an
   aside about the code in front of the reader, not a lesson.
6. Chapter titles are in sentence case, with no terminating period, and an italic cross-reference to
   a chapter spells the title exactly as the heading does. Three-item lists take the Oxford comma.
   Spelling stays British, deliberately: see `doc/STYLE-PLAN.md` §6, where the choice is recorded.
   The one exception the gate forces is a quoted method comment: `LaserGameBoardElement >>
   clickedCell` cites *Determine Push Regions* in the old capitalisation, because the comment lives
   in the image and no commit of mine changes code.

## 9. Consequences for other files

- `PROJECT_MAP.md` §6 *Book files* and §9 need updating: the state table, and the rule that a
  chapter is written "by adapting the matching Pillar chapter" — chapters are now written to this
  plan, and the Pillar text is one source among the HTML pages and the image.
- The Pillar book stays frozen and unedited: `SectionOne/*.pier`, `SectionTwo/*.pier`,
  `pillar.conf`, the templates, `compile.sh`.
- `doc/section2/section2.md`'s head comment, which said the beam-path pages were missing, is gone.
- Images: only `doc/section1/figures/` exists, holding the 2007 screenshots `020.jpg`–`031.jpg`.
  Sections 2–5 reference no figure at all. Screenshots of the Bloc game are the user's to take.
