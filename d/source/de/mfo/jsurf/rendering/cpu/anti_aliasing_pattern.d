/*
 *    Copyright 2008 Christian Stussak
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

module de.mfo.jsurf.rendering.cpu.anti_aliasing_pattern;

class AntiAliasingPattern {
    static class SamplingPoint {
        private float u, v, weight;
        private this(float u, float v, float weight) {
            this.u = u; this.v = v; this.weight = weight;
        }
        float getU() { return u; }
        float getV() { return v; }
        float getWeight() { return weight; }
    }

    private SamplingPoint[] points;
    private this(SamplingPoint[] points) { this.points = points; }

    int opApply(scope int delegate(ref SamplingPoint) dg) {
        foreach (ref point; points) {
            const result = dg(point);
            if (result) return result;
        }
        return 0;
    }

    SamplingPoint[] samplingPoints() { return points.dup; }

    static AntiAliasingPattern OG_1x1;
    static AntiAliasingPattern OG_2x2;
    static AntiAliasingPattern OG_3x3;
    static AntiAliasingPattern OG_4x4;
    static AntiAliasingPattern OG_5x5;
    static AntiAliasingPattern OG_6x6;
    static AntiAliasingPattern OG_7x7;
    static AntiAliasingPattern OG_8x8;
    static AntiAliasingPattern RG_2x2;
    static AntiAliasingPattern QUINCUNX;

    static this() {
        OG_1x1 = new AntiAliasingPattern(getOGSSPattern(1));
        OG_2x2 = new AntiAliasingPattern(getOGSSPattern(2));
        OG_3x3 = new AntiAliasingPattern(getOGSSPattern(3));
        OG_4x4 = new AntiAliasingPattern(getOGSSPattern(4));
        OG_5x5 = new AntiAliasingPattern(getOGSSPattern(5));
        OG_6x6 = new AntiAliasingPattern(getOGSSPattern(6));
        OG_7x7 = new AntiAliasingPattern(getOGSSPattern(7));
        OG_8x8 = new AntiAliasingPattern(getOGSSPattern(8));
        RG_2x2 = new AntiAliasingPattern(getRGSSPattern());
        QUINCUNX = new AntiAliasingPattern(getQuincunxPattern());
    }

    private static SamplingPoint[] getOGSSPattern(int size) {
        assert(size > 0);

        float[][] weights;
        switch (size) {
            case 1:
                weights = [[1.0f]];
                break;
            case 2:
                weights = [
                    [0.25f, 0.25f],
                    [0.25f, 0.25f]
                ];
                break;
            case 3:
                weights = [
                    [0.0625f, 0.125f, 0.0625f],
                    [0.125f, 0.25f, 0.125f],
                    [0.0625f, 0.125f, 0.0625f]
                ];
                break;
            case 4:
                weights = [
                    [0.027777778f, 0.055555556f, 0.055555556f, 0.027777778f],
                    [0.055555556f, 0.11111111f, 0.11111111f, 0.055555556f],
                    [0.055555556f, 0.11111111f, 0.11111111f, 0.055555556f],
                    [0.027777778f, 0.055555556f, 0.055555556f, 0.027777778f]
                ];
                break;
            case 5:
                weights = [
                    [0.012345679f, 0.024691358f, 0.037037037f, 0.024691358f, 0.012345679f],
                    [0.024691358f, 0.049382716f, 0.074074075f, 0.049382716f, 0.024691358f],
                    [0.037037037f, 0.074074075f, 0.11111111f, 0.074074075f, 0.037037037f],
                    [0.024691358f, 0.049382716f, 0.074074075f, 0.049382716f, 0.024691358f],
                    [0.012345679f, 0.024691358f, 0.037037037f, 0.024691358f, 0.012345679f]
                ];
                break;
            case 6:
                weights = [
                    [0.0069444445f, 0.013888889f, 0.020833334f, 0.020833334f, 0.013888889f, 0.0069444445f],
                    [0.013888889f, 0.027777778f, 0.041666668f, 0.041666668f, 0.027777778f, 0.013888889f],
                    [0.020833334f, 0.041666668f, 0.0625f, 0.0625f, 0.041666668f, 0.020833334f],
                    [0.020833334f, 0.041666668f, 0.0625f, 0.0625f, 0.041666668f, 0.020833334f],
                    [0.013888889f, 0.027777778f, 0.041666668f, 0.041666668f, 0.027777778f, 0.013888889f],
                    [0.0069444445f, 0.013888889f, 0.020833334f, 0.020833334f, 0.013888889f, 0.0069444445f]
                ];
                break;
            case 7:
                weights = [
                    [0.00390625f, 0.0078125f, 0.01171875f, 0.015625f, 0.01171875f, 0.0078125f, 0.00390625f],
                    [0.0078125f, 0.015625f, 0.0234375f, 0.03125f, 0.0234375f, 0.015625f, 0.0078125f],
                    [0.01171875f, 0.0234375f, 0.03515625f, 0.046875f, 0.03515625f, 0.0234375f, 0.01171875f],
                    [0.015625f, 0.03125f, 0.046875f, 0.0625f, 0.046875f, 0.03125f, 0.015625f],
                    [0.01171875f, 0.0234375f, 0.03515625f, 0.046875f, 0.03515625f, 0.0234375f, 0.01171875f],
                    [0.0078125f, 0.015625f, 0.0234375f, 0.03125f, 0.0234375f, 0.015625f, 0.0078125f],
                    [0.00390625f, 0.0078125f, 0.01171875f, 0.015625f, 0.01171875f, 0.0078125f, 0.00390625f]
                ];
                break;
            case 8:
                weights = [
                    [0.0024875621f, 0.0049751243f, 0.0074626864f, 0.0099502485f, 0.0099502485f, 0.0074626864f, 0.0049751243f, 0.0024875621f],
                    [0.0049751243f, 0.0099502485f, 0.014925373f, 0.019900497f, 0.019900497f, 0.014925373f, 0.0099502485f, 0.0049751243f],
                    [0.0074626864f, 0.014925373f, 0.02238806f, 0.029850746f, 0.029850746f, 0.02238806f, 0.017412934f, 0.0074626864f],
                    [0.0099502485f, 0.019900497f, 0.029850746f, 0.039800994f, 0.039800994f, 0.029850746f, 0.019900497f, 0.0099502485f],
                    [0.0099502485f, 0.019900497f, 0.029850746f, 0.039800994f, 0.039800994f, 0.029850746f, 0.019900497f, 0.0099502485f],
                    [0.0074626864f, 0.014925373f, 0.02238806f, 0.029850746f, 0.029850746f, 0.02238806f, 0.017412934f, 0.0074626864f],
                    [0.0049751243f, 0.0099502485f, 0.014925373f, 0.019900497f, 0.019900497f, 0.014925373f, 0.0099502485f, 0.0049751243f],
                    [0.0024875621f, 0.0049751243f, 0.0074626864f, 0.0099502485f, 0.0099502485f, 0.0074626864f, 0.0049751243f, 0.0024875621f]
                ];
                break;
            default:
                throw new Exception("unsupported ordered grid size");
        }

        auto points = new SamplingPoint[size * size];
        if (size == 1) {
            points[0] = new SamplingPoint(
                0.5f, 0.5f, weights[0][0]);
        } else {
            const divisor = cast(float)(size - 1);
            for (int i = 0; i < size; ++i)
                for (int j = 0; j < size; ++j)
                    points[i * size + j] =
                        new SamplingPoint(
                            i / divisor,
                            j / divisor,
                            weights[i][j]);
        }
        return points;
    }

    private static SamplingPoint[] getRGSSPattern() {
        enum innerWeight = 0.15f;
        enum outerWeight = 0.25f * (1.0f - 4.0f * innerWeight);

        return [
            new SamplingPoint(185.416f / 1000.0f, 282.652f / 1000.0f, innerWeight),
            new SamplingPoint(282.62799f / 1000.0f, 234.047f / 1000.0f, innerWeight),
            new SamplingPoint(136.813f / 1000.0f, 185.44099f / 1000.0f, innerWeight),
            new SamplingPoint(234.026f / 1000.0f, 136.838f / 1000.0f, innerWeight),
            new SamplingPoint(0.0f, 0.0f, outerWeight),
            new SamplingPoint(0.0f, 1.0f, outerWeight),
            new SamplingPoint(1.0f, 1.0f, outerWeight),
            new SamplingPoint(1.0f, 0.0f, outerWeight)
        ];
    }

    private static SamplingPoint[] getQuincunxPattern() {
        enum boundaryWeight = 0.0625f + 0.25f / 3.0f;
        return [
            new SamplingPoint(0.0f, 0.0f, boundaryWeight),
            new SamplingPoint(0.0f, 1.0f, boundaryWeight),
            new SamplingPoint(1.0f, 1.0f, boundaryWeight),
            new SamplingPoint(1.0f, 0.0f, boundaryWeight),
            new SamplingPoint(
                0.5f, 0.5f, 1.0f - 4.0f * boundaryWeight)
        ];
    }
}

unittest {
    float sum;
    foreach (point; AntiAliasingPattern.OG_4x4)
        sum += point.getWeight();
    assert(sum > 0.999f && sum < 1.001f);
}
