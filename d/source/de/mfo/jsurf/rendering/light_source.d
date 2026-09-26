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

module de.mfo.jsurf.rendering.light_source;
import std.conv : to;
import javax.vecmath : Point3d,Color3f;
import java.util.properties : Properties;
import de.mfo.jsurf.util.basic_io : ioToString=toString,fromPoint3dString,fromColor3fString;

class LightSource {
    enum Status { ON, OFF }
    private Status status; private Point3d position; private Color3f color; private float intensity;
    this(){status=Status.ON;position=new Point3d(0,0,0);color=new Color3f(1,1,1);intensity=1;}
    void setStatus(Status s){status=s;} Status getStatus(){return status;}
    void setPosition(Point3d p){if(p is null)throw new Exception("null position");position=p;} Point3d getPosition(){return position;}
    void setColor(Color3f c){if(c is null)throw new Exception("null color");color=c;} Color3f getColor(){return color;}
    void setIntensity(float v){intensity=v;} float getIntensity(){return intensity;}
    Properties saveProperties(Properties p,string prefix,string suffix){
        p.setProperty(prefix~"status"~suffix,status.to!string);p.setProperty(prefix~"position"~suffix,ioToString(position));
        p.setProperty(prefix~"color"~suffix,ioToString(color));p.setProperty(prefix~"intensity"~suffix,intensity.to!string);return p;
    }
    void loadProperties(Properties p,string prefix,string suffix){
        string k=prefix~"status"~suffix;if(p.containsKey(k))status=p.getProperty(k)=="OFF"?Status.OFF:Status.ON;
        k=prefix~"position"~suffix;if(p.containsKey(k))position=fromPoint3dString(p.getProperty(k));
        k=prefix~"color"~suffix;if(p.containsKey(k))color=fromColor3fString(p.getProperty(k));
        k=prefix~"intensity"~suffix;if(p.containsKey(k))intensity=p.getProperty(k).to!float;
    }
}
