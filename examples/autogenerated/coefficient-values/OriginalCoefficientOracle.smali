.class public final LOriginalCoefficientOracle;
.super Ljava/lang/Object;

# Test-only observer of the retained original jsurf parser and ValueCalculator.
# This class must never be packaged with the candidate application.
.method public static valueBits(Ljava/lang/String;)Ljava/lang/String;
    .registers 8
    invoke-static {p0}, Lde/mfo/jsurf/parser/AlgebraicExpressionParser;->parse(Ljava/lang/String;)Lde/mfo/jsurf/algebra/PolynomialOperation;
    move-result-object v0
    if-nez v0, :parsed
    new-instance v0, Ljava/lang/IllegalStateException;
    const-string v1, "original jsurf parser returned no expression"
    invoke-direct {v0, v1}, Ljava/lang/IllegalStateException;-><init>(Ljava/lang/String;)V
    throw v0

  :parsed
    instance-of v1, v0, Lde/mfo/jsurf/algebra/DoubleOperation;
    if-nez v1, :scalar
    const-string v0, "error: coefficient must be scalar"
    return-object v0

  :scalar
    new-instance v1, Lde/mfo/jsurf/algebra/ValueCalculator;
    invoke-direct {v1}, Lde/mfo/jsurf/algebra/ValueCalculator;-><init>()V
    const/4 v2, 0
  :evaluate_start
    invoke-interface {v0, v1, v2}, Lde/mfo/jsurf/algebra/PolynomialOperation;->accept(Lde/mfo/jsurf/algebra/Visitor;Ljava/lang/Object;)Ljava/lang/Object;
    move-result-object v0
  :evaluate_end
    .catch Ljava/lang/UnsupportedOperationException; {:evaluate_start .. :evaluate_end} :unsupported

    check-cast v0, Ljava/lang/Double;
    invoke-virtual {v0}, Ljava/lang/Double;->doubleValue()D
    move-result-wide v2
    invoke-static {v2, v3}, Ljava/lang/Double;->doubleToLongBits(D)J
    move-result-wide v2
    invoke-static {v2, v3}, Ljava/lang/Long;->toHexString(J)Ljava/lang/String;
    move-result-object v0
    return-object v0

  :unsupported
    move-exception v0
    invoke-virtual {v0}, Ljava/lang/UnsupportedOperationException;->getMessage()Ljava/lang/String;
    move-result-object v1
    if-eqz v1, :rethrow
    const-string v2, "no value has been assigned to parameter '"
    invoke-virtual {v1, v2}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
    move-result v2
    if-eqz v2, :rethrow
    const-string v2, "'"
    invoke-virtual {v1, v2}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
    move-result v2
    if-eqz v2, :rethrow
    const-string v0, "error: "
    invoke-virtual {v0, v1}, Ljava/lang/String;->concat(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    return-object v0

  :rethrow
    throw v0
.end method
