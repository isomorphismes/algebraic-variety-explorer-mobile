.class public final LSessionBitmapRunner;
.super Ljava/lang/Object;

.method public static fail(Ljava/lang/String;)V
    .registers 3
    sget-object v0, Ljava/lang/System;->err:Ljava/io/PrintStream;
    const-string v1, "FAIL Explorer render session"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    invoke-virtual {v0, p0}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/16 v0, 83
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
    return-void
.end method

.method private static equalInt(II)V
    .registers 3
    if-eq p0, p1, :ok
    const-string v0, "session status/count differs"
    invoke-static {v0}, LSessionBitmapRunner;->fail(Ljava/lang/String;)V
  :ok
    return-void
.end method

.method private static equalLong(JJ)V
    .registers 6
    cmp-long v0, p0, p2
    if-eqz v0, :ok
    const-string v1, "session native actor/count differs"
    invoke-static {v1}, LSessionBitmapRunner;->fail(Ljava/lang/String;)V
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
    const-string v1, "actual source session result differs"
    invoke-static {v1}, LSessionBitmapRunner;->fail(Ljava/lang/String;)V
  :ok
    return-void
.end method

.method private static positive(J)V
    .registers 4
    const-wide/16 v0, 0
    cmp-long v0, p0, v0
    if-gtz v0, :ok
    const-string v0, "native session, epoch or source surface identity is not positive"
    invoke-static {v0}, LSessionBitmapRunner;->fail(Ljava/lang/String;)V
  :ok
    return-void
.end method

.method private static empty()V
    .registers 2
    const/4 v1, 0
    invoke-static {}, LRenderSessionObserver;->liveSessions()I
    move-result v0
    invoke-static {v0, v1}, LSessionBitmapRunner;->equalInt(II)V
    invoke-static {}, LRenderSessionObserver;->liveEpochs()I
    move-result v0
    invoke-static {v0, v1}, LSessionBitmapRunner;->equalInt(II)V
    invoke-static {}, LRenderSessionObserver;->liveAllocations()I
    move-result v0
    invoke-static {v0, v1}, LSessionBitmapRunner;->equalInt(II)V
    invoke-static {}, LRenderPixelObserver;->liveFrames()I
    move-result v0
    invoke-static {v0, v1}, LSessionBitmapRunner;->equalInt(II)V
    invoke-static {}, LRenderPixelObserver;->liveBorrows()I
    move-result v0
    invoke-static {v0, v1}, LSessionBitmapRunner;->equalInt(II)V
    invoke-static {}, LCopiedSurfaceObserver;->liveSnapshots()I
    move-result v0
    invoke-static {v0, v1}, LSessionBitmapRunner;->equalInt(II)V
    invoke-static {}, LCopiedSurfaceObserver;->liveTemporaries()I
    move-result v0
    invoke-static {v0, v1}, LSessionBitmapRunner;->equalInt(II)V
    invoke-static {}, LCopiedSurfaceObserver;->liveStoreAllocations()I
    move-result v0
    invoke-static {v0, v1}, LSessionBitmapRunner;->equalInt(II)V
    return-void
.end method

# Independent existing fourteen-word renderer supplies all37x31 expected pixels.
.method private static reference(I)[I
    .registers 17
    const-string v0, "y+0.25*x+0.1"
    invoke-static {v0}, LIdric/Generated;->actual_session_prepare(Ljava/lang/String;)J
    move-result-wide v0
    invoke-static {v0, v1}, LSessionBitmapRunner;->positive(J)V
    const/16 v2, 1147
    new-array v13, v2, [I
    const/16 v2, 37
    const/16 v3, 31
    move/from16 v4, p0
    const-wide v5, 0x4001333333333333L
    const-wide v7, 0x3fd7ae147ae147aeL
    const-wide v9, -0x4037ae147ae147aeL
    const-wide v11, 0x3ff199999999999aL
    invoke-static/range {v0 .. v13}, LRenderPixelObserver;->receiverRender(JIIIDDDD[I)I
    move-result v14
    const/4 v15, 0
    invoke-static {v14, v15}, LSessionBitmapRunner;->equalInt(II)V
    invoke-static {v0, v1}, LIdric/Generated;->releasePreparedSurface(J)I
    move-result v14
    invoke-static {v14, v15}, LSessionBitmapRunner;->equalInt(II)V
    invoke-static {}, LSessionBitmapRunner;->empty()V
    return-object v13
.end method

.method private static success(II)V
    .registers 12
    invoke-static {p1}, LSessionBitmapRunner;->reference(I)[I
    move-result-object v0
    if-eqz p1, :configured
    invoke-static {v0}, LRenderBitmapObserver;->assertDifferent([I)V
  :configured
    invoke-static {v0}, LRenderBitmapObserver;->configure([I)V
    invoke-static {}, LRenderBitmapObserver;->observations()I
    move-result v1
    invoke-static {}, LRenderSessionObserver;->renderCalls()J
    move-result-wide v2
    invoke-static {}, LRenderSessionObserver;->publications()J
    move-result-wide v4
    const-string v0, "y+0.25*x+0.1"
    invoke-static {v0, p0}, LIdric/Generated;->actual_session_bitmap(Ljava/lang/String;I)Ljava/lang/String;
    move-result-object v0
    const-string v6, "session bitmap rendered and observed"
    invoke-static {v0, v6}, LSessionBitmapRunner;->equalText(Ljava/lang/String;Ljava/lang/String;)V
    invoke-static {}, LRenderBitmapObserver;->observations()I
    move-result v0
    add-int/lit8 v1, v1, 1
    invoke-static {v0, v1}, LSessionBitmapRunner;->equalInt(II)V
    const-wide/16 v6, 1
    add-long/2addr v2, v6
    add-long/2addr v4, v6
    invoke-static {}, LRenderSessionObserver;->renderCalls()J
    move-result-wide v6
    invoke-static {v6, v7, v2, v3}, LSessionBitmapRunner;->equalLong(JJ)V
    invoke-static {}, LRenderSessionObserver;->publications()J
    move-result-wide v6
    invoke-static {v6, v7, v4, v5}, LSessionBitmapRunner;->equalLong(JJ)V
    invoke-static {}, LSessionBitmapRunner;->empty()V
    return-void
.end method

.method private static failure(ILjava/lang/String;II)V
    .registers 16
    invoke-static {}, LRenderBitmapObserver;->last()Landroid/graphics/Bitmap;
    move-result-object v0
    invoke-static {}, LRenderBitmapObserver;->observations()I
    move-result v1
    invoke-static {}, LRenderSessionObserver;->renderCalls()J
    move-result-wide v2
    invoke-static {}, LRenderSessionObserver;->publications()J
    move-result-wide v4
    const-string v6, "y+0.25*x+0.1"
    invoke-static {v6, p0}, LIdric/Generated;->actual_session_bitmap(Ljava/lang/String;I)Ljava/lang/String;
    move-result-object v6
    invoke-static {v6, p1}, LSessionBitmapRunner;->equalText(Ljava/lang/String;Ljava/lang/String;)V
    int-to-long v8, p2
    add-long/2addr v2, v8
    int-to-long v8, p3
    add-long/2addr v4, v8
    invoke-static {}, LRenderSessionObserver;->renderCalls()J
    move-result-wide v6
    invoke-static {v6, v7, v2, v3}, LSessionBitmapRunner;->equalLong(JJ)V
    invoke-static {}, LRenderSessionObserver;->publications()J
    move-result-wide v6
    invoke-static {v6, v7, v4, v5}, LSessionBitmapRunner;->equalLong(JJ)V
    invoke-static {v0, v1}, LRenderBitmapObserver;->assertRetained(Landroid/graphics/Bitmap;I)V
    invoke-static {}, LSessionBitmapRunner;->empty()V
    return-void
.end method

# Direct independent eighteen-word wire exercises malformed/stale requests.
.method private static receiver(JJJ[II)I
    .registers 27
    move-wide/from16 v0, p0
    move-wide/from16 v2, p2
    move-wide/from16 v4, p4
    move-object/from16 v17, p6
    move/from16 v8, p7
    const/16 v6, 37
    const/16 v7, 31
    const-wide v9, 0x4001333333333333L
    const-wide v11, 0x3fd7ae147ae147aeL
    const-wide v13, -0x4037ae147ae147aeL
    const-wide v15, 0x3ff199999999999aL
    invoke-static/range {v0 .. v17}, LRenderSessionObserver;->receiverRender(JJJIIIDDDD[I)I
    move-result v18
    return v18
.end method

.method private static unchanged([I)V
    .registers 5
    const/4 v0, 0
    array-length v1, p0
    const v3, 0x13579bdf
  :next
    if-ge v0, v1, :done
    aget v2, p0, v0
    if-ne v2, v3, :invalid
    add-int/lit8 v0, v0, 1
    goto :next
  :invalid
    const-string v0, "failed session JNI call changed output pixels"
    invoke-static {v0}, LSessionBitmapRunner;->fail(Ljava/lang/String;)V
  :done
    return-void
.end method

.method private static direct()V
    .registers 16
    invoke-static {}, LIdric/Generated;->createRenderSession()J
    move-result-wide v0
    invoke-static {v0, v1}, LSessionBitmapRunner;->positive(J)V
    invoke-static {v0, v1}, LIdric/Generated;->beginRenderEpoch(J)J
    move-result-wide v2
    invoke-static {v2, v3}, LSessionBitmapRunner;->positive(J)V
    # Failed begin leaves the old real epoch current across the actual JNI.
    const/4 v8, 0
    invoke-static {v8}, LRenderSessionObserver;->failBeginAllocation(I)I
    move-result v9
    const/4 v10, 1
    invoke-static {v9, v10}, LSessionBitmapRunner;->equalInt(II)V
    invoke-static {v0, v1}, LIdric/Generated;->beginRenderEpoch(J)J
    move-result-wide v12
    const-wide/16 v14, -3
    invoke-static {v12, v13, v14, v15}, LSessionBitmapRunner;->equalLong(JJ)V
    invoke-static {v0, v1, v2, v3}, LRenderSessionObserver;->current(JJ)I
    move-result v9
    invoke-static {v9, v10}, LSessionBitmapRunner;->equalInt(II)V
    const/4 v8, -1
    invoke-static {v8}, LRenderSessionObserver;->failBeginAllocation(I)I
    move-result v9
    const-string v4, "y+0.25*x+0.1"
    invoke-static {v4}, LIdric/Generated;->actual_session_prepare(Ljava/lang/String;)J
    move-result-wide v4
    invoke-static {v4, v5}, LSessionBitmapRunner;->positive(J)V
    const/16 v6, 1146
    new-array v6, v6, [I
    invoke-static {}, LRenderSessionObserver;->publications()J
    move-result-wide v12
    const v8, 0x13579bdf
    invoke-static {v6, v8}, Ljava/util/Arrays;->fill([II)V
    const/4 v7, 0
    invoke-static/range {v0 .. v7}, LSessionBitmapRunner;->receiver(JJJ[II)I
    move-result v9
    const/4 v10, 2
    invoke-static {v9, v10}, LSessionBitmapRunner;->equalInt(II)V
    invoke-static {v6}, LSessionBitmapRunner;->unchanged([I)V
    const/16 v6, 1147
    new-array v6, v6, [I
    invoke-static {v6, v8}, Ljava/util/Arrays;->fill([II)V
    const/4 v7, 2
    invoke-static/range {v0 .. v7}, LSessionBitmapRunner;->receiver(JJJ[II)I
    move-result v9
    invoke-static {v9, v10}, LSessionBitmapRunner;->equalInt(II)V
    invoke-static {v6}, LSessionBitmapRunner;->unchanged([I)V
    const/4 v7, 0
    move-object v11, v6
    const/4 v6, 0
    invoke-static/range {v0 .. v7}, LSessionBitmapRunner;->receiver(JJJ[II)I
    move-result v9
    invoke-static {v9, v10}, LSessionBitmapRunner;->equalInt(II)V
    move-object v6, v11
    invoke-static {v6}, LSessionBitmapRunner;->unchanged([I)V
    move-wide v14, v0
    const-wide/16 v0, 0
    invoke-static/range {v0 .. v7}, LSessionBitmapRunner;->receiver(JJJ[II)I
    move-result v9
    invoke-static {v9, v10}, LSessionBitmapRunner;->equalInt(II)V
    move-wide v0, v14
    invoke-static {v6}, LSessionBitmapRunner;->unchanged([I)V
    invoke-static {v0, v1}, LIdric/Generated;->cancelRenderSession(J)I
    move-result v9
    const/4 v7, 0
    invoke-static {v9, v7}, LSessionBitmapRunner;->equalInt(II)V
    invoke-static/range {v0 .. v7}, LSessionBitmapRunner;->receiver(JJJ[II)I
    move-result v9
    const/4 v10, 4
    invoke-static {v9, v10}, LSessionBitmapRunner;->equalInt(II)V
    invoke-static {v6}, LSessionBitmapRunner;->unchanged([I)V
    invoke-static {v0, v1}, LIdric/Generated;->releaseRenderSession(J)I
    move-result v9
    invoke-static {v9, v7}, LSessionBitmapRunner;->equalInt(II)V
    invoke-static/range {v0 .. v7}, LSessionBitmapRunner;->receiver(JJJ[II)I
    move-result v9
    invoke-static {v9, v10}, LSessionBitmapRunner;->equalInt(II)V
    invoke-static {v6}, LSessionBitmapRunner;->unchanged([I)V
    invoke-static {}, LRenderSessionObserver;->publications()J
    move-result-wide v14
    invoke-static {v12, v13, v14, v15}, LSessionBitmapRunner;->equalLong(JJ)V
    invoke-static {v0, v1, v2, v3}, LRenderSessionObserver;->current(JJ)I
    move-result v9
    invoke-static {v9, v7}, LSessionBitmapRunner;->equalInt(II)V
    invoke-static {v4, v5}, LIdric/Generated;->releasePreparedSurface(J)I
    move-result v9
    invoke-static {v9, v7}, LSessionBitmapRunner;->equalInt(II)V
    invoke-static {}, LSessionBitmapRunner;->empty()V
    return-void
.end method

.method private static run([Ljava/lang/String;)V
    .registers 8
    const/4 v0, 0
    aget-object v1, p0, v0
    const-string v0, "ave.prepared.library"
    invoke-static {v0, v1}, Ljava/lang/System;->setProperty(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    const-string v0, "Idric.Generated"
    invoke-static {v0}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;
    invoke-static {}, LSessionBitmapRunner;->empty()V
    invoke-static {}, LIdric/Generated;->actual_session_protocol()Ljava/lang/String;
    move-result-object v0
    const-string v1, "session protocol accepted"
    invoke-static {v0, v1}, LSessionBitmapRunner;->equalText(Ljava/lang/String;Ljava/lang/String;)V
    invoke-static {}, LSessionBitmapRunner;->empty()V
    const/4 v0, 0
    invoke-static {v0, v0}, LSessionBitmapRunner;->success(II)V
    const/4 v0, 4
    const/4 v1, 1
    invoke-static {v0, v1}, LSessionBitmapRunner;->success(II)V
    # Failure requests below use Interactive. Keep the successful Final Bitmap
    # as the retained prior frame, while configuring expected pixels for any
    # illicit new Bitmap from a source mutant.
    const/4 v0, 0
    invoke-static {v0}, LSessionBitmapRunner;->reference(I)[I
    move-result-object v1
    invoke-static {v1}, LRenderBitmapObserver;->configure([I)V
    const-string v1, "render request cancelled"
    const/4 v2, 0
    const/4 v3, 0
    const/4 v0, 1
    invoke-static {v0, v1, v2, v3}, LSessionBitmapRunner;->failure(ILjava/lang/String;II)V
    const/4 v0, 2
    invoke-static {v0, v1, v2, v3}, LSessionBitmapRunner;->failure(ILjava/lang/String;II)V
    const/4 v0, 3
    invoke-static {v0, v1, v2, v3}, LSessionBitmapRunner;->failure(ILjava/lang/String;II)V
    const/4 v0, 5
    const-string v1, "render dimensions must be at least two"
    invoke-static {v0, v1, v2, v3}, LSessionBitmapRunner;->failure(ILjava/lang/String;II)V
    const-string v1, "native render rejected invalid input"
    const/4 v2, 1
    const/4 v0, 6
    invoke-static {v0, v1, v2, v3}, LSessionBitmapRunner;->failure(ILjava/lang/String;II)V
    const/4 v0, 7
    invoke-static {v0, v1, v2, v3}, LSessionBitmapRunner;->failure(ILjava/lang/String;II)V
    # Cancellation at native final gate prevents primitive-array publication.
    const/4 v0, 1
    invoke-static {v0}, LRenderSessionObserver;->cancelBeforePublish(I)I
    move-result v4
    invoke-static {v4, v0}, LSessionBitmapRunner;->equalInt(II)V
    const/4 v0, 0
    const-string v1, "render request cancelled"
    invoke-static {v0, v1, v2, v3}, LSessionBitmapRunner;->failure(ILjava/lang/String;II)V
    invoke-static {v0}, LRenderSessionObserver;->cancelBeforePublish(I)I
    move-result v4
    # Cancellation between committed pixels and source's second query prevents Bitmap.
    const-wide/16 v4, 2
    invoke-static {v4, v5}, LRenderSessionObserver;->cancelOnCurrent(J)I
    move-result v4
    const/4 v3, 1
    invoke-static {v0, v1, v2, v3}, LSessionBitmapRunner;->failure(ILjava/lang/String;II)V
    const-wide/16 v4, 0
    invoke-static {v4, v5}, LRenderSessionObserver;->cancelOnCurrent(J)I
    move-result v4
    # Real staging allocation failure via actual source call.
    invoke-static {v0}, LRenderSessionObserver;->failRenderAllocation(I)I
    move-result v4
    const-string v1, "native render allocation failed"
    const/4 v3, 0
    invoke-static {v0, v1, v2, v3}, LSessionBitmapRunner;->failure(ILjava/lang/String;II)V
    invoke-static {}, LRenderSessionObserver;->renderAttempts()I
    move-result v4
    const/4 v5, 1
    invoke-static {v4, v5}, LSessionBitmapRunner;->equalInt(II)V
    const/4 v4, -1
    invoke-static {v4}, LRenderSessionObserver;->failRenderAllocation(I)I
    move-result v5
    # Actual create and begin allocation failures unwind session/surface state.
    invoke-static {v0}, LRenderSessionObserver;->failCreateAllocation(I)I
    move-result v4
    const-string v1, "render session allocation failed"
    const/4 v2, 0
    invoke-static {v0, v1, v2, v3}, LSessionBitmapRunner;->failure(ILjava/lang/String;II)V
    invoke-static {}, LRenderSessionObserver;->createAttempts()I
    move-result v4
    const/4 v5, 1
    invoke-static {v4, v5}, LSessionBitmapRunner;->equalInt(II)V
    const/4 v4, -1
    invoke-static {v4}, LRenderSessionObserver;->failCreateAllocation(I)I
    move-result v5
    invoke-static {v0}, LRenderSessionObserver;->failBeginAllocation(I)I
    move-result v4
    invoke-static {v0, v1, v2, v3}, LSessionBitmapRunner;->failure(ILjava/lang/String;II)V
    invoke-static {}, LRenderSessionObserver;->beginAttempts()I
    move-result v4
    const/4 v5, 1
    invoke-static {v4, v5}, LSessionBitmapRunner;->equalInt(II)V
    const/4 v4, -1
    invoke-static {v4}, LRenderSessionObserver;->failBeginAllocation(I)I
    move-result v5
    invoke-static {}, LSessionBitmapRunner;->direct()V
    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS Explorer actual render session Bitmap on ART"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method

.method public static main([Ljava/lang/String;)V
    .registers 3
  :begin
    invoke-static {p0}, LSessionBitmapRunner;->run([Ljava/lang/String;)V
  :end
    return-void
  :unexpected
    move-exception v0
    sget-object v1, Ljava/lang/System;->err:Ljava/io/PrintStream;
    invoke-virtual {v0, v1}, Ljava/lang/Throwable;->printStackTrace(Ljava/io/PrintStream;)V
    const-string v0, "FAIL Explorer render session unexpected Throwable"
    invoke-virtual {v1, v0}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/16 v0, 84
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
    return-void
    .catch Ljava/lang/Throwable; {:begin .. :end} :unexpected
.end method

