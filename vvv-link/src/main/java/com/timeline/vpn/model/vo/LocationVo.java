package com.timeline.vpn.model.vo;

/**
 * @author gqli
 * @date 2016年8月9日 下午12:20:59
 * @version V1.0
 */
public class LocationVo {
    private int id;
    private String img;
    private String name;
    private String ename;
    private int type;
    private String cityName;
    private int level;
    private Integer hostId;
    private String gateway;
    private Integer port;
    private String  category;
    //代表这条数据是 location信息还是一条分类;0 = location信息，1 = cate信息
    private int  locationType =0 ;
    /**
     * 节点经纬度。客户端 3D 地球用这个定位；为 null 时客户端按城市名兜底。
     * 见 sql/2026111800_location_geo.sql。
     */
    private java.math.BigDecimal lat;
    private java.math.BigDecimal lng;

    public java.math.BigDecimal getLat() {
        return lat;
    }

    public void setLat(java.math.BigDecimal lat) {
        this.lat = lat;
    }

    public java.math.BigDecimal getLng() {
        return lng;
    }

    public void setLng(java.math.BigDecimal lng) {
        this.lng = lng;
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

    public String getCityName() {
        return cityName;
    }

    public void setCityName(String cityName) {
        this.cityName = cityName;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
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

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }
}

