module java.util.properties;
class Properties {
    private string[string] values;
    void setProperty(string key,string value){values[key]=value;}
    string getProperty(string key){auto p=key in values;return p is null?null:*p;}
    bool containsKey(string key){return (key in values)!is null;}
}
