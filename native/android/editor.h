/* Touch-editable, Java-free SURFER formula panel. */
#ifndef AVE_FORMULA_EDITOR_H
#define AVE_FORMULA_EDITOR_H
#include "formula.h"
#include <android/native_window.h>

typedef struct {
    bool open;
    int bottom_inset; /* System navigation inset in native-window pixels. */
    char input[AVE_FORMULA_MAX_SOURCE + 1];
    size_t length;
    char error[96];
} ave_formula_editor;

/* 0: no hit; 1: consumed/edited; 2: submit; 3: editor closed. */
int ave_editor_touch(ave_formula_editor *editor, int x, int y, int width, int height);
void ave_editor_draw(ANativeWindow_Buffer *window, const ave_formula_editor *editor);

#endif
