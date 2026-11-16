.class public final Lorg/algebraicvarietyexplorer/idricqualification/ExportCloseListener;
.super Ljava/lang/Object;
.implements Landroid/os/ParcelFileDescriptor$OnCloseListener;

.field private final closed:Ljava/io/File;
.field private final failed:Ljava/io/File;

.method public constructor <init>(Ljava/io/File;Ljava/io/File;)V
    .registers 3
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    iput-object p1, p0, Lorg/algebraicvarietyexplorer/idricqualification/ExportCloseListener;->closed:Ljava/io/File;
    iput-object p2, p0, Lorg/algebraicvarietyexplorer/idricqualification/ExportCloseListener;->failed:Ljava/io/File;
    return-void
.end method

.method public onClose(Ljava/io/IOException;)V
    .registers 3
    if-eqz p1, :clean
    iget-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/ExportCloseListener;->failed:Ljava/io/File;
    goto :record
  :clean
    iget-object v0, p0, Lorg/algebraicvarietyexplorer/idricqualification/ExportCloseListener;->closed:Ljava/io/File;
  :record
    invoke-virtual {v0}, Ljava/io/File;->createNewFile()Z
    return-void
.end method
