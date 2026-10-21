/* Native touch expression panel; no application Java, DEX or Java bridge.
 * Small built-in 5x7 alphabet avoids platform text APIs pending Idriç UI.
 */
#include "editor.h"
#include <ctype.h>
#include <stdint.h>
#include <string.h>

static const char *const keypad[4][6] = {
    {"x","y","z","7","8","9"},
    {"+","-","*","/","4","5"},
    {"(",")","^","=","1","2"},
    {".","<","CLR","0","3","OK"}
};

/* ASCII glyphs as seven rows of five pixel bits, highest bit at left. */
static const uint8_t font[128][7] = {
    ['0']={14,17,19,21,25,17,14}, ['1']={4,12,4,4,4,4,14},
    ['2']={14,17,1,2,4,8,31}, ['3']={30,1,1,14,1,1,30},
    ['4']={2,6,10,18,31,2,2}, ['5']={31,16,16,30,1,1,30},
    ['6']={14,16,16,30,17,17,14}, ['7']={31,1,2,4,8,8,8},
    ['8']={14,17,17,14,17,17,14}, ['9']={14,17,17,15,1,1,14},
    ['A']={14,17,17,31,17,17,17}, ['B']={30,17,17,30,17,17,30},
    ['C']={14,17,16,16,16,17,14}, ['D']={30,17,17,17,17,17,30},
    ['E']={31,16,16,30,16,16,31}, ['F']={31,16,16,30,16,16,16},
    ['G']={14,17,16,23,17,17,14}, ['H']={17,17,17,31,17,17,17},
    ['I']={14,4,4,4,4,4,14}, ['J']={7,2,2,2,18,18,12},
    ['K']={17,18,20,24,20,18,17}, ['L']={16,16,16,16,16,16,31},
    ['M']={17,27,21,21,17,17,17}, ['N']={17,25,21,19,17,17,17},
    ['O']={14,17,17,17,17,17,14}, ['P']={30,17,17,30,16,16,16},
    ['Q']={14,17,17,17,21,18,13}, ['R']={30,17,17,30,20,18,17},
    ['S']={15,16,16,14,1,1,30}, ['T']={31,4,4,4,4,4,4},
    ['U']={17,17,17,17,17,17,14}, ['V']={17,17,17,17,17,10,4},
    ['W']={17,17,17,21,21,21,10}, ['X']={17,17,10,4,10,17,17},
    ['Y']={17,17,10,4,4,4,4}, ['Z']={31,1,2,4,8,16,31},
    ['+']={0,4,4,31,4,4,0}, ['-']={0,0,0,31,0,0,0},
    ['*']={0,10,4,31,4,10,0}, ['/']={1,1,2,4,8,16,16},
    ['^']={4,10,17,0,0,0,0}, ['.']={0,0,0,0,0,12,12},
    ['(']={2,4,8,8,8,4,2}, [')']={8,4,2,2,2,4,8},
    ['=']={0,31,0,31,0,0,0}, ['<']={2,4,8,16,8,4,2},
    [' ']={0,0,0,0,0,0,0}
};
static int keypad_row_height(int width, int height)
{
    int pixels = width * 2 / 15; /* 48 px at the 360-wide emulator baseline. */
    if (pixels < 48) pixels = 48;
    if (pixels > height / 7) pixels = height / 7;
    return pixels;
}
/* Draw and hit-test against the same safe bottom, never behind Android's
 * three-button navigation bar. API 35 may extend our window under that bar. */
static int keypad_bottom(const ave_formula_editor *editor, int height)
{
    const int inset = editor->bottom_inset;
    return height - (inset >= 0 && inset <= height / 3 ? inset : 0);
}
static int text_scale(const ANativeWindow_Buffer *b)
{
    const int scale = (b->width + 179) / 180;
    return scale < 2 ? 2 : (scale > 4 ? 4 : scale);
}
static void pixel(ANativeWindow_Buffer *b, int x, int y,
                  uint8_t r, uint8_t g, uint8_t blue)
{
    if (x < 0 || y < 0 || x >= b->width || y >= b->height) return;
    uint8_t *dst = (uint8_t *)b->bits + (size_t)y * (size_t)b->stride * 4
                 + (size_t)x * 4;
    dst[0] = r; dst[1] = g; dst[2] = blue; dst[3] = 255;
}
static void rectangle(ANativeWindow_Buffer *b,
                      int x0, int y0, int x1, int y1,
                      uint8_t r, uint8_t g, uint8_t blue)
{
    if (x0 < 0) x0 = 0;
    if (y0 < 0) y0 = 0;
    if (x1 > b->width) x1 = b->width;
    if (y1 > b->height) y1 = b->height;
    for (int y = y0; y < y1; ++y)
        for (int x = x0; x < x1; ++x) pixel(b, x, y, r, g, blue);
}
static void letters(ANativeWindow_Buffer *b,
                    int x, int y, const char *value, int limit,
                    uint8_t r, uint8_t g, uint8_t blue)
{
    const int scale = text_scale(b);
    for (int i = 0; value[i] != 0 && i < limit; ++i) {
        const unsigned char ascii =
            (unsigned char)toupper((unsigned char)value[i]);
        if (ascii >= 128) continue;
        for (int row = 0; row < 7; ++row) {
            const uint8_t bits = font[ascii][row];
            for (int column = 0; column < 5; ++column)
                if ((bits & (16U >> column)) != 0)
                    for (int yy = 0; yy < scale; ++yy)
                        for (int xx = 0; xx < scale; ++xx)
                            pixel(b, x + i * 6 * scale + column * scale + xx,
                                y + row * scale + yy, r, g, blue);
        }
    }
}
int ave_editor_touch(ave_formula_editor *editor,
                     int x, int y, int width, int height)
{
    if (!editor || width <= 0 || height <= 0) return 0;
    const int button_width = width / 5 > 80 ? width / 5 : 80;
    if (y < 48 && x >= width - button_width) {
        editor->open = !editor->open;
        editor->error[0] = '\0';
        return editor->open ? 1 : 3;
    }
    if (!editor->open) return 0;
    const int row_height = keypad_row_height(width, height);
    const int bottom = keypad_bottom(editor, height);
    const int y0 = bottom - row_height * 4;
    if (y >= y0 && y < bottom && x >= 0 && x < width) {
        const size_t row = (size_t)(y - y0) / (size_t)row_height;
        const size_t column = (size_t)x * 6 / (size_t)width;
        const char *key = keypad[row][column];
        if (strcmp(key, "OK") == 0) return 2;
        if (strcmp(key, "CLR") == 0) {
            editor->input[0] = '\0';
            editor->length = 0;
        } else if (strcmp(key, "<") == 0) {
            if (editor->length) {
                --editor->length;
                while (editor->length &&
                       ((unsigned char)editor->input[editor->length] & 0xc0) == 0x80)
                    --editor->length;
                editor->input[editor->length] = '\0';
            }
        } else {
            const size_t n = strlen(key);
            if (editor->length + n <= AVE_FORMULA_MAX_SOURCE) {
                memcpy(editor->input + editor->length, key, n + 1);
                editor->length += n;
            } else {
                strcpy(editor->error, "FORMULA TOO LONG");
            }
        }
        if (editor->length <= AVE_FORMULA_MAX_SOURCE && strcmp(editor->error, "FORMULA TOO LONG") != 0)
            editor->error[0] = '\0';
        return 1;
    }
    return 1;
}
void ave_editor_draw(ANativeWindow_Buffer *b, const ave_formula_editor *editor)
{
    if (!b || !editor || b->format != WINDOW_FORMAT_RGBA_8888) return;
    if (!editor->open) {
        const int button_width = b->width / 5 > 80 ? b->width / 5 : 80;
        const int advance = 6 * text_scale(b);
        rectangle(b, b->width - button_width, 16, b->width - 3, 43,
                  38, 53, 71);
        letters(b, b->width - button_width / 2 - 2 * advance, 22,
                "EDIT", 4, 229, 232, 240);
        return;
    }
    rectangle(b, 0, 15, b->width, 121, 23, 34, 46);
    letters(b, 10, 20, "FORMULA", 7, 230, 238, 243);
    letters(b, b->width - 4 * 6 * text_scale(b) - 8, 20,
            "EDIT", 4, 182, 195, 209);
    /* The editor displays the rightmost visible characters, not a truncated input. */
    const int advance = 6 * text_scale(b);
    const size_t max_visible = b->width > 24 ?
        (size_t)(b->width - 20) / (size_t)advance : 0;
    const char *tail = editor->input;
    if (editor->length > max_visible) tail += editor->length - max_visible;
    letters(b, 10, 52, tail, (int)max_visible, 245, 246, 248);
    if (editor->error[0])
        letters(b, 10, 87, editor->error, (b->width - 20) / advance, 255, 133, 132);
    else letters(b, 10, 87, "F=0", 3, 129, 187, 209);

    const int row_height = keypad_row_height(b->width, b->height);
    const int y0 = keypad_bottom(editor, b->height) - row_height * 4;
    for (int row = 0; row < 4; ++row) {
        for (int col = 0; col < 6; ++col) {
            const int x0 = col * b->width / 6;
            const int x1 = (col + 1) * b->width / 6;
            const int by0 = y0 + row * row_height, by1 = by0 + row_height;
            const char *key = keypad[row][col];
            const int highlight = strcmp(key, "OK") == 0;
            rectangle(b, x0 + 1, by0 + 1, x1 - 1, by1 - 1,
                      highlight ? 46 : 39, highlight ? 98 : 50,
                      highlight ? 91 : 67);
            const int characters = (int)strlen(key);
            letters(b, (x0 + x1 - characters * advance) / 2,
                    by0 + (row_height - 7 * text_scale(b)) / 2,
                    key, characters, 233, 240, 241);
        }
    }
}
