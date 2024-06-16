package vpn.web.controller;

import com.timeline.vpn.service.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;

public class BaseController {
    @Autowired
    public HostService hostService;
    @Autowired
    public UserService userService;
    @Autowired
    public DataService dataService;
    @Autowired
    public DataImgService dataImgService;
    @Autowired
    public DataTextService dataTextService;
    @Autowired
    public DataSoundService dataSoundService;
    @Autowired
    public DataVideoService dataVideoService;
    @Autowired
    public ChatService chatService;
    protected static final Logger LOGGER = LoggerFactory.getLogger(BaseController.class);
}
