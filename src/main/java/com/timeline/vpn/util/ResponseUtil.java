package com.timeline.vpn.util;

import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.http.HttpServletResponse;

/**
 * @author gqli
 */
public class ResponseUtil {
    public static void writejsonResponse(HttpServletResponse resp, String jsonResp)
            throws IOException {
        resp.setContentType("application/json;charset=utf-8");
        writeResponse(resp, jsonResp);
    }

    public static void writeResponse(HttpServletResponse resp, String data) throws IOException {
        resp.setCharacterEncoding("utf-8");
        resp.setStatus(200);
        PrintWriter pw = resp.getWriter();
        pw.write(data);
        pw.close();
    }
}
