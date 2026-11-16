/* Private implementation included by surfer_raytracer.c.
 * Direct port of Stussak XYZPolynomial.substitute/evaluateZ and
 * XYPolynomial.evaluateY. Formula semantics and differentiation stay outside.
 */
typedef struct {
    surfer_term *terms;
    size_t count;
} original_xyz_polynomial;

typedef original_xyz_polynomial original_xy_polynomial;

typedef struct {
    original_xyz_polynomial transformed[4];
    original_xy_polynomial rows[2][4];
    double row_values[2];
    bool row_present[2];
    unsigned recent_row;
} original_render_pipeline;

static original_xyz_polynomial original_empty_xyz(void)
{
    return (original_xyz_polynomial){NULL, 0};
}

static void original_free_xyz(original_xyz_polynomial polynomial)
{
    free(polynomial.terms);
}

static original_xyz_polynomial original_allocate_xyz(
    surfer_operation_context *context, size_t count)
{
    original_xyz_polynomial result = original_empty_xyz();
    if (count == 0) return result;
    mark_allocation_path(context, UINT32_C(0x400));
    result.terms = allocate_array(context, count, sizeof(*result.terms), false);
    if (result.terms != NULL) result.count = count;
    return result;
}

static original_xyz_polynomial original_constant_xyz(
    surfer_operation_context *context, double coefficient)
{
    original_xyz_polynomial result = original_allocate_xyz(context, 1);
    if (result.count != 0) result.terms[0] = (surfer_term){coefficient, 0, 0, 0};
    return result;
}

static original_xyz_polynomial original_copy_xyz(
    surfer_operation_context *context, const original_xyz_polynomial *source)
{
    original_xyz_polynomial result = original_allocate_xyz(context, source->count);
    for (size_t index = 0; index < result.count; ++index) {
        if (!continue_operation(context)) { original_free_xyz(result); return original_empty_xyz(); }
        result.terms[index] = source->terms[index];
    }
    return result;
}

static int original_lex_compare(surfer_term left, surfer_term right)
{
    if (left.x_exponent != right.x_exponent) return left.x_exponent < right.x_exponent ? -1 : 1;
    if (left.y_exponent != right.y_exponent) return left.y_exponent < right.y_exponent ? -1 : 1;
    if (left.z_exponent != right.z_exponent) return left.z_exponent < right.z_exponent ? -1 : 1;
    return 0;
}

static int original_term_compare(surfer_term left, surfer_term right)
{
    const int lexical = original_lex_compare(left, right);
    if (lexical != 0) return lexical;
    return left.coefficient < right.coefficient ? -1 :
        (left.coefficient > right.coefficient ? 1 : 0);
}

/* Arrays.sort(Object[]) is stable, including equal-coefficient signed zeros. */
static bool original_sort_terms(surfer_operation_context *context,
    original_xyz_polynomial *polynomial)
{
    if (polynomial->count < 2) return continue_operation(context);
    surfer_term *temporary = allocate_array(context, polynomial->count, sizeof(*temporary), false);
    if (temporary == NULL) return false;
    for (size_t width = 1; width < polynomial->count;) {
        for (size_t start = 0; start < polynomial->count;) {
            const size_t middle = start + (width < polynomial->count - start ? width : polynomial->count - start);
            const size_t end = middle + (width < polynomial->count - middle ? width : polynomial->count - middle);
            size_t left = start, right = middle;
            for (size_t destination = start; destination < end; ++destination) {
                if (!continue_operation(context)) { free(temporary); return false; }
                if (right == end || (left < middle &&
                    original_term_compare(polynomial->terms[left], polynomial->terms[right]) <= 0))
                    temporary[destination] = polynomial->terms[left++];
                else temporary[destination] = polynomial->terms[right++];
            }
            start = end;
        }
        memcpy(polynomial->terms, temporary, polynomial->count * sizeof(*temporary));
        if (width > polynomial->count / 2) break;
        width *= 2;
    }
    free(temporary);
    return true;
}

/* Original collect sorts by exponent then coefficient, starts Kahan at the
 * first coefficient, and replaces an all-zero result by the positive zero. */
static bool original_collect_xyz(surfer_operation_context *context,
    original_xyz_polynomial *polynomial)
{
    if (polynomial->count == 0) return true;
    if (!original_sort_terms(context, polynomial)) return false;
    size_t output = 0;
    for (size_t start = 0; start < polynomial->count;) {
        size_t end = start + 1;
        while (end < polynomial->count &&
            original_lex_compare(polynomial->terms[start], polynomial->terms[end]) == 0) {
            if (!continue_operation(context)) return false;
            ++end;
        }
        double sum = polynomial->terms[start].coefficient;
        double correction = 0.0;
        for (size_t index = start + 1; index < end; ++index) {
            if (!continue_operation(context)) return false;
            const double corrected = polynomial->terms[index].coefficient - correction;
            const double next = sum + corrected;
            correction = (next - sum) - corrected;
            sum = next;
        }
        if (!isfinite(sum)) { context->status = SURFER_INVALID_INPUT; return false; }
        if (sum != 0.0) {
            polynomial->terms[output] = polynomial->terms[start];
            polynomial->terms[output++].coefficient = sum;
        }
        start = end;
    }
    if (output == 0) polynomial->terms[output++] = (surfer_term){0.0, 0, 0, 0};
    polynomial->count = output;
    return continue_operation(context);
}

static original_xyz_polynomial original_add_xyz(surfer_operation_context *context,
    const original_xyz_polynomial *left, const original_xyz_polynomial *right)
{
    if (left->count > SIZE_MAX - right->count) {
        context->status = SURFER_INVALID_INPUT; return original_empty_xyz();
    }
    original_xyz_polynomial result = original_allocate_xyz(context, left->count + right->count);
    if (result.terms == NULL) return result;
    size_t first = 0, second = 0, output = 0;
    while (first < left->count || second < right->count) {
        if (!continue_operation(context)) { original_free_xyz(result); return original_empty_xyz(); }
        const int order = first == left->count ? 1 : (second == right->count ? -1 :
            original_lex_compare(left->terms[first], right->terms[second]));
        if (order < 0) result.terms[output++] = left->terms[first++];
        else if (order > 0) result.terms[output++] = right->terms[second++];
        else {
            result.terms[output] = left->terms[first++];
            result.terms[output].coefficient += right->terms[second++].coefficient;
            if (!isfinite(result.terms[output].coefficient)) {
                context->status = SURFER_INVALID_INPUT; original_free_xyz(result); return original_empty_xyz();
            }
            ++output;
        }
    }
    result.count = output;
    return result;
}

static original_xyz_polynomial original_multiply_xyz(surfer_operation_context *context,
    const original_xyz_polynomial *left, const original_xyz_polynomial *right)
{
    if (left->count == 0 || right->count == 0) return original_constant_xyz(context, 0.0);
    if (left->count > SIZE_MAX / right->count) {
        context->status = SURFER_INVALID_INPUT; return original_empty_xyz();
    }
    original_xyz_polynomial result = original_allocate_xyz(context, left->count * right->count);
    if (result.terms == NULL) return result;
    size_t output = 0;
    for (size_t first = 0; first < left->count; ++first) {
        for (size_t second = 0; second < right->count; ++second) {
            if (!continue_operation(context)) { original_free_xyz(result); return original_empty_xyz(); }
            const surfer_term a = left->terms[first], b = right->terms[second];
            if (a.x_exponent > INT32_MAX - b.x_exponent ||
                a.y_exponent > INT32_MAX - b.y_exponent ||
                a.z_exponent > INT32_MAX - b.z_exponent) {
                context->status = SURFER_INVALID_INPUT; original_free_xyz(result); return original_empty_xyz();
            }
            const double coefficient = a.coefficient * b.coefficient;
            if (!isfinite(coefficient)) {
                context->status = SURFER_INVALID_INPUT; original_free_xyz(result); return original_empty_xyz();
            }
            result.terms[output++] = (surfer_term){coefficient,
                a.x_exponent + b.x_exponent, a.y_exponent + b.y_exponent, a.z_exponent + b.z_exponent};
        }
    }
    if (!original_collect_xyz(context, &result)) { original_free_xyz(result); return original_empty_xyz(); }
    return result;
}

static original_xyz_polynomial original_power_xyz(surfer_operation_context *context,
    const original_xyz_polynomial *base, int32_t exponent)
{
    if (exponent == 0) return original_constant_xyz(context, 1.0);
    if (exponent == 1) return original_copy_xyz(context, base);
    original_xyz_polynomial result = original_copy_xyz(context, base);
    original_xyz_polynomial power = original_copy_xyz(context, base);
    --exponent;
    while (exponent > 0 && continue_operation(context)) {
        if ((exponent & 1) != 0) {
            original_xyz_polynomial next = original_multiply_xyz(context, &result, &power);
            original_free_xyz(result); result = next;
            --exponent;
        }
        /* The Java implementation also performs this final square. */
        original_xyz_polynomial next_power = original_multiply_xyz(context, &power, &power);
        original_free_xyz(power); power = next_power;
        exponent /= 2;
    }
    original_free_xyz(power);
    if (context->status != SURFER_OK) { original_free_xyz(result); return original_empty_xyz(); }
    return result;
}

static bool original_multiply_assign(surfer_operation_context *context,
    original_xyz_polynomial *value, const original_xyz_polynomial *base, int32_t exponent)
{
    original_xyz_polynomial power = original_power_xyz(context, base, exponent);
    original_xyz_polynomial product = original_empty_xyz();
    if (context->status == SURFER_OK) product = original_multiply_xyz(context, value, &power);
    original_free_xyz(power); original_free_xyz(*value); *value = product;
    return context->status == SURFER_OK;
}

static bool original_add_assign(surfer_operation_context *context,
    original_xyz_polynomial *value, const original_xyz_polynomial *summand)
{
    original_xyz_polynomial sum = original_add_xyz(context, value, summand);
    original_free_xyz(*value); *value = sum;
    return context->status == SURFER_OK;
}

static original_xyz_polynomial original_substitute_xyz(surfer_operation_context *context,
    surfer_sparse_polynomial source, const original_xyz_polynomial coordinates[3])
{
    original_xyz_polynomial input = original_allocate_xyz(context, source.term_count);
    if (source.term_count == 0) return original_constant_xyz(context, 0.0);
    if (input.terms == NULL) return input;
    memcpy(input.terms, source.terms, source.term_count * sizeof(*input.terms));
    original_xyz_polynomial result = original_empty_xyz();
    original_xyz_polynomial across_x = original_constant_xyz(context, 0.0);
    original_xyz_polynomial across_y = original_constant_xyz(context, 0.0);
    original_xyz_polynomial across_z = original_empty_xyz();
    if (!original_collect_xyz(context, &input)) goto done;
    size_t index = input.count - 1;
    surfer_term previous = input.terms[index];
    across_z = original_constant_xyz(context, previous.coefficient);
    while (index > 0 && continue_operation(context)) {
        const surfer_term current = input.terms[--index];
        const bool same_x = previous.x_exponent == current.x_exponent;
        const bool same_y = previous.y_exponent == current.y_exponent;
        if (same_x && same_y) {
            if (!original_multiply_assign(context, &across_z, &coordinates[2],
                    previous.z_exponent - current.z_exponent)) goto done;
            original_xyz_polynomial constant = original_constant_xyz(context, current.coefficient);
            const bool okay = original_add_assign(context, &across_z, &constant);
            original_free_xyz(constant);
            if (!okay) goto done;
        } else {
            if (!original_multiply_assign(context, &across_z, &coordinates[2], previous.z_exponent) ||
                !original_add_assign(context, &across_y, &across_z)) goto done;
            if (same_x) {
                if (!original_multiply_assign(context, &across_y, &coordinates[1],
                    previous.y_exponent - current.y_exponent)) goto done;
            } else {
                if (!original_multiply_assign(context, &across_y, &coordinates[1], previous.y_exponent) ||
                    !original_add_assign(context, &across_x, &across_y) ||
                    !original_multiply_assign(context, &across_x, &coordinates[0],
                        previous.x_exponent - current.x_exponent)) goto done;
                original_free_xyz(across_y); across_y = original_constant_xyz(context, 0.0);
            }
            original_free_xyz(across_z); across_z = original_constant_xyz(context, current.coefficient);
        }
        previous = current;
    }
    if (!continue_operation(context) ||
        !original_multiply_assign(context, &across_z, &coordinates[2], previous.z_exponent) ||
        !original_add_assign(context, &across_y, &across_z) ||
        !original_multiply_assign(context, &across_y, &coordinates[1], previous.y_exponent) ||
        !original_add_assign(context, &across_x, &across_y) ||
        !original_multiply_assign(context, &across_x, &coordinates[0], previous.x_exponent)) goto done;
    result = across_x; across_x = original_empty_xyz();
  done:
    original_free_xyz(input); original_free_xyz(across_x);
    original_free_xyz(across_y); original_free_xyz(across_z);
    return result;
}

static original_xyz_polynomial original_coordinate_xyz(surfer_operation_context *context,
    double constant, double direction, double horizontal, double vertical)
{
    original_xyz_polynomial result = original_constant_xyz(context, constant);
    const double coefficients[3] = {vertical, horizontal, direction};
    for (size_t axis = 0; axis < 3 && continue_operation(context); ++axis) {
        original_xyz_polynomial term = original_constant_xyz(context, coefficients[axis]);
        if (term.count == 0) break;
        if (coefficients[axis] != 0.0) {
            if (axis == 0) term.terms[0].z_exponent = 1;
            else if (axis == 1) term.terms[0].y_exponent = 1;
            else term.terms[0].x_exponent = 1;
        } else term.terms[0].coefficient = 0.0;
        const bool okay = original_add_assign(context, &result, &term);
        original_free_xyz(term);
        if (!okay) break;
    }
    if (context->status != SURFER_OK) { original_free_xyz(result); return original_empty_xyz(); }
    return result;
}

static original_xy_polynomial original_evaluate_z(surfer_operation_context *context,
    const original_xyz_polynomial *polynomial, double where)
{
    int32_t degree = 0;
    size_t count = 1;
    for (size_t index = 0; index < polynomial->count; ++index) {
        if (!continue_operation(context)) return original_empty_xyz();
        if (polynomial->terms[index].z_exponent > degree) degree = polynomial->terms[index].z_exponent;
        if (index > 0 && (polynomial->terms[index].x_exponent != polynomial->terms[index - 1].x_exponent ||
            polynomial->terms[index].y_exponent != polynomial->terms[index - 1].y_exponent)) ++count;
    }
    if (polynomial->count == 0) return original_constant_xyz(context, 0.0);
    const uint64_t powers_count = (uint64_t)(uint32_t)degree * 2 + 1;
    if (powers_count > SIZE_MAX) { context->status = SURFER_INVALID_INPUT; return original_empty_xyz(); }
    double *powers = allocate_array(context, (size_t)powers_count, sizeof(*powers), false);
    original_xy_polynomial result = original_allocate_xyz(context, count);
    if (powers == NULL || result.terms == NULL) { free(powers); original_free_xyz(result); return original_empty_xyz(); }
    for (int64_t exponent = 0; exponent <= degree; ++exponent) {
        if (!continue_operation(context)) goto failure;
        powers[(size_t)((int64_t)degree + exponent)] = pow(where, (double)exponent);
    }
    const bool forwards = fabs(where) > 1.0;
    if (forwards) for (int64_t exponent = 1; exponent <= degree; ++exponent) {
        if (!continue_operation(context)) goto failure;
        powers[(size_t)((int64_t)degree - exponent)] = 1.0 / powers[(size_t)((int64_t)degree + exponent)];
    }
    size_t index = forwards ? 0 : polynomial->count - 1;
    size_t output = forwards ? 0 : count - 1;
    surfer_term previous = polynomial->terms[index];
    double coefficient = previous.coefficient;
    result.terms[output] = (surfer_term){0.0, previous.x_exponent, previous.y_exponent, 0};
    for (size_t step = 1; step < polynomial->count; ++step) {
        if (!continue_operation(context)) goto failure;
        if (forwards) ++index; else --index;
        const surfer_term current = polynomial->terms[index];
        if (previous.x_exponent == current.x_exponent && previous.y_exponent == current.y_exponent)
            coefficient = coefficient * powers[(size_t)((int64_t)degree + previous.z_exponent - current.z_exponent)] + current.coefficient;
        else {
            coefficient *= powers[(size_t)((int64_t)degree + previous.z_exponent)];
            if (!isfinite(coefficient)) { context->status = SURFER_INVALID_INPUT; goto failure; }
            result.terms[output].coefficient = coefficient;
            if (forwards) ++output; else --output;
            coefficient = current.coefficient;
            result.terms[output] = (surfer_term){0.0, current.x_exponent, current.y_exponent, 0};
        }
        previous = current;
    }
    coefficient *= powers[(size_t)((int64_t)degree + previous.z_exponent)];
    if (!isfinite(coefficient)) { context->status = SURFER_INVALID_INPUT; goto failure; }
    result.terms[output].coefficient = coefficient;
    free(powers);
    return result;
  failure:
    free(powers); original_free_xyz(result); return original_empty_xyz();
}

static univariate_polynomial original_evaluate_y(surfer_operation_context *context,
    const original_xy_polynomial *polynomial, double where)
{
    if (polynomial->count == 0) {
        const double zero = 0.0;
        return copy_univariate_polynomial(context, &zero, 1);
    }
    int32_t degree = 0;
    for (size_t index = 0; index < polynomial->count; ++index) {
        if (!continue_operation(context)) return empty_univariate_polynomial();
        if (polynomial->terms[index].y_exponent > degree) degree = polynomial->terms[index].y_exponent;
    }
    const uint64_t powers_count = (uint64_t)(uint32_t)degree * 2 + 1;
    if (powers_count > SIZE_MAX) { context->status = SURFER_INVALID_INPUT; return empty_univariate_polynomial(); }
    double *powers = allocate_array(context, (size_t)powers_count, sizeof(*powers), false);
    univariate_polynomial result = allocate_univariate_polynomial(context,
        (size_t)polynomial->terms[polynomial->count - 1].x_exponent + 1);
    if (powers == NULL || result.coefficients == NULL) { free(powers); free_univariate_polynomial(result); return empty_univariate_polynomial(); }
    for (int64_t exponent = 0; exponent <= degree; ++exponent) {
        if (!continue_operation(context)) goto failure;
        powers[(size_t)((int64_t)degree + exponent)] = pow(where, (double)exponent);
    }
    const bool forwards = fabs(where) > 1.0;
    if (forwards) for (int64_t exponent = 1; exponent <= degree; ++exponent) {
        if (!continue_operation(context)) goto failure;
        powers[(size_t)((int64_t)degree - exponent)] = 1.0 / powers[(size_t)((int64_t)degree + exponent)];
    }
    size_t index = forwards ? 0 : polynomial->count - 1;
    surfer_term previous = polynomial->terms[index];
    double coefficient = previous.coefficient;
    for (size_t step = 1; step < polynomial->count; ++step) {
        if (!continue_operation(context)) goto failure;
        if (forwards) ++index; else --index;
        const surfer_term current = polynomial->terms[index];
        if (previous.x_exponent == current.x_exponent)
            coefficient = coefficient * powers[(size_t)((int64_t)degree + previous.y_exponent - current.y_exponent)] + current.coefficient;
        else {
            coefficient *= powers[(size_t)((int64_t)degree + previous.y_exponent)];
            if (!isfinite(coefficient)) { context->status = SURFER_INVALID_INPUT; goto failure; }
            result.coefficients[(size_t)previous.x_exponent] = coefficient;
            coefficient = current.coefficient;
        }
        previous = current;
    }
    coefficient *= powers[(size_t)((int64_t)degree + previous.y_exponent)];
    if (!isfinite(coefficient)) { context->status = SURFER_INVALID_INPUT; goto failure; }
    result.coefficients[(size_t)previous.x_exponent] = coefficient;
    free(powers);
    return result;
  failure:
    free(powers); free_univariate_polynomial(result); return empty_univariate_polynomial();
}

static void original_destroy_pipeline(original_render_pipeline *pipeline)
{
    for (size_t component = 0; component < 4; ++component) {
        original_free_xyz(pipeline->transformed[component]);
        for (size_t row = 0; row < 2; ++row) original_free_xyz(pipeline->rows[row][component]);
    }
    memset(pipeline, 0, sizeof(*pipeline));
}

static bool original_initialize_pipeline(surfer_operation_context *context,
    const surfer_prepared_surface *surface, orthographic_view view,
    original_render_pipeline *pipeline)
{
    memset(pipeline, 0, sizeof(*pipeline));
    original_xyz_polynomial coordinates[3];
    coordinates[0] = original_coordinate_xyz(context, 0.0, view.surface_direction.x, view.surface_u.x, view.surface_v.x);
    coordinates[1] = original_coordinate_xyz(context, 0.0, view.surface_direction.y, view.surface_u.y, view.surface_v.y);
    coordinates[2] = original_coordinate_xyz(context, 0.0, view.surface_direction.z, view.surface_u.z, view.surface_v.z);
    const surfer_sparse_polynomial inputs[4] = {surface->surface, surface->gradient_x, surface->gradient_y, surface->gradient_z};
    for (size_t component = 0; component < 4 && continue_operation(context); ++component)
        pipeline->transformed[component] = original_substitute_xyz(context, inputs[component], coordinates);
    for (size_t axis = 0; axis < 3; ++axis) original_free_xyz(coordinates[axis]);
    if (context->status != SURFER_OK) { original_destroy_pipeline(pipeline); return false; }
    return true;
}

static const original_xy_polynomial *original_row_for_sample(
    surfer_operation_context *context, original_render_pipeline *pipeline, double vertical)
{
    for (unsigned row = 0; row < 2; ++row) {
        if (pipeline->row_present[row] && memcmp(&pipeline->row_values[row], &vertical, sizeof(vertical)) == 0) {
            pipeline->recent_row = row;
            return pipeline->rows[row];
        }
    }
    const unsigned row = 1U - pipeline->recent_row;
    for (size_t component = 0; component < 4; ++component) {
        original_free_xyz(pipeline->rows[row][component]);
        pipeline->rows[row][component] = original_empty_xyz();
    }
    pipeline->row_present[row] = false;
    for (size_t component = 0; component < 4 && continue_operation(context); ++component)
        pipeline->rows[row][component] = original_evaluate_z(context, &pipeline->transformed[component], vertical);
    if (context->status != SURFER_OK) return NULL;
    pipeline->row_values[row] = vertical;
    pipeline->row_present[row] = true;
    pipeline->recent_row = row;
    return pipeline->rows[row];
}
