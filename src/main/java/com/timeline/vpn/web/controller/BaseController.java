package com.timeline.vpn.web.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;

import com.timeline.vpn.service.DataService;
import com.timeline.vpn.service.HostService;
import com.timeline.vpn.service.UserService;

public class BaseController {
    @Autowired
    public HostService hostService;
    @Autowired
    public UserService userService;
    @Autowired
    public DataService dataService;
    protected static final Logger LOGGER = LoggerFactory.getLogger(BaseController.class);
}
