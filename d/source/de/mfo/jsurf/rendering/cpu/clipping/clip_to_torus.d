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

module de.mfo.jsurf.rendering.cpu.clipping.clip_to_torus;
import javax.vecmath : Vector2d,Point3d;
import de.mfo.jsurf.rendering.cpu.ray : Ray;
import de.mfo.jsurf.rendering.cpu.clipping.clipper : Clipper;
import de.mfo.jsurf.algebra.univariate_polynomial : UnivariatePolynomial;
import de.mfo.jsurf.algebra.closed_form_root_finder : ClosedFormRootFinder;

class ClipToTorus : Clipper {
    double R,r,Rsqr,rsqr;ClosedFormRootFinder cfrf;
    this(){this(1,1);} this(double R,double r){this.R=R;this.r=r;Rsqr=R*R;rsqr=r*r;cfrf=new ClosedFormRootFinder();}
    double get_R(){return R;}double get_r(){return r;}
    override Vector2d[] clipRay(Ray ray){
        auto x=new UnivariatePolynomial(ray.o.x,ray.d.x);auto y=new UnivariatePolynomial(ray.o.y,ray.d.y);auto z=new UnivariatePolynomial(ray.o.z,ray.d.z);
        auto xs=x.mult(x),ys=y.mult(y),zs=z.mult(z);auto p=xs.add(ys).add(zs).add(Rsqr-rsqr);p=p.mult(p).sub(ys.add(zs).mult(4*Rsqr));
        auto roots=cfrf.findAllRoots(p);Vector2d[] result;for(size_t i=0;i<roots.length;i+=2)result~=new Vector2d(roots[i],roots[i+1]);return result;
    }
    override bool clipPoint(Point3d p){const t=p.x*p.x+p.y*p.y+p.z*p.z+R*R-r*r;return t*t<=4*R*R*(p.y*p.y+p.z*p.z);}
    override bool pointClippingNecessary(){return false;}
}
