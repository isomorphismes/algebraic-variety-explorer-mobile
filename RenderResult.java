package org.algebraicvarietyexplorer.render;

import android.graphics.Bitmap;

public final class RenderResult {
    public final Bitmap bitmap;
    public final int polynomialDegree;
    public final long elapsedMilliseconds;

    public RenderResult(Bitmap bitmap, int polynomialDegree, long elapsedMilliseconds) {
        this.bitmap = bitmap;
        this.polynomialDegree = polynomialDegree;
        this.elapsedMilliseconds = elapsedMilliseconds;
    }
}
