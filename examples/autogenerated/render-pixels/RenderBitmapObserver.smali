.class public final LRenderBitmapObserver;
.super Ljava/lang/Object;

.field private static expected:[I
.field private static lastPixels:[I
.field private static lastBitmap:Landroid/graphics/Bitmap;
.field private static count:I

.method public static fail(Ljava/lang/String;)V
    .registers 3
    sget-object v0, Ljava/lang/System;->err:Ljava/io/PrintStream;
    const-string v1, "FAIL Explorer rendered Bitmap"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    invoke-virtual {v0, p0}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/16 v0, 81
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
    return-void
.end method

.method public static configure([I)V
    .registers 4
    if-eqz p0, :invalid
    const/16 v0, 1147
    array-length v1, p0
    if-ne v0, v1, :invalid
    invoke-static {p0, v0}, Ljava/util/Arrays;->copyOf([II)[I
    move-result-object v1
    sput-object v1, LRenderBitmapObserver;->expected:[I
    return-void
  :invalid
    const-string v2, "expected native pixel array must contain37x31 pixels"
    invoke-static {v2}, LRenderBitmapObserver;->fail(Ljava/lang/String;)V
    return-void
.end method

.method public static assertDifferent([I)V
    .registers 3
    sget-object v0, LRenderBitmapObserver;->expected:[I
    if-eqz v0, :invalid
    if-eqz p0, :invalid
    invoke-static {v0, p0}, Ljava/util/Arrays;->equals([I[I)Z
    move-result v0
    if-eqz v0, :ok
  :invalid
    const-string v1, "Interactive and Final native reference must be distinguishable"
    invoke-static {v1}, LRenderBitmapObserver;->fail(Ljava/lang/String;)V
  :ok
    return-void
.end method

.method private static checkPixels(Landroid/graphics/Bitmap;[I)V
    .registers 9
    if-eqz p0, :invalid_bitmap
    if-eqz p1, :invalid_expected
    invoke-virtual {p0}, Landroid/graphics/Bitmap;->isRecycled()Z
    move-result v0
    if-nez v0, :invalid_bitmap
    invoke-virtual {p0}, Landroid/graphics/Bitmap;->getWidth()I
    move-result v0
    const/16 v1, 37
    if-ne v0, v1, :invalid_size
    invoke-virtual {p0}, Landroid/graphics/Bitmap;->getHeight()I
    move-result v0
    const/16 v1, 31
    if-ne v0, v1, :invalid_size
    const/16 v3, 31
    const/16 v4, 37
    const/4 v0, 0
    const/4 v2, 0
  :next_row
    if-ge v0, v3, :complete
    const/4 v1, 0
  :next_pixel
    if-ge v1, v4, :row_complete
    invoke-virtual {p0, v1, v0}, Landroid/graphics/Bitmap;->getPixel(II)I
    move-result v5
    aget v6, p1, v2
    if-ne v5, v6, :invalid_pixel
    add-int/lit8 v1, v1, 1
    add-int/lit8 v2, v2, 1
    goto :next_pixel
  :row_complete
    add-int/lit8 v0, v0, 1
    goto :next_row
  :complete
    return-void
  :invalid_bitmap
    const-string v0, "observed Bitmap is null or recycled"
    invoke-static {v0}, LRenderBitmapObserver;->fail(Ljava/lang/String;)V
    return-void
  :invalid_expected
    const-string v0, "Bitmap observation has no configured expected pixels"
    invoke-static {v0}, LRenderBitmapObserver;->fail(Ljava/lang/String;)V
    return-void
  :invalid_size
    const-string v0, "actual Bitmap dimensions differ from37x31"
    invoke-static {v0}, LRenderBitmapObserver;->fail(Ljava/lang/String;)V
    return-void
  :invalid_pixel
    const-string v0, "actual Bitmap pixel differs from independent native reference"
    invoke-static {v0}, LRenderBitmapObserver;->fail(Ljava/lang/String;)V
    return-void
.end method

.method public static observe(Landroid/graphics/Bitmap;)V
    .registers 4
    sget-object v0, LRenderBitmapObserver;->expected:[I
    invoke-static {p0, v0}, LRenderBitmapObserver;->checkPixels(Landroid/graphics/Bitmap;[I)V
    sput-object p0, LRenderBitmapObserver;->lastBitmap:Landroid/graphics/Bitmap;
    sput-object v0, LRenderBitmapObserver;->lastPixels:[I
    sget v1, LRenderBitmapObserver;->count:I
    add-int/lit8 v1, v1, 1
    sput v1, LRenderBitmapObserver;->count:I
    return-void
.end method

.method public static last()Landroid/graphics/Bitmap;
    .registers 1
    sget-object v0, LRenderBitmapObserver;->lastBitmap:Landroid/graphics/Bitmap;
    return-object v0
.end method

.method public static observations()I
    .registers 1
    sget v0, LRenderBitmapObserver;->count:I
    return v0
.end method

.method public static assertRetained(Landroid/graphics/Bitmap;I)V
    .registers 5
    sget-object v0, LRenderBitmapObserver;->lastBitmap:Landroid/graphics/Bitmap;
    if-ne p0, v0, :invalid
    sget v1, LRenderBitmapObserver;->count:I
    if-ne p1, v1, :invalid
    sget-object v1, LRenderBitmapObserver;->lastPixels:[I
    invoke-static {p0, v1}, LRenderBitmapObserver;->checkPixels(Landroid/graphics/Bitmap;[I)V
    return-void
  :invalid
    const-string v2, "failed frame replaced the previous successful Bitmap"
    invoke-static {v2}, LRenderBitmapObserver;->fail(Ljava/lang/String;)V
    return-void
.end method
