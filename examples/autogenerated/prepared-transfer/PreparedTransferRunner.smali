.class public LPreparedTransferRunner;
.super Ljava/lang/Object;

.method private static equalLong(JJ)V
    .registers 6
    cmp-long v0, p0, p2
    if-eqz v0, :ok
    sget-object v0, Ljava/lang/System;->err:Ljava/io/PrintStream;
    const-string v1, "FAIL Explorer prepared transfer"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    invoke-virtual {v0, p0, p1}, Ljava/io/PrintStream;->println(J)V
    invoke-virtual {v0, p2, p3}, Ljava/io/PrintStream;->println(J)V
    const/16 v0, 80
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
  :ok
    return-void
.end method

.method private static equalText(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V
    .registers 6
    invoke-virtual {p1, p2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    if-nez v0, :ok
    sget-object v0, Ljava/lang/System;->err:Ljava/io/PrintStream;
    const-string v1, "FAIL Explorer prepared transfer"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    invoke-virtual {v0, p0}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    invoke-virtual {v0, p1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    invoke-virtual {v0, p2}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/16 v0, 80
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
  :ok
    return-void
.end method

.method private static positive(J)V
    .registers 6
    const-wide/16 v0, 0
    cmp-long v2, p0, v0
    if-gtz v2, :ok
    const-wide/16 v0, 1
    invoke-static {p0, p1, v0, v1}, LPreparedTransferRunner;->equalLong(JJ)V
  :ok
    return-void
.end method

.method private static status(J)J
    .registers 5
    const/4 v0, 0
    const/4 v1, 6
    invoke-static {p0, p1, v0, v0, v1}, LCopiedSurfaceObserver;->observe(JIII)J
    move-result-wide v0
    return-wide v0
.end method

# These format existing native fields only; no polynomial semantics live here.
.method private static appendTerm(Ljava/lang/StringBuilder;JII)V
    .registers 10
    const/4 v0, 3
    const/4 v4, 6
  :coordinate
    invoke-static {p1, p2, p3, p4, v0}, LCopiedSurfaceObserver;->observe(JIII)J
    move-result-wide v1
    invoke-virtual {p0, v1, v2}, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
    add-int/lit8 v0, v0, 1
    if-ge v0, v4, :coefficient
    const-string v3, ","
    invoke-virtual {p0, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    goto :coordinate
  :coefficient
    const-string v3, ":"
    invoke-virtual {p0, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    const/4 v0, 2
    invoke-static {p1, p2, p3, p4, v0}, LCopiedSurfaceObserver;->observe(JIII)J
    move-result-wide v1
    invoke-static {v1, v2}, Ljava/lang/Long;->toHexString(J)Ljava/lang/String;
    move-result-object v3
    invoke-virtual {p0, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    return-void
.end method

.method private static terms(JI)Ljava/lang/String;
    .registers 10
    const/4 v0, 0
    const/4 v1, 1
    invoke-static {p0, p1, p2, v0, v1}, LCopiedSurfaceObserver;->observe(JIII)J
    move-result-wide v2
    const-wide/16 v5, 0
    const/4 v4, 0
    cmp-long v0, v2, v5
    if-ltz v0, :invalid_count
    long-to-int v4, v2
    int-to-long v5, v4
    cmp-long v0, v2, v5
    if-eqz v0, :count_ok
  :invalid_count
    const-wide/16 v5, 0
    invoke-static {v2, v3, v5, v6}, LPreparedTransferRunner;->equalLong(JJ)V
  :count_ok
    new-instance v0, Ljava/lang/StringBuilder;
    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V
    const/4 v5, 0
  :next
    if-ge v5, v4, :complete
    if-eqz v5, :term
    const-string v1, "|"
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  :term
    invoke-static {v0, p0, p1, p2, v5}, LPreparedTransferRunner;->appendTerm(Ljava/lang/StringBuilder;JII)V
    add-int/lit8 v5, v5, 1
    goto :next
  :complete
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v0
    return-object v0
.end method

.method private static appendPolynomial(Ljava/lang/StringBuilder;Ljava/lang/String;JI)V
    .registers 6
    invoke-virtual {p0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-static {p2, p3, p4}, LPreparedTransferRunner;->terms(JI)Ljava/lang/String;
    move-result-object v0
    invoke-virtual {p0, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    return-void
.end method

.method private static report(J)Ljava/lang/String;
    .registers 8
    new-instance v0, Ljava/lang/StringBuilder;
    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V
    const-string v2, "family="
    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    const/4 v1, 0
    const/4 v2, 0
    const/4 v3, 0
    invoke-static {p0, p1, v1, v2, v3}, LCopiedSurfaceObserver;->observe(JIII)J
    move-result-wide v3
    invoke-virtual {v0, v3, v4}, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
    const/4 v1, 0
    const-string v2, ";surface="
    invoke-static {v0, v2, p0, p1, v1}, LPreparedTransferRunner;->appendPolynomial(Ljava/lang/StringBuilder;Ljava/lang/String;JI)V
    const/4 v1, 1
    const-string v2, ";dx="
    invoke-static {v0, v2, p0, p1, v1}, LPreparedTransferRunner;->appendPolynomial(Ljava/lang/StringBuilder;Ljava/lang/String;JI)V
    const/4 v1, 2
    const-string v2, ";dy="
    invoke-static {v0, v2, p0, p1, v1}, LPreparedTransferRunner;->appendPolynomial(Ljava/lang/StringBuilder;Ljava/lang/String;JI)V
    const/4 v1, 3
    const-string v2, ";dz="
    invoke-static {v0, v2, p0, p1, v1}, LPreparedTransferRunner;->appendPolynomial(Ljava/lang/StringBuilder;Ljava/lang/String;JI)V
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v0
    return-object v0
.end method

.method private static empty()V
    .registers 4
    const-wide/16 v2, 0
    invoke-static {}, LCopiedSurfaceObserver;->liveSnapshots()I
    move-result v0
    int-to-long v0, v0
    invoke-static {v0, v1, v2, v3}, LPreparedTransferRunner;->equalLong(JJ)V
    invoke-static {}, LCopiedSurfaceObserver;->liveTemporaries()I
    move-result v0
    int-to-long v0, v0
    invoke-static {v0, v1, v2, v3}, LPreparedTransferRunner;->equalLong(JJ)V
    invoke-static {}, LCopiedSurfaceObserver;->liveBorrows()I
    move-result v0
    int-to-long v0, v0
    invoke-static {v0, v1, v2, v3}, LPreparedTransferRunner;->equalLong(JJ)V
    invoke-static {}, LCopiedSurfaceObserver;->liveStoreAllocations()I
    move-result v0
    int-to-long v0, v0
    invoke-static {v0, v1, v2, v3}, LPreparedTransferRunner;->equalLong(JJ)V
    return-void
.end method

.method private static oneLive()V
    .registers 4
    invoke-static {}, LCopiedSurfaceObserver;->liveSnapshots()I
    move-result v0
    int-to-long v0, v0
    const-wide/16 v2, 1
    invoke-static {v0, v1, v2, v3}, LPreparedTransferRunner;->equalLong(JJ)V
    invoke-static {}, LCopiedSurfaceObserver;->liveStoreAllocations()I
    move-result v0
    int-to-long v0, v0
    const-wide/16 v2, 2
    invoke-static {v0, v1, v2, v3}, LPreparedTransferRunner;->equalLong(JJ)V
    invoke-static {}, LCopiedSurfaceObserver;->liveTemporaries()I
    move-result v0
    int-to-long v0, v0
    const-wide/16 v2, 0
    invoke-static {v0, v1, v2, v3}, LPreparedTransferRunner;->equalLong(JJ)V
    invoke-static {}, LCopiedSurfaceObserver;->liveBorrows()I
    move-result v0
    int-to-long v0, v0
    invoke-static {v0, v1, v2, v3}, LPreparedTransferRunner;->equalLong(JJ)V
    return-void
.end method

.method private static releaseChecked(J)V
    .registers 6
    invoke-static {p0, p1}, LIdric/Generated;->releasePreparedSurface(J)I
    move-result v0
    int-to-long v0, v0
    const-wide/16 v2, 0
    invoke-static {v0, v1, v2, v3}, LPreparedTransferRunner;->equalLong(JJ)V
    invoke-static {p0, p1}, LPreparedTransferRunner;->status(J)J
    move-result-wide v0
    const-wide/16 v2, 2
    invoke-static {v0, v1, v2, v3}, LPreparedTransferRunner;->equalLong(JJ)V
    invoke-static {p0, p1}, LIdric/Generated;->releasePreparedSurface(J)I
    move-result v0
    int-to-long v0, v0
    invoke-static {v0, v1, v2, v3}, LPreparedTransferRunner;->equalLong(JJ)V
    return-void
.end method

.method private static checkExpected(Ljava/lang/String;Ljava/lang/String;)V
    .registers 10
    invoke-static {p0}, LIdric/Generated;->actual_prepare_handle(Ljava/lang/String;)J
    move-result-wide v0
    invoke-static {v0, v1}, LPreparedTransferRunner;->positive(J)V
    invoke-static {v0, v1}, LPreparedTransferRunner;->status(J)J
    move-result-wide v3
    const-wide/16 v5, 0
    invoke-static {v3, v4, v5, v6}, LPreparedTransferRunner;->equalLong(JJ)V
    invoke-static {v0, v1}, LPreparedTransferRunner;->report(J)Ljava/lang/String;
    move-result-object v2
    invoke-static {v0, v1}, LPreparedTransferRunner;->releaseChecked(J)V
    invoke-static {}, LPreparedTransferRunner;->empty()V
    invoke-static {p0, p1, v2}, LPreparedTransferRunner;->equalText(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V
    return-void
.end method

.method private static check(Ljava/lang/String;)V
    .registers 3
    invoke-static {p0}, Lde/mfo/jsurf/algebra/OriginalExpansionOracle;->original_expansion(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    invoke-static {p0, v0}, LPreparedTransferRunner;->checkExpected(Ljava/lang/String;Ljava/lang/String;)V
    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    invoke-virtual {v0, p0}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method

.method private static error(Ljava/lang/String;Ljava/lang/String;)V
    .registers 4
    invoke-static {p0}, LIdric/Generated;->actual_prepare_error(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    invoke-static {p0, p1, v0}, LPreparedTransferRunner;->equalText(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V
    return-void
.end method

.method private static sourceValidation()V
    .registers 6
    invoke-static {}, LCopiedSurfaceObserver;->copyCalls()J
    move-result-wide v2
    const-string v0, "x/y"
    const-string v1, "meaning error: polynomial divisor"
    invoke-static {v0, v1}, LPreparedTransferRunner;->error(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "radius*x"
    const-string v1, "expansion error: no value has been assigned to parameter 'radius'"
    invoke-static {v0, v1}, LPreparedTransferRunner;->error(Ljava/lang/String;Ljava/lang/String;)V
    invoke-static {}, LCopiedSurfaceObserver;->copyCalls()J
    move-result-wide v4
    invoke-static {v2, v3, v4, v5}, LPreparedTransferRunner;->equalLong(JJ)V
    invoke-static {}, LPreparedTransferRunner;->empty()V
    return-void
.end method

.method private static cycle(Ljava/lang/String;Ljava/lang/String;J)V
    .registers 10
    invoke-static {}, LCopiedSurfaceObserver;->copyCalls()J
    move-result-wide v2
    invoke-static {p0}, LIdric/Generated;->actual_replace_cycle(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    invoke-static {p0, p1, v0}, LPreparedTransferRunner;->equalText(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V
    invoke-static {}, LCopiedSurfaceObserver;->copyCalls()J
    move-result-wide v4
    sub-long v4, v4, v2
    invoke-static {v4, v5, p2, p3}, LPreparedTransferRunner;->equalLong(JJ)V
    invoke-static {}, LPreparedTransferRunner;->empty()V
    return-void
.end method

# A separately retained valid surface must survive failure of a new transfer.
.method private static allocationFailure(ZI)V
    .registers 14
    const-string v3, "x"
    invoke-static {v3}, LIdric/Generated;->actual_prepare_handle(Ljava/lang/String;)J
    move-result-wide v0
    invoke-static {v0, v1}, LPreparedTransferRunner;->positive(J)V
    if-eqz p0, :temporary_hook
    invoke-static {p1}, LCopiedSurfaceObserver;->failStoreAllocation(I)I
    move-result v4
    goto :hook_set
  :temporary_hook
    invoke-static {p1}, LCopiedSurfaceObserver;->failAllocation(I)I
    move-result v4
  :hook_set
    int-to-long v4, v4
    const-wide/16 v6, 1
    invoke-static {v4, v5, v6, v7}, LPreparedTransferRunner;->equalLong(JJ)V
    const-string v3, "y"
    const-string v9, "native prepared-surface allocation failed"
    invoke-static {v3, v9}, LPreparedTransferRunner;->error(Ljava/lang/String;Ljava/lang/String;)V
    if-eqz p0, :temporary_attempts
    invoke-static {}, LCopiedSurfaceObserver;->storeAllocationAttempts()I
    move-result v4
    goto :attempts_read
  :temporary_attempts
    invoke-static {}, LCopiedSurfaceObserver;->allocationAttempts()I
    move-result v4
  :attempts_read
    int-to-long v4, v4
    add-int/lit8 v8, p1, 1
    int-to-long v6, v8
    invoke-static {v4, v5, v6, v7}, LPreparedTransferRunner;->equalLong(JJ)V
    invoke-static {}, LPreparedTransferRunner;->oneLive()V
    invoke-static {v0, v1}, LPreparedTransferRunner;->report(J)Ljava/lang/String;
    move-result-object v2
    const-string v3, "x"
    const-string v9, "family=1;surface=1,0,0:3ff0000000000000;dx=0,0,0:3ff0000000000000;dy=0,0,0:0;dz=0,0,0:0"
    invoke-static {v3, v9, v2}, LPreparedTransferRunner;->equalText(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V
    const/4 v8, -1
    if-eqz p0, :temporary_disable
    invoke-static {v8}, LCopiedSurfaceObserver;->failStoreAllocation(I)I
    move-result v4
    goto :hook_disabled
  :temporary_disable
    invoke-static {v8}, LCopiedSurfaceObserver;->failAllocation(I)I
    move-result v4
  :hook_disabled
    int-to-long v4, v4
    const-wide/16 v6, 1
    invoke-static {v4, v5, v6, v7}, LPreparedTransferRunner;->equalLong(JJ)V
    invoke-static {v0, v1}, LPreparedTransferRunner;->releaseChecked(J)V
    invoke-static {}, LPreparedTransferRunner;->empty()V
    return-void
.end method

.method public static main([Ljava/lang/String;)V
    .registers 5
    const/4 v0, 0
    aget-object v1, p0, v0
    const-string v0, "ave.prepared.library"
    invoke-static {v0, v1}, Ljava/lang/System;->setProperty(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    # The candidate's real class initializer loads the same .so subsequently
    # resolved by CopiedSurfaceObserver in this shared process/class loader.
    const-string v0, "Idric.Generated"
    invoke-static {v0}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;
    invoke-static {}, LPreparedTransferRunner;->empty()V
    const-string v0, "x"
    const-string v1, "family=1;surface=1,0,0:3ff0000000000000;dx=0,0,0:3ff0000000000000;dy=0,0,0:0;dz=0,0,0:0"
    invoke-static {v0}, Lde/mfo/jsurf/algebra/OriginalExpansionOracle;->original_expansion(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v2
    invoke-static {v0, v1, v2}, LPreparedTransferRunner;->equalText(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V
    invoke-static {v0, v1}, LPreparedTransferRunner;->checkExpected(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "x^2+y^2+z^2-0.64"
    invoke-static {v0}, LPreparedTransferRunner;->check(Ljava/lang/String;)V
    const-string v0, "(x^2+y^2+z^2+0.36)^2-1.69*(x^2+y^2)"
    invoke-static {v0}, LPreparedTransferRunner;->check(Ljava/lang/String;)V
    const-string v0, "x^2+y^2+z^2+2*x*y*z-1"
    invoke-static {v0}, LPreparedTransferRunner;->check(Ljava/lang/String;)V
    const-string v0, "x^2-y^2*z"
    invoke-static {v0}, LPreparedTransferRunner;->check(Ljava/lang/String;)V
    const-string v0, "x^2*y^2+y^2*z^2+z^2*x^2-x*y*z"
    invoke-static {v0}, LPreparedTransferRunner;->check(Ljava/lang/String;)V
    const-string v0, "(x^2+2.25*y^2+z^2-1)^3-x^2*z^3-0.1125*y^2*z^3"
    invoke-static {v0}, LPreparedTransferRunner;->check(Ljava/lang/String;)V
    const-string v0, "x^2+x*z^2+y^3"
    invoke-static {v0}, LPreparedTransferRunner;->check(Ljava/lang/String;)V
    const-string v0, "x^4-x*y^3-z^4+z"
    invoke-static {v0}, LPreparedTransferRunner;->check(Ljava/lang/String;)V
    const-string v0, "x^2-x^2+y"
    invoke-static {v0}, LPreparedTransferRunner;->check(Ljava/lang/String;)V
    const-string v0, "(3*x+2)/10"
    invoke-static {v0}, LPreparedTransferRunner;->check(Ljava/lang/String;)V
    const-string v0, "(-10000000000000000+x+x^2+10000000000000000*x^3)*(1+x+x^2+x^3)"
    invoke-static {v0}, LPreparedTransferRunner;->check(Ljava/lang/String;)V
    invoke-static {}, LPreparedTransferRunner;->sourceValidation()V
    const-string v0, "x"
    const-string v1, "accepted and released"
    invoke-static {v0, v1}, LPreparedTransferRunner;->error(Ljava/lang/String;Ljava/lang/String;)V
    invoke-static {}, LPreparedTransferRunner;->empty()V
    const-string v0, "y"
    const-string v1, "replaced and released"
    const-wide/16 v2, 2
    invoke-static {v0, v1, v2, v3}, LPreparedTransferRunner;->cycle(Ljava/lang/String;Ljava/lang/String;J)V
    const-string v0, "x/y"
    const-string v1, "replacement rejected: meaning error: polynomial divisor"
    const-wide/16 v2, 1
    invoke-static {v0, v1, v2, v3}, LPreparedTransferRunner;->cycle(Ljava/lang/String;Ljava/lang/String;J)V
    const/4 v0, 0
    const/4 v1, 0
    invoke-static {v0, v1}, LPreparedTransferRunner;->allocationFailure(ZI)V
    const/4 v1, 1
    invoke-static {v0, v1}, LPreparedTransferRunner;->allocationFailure(ZI)V
    const/4 v0, 1
    const/4 v1, 0
    invoke-static {v0, v1}, LPreparedTransferRunner;->allocationFailure(ZI)V
    const/4 v1, 1
    invoke-static {v0, v1}, LPreparedTransferRunner;->allocationFailure(ZI)V
    invoke-static {}, LPreparedTransferRunner;->empty()V
    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS Explorer actual prepared transfer on ART"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method
