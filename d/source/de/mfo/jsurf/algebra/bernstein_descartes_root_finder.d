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

module de.mfo.jsurf.algebra.bernstein_descartes_root_finder;

import std.math : abs, isNaN;
import de.mfo.jsurf.algebra.real_root_finder : RealRootFinder;
import de.mfo.jsurf.algebra.univariate_polynomial : UnivariatePolynomial;
import de.mfo.jsurf.algebra.multinomial_coefficients : MultinomialCoefficients;

class BernsteinDescartesRootFinder : RealRootFinder {
    enum EPSILON = 1.0e-6;
    private bool makeSquarefree;

    private class PolyInterval {
        double[] a;
        double l, u;
        this(double[] a,double l,double u){this.a=a;this.l=l;this.u=u;}
        this(double[] a,bool shift,double l,double u){this(a,l,u);}
    }

    this(bool makeSquarefree){this.makeSquarefree=makeSquarefree;}

    override double[] findAllRoots(UnivariatePolynomial p){
        return findAllRootsIn(
            p,
            -p.stretch(-1.0).maxPositiveRootBound()*(1.0+2.220446049250313E-16),
            p.maxPositiveRootBound()*(1.0+2.220446049250313E-16));
    }

    override double[] findAllRootsIn(UnivariatePolynomial p,double lowerBound,double upperBound){
        p=p.shrink();
        if(makeSquarefree){
            auto g=UnivariatePolynomial.gcd(p,p.derive());
            if(g.degree()>0)p=p.div(g);
        }
        auto neg=findAllNegRootsIn(p,lowerBound,upperBound);
        auto pos=findAllPosRootsIn(p,lowerBound,upperBound);
        auto roots=new double[neg.length+pos.length];
        roots[0..neg.length]=neg[];
        roots[neg.length..$]=pos[];
        return roots;
    }

    package double[] findAllPosRootsIn(UnivariatePolynomial p,double lowerBound,double upperBound){
        if(upperBound<0.0)return[];
        const bound2=nextPowerOfTwo(upperBound);
        p=p.shrink();
        const tlb=lowerBound/bound2;
        const tub=upperBound/bound2;
        p=p.stretch(bound2);

        auto results=new double[cast(size_t)p.degree()];
        size_t resultsLength;
        if(p.getCoeff(0)==0.0){
            if(lowerBound<=0.0)results[resultsLength++]=0.0;
            p=new UnivariatePolynomial(deflate0(p.getCoeffs()));
        }
        if(lowerBound<0.0)lowerBound=0.0;

        if(resultsLength!=results.length){
            PolyInterval[] candidates;
            // Preserve source: this all-roots path starts with the raw
            // coefficients rather than bernsteinCoefficients(...).
            candidates~=new PolyInterval(
                p.getCoeff(0)==0.0?deflate0(p.getCoeffs()):p.getCoeffs(),
                0.0,1.0);
            while(candidates.length){
                auto pi=candidates[$-1];
                candidates.length--;
                if(resultsLength==results.length)break;
                const variations=countSignChanges(pi.a);
                if(variations==1){
                    const root=adjustIntervalAndBisect(p,pi.l,pi.u,tlb,tub)*bound2;
                    if(!isNaN(root))results[resultsLength++]=root;
                }
                if(resultsLength==results.length)break;
                if(variations>1){
                    const center=0.5*(pi.l+pi.u);
                    if(abs(pi.u-pi.l)<0.5*EPSILON){
                        results[resultsLength++]=pi.l<=tlb?lowerBound:pi.l*bound2;
                        continue;
                    }
                    auto first=pi.a;
                    auto second=new double[pi.a.length];
                    deCasteljau(first,second);
                    if(center<=tub)candidates~=new PolyInterval(second,center,pi.u);
                    if(center>=tlb)candidates~=new PolyInterval(first,pi.l,center);
                }
            }
        }
        return results[0..resultsLength].dup;
    }

    package double[] findAllNegRootsIn(UnivariatePolynomial p,double lowerBound,double upperBound){
        if(lowerBound>=0.0)return[];
        p=p.stretch(-1.0);
        auto roots=findAllPosRootsIn(p,-upperBound,-lowerBound);
        if(roots.length==0)return roots;
        for(size_t i=0,j=roots.length-1;i<(roots.length+1)/2;++i,--j){
            const tmp=-roots[i];roots[i]=-roots[j];roots[j]=tmp;
        }
        return roots;
    }

    private enum WhichRoot { SMALLEST,LARGEST }

    override double findFirstRootIn(UnivariatePolynomial p,double lowerBound,double upperBound){
        if(makeSquarefree){
            auto g=UnivariatePolynomial.gcd(p,p.derive());
            if(g.degree()>0)p=p.div(g);
        }
        const root=-findPosRootIn(p.stretch(-1.0),-upperBound,-lowerBound,WhichRoot.LARGEST);
        return isNaN(root)?findPosRootIn(p,lowerBound,upperBound,WhichRoot.SMALLEST):root;
    }

    private double findPosRootIn(UnivariatePolynomial p,double lowerBound,double upperBound,WhichRoot which){
        if(upperBound<=0.0||p.degree()==0)return double.nan;
        p=p.shrink();
        const bound2=nextPowerOfTwo(upperBound);
        const tlb=lowerBound/bound2;
        const tub=upperBound/bound2;
        p=p.stretch(bound2);
        double remembered=double.nan;
        if(p.getCoeff(0)==0.0){
            if(lowerBound<=0.0){
                if(which==WhichRoot.SMALLEST)return 0.0;
                remembered=0.0;
            }
            p=new UnivariatePolynomial(deflate0(p.getCoeffs()));
        }
        if(lowerBound<=0.0)lowerBound=0.0;

        PolyInterval[] candidates;
        candidates~=new PolyInterval(bernsteinCoefficients(p.getCoeffs()),0.0,1.0);
        while(candidates.length){
            auto pi=candidates[$-1];candidates.length--;
            if(pi.a[0]==0.0){
                const root=pi.l*bound2;
                if(lowerBound<=root&&root<=upperBound){
                    if(which==WhichRoot.SMALLEST)return root;
                    remembered=root;
                    pi.a=deflate0(pi.a);
                }
            }
            const variations=countSignChanges(pi.a);
            if(variations==1){
                const root=adjustIntervalAndBisect(p,pi.l,pi.u,tlb,tub)*bound2;
                if(!isNaN(root))return root;
            }else if(variations>1){
                const center=0.5*(pi.l+pi.u);
                if(abs(pi.u-pi.l)<0.5*EPSILON)return pi.l<=tlb?lowerBound:pi.l*bound2;
                auto first=pi.a;
                auto second=new double[pi.a.length];
                deCasteljau(first,second);
                if(which==WhichRoot.SMALLEST){
                    if(center<=tub)candidates~=new PolyInterval(second,center,pi.u);
                    if(center>=tlb)candidates~=new PolyInterval(first,pi.l,center);
                }else{
                    if(center>=tlb)candidates~=new PolyInterval(first,pi.l,center);
                    if(center<=tub)candidates~=new PolyInterval(second,center,pi.u);
                }
            }
        }
        return remembered;
    }

    private static double adjustIntervalAndBisect(UnivariatePolynomial p,double lowerBound,double upperBound,double strictLower,double strictUpper){
        double fl=p.evaluateAt(lowerBound);
        if(lowerBound<strictLower){
            if(upperBound<strictLower)return double.nan;
            const fsl=p.evaluateAt(strictLower);
            if(fl*fsl<0.0||fl==0.0)return double.nan;
            lowerBound=strictLower;fl=fsl;
        }
        double fu=p.evaluateAt(upperBound);
        if(strictUpper<upperBound){
            if(strictUpper<lowerBound)return double.nan;
            const fsu=p.evaluateAt(strictUpper);
            if(fu*fsu<0.0||fu==0.0)return double.nan;
            upperBound=strictUpper;fu=fsu;
        }
        return bisect(p,lowerBound,upperBound,fl,fu);
    }

    private static double bisect(UnivariatePolynomial p,double lowerBound,double upperBound,double fl,double fu){
        const a=p.getCoeffs();
        assert(fl*fu<0.0,"tried bisection on interval without sign change");
        while(abs(upperBound-lowerBound)>EPSILON){
            const center=0.5*(lowerBound+upperBound);
            double fc=a[$-1];
            for(int i=cast(int)a.length-2;i>=0;--i)fc=fc*center+a[i];
            if(fc*fl<0.0){upperBound=center;fu=fc;}
            else if(fc==0.0)return center;
            else{lowerBound=center;fl=fc;}
        }
        return lowerBound;
    }

    private static double[] deflate0(double[] a){return a.length?a[1..$].dup:a;}

    private union DoubleBits { double value; ulong bits; }
    static double nextPowerOfTwo(double d){
        DoubleBits x;x.value=d;auto bits=x.bits;
        if((bits&0x000f_ffff_ffff_ffffUL)!=0){
            x.value=2.0*d;bits=x.bits&0xfff0_0000_0000_0000UL;x.bits=bits;
        }
        return x.value;
    }

    private static int countSignChanges(double[] a){
        int changes;double last=double.nan;
        foreach(value;a)if(value!=0.0){
            if(value*last<0.0)++changes;
            if(changes>1)return changes;
            last=value;
        }
        return changes;
    }

    private static void deCasteljau(double[] a,double[] b){
        b[$-1]=a[$-1];
        for(int i=1;i<cast(int)a.length;++i){
            for(int j=cast(int)a.length-1;j>=i;--j)a[j]=(a[j-1]+a[j])*0.5;
            b[a.length-1-i]=a[$-1];
        }
    }

    private static double[] bernsteinCoefficients(double[] a){
        auto result=new double[a.length];
        foreach(i;0..a.length)result[i]=a[i]/MultinomialCoefficients.binomialCoefficient(cast(int)a.length-1,cast(int)i);
        for(int i=1;i<cast(int)a.length;++i)
            for(int j=cast(int)a.length-1;j>=i;--j)
                result[j]=result[j-1]+result[j];
        return result;
    }
}
