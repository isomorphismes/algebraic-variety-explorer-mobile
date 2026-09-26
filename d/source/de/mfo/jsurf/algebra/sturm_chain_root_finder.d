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

module de.mfo.jsurf.algebra.sturm_chain_root_finder;

import std.math : abs,isNaN;
import de.mfo.jsurf.algebra.real_root_finder : RealRootFinder;
import de.mfo.jsurf.algebra.univariate_polynomial : UnivariatePolynomial;

interface Function {
    double valueAt(double x);
}

abstract class SturmPolynomial : Function {
    abstract double[] toArray();
    abstract SturmPolynomial diff();
    abstract SturmPolynomial mod(SturmPolynomial other);
    abstract SturmPolynomial div(SturmPolynomial other);
    abstract SturmPolynomial multiply(double scalar);
    abstract int degree();

    static SturmPolynomial gcd(SturmPolynomial a,SturmPolynomial b){
        while(b.degree()!=-1){auto t=b;b=a.mod(b);a=t;}
        return a;
    }
}

class MyPolynomial : SturmPolynomial {
    package UnivariatePolynomial p;
    this(UnivariatePolynomial p){this.p=p;}
    override double valueAt(double x){return p.evaluateAt(x);}
    override double[] toArray(){return p.getCoeffs();}
    override SturmPolynomial diff(){return new MyPolynomial(p.derive());}

    private static double[] reduce(double[] a,int degA,double[] b,int degB){
        const diff=degA-degB;auto result=new double[degA];
        for(int i=degA-1;i>=diff;--i)result[i]=a[i]-b[i-diff]/b[degB]*a[degA];
        for(int i=0;i<diff;++i)result[i]=a[i];
        return result;
    }

    private static double[] modArray(double[] a,int degA,double[] b,int degB){
        if(degB<1){
            if(degB==-1)throw new Exception("Cannot divide by constant polynomials");
            return[0.0];
        }
        if(degA<degB)return a;
        auto result=reduce(a,degA,b,degB);
        int newDeg=degA-1;
        while(newDeg>=0&&result[newDeg]==0.0)--newDeg;
        return modArray(result,newDeg,b,degB);
    }

    override SturmPolynomial mod(SturmPolynomial other){
        return new MyPolynomial(new UnivariatePolynomial(modArray(toArray(),degree(),other.toArray(),other.degree())));
    }
    override SturmPolynomial div(SturmPolynomial other){
        return new MyPolynomial(new UnivariatePolynomial(reduce(toArray(),degree(),other.toArray(),other.degree())));
    }
    override SturmPolynomial multiply(double scalar){return new MyPolynomial(p.mult(scalar));}
    override int degree(){
        const coeffs=p.getCoeffs();int deg=-1;
        foreach(c;coeffs)if(c!=0.0)++deg; // preserve source counting behavior
        return deg;
    }
}

class Solve {
    enum FLOATING_POINT_PRECISION=0.0;

    static double solve(SturmPolynomial poly,int num,double lower,double upper,double precision,int iterations){
        return bisection(calculateSturm(poly),num,lower,upper,precision,iterations);
    }
    static double solve(SturmPolynomial poly,int num,double lower,double upper,int iterations){
        return bisection(calculateSturm(poly),num,lower,upper,FLOATING_POINT_PRECISION,iterations);
    }

    private static int w(SturmPolynomial[] sturm,double x,double precision){
        int signChanges,lastNonZero;
        for(int i=1;i<cast(int)sturm.length;++i){
            if(abs(sturm[i].valueAt(x))>precision){
                if(sturm[lastNonZero].valueAt(x)*sturm[i].valueAt(x)<0.0)++signChanges;
                lastNonZero=i;
            }
        }
        return signChanges;
    }

    private static double bisection(SturmPolynomial[] sturm,int num,double lower,double upper,double precision,int iterations){
        auto p=sturm[$-1];const t=lower;
        for(int i=0;i<iterations;++i){
            const center=(upper+lower)/2.0;
            if(upper<=lower||center<=lower||center>=upper)return lower;
            const changes=w(sturm,t,precision)-w(sturm,center,precision);
            if(changes<num)lower=center;else upper=center;
            const fl=p.valueAt(lower),fu=p.valueAt(upper);
            if(fl*fu<0.0)return scalarBisect(p,lower,upper,fl,fu);
        }
        if(w(sturm,upper,precision)-w(sturm,t,precision)==0)return double.nan;
        return (upper+lower)/2.0;
    }

    private static double scalarBisect(SturmPolynomial p,double lower,double upper,double fl,double fu){
        double center=lower,oldCenter=double.nan;const a=p.toArray();
        while(center!=oldCenter){
            oldCenter=center;center=0.5*(lower+upper);
            double fc=a[$-1];
            for(int i=cast(int)a.length-2;i>=0;--i)fc=fc*center+a[i];
            if(fc*fl<0.0){upper=center;fu=fc;}
            else if(fc==0.0)return center;
            else{lower=center;fl=fc;}
        }
        return center;
    }

    static SturmPolynomial[] calculateSturm(SturmPolynomial function){
        auto g=SturmPolynomial.gcd(function,function.diff());
        if(g.degree()>0)function=function.div(g);
        SturmPolynomial[] sturm;
        sturm=[function]~sturm;
        sturm=[function.diff()]~sturm;
        while(sturm[0].degree()>0)
            sturm=[sturm[1].mod(sturm[0]).multiply(-1.0)]~sturm;
        return sturm;
    }
}

class SturmChainRootFinder : RealRootFinder {
    override double[] findAllRoots(UnivariatePolynomial p){
        assert(0,"findAllRoots is not implemented in the Java source");
        return null;
    }
    override double[] findAllRootsIn(UnivariatePolynomial p,double lowerBound,double upperBound){
        assert(0,"findAllRootsIn is not implemented in the Java source");
        return null;
    }
    override double findFirstRootIn(UnivariatePolynomial p,double lowerBound,double upperBound){
        return Solve.solve(new MyPolynomial(p),1,lowerBound,upperBound,20);
    }
}
