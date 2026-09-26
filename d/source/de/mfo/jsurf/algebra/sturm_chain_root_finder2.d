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

module de.mfo.jsurf.algebra.sturm_chain_root_finder2;

import de.mfo.jsurf.algebra.real_root_finder : RealRootFinder;
import de.mfo.jsurf.algebra.univariate_polynomial : UnivariatePolynomial;

class SturmChainRootFinder2 : RealRootFinder {
    // The Java source contains only these stubs plus a large commented
    // shader-language sketch. Preserve the implemented Java behavior.

    override double[] findAllRoots(UnivariatePolynomial p) {
        return null;
    }

    override double[] findAllRootsIn(
        UnivariatePolynomial p,
        double lowerBound,
        double upperBound)
    {
        return null;
    }

    override double findFirstRootIn(
        UnivariatePolynomial p,
        double lowerBound,
        double upperBound)
    {
        return double.nan;
    }
}
