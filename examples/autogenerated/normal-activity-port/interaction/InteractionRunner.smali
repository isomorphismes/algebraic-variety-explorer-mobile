.class public LInteractionRunner;
.super Ljava/lang/Object;

# Independent constant expectations derived from the original interaction.
# This observer contains no source state, source constructors or field logic.
.method private static fail()V
    .registers 2
    sget-object v0, Ljava/lang/System;->err:Ljava/io/PrintStream;
    const-string v1, "FAIL Explorer interaction and quality source"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/16 v0, 87
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
    return-void
.end method

.method private static same_int(II)V
    .registers 2
    if-eq p0, p1, :ok
    invoke-static {}, LInteractionRunner;->fail()V
  :ok
    return-void
.end method

.method private static same_double(JLjava/lang/String;)V
    .registers 6
    invoke-static {p2}, Ljava/lang/Double;->parseDouble(Ljava/lang/String;)D
    move-result-wide v0
    invoke-static {v0, v1}, Ljava/lang/Double;->doubleToRawLongBits(D)J
    move-result-wide v0
    cmp-long v2, p0, v0
    if-eqz v2, :ok
    invoke-static {}, LInteractionRunner;->fail()V
  :ok
    return-void
.end method

.method private static same_long(JJ)V
    .registers 5
    cmp-long v0, p0, p2
    if-eqz v0, :ok
    invoke-static {}, LInteractionRunner;->fail()V
  :ok
    return-void
.end method

.method private static size(ZIIII)V
    .registers 6
    invoke-static {p0, p1, p2}, LIdric/Generated;->interaction_request_width(ZII)I
    move-result v0
    invoke-static {v0, p3}, LInteractionRunner;->same_int(II)V
    invoke-static {p0, p1, p2}, LIdric/Generated;->interaction_request_height(ZII)I
    move-result v0
    invoke-static {v0, p4}, LInteractionRunner;->same_int(II)V
    return-void
.end method

.method private static observe()V
    .registers 8
    # (33554432f - 1f) rounds to33554432f before widening.
    const v0, 1065353216
    const v1, 1275068416
    const v2, 33554432
    invoke-static {v0, v1, v2}, LIdric/Generated;->interaction_drag_yaw_bits(III)J
    move-result-wide v0
    const-string v2, "5.26238898038469"
    invoke-static {v0, v1, v2}, LInteractionRunner;->same_double(JLjava/lang/String;)V

    const/4 v0, 0
    const v1, 1148846080
    const/4 v2, 1
    invoke-static {v0, v1, v2}, LIdric/Generated;->interaction_drag_pitch_bits(III)J
    move-result-wide v0
    const-string v2, "1.45"
    invoke-static {v0, v1, v2}, LInteractionRunner;->same_double(JLjava/lang/String;)V
    const/4 v0, 0
    const v1, -998637568
    const/4 v2, 1
    invoke-static {v0, v1, v2}, LIdric/Generated;->interaction_drag_pitch_bits(III)J
    move-result-wide v0
    const-string v2, "-1.45"
    invoke-static {v0, v1, v2}, LInteractionRunner;->same_double(JLjava/lang/String;)V

    # 3 * widen(0.2f), rather than widen(3f * 0.2f).
    const/4 v0, 3
    const v1, 1045220557
    invoke-static {v0, v1}, LIdric/Generated;->interaction_scale_zoom_bits(II)J
    move-result-wide v0
    const-string v2, "0.6000000089406967"
    invoke-static {v0, v1, v2}, LInteractionRunner;->same_double(JLjava/lang/String;)V
    const/4 v0, 1
    const/4 v1, 0
    invoke-static {v0, v1}, LIdric/Generated;->interaction_scale_zoom_bits(II)J
    move-result-wide v0
    const-string v2, "0.45"
    invoke-static {v0, v1, v2}, LInteractionRunner;->same_double(JLjava/lang/String;)V
    const/4 v0, 3
    const v1, 1073741824
    invoke-static {v0, v1}, LIdric/Generated;->interaction_scale_zoom_bits(II)J
    move-result-wide v0
    const-string v2, "4.0"
    invoke-static {v0, v1, v2}, LInteractionRunner;->same_double(JLjava/lang/String;)V

    const/4 v0, 2
    const/4 v1, 0
    invoke-static {v0, v1}, LIdric/Generated;->interaction_blocked_move_yaw_bits(IZ)J
    move-result-wide v0
    const-string v2, "0.5971238898038469"
    invoke-static {v0, v1, v2}, LInteractionRunner;->same_double(JLjava/lang/String;)V
    const/4 v0, 1
    const/4 v1, 1
    invoke-static {v0, v1}, LIdric/Generated;->interaction_blocked_move_yaw_bits(IZ)J
    move-result-wide v0
    const-string v2, "0.5971238898038469"
    invoke-static {v0, v1, v2}, LInteractionRunner;->same_double(JLjava/lang/String;)V
    const/16 v0, 100
    invoke-static {v0}, LIdric/Generated;->interaction_reset_drag_yaw_bits(I)J
    move-result-wide v0
    const-string v2, "0.5971238898038469"
    invoke-static {v0, v1, v2}, LInteractionRunner;->same_double(JLjava/lang/String;)V

    const/16 v0, 100
    invoke-static {v0}, LIdric/Generated;->interaction_initial_move_yaw_bits(I)J
    move-result-wide v0
    const-string v2, "0.5971238898038469"
    invoke-static {v0, v1, v2}, LInteractionRunner;->same_double(JLjava/lang/String;)V

    const/4 v0, 1
    const/4 v1, 0
    const-wide/16 v2, 69
    const-wide/16 v4, 0
    invoke-static/range {v0 .. v5}, LIdric/Generated;->interaction_notify_timestamp(ZZJJ)J
    move-result-wide v0
    const-wide/16 v2, 0
    invoke-static {v0, v1, v2, v3}, LInteractionRunner;->same_long(JJ)V
    const/4 v0, 1
    const/4 v1, 0
    const-wide/16 v2, 70
    const-wide/16 v4, 0
    invoke-static/range {v0 .. v5}, LIdric/Generated;->interaction_notify_timestamp(ZZJJ)J
    move-result-wide v0
    const-wide/16 v2, 70
    invoke-static {v0, v1, v2, v3}, LInteractionRunner;->same_long(JJ)V
    const/4 v0, 1
    const/4 v1, 1
    const-wide/16 v2, 141
    const-wide/16 v4, 140
    invoke-static/range {v0 .. v5}, LIdric/Generated;->interaction_notify_timestamp(ZZJJ)J
    move-result-wide v0
    const-wide/16 v2, 141
    invoke-static {v0, v1, v2, v3}, LInteractionRunner;->same_long(JJ)V
    const/4 v0, 1
    const/4 v1, 0
    const-wide/16 v2, 210
    const-wide/16 v4, 141
    invoke-static/range {v0 .. v5}, LIdric/Generated;->interaction_notify_timestamp(ZZJJ)J
    move-result-wide v0
    const-wide/16 v2, 141
    invoke-static {v0, v1, v2, v3}, LInteractionRunner;->same_long(JJ)V
    const/4 v0, 1
    const/4 v1, 0
    const-wide/16 v2, 211
    const-wide/16 v4, 141
    invoke-static/range {v0 .. v5}, LIdric/Generated;->interaction_notify_timestamp(ZZJJ)J
    move-result-wide v0
    const-wide/16 v2, 211
    invoke-static {v0, v1, v2, v3}, LInteractionRunner;->same_long(JJ)V
    const/4 v0, 0
    const/4 v1, 1
    const-wide/16 v2, 100
    const-wide/16 v4, 0
    invoke-static/range {v0 .. v5}, LIdric/Generated;->interaction_notify_timestamp(ZZJJ)J
    move-result-wide v0
    const-wide/16 v2, 0
    invoke-static {v0, v1, v2, v3}, LInteractionRunner;->same_long(JJ)V

    const/4 v0, 0
    const/16 v1, 288
    const/16 v2, 65
    const/16 v3, 144
    const/16 v4, 33
    invoke-static {v0, v1, v2, v3, v4}, LInteractionRunner;->size(ZIIII)V
    const/4 v0, 1
    const/16 v1, 768
    const/16 v2, 65
    const/16 v3, 384
    const/16 v4, 33
    invoke-static {v0, v1, v2, v3, v4}, LInteractionRunner;->size(ZIIII)V
    const/4 v0, 0
    const/16 v1, 10000
    const/4 v2, 1
    const/16 v3, 144
    const/16 v4, 32
    invoke-static {v0, v1, v2, v3, v4}, LInteractionRunner;->size(ZIIII)V
    const/4 v0, 1
    const/16 v3, 384
    invoke-static {v0, v1, v2, v3, v4}, LInteractionRunner;->size(ZIIII)V
    const/4 v0, 0
    const/16 v1, 10
    const/16 v2, 100
    const/16 v3, 32
    const/16 v4, 100
    invoke-static {v0, v1, v2, v3, v4}, LInteractionRunner;->size(ZIIII)V
    const/4 v0, 1
    invoke-static {v0, v1, v2, v3, v4}, LInteractionRunner;->size(ZIIII)V
    const/4 v0, 0
    const/16 v1, 100
    const/16 v2, 100
    const/16 v3, 100
    const/16 v4, 100
    invoke-static {v0, v1, v2, v3, v4}, LInteractionRunner;->size(ZIIII)V
    const/4 v0, 0
    const/4 v1, 0
    const/16 v2, 100
    const/4 v3, -1
    const/4 v4, -1
    invoke-static {v0, v1, v2, v3, v4}, LInteractionRunner;->size(ZIIII)V
    const/4 v0, 1
    const/16 v1, 100
    const/4 v2, -1
    invoke-static {v0, v1, v2, v3, v4}, LInteractionRunner;->size(ZIIII)V

    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS Explorer interaction and quality source"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method

.method public static main([Ljava/lang/String;)V
    .registers 3
  :start
    invoke-static {}, LInteractionRunner;->observe()V
  :end
    return-void
    .catch Ljava/lang/Throwable; {:start .. :end} :unexpected
  :unexpected
    move-exception v0
    invoke-virtual {v0}, Ljava/lang/Throwable;->printStackTrace()V
    const/16 v1, 88
    invoke-static {v1}, Ljava/lang/System;->exit(I)V
    return-void
.end method
