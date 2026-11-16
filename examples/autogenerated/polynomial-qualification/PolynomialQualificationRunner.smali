.class public LPolynomialQualificationRunner;
.super Ljava/lang/Object;

# Independent observer only. The qualified expression implementation remains
# checked Idric source; this runner supplies expectations, never candidate code.
.method private static check(Ljava/lang/String;Ljava/lang/String;)V
    .registers 6
    invoke-static {p0}, LIdric/Generated;->formula_qualification(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-nez v1, :ok
    sget-object v1, Ljava/lang/System;->err:Ljava/io/PrintStream;
    const-string v2, "FAIL Explorer polynomial qualification"
    invoke-virtual {v1, v2}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    invoke-virtual {v1, p0}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    invoke-virtual {v1, p1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    invoke-virtual {v1, v0}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/16 v3, 75
    invoke-static {v3}, Ljava/lang/System;->exit(I)V
  :ok
    return-void
.end method

.method public static main([Ljava/lang/String;)V
    .registers 4
    const-string v0, "2+3*4"
    const-string v1, "scalar"
    invoke-static {v0, v1}, LPolynomialQualificationRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "radius"
    const-string v1, "scalar"
    invoke-static {v0, v1}, LPolynomialQualificationRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "X"
    const-string v1, "scalar"
    invoke-static {v0, v1}, LPolynomialQualificationRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "2^2^3"
    const-string v1, "scalar"
    invoke-static {v0, v1}, LPolynomialQualificationRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "sin(0.2)"
    const-string v1, "scalar"
    invoke-static {v0, v1}, LPolynomialQualificationRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "x"
    const-string v1, "polynomial"
    invoke-static {v0, v1}, LPolynomialQualificationRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "x/(2+2)"
    const-string v1, "polynomial"
    invoke-static {v0, v1}, LPolynomialQualificationRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "x^(2)"
    const-string v1, "polynomial"
    invoke-static {v0, v1}, LPolynomialQualificationRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "sin(2)"
    const-string v1, "scalar"
    invoke-static {v0, v1}, LPolynomialQualificationRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "(sin(2))"
    const-string v1, "scalar"
    invoke-static {v0, v1}, LPolynomialQualificationRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "(x)+(y)"
    const-string v1, "polynomial"
    invoke-static {v0, v1}, LPolynomialQualificationRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "x^((2))"
    const-string v1, "meaning error: inherited repeated-grouping limitation"
    invoke-static {v0, v1}, LPolynomialQualificationRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "sin((2))"
    const-string v1, "meaning error: inherited repeated-grouping limitation"
    invoke-static {v0, v1}, LPolynomialQualificationRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "((sin(2)))"
    const-string v1, "meaning error: inherited repeated-grouping limitation"
    invoke-static {v0, v1}, LPolynomialQualificationRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "x^4-x*y^3-z^4+z"
    const-string v1, "polynomial"
    invoke-static {v0, v1}, LPolynomialQualificationRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "x^2+x*z^2+y^3"
    const-string v1, "polynomial"
    invoke-static {v0, v1}, LPolynomialQualificationRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "x/y"
    const-string v1, "meaning error: polynomial divisor"
    invoke-static {v0, v1}, LPolynomialQualificationRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "x/(0*x+1)"
    const-string v1, "meaning error: polynomial divisor"
    invoke-static {v0, v1}, LPolynomialQualificationRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "x^2.0"
    const-string v1, "meaning error: polynomial exponent must be a decimal literal"
    invoke-static {v0, v1}, LPolynomialQualificationRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "x^(1+1)"
    const-string v1, "meaning error: polynomial exponent must be a decimal literal"
    invoke-static {v0, v1}, LPolynomialQualificationRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "sin(x)"
    const-string v1, "meaning error: function requires scalar argument: sin"
    invoke-static {v0, v1}, LPolynomialQualificationRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "sin(x^0)"
    const-string v1, "meaning error: function requires scalar argument: sin"
    invoke-static {v0, v1}, LPolynomialQualificationRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "foo(2)"
    const-string v1, "meaning error: unknown coefficient function: foo"
    invoke-static {v0, v1}, LPolynomialQualificationRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "x^2147483647"
    const-string v1, "polynomial"
    invoke-static {v0, v1}, LPolynomialQualificationRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "x^2147483648"
    const-string v1, "polynomial; inherited exponent overflow to zero: 2147483648"
    invoke-static {v0, v1}, LPolynomialQualificationRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS Explorer polynomial qualification on ART"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method
