.class public final LOriginalPreparationOracle;
.super Ljava/lang/Object;

# Test-only getter walk over actual original operation objects. All semantic
# preparation is performed by the original Simplificator and Differentiator.
.method private static getter(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;
    .registers 5
    invoke-virtual {p0}, Ljava/lang/Object;->getClass()Ljava/lang/Class;
    move-result-object v0
    const/4 v1, 0
    new-array v2, v1, [Ljava/lang/Class;
    invoke-virtual {v0, p1, v2}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;
    move-result-object v0
    new-array v2, v1, [Ljava/lang/Object;
    invoke-virtual {v0, p0, v2}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;
    move-result-object v0
    return-object v0
.end method

.method private static unary(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    .registers 4
    new-instance v0, Ljava/lang/StringBuilder;
    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V
    invoke-virtual {v0, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    const-string v1, "("
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    const-string v1, ")"
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v0
    return-object v0
.end method

.method private static binary(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    .registers 5
    new-instance v0, Ljava/lang/StringBuilder;
    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V
    invoke-virtual {v0, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    const-string v1, "("
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    const-string v1, ","
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v0, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    const-string v1, ")"
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v0
    return-object v0
.end method

.method private static scalarOperator(Ljava/lang/String;)Ljava/lang/String;
    .registers 3
    const-string v0, "add"
    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-eqz v1, :sub
    const-string v0, "s+"
    return-object v0
  :sub
    const-string v0, "sub"
    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-eqz v1, :mult
    const-string v0, "s-"
    return-object v0
  :mult
    const-string v0, "mult"
    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-eqz v1, :div
    const-string v0, "s*"
    return-object v0
  :div
    const-string v0, "div"
    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-eqz v1, :pow
    const-string v0, "s/"
    return-object v0
  :pow
    const-string v0, "pow"
    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-eqz v1, :unknown
    const-string v0, "s^"
    return-object v0
  :unknown
    new-instance v0, Ljava/lang/IllegalArgumentException;
    invoke-direct {v0, p0}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V
    throw v0
.end method

.method private static shape(Ljava/lang/Object;)Ljava/lang/String;
    .registers 7
    invoke-virtual {p0}, Ljava/lang/Object;->getClass()Ljava/lang/Class;
    move-result-object v0
    invoke-virtual {v0}, Ljava/lang/Class;->getSimpleName()Ljava/lang/String;
    move-result-object v0
    const-string v1, "DoubleValue"
    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-nez v1, :value
    const-string v1, "DoubleVariable"
    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-nez v1, :parameter
    const-string v1, "PolynomialVariable"
    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-nez v1, :coordinate
    const-string v1, "DoubleBinaryOperation"
    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-nez v1, :scalar_binary
    const-string v1, "DoubleUnaryOperation"
    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-nez v1, :scalar_unary
    const-string v1, "PolynomialAddition"
    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-nez v1, :addition
    const-string v1, "PolynomialSubtraction"
    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-nez v1, :subtraction
    const-string v1, "PolynomialMultiplication"
    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-nez v1, :multiplication
    const-string v1, "PolynomialDoubleDivision"
    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-nez v1, :division
    const-string v1, "PolynomialPower"
    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-nez v1, :power
    const-string v1, "PolynomialNegation"
    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-nez v1, :negative
    new-instance v1, Ljava/lang/IllegalArgumentException;
    invoke-direct {v1, v0}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V
    throw v1

  :value
    const-string v0, "getValue"
    invoke-static {p0, v0}, LOriginalPreparationOracle;->getter(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;
    move-result-object v0
    check-cast v0, Ljava/lang/Double;
    invoke-virtual {v0}, Ljava/lang/Double;->doubleValue()D
    move-result-wide v2
    invoke-static {v2, v3}, Ljava/lang/Double;->doubleToLongBits(D)J
    move-result-wide v2
    invoke-static {v2, v3}, Ljava/lang/Long;->toHexString(J)Ljava/lang/String;
    move-result-object v1
    const-string v0, "v"
    invoke-static {v0, v1}, LOriginalPreparationOracle;->unary(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    return-object v0
  :parameter
    const-string v0, "getName"
    invoke-static {p0, v0}, LOriginalPreparationOracle;->getter(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;
    move-result-object v1
    check-cast v1, Ljava/lang/String;
    const-string v0, "name"
    invoke-static {v0, v1}, LOriginalPreparationOracle;->unary(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    return-object v0
  :coordinate
    const-string v0, "getVariable"
    invoke-static {p0, v0}, LOriginalPreparationOracle;->getter(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;
    move-result-object v0
    invoke-virtual {v0}, Ljava/lang/Object;->toString()Ljava/lang/String;
    move-result-object v0
    return-object v0
  :scalar_binary
    const-string v0, "getOperator"
    invoke-static {p0, v0}, LOriginalPreparationOracle;->getter(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;
    move-result-object v0
    invoke-virtual {v0}, Ljava/lang/Object;->toString()Ljava/lang/String;
    move-result-object v0
    invoke-static {v0}, LOriginalPreparationOracle;->scalarOperator(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    goto :operands
  :addition
    const-string v0, "p+"
    goto :operands
  :subtraction
    const-string v0, "p-"
    goto :operands
  :multiplication
    const-string v0, "p*"
  :operands
    const-string v1, "getFirstOperand"
    const-string v2, "getSecondOperand"
    goto :two_children
  :division
    const-string v0, "p/"
    const-string v1, "getDividend"
    const-string v2, "getDivisor"
  :two_children
    invoke-static {p0, v1}, LOriginalPreparationOracle;->getter(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;
    move-result-object v1
    invoke-static {v1}, LOriginalPreparationOracle;->shape(Ljava/lang/Object;)Ljava/lang/String;
    move-result-object v1
    invoke-static {p0, v2}, LOriginalPreparationOracle;->getter(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;
    move-result-object v2
    invoke-static {v2}, LOriginalPreparationOracle;->shape(Ljava/lang/Object;)Ljava/lang/String;
    move-result-object v2
    invoke-static {v0, v1, v2}, LOriginalPreparationOracle;->binary(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    return-object v0
  :power
    const-string v0, "getBase"
    invoke-static {p0, v0}, LOriginalPreparationOracle;->getter(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;
    move-result-object v1
    invoke-static {v1}, LOriginalPreparationOracle;->shape(Ljava/lang/Object;)Ljava/lang/String;
    move-result-object v1
    const-string v0, "getExponent"
    invoke-static {p0, v0}, LOriginalPreparationOracle;->getter(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;
    move-result-object v2
    invoke-virtual {v2}, Ljava/lang/Object;->toString()Ljava/lang/String;
    move-result-object v2
    const-string v0, "p^"
    invoke-static {v0, v1, v2}, LOriginalPreparationOracle;->binary(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    return-object v0
  :scalar_unary
    const-string v0, "getOperator"
    invoke-static {p0, v0}, LOriginalPreparationOracle;->getter(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;
    move-result-object v0
    invoke-virtual {v0}, Ljava/lang/Object;->toString()Ljava/lang/String;
    move-result-object v0
    goto :one_child
  :negative
    const-string v0, "pneg"
  :one_child
    const-string v1, "getOperand"
    invoke-static {p0, v1}, LOriginalPreparationOracle;->getter(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;
    move-result-object v1
    invoke-static {v1}, LOriginalPreparationOracle;->shape(Ljava/lang/Object;)Ljava/lang/String;
    move-result-object v1
    invoke-static {v0, v1}, LOriginalPreparationOracle;->unary(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    return-object v0
.end method

.method private static derivative(Lde/mfo/jsurf/algebra/PolynomialOperation;Lde/mfo/jsurf/algebra/PolynomialVariable$Var;)Ljava/lang/String;
    .registers 5
    new-instance v0, Lde/mfo/jsurf/algebra/Differentiator;
    invoke-direct {v0, p1}, Lde/mfo/jsurf/algebra/Differentiator;-><init>(Lde/mfo/jsurf/algebra/PolynomialVariable$Var;)V
    const/4 v1, 0
    invoke-interface {p0, v0, v1}, Lde/mfo/jsurf/algebra/PolynomialOperation;->accept(Lde/mfo/jsurf/algebra/Visitor;Ljava/lang/Object;)Ljava/lang/Object;
    move-result-object v0
    invoke-static {v0}, LOriginalPreparationOracle;->shape(Ljava/lang/Object;)Ljava/lang/String;
    move-result-object v0
    return-object v0
.end method

.method public static report(Ljava/lang/String;Z)Ljava/lang/String;
    .registers 10
    invoke-static {p0}, Lde/mfo/jsurf/parser/AlgebraicExpressionParser;->parse(Ljava/lang/String;)Lde/mfo/jsurf/algebra/PolynomialOperation;
    move-result-object v0
    new-instance v1, Lde/mfo/jsurf/algebra/DegreeCalculator;
    invoke-direct {v1}, Lde/mfo/jsurf/algebra/DegreeCalculator;-><init>()V
    const/4 v2, 0
    invoke-interface {v0, v1, v2}, Lde/mfo/jsurf/algebra/PolynomialOperation;->accept(Lde/mfo/jsurf/algebra/Visitor;Ljava/lang/Object;)Ljava/lang/Object;
    move-result-object v3
    new-instance v1, Lde/mfo/jsurf/algebra/Simplificator;
    invoke-direct {v1}, Lde/mfo/jsurf/algebra/Simplificator;-><init>()V
    if-eqz p1, :simplify
    const-string v4, "radius"
    const-wide/high16 v5, 0x4000000000000000L
    invoke-virtual {v1, v4, v5, v6}, Lde/mfo/jsurf/algebra/Simplificator;->setParameterValue(Ljava/lang/String;D)V
    const-string v4, "zero"
    const-wide/16 v5, 0
    invoke-virtual {v1, v4, v5, v6}, Lde/mfo/jsurf/algebra/Simplificator;->setParameterValue(Ljava/lang/String;D)V
    const-string v4, "unit"
    const-wide/high16 v5, 0x3ff0000000000000L
    invoke-virtual {v1, v4, v5, v6}, Lde/mfo/jsurf/algebra/Simplificator;->setParameterValue(Ljava/lang/String;D)V
  :simplify
    invoke-interface {v0, v1, v2}, Lde/mfo/jsurf/algebra/PolynomialOperation;->accept(Lde/mfo/jsurf/algebra/Visitor;Ljava/lang/Object;)Ljava/lang/Object;
    move-result-object v0
    check-cast v0, Lde/mfo/jsurf/algebra/PolynomialOperation;
    new-instance v1, Ljava/lang/StringBuilder;
    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V
    const-string v4, "degree="
    invoke-virtual {v1, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v1, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
    const-string v4, ";surface="
    invoke-virtual {v1, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-static {v0}, LOriginalPreparationOracle;->shape(Ljava/lang/Object;)Ljava/lang/String;
    move-result-object v4
    invoke-virtual {v1, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    const-string v4, ";dx="
    invoke-virtual {v1, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    sget-object v4, Lde/mfo/jsurf/algebra/PolynomialVariable$Var;->x:Lde/mfo/jsurf/algebra/PolynomialVariable$Var;
    invoke-static {v0, v4}, LOriginalPreparationOracle;->derivative(Lde/mfo/jsurf/algebra/PolynomialOperation;Lde/mfo/jsurf/algebra/PolynomialVariable$Var;)Ljava/lang/String;
    move-result-object v4
    invoke-virtual {v1, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    const-string v4, ";dy="
    invoke-virtual {v1, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    sget-object v4, Lde/mfo/jsurf/algebra/PolynomialVariable$Var;->y:Lde/mfo/jsurf/algebra/PolynomialVariable$Var;
    invoke-static {v0, v4}, LOriginalPreparationOracle;->derivative(Lde/mfo/jsurf/algebra/PolynomialOperation;Lde/mfo/jsurf/algebra/PolynomialVariable$Var;)Ljava/lang/String;
    move-result-object v4
    invoke-virtual {v1, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    const-string v4, ";dz="
    invoke-virtual {v1, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    sget-object v4, Lde/mfo/jsurf/algebra/PolynomialVariable$Var;->z:Lde/mfo/jsurf/algebra/PolynomialVariable$Var;
    invoke-static {v0, v4}, LOriginalPreparationOracle;->derivative(Lde/mfo/jsurf/algebra/PolynomialOperation;Lde/mfo/jsurf/algebra/PolynomialVariable$Var;)Ljava/lang/String;
    move-result-object v4
    invoke-virtual {v1, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    const-string v4, ";notices=0"
    invoke-virtual {v1, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v0
    return-object v0
.end method
