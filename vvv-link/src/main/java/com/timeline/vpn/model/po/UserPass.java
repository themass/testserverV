package vpn.model.po;
/**
 * @author gqli
 * @date 2017年1月6日 下午9:54:43
 * @version V1.0
 */
public class UserPass {
    private String name;
    private String pass;
    public UserPass(String name,String pass){
        this.name = name;
        this.pass = pass;
    }
    public String getName() {
        return name;
    }
    public void setName(String name) {
        this.name = name;
    }
    public String getPass() {
        return pass;
    }
    public void setPass(String pass) {
        this.pass = pass;
    }
    
}

