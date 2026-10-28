# The development cycle: tests, examples and inspector views

Doc date: 2026-10-07. Written for the next project, and project-neutral: nothing in it is specific to
the Laser Game. Copy it into the next repository and adapt the package names.

Pharo offers two tools the classic test-driven cycle predates: a class-side **example** marked
`<sampleInstance>`, which the browser offers as one click and which answers an object with an
inspector open on it, and an **inspector view** declared by
`<inspectorPresentationOrder: n title: '…'>`, which gives an object a tab of its own. Both are cheap.
Neither has an agreed place in the red-green-refactor loop, which is why they are usually bolted on
at the end of a project, as a documentation chore, and then rot.

This document gives them a place.

## 1. Three artefacts, three triggers

| Artefact | Answers | Trigger |
|---|---|---|
| Test | "is the behaviour right, and does it stay right" | every behaviour, written before the code |
| Example | "how do I get one of these" | a snippet typed twice; a fixture a second test class wants; a bug reproduction; something you would screenshot |
| Inspector view | "what do I see once I have one" | the same inspector path dug a second time; a red test you could not diagnose quickly |

They are orthogonal. An example never asserts. A view never asserts. A test never opens a window.
The three are kept apart on purpose, and §2 says why.

## 2. Why tests and examples stay separate

Glamorous Toolkit merges them: a `GtExample` is a method that asserts its own invariants and answers
the object, so the example *is* the test. The idea is attractive and the practice is not. The example
assertion vocabulary is far short of the SUnit one, so anything beyond an equality check becomes
awkward to write, and the awkwardness pushes you towards weaker assertions. A test suite should not
be shaped by the needs of documentation.

So: SUnit keeps the whole assertion vocabulary and keeps every behavioural claim. An example is a
builder and nothing else. The only test an example carries is the generic one of §9, which asserts
that it builds — and that test lives in SUnit, with the rest.

## 3. The cycle

The inner loop does not change.

1. **Red.** Write the failing test. If an existing example gives the input, use it.
2. **Green.** Write the smallest method that passes.
3. **Refactor.**

A checkpoint runs **once per feature**, not once per method. Four questions, usually answered "no".

4. **Promotion.** Did a Playground snippet survive this feature? Does a second test class now want
   this fixture? Promote it to an example, per §4.
5. **Diagnosis debt.** Did any red test this feature take more than about a minute to diagnose? That
   is a missing view, not a missing skill. Write it now, while the gap is fresh.
6. **Pairing.** Does every new view have at least one example that opens on it? A view designed
   without an instance to open is designed blind.
7. **Gate.** The generic example test and the generic view test are green.

Order inside the checkpoint is fixed: implementation, then example, then view. The view is laid out
against a real object or not at all.

## 4. Promotion triggers for an example

Promote on one of four signals, and nothing else:

1. **Typed twice.** A Playground snippet you retype. Retyping *is* the signal, so no judgement is
   needed and the rule cannot be argued with.
2. **A second test class wants the fixture.** One test class needing a fixture is what `setUp` is
   for. Two test classes needing it is an example. That boundary is the main brake on growth.
3. **It reproduced a bug.** You built the object state in the debugger already. Keep it, named by
   the state. The regression test is separate, in SUnit, as always.
4. **You would screenshot it.** A UI element, a rendered picture, a parse tree. This is the case the
   `<sampleInstance>` click was made for.

Everything else stays in the Playground and dies there. An example is not a notebook.

## 5. Typical versus degenerate

- **Examples hold typical and interesting states.** The board of the tutorial. A mirror on the beam.
  A panel with three counters showing.
- **Tests hold degenerate states.** The empty collection, the 1x1 grid, the nil target, the value
  that overflows.

Never promote an edge case. This keeps the example package a gallery rather than a dumping ground,
and it keeps the edge cases where a reader looks for them, next to the assertion that names them.

## 6. Rules for an example

1. **Rebuild on every call.** Never cache, never answer a singleton. Tests mutate what they are
   given, and two tests that share one instance share one bug.
2. **Parent plus one action.** A derived example takes another example and performs a single step:
   `demoGrid` then `gridWithTheLaserFiring`. Three steps in one method means either the intermediate
   states deserve names or the snippet was not worth promoting. The chain then reads as a history,
   which is what makes stepping through it in the inspector useful.
3. **Name the state, not the purpose.** `gridWithTheLaserFiring`, never `gridForBeamTests`. A name
   that mentions a test will outlive that test.
4. **Answer the object. Assert nothing.** An example that needs an assertion to be trustworthy is a
   test in the wrong package.
5. **Only an opener opens.** Prefix with `open` every example that puts a window on screen, and
   nothing else. The generic test of §9 then runs the whole package for free. Decide what opens by
   the selectors a method sends, not by searching its source text: one example opens a window by
   asking an element to open on an object, another builds its own space and shows it, and a text
   search for the first spelling silently passes the second.
6. **Take no arguments.** An example is a click. A builder that needs arguments is production API,
   and it belongs with the production code.
7. **No bookmark examples.** An example answers an object it built. A method whose whole body is
   `^ SomeClass`, written so that a class-side view has something pointing at it, is a bookmark, not
   an example: a class is always reachable, since you inspect the class itself. See the exemption in
   §9.

## 7. Triggers and rules for an inspector view

A view is an ordinary method, so the cost is one method and the dependency is nothing.

**Triggers.** Clicked twice: you expanded the same path in the inspector a second time, or
`printOn:` was not enough while you were in the debugger. Or the diagnosis-debt rule of step 5.

**Rules.**

1. **Split data from presentation.**

   ```smalltalk
   inspectionBoardFacts        "data — a plain collection, with real SUnit assertions on it"
   inspectionBoards: aBuilder  "presentation — one test, that it builds without error"
   ```

   This is what makes a view testable without a UI test framework, and it is the single most useful
   rule in this document. The data method is also the method a *test* can assert through, which is
   how a view starts paying for itself twice.
2. **A view never changes what it shows.** Not a lazy initialisation, not a sort in place, not a
   cached derived value. Inspecting an object is an observation.
3. **A view asks the rules, it does not restate them.** A table of what a mirror does with a beam
   calls `exitSideFor:`; it does not hold its own copy of the four mappings. A view that restates a
   rule drifts away from it and then lies.
4. **A question about a hierarchy belongs on the class side.** "What are the four directions" is
   asked of `GridDirection`, not of one direction.
5. **A list the view needs is read off the object, never written into the view.**
6. **Hide a view that has nothing to say,** with the context method
   (`inspectionMovesContext: aContext`), so an empty tab never appears.

**Tiers, and when each is built.**

- **Tier 1, structural** — what the object holds. Build during development; it repays itself the same
  day.
- **Tier 2, derived facts** — counts, relations, validity, the answer to a rule. Build at the feature
  checkpoint, when step 5 asks for it.
- **Tier 3, rendered** — a picture of the object, through the real renderer. Only for objects whose
  whole point is visual.

Cap at two views per class while a feature is in flight. A third is tier 2 work that can wait for the
checkpoint.

## 8. Package layering

```
Core  <--  Examples  <--  Tests
```

- Core never depends on Examples. Tests may depend on Examples; that is what examples are for.
- **A fixture never lives in core.** The most common way this rule is broken is quietly: a shared test
  board is promoted to the domain factory, because the factory is where boards come from and the
  example package does not exist yet. Then a core inspector view lists it, and core depends on a
  fixture. Create the example package at the first promotion instead, however early that is.
- An example may call another example, and may call core. It never names a test class.

## 9. Gating

Generic tests, written once, early, when the example package is created and not retrofitted. Start
with the first two. The other three are what the Laser Game found it wanted once the first two had
been running for a while, and they cost nothing extra, since all five share the same handful of
helpers.

- **Every example answers something worth a click.** Walk the example package for `<sampleInstance>`
  methods, set the openers aside by their prefix, perform each remaining selector on its class, and
  assert that it answers neither nil nor an object the inspector shows no tab of ours for. One
  method, and no example can rot.
- **Every instance-side view is reachable.** Walk the core packages for
  `<inspectorPresentationOrder:title:>` methods and assert that the examples between them reach every
  *instance-side* one. This is what stops a view from surviving the object it described.
  **Exempt the class-side views.** A view on the class side is reached by inspecting the class, which
  needs no example. Demanding one produces bookmark methods (§6 rule 7) and nothing else: the Laser
  Game grew six of them this way, one per class-side view, each with `^ SomeClass` for a body.
- **Every class-side view is shown by inspecting its class.** The counterpart of the exemption above,
  and the reason the exemption is safe: the class-side views are still checked, by the one route that
  reaches them.
- **The example package holds examples and nothing else.** Every method in it carries
  `<sampleInstance>`, so everything in it is a click the browser offers. This is the rule that keeps
  a helper from quietly moving in next to the examples.
- **Only an example named `open…` opens a window.** Reading the selector then tells you what the
  click costs: an opener puts a window on screen, anything else only answers an object. Checked both
  ways, so an opener that opens nothing fails too.

A rule that starts producing code which exists only to satisfy it has the wrong scope, not the code.
That is why the second gate exempts the class side rather than demanding an example per view, and it
is the question to ask of any gate added later.

The Laser Game's `LaserGameExamplesTestCase` is a working implementation of all five, in fourteen
methods: read it before writing another. Beyond the gates, data methods get ordinary assertions and
presentation methods get one smoke test each.

## 10. Garbage collection

Examples and views need a collector or they accumulate.

- An example with no sender and no `<sampleInstance>` is dead. Delete it.
- A view nobody opened during a feature, that says no more than tier 1 already says, is dead. Delete
  it.
- A `Form`, shape or colour view that outlives the thing it drew goes with it.

Both checks are mechanical, so run them at every release rather than discussing them.

## 11. Pharo specifics

```smalltalk
"an example"
GridExample class >> gridWithTheLaserFiring
	"The demo board with the laser lit."
	<sampleInstance>
	| grid |
	grid := GridExample demoGrid.
	grid fireLaser.
	^ grid

"a view, split in two"
Grid >> inspectionBeamFacts
	^ "a plain collection"

Grid >> inspectionBeam: aBuilder
	<inspectorPresentationOrder: 2 title: 'Beam'>
	^ aBuilder newTable …

Grid >> inspectionBeamContext: aContext
	^ aContext active: self laserIsFiring
```

Protocols: examples in `examples`, views in `inspecting`. An example class is named after the class
it builds for, suffixed `Example`, and lives in the example package, never beside the class.

## 12. Checklist

Pin this where the keyboard is.

- Test first, always. Examples and views never replace one.
- Example on four triggers only: typed twice, second test class, bug reproduction, screenshot.
- Example rebuilds per call, derives in one step, names a state, asserts nothing, takes no arguments.
- Typical states are examples. Degenerate states are tests.
- View on two triggers only: clicked twice, or a diagnosis that took too long.
- Every view splits data from presentation. The data method gets real assertions.
- Every instance-side view has an example that opens on it. Class-side views are exempt.
- Core never depends on the example package. No fixture in core.
- The generic gates exist from the day the example package is created: the first two on day one,
  the other three as soon as they are cheap.
- Delete the example with no sender and the view with nothing to add.
