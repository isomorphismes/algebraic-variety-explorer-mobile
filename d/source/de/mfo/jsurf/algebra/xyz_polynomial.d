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

module de.mfo.jsurf.algebra.xyz_polynomial;

import std.algorithm.sorting : sort;
import std.algorithm.comparison : min,max;
import std.conv : to;
import std.math : abs, mathPow = pow;
import de.mfo.jsurf.algebra.helper : intPow = pow;
import de.mfo.jsurf.algebra.univariate_polynomial : UnivariatePolynomial;
import de.mfo.jsurf.algebra.xy_polynomial : XYPolynomial;

class XYZPolynomial {
    static class Term {
        double coeff;
        byte xExp,yExp,zExp;

        this(Term t){coeff=t.coeff;xExp=t.xExp;yExp=t.yExp;zExp=t.zExp;}
        this(double coeff,byte xExp,byte yExp,byte zExp){this.coeff=coeff;this.xExp=xExp;this.yExp=yExp;this.zExp=zExp;}

        int lexCompare(Term t){
            int result=xExp<t.xExp?-4:(xExp>t.xExp?4:0);
            if(result==0){result+=yExp<t.yExp?-2:(yExp>t.yExp?2:0);if(result==0)result+=zExp<t.zExp?-1:(zExp>t.zExp?1:0);}
            return result;
        }
        int compareTo(Term t){
            int result=xExp<t.xExp?-8:(xExp>t.xExp?8:0);
            if(result==0){result+=yExp<t.yExp?-4:(yExp>t.yExp?4:0);if(result==0){result+=zExp<t.zExp?-2:(zExp>t.zExp?2:0);if(result==0)result+=coeff<t.coeff?-1:(coeff>t.coeff?2:0);}}
            return result;
        }
        Term mult(Term t){return new Term(coeff*t.coeff,cast(byte)(xExp+t.xExp),cast(byte)(yExp+t.yExp),cast(byte)(zExp+t.zExp));}
        Term mult(double d){auto r=new Term(this);r.coeff*=d;return r;}
        Term powTerm(int exp){return new Term(mathPow(coeff,cast(double)exp),cast(byte)(xExp*exp),cast(byte)(yExp*exp),cast(byte)(zExp*exp));}
        double evaluateAt(double x,double y,double z){return coeff*intPow(x,xExp)*intPow(y,yExp)*intPow(z,zExp);}

        override string toString(){
            string r;
            if(coeff!=1.0){if(coeff==-1.0 && !(xExp==0&&yExp==0&&zExp==0))r~="-";else r~=coeff.to!string;}
            if(xExp>=1)r~="x";if(xExp>1)r~="^"~xExp.to!string;
            if(yExp>=1)r~="y";if(yExp>1)r~="^"~yExp.to!string;
            if(zExp>=1)r~="z";if(zExp>1)r~="^"~zExp.to!string;
            return r;
        }
        string longToString(){return (coeff>=0?"+":"")~coeff.to!string~"x^"~xExp.to!string~"y^"~yExp.to!string~"z^"~zExp.to!string;}
        bool equals(Term t){return coeff==t.coeff&&xExp==t.xExp&&yExp==t.yExp&&zExp==t.zExp;}
        int sourceHashCode(){
            union Bits { double d; ulong u; } Bits b; b.d=coeff;
            return cast(int)(b.u % 0x0000_0000_FFFF_FFFFUL)
                & cast(int)xExp & (cast(int)xExp<<8) & (cast(int)xExp<<16);
        }
    }

    static XYZPolynomial X,Y,Z,ZERO,ONE;
    static this(){
        X=new XYZPolynomial(new Term(1.0,1,0,0));
        Y=new XYZPolynomial(new Term(1.0,0,1,0));
        Z=new XYZPolynomial(new Term(1.0,0,0,1));
        ZERO=new XYZPolynomial(0.0);ONE=new XYZPolynomial(1.0);
    }

    private Term[] terms;
    private byte xDegree,yDegree,zDegree,minDegree,maxDegree,degree;
    private int numXyTerms;
    private bool isCompact=false;

    this(){this(0.0);}
    this(double value){this(new Term(value,0,0,0));}
    this(XYZPolynomial p){terms=new Term[p.terms.length];foreach(i;0..terms.length)terms[i]=new Term(p.terms[i]);calculateDegree();}
    this(Term t){terms=[new Term(t)];calculateDegree();}
    package this(Term[] terms){this.terms=terms;calculateDegree();}

    private void calculateDegree(){
        xDegree=terms[$-1].xExp;yDegree=0;zDegree=0;numXyTerms=1;
        auto last=terms[0];
        foreach(t;terms){
            yDegree=cast(byte)max(cast(int)yDegree,cast(int)t.yExp);
            zDegree=cast(byte)max(cast(int)zDegree,cast(int)t.zExp);
            degree=cast(byte)max(cast(int)degree,cast(int)t.xExp+t.yExp+t.zExp);
            if(last.xExp!=t.xExp||last.yExp!=t.yExp){last=t;++numXyTerms;}
        }
        minDegree=cast(byte)min(cast(int)xDegree,min(cast(int)yDegree,cast(int)zDegree));
        maxDegree=cast(byte)max(cast(int)xDegree,max(cast(int)yDegree,cast(int)zDegree));
    }

    package Term[] getTerms(){return terms;}

    XYZPolynomial neg(){auto r=new Term[terms.length];foreach(i,t;terms)r[i]=new Term(-t.coeff,t.xExp,t.yExp,t.zExp);return new XYZPolynomial(r);}
    XYZPolynomial sub(XYZPolynomial p){return add(p.neg());}

    XYZPolynomial add(XYZPolynomial p){
        Term[] result;
        size_t i1=0,i2=0;
        while(i1<terms.length&&i2<p.terms.length){
            const cmp=terms[i1].lexCompare(p.terms[i2]);
            if(cmp<0)result~=new Term(terms[i1++]);
            else if(cmp>0)result~=new Term(p.terms[i2++]);
            else {auto s=new Term(terms[i1++]);s.coeff+=p.terms[i2++].coeff;result~=s;}
        }
        while(i1<terms.length)result~=new Term(terms[i1++]);
        while(i2<p.terms.length)result~=new Term(p.terms[i2++]);
        return new XYZPolynomial(result);
    }

    XYZPolynomial mult(XYZPolynomial p){return multiply(this,p);}
    private static XYZPolynomial multiply(XYZPolynomial p1,XYZPolynomial p2){
        Term[] result;
        foreach(t1;p1.terms)foreach(t2;p2.terms)result~=t1.mult(t2);
        return new XYZPolynomial(collect(result,true));
    }
    XYZPolynomial mult(double d){auto r=new Term[terms.length];foreach(i,t;terms)r[i]=new Term(d*t.coeff,t.xExp,t.yExp,t.zExp);return new XYZPolynomial(r);}
    XYZPolynomial pow(int exp){
        if(exp==0)return ONE;if(exp==1)return this;
        auto result=this;auto x=this;--exp;
        while(exp>0){if((exp&1)==1){result=result.mult(x);--exp;}x=x.mult(x);exp/=2;}
        return result;
    }

    double evaluateXYZ(double x,double y,double z){
        auto xp=new double[cast(int)maxDegree+1];auto yp=new double[xp.length];auto zp=new double[xp.length];
        xp[0]=yp[0]=zp[0]=1.0;
        for(int i=1;i<=maxDegree;++i){xp[i]=xp[i-1]*x;yp[i]=yp[i-1]*y;zp[i]=zp[i-1]*z;}
        double result=0;foreach(t;terms)result+=t.coeff*xp[t.xExp]*yp[t.yExp]*zp[t.zExp];
        return result;
    }

    XYPolynomial evaluateZ(double z){
        if(terms.length==0)return new XYPolynomial(0.0);
        if(!isCompact){terms=collect(terms,true);isCompact=true;}
        auto zp=new double[cast(int)zDegree*2+1];
        for(int i=0;i<=zDegree;++i)zp[zDegree+i]=mathPow(z,cast(double)i);
        auto c=new double[numXyTerms];auto xe=new byte[numXyTerms];auto ye=new byte[numXyTerms];
        int ti,incr,lastIndex,xyi;
        if(abs(z)>1.0){ti=0;incr=1;lastIndex=cast(int)terms.length-1;xyi=0;for(int i=1;i<=zDegree;++i)zp[zDegree-i]=1.0/zp[zDegree+i];}
        else {ti=cast(int)terms.length-1;incr=-1;lastIndex=0;xyi=cast(int)c.length-1;}
        auto last=terms[ti];double coeff=last.coeff;xe[xyi]=last.xExp;ye[xyi]=last.yExp;
        while(incr*ti<incr*lastIndex){
            ti+=incr;auto t=terms[ti];
            if(last.xExp==t.xExp&&last.yExp==t.yExp)coeff=coeff*zp[zDegree+(last.zExp-t.zExp)]+t.coeff;
            else {coeff*=zp[zDegree+last.zExp];c[xyi]=coeff;xyi+=incr;coeff=t.coeff;xe[xyi]=t.xExp;ye[xyi]=t.yExp;}
            last=t;
        }
        coeff*=zp[zDegree+last.zExp];c[xyi]=coeff;
        return new XYPolynomial(c,xe,ye,false);
    }

    XYZPolynomial eliminateZeroTerms(){
        int j=0;foreach(i;0..terms.length)if(terms[i].coeff!=0.0)terms[j++]=terms[i];
        if(j==0)terms[j++]=new Term(0.0,0,0,0);
        terms=terms[0..j].dup;calculateDegree();return this;
    }

    UnivariatePolynomial substitute(UnivariatePolynomial xPoly,UnivariatePolynomial yPoly,UnivariatePolynomial zPoly){
        if(terms.length==0)return new UnivariatePolynomial();
        if(!isCompact){terms=collect(terms,true);isCompact=true;}
        int ti=cast(int)terms.length;auto last=terms[--ti];
        auto xr=UnivariatePolynomial.ZERO;auto yr=UnivariatePolynomial.ZERO;auto zr=new UnivariatePolynomial(last.coeff);
        auto xp=new UnivariatePolynomial[cast(int)xDegree+1];
        auto yp=new UnivariatePolynomial[cast(int)yDegree+1];
        auto zp=new UnivariatePolynomial[cast(int)zDegree+1];
        while(ti>0){
            auto t=terms[--ti];const xequal=last.xExp==t.xExp;const yequal=last.yExp==t.yExp;
            if(xequal&&yequal)zr=zr.mult_add(zPoly.pow(last.zExp-t.zExp,zp),t.coeff);
            else {
                zr=zr.mult(zPoly.pow(last.zExp,zp));
                if(xequal)yr=yr.add(zr).mult(yPoly.pow(last.yExp-t.yExp,yp));
                else {yr=yr.add(zr).mult(yPoly.pow(last.yExp,yp));xr=xr.add(yr).mult(xPoly.pow(last.xExp-t.xExp,xp));yr=UnivariatePolynomial.ZERO;}
                zr=new UnivariatePolynomial(t.coeff);
            }
            last=t;
        }
        zr=zr.mult(zPoly.pow(last.zExp,zp));
        yr=yr.add(zr).mult(yPoly.pow(last.yExp,yp));
        // Preserve original source's zPolyPowers argument on the final x power.
        xr=xr.add(yr).mult(xPoly.pow(last.xExp,zp));
        return xr;
    }

    XYZPolynomial substitute(XYZPolynomial xPoly,XYZPolynomial yPoly,XYZPolynomial zPoly){
        if(terms.length==0)return new XYZPolynomial();
        if(!isCompact){terms=collect(terms,true);isCompact=true;}
        int ti=cast(int)terms.length;auto last=terms[--ti];
        auto xr=new XYZPolynomial();auto yr=new XYZPolynomial();auto zr=new XYZPolynomial(last.coeff);
        while(ti>0){
            auto t=terms[--ti];const xequal=last.xExp==t.xExp;const yequal=last.yExp==t.yExp;
            if(xequal&&yequal)zr=zr.mult(zPoly.pow(last.zExp-t.zExp)).add(new XYZPolynomial(t.coeff));
            else {
                zr=zr.mult(zPoly.pow(last.zExp));
                if(xequal)yr=yr.add(zr).mult(yPoly.pow(last.yExp-t.yExp));
                else {yr=yr.add(zr).mult(yPoly.pow(last.yExp));xr=xr.add(yr).mult(xPoly.pow(last.xExp-t.xExp));yr=new XYZPolynomial();}
                zr=new XYZPolynomial(t.coeff);
            }
            last=t;
        }
        zr=zr.mult(zPoly.pow(last.zExp));yr=yr.add(zr).mult(yPoly.pow(last.yExp));xr=xr.add(yr).mult(xPoly.pow(last.xExp));
        return xr;
    }

    private static Term[] collect(Term[] input,bool doSort){
        if(input.length==0)return input;
        auto terms=input.dup;
        if(doSort)sort!((a,b)=>a.compareTo(b)<0)(terms);
        Term[] result;int j=0;int i=1;
        for(;i<terms.length;++i){
            if(terms[j].lexCompare(terms[i])!=0){
                const s=kahanSum(terms,j,i-j);if(s!=0.0)result~=new Term(s,terms[j].xExp,terms[j].yExp,terms[j].zExp);j=i;
            }
        }
        if(j!=i){const s=kahanSum(terms,j,i-j);if(s!=0.0)result~=new Term(s,terms[j].xExp,terms[j].yExp,terms[j].zExp);}
        if(result.length==0)result~=new Term(0.0,0,0,0);
        return result;
    }

    private static double kahanSum(Term[] terms,int from,int num){
        double sum=0;if(num!=0){sum=terms[from].coeff;double c=0;for(int i=from+1;i<from+num;++i){const y=terms[i].coeff-c;const t=sum+y;c=(t-sum)-y;sum=t;}}return sum;
    }

    override string toString(){
        string s;foreach(t;terms)s~=(t.coeff>0?"+":"")~t.toString();
        if(s.length&&s[0]=='+')s=s[1..$];return s;
    }

    double[][][] recursiveView(){
        auto a=new double[][][cast(int)zDegree+1];
        for(int i=0;i<=zDegree;++i){
            auto tmp=new double[][cast(int)yDegree+1];
            for(int j=0;j<=yDegree;++j)tmp[j]=new double[xDegree];
            a[i]=tmp;
        }
        foreach(t;terms)a[t.zExp][t.yExp][t.xExp]=t.coeff;
        return a;
    }

    bool equals(XYZPolynomial p){
        if(terms.length!=p.terms.length)return false;
        foreach(i;0..terms.length)if(!terms[i].equals(p.terms[i]))return false;
        return true;
    }

    int sourceHashCode(){int c=0;foreach(t;terms)c+=t.sourceHashCode();return c;}
}

unittest {
    auto sphere=XYZPolynomial.X.pow(2).add(XYZPolynomial.Y.pow(2)).add(XYZPolynomial.Z.pow(2)).sub(new XYZPolynomial(0.64));
    assert(abs(sphere.evaluateXYZ(0.8,0,0))<1e-12);
}
