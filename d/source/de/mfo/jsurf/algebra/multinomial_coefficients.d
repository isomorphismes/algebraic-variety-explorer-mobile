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

module de.mfo.jsurf.algebra.multinomial_coefficients;

class MultinomialCoefficients {
    enum N=100;
    enum K=100;
    private static long[101][101] binomialCoeffs;

    static this(){
        for(int k=1;k<=K;++k) binomialCoeffs[0][k]=0;
        for(int n=0;n<=N;++n) binomialCoeffs[n][0]=1;
        for(int n=1;n<=N;++n)
            for(int k=1;k<=K;++k)
                binomialCoeffs[n][k]=binomialCoeffs[n-1][k-1]+binomialCoeffs[n-1][k];
    }

    static long binomialCoefficient(int n,int k){
        if(n<=N && k<=K) return binomialCoeffs[n][k];
        return binomialCoefficient(n-1,k-1)+binomialCoefficient(n-1,k);
    }

    static long multinomialCoefficient(int[] values...){
        if(values.length==0)return 1;
        long result=1; int sum=values[0];
        foreach(i;1..values.length){sum+=values[i];result*=binomialCoefficient(sum,values[i]);}
        return result;
    }

    static long trinomialCoefficient(int k1,int k2,int k3){
        return multinomialCoefficient(k1,k2,k3);
    }
    static long quadrinomialCoefficient(int k1,int k2,int k3,int k4){
        return multinomialCoefficient(k1,k2,k3,k4);
    }
}
