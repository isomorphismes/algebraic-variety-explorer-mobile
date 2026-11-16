module CoefficientArithmetic

%default total

-- Explicit primitive-operator compatibility with pinned frontend740bbf2b1.
-- The application-facing evaluator is CoefficientValue.idric. Named operations
-- keep unsupported modern infix declarations out of its mathematical recipe.

export
subtract_coefficients : Double -> Double -> Double
subtract_coefficients left right = left - right

export
multiply_coefficients : Double -> Double -> Double
multiply_coefficients left right = left * right

export
divide_coefficients : Double -> Double -> Double
divide_coefficients left right = left / right
