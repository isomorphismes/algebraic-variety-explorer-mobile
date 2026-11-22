.class public LCoefficientRunner;
.super Ljava/lang/Object;

# Independent observations of the application-owned coefficient evaluator.
.method private static check(Ljava/lang/String;Ljava/lang/String;)V
    .registers 6
    invoke-static {p0}, LOriginalCoefficientOracle;->valueBits(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v3
    invoke-virtual {p1, v3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-eqz v1, :fail
    invoke-static {p0}, LIdric/Generated;->coefficient_bits(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-nez v1, :ok
  :fail
    # Read the candidate for an oracle disagreement as well, for useful evidence.
    invoke-static {p0}, LIdric/Generated;->coefficient_bits(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    sget-object v1, Ljava/lang/System;->err:Ljava/io/PrintStream;
    const-string v2, "FAIL Explorer coefficient value"
    invoke-virtual {v1, v2}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    invoke-virtual {v1, p0}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    invoke-virtual {v1, p1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    invoke-virtual {v1, v3}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    invoke-virtual {v1, v0}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/16 v0, 76
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
  :ok
    return-void
.end method

.method public static main([Ljava/lang/String;)V
    .registers 4
    const-string v0, "0.4"
    const-string v1, "3fd999999999999a"
    invoke-static {v0, v1}, LCoefficientRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "0.4+0.1"
    const-string v1, "3fe0000000000000"
    invoke-static {v0, v1}, LCoefficientRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "16777217"
    const-string v1, "4170000010000000"
    invoke-static {v0, v1}, LCoefficientRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "16777217+1"
    const-string v1, "4170000020000000"
    invoke-static {v0, v1}, LCoefficientRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "9007199254740991"
    const-string v1, "433fffffffffffff"
    invoke-static {v0, v1}, LCoefficientRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "(16777217+1)-16777217"
    const-string v1, "3ff0000000000000"
    invoke-static {v0, v1}, LCoefficientRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "-0"
    const-string v1, "8000000000000000"
    invoke-static {v0, v1}, LCoefficientRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "1/(-0)"
    const-string v1, "fff0000000000000"
    invoke-static {v0, v1}, LCoefficientRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "0/0"
    const-string v1, "7ff8000000000000"
    invoke-static {v0, v1}, LCoefficientRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "sqrt(.25)"
    const-string v1, "3fe0000000000000"
    invoke-static {v0, v1}, LCoefficientRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "2^3"
    const-string v1, "4020000000000000"
    invoke-static {v0, v1}, LCoefficientRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "ceil(1.1)"
    const-string v1, "4000000000000000"
    invoke-static {v0, v1}, LCoefficientRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "floor(1.9)"
    const-string v1, "3ff0000000000000"
    invoke-static {v0, v1}, LCoefficientRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "abs(-0)"
    const-string v1, "0"
    invoke-static {v0, v1}, LCoefficientRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "sign(-0)"
    const-string v1, "8000000000000000"
    invoke-static {v0, v1}, LCoefficientRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "log(1)"
    const-string v1, "0"
    invoke-static {v0, v1}, LCoefficientRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "0.5*0.5"
    const-string v1, "3fd0000000000000"
    invoke-static {v0, v1}, LCoefficientRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "3/2"
    const-string v1, "3ff8000000000000"
    invoke-static {v0, v1}, LCoefficientRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "sin(0)"
    const-string v1, "0"
    invoke-static {v0, v1}, LCoefficientRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "cos(0)"
    const-string v1, "3ff0000000000000"
    invoke-static {v0, v1}, LCoefficientRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "tan(0)"
    const-string v1, "0"
    invoke-static {v0, v1}, LCoefficientRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "asin(0)"
    const-string v1, "0"
    invoke-static {v0, v1}, LCoefficientRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "acos(1)"
    const-string v1, "0"
    invoke-static {v0, v1}, LCoefficientRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "atan(0)"
    const-string v1, "0"
    invoke-static {v0, v1}, LCoefficientRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "exp(0)"
    const-string v1, "3ff0000000000000"
    invoke-static {v0, v1}, LCoefficientRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "x"
    const-string v1, "error: coefficient must be scalar"
    invoke-static {v0, v1}, LCoefficientRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "radius"
    const-string v1, "error: no value has been assigned to parameter 'radius'"
    invoke-static {v0, v1}, LCoefficientRunner;->check(Ljava/lang/String;Ljava/lang/String;)V
    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS Explorer coefficient values on ART"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method
