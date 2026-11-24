package com.timeline.vpn.model.vo;

/**
 * @author gqli
 * @date 2017年8月17日 下午7:51:08
 * @version V1.0
 */
public class SoundItemsVo {
    /**
     * 条目 id（vpn.sounditems.id）。契约 sound-lyrics-contract §2 Phase 0：
     * 歌词/翻译等按条目挂的元数据全靠它。VoBuilder 的 BeanUtils 从 PO 同名属性自动拷出；
     * mapper 是 select *（SoundChannelMapper.xml），列里本来就有 id，只是 VO 以前没透出。
     * 老客户端忽略多余字段，安全。
     */
    private Integer id;
    private String url;
    private String name;
    private String file;
    private String fileDate;
    public Integer getId() {
        return id;
    }
    public void setId(Integer id) {
        this.id = id;
    }
    public String getUrl() {
        return url;
    }
    public void setUrl(String url) {
        this.url = url;
    }
    public String getName() {
        return name;
    }
    public void setName(String name) {
        this.name = name;
    }
    public String getFile() {
        return file;
    }
    public void setFile(String file) {
        this.file = file;
    }
    public String getFileDate() {
        return fileDate;
    }
    public void setFileDate(String fileDate) {
        this.fileDate = fileDate;
    }
    
    
}

