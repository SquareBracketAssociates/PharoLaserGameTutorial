# Bringing this book closer to the Pharo house style

## 1. What was compared

Three books published by Square Bracket Associates, the Pharo community's publisher, cloned and read
in full:

- `NewPharoByExample9` — the introductory book. Ships a `STYLEGUIDE.md`, which is the only written
  statement of house style any of the three carries.
- `LearningOOPWithPharo` — a book of worked exercises, closest in shape to this one: a small program
  grown chapter by chapter, with tests.
- `BuildingApplicationWithSpec2` — a framework book, closest in subject to the graphics chapters.

All three are written in Microdown and compiled by Pillar into PDF and HTML. This book is plain
GitHub-flavoured Markdown read on GitHub, so some of their conventions are tool conventions rather
than style, and those are listed separately in §4.

## 2. What they do, measured

Counts are per thousand words of prose, with code fences removed, so that books of different lengths
can be compared.

| | this book | NewPharoByExample9 | LearningOOPWithPharo | Spec2 |
|---|---|---|---|---|
| words of prose | 86,365 | 64,537 | 77,167 | 36,223 |
| "we" | **1.8** | 9.7 | 22.7 | 23.9 |
| "you" | **3.5** | 13.7 | 8.4 | 7.2 |
| "let us" / "let's" | **0.4** | 1.2 | 2.2 | 2.6 |
| words per sentence, mean | **18.6** | 16.6 | 15.7 | 14.1 |
| words per paragraph, median | **40** | 33 | 28 | 27 |
| British spellings | **206** | 27 | 0 | 1 |
| American spellings | **41** | 199 | 261 | 123 |

And in structure:

- **The reader is addressed and carried along.** "In this chapter you will build a small mathematical
  expression interpreter." "Let us start by defining a test case class as follows." "When you compile
  such a test method, the system should prompt you to define the class `EConstant`." The writer is
  beside the reader at the keyboard. This is the single largest difference from this book, and the
  numbers above are only its shadow.
- **Chapters open by saying what the reader will build and what it revisits**, in two or three
  sentences, before the first heading.
- **Chapters close with a named section.** `### Conclusion` appears 36 times across the three books,
  `### Chapter summary` 7 times. The summary is a bullet list of the rules the chapter established.
- **Rules are called out.** Microdown's `!!important` admonition, 47 times in `NewPharoByExample9`,
  `!!note` 10 times. One sentence each, stating a rule the reader should carry away.
- **Playground snippets carry their result in the block**, as a `>>>` line:

  ```
  3 + 4
  >>> 7
  ```

  `NewPharoByExample9` has 126 blocks marked `testcase=true` and 22 marked `example=true`, all of
  this shape. The marker is what lets the book's own test suite evaluate the snippet and check the
  answer.
- **Exercises are headings.** `#### Exercise: defining class LNPacket`, with `... Your code ...` left
  in the method body for the reader to fill in.
- **Titles are sentence case**, with no terminating period, and spelling is American English with the
  Oxford comma. These three are the whole of `STYLEGUIDE.md` that concerns prose.
- **Prose is one sentence per line.** Their mean line is 55 to 60 characters, which is not a wrap
  width — it is a line break after every sentence, so that a diff of a paragraph shows the sentence
  that changed.

## 3. Where this book differs, and whether it matters

| Difference | Worth changing | Why |
|---|---|---|
| Impersonal voice; the reader is rarely addressed | **Yes** | The book teaches TDD and bug-chasing, which are things the reader does, not things that happen. Their voice is better suited to this book's purpose than this book's own voice is. |
| British spelling, 211 occurrences in prose and 80 inside gated `smalltalk` fences | **Yes, with one decision to take** | `STYLEGUIDE.md` requires en_US, and the book is already inconsistent with itself: chapter titles read *Communicate with arrow colours* and *Add a counter and window colours* while the prose under them says "colour". See §6. |
| 54 of the 61 chapter titles capitalise a word that sentence case would not | **Yes** | Sentence case is the one hard rule in `STYLEGUIDE.md`. Costs 153 italic cross-references as well as the titles. |
| Oxford comma present in 27 lists, absent in roughly 60 | **Yes** | Required by `STYLEGUIDE.md`, cheap to fix. |
| Paragraphs run 40 words to their 27–33; sentences 18.6 to their 14–16.6 | **Partly** | Not a rule, and the density is sometimes the point. Worth splitting the paragraphs that run past about 60 words, which are the ones that carry two ideas. |
| No chapter openers | **Yes** | Two or three sentences per chapter, 61 chapters. The one place where this book asks the reader to hold the most in their head is the start of a chapter. |
| 43 of 61 chapters close with `## Checking it`, only 2 with a summary | **Partly** | `Checking it` is better than a summary — it asks the reader to run the thing. Keep it. Add a bullet summary only to the chapters that establish more than two rules. |
| Playground snippets have no result in the block; printed results sit in a separate ` ```text ` fence | **Yes** | 71 playground fences, none carrying a result; 29 `text` fences, most of them holding the result of a snippet printed a few lines above. Merging them with `>>>` puts question and answer in one place, and would let a future script evaluate them. |
| No exercises | **No** | This book's reader types the same code the book does, verified by the fence gate. An exercise with a hidden answer would break that contract. |
| 10 figures to their dozens | **No** | The user adds screenshots; the subject is code and tests, not a tour of the IDE. |

## 4. Their conventions that are tooling, not style, and are not adopted

- **Microdown admonitions** (`!!important`, `!!note`). This book's `> **The lesson as a sentence.**`
  and `> **Note.**` blockquotes are the same device in GitHub-flavoured Markdown, and they render on
  GitHub, which `!!important` does not. The mapping is one for one if the book ever moves into the
  Pillar toolchain.
- **Microdown fence attributes** (`language=smalltalk`, `testcase=true`, `example=true`,
  `caption=`, `anchor=`). This book tags fences ` ```smalltalk `, ` ```st ` and ` ```text `, which is
  what the fence gate of `REWRITE-PLAN.md` §8 reads. Keep it.
- **`*@label@*` cross-references and `@anchor` lines.** Pillar resolves these into numbered
  references. GitHub does not, which is why this book names chapters in italics instead. A real
  Markdown link to the heading would be an improvement, but it is a separate job from tone.
- **Chapter as `##` with the file holding one chapter.** An artefact of Pillar collecting chapters
  into a book. This book holds a whole tutorial section per file, with chapters as `#`.
- **One sentence per line.** Better for diffs, invisible to the reader, and an 86,000-word reflow.
  Worth doing one day, in a commit of its own, and only when nothing else is in flight. Listed as
  phase 6 for that reason.

## 5. Phases

Each phase is one commit of `doc/` only, verified before it is committed. No phase may change a
character inside a ` ```smalltalk ` fence: after every phase, re-run the fence gate of
`REWRITE-PLAN.md` §8 and confirm 690 blocks, all matching.

**Phase 1 — the mechanical rules. Done on 2026-10-03.** Sentence-case the 54 chapter headings that need it, and update
the 153 italic cross-references to match. Add the Oxford comma to the three-item lists that lack it;
a loose pattern finds 27 lists that have it and about 66 candidates that do not, and each candidate
needs an eye, because the pattern also catches two clauses joined by "and". No heading gains or loses
a word; this is capitalisation only, so that the diff can be read.

*Verified by:* every `#` heading matches `^# [A-Z][a-z]` with no later capitalised word that is not a
class name or a proper noun; every italic cross-reference resolves to a heading that exists, checked
by a script that extracts both sets and compares them.

*What landed:* 55 chapter headings lowercased — the six left alone are *Introduction*, *Enhancing
MirrorCell*, *Enhancing TargetCell*, *Grid*, *Undo* and *Reset*, which are a single word or a class
name — and 177 cross-references rewritten with them, 152 in the book and 25 in `REWRITE-PLAN.md`,
`STYLE-PLAN.md` and `PROJECT_MAP.md`. 54 Oxford commas added, chosen by reading every candidate the
pattern found: a list of three or more parallel items gets one, a pair of clauses joined by "and"
does not, and the CC BY-SA wording quoted in the introduction is left verbatim. 26 paragraphs were
rewrapped where the added comma pushed a line past 100 columns. The chapter tables of
`REWRITE-PLAN.md` §7 and the page lists of `PROJECT_MAP.md` §6 keep their Title Case, because they
name the pages of the 2007 original, not our chapters. The gate is unchanged at 690 blocks: one
quoted method comment cites a chapter title, and it is left as the image has it.

**Phase 2 — the chapter openers. Done on 2026-10-03.** Two or three sentences at the head of each of
the 61 chapters, before the first `##`: what the reader will build, and what it revisits. Written in
the voice phase 3 establishes, so phase 3's rules are decided first even though the openers land
first.

*What landed:* every chapter already opened with prose, so this was an enrichment rather than an
insertion. Each opener was composed against an inventory of its own chapter — the `##` subheadings
and the `Class >> selector` heads of its fences — so that the sentences name deliverables that really
arrive. Section 1's 13 openers were rewritten outright, because the introductory chapters had been
the terse ones; sections 2 to 5 kept their opening sentences and gained one that says what the
chapter builds. 61 chapters, 61 openers.

*Verified by:* every `#` heading is followed by prose, not by a heading or a fence.

**Phase 3 — the voice. Done on 2026-10-03.** The large one. Go chapter by chapter and rewrite the prose that describes
what happens into prose that addresses the reader: "The test is written first" becomes "We write the
test first"; "Running the package gives green" becomes "Run the package: it is green." Target the
range the three books occupy, roughly 8 to 20 occurrences of "we" per thousand words and 7 to 14 of
"you", without inventing enthusiasm the book does not have. The aphoristic register of the lesson
callouts stays impersonal, because a rule is a rule whoever is reading it.

*Verified by:* the word counts of §2 recomputed per file, and a read of each chapter. This phase is
best split one section file per commit, because it is the only phase where a bad edit is invisible to
a script.

**Phase 4 — paragraphs that carry two ideas. Done on 2026-10-03.** Split the paragraphs over about 60 words where the
split falls naturally. Not a reflow of everything: the target is the median, 40 words down towards
their 30, by breaking the long ones rather than by shortening every sentence.

*Verified by:* the paragraph histogram of §2 recomputed; no paragraph over 90 words survives without
a reason.

**Phase 5 — `>>>` results in playground fences. Done on 2026-10-03.** Merge each printed result into the fence of the
snippet that produced it, as a `>>>` line, and delete the ` ```text ` fence that held it. The 29
`text` fences divide into results of a snippet, which move, and class comments, error reports,
test-runner output and ASCII tables, which stay as they are. A `>>>` line inside a fence with no
`Class >> selector` head is invisible to the gate, so the gate is unaffected — but confirm it.

*Verified by:* no ` ```text ` fence remains whose content is the printed result of the fence above it;
gate still 690.

**Phase 6 — one sentence per line, optional, last. Done on 2026-10-03.** A reflow of all five section files, nothing else
in the commit. Only worth doing if the book is going to keep being edited.

*Verified by:* no prose line holds two sentence endings; the rendered text is identical, checked by
normalising whitespace on both sides of the commit and diffing.

## 6. The decision this plan needs

**Decided on 2026-10-03: option 4, the book stays British.** The deviation from `STYLEGUIDE.md` is
deliberate and is recorded in `PROJECT_MAP.md` §8, so that the next reader does not take it for a
slip. Words that echo a selector keep the selector's spelling, which is why the chapter *Add move
counter and randomizer* is still a randomizer: the code it describes is `randomizeGrid:`. The two
chapter titles that said *Colors* now say *colours*, matching the prose under them. Nothing in the
image changed. The rest of this section is kept as the record of what was weighed.

American spelling cannot be done in the Markdown alone. Of the 327 British spellings in the book,
211 are in prose, 36 sit in ungated ` ```st ` and ` ```text ` fences, and **80 are inside gated
` ```smalltalk ` fences**, because they are in method comments and method names in the image. The
words, most to least: `colour` 90, `centre` 68, `centred` 48, `colours` 27, `labelled` 18,
`behaviour` 14, `grey` 14, then a tail of `centres`, `neighbour`, `centring` and others. The gated
fences are compared character for character against the image, so four choices exist and only the
user can pick:

1. **Prose and image together.** This is larger than it looks, because the 80 are not all comments.
   Counting them: comments and prose inside methods are a recompile; temporary variable names such as
   `centre` in `testABeamIsAPaleBandWithABrightCentreOnIt` are a recompile; a string literal such as
   `'Arrow colours'` is a recompile. But test selectors are renames —
   `testACrossHairIsTwoBarsCrossingAtTheCentre`,
   `testPushingAMirrorAgainstANonBlankNeighbourDoesNothing`,
   `testAPushArrowIsColouredByWhetherThePushIsAllowed` and others — and one production selector is a
   rename with senders, `LaserGameCounterElement class >> labelled:digits:`. A rename is a code
   change, not a cosmetic one, and it moves `src/`, which no commit of mine touches. So this option
   needs the user to do the renames, or to say explicitly that I should.
2. **Image comments only, selectors left British.** Recompile the comments, the temporaries and the
   literal; leave `labelled:digits:` and the test selectors as they are. The page then says "color"
   in prose and in comments, and `Coloured` in two test names, which reads as a deliberate name
   rather than a slip.
3. **Prose only.** The book's own sentences say "color" while the method comments it quotes on the
   same page say "colour". Cheap, and visibly wrong on about twenty pages.
4. **Leave it British.** A deliberate deviation from `STYLEGUIDE.md`, defensible on the grounds that
   this book is not published by Square Bracket Associates. It would be worth saying so in one line
   in `PROJECT_MAP.md`, so that the next person does not take it for an oversight. The chapter titles
   that already say *Colors* would be changed to *Colours* for consistency.

Phase 1 can run under any of the four. Phases 2 to 5 are unaffected.

## 7. What this plan does not touch

The code, the fence gate, the three-tag fence convention, the `> **Note.**` and lesson blockquotes,
the `## Checking it` sections, and the Morphic reminder sentences sanctioned by `REWRITE-PLAN.md` §3.
Tone is prose; none of it is a reason to touch `src/`.
