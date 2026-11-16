.class public final LRenderedBitmapRunner;
.super Ljava/lang/Object;

.method private static equalInt(II)V
    .registers 4
    if-eq p0, p1, :ok
    const-string v0, "integer status/count differs"
    invoke-static {v0}, LRenderBitmapObserver;->fail(Ljava/lang/String;)V
  :ok
    return-void
.end method

.method private static equalLong(JJ)V
    .registers 6
    cmp-long v0, p0, p2
    if-eqz v0, :ok
    sget-object v0, Ljava/lang/System;->err:Ljava/io/PrintStream;
    invoke-virtual {v0, p0, p1}, Ljava/io/PrintStream;->println(J)V
    invoke-virtual {v0, p2, p3}, Ljava/io/PrintStream;->println(J)V
    const-string v1, "native actor/count differs"
    invoke-static {v1}, LRenderBitmapObserver;->fail(Ljava/lang/String;)V
  :ok
    return-void
.end method

.method private static equalText(Ljava/lang/String;Ljava/lang/String;)V
    .registers 4
    if-eqz p0, :invalid
    invoke-virtual {p0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    if-nez v0, :ok
  :invalid
    sget-object v0, Ljava/lang/System;->err:Ljava/io/PrintStream;
    invoke-virtual {v0, p0}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    invoke-virtual {v0, p1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const-string v1, "source render result differs"
    invoke-static {v1}, LRenderBitmapObserver;->fail(Ljava/lang/String;)V
  :ok
    return-void
.end method

.method private static positive(J)V
    .registers 4
    const-wide/16 v0, 0
    cmp-long v0, p0, v0
    if-gtz v0, :ok
    const-string v0, "real source preparation did not produce a positive handle"
    invoke-static {v0}, LRenderBitmapObserver;->fail(Ljava/lang/String;)V
  :ok
    return-void
.end method

.method private static empty()V
    .registers 4
    const-wide/16 v2, 0
    invoke-static {}, LRenderPixelObserver;->liveFrames()I
    move-result v0
    int-to-long v0, v0
    invoke-static {v0, v1, v2, v3}, LRenderedBitmapRunner;->equalLong(JJ)V
    invoke-static {}, LRenderPixelObserver;->liveBorrows()I
    move-result v0
    int-to-long v0, v0
    invoke-static {v0, v1, v2, v3}, LRenderedBitmapRunner;->equalLong(JJ)V
    invoke-static {}, LCopiedSurfaceObserver;->liveSnapshots()I
    move-result v0
    int-to-long v0, v0
    invoke-static {v0, v1, v2, v3}, LRenderedBitmapRunner;->equalLong(JJ)V
    invoke-static {}, LCopiedSurfaceObserver;->liveTemporaries()I
    move-result v0
    int-to-long v0, v0
    invoke-static {v0, v1, v2, v3}, LRenderedBitmapRunner;->equalLong(JJ)V
    invoke-static {}, LCopiedSurfaceObserver;->liveStoreAllocations()I
    move-result v0
    int-to-long v0, v0
    invoke-static {v0, v1, v2, v3}, LRenderedBitmapRunner;->equalLong(JJ)V
    return-void
.end method

# Existing real native renderer supplies the expected primitive array. This
# runner contains no surface preparation, derivative, AA or pixel algorithm.
.method private static reference(Ljava/lang/String;I)[I
    .registers 16
    invoke-static {p0}, LIdric/Generated;->actual_render_prepare(Ljava/lang/String;)J
    move-result-wide v0
    invoke-static {v0, v1}, LRenderedBitmapRunner;->positive(J)V
    const/16 v2, 1147
    new-array v13, v2, [I
    const/16 v2, 37
    const/16 v3, 31
    move v4, p1
    const-wide v5, 0x4001333333333333L
    const-wide v7, 0x3fd7ae147ae147aeL
    const-wide v9, -0x4037ae147ae147aeL
    const-wide v11, 0x3ff199999999999aL
    invoke-static/range {v0 .. v13}, LRenderPixelObserver;->receiverRender(JIIIDDDD[I)I
    move-result v14
    const/4 v15, 0
    invoke-static {v14, v15}, LRenderedBitmapRunner;->equalInt(II)V
    invoke-static {v0, v1}, LIdric/Generated;->releasePreparedSurface(J)I
    move-result v14
    invoke-static {v14, v15}, LRenderedBitmapRunner;->equalInt(II)V
    invoke-static {}, LRenderedBitmapRunner;->empty()V
    return-object v13
.end method

.method private static success(Ljava/lang/String;II)V
    .registers 12
    invoke-static {p0, p2}, LRenderedBitmapRunner;->reference(Ljava/lang/String;I)[I
    move-result-object v0
    if-eqz p2, :configured_quality
    invoke-static {v0}, LRenderBitmapObserver;->assertDifferent([I)V
  :configured_quality
    invoke-static {v0}, LRenderBitmapObserver;->configure([I)V
    invoke-static {}, LRenderBitmapObserver;->observations()I
    move-result v1
    invoke-static {}, LRenderPixelObserver;->publications()J
    move-result-wide v2
    invoke-static {}, LRenderPixelObserver;->renderCalls()J
    move-result-wide v4
    invoke-static {p0, p1}, LIdric/Generated;->actual_render_check(Ljava/lang/String;I)Ljava/lang/String;
    move-result-object v0
    const-string v6, "rendered and observed"
    invoke-static {v0, v6}, LRenderedBitmapRunner;->equalText(Ljava/lang/String;Ljava/lang/String;)V
    invoke-static {}, LRenderBitmapObserver;->observations()I
    move-result v0
    add-int/lit8 v1, v1, 1
    invoke-static {v0, v1}, LRenderedBitmapRunner;->equalInt(II)V
    const-wide/16 v7, 1
    add-long v2, v2, v7
    invoke-static {}, LRenderPixelObserver;->publications()J
    move-result-wide v7
    invoke-static {v7, v8, v2, v3}, LRenderedBitmapRunner;->equalLong(JJ)V
    const-wide/16 v7, 1
    add-long v4, v4, v7
    invoke-static {}, LRenderPixelObserver;->renderCalls()J
    move-result-wide v7
    invoke-static {v7, v8, v4, v5}, LRenderedBitmapRunner;->equalLong(JJ)V
    invoke-static {}, LRenderedBitmapRunner;->empty()V
    return-void
.end method

.method private static failure(Ljava/lang/String;ILjava/lang/String;I)V
    .registers 14
    invoke-static {}, LRenderBitmapObserver;->last()Landroid/graphics/Bitmap;
    move-result-object v0
    invoke-static {}, LRenderBitmapObserver;->observations()I
    move-result v1
    invoke-static {}, LRenderPixelObserver;->renderCalls()J
    move-result-wide v2
    invoke-static {}, LRenderPixelObserver;->publications()J
    move-result-wide v4
    invoke-static {p0, p1}, LIdric/Generated;->actual_render_check(Ljava/lang/String;I)Ljava/lang/String;
    move-result-object v6
    invoke-static {v6, p2}, LRenderedBitmapRunner;->equalText(Ljava/lang/String;Ljava/lang/String;)V
    int-to-long v8, p3
    add-long v2, v2, v8
    invoke-static {}, LRenderPixelObserver;->renderCalls()J
    move-result-wide v6
    invoke-static {v6, v7, v2, v3}, LRenderedBitmapRunner;->equalLong(JJ)V
    invoke-static {}, LRenderPixelObserver;->publications()J
    move-result-wide v6
    invoke-static {v6, v7, v4, v5}, LRenderedBitmapRunner;->equalLong(JJ)V
    invoke-static {v0, v1}, LRenderBitmapObserver;->assertRetained(Landroid/graphics/Bitmap;I)V
    invoke-static {}, LRenderedBitmapRunner;->empty()V
    return-void
.end method

.method private static sourceFailure()V
    .registers 5
    invoke-static {}, LCopiedSurfaceObserver;->copyCalls()J
    move-result-wide v0
    const-string v2, "x/y"
    const-string v3, "preparation error: meaning error: polynomial divisor"
    const/4 v4, 0
    invoke-static {v2, v4, v3, v4}, LRenderedBitmapRunner;->failure(Ljava/lang/String;ILjava/lang/String;I)V
    invoke-static {}, LCopiedSurfaceObserver;->copyCalls()J
    move-result-wide v2
    invoke-static {v0, v1, v2, v3}, LRenderedBitmapRunner;->equalLong(JJ)V
    return-void
.end method

.method private static oneLive()V
    .registers 4
    invoke-static {}, LCopiedSurfaceObserver;->liveSnapshots()I
    move-result v0
    int-to-long v0, v0
    const-wide/16 v2, 1
    invoke-static {v0, v1, v2, v3}, LRenderedBitmapRunner;->equalLong(JJ)V
    invoke-static {}, LCopiedSurfaceObserver;->liveStoreAllocations()I
    move-result v0
    int-to-long v0, v0
    const-wide/16 v2, 2
    invoke-static {v0, v1, v2, v3}, LRenderedBitmapRunner;->equalLong(JJ)V
    const-wide/16 v2, 0
    invoke-static {}, LRenderPixelObserver;->liveFrames()I
    move-result v0
    int-to-long v0, v0
    invoke-static {v0, v1, v2, v3}, LRenderedBitmapRunner;->equalLong(JJ)V
    invoke-static {}, LRenderPixelObserver;->liveBorrows()I
    move-result v0
    int-to-long v0, v0
    invoke-static {v0, v1, v2, v3}, LRenderedBitmapRunner;->equalLong(JJ)V
    invoke-static {}, LCopiedSurfaceObserver;->liveTemporaries()I
    move-result v0
    int-to-long v0, v0
    invoke-static {v0, v1, v2, v3}, LRenderedBitmapRunner;->equalLong(JJ)V
    return-void
.end method

.method private static sentinelUnchanged([II)V
    .registers 6
    array-length v1, p0
    const/4 v0, 0
  :next
    if-ge v0, v1, :complete
    aget v2, p0, v0
    if-ne v2, p1, :changed
    add-int/lit8 v0, v0, 1
    goto :next
  :changed
    const-string v3, "malformed JNI output call changed sentinel pixels"
    invoke-static {v3}, LRenderBitmapObserver;->fail(Ljava/lang/String;)V
  :complete
    return-void
.end method

.method private static sentinelChanged([II)V
    .registers 6
    array-length v1, p0
    const/4 v0, 0
  :next
    if-ge v0, v1, :unchanged
    aget v2, p0, v0
    if-ne v2, p1, :complete
    add-int/lit8 v0, v0, 1
    goto :next
  :unchanged
    const-string v3, "valid retained handle did not publish any pixels"
    invoke-static {v3}, LRenderBitmapObserver;->fail(Ljava/lang/String;)V
  :complete
    return-void
.end method

# Fixed14-word direct receiver payload; no generated candidate is replaced.
.method private static receiver(J[II)I
    .registers 16
    move-wide v0, p0
    const/16 v2, 37
    const/16 v3, 31
    move v4, p3
    const-wide v5, 0x4001333333333333L
    const-wide v7, 0x3fd7ae147ae147aeL
    const-wide v9, -0x4037ae147ae147aeL
    const-wide v11, 0x3ff199999999999aL
    move-object v13, p2
    invoke-static/range {v0 .. v13}, LRenderPixelObserver;->receiverRender(JIIIDDDD[I)I
    move-result v14
    return v14
.end method

.method private static noFrameAttempt()V
    .registers 2
    invoke-static {}, LRenderPixelObserver;->allocationAttempts()I
    move-result v0
    const/4 v1, 0
    invoke-static {v0, v1}, LRenderedBitmapRunner;->equalInt(II)V
    invoke-static {}, LRenderedBitmapRunner;->oneLive()V
    return-void
.end method

.method private static malformedOutputs()V
    .registers 16
    const-string v2, "y+0.25*x+0.1"
    invoke-static {v2}, LIdric/Generated;->actual_render_prepare(Ljava/lang/String;)J
    move-result-wide v0
    invoke-static {v0, v1}, LRenderedBitmapRunner;->positive(J)V
    invoke-static {}, LRenderedBitmapRunner;->oneLive()V
    const/16 v4, 1146
    new-array v2, v4, [I
    const/16 v4, 1147
    new-array v3, v4, [I
    const v10, 0x13579bdf
    invoke-static {v2, v10}, Ljava/util/Arrays;->fill([II)V
    invoke-static {v3, v10}, Ljava/util/Arrays;->fill([II)V
    invoke-static {}, LRenderPixelObserver;->publications()J
    move-result-wide v6
    invoke-static {}, LRenderPixelObserver;->renderCalls()J
    move-result-wide v8
    # Wrong length refuses without touching either output or frame allocator.
    const/4 v4, -1
    invoke-static {v4}, LRenderPixelObserver;->failFrameAllocation(I)I
    move-result v5
    const/4 v4, 1
    invoke-static {v5, v4}, LRenderedBitmapRunner;->equalInt(II)V
    const/4 v4, 0
    invoke-static {v0, v1, v2, v4}, LRenderedBitmapRunner;->receiver(J[II)I
    move-result v5
    const/4 v4, 2
    invoke-static {v5, v4}, LRenderedBitmapRunner;->equalInt(II)V
    invoke-static {v2, v10}, LRenderedBitmapRunner;->sentinelUnchanged([II)V
    invoke-static {v3, v10}, LRenderedBitmapRunner;->sentinelUnchanged([II)V
    invoke-static {}, LRenderedBitmapRunner;->noFrameAttempt()V
    # Unsupported quality2 uses a correctly sized sentinel output.
    const/4 v4, -1
    invoke-static {v4}, LRenderPixelObserver;->failFrameAllocation(I)I
    move-result v5
    const/4 v4, 1
    invoke-static {v5, v4}, LRenderedBitmapRunner;->equalInt(II)V
    const/4 v4, 2
    invoke-static {v0, v1, v3, v4}, LRenderedBitmapRunner;->receiver(J[II)I
    move-result v5
    invoke-static {v5, v4}, LRenderedBitmapRunner;->equalInt(II)V
    invoke-static {v2, v10}, LRenderedBitmapRunner;->sentinelUnchanged([II)V
    invoke-static {v3, v10}, LRenderedBitmapRunner;->sentinelUnchanged([II)V
    invoke-static {}, LRenderedBitmapRunner;->noFrameAttempt()V
    # Null is a direct malformed receiver call; source nonnull policy stays intact.
    const/4 v4, -1
    invoke-static {v4}, LRenderPixelObserver;->failFrameAllocation(I)I
    move-result v5
    const/4 v4, 1
    invoke-static {v5, v4}, LRenderedBitmapRunner;->equalInt(II)V
    const/4 v4, 0
    const/4 v5, 0
    invoke-static {v0, v1, v5, v4}, LRenderedBitmapRunner;->receiver(J[II)I
    move-result v5
    const/4 v4, 2
    invoke-static {v5, v4}, LRenderedBitmapRunner;->equalInt(II)V
    invoke-static {v2, v10}, LRenderedBitmapRunner;->sentinelUnchanged([II)V
    invoke-static {v3, v10}, LRenderedBitmapRunner;->sentinelUnchanged([II)V
    invoke-static {}, LRenderedBitmapRunner;->noFrameAttempt()V
    const-wide/16 v14, 3
    add-long v8, v8, v14
    invoke-static {}, LRenderPixelObserver;->renderCalls()J
    move-result-wide v12
    invoke-static {v12, v13, v8, v9}, LRenderedBitmapRunner;->equalLong(JJ)V
    invoke-static {}, LRenderPixelObserver;->publications()J
    move-result-wide v12
    invoke-static {v12, v13, v6, v7}, LRenderedBitmapRunner;->equalLong(JJ)V
    # The held real handle must still support a complete native render.
    const/4 v4, 0
    invoke-static {v0, v1, v3, v4}, LRenderedBitmapRunner;->receiver(J[II)I
    move-result v5
    invoke-static {v5, v4}, LRenderedBitmapRunner;->equalInt(II)V
    invoke-static {v3, v10}, LRenderedBitmapRunner;->sentinelChanged([II)V
    const-wide/16 v14, 1
    add-long v6, v6, v14
    add-long v8, v8, v14
    invoke-static {}, LRenderPixelObserver;->publications()J
    move-result-wide v12
    invoke-static {v12, v13, v6, v7}, LRenderedBitmapRunner;->equalLong(JJ)V
    invoke-static {}, LRenderPixelObserver;->renderCalls()J
    move-result-wide v12
    invoke-static {v12, v13, v8, v9}, LRenderedBitmapRunner;->equalLong(JJ)V
    invoke-static {}, LRenderedBitmapRunner;->oneLive()V
    invoke-static {v0, v1}, LIdric/Generated;->releasePreparedSurface(J)I
    move-result v5
    const/4 v4, 0
    invoke-static {v5, v4}, LRenderedBitmapRunner;->equalInt(II)V
    invoke-static {}, LRenderedBitmapRunner;->empty()V
    return-void
.end method

.method private static run([Ljava/lang/String;)V
    .registers 6
    const/4 v0, 0
    aget-object v1, p0, v0
    const-string v0, "ave.prepared.library"
    invoke-static {v0, v1}, Ljava/lang/System;->setProperty(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    const-string v0, "Idric.Generated"
    invoke-static {v0}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;
    invoke-static {}, LRenderedBitmapRunner;->empty()V
    const-string v0, "y+0.25*x+0.1"
    const/4 v1, 0
    const/4 v2, 0
    invoke-static {v0, v1, v2}, LRenderedBitmapRunner;->success(Ljava/lang/String;II)V
    const/4 v1, 4
    const/4 v2, 1
    invoke-static {v0, v1, v2}, LRenderedBitmapRunner;->success(Ljava/lang/String;II)V
    invoke-static {}, LRenderedBitmapRunner;->sourceFailure()V
    const/4 v1, 1
    const-string v2, "render dimensions must be at least two"
    const/4 v3, 0
    invoke-static {v0, v1, v2, v3}, LRenderedBitmapRunner;->failure(Ljava/lang/String;ILjava/lang/String;I)V
    const/4 v1, 2
    const-string v2, "native render rejected invalid input"
    const/4 v3, 1
    invoke-static {v0, v1, v2, v3}, LRenderedBitmapRunner;->failure(Ljava/lang/String;ILjava/lang/String;I)V
    const/4 v1, 3
    invoke-static {v0, v1, v2, v3}, LRenderedBitmapRunner;->failure(Ljava/lang/String;ILjava/lang/String;I)V
    const/4 v1, 0
    invoke-static {v1}, LRenderPixelObserver;->failFrameAllocation(I)I
    move-result v4
    const/4 v2, 1
    invoke-static {v4, v2}, LRenderedBitmapRunner;->equalInt(II)V
    const-string v2, "native render allocation failed"
    invoke-static {v0, v1, v2, v3}, LRenderedBitmapRunner;->failure(Ljava/lang/String;ILjava/lang/String;I)V
    invoke-static {}, LRenderPixelObserver;->allocationAttempts()I
    move-result v4
    const/4 v2, 1
    invoke-static {v4, v2}, LRenderedBitmapRunner;->equalInt(II)V
    const/4 v1, -1
    invoke-static {v1}, LRenderPixelObserver;->failFrameAllocation(I)I
    move-result v4
    invoke-static {v4, v2}, LRenderedBitmapRunner;->equalInt(II)V
    invoke-static {}, LRenderedBitmapRunner;->empty()V
    invoke-static {}, LRenderedBitmapRunner;->malformedOutputs()V
    sget-object v1, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v0, "PASS Explorer actual rendered Bitmap on ART"
    invoke-virtual {v1, v0}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method

.method public static main([Ljava/lang/String;)V
    .registers 3
  :run_begin
    invoke-static {p0}, LRenderedBitmapRunner;->run([Ljava/lang/String;)V
  :run_end
    return-void
  :unexpected
    move-exception v0
    sget-object v1, Ljava/lang/System;->err:Ljava/io/PrintStream;
    invoke-virtual {v0, v1}, Ljava/lang/Throwable;->printStackTrace(Ljava/io/PrintStream;)V
    const-string v0, "FAIL Explorer rendered Bitmap unexpected Throwable"
    invoke-virtual {v1, v0}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/16 v0, 82
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
    return-void
    .catch Ljava/lang/Throwable; {:run_begin .. :run_end} :unexpected
.end method
