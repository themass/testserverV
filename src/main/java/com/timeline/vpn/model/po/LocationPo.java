package com.timeline.vpn.model.po;

/**
 * @author gqli
 * @date 2016年8月9日 下午12:20:59
 * @version V1.0
 */
public class LocationPo implements Comparable<LocationPo>{
    private int id;
    private String img;
    private String name;
    private String ename;
    private int type;
    private boolean enable;
    private String cityName;
    private int level;
    private Integer hostId;
    private String gateway;
    private Integer port;
    private Integer weight;
    private String showName;
    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getImg() {
        return img;
    }

    public void setImg(String img) {
        this.img = img;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getEname() {
        return ename;
    }

    public void setEname(String ename) {
        this.ename = ename;
    }

    public int getType() {
        return type;
    }

    public void setType(int type) {
        this.type = type;
    }

    public boolean isEnable() {
        return enable;
    }

    public void setEnable(boolean enable) {
        this.enable = enable;
    }

    public String getCityName() {
        return cityName;
    }

    public void setCityName(String cityName) {
        this.cityName = cityName;
    }

    public int getLevel() {
        return level;
    }

    public void setLevel(int level) {
        this.level = level;
    }

    public Integer getHostId() {
        return hostId;
    }

    public void setHostId(Integer hostId) {
        this.hostId = hostId;
    }

    public String getGateway() {
        return gateway;
    }

    public void setGateway(String gateway) {
        this.gateway = gateway;
    }

    public Integer getPort() {
        return port;
    }

    public void setPort(Integer port) {
        this.port = port;
    }

    public Integer getWeight() {
        return weight;
    }

    public void setWeight(Integer weight) {
        this.weight = weight;
    }

    public String getShowName() {
        return showName;
    }

    public void setShowName(String showName) {
        this.showName = showName;
    }

    @Override
    public String toString() {
        return "LocationPo [id=" + id + ", img=" + img + ", name=" + name + ", ename=" + ename
                + ", type=" + type + ", enable=" + enable + ", cityName=" + cityName + ", level="
                + level + ", hostId=" + hostId + ", gateway=" + gateway + ", port=" + port
                + ", weight=" + weight + "]";
    }

    @Override
    public int compareTo(LocationPo o) {
        int ret = type-o.getType();
        ret = (ret==0?name.compareTo(o.getName()):ret);
        return ret ==0?id-o.getId():ret;
    }
    


}

