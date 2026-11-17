.class public final Lde/mfo/jsurf/algebra/OriginalExpansionOracle;
.super Ljava/lang/Object;

# Test-only observation. The original renderer owns preparation, and its
# unchanged Expand visitor owns all polynomial operations and collection.
# Package membership permits read-only access to the original term fields.
.method private static terms(Lde/mfo/jsurf/algebra/XYZPolynomial;)Ljava/lang/String;
    .registers 10
    new-instance v0, Ljava/lang/StringBuilder;
    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V
    invoke-virtual {p0}, Lde/mfo/jsurf/algebra/XYZPolynomial;->getTerms()[Lde/mfo/jsurf/algebra/XYZPolynomial$Term;
    move-result-object v1
    const/4 v2, 0
    array-length v3, v1
  :next
    if-ge v2, v3, :complete
    if-eqz v2, :term
    const-string v5, "|"
    invoke-virtual {v0, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  :term
    aget-object v4, v1, v2
    iget-byte v5, v4, Lde/mfo/jsurf/algebra/XYZPolynomial$Term;->xExp:B
    invoke-virtual {v0, v5}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
    const-string v5, ","
    invoke-virtual {v0, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    iget-byte v5, v4, Lde/mfo/jsurf/algebra/XYZPolynomial$Term;->yExp:B
    invoke-virtual {v0, v5}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
    const-string v5, ","
    invoke-virtual {v0, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    iget-byte v5, v4, Lde/mfo/jsurf/algebra/XYZPolynomial$Term;->zExp:B
    invoke-virtual {v0, v5}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
    const-string v5, ":"
    invoke-virtual {v0, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    iget-wide v6, v4, Lde/mfo/jsurf/algebra/XYZPolynomial$Term;->coeff:D
    invoke-static {v6, v7}, Ljava/lang/Double;->doubleToLongBits(D)J
    move-result-wide v6
    invoke-static {v6, v7}, Ljava/lang/Long;->toHexString(J)Ljava/lang/String;
    move-result-object v5
    invoke-virtual {v0, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    add-int/lit8 v2, v2, 1
    goto :next
  :complete
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v0
    return-object v0
.end method

.method private static expanded(Lde/mfo/jsurf/algebra/PolynomialOperation;)Ljava/lang/String;
    .registers 4
    new-instance v0, Lde/mfo/jsurf/algebra/Expand;
    invoke-direct {v0}, Lde/mfo/jsurf/algebra/Expand;-><init>()V
    const/4 v1, 0
    invoke-interface {p0, v0, v1}, Lde/mfo/jsurf/algebra/PolynomialOperation;->accept(Lde/mfo/jsurf/algebra/Visitor;Ljava/lang/Object;)Ljava/lang/Object;
    move-result-object v0
    check-cast v0, Lde/mfo/jsurf/algebra/XYZPolynomial;
    invoke-static {v0}, Lde/mfo/jsurf/algebra/OriginalExpansionOracle;->terms(Lde/mfo/jsurf/algebra/XYZPolynomial;)Ljava/lang/String;
    move-result-object v0
    return-object v0
.end method

.method private static appendExpanded(Ljava/lang/StringBuilder;Ljava/lang/String;Lde/mfo/jsurf/algebra/PolynomialOperation;)V
    .registers 4
    invoke-virtual {p0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-static {p2}, Lde/mfo/jsurf/algebra/OriginalExpansionOracle;->expanded(Lde/mfo/jsurf/algebra/PolynomialOperation;)Ljava/lang/String;
    move-result-object v0
    invoke-virtual {p0, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    return-void
.end method

.method private static observe(Ljava/lang/String;Z)Ljava/lang/String;
    .registers 13
    new-instance v0, Lde/mfo/jsurf/rendering/cpu/CPUAlgebraicSurfaceRenderer;
    invoke-direct {v0}, Lde/mfo/jsurf/rendering/cpu/CPUAlgebraicSurfaceRenderer;-><init>()V
    invoke-virtual {v0, p0}, Lde/mfo/jsurf/rendering/AlgebraicSurfaceRenderer;->setSurfaceFamily(Ljava/lang/String;)V
    if-eqz p1, :unbound
    const-string v1, "radius"
    const-wide/high16 v2, 0x4000000000000000L
    invoke-virtual {v0, v1, v2, v3}, Lde/mfo/jsurf/rendering/AlgebraicSurfaceRenderer;->setParameterValue(Ljava/lang/String;D)V
  :unbound
    invoke-virtual {v0}, Lde/mfo/jsurf/rendering/AlgebraicSurfaceRenderer;->getSurfaceTotalDegree()I
    move-result v2
    invoke-virtual {v0}, Lde/mfo/jsurf/rendering/AlgebraicSurfaceRenderer;->getSurfaceExpression()Lde/mfo/jsurf/algebra/PolynomialOperation;
    move-result-object v3
    invoke-virtual {v0}, Lde/mfo/jsurf/rendering/AlgebraicSurfaceRenderer;->getGradientXExpression()Lde/mfo/jsurf/algebra/PolynomialOperation;
    move-result-object v4
    invoke-virtual {v0}, Lde/mfo/jsurf/rendering/AlgebraicSurfaceRenderer;->getGradientYExpression()Lde/mfo/jsurf/algebra/PolynomialOperation;
    move-result-object v5
    invoke-virtual {v0}, Lde/mfo/jsurf/rendering/AlgebraicSurfaceRenderer;->getGradientZExpression()Lde/mfo/jsurf/algebra/PolynomialOperation;
    move-result-object v6
    new-instance v1, Ljava/lang/StringBuilder;
    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V
    const-string v7, "family="
    invoke-virtual {v1, v7}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
    const-string v7, ";surface="
    invoke-static {v1, v7, v3}, Lde/mfo/jsurf/algebra/OriginalExpansionOracle;->appendExpanded(Ljava/lang/StringBuilder;Ljava/lang/String;Lde/mfo/jsurf/algebra/PolynomialOperation;)V
    const-string v7, ";dx="
    invoke-static {v1, v7, v4}, Lde/mfo/jsurf/algebra/OriginalExpansionOracle;->appendExpanded(Ljava/lang/StringBuilder;Ljava/lang/String;Lde/mfo/jsurf/algebra/PolynomialOperation;)V
    const-string v7, ";dy="
    invoke-static {v1, v7, v5}, Lde/mfo/jsurf/algebra/OriginalExpansionOracle;->appendExpanded(Ljava/lang/StringBuilder;Ljava/lang/String;Lde/mfo/jsurf/algebra/PolynomialOperation;)V
    const-string v7, ";dz="
    invoke-static {v1, v7, v6}, Lde/mfo/jsurf/algebra/OriginalExpansionOracle;->appendExpanded(Ljava/lang/StringBuilder;Ljava/lang/String;Lde/mfo/jsurf/algebra/PolynomialOperation;)V
    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v1
    return-object v1
.end method

.method public static original_expansion(Ljava/lang/String;)Ljava/lang/String;
    .registers 2
    const/4 v0, 0
    invoke-static {p0, v0}, Lde/mfo/jsurf/algebra/OriginalExpansionOracle;->observe(Ljava/lang/String;Z)Ljava/lang/String;
    move-result-object v0
    return-object v0
.end method

.method public static original_expansion_with_radius(Ljava/lang/String;)Ljava/lang/String;
    .registers 2
    const/4 v0, 1
    invoke-static {p0, v0}, Lde/mfo/jsurf/algebra/OriginalExpansionOracle;->observe(Ljava/lang/String;Z)Ljava/lang/String;
    move-result-object v0
    return-object v0
.end method
