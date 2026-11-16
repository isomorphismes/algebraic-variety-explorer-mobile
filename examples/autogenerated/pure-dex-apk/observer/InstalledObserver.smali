.class public final Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;
.super Landroid/app/Instrumentation;
.implements Ljava/lang/Runnable;

.field private activity:Landroid/app/Activity;
.field private editor:Landroid/widget/EditText;
.field private image:Landroid/widget/ImageView;
.field private status:Landroid/widget/TextView;
.field private render:Landroid/view/View;
.field private examples:Landroid/view/View;
.field private save:Landroid/view/View;
.field private about:Landroid/view/View;
.field private root:Landroid/view/View;
.field private mode:I
.field private uiError:Ljava/lang/Throwable;
.field private observedBitmap:Landroid/graphics/Bitmap;
.field private observedPixels:[I
.field private observedStatus:Ljava/lang/String;
.field private observedFormula:Ljava/lang/String;
.field private completed:I
.field private negativeControl:Z
.field private negativeApplied:Z
.field private cleanupState:Ljava/lang/String;

.method public constructor <init>()V
    .registers 1
    invoke-direct {p0}, Landroid/app/Instrumentation;-><init>()V
    return-void
.end method

.method public onCreate(Landroid/os/Bundle;)V
    .registers 4
    invoke-super {p0, p1}, Landroid/app/Instrumentation;->onCreate(Landroid/os/Bundle;)V
    if-eqz p1, :start
    const-string v0, "ave_negative_control"
    const-string v1, ""
    invoke-virtual {p1, v0, v1}, Landroid/os/Bundle;->getString(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    const-string v1, "blank_bitmap"
    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    iput-boolean v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->negativeControl:Z
  :start
    invoke-virtual {p0}, Landroid/app/Instrumentation;->start()V
    return-void
.end method

.method private static require(ZLjava/lang/String;)V
    .registers 3
    if-nez p0, :ok
    new-instance v0, Ljava/lang/AssertionError;
    invoke-direct {v0, p1}, Ljava/lang/AssertionError;-><init>(Ljava/lang/Object;)V
    throw v0
  :ok
    return-void
.end method

.method private view(Ljava/lang/String;)Landroid/view/View;
    .registers 7
    iget-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->activity:Landroid/app/Activity;
    invoke-virtual {v0}, Landroid/app/Activity;->getResources()Landroid/content/res/Resources;
    move-result-object v1
    const-string v2, "id"
    const-string v3, "org.algebraicvarietyexplorer"
    invoke-virtual {v1, p1, v2, v3}, Landroid/content/res/Resources;->getIdentifier(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)I
    move-result v1
    const/4 v2, 0
    if-eqz v1, :require
    const/4 v2, 1
  :require
    invoke-static {v2, p1}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->require(ZLjava/lang/String;)V
    invoke-virtual {v0, v1}, Landroid/app/Activity;->findViewById(I)Landroid/view/View;
    move-result-object v0
    const/4 v2, 0
    if-eqz v0, :found
    const/4 v2, 1
  :found
    invoke-static {v2, p1}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->require(ZLjava/lang/String;)V
    return-object v0
.end method

.method private bind()V
    .registers 3
    const-string v0, "root"
    invoke-direct {p0, v0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->view(Ljava/lang/String;)Landroid/view/View;
    move-result-object v0
    iput-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->root:Landroid/view/View;
    const-string v0, "formula"
    invoke-direct {p0, v0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->view(Ljava/lang/String;)Landroid/view/View;
    move-result-object v0
    check-cast v0, Landroid/widget/EditText;
    iput-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->editor:Landroid/widget/EditText;
    const-string v0, "surface_view"
    invoke-direct {p0, v0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->view(Ljava/lang/String;)Landroid/view/View;
    move-result-object v0
    check-cast v0, Landroid/widget/ImageView;
    iput-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->image:Landroid/widget/ImageView;
    const-string v0, "status"
    invoke-direct {p0, v0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->view(Ljava/lang/String;)Landroid/view/View;
    move-result-object v0
    check-cast v0, Landroid/widget/TextView;
    iput-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->status:Landroid/widget/TextView;
    const-string v0, "render"
    invoke-direct {p0, v0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->view(Ljava/lang/String;)Landroid/view/View;
    move-result-object v0
    iput-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->render:Landroid/view/View;
    const-string v0, "examples"
    invoke-direct {p0, v0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->view(Ljava/lang/String;)Landroid/view/View;
    move-result-object v0
    iput-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->examples:Landroid/view/View;
    const-string v0, "save"
    invoke-direct {p0, v0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->view(Ljava/lang/String;)Landroid/view/View;
    move-result-object v0
    iput-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->save:Landroid/view/View;
    const-string v0, "about"
    invoke-direct {p0, v0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->view(Ljava/lang/String;)Landroid/view/View;
    move-result-object v0
    iput-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->about:Landroid/view/View;
    iget-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->root:Landroid/view/View;
    invoke-virtual {v0}, Landroid/view/View;->isAttachedToWindow()Z
    move-result v0
    const-string v1, "real resource controls must be attached to the framework window"
    invoke-static {v0, v1}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->require(ZLjava/lang/String;)V
    return-void
.end method

.method private click(Landroid/view/View;)V
    .registers 3
    invoke-virtual {p1}, Landroid/view/View;->performClick()Z
    move-result v0
    const-string p1, "actual installed control did not handle performClick"
    invoke-static {v0, p1}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->require(ZLjava/lang/String;)V
    return-void
.end method

# All view/drawable reads and actions occur on the real main thread.
.method public run()V
    .registers 5
  :begin
    iget v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->mode:I
    packed-switch v0, :modes
    new-instance v0, Ljava/lang/AssertionError;
    const-string v1, "unknown observer action"
    invoke-direct {v0, v1}, Ljava/lang/AssertionError;-><init>(Ljava/lang/Object;)V
    throw v0
  :bind
    invoke-direct {p0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->bind()V
    goto :done
  :affine
    iget-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->editor:Landroid/widget/EditText;
    const-string v1, "y+0.25*x+0.1"
    invoke-virtual {v0, v1}, Landroid/widget/EditText;->setText(Ljava/lang/CharSequence;)V
    iget-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->render:Landroid/view/View;
    invoke-direct {p0, v0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->click(Landroid/view/View;)V
    goto :done
  :invalid
    invoke-direct {p0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->snapshot()V
    iget-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->editor:Landroid/widget/EditText;
    const-string v1, "x/y"
    invoke-virtual {v0, v1}, Landroid/widget/EditText;->setText(Ljava/lang/CharSequence;)V
    iget-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->render:Landroid/view/View;
    invoke-direct {p0, v0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->click(Landroid/view/View;)V
    goto :done
  :done_editor
    iget-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->editor:Landroid/widget/EditText;
    const-string v1, "x^2+y^2+z^2-0.64"
    invoke-virtual {v0, v1}, Landroid/widget/EditText;->setText(Ljava/lang/CharSequence;)V
    const/4 v1, 6
    invoke-virtual {v0, v1}, Landroid/widget/TextView;->onEditorAction(I)V
    goto :done
  :examples
    iget-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->examples:Landroid/view/View;
    invoke-direct {p0, v0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->click(Landroid/view/View;)V
    goto :done
  :save
    invoke-direct {p0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->snapshot()V
    iget-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->save:Landroid/view/View;
    invoke-direct {p0, v0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->click(Landroid/view/View;)V
    goto :done
  :recreate
    iget-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->activity:Landroid/app/Activity;
    invoke-virtual {v0}, Landroid/app/Activity;->recreate()V
    goto :done
  :close
    # Submit a fresh real request immediately before framework close. This is
    # bounded lifecycle behavior; production native live counters are private.
    iget-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->editor:Landroid/widget/EditText;
    const-string v1, "x^2+y^2+z^2-0.64"
    invoke-virtual {v0, v1}, Landroid/widget/EditText;->setText(Ljava/lang/CharSequence;)V
    iget-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->render:Landroid/view/View;
    invoke-direct {p0, v0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->click(Landroid/view/View;)V
  :close_only
    iget-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->activity:Landroid/app/Activity;
    invoke-virtual {v0}, Landroid/app/Activity;->finish()V
    goto :done
  :snapshot
    invoke-direct {p0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->snapshot()V
    goto :done
  :blank_bitmap
    # Observer sensitivity control only: change the real ImageView after a
    # completed real frame, then reuse its ordinary full-pixel assertion.
    iget-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->observedBitmap:Landroid/graphics/Bitmap;
    invoke-virtual {v0}, Landroid/graphics/Bitmap;->getWidth()I
    move-result v1
    invoke-virtual {v0}, Landroid/graphics/Bitmap;->getHeight()I
    move-result v2
    const-string v0, "ARGB_8888"
    invoke-static {v0}, Landroid/graphics/Bitmap$Config;->valueOf(Ljava/lang/String;)Landroid/graphics/Bitmap$Config;
    move-result-object v3
    invoke-static {v1, v2, v3}, Landroid/graphics/Bitmap;->createBitmap(IILandroid/graphics/Bitmap$Config;)Landroid/graphics/Bitmap;
    move-result-object v0
    const v1, 0xff112233
    invoke-virtual {v0, v1}, Landroid/graphics/Bitmap;->eraseColor(I)V
    iget-object v1, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->image:Landroid/widget/ImageView;
    invoke-virtual {v1, v0}, Landroid/widget/ImageView;->setImageBitmap(Landroid/graphics/Bitmap;)V
    invoke-direct {p0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->snapshot()V
    const/4 v0, 1
    iput-boolean v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->negativeApplied:Z
    iget-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->observedPixels:[I
    invoke-static {v0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->actualPixels([I)V
  :done
    return-void
  :caught
    move-exception v0
    iput-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->uiError:Ljava/lang/Throwable;
    return-void
    .catch Ljava/lang/Throwable; {:begin .. :done} :caught
  :modes
    .packed-switch 0
      :bind
      :affine
      :invalid
      :done_editor
      :examples
      :save
      :recreate
      :close
      :snapshot
      :blank_bitmap
      :close_only
    .end packed-switch
.end method

.method private step(I)V
    .registers 4
    iput p1, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->mode:I
    const/4 v0, 0
    iput-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->uiError:Ljava/lang/Throwable;
    invoke-virtual {p0, p0}, Landroid/app/Instrumentation;->runOnMainSync(Ljava/lang/Runnable;)V
    iget-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->uiError:Ljava/lang/Throwable;
    if-eqz v0, :done
    throw v0
  :done
    return-void
.end method

.method private snapshot()V
    .registers 12
    iget-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->status:Landroid/widget/TextView;
    invoke-virtual {v0}, Landroid/widget/TextView;->getText()Ljava/lang/CharSequence;
    move-result-object v0
    invoke-interface {v0}, Ljava/lang/CharSequence;->toString()Ljava/lang/String;
    move-result-object v0
    iput-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->observedStatus:Ljava/lang/String;
    iget-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->editor:Landroid/widget/EditText;
    invoke-virtual {v0}, Landroid/widget/EditText;->getText()Landroid/text/Editable;
    move-result-object v0
    invoke-interface {v0}, Landroid/text/Editable;->toString()Ljava/lang/String;
    move-result-object v0
    iput-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->observedFormula:Ljava/lang/String;
    const/4 v0, 0
    iput-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->observedBitmap:Landroid/graphics/Bitmap;
    iput-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->observedPixels:[I
    iget-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->image:Landroid/widget/ImageView;
    invoke-virtual {v0}, Landroid/widget/ImageView;->getDrawable()Landroid/graphics/drawable/Drawable;
    move-result-object v0
    instance-of v1, v0, Landroid/graphics/drawable/BitmapDrawable;
    if-eqz v1, :done
    check-cast v0, Landroid/graphics/drawable/BitmapDrawable;
    invoke-virtual {v0}, Landroid/graphics/drawable/BitmapDrawable;->getBitmap()Landroid/graphics/Bitmap;
    move-result-object v0
    iput-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->observedBitmap:Landroid/graphics/Bitmap;
    invoke-virtual {v0}, Landroid/graphics/Bitmap;->isRecycled()Z
    move-result v1
    if-nez v1, :done
    invoke-virtual {v0}, Landroid/graphics/Bitmap;->getWidth()I
    move-result v6
    invoke-virtual {v0}, Landroid/graphics/Bitmap;->getHeight()I
    move-result v7
    if-lez v6, :done
    if-lez v7, :done
    mul-int v1, v6, v7
    new-array v1, v1, [I
    move v3, v6
    const/4 v2, 0
    const/4 v4, 0
    const/4 v5, 0
    invoke-virtual/range {v0 .. v7}, Landroid/graphics/Bitmap;->getPixels([IIIIIII)V
    iput-object v1, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->observedPixels:[I
  :done
    return-void
.end method

.method private static actualPixels([I)V
    .registers 8
    const/4 v0, 0
    if-eqz p0, :invalid
    array-length v1, p0
    const/4 v2, 4
    if-lt v1, v2, :invalid
    aget v2, p0, v0
    const/4 v3, 0
  :next
    if-ge v0, v1, :complete
    aget v4, p0, v0
    ushr-int/lit8 v5, v4, 24
    const/16 v6, 255
    if-ne v5, v6, :invalid
    if-eq v4, v2, :same
    const/4 v3, 1
  :same
    add-int/lit8 v0, v0, 1
    goto :next
  :complete
    const-string v0, "actual ImageView Bitmap must contain more than one opaque pixel color"
    invoke-static {v3, v0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->require(ZLjava/lang/String;)V
    return-void
  :invalid
    const/4 v0, 0
    const-string v1, "actual ImageView Bitmap pixels are absent, recycled, empty or nonopaque"
    invoke-static {v0, v1}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->require(ZLjava/lang/String;)V
    return-void
.end method

# Polling only the instrumentation thread; each sample synchronizes with UI.
.method private waitFrame(ZLandroid/graphics/Bitmap;)V
    .registers 10
    invoke-static {}, Landroid/os/SystemClock;->elapsedRealtime()J
    move-result-wide v0
    const-wide/32 v2, 90000
    add-long/2addr v0, v2
  :poll
    const/16 v2, 8
    invoke-direct {p0, v2}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->step(I)V
    iget-object v2, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->observedStatus:Ljava/lang/String;
    if-eqz p1, :success
    const-string v3, "Formula error:"
    invoke-virtual {v2, v3}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
    move-result v2
    if-nez v2, :ready
    goto :later
  :success
    const-string v3, "Degree "
    invoke-virtual {v2, v3}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
    move-result v2
    if-eqz v2, :later
    iget-object v2, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->observedBitmap:Landroid/graphics/Bitmap;
    if-eqz v2, :later
    if-eq v2, p2, :later
  :ready
    iget-object v2, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->observedPixels:[I
    invoke-static {v2}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->actualPixels([I)V
    return-void
  :later
    invoke-static {}, Landroid/os/SystemClock;->elapsedRealtime()J
    move-result-wide v2
    cmp-long v4, v2, v0
    if-gez v4, :timeout
    const-wide/16 v2, 200
    invoke-static {v2, v3}, Landroid/os/SystemClock;->sleep(J)V
    goto :poll
  :timeout
    new-instance v2, Ljava/lang/AssertionError;
    iget-object v3, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->observedStatus:Ljava/lang/String;
    invoke-direct {v2, v3}, Ljava/lang/AssertionError;-><init>(Ljava/lang/Object;)V
    throw v2
.end method

.method private count()V
    .registers 2
    iget v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->completed:I
    add-int/lit8 v0, v0, 1
    iput v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->completed:I
    return-void
.end method

# Failure cleanup preserves the first diagnostic and reports its own outcome.
.method private cleanupActivity()V
    .registers 7
  :begin
    const-string v0, "absent"
    iput-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->cleanupState:Ljava/lang/String;
    iget-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->activity:Landroid/app/Activity;
    if-eqz v0, :end
    const/16 v1, 10
    invoke-direct {p0, v1}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->step(I)V
    const/4 v1, 0
  :poll
    invoke-virtual {p0}, Landroid/app/Instrumentation;->waitForIdleSync()V
    iget-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->activity:Landroid/app/Activity;
    invoke-virtual {v0}, Landroid/app/Activity;->isDestroyed()Z
    move-result v0
    if-nez v0, :destroyed
    const/16 v0, 50
    if-ge v1, v0, :failed
    const-wide/16 v2, 200
    invoke-static {v2, v3}, Landroid/os/SystemClock;->sleep(J)V
    add-int/lit8 v1, v1, 1
    goto :poll
  :destroyed
    const-string v0, "destroyed"
    goto :store
  :failed
    const-string v0, "failed"
  :store
    iput-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->cleanupState:Ljava/lang/String;
  :end
    return-void
  :caught
    move-exception v0
    sget-object v1, Ljava/lang/System;->err:Ljava/io/PrintStream;
    invoke-virtual {v0, v1}, Ljava/lang/Throwable;->printStackTrace(Ljava/io/PrintStream;)V
    const-string v0, "failed"
    iput-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->cleanupState:Ljava/lang/String;
    return-void
    .catch Ljava/lang/Throwable; {:begin .. :end} :caught
.end method

.method private selectTorus()V
    .registers 11
    invoke-virtual {p0}, Landroid/app/Instrumentation;->getUiAutomation()Landroid/app/UiAutomation;
    move-result-object v0
    const/4 v1, 0
  :poll
    const/16 v2, 50
    if-ge v1, v2, :missing
    invoke-virtual {v0}, Landroid/app/UiAutomation;->getRootInActiveWindow()Landroid/view/accessibility/AccessibilityNodeInfo;
    move-result-object v2
    if-eqz v2, :later
    const-string v3, "Torus"
    invoke-virtual {v2, v3}, Landroid/view/accessibility/AccessibilityNodeInfo;->findAccessibilityNodeInfosByText(Ljava/lang/String;)Ljava/util/List;
    move-result-object v3
    const/4 v4, 0
  :node
    invoke-interface {v3}, Ljava/util/List;->size()I
    move-result v5
    if-ge v4, v5, :later
    invoke-interface {v3, v4}, Ljava/util/List;->get(I)Ljava/lang/Object;
    move-result-object v5
    check-cast v5, Landroid/view/accessibility/AccessibilityNodeInfo;
    invoke-virtual {v5}, Landroid/view/accessibility/AccessibilityNodeInfo;->getText()Ljava/lang/CharSequence;
    move-result-object v6
    if-eqz v6, :next_node
    const-string v7, "Torus"
    invoke-virtual {v7, v6}, Ljava/lang/String;->contentEquals(Ljava/lang/CharSequence;)Z
    move-result v6
    if-eqz v6, :next_node
    const/4 v6, 0
  :ancestor
    if-eqz v5, :next_node
    const/4 v7, 4
    if-ge v6, v7, :next_node
    const/16 v7, 16
    invoke-virtual {v5, v7}, Landroid/view/accessibility/AccessibilityNodeInfo;->performAction(I)Z
    move-result v7
    if-nez v7, :selected
    invoke-virtual {v5}, Landroid/view/accessibility/AccessibilityNodeInfo;->getParent()Landroid/view/accessibility/AccessibilityNodeInfo;
    move-result-object v5
    add-int/lit8 v6, v6, 1
    goto :ancestor
  :next_node
    add-int/lit8 v4, v4, 1
    goto :node
  :later
    const-wide/16 v8, 200
    invoke-static {v8, v9}, Landroid/os/SystemClock;->sleep(J)V
    add-int/lit8 v1, v1, 1
    goto :poll
  :selected
    return-void
  :missing
    const/4 v0, 0
    const-string v1, "Examples dialog Torus item was not accessible/clickable within10seconds"
    invoke-static {v0, v1}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->require(ZLjava/lang/String;)V
    return-void
.end method

.method private retained(Landroid/graphics/Bitmap;[I)V
    .registers 5
    iget-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->observedBitmap:Landroid/graphics/Bitmap;
    const/4 v1, 0
    if-ne v0, p1, :identity
    const/4 v1, 1
  :identity
    const-string v0, "failed/cancelled operation replaced the previous actual ImageView Bitmap"
    invoke-static {v1, v0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->require(ZLjava/lang/String;)V
    iget-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->observedPixels:[I
    invoke-static {v0, p2}, Ljava/util/Arrays;->equals([I[I)Z
    move-result v0
    const-string v1, "failed/cancelled operation changed pixels of the previous actual Bitmap"
    invoke-static {v0, v1}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->require(ZLjava/lang/String;)V
    return-void
.end method

.method private scenarios()V
    .registers 14
    new-instance v0, Landroid/content/Intent;
    const-string v1, "android.intent.action.MAIN"
    invoke-direct {v0, v1}, Landroid/content/Intent;-><init>(Ljava/lang/String;)V
    const-string v1, "org.algebraicvarietyexplorer"
    const-string v2, "Idric.Generated"
    invoke-virtual {v0, v1, v2}, Landroid/content/Intent;->setClassName(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;
    const/high16 v1, 0x10000000
    invoke-virtual {v0, v1}, Landroid/content/Intent;->addFlags(I)Landroid/content/Intent;
    invoke-virtual {p0, v0}, Landroid/app/Instrumentation;->startActivitySync(Landroid/content/Intent;)Landroid/app/Activity;
    move-result-object v0
    iput-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->activity:Landroid/app/Activity;
    invoke-virtual {p0}, Landroid/app/Instrumentation;->waitForIdleSync()V
    const/4 v0, 0
    invoke-direct {p0, v0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->step(I)V
    const/4 v1, 0
    invoke-direct {p0, v0, v1}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->waitFrame(ZLandroid/graphics/Bitmap;)V
    iget-boolean v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->negativeControl:Z
    if-eqz v0, :normal_initial
    const/16 v0, 9
    invoke-direct {p0, v0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->step(I)V
  :normal_initial
    iget-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->observedFormula:Ljava/lang/String;
    const-string v1, "x^2+y^2+z^2-0.64"
    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    const-string v1, "initial formula must come from source-owned Sphere example"
    invoke-static {v0, v1}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->require(ZLjava/lang/String;)V
    invoke-direct {p0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->count()V
    iget-object v2, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->observedBitmap:Landroid/graphics/Bitmap;
    iget-object v3, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->observedPixels:[I
    const/4 v0, 1
    invoke-direct {p0, v0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->step(I)V
    const/4 v0, 0
    invoke-direct {p0, v0, v2}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->waitFrame(ZLandroid/graphics/Bitmap;)V
    iget-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->observedPixels:[I
    invoke-static {v0, v3}, Ljava/util/Arrays;->equals([I[I)Z
    move-result v0
    xor-int/lit8 v0, v0, 1
    const-string v1, "Render must produce pixels different from the initial Sphere"
    invoke-static {v0, v1}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->require(ZLjava/lang/String;)V
    invoke-direct {p0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->count()V
    iget-object v2, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->observedBitmap:Landroid/graphics/Bitmap;
    iget-object v3, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->observedPixels:[I
    const/4 v0, 2
    invoke-direct {p0, v0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->step(I)V
    iget-object v2, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->observedBitmap:Landroid/graphics/Bitmap;
    iget-object v3, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->observedPixels:[I
    const/4 v0, 1
    invoke-direct {p0, v0, v2}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->waitFrame(ZLandroid/graphics/Bitmap;)V
    invoke-direct {p0, v2, v3}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->retained(Landroid/graphics/Bitmap;[I)V
    invoke-direct {p0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->count()V
    const/4 v0, 3
    invoke-direct {p0, v0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->step(I)V
    const/4 v0, 0
    invoke-direct {p0, v0, v2}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->waitFrame(ZLandroid/graphics/Bitmap;)V
    invoke-direct {p0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->count()V
    iget-object v2, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->observedBitmap:Landroid/graphics/Bitmap;
    const/4 v0, 4
    invoke-direct {p0, v0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->step(I)V
    invoke-direct {p0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->selectTorus()V
    const/4 v0, 0
    invoke-direct {p0, v0, v2}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->waitFrame(ZLandroid/graphics/Bitmap;)V
    iget-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->observedFormula:Ljava/lang/String;
    const-string v1, "(x^2+y^2+z^2+0.36)^2-1.69*(x^2+y^2)"
    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    const-string v1, "Examples must select the actual source-owned Torus formula"
    invoke-static {v0, v1}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->require(ZLjava/lang/String;)V
    invoke-direct {p0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->count()V
    # Block only the real CREATE_DOCUMENT/image/png request; return cancellation.
    new-instance v4, Landroid/content/IntentFilter;
    const-string v0, "android.intent.action.CREATE_DOCUMENT"
    invoke-direct {v4, v0}, Landroid/content/IntentFilter;-><init>(Ljava/lang/String;)V
    const-string v0, "android.intent.category.OPENABLE"
    invoke-virtual {v4, v0}, Landroid/content/IntentFilter;->addCategory(Ljava/lang/String;)V
    const-string v0, "image/png"
    invoke-virtual {v4, v0}, Landroid/content/IntentFilter;->addDataType(Ljava/lang/String;)V
    new-instance v5, Landroid/app/Instrumentation$ActivityResult;
    const/4 v0, 0
    const/4 v1, 0
    invoke-direct {v5, v0, v1}, Landroid/app/Instrumentation$ActivityResult;-><init>(ILandroid/content/Intent;)V
    const/4 v0, 1
    invoke-virtual {p0, v4, v5, v0}, Landroid/app/Instrumentation;->addMonitor(Landroid/content/IntentFilter;Landroid/app/Instrumentation$ActivityResult;Z)Landroid/app/Instrumentation$ActivityMonitor;
    move-result-object v4
    iget-object v2, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->observedBitmap:Landroid/graphics/Bitmap;
    iget-object v3, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->observedPixels:[I
    const/4 v0, 5
    invoke-direct {p0, v0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->step(I)V
    iget-object v2, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->observedBitmap:Landroid/graphics/Bitmap;
    iget-object v3, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->observedPixels:[I
    invoke-virtual {p0}, Landroid/app/Instrumentation;->waitForIdleSync()V
    invoke-virtual {v4}, Landroid/app/Instrumentation$ActivityMonitor;->getHits()I
    move-result v0
    const/4 v1, 1
    if-ne v0, v1, :bad_picker
    const/4 v0, 1
    goto :picker_check
  :bad_picker
    const/4 v0, 0
  :picker_check
    const-string v1, "Save PNG must launch exactly one actual CREATE_DOCUMENT/image/png request"
    invoke-static {v0, v1}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->require(ZLjava/lang/String;)V
    invoke-virtual {p0, v4}, Landroid/app/Instrumentation;->removeMonitor(Landroid/app/Instrumentation$ActivityMonitor;)V
    const/16 v0, 8
    invoke-direct {p0, v0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->step(I)V
    invoke-direct {p0, v2, v3}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->retained(Landroid/graphics/Bitmap;[I)V
    invoke-direct {p0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->count()V
    # Framework recreation, not manual lifecycle calls or direct exports.
    const-string v4, "Idric.Generated"
    const/4 v5, 0
    const/4 v0, 0
    invoke-virtual {p0, v4, v5, v0}, Landroid/app/Instrumentation;->addMonitor(Ljava/lang/String;Landroid/app/Instrumentation$ActivityResult;Z)Landroid/app/Instrumentation$ActivityMonitor;
    move-result-object v4
    iget-object v5, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->activity:Landroid/app/Activity;
    const/4 v0, 6
    invoke-direct {p0, v0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->step(I)V
    const-wide/32 v6, 90000
    invoke-virtual {p0, v4, v6, v7}, Landroid/app/Instrumentation;->waitForMonitorWithTimeout(Landroid/app/Instrumentation$ActivityMonitor;J)Landroid/app/Activity;
    move-result-object v0
    const/4 v1, 0
    if-eqz v0, :new_check
    if-eq v0, v5, :new_check
    const/4 v1, 1
  :new_check
    const-string v8, "framework recreation must supply a different Activity instance"
    invoke-static {v1, v8}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->require(ZLjava/lang/String;)V
    invoke-virtual {p0, v4}, Landroid/app/Instrumentation;->removeMonitor(Landroid/app/Instrumentation$ActivityMonitor;)V
    iput-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->activity:Landroid/app/Activity;
    invoke-virtual {p0}, Landroid/app/Instrumentation;->waitForIdleSync()V
    const/4 v0, 0
    invoke-direct {p0, v0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->step(I)V
    invoke-direct {p0, v0, v2}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->waitFrame(ZLandroid/graphics/Bitmap;)V
    iget-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->observedFormula:Ljava/lang/String;
    const-string v1, "(x^2+y^2+z^2+0.36)^2-1.69*(x^2+y^2)"
    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    const-string v1, "recreation must restore the selected formula"
    invoke-static {v0, v1}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->require(ZLjava/lang/String;)V
    iget-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->observedPixels:[I
    invoke-static {v0, v3}, Ljava/util/Arrays;->equals([I[I)Z
    move-result v0
    const-string v1, "recreated frame must reproduce the prior formula and camera pixels"
    invoke-static {v0, v1}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->require(ZLjava/lang/String;)V
    invoke-virtual {v5}, Landroid/app/Activity;->isDestroyed()Z
    move-result v0
    const-string v1, "recreated prior Activity must be destroyed"
    invoke-static {v0, v1}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->require(ZLjava/lang/String;)V
    invoke-direct {p0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->count()V
    const/4 v0, 7
    invoke-direct {p0, v0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->step(I)V
    const/4 v0, 0
  :close_poll
    invoke-virtual {p0}, Landroid/app/Instrumentation;->waitForIdleSync()V
    iget-object v1, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->activity:Landroid/app/Activity;
    invoke-virtual {v1}, Landroid/app/Activity;->isDestroyed()Z
    move-result v1
    if-nez v1, :closed
    const/16 v1, 50
    if-ge v0, v1, :close_timeout
    const-wide/16 v6, 200
    invoke-static {v6, v7}, Landroid/os/SystemClock;->sleep(J)V
    add-int/lit8 v0, v0, 1
    goto :close_poll
  :closed
    const/4 v1, 1
    goto :close_check
  :close_timeout
    const/4 v1, 0
  :close_check
    const-string v0, "finished installed Activity must reach framework destruction"
    invoke-static {v1, v0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->require(ZLjava/lang/String;)V
    const-wide/16 v6, 1000
    invoke-static {v6, v7}, Landroid/os/SystemClock;->sleep(J)V
    invoke-virtual {p0}, Landroid/app/Instrumentation;->waitForIdleSync()V
    invoke-direct {p0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->count()V
    return-void
.end method

.method public onStart()V
    .registers 7
    new-instance v0, Landroid/os/Bundle;
    invoke-direct {v0}, Landroid/os/Bundle;-><init>()V
  :begin
    invoke-direct {p0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->scenarios()V
    iget v1, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->completed:I
    const/16 v2, 8
    if-ne v1, v2, :wrong_count
    const-string v1, "ave_observer_result"
    const-string v2, "PASS Explorer installed checked-DEX Activity"
    invoke-virtual {v0, v1, v2}, Landroid/os/Bundle;->putString(Ljava/lang/String;Ljava/lang/String;)V
    const-string v1, "scenarios"
    iget v2, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->completed:I
    invoke-virtual {v0, v1, v2}, Landroid/os/Bundle;->putInt(Ljava/lang/String;I)V
    const/4 v1, -1
    invoke-virtual {p0, v1, v0}, Landroid/app/Instrumentation;->finish(ILandroid/os/Bundle;)V
    return-void
  :wrong_count
    new-instance v1, Ljava/lang/AssertionError;
    const-string v2, "installed observer did not finish all eight scenarios"
    invoke-direct {v1, v2}, Ljava/lang/AssertionError;-><init>(Ljava/lang/Object;)V
    throw v1
  :end
    .catch Ljava/lang/Throwable; {:begin .. :end} :failed
  :failed
    move-exception v1
    new-instance v2, Ljava/io/StringWriter;
    invoke-direct {v2}, Ljava/io/StringWriter;-><init>()V
    new-instance v3, Ljava/io/PrintWriter;
    invoke-direct {v3, v2}, Ljava/io/PrintWriter;-><init>(Ljava/io/Writer;)V
    invoke-virtual {v1, v3}, Ljava/lang/Throwable;->printStackTrace(Ljava/io/PrintWriter;)V
    invoke-virtual {v3}, Ljava/io/PrintWriter;->flush()V
    invoke-virtual {v2}, Ljava/io/StringWriter;->toString()Ljava/lang/String;
    move-result-object v2
    const-string v3, "ave_observer_result"
    const-string v4, "FAIL Explorer installed checked-DEX Activity"
    invoke-virtual {v0, v3, v4}, Landroid/os/Bundle;->putString(Ljava/lang/String;Ljava/lang/String;)V
    const-string v3, "stack"
    invoke-virtual {v0, v3, v2}, Landroid/os/Bundle;->putString(Ljava/lang/String;Ljava/lang/String;)V
    const-string v3, "scenarios"
    iget v4, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->completed:I
    invoke-virtual {v0, v3, v4}, Landroid/os/Bundle;->putInt(Ljava/lang/String;I)V
    invoke-direct {p0}, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->cleanupActivity()V
    const-string v3, "observer_cleanup"
    iget-object v4, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->cleanupState:Ljava/lang/String;
    invoke-virtual {v0, v3, v4}, Landroid/os/Bundle;->putString(Ljava/lang/String;Ljava/lang/String;)V
    iget-boolean v3, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->negativeControl:Z
    if-eqz v3, :ordinary_failure
    const-string v3, "ave_negative_control"
    const-string v4, "blank_bitmap"
    invoke-virtual {v0, v3, v4}, Landroid/os/Bundle;->putString(Ljava/lang/String;Ljava/lang/String;)V
    const-string v3, "ave_negative_control_applied"
    iget-boolean v4, p0, Lorg/algebraicvarietyexplorer/idricqualification/InstalledObserver;->negativeApplied:Z
    invoke-virtual {v0, v3, v4}, Landroid/os/Bundle;->putBoolean(Ljava/lang/String;Z)V
  :ordinary_failure
    sget-object v3, Ljava/lang/System;->err:Ljava/io/PrintStream;
    invoke-virtual {v1, v3}, Ljava/lang/Throwable;->printStackTrace(Ljava/io/PrintStream;)V
    const/4 v1, 0
    invoke-virtual {p0, v1, v0}, Landroid/app/Instrumentation;->finish(ILandroid/os/Bundle;)V
    return-void
.end method

