/* Java-free NativeActivity preset boundary. Apache-2.0; see NOTICE. */
#ifndef AVE_NATIVE_PRESETS_H
#define AVE_NATIVE_PRESETS_H

#include "../surfer_raytracer.h"

#define AVE_MAX_PRESET_TERMS 32

typedef struct {
    const char *name;
    surfer_prepared_surface surface;
    surfer_term derivatives[3][AVE_MAX_PRESET_TERMS];
} ave_native_preset;

size_t ave_native_preset_count(void);
bool ave_native_load_preset(size_t index, ave_native_preset *result);

#endif
