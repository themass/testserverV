package vpn.model.form;

import java.util.List;

public class ChatHistory {
    public String id;
    public List<SimpleMessage> content;

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public List<SimpleMessage> getContent() {
        return content;
    }

    public void setContent(List<SimpleMessage> content) {
        this.content = content;
    }
}
