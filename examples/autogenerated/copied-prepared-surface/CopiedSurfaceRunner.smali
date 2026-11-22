.class public final LCopiedSurfaceRunner;
.super Ljava/lang/Object;

.method private static equal(JJ)V
    .registers 6
    cmp-long v0, p0, p2
    if-eqz v0, :ok
    sget-object v0, Ljava/lang/System;->err:Ljava/io/PrintStream;
    const-string v1, "FAIL Explorer copied PreparedSurface"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    invoke-virtual {v0, p0, p1}, Ljava/io/PrintStream;->println(J)V
    invoke-virtual {v0, p2, p3}, Ljava/io/PrintStream;->println(J)V
    const/16 v0, 79
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
  :ok
    return-void
.end method

.method private static copy(I[D[I)J
    .registers 12
    move v0, p0
    const/16 v1, 4096
    const/4 v2, 0
    const/4 v3, 1
    const/4 v4, 2
    const/4 v5, 3
    const/4 v6, 4
    move-object v7, p1
    move-object v8, p2
    invoke-static/range {v0 .. v8}, LCopiedSurfaceObserver;->copy(IIIIIII[D[I)J
    move-result-wide v0
    return-wide v0
.end method

.method private static copyPair([D[I)J
    .registers 11
    const/4 v0, 1
    const/16 v1, 4096
    const/4 v2, 0
    const/4 v3, 2
    const/4 v4, 2
    const/4 v5, 3
    const/4 v6, 4
    move-object v7, p0
    move-object v8, p1
    invoke-static/range {v0 .. v8}, LCopiedSurfaceObserver;->copy(IIIIIII[D[I)J
    move-result-wide v0
    return-wide v0
.end method

.method private static replace(JI[D[I)J
    .registers 16
    move-wide v0, p0
    move v2, p2
    const/16 v3, 8192
    const/4 v4, 0
    const/4 v5, 1
    const/4 v6, 2
    const/4 v7, 3
    const/4 v8, 4
    move-object v9, p3
    move-object v10, p4
    invoke-static/range {v0 .. v10}, LCopiedSurfaceObserver;->replace(JIIIIIII[D[I)J
    move-result-wide v0
    return-wide v0
.end method

.method public static main([Ljava/lang/String;)V
    .registers 16
    const/4 v4, 0
    aget-object v5, p0, v4
    invoke-static {v5}, Ljava/lang/System;->load(Ljava/lang/String;)V
    const/4 v4, 4
    new-array v0, v4, [D
    fill-array-data v0, :coefficients
    const/16 v4, 12
    new-array v1, v4, [I
    fill-array-data v1, :powers
    const/4 v4, 1
    invoke-static {v4, v0, v1}, LCopiedSurfaceRunner;->copy(I[D[I)J
    move-result-wide v2
    const-wide/16 v6, 0
    cmp-long v5, v2, v6
    if-gtz v5, :positive
    const-wide/16 v6, 1
    invoke-static {v2, v3, v6, v7}, LCopiedSurfaceRunner;->equal(JJ)V
  :positive
    # Mutate both input arrays after the production native call.
    const/4 v4, 0
    const-wide/16 v6, 0
    const/4 v5, 4
  :mutate_coefficients
    aput-wide v6, v0, v4
    add-int/lit8 v4, v4, 1
    if-lt v4, v5, :mutate_coefficients
    const/4 v4, 0
    aput v4, v1, v4
    const/4 v5, 2
    invoke-static {v2, v3, v4, v4, v5}, LCopiedSurfaceObserver;->observe(JIII)J
    move-result-wide v6
    const-wide v8, 0x3fd999999999999aL
    invoke-static {v6, v7, v8, v9}, LCopiedSurfaceRunner;->equal(JJ)V
    const/4 v5, 3
    invoke-static {v2, v3, v4, v4, v5}, LCopiedSurfaceObserver;->observe(JIII)J
    move-result-wide v6
    const-wide/16 v8, 256
    invoke-static {v6, v7, v8, v9}, LCopiedSurfaceRunner;->equal(JJ)V
    const/4 v10, 1
    const/4 v5, 2
    invoke-static {v2, v3, v10, v4, v5}, LCopiedSurfaceObserver;->observe(JIII)J
    move-result-wide v6
    const-wide v8, -0x8000000000000000L
    invoke-static {v6, v7, v8, v9}, LCopiedSurfaceRunner;->equal(JJ)V
    const/4 v10, 2
    invoke-static {v2, v3, v10, v4, v5}, LCopiedSurfaceObserver;->observe(JIII)J
    move-result-wide v6
    const-wide v8, 0x4000000000000000L
    invoke-static {v6, v7, v8, v9}, LCopiedSurfaceRunner;->equal(JJ)V
    const/4 v10, 3
    invoke-static {v2, v3, v10, v4, v5}, LCopiedSurfaceObserver;->observe(JIII)J
    move-result-wide v6
    const-wide v8, 0x4008000000000000L
    invoke-static {v6, v7, v8, v9}, LCopiedSurfaceRunner;->equal(JJ)V
    const/4 v5, 0
    invoke-static {v2, v3, v4, v4, v5}, LCopiedSurfaceObserver;->observe(JIII)J
    move-result-wide v6
    const-wide/16 v8, 4096
    invoke-static {v6, v7, v8, v9}, LCopiedSurfaceRunner;->equal(JJ)V
    # Restore input and exercise malformed version, length, null and ordering.
    fill-array-data v0, :coefficients
    fill-array-data v1, :powers
    const/4 v4, 2
    invoke-static {v4, v0, v1}, LCopiedSurfaceRunner;->copy(I[D[I)J
    move-result-wide v6
    const-wide/16 v8, -2
    invoke-static {v6, v7, v8, v9}, LCopiedSurfaceRunner;->equal(JJ)V
    const/16 v4, 11
    new-array v5, v4, [I
    const/4 v4, 1
    invoke-static {v4, v0, v5}, LCopiedSurfaceRunner;->copy(I[D[I)J
    move-result-wide v6
    invoke-static {v6, v7, v8, v9}, LCopiedSurfaceRunner;->equal(JJ)V
    const/4 v5, 0
    invoke-static {v4, v5, v1}, LCopiedSurfaceRunner;->copy(I[D[I)J
    move-result-wide v6
    invoke-static {v6, v7, v8, v9}, LCopiedSurfaceRunner;->equal(JJ)V
    invoke-static {v0, v1}, LCopiedSurfaceRunner;->copyPair([D[I)J
    move-result-wide v6
    invoke-static {v6, v7, v8, v9}, LCopiedSurfaceRunner;->equal(JJ)V
    # With offset0..2 covering two source terms, equal xyz must also refuse.
    const/4 v4, 0
    const/4 v5, 1
    aput v5, v1, v4
    invoke-static {v0, v1}, LCopiedSurfaceRunner;->copyPair([D[I)J
    move-result-wide v6
    invoke-static {v6, v7, v8, v9}, LCopiedSurfaceRunner;->equal(JJ)V
    fill-array-data v1, :powers
    const-wide v6, 0x7ff0000000000000L
    aput-wide v6, v0, v4
    const/4 v4, 1
    invoke-static {v4, v0, v1}, LCopiedSurfaceRunner;->copy(I[D[I)J
    move-result-wide v6
    invoke-static {v6, v7, v8, v9}, LCopiedSurfaceRunner;->equal(JJ)V
    fill-array-data v0, :coefficients
    # Fail each temporary JNI allocation; none may leak or publish a snapshot.
    const/4 v4, 0
    invoke-static {v4}, LCopiedSurfaceObserver;->failAllocation(I)I
    move-result v5
    int-to-long v6, v5
    const-wide/16 v8, 1
    invoke-static {v6, v7, v8, v9}, LCopiedSurfaceRunner;->equal(JJ)V
    const/4 v4, 1
    invoke-static {v4, v0, v1}, LCopiedSurfaceRunner;->copy(I[D[I)J
    move-result-wide v6
    const-wide/16 v8, -3
    invoke-static {v6, v7, v8, v9}, LCopiedSurfaceRunner;->equal(JJ)V
    invoke-static {}, LCopiedSurfaceObserver;->allocationAttempts()I
    move-result v5
    int-to-long v6, v5
    const-wide/16 v8, 1
    invoke-static {v6, v7, v8, v9}, LCopiedSurfaceRunner;->equal(JJ)V
    invoke-static {}, LCopiedSurfaceObserver;->liveTemporaries()I
    move-result v5
    int-to-long v6, v5
    const-wide/16 v8, 0
    invoke-static {v6, v7, v8, v9}, LCopiedSurfaceRunner;->equal(JJ)V
    invoke-static {v4}, LCopiedSurfaceObserver;->failAllocation(I)I
    move-result v5
    int-to-long v6, v5
    const-wide/16 v8, 1
    invoke-static {v6, v7, v8, v9}, LCopiedSurfaceRunner;->equal(JJ)V
    invoke-static {v4, v0, v1}, LCopiedSurfaceRunner;->copy(I[D[I)J
    move-result-wide v6
    const-wide/16 v8, -3
    invoke-static {v6, v7, v8, v9}, LCopiedSurfaceRunner;->equal(JJ)V
    invoke-static {}, LCopiedSurfaceObserver;->allocationAttempts()I
    move-result v5
    int-to-long v6, v5
    const-wide/16 v8, 2
    invoke-static {v6, v7, v8, v9}, LCopiedSurfaceRunner;->equal(JJ)V
    invoke-static {}, LCopiedSurfaceObserver;->liveTemporaries()I
    move-result v5
    int-to-long v6, v5
    const-wide/16 v8, 0
    invoke-static {v6, v7, v8, v9}, LCopiedSurfaceRunner;->equal(JJ)V
    const/4 v4, -1
    invoke-static {v4}, LCopiedSurfaceObserver;->failAllocation(I)I
    move-result v5
    # Bad replacement preserves old handle; successful replacement retires it.
    const/4 v4, 2
    invoke-static {v2, v3, v4, v0, v1}, LCopiedSurfaceRunner;->replace(JI[D[I)J
    move-result-wide v6
    const-wide/16 v8, -2
    invoke-static {v6, v7, v8, v9}, LCopiedSurfaceRunner;->equal(JJ)V
    const/4 v4, 0
    const/4 v5, 6
    invoke-static {v2, v3, v4, v4, v5}, LCopiedSurfaceObserver;->observe(JIII)J
    move-result-wide v6
    const-wide/16 v8, 0
    invoke-static {v6, v7, v8, v9}, LCopiedSurfaceRunner;->equal(JJ)V
    const/4 v4, 1
    invoke-static {v2, v3, v4, v0, v1}, LCopiedSurfaceRunner;->replace(JI[D[I)J
    move-result-wide v10
    invoke-static {v2, v3}, LCopiedSurfaceObserver;->release(J)I
    move-result v5
    int-to-long v6, v5
    const-wide/16 v8, 2
    invoke-static {v6, v7, v8, v9}, LCopiedSurfaceRunner;->equal(JJ)V
    const/4 v4, 0
    invoke-static {v10, v11, v4, v4, v4}, LCopiedSurfaceObserver;->observe(JIII)J
    move-result-wide v6
    const-wide/16 v8, 8192
    invoke-static {v6, v7, v8, v9}, LCopiedSurfaceRunner;->equal(JJ)V
    invoke-static {v10, v11}, LCopiedSurfaceObserver;->release(J)I
    move-result v5
    int-to-long v6, v5
    const-wide/16 v8, 0
    invoke-static {v6, v7, v8, v9}, LCopiedSurfaceRunner;->equal(JJ)V
    invoke-static {v10, v11}, LCopiedSurfaceObserver;->release(J)I
    move-result v5
    int-to-long v6, v5
    const-wide/16 v8, 2
    invoke-static {v6, v7, v8, v9}, LCopiedSurfaceRunner;->equal(JJ)V
    invoke-static {}, LCopiedSurfaceObserver;->liveSnapshots()I
    move-result v5
    int-to-long v6, v5
    const-wide/16 v8, 0
    invoke-static {v6, v7, v8, v9}, LCopiedSurfaceRunner;->equal(JJ)V
    sget-object v5, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v4, "PASS Explorer copied PreparedSurface JNI on ART"
    invoke-virtual {v5, v4}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
  :coefficients
    .array-data 8
        0x3fd999999999999aL
        -0x8000000000000000L
        0x4000000000000000L
        0x4008000000000000L
    .end array-data
  :powers
    .array-data 4
        256
        0
        0
        1
        0
        0
        0
        1
        0
        0
        0
        1
    .end array-data
.end method
