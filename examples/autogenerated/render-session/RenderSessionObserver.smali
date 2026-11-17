.class public final LRenderSessionObserver;
.super Ljava/lang/Object;

.method public static native failCreateAllocation(I)I
.end method

.method public static native failBeginAllocation(I)I
.end method

.method public static native failRenderAllocation(I)I
.end method

.method public static native cancelBeforePublish(I)I
.end method

.method public static native cancelOnCurrent(J)I
.end method

.method public static native createAttempts()I
.end method

.method public static native beginAttempts()I
.end method

.method public static native renderAttempts()I
.end method

.method public static native liveSessions()I
.end method

.method public static native liveEpochs()I
.end method

.method public static native liveAllocations()I
.end method

.method public static native renderCalls()J
.end method

.method public static native publications()J
.end method

.method public static native currentCalls()J
.end method

.method public static native createCalls()J
.end method

.method public static native beginCalls()J
.end method

.method public static native cancelCalls()J
.end method

.method public static native releaseCalls()J
.end method

.method public static native current(JJ)I
.end method

.method public static native receiverRender(JJJIIIDDDD[I)I
.end method

.method public static observeProtocol(JJJ)V
    .registers 10
    const-wide/16 v0, 0
    cmp-long v2, p0, v0
    if-lez v2, :invalid
    cmp-long v2, p2, v0
    if-lez v2, :invalid
    cmp-long v2, p4, v0
    if-lez v2, :invalid
    cmp-long v2, p2, p4
    if-eqz v2, :invalid
    invoke-static {p0, p1, p2, p3}, LRenderSessionObserver;->current(JJ)I
    move-result v2
    if-nez v2, :invalid
    invoke-static {p0, p1, p4, p5}, LRenderSessionObserver;->current(JJ)I
    move-result v2
    const/4 v3, 1
    if-ne v2, v3, :invalid
    invoke-static {}, LRenderSessionObserver;->liveSessions()I
    move-result v2
    if-ne v2, v3, :invalid
    invoke-static {}, LRenderSessionObserver;->liveEpochs()I
    move-result v2
    if-ne v2, v3, :invalid
    return-void
  :invalid
    const-string v2, "independent session/epoch protocol observation failed"
    invoke-static {v2}, LSessionBitmapRunner;->fail(Ljava/lang/String;)V
    return-void
.end method

