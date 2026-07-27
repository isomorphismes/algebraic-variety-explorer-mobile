package org.algebraicvarietyexplorer.render;

public enum RenderQuality {
    INTERACTIVE(144),
    FINAL(384);

    private final int maximumDimension;

    RenderQuality(int maximumDimension) {
        this.maximumDimension = maximumDimension;
    }

    public int maximumDimension() {
        return maximumDimension;
    }
}
