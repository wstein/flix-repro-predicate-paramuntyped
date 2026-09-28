///
/// The program is correct, and that is the point: this defect has no runtime
/// symptom and a test suite cannot express it.
///
/// What it costs is stated in the README — a `TreeKind` no input can produce,
/// and two match arms in `Weeder2` no input can reach. These tests only show
/// that the construct which triggers it is ordinary, working Flix.
///
@Test
def testFactsFindsTheSeededFact(): Unit \ Assert =
    Assert.assertEq(expected = true, Vector.memberOf(42, Datalog.facts()))

@Test
def testFactsReturnsExactlyOneFact(): Unit \ Assert =
    Assert.assertEq(expected = 1, Vector.length(Datalog.facts()))
