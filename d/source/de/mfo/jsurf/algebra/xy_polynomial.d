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

module de.mfo.jsurf.algebra.xy_polynomial;

import std.algorithm.comparison : max;
import std.conv : to;
import std.math : abs, mathPow = pow;
import de.mfo.jsurf.algebra.univariate_polynomial : UnivariatePolynomial;

class XYPolynomial {
    static XYPolynomial X;
    static XYPolynomial Y;

    static this() {
        X = new XYPolynomial(1.0, cast(byte)1, cast(byte)0);
        Y = new XYPolynomial(1.0, cast(byte)0, cast(byte)1);
    }

    private double[] coeffs;
    private byte[] xExps;
    private byte[] yExps;

    private byte xDegree;
    private byte yDegree;
    private byte degree;

    this() { this(0.0); }

    this(double value) {
        coeffs=[value]; xExps=[cast(byte)0]; yExps=[cast(byte)0];
        calculateDegree();
    }

    this(double value, byte xExp, byte yExp) {
        coeffs=[value]; xExps=[xExp]; yExps=[yExp];
        calculateDegree();
    }

    package this(double[] coeffs, byte[] xExps, byte[] yExps, int from, int length) {
        createArrays(length);
        this.coeffs[] = coeffs[from .. from+length];
        this.xExps[] = xExps[from .. from+length];
        this.yExps[] = yExps[from .. from+length];
        calculateDegree();
    }

    package this(double[] coeffs, byte[] xExps, byte[] yExps, bool copy) {
        if(copy){
            this.coeffs=coeffs.dup; this.xExps=xExps.dup; this.yExps=yExps.dup;
        } else {
            this.coeffs=coeffs; this.xExps=xExps; this.yExps=yExps;
        }
        calculateDegree();
    }

    package this(double[] coeffs, byte[] xExps, byte[] yExps) {
        this(coeffs,xExps,yExps,true);
    }

    package this(int length) { createArrays(length); }

    private void createArrays(int length) {
        coeffs=new double[length]; xExps=new byte[length]; yExps=new byte[length];
    }

    private void calculateDegree() {
        xDegree=xExps[$-1];
        yDegree=0;
        int yDegreePos=cast(int)coeffs.length-1;
        degree=0;
        for(int i=cast(int)coeffs.length-1;i>=0;--i){
            if(yExps[i]>yDegree){yDegree=yExps[i];yDegreePos=i;}
        }
        degree=cast(byte)max(
            cast(int)xExps[yDegreePos]+cast(int)yDegree,
            cast(int)xDegree+cast(int)yExps[$-1]);
    }

    static int lexCompare(XYPolynomial p1,XYPolynomial p2,int pos1,int pos2){
        int result=p1.xExps[pos1]<p2.xExps[pos2]?-4:(p1.xExps[pos1]>p2.xExps[pos2]?4:0);
        if(result==0)
            result += p1.yExps[pos1]<p2.yExps[pos2]?-2:(p1.yExps[pos1]>p2.yExps[pos2]?2:0);
        return result;
    }

    XYPolynomial neg(){
        auto negCoeffs=new double[coeffs.length];
        foreach(i;0..coeffs.length)negCoeffs[i]=-coeffs[i];
        return new XYPolynomial(negCoeffs,xExps,yExps,false);
    }

    XYPolynomial sub(XYPolynomial p){return add(p.neg());}

    XYPolynomial add(XYPolynomial p){
        auto resultCoeffs=new double[coeffs.length+p.coeffs.length];
        auto resultX=new byte[resultCoeffs.length];
        auto resultY=new byte[resultCoeffs.length];
        int ri=0,i1=0,i2=0;
        while(i1<coeffs.length && i2<p.coeffs.length){
            const cmp=lexCompare(this,p,i1,i2);
            if(cmp<0){
                resultCoeffs[ri]=coeffs[i1];resultX[ri]=xExps[i1];resultY[ri]=yExps[i1];++ri;++i1;
            } else if(cmp>0){
                resultCoeffs[ri]=p.coeffs[i2];resultX[ri]=p.xExps[i2];resultY[ri]=p.yExps[i2];++ri;++i2;
            } else {
                resultCoeffs[ri]=coeffs[i1]+p.coeffs[i2];resultX[ri]=xExps[i1];resultY[ri]=yExps[i1];++ri;++i1;++i2;
            }
        }
        while(i1<coeffs.length){resultCoeffs[ri]=coeffs[i1];resultX[ri]=xExps[i1];resultY[ri]=yExps[i1];++ri;++i1;}
        while(i2<p.coeffs.length){resultCoeffs[ri]=p.coeffs[i2];resultX[ri]=p.xExps[i2];resultY[ri]=p.yExps[i2];++ri;++i2;}

        // Preserve the original Java source literally: its full-length branch
        // passes this.xExps/this.yExps rather than resultX/resultY.
        if(ri==resultCoeffs.length)
            return new XYPolynomial(resultCoeffs,xExps,yExps,false);
        return new XYPolynomial(resultCoeffs,resultX,resultY,0,ri);
    }

    XYPolynomial mult(XYPolynomial p){
        auto result=new XYPolynomial();
        for(int j=0;j<coeffs.length;++j){
            auto partial=new XYPolynomial(cast(int)p.coeffs.length);
            for(int i=0;i<p.coeffs.length;++i){
                partial.coeffs[i]=coeffs[j]*p.coeffs[i];
                partial.xExps[i]=cast(byte)(xExps[j]+p.xExps[i]);
                partial.yExps[i]=cast(byte)(yExps[j]+p.yExps[i]);
            }
            partial.calculateDegree();
            result=result.add(partial);
        }
        return result;
    }

    XYPolynomial mult(double d){
        auto c=new double[coeffs.length];
        foreach(i;0..coeffs.length)c[i]=d*coeffs[i];
        return new XYPolynomial(c,xExps,yExps,false);
    }

    XYPolynomial pow(int exp){
        if(exp==0)return new XYPolynomial(1.0);
        auto result=this;
        auto x=this;
        --exp;
        while(exp>0){
            if((exp&1)==1){result=result.mult(x);--exp;}
            x=x.mult(x);exp/=2;
        }
        return result;
    }

    double evaluateXY(double x,double y){
        double result=0;
        foreach(i;0..coeffs.length)
            result += coeffs[i]*mathPow(x,cast(double)xExps[i])*mathPow(y,cast(double)yExps[i]);
        return result;
    }

    UnivariatePolynomial evaluateY(double y){
        if(coeffs.length==0)return new UnivariatePolynomial(0.0);
        auto yPowers=new double[cast(int)yDegree*2+1];
        for(int i=0;i<=yDegree;++i)yPowers[yDegree+i]=mathPow(y,cast(double)i);

        int termIndex,incr,lastIndex;
        if(abs(y)>1.0){
            termIndex=0;incr=1;lastIndex=cast(int)coeffs.length-1;
            for(int i=1;i<=yDegree;++i)yPowers[yDegree-i]=1.0/yPowers[yDegree+i];
        } else {
            termIndex=cast(int)coeffs.length-1;incr=-1;lastIndex=0;
        }
        int lastX=xExps[termIndex];
        int lastY=yExps[termIndex];
        auto a=new double[cast(int)xExps[$-1]+1];
        double current=coeffs[termIndex];

        while(incr*termIndex<incr*lastIndex){
            termIndex+=incr;
            const xe=xExps[termIndex];
            const ye=yExps[termIndex];
            if(lastX==xe)
                current=current*yPowers[yDegree+(lastY-ye)]+coeffs[termIndex];
            else {
                current=current*yPowers[yDegree+lastY];
                a[lastX]=current;
                current=coeffs[termIndex];
            }
            lastX=xe;lastY=ye;
        }
        current=current*yPowers[yDegree+lastY];
        a[lastX]=current;
        return new UnivariatePolynomial(a,false);
    }

    XYPolynomial eliminateZeroTerms(){
        auto tmp=new XYPolynomial(cast(int)coeffs.length);
        int j=0;
        foreach(i;0..coeffs.length)if(coeffs[i]!=0.0){
            tmp.coeffs[j]=coeffs[i];tmp.xExps[j]=xExps[i];tmp.yExps[j]=yExps[i];++j;
        }
        if(j==0)++j;
        return new XYPolynomial(tmp.coeffs,tmp.xExps,tmp.yExps,0,j);
    }

    override string toString(){
        string result;
        foreach(i;0..coeffs.length)result~=termToString(cast(int)i);
        return result;
    }

    private string termToStringShort(int i){
        string result;
        if(coeffs[i]!=1.0){
            if(coeffs[i]==-1.0 && !(xExps[i]==0 && yExps[i]==0))result~="-";
            else result~=coeffs[i].to!string;
        }
        if(xExps[i]>=1)result~="x";
        if(xExps[i]>1)result~="^"~xExps[i].to!string;
        if(yExps[i]>=1)result~="y";
        if(yExps[i]>1)result~="^"~yExps[i].to!string;
        return result;
    }

    private string termToString(int i){
        string result=coeffs[i]>=0.0?"+":"";
        result~=coeffs[i].to!string~"x^"~xExps[i].to!string~"y^"~yExps[i].to!string;
        return result;
    }
}
