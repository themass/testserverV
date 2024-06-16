package vpn.model.vo;
/**
 * @author gqli
 * @date 2017年9月3日 上午1:14:45
 * @version V1.0
 */
public class ImgItemsVo {
    private String url;
    private String channel;
    private String name;
    private String fileDate;
    private int pics;
    private Integer type;
    
    public Integer getType() {
        return type;
    }
    public void setType(Integer type) {
        this.type = type;
    }   
    public String getUrl() {
        return url;
    }
    public void setUrl(String url) {
        this.url = url;
    }
    public String getChannel() {
        return channel;
    }
    public void setChannel(String channel) {
        this.channel = channel;
    }
    public String getName() {
        return name;
    }
    public void setName(String name) {
        this.name = name;
    }
    public String getFileDate() {
        return fileDate;
    }
    public void setFileDate(String fileDate) {
        this.fileDate = fileDate;
    }
    public int getPics() {
        return pics;
    }
    public void setPics(int pics) {
        this.pics = pics;
    }
    
}

