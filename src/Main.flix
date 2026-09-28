///
/// Minimal reproduction: `TreeKind.Predicate.ParamUntyped` is dead by
/// assignment and can appear in no syntax tree from any input.
///
/// There is nothing to observe at runtime. This program compiles, runs and is
/// correct. The defect is in the shape of the tree the parser builds, and in
/// the fact that a later phase still matches on a kind the parser can never
/// produce. See the README for how to confirm it.
///
mod Datalog {

    ///
    /// Solves a small Datalog program abstracted over an untyped predicate.
    ///
    /// `#(A)` is the reproduction: a predicate parameter list whose single
    /// parameter carries no type ascription — precisely the shape
    /// `Predicate.ParamUntyped` names. `Parser2.param()` is what builds it,
    /// and it closes the node as `Predicate.Param` instead.
    ///
    pub def facts(): Vector[Int32] =
        let p1 = #(A) -> #{
            Local("seed").
            A(42) :- Local("seed").
        };
        let p2 = #{
            R(x) :- A(x).
        };
        query p1, p2 select x from R(x)

}

///
/// The entry point.
///
def main(): Unit \ IO =
    println("A = ${Datalog.facts()}")
