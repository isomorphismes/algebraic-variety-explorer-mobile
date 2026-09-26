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

module de.mfo.jsurf.rendering.algebraic_surface_renderer;

import javax.vecmath : Matrix4d,Color3f;
import de.mfo.jsurf.algebra.polynomial_operation : PolynomialOperation;
import de.mfo.jsurf.algebra.polynomial_variable : PolynomialVariable;
import de.mfo.jsurf.algebra.simplificator : Simplificator;
import de.mfo.jsurf.algebra.degree_calculator : DegreeCalculator;
import de.mfo.jsurf.algebra.to_string_visitor : ToStringVisitor;
import de.mfo.jsurf.algebra.differentiator : Differentiator;
import de.mfo.jsurf.algebra.double_variable_extractor : DoubleVariableExtractor,StringSet;
import de.mfo.jsurf.algebra.visitor : accept;
import de.mfo.jsurf.parser.algebraic_expression_parser : AlgebraicExpressionParser;
import de.mfo.jsurf.rendering.camera : Camera;
import de.mfo.jsurf.rendering.material : Material;
import de.mfo.jsurf.rendering.light_source : LightSource;

abstract class AlgebraicSurfaceRenderer {
    enum MAX_LIGHTS=8;

    private string surfaceExpressionFamilyString;
    private PolynomialOperation surfaceExpressionFamily;
    private int surfaceTotalDegree;
    private PolynomialOperation surfaceExpression,gradientXExpression,gradientYExpression,gradientZExpression;
    private Simplificator parameterSubstitutor;
    private Camera camera;
    private Material frontMaterial,backMaterial;
    private LightSource[] lightSources;
    private Matrix4d transform,surfaceTransform;
    private Color3f backgroundColor;

    this(){
        parameterSubstitutor=new Simplificator();
        camera=new Camera();frontMaterial=new Material();backMaterial=new Material();
        lightSources=new LightSource[MAX_LIGHTS];lightSources[0]=new LightSource();
        foreach(i;1..lightSources.length){lightSources[i]=new LightSource();lightSources[i].setStatus(LightSource.Status.OFF);}
        transform=new Matrix4d();transform.setIdentity();surfaceTransform=new Matrix4d();surfaceTransform.setIdentity();
        backgroundColor=new Color3f(1,1,1);
        setSurfaceFamily(new PolynomialVariable(PolynomialVariable.Var.z));
    }

    abstract void draw(int[] colorBuffer,int width,int height);

    private void setSurfaceFamilyInternal(PolynomialOperation expression,string expressionString){
        surfaceExpressionFamily=expression;surfaceExpressionFamilyString=expressionString;clearExpressionCache();
        parameterSubstitutor=new Simplificator();surfaceTotalDegree=accept(surfaceExpressionFamily,new DegreeCalculator());
    }

    void setSurfaceExpression(PolynomialOperation expression){setSurfaceFamily(expression);}
    void setSurfaceFamily(PolynomialOperation expression){setSurfaceFamilyInternal(expression,accept(expression,new ToStringVisitor()));}
    void setSurfaceFamily(string expression){setSurfaceFamilyInternal(AlgebraicExpressionParser.parse(expression),expression);}

    private void clearExpressionCache(){surfaceExpression=null;gradientXExpression=null;gradientYExpression=null;gradientZExpression=null;}

    PolynomialOperation getSurfaceFamily(){return surfaceExpressionFamily;}
    string getSurfaceFamilyString(){return surfaceExpressionFamilyString;}
    PolynomialOperation getSurfaceExpression(){if(surfaceExpression is null)surfaceExpression=accept(surfaceExpressionFamily,parameterSubstitutor);return surfaceExpression;}
    PolynomialOperation getGradientXExpression(){if(gradientXExpression is null)gradientXExpression=accept(getSurfaceExpression(),new Differentiator(PolynomialVariable.Var.x));return gradientXExpression;}
    PolynomialOperation getGradientYExpression(){if(gradientYExpression is null)gradientYExpression=accept(getSurfaceExpression(),new Differentiator(PolynomialVariable.Var.y));return gradientYExpression;}
    PolynomialOperation getGradientZExpression(){if(gradientZExpression is null)gradientZExpression=accept(getSurfaceExpression(),new Differentiator(PolynomialVariable.Var.z));return gradientZExpression;}
    int getSurfaceTotalDegree(){return surfaceTotalDegree;}

    void setParameterValue(string name,double value){parameterSubstitutor.setParameterValue(name,value);clearExpressionCache();}
    void unsetParameter(string name){parameterSubstitutor.unsetParameterValue(name);clearExpressionCache();}
    double getParameterValue(string name){return parameterSubstitutor.getParameterValue(name);}
    double[string] getAssignedParameters(){return parameterSubstitutor.getKnownParameters();}
    StringSet getAllParameterNames(){return accept(surfaceExpressionFamily,new DoubleVariableExtractor());}

    void setCamera(Camera c){if(c is null)throw new Exception("null camera");camera=c;} Camera getCamera(){return camera;}
    void setTransform(Matrix4d m){if(m is null)throw new Exception("null transform");transform=new Matrix4d(m);} Matrix4d getTransform(){return new Matrix4d(transform);}
    void setSurfaceTransform(Matrix4d m){if(m is null)throw new Exception("null surface transform");surfaceTransform=new Matrix4d(m);} Matrix4d getSurfaceTransform(){return new Matrix4d(surfaceTransform);}

    void setLightSource(int which,LightSource s){if(0<=which&&which<MAX_LIGHTS)lightSources[which]=s;}
    LightSource getLightSource(int which){return 0<=which&&which<MAX_LIGHTS?lightSources[which]:null;}
    void setFrontMaterial(Material m){if(m is null)throw new Exception("null material");frontMaterial=m;} Material getFrontMaterial(){return frontMaterial;}
    void setBackMaterial(Material m){if(m is null)throw new Exception("null material");backMaterial=m;} Material getBackMaterial(){return backMaterial;}
    void setBackgroundColor(Color3f c){if(c is null)throw new Exception("null color");backgroundColor=c;} Color3f getBackgroundColor(){return backgroundColor;}
}
