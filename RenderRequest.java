package org.algebraicvarietyexplorer.render;

public final class RenderRequest {
    public final String formula;
    public final double yaw;
    public final double pitch;
    public final double zoom;
    public final int width;
    public final int height;
    public final RenderQuality quality;

    public RenderRequest(
            String formula,
            double yaw,
            double pitch,
            double zoom,
            int width,
            int height,
            RenderQuality quality) {
        this.formula = formula;
        this.yaw = yaw;
        this.pitch = pitch;
        this.zoom = zoom;
        this.width = width;
        this.height = height;
        this.quality = quality;
    }
}
