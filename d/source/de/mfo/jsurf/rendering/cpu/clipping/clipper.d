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

module de.mfo.jsurf.rendering.cpu.clipping.clipper;
import std.algorithm.comparison : min,max;
import javax.vecmath : Vector2d,Point3d;
import de.mfo.jsurf.rendering.cpu.ray : Ray;

abstract class Clipper {
    abstract Vector2d[] clipRay(Ray r);
    abstract bool clipPoint(Point3d p);
    abstract bool pointClippingNecessary();
    Vector2d[] clipRay(Ray r,Vector2d interval){
        Vector2d[] result;foreach(i;clipRay(r)){auto t=intersect(i,interval);if(t !is null)result~=t;}return result;
    }
    bool clipPoint(Point3d p,bool clippedAgainstRay){return clippedAgainstRay&&!pointClippingNecessary()?true:clipPoint(p);}
    Point3d[] clipPoints(Point3d[] values){Point3d[] r;foreach(p;values)if(clipPoint(p))r~=p;return r;}
    Point3d[] clipPoints(Point3d[] values,bool clippedAgainstRay){return clippedAgainstRay&&!pointClippingNecessary()?values:clipPoints(values);}
    static Vector2d intersect(Vector2d i1,Vector2d i2){i1.x=max(i1.x,i2.x);i1.y=min(i1.y,i2.y);return i1.y<i1.x?null:i1;}
}
