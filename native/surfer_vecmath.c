/*
 * $RCSfile$
 *
 * Copyright 1996-2008 Sun Microsystems, Inc.  All Rights Reserved.
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
 *
 * This code is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 only, as
 * published by the Free Software Foundation.  Sun designates this
 * particular file as subject to the "Classpath" exception as provided
 * by Sun in the LICENSE file that accompanied this code.
 *
 * This code is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * version 2 for more details (a copy is included in the LICENSE file that
 * accompanied this code).
 *
 * You should have received a copy of the GNU General Public License version
 * 2 along with this work; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * Please contact Sun Microsystems, Inc., 4150 Network Circle, Santa Clara,
 * CA 95054 USA or visit www.sun.com if you need additional information or
 * have any questions.
 *
 * $Revision: 127 $
 * $Date: 2008-02-28 21:18:51 +0100 (Thu, 28 Feb 2008) $
 * $State$
 */
/* C adaptation copyright 2026 AVE contributors. Source: vecmath1.5.2,
 * archiveSHA7bea4e97b737757c14bc346a45bb5e57a3f6ddd5c1bafe51e4d1eacd64347030.
 * This module has no application types, allocator, JNI state or UI behavior.
 */
#include "surfer_vecmath.h"
#include <math.h>
#include <stddef.h>
#include <string.h>

surfer_vecmath_matrix4 surfer_vecmath_identity4(void)
{
    return (surfer_vecmath_matrix4){{1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1}};
}

surfer_vecmath_matrix4 surfer_vecmath_multiply4(surfer_vecmath_matrix4 left, surfer_vecmath_matrix4 right)
{
    surfer_vecmath_matrix4 result;
    for (size_t row = 0; row < 4; ++row) for (size_t column = 0; column < 4; ++column)
        result.entries[row * 4 + column] = left.entries[row * 4] * right.entries[column] +
            left.entries[row * 4 + 1] * right.entries[4 + column] +
            left.entries[row * 4 + 2] * right.entries[8 + column] +
            left.entries[row * 4 + 3] * right.entries[12 + column];
    return result;
}

bool surfer_vecmath_inverse4(surfer_vecmath_matrix4 input,
    surfer_vecmath_matrix4 *inverse, surfer_vecmath_continue proceed, void *state)
{
    double values[16], row_scale[4];
    int permutation[4];
    memcpy(values, input.entries, sizeof(values));
    for (int row = 0; row < 4; ++row) {
        double largest = 0.0;
        for (int column = 0; column < 4; ++column) {
            const double absolute = fabs(values[4 * row + column]);
            if (absolute > largest) largest = absolute;
        }
        if (largest == 0.0) return false;
        row_scale[row] = 1.0 / largest;
    }
    for (int column = 0; column < 4; ++column) {
        if (proceed != NULL && !proceed(state)) return false;
        for (int row = 0; row < column; ++row) {
            double sum = values[4 * row + column];
            for (int previous = 0; previous < row; ++previous)
                sum -= values[4 * row + previous] * values[4 * previous + column];
            values[4 * row + column] = sum;
        }
        double largest = 0.0;
        int pivot = -1;
        for (int row = column; row < 4; ++row) {
            double sum = values[4 * row + column];
            for (int previous = 0; previous < column; ++previous)
                sum -= values[4 * row + previous] * values[4 * previous + column];
            values[4 * row + column] = sum;
            const double scaled = row_scale[row] * fabs(sum);
            if (scaled >= largest) { largest = scaled; pivot = row; }
        }
        if (pivot < 0) return false;
        if (column != pivot) {
            for (int index = 0; index < 4; ++index) {
                const double temporary = values[4 * pivot + index];
                values[4 * pivot + index] = values[4 * column + index];
                values[4 * column + index] = temporary;
            }
            row_scale[pivot] = row_scale[column];
        }
        permutation[column] = pivot;
        if (values[4 * column + column] == 0.0) return false;
        if (column != 3) {
            const double reciprocal = 1.0 / values[4 * column + column];
            for (int row = column + 1; row < 4; ++row) values[4 * row + column] *= reciprocal;
        }
    }
    *inverse = surfer_vecmath_identity4();
    for (int column = 0; column < 4; ++column) {
        if (proceed != NULL && !proceed(state)) return false;
        int first = -1;
        for (int row = 0; row < 4; ++row) {
            const int pivot = permutation[row];
            double sum = inverse->entries[column + 4 * pivot];
            inverse->entries[column + 4 * pivot] = inverse->entries[column + 4 * row];
            if (first >= 0) for (int previous = first; previous <= row - 1; ++previous)
                sum -= values[4 * row + previous] * inverse->entries[column + 4 * previous];
            else if (sum != 0.0) first = row;
            inverse->entries[column + 4 * row] = sum;
        }
        inverse->entries[column + 12] /= values[15];
        inverse->entries[column + 8] = (inverse->entries[column + 8] -
            values[11] * inverse->entries[column + 12]) / values[10];
        inverse->entries[column + 4] = (inverse->entries[column + 4] -
            values[6] * inverse->entries[column + 8] -
            values[7] * inverse->entries[column + 12]) / values[5];
        inverse->entries[column] = (inverse->entries[column] -
            values[1] * inverse->entries[column + 4] -
            values[2] * inverse->entries[column + 8] -
            values[3] * inverse->entries[column + 12]) / values[0];
    }
    for (size_t index = 0; index < 16; ++index) if (!isfinite(inverse->entries[index])) return false;
    return true;
}

surfer_vecmath_vector3 surfer_vecmath_transform_vector4(surfer_vecmath_matrix4 matrix, surfer_vecmath_vector3 value)
{
    const double *entries = matrix.entries;
    return (surfer_vecmath_vector3){
        entries[0] * value.x + entries[1] * value.y + entries[2] * value.z + entries[3] * 0.0,
        entries[4] * value.x + entries[5] * value.y + entries[6] * value.z + entries[7] * 0.0,
        entries[8] * value.x + entries[9] * value.y + entries[10] * value.z + entries[11] * 0.0};
}

surfer_vecmath_vector3 surfer_vecmath_transform_point4(surfer_vecmath_matrix4 matrix, surfer_vecmath_vector3 value)
{
    const double *entries = matrix.entries;
    return (surfer_vecmath_vector3){
        entries[0] * value.x + entries[1] * value.y + entries[2] * value.z + entries[3],
        entries[4] * value.x + entries[5] * value.y + entries[6] * value.z + entries[7],
        entries[8] * value.x + entries[9] * value.y + entries[10] * value.z + entries[11]};
}
