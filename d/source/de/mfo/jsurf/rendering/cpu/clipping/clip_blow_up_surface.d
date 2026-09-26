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

module de.mfo.jsurf.rendering.cpu.clipping.clip_blow_up_surface;
import std.algorithm.comparison : max;
import std.math : abs,sqrt;
import javax.vecmath : Point3d;
import de.mfo.jsurf.rendering.cpu.clipping.clip_to_torus : ClipToTorus;

class ClipBlowUpSurface : ClipToTorus {
    this(){super();}this(double R,double r){super(R,r);}
    override bool clipPoint(Point3d p){
        const u=p.x;const tmp=sqrt(p.y*p.y+p.z*p.z);const v=R+tmp;double inside,outside;
        if(u*u+v*v<R*R){inside=v;outside=R-tmp;}else{inside=R-tmp;outside=v;}
        if(u*u+inside*inside>r*r)return false;
        enum eps=0.0001;
        const f=blowup_f(u,outside),g=blowup_g(u,outside);
        const pInside=max(abs(p.z*(g*g+f*f)-2.0*(R-outside)*f*g),abs(p.y*(g*g+f*f)+(R-outside)*(g*g-f*f)))>=eps*(g*g+f*f);
        return pInside;
    }
    double blowup_f(double u,double v){return u*u-0.25;}
    double blowup_g(double u,double v){return v*v-0.25;}
    override bool pointClippingNecessary(){return true;}
}
