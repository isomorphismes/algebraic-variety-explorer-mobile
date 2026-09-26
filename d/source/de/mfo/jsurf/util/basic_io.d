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

module de.mfo.jsurf.util.basic_io;
import std.conv : to;
import std.string : split;
import javax.vecmath : Point3d,Vector3d,Color3f,Matrix4d;

string tupleString(double x,double y,double z){return x.to!string~" "~y.to!string~" "~z.to!string;}
string toString(Point3d t){return tupleString(t.x,t.y,t.z);}
string toString(Vector3d t){return tupleString(t.x,t.y,t.z);}
string toString(Color3f t){return t.x.to!string~" "~t.y.to!string~" "~t.z.to!string;}

Color3f fromColor3fString(string s){auto a=s.split();return new Color3f(a[0].to!float,a[1].to!float,a[2].to!float);}
Point3d fromPoint3dString(string s){auto a=s.split();return new Point3d(a[0].to!double,a[1].to!double,a[2].to!double);}
Vector3d fromVector3dString(string s){return new Vector3d(fromPoint3dString(s));}

string toString(Matrix4d m){
    return m.m00.to!string~" "~m.m01.to!string~" "~m.m02.to!string~" "~m.m03.to!string~"  "~
           m.m10.to!string~" "~m.m11.to!string~" "~m.m12.to!string~" "~m.m13.to!string~"  "~
           m.m20.to!string~" "~m.m21.to!string~" "~m.m22.to!string~" "~m.m23.to!string~"  "~
           m.m30.to!string~" "~m.m31.to!string~" "~m.m32.to!string~" "~m.m33.to!string;
}
Matrix4d fromMatrix4dString(string s){
    auto a=s.split();auto m=new Matrix4d();
    foreach(i;0..16)m.setElement(cast(int)(i/4),cast(int)(i%4),a[i].to!double);
    return m;
}
