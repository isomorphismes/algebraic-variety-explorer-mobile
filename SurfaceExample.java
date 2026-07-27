package org.algebraicvarietyexplorer.samples;

public final class SurfaceExample {
    public final String name;
    public final String formula;

    public SurfaceExample(String name, String formula) {
        this.name = name;
        this.formula = formula;
    }

    @Override
    public String toString() {
        return name;
    }
}
