.class public LExpansionRunner;
.super Ljava/lang/Object;

# Independent exact term/bit comparison against the retained original program.
.method private static equal(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V
    .registers 6
    invoke-virtual {p1, p2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    if-nez v0, :ok
    sget-object v0, Ljava/lang/System;->err:Ljava/io/PrintStream;
    const-string v1, "FAIL Explorer ordered expansion"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    invoke-virtual {v0, p0}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    invoke-virtual {v0, p1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    invoke-virtual {v0, p2}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/16 v0, 77
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
  :ok
    return-void
.end method

.method private static check(Ljava/lang/String;)V
    .registers 4
    invoke-static {p0}, Lde/mfo/jsurf/algebra/OriginalExpansionOracle;->original_expansion(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    invoke-static {p0}, LIdric/Generated;->actual_expansion(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v1
    invoke-static {p0, v0, v1}, LExpansionRunner;->equal(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V
    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    invoke-virtual {v0, p0}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method

.method private static bound(Ljava/lang/String;)V
    .registers 4
    invoke-static {p0}, Lde/mfo/jsurf/algebra/OriginalExpansionOracle;->original_expansion_with_radius(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    invoke-static {p0}, LIdric/Generated;->actual_expansion_with_radius(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v1
    invoke-static {p0, v0, v1}, LExpansionRunner;->equal(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V
    return-void
.end method

.method private static refusal(Ljava/lang/String;Ljava/lang/String;)V
    .registers 4
    invoke-static {p0}, LIdric/Generated;->expansion_budget_probe(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    invoke-static {p0, p1, v0}, LExpansionRunner;->equal(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V
    return-void
.end method

# Elementary plane: fixed expectations also check the oracle's axis labels.
.method private static plane()V
    .registers 3
    const-string v0, "x"
    const-string v1, "family=1;surface=1,0,0:3ff0000000000000;dx=0,0,0:3ff0000000000000;dy=0,0,0:0;dz=0,0,0:0"
    invoke-static {v0}, Lde/mfo/jsurf/algebra/OriginalExpansionOracle;->original_expansion(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v2
    invoke-static {v0, v1, v2}, LExpansionRunner;->equal(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V
    invoke-static {v0}, LIdric/Generated;->actual_expansion(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v2
    invoke-static {v0, v1, v2}, LExpansionRunner;->equal(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V
    return-void
.end method

.method public static main([Ljava/lang/String;)V
    .registers 3
    invoke-static {}, LExpansionRunner;->plane()V
    const-string v0, "x^2+y^2+z^2-0.64"
    invoke-static {v0}, LExpansionRunner;->check(Ljava/lang/String;)V
    const-string v0, "(x^2+y^2+z^2+0.36)^2-1.69*(x^2+y^2)"
    invoke-static {v0}, LExpansionRunner;->check(Ljava/lang/String;)V
    const-string v0, "x^2+y^2+z^2+2*x*y*z-1"
    invoke-static {v0}, LExpansionRunner;->check(Ljava/lang/String;)V
    const-string v0, "x^2-y^2*z"
    invoke-static {v0}, LExpansionRunner;->check(Ljava/lang/String;)V
    const-string v0, "x^2*y^2+y^2*z^2+z^2*x^2-x*y*z"
    invoke-static {v0}, LExpansionRunner;->check(Ljava/lang/String;)V
    const-string v0, "(x^2+2.25*y^2+z^2-1)^3-x^2*z^3-0.1125*y^2*z^3"
    invoke-static {v0}, LExpansionRunner;->check(Ljava/lang/String;)V
    const-string v0, "x^2+x*z^2+y^3"
    invoke-static {v0}, LExpansionRunner;->check(Ljava/lang/String;)V
    const-string v0, "x^4-x*y^3-z^4+z"
    invoke-static {v0}, LExpansionRunner;->check(Ljava/lang/String;)V
    const-string v0, "x^2-x^2+y"
    invoke-static {v0}, LExpansionRunner;->check(Ljava/lang/String;)V
    const-string v0, "(3*x+2)/10"
    invoke-static {v0}, LExpansionRunner;->check(Ljava/lang/String;)V
    const-string v0, "(0.1*x+0.2)^5"
    invoke-static {v0}, LExpansionRunner;->check(Ljava/lang/String;)V
    const-string v0, "(x-x)*(y+1)"
    invoke-static {v0}, LExpansionRunner;->check(Ljava/lang/String;)V
    const-string v0, "(x+y)^0+z"
    invoke-static {v0}, LExpansionRunner;->check(Ljava/lang/String;)V
    const-string v0, "(-10000000000000000+x+x^2+10000000000000000*x^3)*(1+x+x^2+x^3)"
    invoke-static {v0}, LExpansionRunner;->check(Ljava/lang/String;)V
    const-string v0, "x^2+y^2+z^2-radius^2"
    invoke-static {v0}, LExpansionRunner;->bound(Ljava/lang/String;)V
    # Both retained results and all three derivatives are finite/in range.
    # The original final factor square is discarded, so its overflow is moot.
    const-string v0, "x^127"
    invoke-static {v0}, LExpansionRunner;->check(Ljava/lang/String;)V
    const-string v0, "(1e100*x)^3"
    invoke-static {v0}, LExpansionRunner;->check(Ljava/lang/String;)V
    const-string v0, "terms"
    const-string v1, "error: polynomial expansion term budget exceeded"
    invoke-static {v0, v1}, LExpansionRunner;->refusal(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "products"
    const-string v1, "error: polynomial expansion product budget exceeded"
    invoke-static {v0, v1}, LExpansionRunner;->refusal(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "invalid"
    const-string v1, "error: expansion limits must permit at least one term and product"
    invoke-static {v0, v1}, LExpansionRunner;->refusal(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "1/0"
    const-string v1, "error: nonfinite coefficient is outside checked ordered expansion"
    invoke-static {v0, v1}, LExpansionRunner;->refusal(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "x^128"
    const-string v1, "error: polynomial exponent exceeds original nonnegative signed-byte range"
    invoke-static {v0, v1}, LExpansionRunner;->refusal(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "(1e200*x)^2"
    const-string v1, "error: nonfinite coefficient is outside checked ordered expansion"
    invoke-static {v0, v1}, LExpansionRunner;->refusal(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "radius*x"
    const-string v1, "error: no value has been assigned to parameter 'radius'"
    invoke-static {v0, v1}, LExpansionRunner;->refusal(Ljava/lang/String;Ljava/lang/String;)V
    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS Explorer ordered expansion on ART"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method
