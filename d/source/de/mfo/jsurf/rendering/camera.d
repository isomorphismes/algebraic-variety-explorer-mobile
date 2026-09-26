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

module de.mfo.jsurf.rendering.camera;
import std.conv : to;
import javax.vecmath : Point3d,Vector3d,Vector4d,Matrix4d;
import java.util.properties : Properties;
import de.mfo.jsurf.util.basic_io : ioToString=toString,fromMatrix4dString;

class Camera {
    enum CameraType { ORTHOGRAPHIC_CAMERA, PERSPECTIVE_CAMERA }
    private CameraType cameraType;
    private double fovY;
    private double height;
    private Matrix4d transform;

    this(){cameraType=CameraType.ORTHOGRAPHIC_CAMERA;fovY=60.0;height=2.0;transform=new Matrix4d();transform.setIdentity();}

    void lookAt(Point3d camPosition,Point3d pointOfInterest,Vector3d upVector){
        auto x=new Vector3d();auto y=new Vector3d();auto z=new Vector3d();
        z.sub(camPosition,pointOfInterest);z.normalize();x.cross(upVector,z);x.normalize();y.cross(z,x);
        transform.setColumn(0,new Vector4d(x));transform.setColumn(1,new Vector4d(y));transform.setColumn(2,new Vector4d(z));
        transform.setColumn(3,new Vector4d(-camPosition.x,-camPosition.y,-camPosition.z,1.0));
    }
    void setCameraType(CameraType t){cameraType=t;} CameraType getCameraType(){return cameraType;}
    void setFoVY(float v){fovY=v;} double getFoVY(){return fovY;}
    void setHeight(double v){height=v;} double getHeight(){return height;}
    Matrix4d getTransform(){return transform;}

    Properties saveProperties(Properties props,string prefix,string suffix){
        props.setProperty(prefix~"type"~suffix,cameraType.to!string);
        props.setProperty(prefix~"fov_y"~suffix,fovY.to!string);
        props.setProperty(prefix~"height"~suffix,height.to!string);
        props.setProperty(prefix~"transform"~suffix,ioToString(transform));return props;
    }
    void loadProperties(Properties props,string prefix,string suffix){
        auto k=prefix~"type"~suffix;
        if(props.containsKey(k))cameraType=props.getProperty(k)=="PERSPECTIVE_CAMERA"?CameraType.PERSPECTIVE_CAMERA:CameraType.ORTHOGRAPHIC_CAMERA;
        k=prefix~"fov_y"~suffix;if(props.containsKey(k))fovY=props.getProperty(k).to!double;
        k=prefix~"height"~suffix;if(props.containsKey(k))height=props.getProperty(k).to!double;
        k=prefix~"transform"~suffix;if(props.containsKey(k))transform=fromMatrix4dString(props.getProperty(k));
    }
}
