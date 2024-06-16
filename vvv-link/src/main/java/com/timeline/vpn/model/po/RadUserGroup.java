package vpn.model.po;
/**
 * @author gqli
 * @date 2016年12月14日 下午12:04:21
 * @version V1.0
 */
public class RadUserGroup {
    private String userName;
    private String groupName;
    private int priority;
    public String getUserName() {
        return userName;
    }
    public void setUserName(String userName) {
        this.userName = userName;
    }
    public String getGroupName() {
        return groupName;
    }
    public void setGroupName(String groupName) {
        this.groupName = groupName;
    }
    public int getPriority() {
        return priority;
    }
    public void setPriority(int priority) {
        this.priority = priority;
    }
    
}

