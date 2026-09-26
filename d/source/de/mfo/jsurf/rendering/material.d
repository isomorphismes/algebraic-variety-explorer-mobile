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

module de.mfo.jsurf.rendering.material;
import std.conv : to;
import javax.vecmath : Color3f;
import java.util.properties : Properties;
import de.mfo.jsurf.util.basic_io : ioToString=toString,fromColor3fString;

class Material {
    private Color3f color;
    private float ambientIntensity,diffuseIntensity,specularIntensity,shininess;
    this(){color=new Color3f(0.5f,0.5f,0.5f);ambientIntensity=0.1f;diffuseIntensity=0.23232f;specularIntensity=0.9f;shininess=1.0f;}
    Color3f getColor(){return color;} void setColor(Color3f c){if(c is null)throw new Exception("null color");color=c;}
    float getAmbientIntensity(){return ambientIntensity;} void setAmbientIntensity(float v){ambientIntensity=v;}
    float getDiffuseIntensity(){return diffuseIntensity;} void setDiffuseIntensity(float v){diffuseIntensity=v;}
    float getSpecularIntensity(){return specularIntensity;} void setSpecularIntensity(float v){specularIntensity=v;}
    float getShininess(){return shininess;} void setShininess(float v){shininess=v;}
    private static float lerpScalar(float a,float b,float t){return a*(1.0f-t)+t*b;}
    static Material lerp(Material a,Material b,float t){auto m=new Material();m.color.interpolate(a.color,b.color,t);m.ambientIntensity=lerpScalar(a.ambientIntensity,b.ambientIntensity,t);m.diffuseIntensity=lerpScalar(a.diffuseIntensity,b.diffuseIntensity,t);m.specularIntensity=lerpScalar(a.specularIntensity,b.specularIntensity,t);m.shininess=lerpScalar(a.shininess,b.shininess,t);return m;}
    Properties saveProperties(Properties p,string prefix,string suffix){
        p.setProperty(prefix~"color"~suffix,ioToString(color));
        p.setProperty(prefix~"ambient_intensity"~suffix,ambientIntensity.to!string);
        p.setProperty(prefix~"diffuse_intensity"~suffix,diffuseIntensity.to!string);
        p.setProperty(prefix~"specular_intensity"~suffix,specularIntensity.to!string);
        p.setProperty(prefix~"shininess"~suffix,shininess.to!string);return p;
    }
    void loadProperties(Properties p,string prefix,string suffix){
        string k=prefix~"color"~suffix;if(p.containsKey(k))color=fromColor3fString(p.getProperty(k));
        k=prefix~"ambient_intensity"~suffix;if(p.containsKey(k))ambientIntensity=p.getProperty(k).to!float;
        k=prefix~"diffuse_intensity"~suffix;if(p.containsKey(k))diffuseIntensity=p.getProperty(k).to!float;
        k=prefix~"specular_intensity"~suffix;if(p.containsKey(k))specularIntensity=p.getProperty(k).to!float;
        k=prefix~"shininess"~suffix;if(p.containsKey(k))shininess=p.getProperty(k).to!float;
    }
}
