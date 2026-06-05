# Implementation Plan: Clade Zoom Root Using Dinosauria

## Goal

Add a small zoom text icon, shown as `+`, to selected vertical clade labels such as **Dinosauria**.

When the user clicks the `+` on the **Dinosauria** label, the Clade column should switch from the normal clade overview to a focused view where **Dinosauria is treated as the root node**.

When Dinosauria is displayed as the active root, its label should show a `-` icon. Clicking the `-` should return the Clade column to the previous/global view.

This plan is only for the first implementation using **Dinosauria** as the example. It does not implement user-added clades, OpenTree lookup, or general nested zooming yet.

## User-Facing Behaviour

### Normal clade view

In the normal/global view, Dinosauria appears as part of the wider clade tree.

```text
Clades
│
├── Vertebrates
├── Tetrapods
├── Amniotes
├── Archosaurs
└── + Dinosauria
```

The `+` means:

```text
Zoom into this clade
```

The clickable target should include both the `+` icon and the Dinosauria label.

### Dinosauria zoom-root view

After clicking `+ Dinosauria`, the Clade column switches to a focused Dinosauria subtree.

```text
Clades: Dinosauria
│
└── - Dinosauria
    ├── Saurischia
    │   ├── Sauropodomorpha
    │   └── Theropoda
    └── Ornithischia
        ├── Thyreophora
        ├── Ornithopoda
        └── Marginocephalia
```

The `-` means:

```text
Return to previous clade view
```

For the first implementation, clicking `- Dinosauria` should return to the normal/global clade view.

## Important Display Principle

This interaction changes only the **root of the Clade column**.

It should not change:

```text
the geological time scale
the time divisions
event markers
extinction markers
palaeoenvironment blocks
landmass blocks
sea blocks
```

Only the Clade column changes its displayed root and visible subtree.

## State Model

Add one piece of UI state for the active clade root.

```dart
String? activeCladeRootId;
```

Meaning:

```text
null          = show the normal/global clade view
"dinosauria"  = show Dinosauria as the root of the Clade column
```

For the first implementation, do not implement a full navigation stack.

Later, this could become:

```dart
List<String> cladeRootStack;
```

which would support:

```text
All clades → Dinosauria → Theropoda → Tyrannosauridae
```

## Data Requirements

The clade data needs a way to identify which clades can become zoom roots.

For the first version, add this only to Dinosauria:

```yaml
- id: dinosauria
  label: Dinosauria
  parent_id: archosauria
  start_ma: 231.0
  end_ma: 0.0
  zoomable: true
```

Descendant clades should use their normal biological `parent_id` values:

```yaml
- id: saurischia
  label: Saurischia
  parent_id: dinosauria

- id: ornithischia
  label: Ornithischia
  parent_id: dinosauria

- id: theropoda
  label: Theropoda
  parent_id: saurischia

- id: sauropodomorpha
  label: Sauropodomorpha
  parent_id: saurischia
```

Do not flatten the scientific `parent_id` structure just to make the display easier. The renderer should handle the zoomed view.

## Recommended First Dinosauria Subtree

Use the traditional simplified dinosaur structure.

```text
Dinosauria
├── Saurischia
│   ├── Sauropodomorpha
│   │   ├── Sauropoda
│   │   ├── Diplodocoidea
│   │   └── Macronaria
│   └── Theropoda
│       ├── Coelophysoidea
│       ├── Ceratosauria
│       ├── Tetanurae
│       └── Coelurosauria
│           ├── Tyrannosauroidea
│           ├── Maniraptora
│           └── Avialae / Aves
└── Ornithischia
    ├── Heterodontosauridae
    ├── Thyreophora
    │   ├── Stegosauria
    │   └── Ankylosauria
    └── Neornithischia
        ├── Ornithopoda
        └── Marginocephalia
            ├── Pachycephalosauria
            └── Ceratopsia
```

This is enough to test the interaction without turning the display into a full dinosaur taxonomy browser.

## Filtering Logic

### Normal/global mode

When `activeCladeRootId == null`, use the current clade-rendering process.

```text
if activeCladeRootId == null:
    rootClades = normal global clade roots
    visibleClades = apply existing display rules
```

Existing rules should continue to apply, such as:

```text
display_priority
min_zoom_level
start_ma
end_ma
visible display groups
screen-space constraints
```

### Dinosauria zoom-root mode

When `activeCladeRootId == "dinosauria"`:

```text
1. Find clade with id == "dinosauria".
2. Collect all descendants of Dinosauria using parent_id links.
3. Treat Dinosauria as the visual root.
4. Apply existing display rules inside that subtree.
5. Render only Dinosauria and its visible descendants.
```

Pseudo-logic:

```text
if activeCladeRootId == "dinosauria":
    root = findClade("dinosauria")
    subtree = collectDescendants(root.id)
    visibleClades = applyExistingDisplayRules([root] + subtree)
```

The output should be a normal tree layout, but scoped to the Dinosauria subtree.

## Collecting Descendants

The data loader or view model should build a parent-to-children index.

```dart
Map<String, List<Clade>> childrenByParentId;
```

Then descendant collection can be recursive.

```dart
List<Clade> collectDescendants(String rootId) {
  final result = <Clade>[];

  void visit(String parentId) {
    final children = childrenByParentId[parentId] ?? [];
    for (final child in children) {
      result.add(child);
      visit(child.id);
    }
  }

  visit(rootId);
  return result;
}
```

For the first version, the tree is small enough that a simple recursive approach is fine.

## Rendering the `+` and `-` Icons

### In normal/global mode

If a clade has:

```yaml
zoomable: true
```

and is not currently the active root, render:

```text
+ Dinosauria
```

Click behaviour:

```dart
setState(() {
  activeCladeRootId = "dinosauria";
});
```

### In Dinosauria zoom-root mode

If the active root is Dinosauria, render the root label as:

```text
- Dinosauria
```

Click behaviour:

```dart
setState(() {
  activeCladeRootId = null;
});
```

This returns to the previous/global view.

## Click Target

The clickable target should include the whole label area, not only the symbol.

Recommended behaviour:

```text
Click + icon       → zoom into Dinosauria
Click Dinosauria   → zoom into Dinosauria
Click - icon       → return to global view
Click Dinosauria   → return to global view, when Dinosauria is the active root
```

This makes the UI forgiving and avoids tiny click targets.

## Visual Treatment

Keep the icon textual for now.

Suggested formats:

```text
+ Dinosauria
- Dinosauria
```

For vertical text:

```text
+
Dinosauria
```

and:

```text
-
Dinosauria
```

Avoid adding complex icons or custom graphics at this stage.

## Header Text

When the active root is Dinosauria, the Clade column should show context.

Recommended first version:

```text
Clades: Dinosauria
```

When in global mode:

```text
Clades
```

## Range Bar Behaviour

Range bars should continue to use existing `start_ma` and `end_ma` values.

Important dinosaur-specific modelling rule:

```text
Dinosauria should continue to 0 Ma if birds are included.
Non-avian dinosaurs should end at 66 Ma.
Aves / Birds should continue to 0 Ma.
```

So the data should eventually distinguish:

```yaml
- id: dinosauria
  label: Dinosauria
  start_ma: 231.0
  end_ma: 0.0

- id: non_avian_dinosaurs
  label: Non-avian dinosaurs
  parent_id: dinosauria
  start_ma: 231.0
  end_ma: 66.0

- id: aves
  label: Birds / Aves
  parent_id: avialae
  start_ma: 150.0
  end_ma: 0.0
```

This prevents the common error of implying that all dinosaurs ended at 66 Ma.

## Suggested Implementation Steps

### Step 1: Add data flag

In `clades.yaml`, add:

```yaml
zoomable: true
```

to the `dinosauria` block only.

### Step 2: Add active-root state

In the relevant clade/timeline widget state, add:

```dart
String? activeCladeRootId;
```

Initial value:

```dart
null
```

### Step 3: Build child index

When clade data is loaded, build:

```dart
childrenByParentId
```

from `parent_id`.

### Step 4: Add descendant collection

Add a helper:

```dart
List<Clade> collectDescendants(String rootId)
```

### Step 5: Scope clades before rendering

Before rendering the Clade column, choose the clade list:

```dart
final cladesForDisplay = activeCladeRootId == null
    ? globalVisibleClades
    : visibleCladesInsideSubtree(activeCladeRootId!);
```

The subtree version should still pass through the existing display rules.

### Step 6: Add `+` click handler

In normal mode, when rendering a zoomable clade:

```text
+ Dinosauria
```

clicking it sets:

```dart
activeCladeRootId = "dinosauria";
```

### Step 7: Add `-` click handler

In zoomed mode, when rendering the active root:

```text
- Dinosauria
```

clicking it sets:

```dart
activeCladeRootId = null;
```

### Step 8: Update column header

Use:

```text
Clades
```

when `activeCladeRootId == null`.

Use:

```text
Clades: Dinosauria
```

when `activeCladeRootId == "dinosauria"`.

### Step 9: Test only Dinosauria

Initial tests should confirm:

```text
Dinosauria shows + in global mode.
Clicking + changes the clade root to Dinosauria.
The Clade column now shows Dinosauria and descendants only.
Dinosauria now shows -.
Clicking - returns to the previous/global view.
The geological timeline does not change.
Range bars still align correctly.
Existing zoom/display rules still apply.
```

## Edge Cases

### Dinosauria has no loaded descendants

Show:

```text
Clades: Dinosauria
- Dinosauria
No descendant clades available.
```

This should not crash.

### Dinosauria is hidden at the current zoom

If Dinosauria is not visible because of current zoom/display rules, the `+` will not be shown. That is acceptable for the first version.

### User zooms the geological timeline while Dinosauria is active

The Dinosauria root should remain active.

The visible descendants may change according to existing `min_zoom_level` and display priority rules.

### User switches display category

If the user hides the Clade column or changes a major mode, either preserve `activeCladeRootId` or reset it.

Recommended first version:

```text
Preserve activeCladeRootId until the user clicks -
```

## Possible Future Generalisation

After Dinosauria works, the same mechanism can apply to other zoomable clades:

```text
Mammalia
Primates
Hominidae
Arthropoda
Angiosperms
Birds / Aves
```

The data flag would remain:

```yaml
zoomable: true
```

The same UI rules would apply:

```text
+ = make this clade the active root
- = return to previous/global view
```

For nested zoom later, replace:

```dart
String? activeCladeRootId;
```

with:

```dart
List<String> activeCladeRootStack;
```

Then the user could navigate:

```text
All clades
→ Dinosauria
→ Theropoda
→ Tyrannosauridae
```

But that should be deferred until the first single-root version works.

## Recommended First Version

Implement only this behaviour:

```text
Global Clades view
  click + Dinosauria
Dinosauria-root Clades view
  click - Dinosauria
Global Clades view
```

Do not yet implement:

```text
nested zoom roots
OpenTree lookup
user-added clades
clade search
automatic dinosaur taxonomy expansion
custom icons
animations
```

The first implementation should prove that the clade column can be scoped to a subtree while reusing the existing layout and display rules.
