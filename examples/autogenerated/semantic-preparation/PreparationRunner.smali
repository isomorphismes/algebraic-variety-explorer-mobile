.class public LPreparationRunner;
.super Ljava/lang/Object;

# Independent expected structures/bits and the actual original jsurf visitors.
.method private static equal(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;I)V
    .registers 7
    invoke-virtual {p1, p2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    if-nez v0, :ok
    sget-object v0, Ljava/lang/System;->err:Ljava/io/PrintStream;
    const/16 v1, 77
    if-eq p3, v1, :candidate_failure
    const-string v1, "FAIL original jsurf preparation oracle"
    goto :print
  :candidate_failure
    const-string v1, "FAIL Explorer semantic preparation"
  :print
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    invoke-virtual {v0, p0}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    invoke-virtual {v0, p1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    invoke-virtual {v0, p2}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    invoke-static {p3}, Ljava/lang/System;->exit(I)V
  :ok
    return-void
.end method
.method private static check(Ljava/lang/String;Ljava/lang/String;ZZ)V
    .registers 8
    if-eqz p3, :candidate
    invoke-static {p0, p2}, LOriginalPreparationOracle;->report(Ljava/lang/String;Z)Ljava/lang/String;
    move-result-object v0
    const/16 v1, 78
    invoke-static {p0, p1, v0, v1}, LPreparationRunner;->equal(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;I)V
  :candidate
    if-eqz p2, :unbound
    invoke-static {p0}, LIdric/Generated;->bound_preparation_report(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    goto :compare
  :unbound
    invoke-static {p0}, LIdric/Generated;->preparation_report(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
  :compare
    const/16 v1, 77
    invoke-static {p0, p1, v0, v1}, LPreparationRunner;->equal(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;I)V
    return-void
.end method

.method public static main([Ljava/lang/String;)V
    .registers 5
    const-string v0, "x"
    const-string v1, "degree=1;surface=x;dx=v(3ff0000000000000);dy=v(0);dz=v(0);notices=0"
    const/4 v2, 0
    const/4 v3, 1
    invoke-static {v0, v1, v2, v3}, LPreparationRunner;->check(Ljava/lang/String;Ljava/lang/String;ZZ)V
    const-string v0, "0*x"
    const-string v1, "degree=1;surface=v(0);dx=v(0);dy=v(0);dz=v(0);notices=0"
    const/4 v2, 0
    const/4 v3, 1
    invoke-static {v0, v1, v2, v3}, LPreparationRunner;->check(Ljava/lang/String;Ljava/lang/String;ZZ)V
    const-string v0, "-0*x"
    const-string v1, "degree=1;surface=v(8000000000000000);dx=v(0);dy=v(0);dz=v(0);notices=0"
    const/4 v2, 0
    const/4 v3, 1
    invoke-static {v0, v1, v2, v3}, LPreparationRunner;->check(Ljava/lang/String;Ljava/lang/String;ZZ)V
    const-string v0, "x^0"
    const-string v1, "degree=0;surface=v(3ff0000000000000);dx=v(0);dy=v(0);dz=v(0);notices=0"
    const/4 v2, 0
    const/4 v3, 1
    invoke-static {v0, v1, v2, v3}, LPreparationRunner;->check(Ljava/lang/String;Ljava/lang/String;ZZ)V
    const-string v0, "x^1"
    const-string v1, "degree=1;surface=x;dx=v(3ff0000000000000);dy=v(0);dz=v(0);notices=0"
    const/4 v2, 0
    const/4 v3, 1
    invoke-static {v0, v1, v2, v3}, LPreparationRunner;->check(Ljava/lang/String;Ljava/lang/String;ZZ)V
    const-string v0, "(x+y)^1"
    const-string v1, "degree=1;surface=p+(x,y);dx=p+(v(3ff0000000000000),v(0));dy=p+(v(0),v(3ff0000000000000));dz=p+(v(0),v(0));notices=0"
    const/4 v2, 0
    const/4 v3, 1
    invoke-static {v0, v1, v2, v3}, LPreparationRunner;->check(Ljava/lang/String;Ljava/lang/String;ZZ)V
    const-string v0, "x^2"
    const-string v1, "degree=2;surface=p^(x,2);dx=p*(p*(v(4000000000000000),x),v(3ff0000000000000));dy=p*(p*(v(4000000000000000),x),v(0));dz=p*(p*(v(4000000000000000),x),v(0));notices=0"
    const/4 v2, 0
    const/4 v3, 1
    invoke-static {v0, v1, v2, v3}, LPreparationRunner;->check(Ljava/lang/String;Ljava/lang/String;ZZ)V
    const-string v0, "x*y"
    const-string v1, "degree=2;surface=p*(x,y);dx=p+(p*(v(3ff0000000000000),y),p*(x,v(0)));dy=p+(p*(v(0),y),p*(x,v(3ff0000000000000)));dz=p+(p*(v(0),y),p*(x,v(0)));notices=0"
    const/4 v2, 0
    const/4 v3, 1
    invoke-static {v0, v1, v2, v3}, LPreparationRunner;->check(Ljava/lang/String;Ljava/lang/String;ZZ)V
    const-string v0, "0*x+y"
    const-string v1, "degree=1;surface=y;dx=v(0);dy=v(3ff0000000000000);dz=v(0);notices=0"
    const/4 v2, 0
    const/4 v3, 1
    invoke-static {v0, v1, v2, v3}, LPreparationRunner;->check(Ljava/lang/String;Ljava/lang/String;ZZ)V
    const-string v0, "zero*x+y"
    const-string v1, "degree=1;surface=y;dx=v(0);dy=v(3ff0000000000000);dz=v(0);notices=0"
    const/4 v2, 1
    const/4 v3, 1
    invoke-static {v0, v1, v2, v3}, LPreparationRunner;->check(Ljava/lang/String;Ljava/lang/String;ZZ)V
    const-string v0, "(zero*x+radius)^3"
    const-string v1, "degree=3;surface=v(4020000000000000);dx=v(0);dy=v(0);dz=v(0);notices=0"
    const/4 v2, 1
    const/4 v3, 1
    invoke-static {v0, v1, v2, v3}, LPreparationRunner;->check(Ljava/lang/String;Ljava/lang/String;ZZ)V
    const-string v0, "(zero*x+radius)+(zero*y+radius)"
    const-string v1, "degree=1;surface=s+(v(4000000000000000),v(4000000000000000));dx=v(0);dy=v(0);dz=v(0);notices=0"
    const/4 v2, 1
    const/4 v3, 1
    invoke-static {v0, v1, v2, v3}, LPreparationRunner;->check(Ljava/lang/String;Ljava/lang/String;ZZ)V
    const-string v0, "(zero*x+radius)*(zero*y+radius)"
    const-string v1, "degree=2;surface=s*(v(4000000000000000),v(4000000000000000));dx=v(0);dy=v(0);dz=v(0);notices=0"
    const/4 v2, 1
    const/4 v3, 1
    invoke-static {v0, v1, v2, v3}, LPreparationRunner;->check(Ljava/lang/String;Ljava/lang/String;ZZ)V
    const-string v0, "0-((zero*x+radius)+(zero*y+radius))"
    const-string v1, "degree=1;surface=v(c010000000000000);dx=v(0);dy=v(0);dz=v(0);notices=0"
    const/4 v2, 1
    const/4 v3, 1
    invoke-static {v0, v1, v2, v3}, LPreparationRunner;->check(Ljava/lang/String;Ljava/lang/String;ZZ)V
    const-string v0, "radius+1"
    const-string v1, "degree=0;surface=s+(name(radius),v(3ff0000000000000));dx=v(0);dy=v(0);dz=v(0);notices=0"
    const/4 v2, 0
    const/4 v3, 1
    invoke-static {v0, v1, v2, v3}, LPreparationRunner;->check(Ljava/lang/String;Ljava/lang/String;ZZ)V
    const-string v0, "radius+1"
    const-string v1, "degree=0;surface=v(4008000000000000);dx=v(0);dy=v(0);dz=v(0);notices=0"
    const/4 v2, 1
    const/4 v3, 1
    invoke-static {v0, v1, v2, v3}, LPreparationRunner;->check(Ljava/lang/String;Ljava/lang/String;ZZ)V
    const-string v0, "0*radius*x"
    const-string v1, "degree=1;surface=p*(s*(v(0),name(radius)),x);dx=p+(p*(v(0),x),p*(s*(v(0),name(radius)),v(3ff0000000000000)));dy=p+(p*(v(0),x),p*(s*(v(0),name(radius)),v(0)));dz=p+(p*(v(0),x),p*(s*(v(0),name(radius)),v(0)));notices=0"
    const/4 v2, 0
    const/4 v3, 1
    invoke-static {v0, v1, v2, v3}, LPreparationRunner;->check(Ljava/lang/String;Ljava/lang/String;ZZ)V
    const-string v0, "x/(-0)"
    const-string v1, "degree=1;surface=p/(x,v(8000000000000000));dx=p/(v(3ff0000000000000),v(8000000000000000));dy=p/(v(0),v(8000000000000000));dz=p/(v(0),v(8000000000000000));notices=0"
    const/4 v2, 0
    const/4 v3, 1
    invoke-static {v0, v1, v2, v3}, LPreparationRunner;->check(Ljava/lang/String;Ljava/lang/String;ZZ)V
    const-string v0, "16777217+1"
    const-string v1, "degree=0;surface=v(4170000020000000);dx=v(0);dy=v(0);dz=v(0);notices=0"
    const/4 v2, 0
    const/4 v3, 1
    invoke-static {v0, v1, v2, v3}, LPreparationRunner;->check(Ljava/lang/String;Ljava/lang/String;ZZ)V
    const-string v0, "0/0"
    const-string v1, "degree=0;surface=v(7ff8000000000000);dx=v(0);dy=v(0);dz=v(0);notices=0"
    const/4 v2, 0
    const/4 v3, 1
    invoke-static {v0, v1, v2, v3}, LPreparationRunner;->check(Ljava/lang/String;Ljava/lang/String;ZZ)V
    const-string v0, "0*x^2+y"
    const-string v1, "degree=2;surface=y;dx=v(0);dy=v(3ff0000000000000);dz=v(0);notices=0"
    const/4 v2, 0
    const/4 v3, 1
    invoke-static {v0, v1, v2, v3}, LPreparationRunner;->check(Ljava/lang/String;Ljava/lang/String;ZZ)V
    const-string v0, "x^3"
    const-string v1, "degree=3;surface=p^(x,3);dx=p*(p*(v(4008000000000000),p^(x,2)),v(3ff0000000000000));dy=p*(p*(v(4008000000000000),p^(x,2)),v(0));dz=p*(p*(v(4008000000000000),p^(x,2)),v(0));notices=0"
    const/4 v2, 0
    const/4 v3, 1
    invoke-static {v0, v1, v2, v3}, LPreparationRunner;->check(Ljava/lang/String;Ljava/lang/String;ZZ)V
    const-string v0, "x^16777217"
    const-string v1, "degree=16777217;surface=p^(x,16777217);dx=p*(p*(v(4170000010000000),p^(x,16777216)),v(3ff0000000000000));dy=p*(p*(v(4170000010000000),p^(x,16777216)),v(0));dz=p*(p*(v(4170000010000000),p^(x,16777216)),v(0));notices=0"
    const/4 v2, 0
    const/4 v3, 1
    invoke-static {v0, v1, v2, v3}, LPreparationRunner;->check(Ljava/lang/String;Ljava/lang/String;ZZ)V
    const-string v0, "x^2147483648"
    const-string v1, "degree=0;surface=v(3ff0000000000000);dx=v(0);dy=v(0);dz=v(0);notices=1"
    const/4 v2, 0
    const/4 v3, 0
    invoke-static {v0, v1, v2, v3}, LPreparationRunner;->check(Ljava/lang/String;Ljava/lang/String;ZZ)V
    const-string v0, "x^2147483647*x"
    const-string v1, "preparation error: family degree exceeds original signed32 range: 2147483648"
    const/4 v2, 0
    const/4 v3, 0
    invoke-static {v0, v1, v2, v3}, LPreparationRunner;->check(Ljava/lang/String;Ljava/lang/String;ZZ)V
    const-string v0, "(x^2147483647)^2"
    const-string v1, "preparation error: family degree exceeds original signed32 range: 4294967294"
    const/4 v2, 0
    const/4 v3, 0
    invoke-static {v0, v1, v2, v3}, LPreparationRunner;->check(Ljava/lang/String;Ljava/lang/String;ZZ)V
    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS Explorer semantic preparation on ART"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method
