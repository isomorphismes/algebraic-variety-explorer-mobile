module javax.vecmath;

import std.algorithm.comparison : min, max;
import std.math : sqrt;

class Vector2d {
    double x, y;
    this() {}
    this(double x, double y) { this.x=x; this.y=y; }
    this(Vector2d v) { this(v.x,v.y); }
    void scale(double s){x*=s;y*=s;}
}

class Point3d {
    double x, y, z;
    this() {}
    this(double x, double y, double z) { this.x=x; this.y=y; this.z=z; }
    this(Point3d p) { this(p.x,p.y,p.z); }
    void add(Vector3d v) { x+=v.x; y+=v.y; z+=v.z; }
    void sub(Vector3d v) { x-=v.x; y-=v.y; z-=v.z; }
    override string toString() { import std.format : format; return format("(%s, %s, %s)",x,y,z); }
}

class Point3f {
    float x, y, z;
    this() {}
    this(float x, float y, float z) { this.x=x; this.y=y; this.z=z; }
    this(Point3f p) { this(p.x,p.y,p.z); }
}

class Vector3d {
    double x, y, z;
    this() {}
    this(double x, double y, double z) { this.x=x; this.y=y; this.z=z; }
    this(Vector3d v) { this(v.x,v.y,v.z); }
    this(Point3d p) { this(p.x,p.y,p.z); }

    void set(double x,double y,double z){this.x=x;this.y=y;this.z=z;}
    void set(Vector3d v){set(v.x,v.y,v.z);}
    void add(Vector3d v){x+=v.x;y+=v.y;z+=v.z;}
    void add(Vector3d a, Vector3d b){x=a.x+b.x;y=a.y+b.y;z=a.z+b.z;}
    void sub(Vector3d v){x-=v.x;y-=v.y;z-=v.z;}
    void sub(Vector3d a, Vector3d b){x=a.x-b.x;y=a.y-b.y;z=a.z-b.z;}
    void sub(Point3d a, Point3d b){x=a.x-b.x;y=a.y-b.y;z=a.z-b.z;}
    void cross(Vector3d a, Vector3d b){
        const nx=a.y*b.z-a.z*b.y;
        const ny=a.z*b.x-a.x*b.z;
        const nz=a.x*b.y-a.y*b.x;
        x=nx;y=ny;z=nz;
    }
    double dot(Vector3d v){return x*v.x+y*v.y+z*v.z;}
    double lengthSquared(){return dot(this);}
    double length(){return sqrt(lengthSquared());}
    void normalize(){const l=length(); if(l!=0.0){x/=l;y/=l;z/=l;}}
    void scale(double s){x*=s;y*=s;z*=s;}
    void negate(){x=-x;y=-y;z=-z;}
    override string toString() { import std.format : format; return format("(%s, %s, %s)",x,y,z); }
}

class Vector3f {
    float x, y, z;
    this() {}
    this(float x, float y, float z){this.x=x;this.y=y;this.z=z;}
    this(Vector3f v){this(v.x,v.y,v.z);}
    void normalize(){
        const l=cast(float)sqrt(cast(double)(x*x+y*y+z*z));
        if(l!=0.0f){x/=l;y/=l;z/=l;}
    }
}

class Vector4d {
    double x,y,z,w;
    this(){}
    this(double x,double y,double z,double w=0.0){this.x=x;this.y=y;this.z=z;this.w=w;}
    this(Vector3d v){this(v.x,v.y,v.z,0.0);}
    this(Point3d p){this(p.x,p.y,p.z,1.0);}
}

class Color3f {
    float x,y,z;
    this(){}
    this(float x,float y,float z){this.x=x;this.y=y;this.z=z;}
    this(Color3f c){this(c.x,c.y,c.z);}
    void set(Color3f c){x=c.x;y=c.y;z=c.z;}
    void scale(float s){x*=s;y*=s;z*=s;}
    void add(Color3f c){x+=c.x;y+=c.y;z+=c.z;}
    void interpolate(Color3f a, Color3f b, float t){
        x=a.x*(1.0f-t)+b.x*t;
        y=a.y*(1.0f-t)+b.y*t;
        z=a.z*(1.0f-t)+b.z*t;
    }
    void clamp(float low,float high){
        x=min(high,max(low,x)); y=min(high,max(low,y)); z=min(high,max(low,z));
    }
}

class Matrix3d {
    double[9] m;
    this(){setIdentity();}
    this(Matrix3d other){m=other.m;}
    void setIdentity(){m=[1,0,0,0,1,0,0,0,1];}
    double getElement(int r,int c){return m[r*3+c];}
    void setElement(int r,int c,double v){m[r*3+c]=v;}
    void transpose(){
        double t=m[1];m[1]=m[3];m[3]=t;
        t=m[2];m[2]=m[6];m[6]=t;
        t=m[5];m[5]=m[7];m[7]=t;
    }
    void transform(Vector3d v){
        const x=m[0]*v.x+m[1]*v.y+m[2]*v.z;
        const y=m[3]*v.x+m[4]*v.y+m[5]*v.z;
        const z=m[6]*v.x+m[7]*v.y+m[8]*v.z;
        v.set(x,y,z);
    }
}

class Matrix4d {
    double[16] m;

    @property double m00(){return m[0];} @property void m00(double v){m[0]=v;}
    @property double m01(){return m[1];} @property void m01(double v){m[1]=v;}
    @property double m02(){return m[2];} @property void m02(double v){m[2]=v;}
    @property double m03(){return m[3];} @property void m03(double v){m[3]=v;}
    @property double m10(){return m[4];} @property void m10(double v){m[4]=v;}
    @property double m11(){return m[5];} @property void m11(double v){m[5]=v;}
    @property double m12(){return m[6];} @property void m12(double v){m[6]=v;}
    @property double m13(){return m[7];} @property void m13(double v){m[7]=v;}
    @property double m20(){return m[8];} @property void m20(double v){m[8]=v;}
    @property double m21(){return m[9];} @property void m21(double v){m[9]=v;}
    @property double m22(){return m[10];} @property void m22(double v){m[10]=v;}
    @property double m23(){return m[11];} @property void m23(double v){m[11]=v;}
    @property double m30(){return m[12];} @property void m30(double v){m[12]=v;}
    @property double m31(){return m[13];} @property void m31(double v){m[13]=v;}
    @property double m32(){return m[14];} @property void m32(double v){m[14]=v;}
    @property double m33(){return m[15];} @property void m33(double v){m[15]=v;}

    this(){setIdentity();}
    this(Matrix4d other){m=other.m;}
    void setIdentity(){m=[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1];}
    double getElement(int r,int c){return m[r*4+c];}
    void setElement(int r,int c,double v){m[r*4+c]=v;}
    void setColumn(int c, Vector4d v){m[c]=v.x;m[4+c]=v.y;m[8+c]=v.z;m[12+c]=v.w;}
    void getRotationScale(Matrix3d outm){
        foreach(r;0..3) foreach(c;0..3) outm.setElement(cast(int)r,cast(int)c,m[r*4+c]);
    }
    void mul(Matrix4d rhs){
        auto a=m; double[16] outm;
        foreach(r;0..4) foreach(c;0..4){
            double s=0; foreach(k;0..4)s+=a[r*4+k]*rhs.m[k*4+c];
            outm[r*4+c]=s;
        } m=outm;
    }
    void mul(Matrix4d a, Matrix4d b){m=a.m;mul(b);}
    void transform(Point3d p){
        const x=m[0]*p.x+m[1]*p.y+m[2]*p.z+m[3];
        const y=m[4]*p.x+m[5]*p.y+m[6]*p.z+m[7];
        const z=m[8]*p.x+m[9]*p.y+m[10]*p.z+m[11];
        const w=m[12]*p.x+m[13]*p.y+m[14]*p.z+m[15];
        if(w!=0.0 && w!=1.0){p.x=x/w;p.y=y/w;p.z=z/w;} else {p.x=x;p.y=y;p.z=z;}
    }
    void transform(Vector3d v){
        const x=m[0]*v.x+m[1]*v.y+m[2]*v.z;
        const y=m[4]*v.x+m[5]*v.y+m[6]*v.z;
        const z=m[8]*v.x+m[9]*v.y+m[10]*v.z;
        v.set(x,y,z);
    }
    void transpose(){
        foreach(r;0..4) foreach(c;r+1..4){auto t=m[r*4+c];m[r*4+c]=m[c*4+r];m[c*4+r]=t;}
    }
}
