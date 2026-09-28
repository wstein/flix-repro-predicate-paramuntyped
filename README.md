# flix-repro-predicate-paramuntyped

Minimal reproduction: **`TreeKind.Predicate.ParamUntyped` is dead by assignment in
`Parser2.param()` and can appear in no syntax tree from any input**, while `Weeder2` still
pattern-matches on it in two places.

Built from [`wstein/flix-template`](https://github.com/wstein/flix-template), so it carries the
compiler it pins. A clone needs only a JDK. Pinned to Flix **v0.77.0** (`.flixw/lock.toml`,
digest-verified).

```sh
./flixw run          # prints: A = Vector#{42}
./flixw test         # 2 tests, both pass
```

## There is nothing to see at runtime, and that is the point

This project **compiles, runs and is correct**. Unlike most defects there is no crash, no wrong
answer and no diagnostic. The defect is in the shape of the tree the parser builds, so a test suite
cannot express it — the tests here only show that the construct which triggers it is ordinary,
working Flix.

## The defect

`src/Main.flix` contains `#(A)`, a predicate parameter list whose single parameter carries no type
ascription — precisely the shape `Predicate.ParamUntyped` names. `Parser2.param()`:

```scala
private def param()(implicit s: State): Mark.Closed = {
  implicit val sctx: SyntacticContext = SyntacticContext.Expr.Constraint
  var kind: TreeKind = TreeKind.Predicate.ParamUntyped     // 4018
  val mark = open()
  nameUnqualified(NAME_PREDICATE)
  kind = TreeKind.Predicate.Param                          // 4021 — unconditional
  if (at(TokenKind.ParenL)) {
    ...
  }
  close(mark, kind)                                        // 4035
}
```

`kind` is overwritten at 4021 before any branch, so `close(mark, kind)` can only ever receive
`Predicate.Param`. `Predicate.ParamUntyped` is unreachable from every input.

Two arms in `Weeder2` still match on it:

- `Weeder2.scala:2075` — `pickAllMulti(pick(TreeKind.Predicate.ParamList, tree), TreeKind.Predicate.ParamUntyped, TreeKind.Predicate.Param)`
- `Weeder2.scala:2833` — `expectAny(tree, List(TreeKind.Predicate.Param, TreeKind.Predicate.ParamUntyped))`

So the producer and the consumer of this kind disagree about whether it can occur. That is what
makes it a defect rather than a retired kind quietly left in the enum.

(Line numbers are at the v0.77.0 tag, `4a5b60a31ac03bb762f68b554a0fc2b6f4d982b9`.)

## Confirming it

Reading `Parser2.param()` is the whole proof, and `--Xprint-phases` does **not** help: its
`Parser2.flixir` dump does not render `TreeKind` names for these nodes.

To see the tree itself, use [`flix-spec`](https://github.com/wstein/flix-spec), which publishes
projected concrete syntax trees from the same pinned compiler:

```sh
./gradlew -q :tools:project:extract --args="--form raw path/to/Main.flix"
```

For `src/Main.flix` that reports `Predicate.Param: 1`, `Predicate.ParamList: 1` and
`Predicate.ParamUntyped: 0`, with no diagnostics.

## Suggested fix

Either delete `Predicate.ParamUntyped` and the two `Weeder2` arms, or give `param()` the branch the
initialiser implies — set `Predicate.Param` only when a type actually follows. The first is
probably right: nothing downstream distinguishes the two.

## Provenance

Found by [`flix-spec`](https://github.com/wstein/flix-spec) and recorded there as `FLIX-0001` in
`defects/ledger.json`, with a declarative assertion that fails once upstream changes this.
