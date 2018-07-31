package com.timeline.vpn.web.common.response;

import java.io.IOException;

import com.alibaba.fastjson.parser.DefaultJSONParser;
import com.alibaba.fastjson.parser.deserializer.ObjectDeserializer;
import com.alibaba.fastjson.serializer.JSONSerializer;
import com.alibaba.fastjson.serializer.ObjectSerializer;
import com.alibaba.fastjson.serializer.SerializeWriter;

import springfox.documentation.spring.web.json.Json;

public class SwaggerJsonSerializer implements ObjectSerializer, ObjectDeserializer {

    public static final SwaggerJsonSerializer instance = new SwaggerJsonSerializer();

    @Override
    public int getFastMatchToken() {
        return 0;
    }

    @Override
    public <T> T deserialze(DefaultJSONParser parser, java.lang.reflect.Type type,
            Object fieldName) {
        return null;
    }

    @Override
    public void write(JSONSerializer serializer, Object object, Object fieldName,
            java.lang.reflect.Type fieldType, int features) throws IOException {
        SerializeWriter out = serializer.getWriter();
        Json json = (Json) object;
        out.write(json.value());

    }
}
