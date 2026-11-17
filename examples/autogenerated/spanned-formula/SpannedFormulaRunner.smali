.class public final LSpannedFormulaRunner;
.super Ljava/lang/Object;

# Independent expected values only; all admission/preparation comes from DEX
# emitted from the actual production Idriç modules.
.method private static require(Ljava/lang/String;Ljava/lang/String;)V
    .registers 4
    invoke-virtual {p1, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    if-nez v0, :ok
    sget-object v0, Ljava/lang/System;->err:Ljava/io/PrintStream;
    const-string v1, "FAIL Explorer spanned formula on ART"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    invoke-virtual {v0, p0}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    invoke-virtual {v0, p1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/16 v0, 85
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
  :ok
    return-void
.end method

.method public static main([Ljava/lang/String;)V
    .registers 3
    const-string v0, " \tsin(.25)+1.20e-3*x_2\n"
    invoke-static {v0}, LIdric/Generated;->spanned_tokens(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    const-string v1, "name[sin]@2..5|open@5..6|float[.25]@6..9|close@9..10|plus@10..11|float[1.20e-3]@11..18|multiply@18..19|name[x_2]@19..22"
    invoke-static {v0, v1}, LSpannedFormulaRunner;->require(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "0 01.0 01e2 1. .5"
    invoke-static {v0}, LIdric/Generated;->spanned_tokens(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    const-string v1, "decimal[0]@0..1|float[01.0]@2..6|float[01e2]@7..11|float[1.]@12..14|float[.5]@15..17"
    invoke-static {v0, v1}, LSpannedFormulaRunner;->require(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "x+  "
    invoke-static {v0}, LIdric/Generated;->detailed_syntax(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    const-string v1, "primary@4..4:expected number, name or '('"
    invoke-static {v0, v1}, LSpannedFormulaRunner;->require(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "1e+x"
    invoke-static {v0}, LIdric/Generated;->detailed_syntax(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    const-string v1, "scientific-digits@3..4:expected digits in scientific exponent"
    invoke-static {v0, v1}, LSpannedFormulaRunner;->require(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "x+🙂"
    invoke-static {v0}, LIdric/Generated;->detailed_syntax(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    const-string v1, "unexpected-character@2..3:unexpected character: 🙂"
    invoke-static {v0, v1}, LSpannedFormulaRunner;->require(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "(x"
    invoke-static {v0}, LIdric/Generated;->detailed_syntax(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    const-string v1, "group-close@2..2:expected ')'"
    invoke-static {v0, v1}, LSpannedFormulaRunner;->require(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "sin(x y)"
    invoke-static {v0}, LIdric/Generated;->detailed_syntax(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    const-string v1, "function-close@6..7:expected ')' after function argument"
    invoke-static {v0, v1}, LSpannedFormulaRunner;->require(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, " x+$"
    invoke-static {v0}, LIdric/Generated;->located_preparation(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    const-string v1, "syntax error: unexpected character: $ at characters 3..4"
    invoke-static {v0, v1}, LSpannedFormulaRunner;->require(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "x^2+y^2+z^2-0.64"
    invoke-static {v0}, LIdric/Generated;->located_preparation(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    const-string v1, "prepared"
    invoke-static {v0, v1}, LSpannedFormulaRunner;->require(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "-x^2^3"
    invoke-static {v0}, LIdric/Generated;->detailed_syntax(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    const-string v1, "accepted:neg(pow(name[x],pow(decimal[2],decimal[3])))"
    invoke-static {v0, v1}, LSpannedFormulaRunner;->require(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "x/y"
    invoke-static {v0}, LIdric/Generated;->located_preparation(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    const-string v1, "meaning error: polynomial divisor"
    invoke-static {v0, v1}, LSpannedFormulaRunner;->require(Ljava/lang/String;Ljava/lang/String;)V
    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS Explorer spanned formula on ART"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method
