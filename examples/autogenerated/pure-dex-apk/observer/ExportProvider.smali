.class public final Lorg/algebraicvarietyexplorer/idricqualification/ExportProvider;
.super Landroid/content/ContentProvider;

.method public constructor <init>()V
    .registers 1
    invoke-direct {p0}, Landroid/content/ContentProvider;-><init>()V
    return-void
.end method

.method public onCreate()Z
    .registers 2
    const/4 v0, 1
    return v0
.end method

# Only independently generated, bounded tokens may address this test-only store.
.method private file(Ljava/lang/String;Ljava/lang/String;)Ljava/io/File;
    .registers 7
    if-eqz p1, :invalid
    const-string v0, "[0-9a-f]{32}"
    invoke-virtual {p1, v0}, Ljava/lang/String;->matches(Ljava/lang/String;)Z
    move-result v0
    if-eqz v0, :invalid
    invoke-virtual {p0}, Landroid/content/ContentProvider;->getContext()Landroid/content/Context;
    move-result-object v0
    invoke-virtual {v0}, Landroid/content/Context;->getFilesDir()Ljava/io/File;
    move-result-object v0
    new-instance v1, Ljava/lang/StringBuilder;
    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V
    const-string v2, "export-"
    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v1, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v1, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v1
    new-instance v2, Ljava/io/File;
    invoke-direct {v2, v0, v1}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V
    return-object v2
  :invalid
    new-instance v0, Ljava/lang/IllegalArgumentException;
    const-string v1, "invalid isolated export token"
    invoke-direct {v0, v1}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V
    throw v0
.end method

.method private token(Landroid/net/Uri;)Ljava/lang/String;
    .registers 6
    invoke-virtual {p1}, Landroid/net/Uri;->getPathSegments()Ljava/util/List;
    move-result-object v0
    invoke-interface {v0}, Ljava/util/List;->size()I
    move-result v1
    const/4 v2, 2
    if-ne v1, v2, :invalid
    const/4 v1, 0
    invoke-interface {v0, v1}, Ljava/util/List;->get(I)Ljava/lang/Object;
    move-result-object v1
    const-string v2, "exports"
    invoke-virtual {v2, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-eqz v1, :invalid
    const/4 v1, 1
    invoke-interface {v0, v1}, Ljava/util/List;->get(I)Ljava/lang/Object;
    move-result-object v0
    check-cast v0, Ljava/lang/String;
    return-object v0
  :invalid
    new-instance v0, Ljava/lang/IllegalArgumentException;
    const-string v1, "invalid isolated export URI"
    invoke-direct {v0, v1}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V
    throw v0
.end method

.method public openFile(Landroid/net/Uri;Ljava/lang/String;)Landroid/os/ParcelFileDescriptor;
    .registers 10
    invoke-direct {p0, p1}, Lorg/algebraicvarietyexplorer/idricqualification/ExportProvider;->token(Landroid/net/Uri;)Ljava/lang/String;
    move-result-object v0
    const-string v1, ".png"
    invoke-direct {p0, v0, v1}, Lorg/algebraicvarietyexplorer/idricqualification/ExportProvider;->file(Ljava/lang/String;Ljava/lang/String;)Ljava/io/File;
    move-result-object v1
    const-string v2, "r"
    invoke-virtual {v2, p2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v2
    if-eqz v2, :write
    const/high16 v0, 0x10000000
    invoke-static {v1, v0}, Landroid/os/ParcelFileDescriptor;->open(Ljava/io/File;I)Landroid/os/ParcelFileDescriptor;
    move-result-object v0
    return-object v0
  :write
    const-string v2, "w"
    invoke-virtual {v2, p2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v2
    if-eqz v2, :invalid
    const-string v2, ".opened"
    invoke-direct {p0, v0, v2}, Lorg/algebraicvarietyexplorer/idricqualification/ExportProvider;->file(Ljava/lang/String;Ljava/lang/String;)Ljava/io/File;
    move-result-object v2
    invoke-virtual {v2}, Ljava/io/File;->createNewFile()Z
    move-result v2
    if-eqz v2, :invalid
    const-string v2, ".closed"
    invoke-direct {p0, v0, v2}, Lorg/algebraicvarietyexplorer/idricqualification/ExportProvider;->file(Ljava/lang/String;Ljava/lang/String;)Ljava/io/File;
    move-result-object v2
    const-string v3, ".failed"
    invoke-direct {p0, v0, v3}, Lorg/algebraicvarietyexplorer/idricqualification/ExportProvider;->file(Ljava/lang/String;Ljava/lang/String;)Ljava/io/File;
    move-result-object v3
    new-instance v4, Lorg/algebraicvarietyexplorer/idricqualification/ExportCloseListener;
    invoke-direct {v4, v2, v3}, Lorg/algebraicvarietyexplorer/idricqualification/ExportCloseListener;-><init>(Ljava/io/File;Ljava/io/File;)V
    invoke-static {}, Landroid/os/Looper;->getMainLooper()Landroid/os/Looper;
    move-result-object v2
    new-instance v3, Landroid/os/Handler;
    invoke-direct {v3, v2}, Landroid/os/Handler;-><init>(Landroid/os/Looper;)V
    const/high16 v2, 0x3c000000
    invoke-static {v1, v2, v3, v4}, Landroid/os/ParcelFileDescriptor;->open(Ljava/io/File;ILandroid/os/Handler;Landroid/os/ParcelFileDescriptor$OnCloseListener;)Landroid/os/ParcelFileDescriptor;
    move-result-object v0
    return-object v0
  :invalid
    new-instance v0, Ljava/io/FileNotFoundException;
    const-string v1, "isolated PNG provider requires one fresh exact w open"
    invoke-direct {v0, v1}, Ljava/io/FileNotFoundException;-><init>(Ljava/lang/String;)V
    throw v0
.end method

.method public call(Ljava/lang/String;Ljava/lang/String;Landroid/os/Bundle;)Landroid/os/Bundle;
    .registers 9
    const-string v0, "inspect"
    invoke-virtual {v0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    if-eqz v0, :invalid
    new-instance v0, Landroid/os/Bundle;
    invoke-direct {v0}, Landroid/os/Bundle;-><init>()V
    const-string v1, ".opened"
    invoke-direct {p0, p2, v1}, Lorg/algebraicvarietyexplorer/idricqualification/ExportProvider;->file(Ljava/lang/String;Ljava/lang/String;)Ljava/io/File;
    move-result-object v1
    invoke-virtual {v1}, Ljava/io/File;->exists()Z
    move-result v1
    const-string v2, "opened"
    invoke-virtual {v0, v2, v1}, Landroid/os/Bundle;->putBoolean(Ljava/lang/String;Z)V
    const-string v1, ".closed"
    invoke-direct {p0, p2, v1}, Lorg/algebraicvarietyexplorer/idricqualification/ExportProvider;->file(Ljava/lang/String;Ljava/lang/String;)Ljava/io/File;
    move-result-object v1
    invoke-virtual {v1}, Ljava/io/File;->exists()Z
    move-result v1
    const-string v2, "closed"
    invoke-virtual {v0, v2, v1}, Landroid/os/Bundle;->putBoolean(Ljava/lang/String;Z)V
    const-string v1, ".failed"
    invoke-direct {p0, p2, v1}, Lorg/algebraicvarietyexplorer/idricqualification/ExportProvider;->file(Ljava/lang/String;Ljava/lang/String;)Ljava/io/File;
    move-result-object v1
    invoke-virtual {v1}, Ljava/io/File;->exists()Z
    move-result v1
    const-string v2, "failed"
    invoke-virtual {v0, v2, v1}, Landroid/os/Bundle;->putBoolean(Ljava/lang/String;Z)V
    const-string v1, ".png"
    invoke-direct {p0, p2, v1}, Lorg/algebraicvarietyexplorer/idricqualification/ExportProvider;->file(Ljava/lang/String;Ljava/lang/String;)Ljava/io/File;
    move-result-object v1
    invoke-virtual {v1}, Ljava/io/File;->length()J
    move-result-wide v1
    const-string v3, "length"
    invoke-virtual {v0, v3, v1, v2}, Landroid/os/Bundle;->putLong(Ljava/lang/String;J)V
    return-object v0
  :invalid
    new-instance v0, Ljava/lang/IllegalArgumentException;
    const-string v1, "unknown isolated export inspection"
    invoke-direct {v0, v1}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V
    throw v0
.end method

.method public getType(Landroid/net/Uri;)Ljava/lang/String;
    .registers 3
    invoke-direct {p0, p1}, Lorg/algebraicvarietyexplorer/idricqualification/ExportProvider;->token(Landroid/net/Uri;)Ljava/lang/String;
    const-string v0, "image/png"
    return-object v0
.end method

.method public query(Landroid/net/Uri;[Ljava/lang/String;Ljava/lang/String;[Ljava/lang/String;Ljava/lang/String;)Landroid/database/Cursor;
    .registers 6
    const/4 p1, 0
    return-object p1
.end method

.method public insert(Landroid/net/Uri;Landroid/content/ContentValues;)Landroid/net/Uri;
    .registers 3
    const/4 p1, 0
    return-object p1
.end method

.method public delete(Landroid/net/Uri;Ljava/lang/String;[Ljava/lang/String;)I
    .registers 4
    const/4 p1, 0
    return p1
.end method

.method public update(Landroid/net/Uri;Landroid/content/ContentValues;Ljava/lang/String;[Ljava/lang/String;)I
    .registers 5
    const/4 p1, 0
    return p1
.end method
