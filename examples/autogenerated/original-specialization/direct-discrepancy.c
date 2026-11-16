/* Reduced observation of the retained pre-specialization implementation. */
#include "../../../native/surfer_raytracer.c"
#include <inttypes.h>
#include <stdio.h>

int main(void)
{
    const surfer_term terms[] = {
        {-0.64, 0, 0, 0}, {1.0, 0, 0, 2}, {1.0, 0, 2, 0}, {1.0, 2, 0, 0}
    };
    const surfer_vec3 horizontal = {0.8, 0.0, -0.6};
    const surfer_vec3 vertical = {0.48, 0.8, 0.64};
    const surfer_ray ray = {add_vectors(scale_vector(horizontal, -1.0),
        scale_vector(vertical, -1.0)), {-0.36, 0.6, -0.48}};
    surfer_operation_context context = new_operation_context();
    univariate_polynomial actual = empty_univariate_polynomial();
    if (!expand_sparse_polynomial_directly_along_ray(&context,
        (surfer_sparse_polynomial){terms, 4}, ray, &actual)) return 1;
    for (size_t index = 0; index < actual.length; ++index) {
        uint64_t bits;
        memcpy(&bits, &actual.coefficients[index], sizeof(bits));
        printf("direct\tsphere-rotated\t%zu\t%016" PRIx64 "\n", index, bits);
    }
    free_univariate_polynomial(actual);
    return 0;
}
