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

module de.mfo.jsurf.rendering.cpu.clipping.clip_to_sphere;
import std.math : sqrt;
import javax.vecmath : Vector2d,Vector3d,Point3d;
import de.mfo.jsurf.rendering.cpu.ray : Ray;
import de.mfo.jsurf.rendering.cpu.clipping.clipper : Clipper;

class ClipToSphere : Clipper {
    double radius;
    this(){this(1.0);} this(double radius){this.radius=radius;}
    override Vector2d[] clipRay(Ray r){
        auto o=new Vector3d(r.o);auto d=new Vector3d(r.d);const length=d.length();d.scale(1.0/length);
        const B=-o.dot(d);const C=o.dot(o)-radius*radius;const D=B*B-C;
        if(D<0)return[];const root=sqrt(D);auto v=new Vector2d(B-root,B+root);v.scale(1.0/length);return[v];
    }
    override bool clipPoint(Point3d p){return p.x*p.x+p.y*p.y+p.z*p.z<=radius*radius;}
    override bool pointClippingNecessary(){return false;}
}
