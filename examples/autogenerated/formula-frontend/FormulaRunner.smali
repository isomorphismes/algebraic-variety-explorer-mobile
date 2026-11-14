.class public LFormulaRunner;
.super Ljava/lang/Object;

# Independent observer only. All candidate instructions come from checked
# AlgebraicExpression.idric; this class never produces a candidate parser.
.method private static check(Ljava/lang/String;Ljava/lang/String;)V
    .registers 5
    invoke-static {p0}, LIdric/Generated;->formula_shape(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-nez v1, :ok
    sget-object v1, Ljava/lang/System;->err:Ljava/io/PrintStream;
    const-string v2, "FAIL Explorer formula shape"
    invoke-virtual {v1, v2}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    invoke-virtual {v1, p0}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    invoke-virtual {v1, v0}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/16 v0, 73
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
  :ok
    return-void
.end method

.method private static reject(Ljava/lang/String;)V
    .registers 4
    invoke-static {p0}, LIdric/Generated;->formula_shape(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    const-string v1, "error: "
    invoke-virtual {v0, v1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
    move-result v1
    if-nez v1, :ok
    sget-object v1, Ljava/lang/System;->err:Ljava/io/PrintStream;
    const-string v2, "FAIL Explorer accepted malformed formula"
    invoke-virtual {v1, v2}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/16 v0, 74
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
  :ok
    return-void
.end method

.method public static main([Ljava/lang/String;)V
    .registers 4
    const-string v0, "x^2^3"
    const-string v1, "pow(name[x],pow(decimal[2],decimal[3]))"
    invoke-static {v0, v1}, LFormulaRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "-x^2"
    const-string v1, "neg(pow(name[x],decimal[2]))"
    invoke-static {v0, v1}, LFormulaRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "(-x)^2"
    const-string v1, "pow(group(neg(name[x])),decimal[2])"
    invoke-static {v0, v1}, LFormulaRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "1.25e-3*x"
    const-string v1, "mul(float[1.25e-3],name[x])"
    invoke-static {v0, v1}, LFormulaRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "sqrt(.25)+x"
    const-string v1, "add(call[sqrt](float[.25]),name[x])"
    invoke-static {v0, v1}, LFormulaRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "x/2/3"
    const-string v1, "div(div(name[x],decimal[2]),decimal[3])"
    invoke-static {v0, v1}, LFormulaRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "x^4-x*y^3-z^4+z"
    const-string v1, "add(sub(sub(pow(name[x],decimal[4]),mul(name[x],pow(name[y],decimal[3]))),pow(name[z],decimal[4])),name[z])"
    invoke-static {v0, v1}, LFormulaRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "x^2+x*z^2+y^3"
    const-string v1, "add(add(pow(name[x],decimal[2]),mul(name[x],pow(name[z],decimal[2]))),pow(name[y],decimal[3]))"
    invoke-static {v0, v1}, LFormulaRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "x+"
    invoke-static {v0}, LFormulaRunner;->reject(Ljava/lang/String;)V
    const-string v0, "1e+"
    invoke-static {v0}, LFormulaRunner;->reject(Ljava/lang/String;)V
    const-string v0, "x$"
    invoke-static {v0}, LFormulaRunner;->reject(Ljava/lang/String;)V
    const-string v0, "x^-2"
    invoke-static {v0}, LFormulaRunner;->reject(Ljava/lang/String;)V
    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS Explorer source parser on ART"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method
