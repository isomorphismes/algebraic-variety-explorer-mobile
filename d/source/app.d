module app;

import std.getopt : defaultGetoptPrinter, getopt;
import std.stdio : File, stderr, writeln;
import std.string : toLower;

import surfer.math3 : Affine, Color, Vec3;
import surfer.render : AntiAliasingMode, AntiAliasingPattern, Renderer;

int main(string[] arguments) {
    string output_path = "surfer.ppm";
    string formula = "x^2+y^2+z^2-0.64";
    uint width = 512;
    uint height = 512;
    double yaw = 0.55;
    double pitch = -0.35;
    double zoom = 1.0;
    string aa = "quincunx";
    try {
        auto option_result = getopt(
            arguments,
            "output|o", &output_path,
            "formula|f", &formula,
            "width", &width,
            "height", &height,
            "yaw", &yaw,
            "pitch", &pitch,
            "zoom", &zoom,
            "aa", &aa
        );
        if (option_result.helpWanted) {
            defaultGetoptPrinter(
                "Desktop D translation of Christian Stussak's jsurf/SURFER renderer\n"
                ~ "\n"
                ~ "  surfer-d [options]\n",
                option_result.options
            );
            return 0;
        }

        auto renderer = new Renderer();
        renderer.set_surface_family(formula);
        renderer.background = Color(0.075f, 0.09f, 0.115f);
        renderer.camera.height = 2.15 / zoom;
        renderer.camera.transform = Affine.translation_by(Vec3(0.0, 0.0, -1.0));
        renderer.transform = Affine.rotation_y(yaw) * Affine.rotation_x(pitch);

        renderer.front_material.color = Color(0.90f, 0.47f, 0.18f);
        renderer.front_material.ambient = 0.32f;
        renderer.front_material.diffuse = 0.76f;
        renderer.front_material.specular = 0.55f;
        renderer.front_material.shininess = 24.0f;

        renderer.back_material.color = Color(0.93f, 0.76f, 0.40f);
        renderer.back_material.ambient = 0.30f;
        renderer.back_material.diffuse = 0.72f;
        renderer.back_material.specular = 0.45f;
        renderer.back_material.shininess = 18.0f;

        configure_light(renderer, 0, Vec3(-100.0, 100.0, 100.0), 0.55f);
        configure_light(renderer, 1, Vec3(100.0, 100.0, 100.0), 0.70f);
        configure_light(renderer, 2, Vec3(0.0, -100.0, 100.0), 0.30f);

        renderer.anti_aliasing_mode = AntiAliasingMode.adaptive_supersampling;
        renderer.anti_aliasing_pattern = parse_anti_aliasing(aa);

        writeln("formula degree: ", renderer.surface_total_degree());
        auto pixels = renderer.draw(width, height);
        write_ppm(output_path, pixels, width, height);
        writeln("wrote ", output_path, " (", width, "x", height, ")");
        return 0;
    } catch (Exception error) {
        stderr.writeln("surfer-d: ", error.msg);
        return 1;
    }
}

private void configure_light(Renderer renderer, size_t index, Vec3 position, float intensity) {
    renderer.lights[index].enabled = true;
    renderer.lights[index].position = position;
    renderer.lights[index].color = Color(1.0f, 1.0f, 1.0f);
    renderer.lights[index].intensity = intensity;
}

private AntiAliasingPattern parse_anti_aliasing(string name) {
    switch (name.toLower()) {
        case "1", "1x1", "og1": return AntiAliasingPattern.og_1x1;
        case "2", "2x2", "og2": return AntiAliasingPattern.og_2x2;
        case "3", "3x3", "og3": return AntiAliasingPattern.og_3x3;
        case "4", "4x4", "og4": return AntiAliasingPattern.og_4x4;
        case "5", "5x5", "og5": return AntiAliasingPattern.og_5x5;
        case "6", "6x6", "og6": return AntiAliasingPattern.og_6x6;
        case "7", "7x7", "og7": return AntiAliasingPattern.og_7x7;
        case "8", "8x8", "og8": return AntiAliasingPattern.og_8x8;
        case "rg", "rg2", "rg2x2": return AntiAliasingPattern.rg_2x2;
        case "quincunx": return AntiAliasingPattern.quincunx;
        default: throw new Exception("unknown anti-aliasing pattern: " ~ name);
    }
}

private void write_ppm(string path, const(uint)[] pixels, uint width, uint height) {
    auto file = File(path, "wb");
    file.write("P6\n", width, " ", height, "\n255\n");
    auto row = new ubyte[cast(size_t) width * 3];
    foreach (output_y; 0 .. height) {
        const source_y = height - 1 - output_y;
        foreach (x; 0 .. width) {
            const pixel = pixels[cast(size_t) source_y * width + x];
            row[3 * x + 0] = cast(ubyte) ((pixel >> 16) & 0xff);
            row[3 * x + 1] = cast(ubyte) ((pixel >> 8) & 0xff);
            row[3 * x + 2] = cast(ubyte) (pixel & 0xff);
        }
        file.rawWrite(row);
    }
}
