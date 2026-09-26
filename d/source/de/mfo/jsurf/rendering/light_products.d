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

module de.mfo.jsurf.rendering.light_products;
import javax.vecmath : Color3f;
import de.mfo.jsurf.rendering.light_source : LightSource;
import de.mfo.jsurf.rendering.material : Material;

class LightProducts {
    private LightSource lightSource;private Material material;private Color3f diffuseProduct,specularProduct;
    this(LightSource light,Material material){
        lightSource=light;this.material=material;diffuseProduct=new Color3f(material.getColor());
        diffuseProduct.x*=light.getColor().x;diffuseProduct.y*=light.getColor().y;diffuseProduct.z*=light.getColor().z;
        diffuseProduct.scale(material.getDiffuseIntensity()*light.getIntensity());
        specularProduct=new Color3f(light.getColor());specularProduct.scale(material.getSpecularIntensity()*light.getIntensity());
    }
    LightSource getLightSource(){return lightSource;} Material getMaterial(){return material;}
    Color3f getDiffuseProduct(){return diffuseProduct;} Color3f getSpecularProduct(){return specularProduct;}
}
