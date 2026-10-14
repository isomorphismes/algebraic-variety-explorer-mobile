/*
 * Experimental Java-free Android shell for the maintained SURFER C ray tracer.
 * Android's platform NativeActivity and the pinned NDK native_app_glue handle
 * activity/input lifecycle. This is not the shipping UI or its oracle yet.
 *
 * Derived work: Christian Stussak's jsurf/SURFER (Apache-2.0), see NOTICE.
 */
#include "presets.h"

#include <android/input.h>
#include <android/log.h>
#include <android/looper.h>
#include <android/native_window.h>
#include <android/window.h>
#include <android_native_app_glue.h>
#include <math.h>
#include <stdint.h>
#include <stdlib.h>

#define AVE_LOG(...) __android_log_print(ANDROID_LOG_INFO, "SurferNative", __VA_ARGS__)
#define AVE_LOG_ERROR(...) __android_log_print(ANDROID_LOG_ERROR, "SurferNative", __VA_ARGS__)
#define AVE_MAX_RENDER_SIDE 256

typedef struct {
    ave_native_preset preset;
    size_t preset_index;
    double yaw;
    double pitch;
    double zoom;
    int redraw;
    int fingers;
    int used_pinch;
    float last_x;
    float last_y;
    float start_x;
    float start_y;
    float last_distance;
} ave_engine;

static double clamp_value(double value, double minimum, double maximum)
{
    if (value < minimum) return minimum;
    if (value > maximum) return maximum;
    return value;
}

static void select_preset(ave_engine *engine, size_t index)
{
    if (ave_native_load_preset(index, &engine->preset)) {
        engine->preset_index = index;
        engine->redraw = 1;
        AVE_LOG("preset=%zu name=%s", index, engine->preset.name);
    }
}

static int32_t input_event(struct android_app *app, AInputEvent *event)
{
    if (AInputEvent_getType(event) != AINPUT_EVENT_TYPE_MOTION) {
        return 0;
    }

    ave_engine *engine = (ave_engine *)app->userData;
    const int32_t action =
        AMotionEvent_getAction(event) & AMOTION_EVENT_ACTION_MASK;
    const size_t pointers = AMotionEvent_getPointerCount(event);
    const float x = AMotionEvent_getX(event, 0);
    const float y = AMotionEvent_getY(event, 0);

    if (action == AMOTION_EVENT_ACTION_DOWN) {
        engine->fingers = 1;
        engine->used_pinch = 0;
        engine->last_x = engine->start_x = x;
        engine->last_y = engine->start_y = y;
        engine->last_distance = 0.0f;
        return 1;
    }

    if (action == AMOTION_EVENT_ACTION_POINTER_DOWN && pointers >= 2) {
        const float x2 = AMotionEvent_getX(event, 1);
        const float y2 = AMotionEvent_getY(event, 1);
        engine->fingers = 2;
        engine->used_pinch = 1;
        engine->last_distance = hypotf(x2 - x, y2 - y);
        return 1;
    }

    if (action == AMOTION_EVENT_ACTION_MOVE && pointers >= 2) {
        const float x2 = AMotionEvent_getX(event, 1);
        const float y2 = AMotionEvent_getY(event, 1);
        const float distance = hypotf(x2 - x, y2 - y);
        if (engine->last_distance > 4.0f && distance > 4.0f) {
            engine->zoom = clamp_value(
                engine->zoom * (double)distance / (double)engine->last_distance,
                0.5, 4.0);
            engine->redraw = 1;
        }
        engine->fingers = 2;
        engine->used_pinch = 1;
        engine->last_distance = distance;
        return 1;
    }

    if (action == AMOTION_EVENT_ACTION_MOVE &&
        pointers == 1 && engine->fingers == 1 && !engine->used_pinch) {
        const float dx = x - engine->last_x;
        const float dy = y - engine->last_y;
        if (app->window != NULL) {
            const int32_t width = ANativeWindow_getWidth(app->window);
            const int32_t height = ANativeWindow_getHeight(app->window);
            const int32_t smaller = width < height ? width : height;
            if (smaller > 0) {
                engine->yaw += 3.141592653589793 * (double)dx / smaller;
                engine->pitch = clamp_value(
                    engine->pitch + 3.141592653589793 * (double)dy / smaller,
                    -1.57, 1.57);
                engine->redraw = 1;
            }
        }
        engine->last_x = x;
        engine->last_y = y;
        return 1;
    }

    if (action == AMOTION_EVENT_ACTION_POINTER_UP) {
        engine->fingers = 0;
        engine->used_pinch = 1;
        return 1;
    }

    if (action == AMOTION_EVENT_ACTION_UP) {
        const float distance = hypotf(x - engine->start_x, y - engine->start_y);
        if (engine->fingers == 1 && !engine->used_pinch && distance < 12.0f) {
            select_preset(engine,
                (engine->preset_index + 1) % ave_native_preset_count());
        }
        engine->fingers = 0;
        return 1;
    }

    if (action == AMOTION_EVENT_ACTION_CANCEL) {
        engine->fingers = 0;
        return 1;
    }
    return 0;
}

static void app_command(struct android_app *app, int32_t command)
{
    ave_engine *engine = (ave_engine *)app->userData;
    switch (command) {
        case APP_CMD_INIT_WINDOW:
            if (app->window != NULL) {
                if (ANativeWindow_setBuffersGeometry(
                        app->window, 0, 0, WINDOW_FORMAT_RGBA_8888) != 0) {
                    AVE_LOG_ERROR("cannot request RGBA_8888 window buffer");
                }
                engine->redraw = 1;
            }
            break;
        case APP_CMD_WINDOW_RESIZED:
        case APP_CMD_WINDOW_REDRAW_NEEDED:
        case APP_CMD_GAINED_FOCUS:
        case APP_CMD_CONFIG_CHANGED:
            engine->redraw = 1;
            break;
        default:
            break;
    }
}

/* The underlying SURFER renderer uses mathematical y-up row order.
 * Flip once when writing Android's y-down RGBA window. */
static void draw_frame(struct android_app *app, ave_engine *engine)
{
    ANativeWindow *window = app->window;
    if (window == NULL) return;

    const int32_t window_width = ANativeWindow_getWidth(window);
    const int32_t window_height = ANativeWindow_getHeight(window);
    const int32_t square =
        window_width < window_height ? window_width : window_height;
    if (square < 2) return;

    const size_t side = square < AVE_MAX_RENDER_SIDE ?
        (size_t)square : AVE_MAX_RENDER_SIDE;
    uint32_t *pixels = (uint32_t *)malloc(side * side * sizeof(*pixels));
    if (pixels == NULL) {
        AVE_LOG_ERROR("render buffer allocation failed");
        return;
    }

    const surfer_scene scene = surfer_default_scene(&engine->preset.surface);
    if (!surfer_render_orthographic(&scene, side, side, 2.15,
            engine->yaw, engine->pitch, engine->zoom, pixels)) {
        AVE_LOG_ERROR("SURFER renderer rejected request");
        free(pixels);
        return;
    }

    const uint32_t background = surfer_color_to_argb(scene.background);
    size_t foreground = 0;
    for (size_t k = 0; k < side * side; ++k) {
        if (pixels[k] != background) ++foreground;
    }
    AVE_LOG("frame preset=%zu size=%zux%zu foreground=%zu",
        engine->preset_index, side, side, foreground);

    ANativeWindow_Buffer buffer;
    if (ANativeWindow_lock(window, &buffer, NULL) != 0) {
        AVE_LOG_ERROR("unable to lock native window");
        free(pixels);
        return;
    }

    if (buffer.format == WINDOW_FORMAT_RGBA_8888) {
        const int32_t edge =
            buffer.width < buffer.height ? buffer.width : buffer.height;
        const int32_t x_offset = (buffer.width - edge) / 2;
        const int32_t y_offset = (buffer.height - edge) / 2;
        for (int32_t y = 0; y < buffer.height; ++y) {
            uint8_t *row = (uint8_t *)buffer.bits +
                (size_t)y * (size_t)buffer.stride * 4;
            for (int32_t x = 0; x < buffer.width; ++x) {
                uint8_t red = 18, green = 22, blue = 28;
                if (x >= x_offset && y >= y_offset &&
                    x < x_offset + edge && y < y_offset + edge) {
                    const size_t u = (size_t)(x - x_offset) * side / (size_t)edge;
                    const size_t v = (size_t)(y - y_offset) * side / (size_t)edge;
                    const uint32_t argb = pixels[(side - 1 - v) * side + u];
                    red = (uint8_t)(argb >> 16);
                    green = (uint8_t)(argb >> 8);
                    blue = (uint8_t)argb;
                }
                /* Seven native marks show which preset a tap selected. */
                if (y < 14 && (size_t)x * ave_native_preset_count() /
                        (size_t)buffer.width == engine->preset_index) {
                    red = 225; green = 229; blue = 238;
                }
                uint8_t *rgba = row + (size_t)x * 4;
                rgba[0] = red;
                rgba[1] = green;
                rgba[2] = blue;
                rgba[3] = 255;
            }
        }
    } else {
        AVE_LOG_ERROR("unexpected window format=%d", buffer.format);
    }

    ANativeWindow_unlockAndPost(window);
    free(pixels);
}

void android_main(struct android_app *app)
{
    ave_engine engine = {0};
    engine.zoom = 1.0;
    app->userData = &engine;
    app->onAppCmd = app_command;
    app->onInputEvent = input_event;
    select_preset(&engine, 0);

    AVE_LOG("starting Java-free SURFER NativeActivity");
    while (!app->destroyRequested) {
        int events = 0;
        struct android_poll_source *source = NULL;
        const int timeout = engine.redraw ? 0 : -1;
        const int id = ALooper_pollOnce(timeout, NULL, &events, (void **)&source);
        if (id >= 0 && source != NULL) {
            source->process(app, source);
        }
        if (app->destroyRequested) break;
        if (app->window != NULL && engine.redraw) {
            engine.redraw = 0;
            draw_frame(app, &engine);
        }
    }
    AVE_LOG("native activity finished");
}
