package com.timeline.vpn.util;


import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.HashMap;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.Version;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.JavaType;
import com.fasterxml.jackson.databind.JsonSerializer;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.module.SimpleModule;

/**
 * JSON工具类
 * 
 */

public class JsonUtil {
  private static final Logger LOGGER = LoggerFactory.getLogger(JsonUtil.class);
  private static ObjectMapper mapper = new ObjectMapper();

  static {

    mapper.setSerializationInclusion(JsonInclude.Include.NON_NULL);
    mapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
    mapper.configure(JsonParser.Feature.ALLOW_SINGLE_QUOTES, true);
    mapper.configure(JsonParser.Feature.ALLOW_UNQUOTED_FIELD_NAMES, true);
    mapper.configure(SerializationFeature.FAIL_ON_EMPTY_BEANS, false);
    mapper.configure(SerializationFeature.WRITE_EMPTY_JSON_ARRAYS, false);
    @SuppressWarnings("deprecation")
    SimpleModule simpleModule = new SimpleModule("SimpleModule", new Version(1, 0, 0, null));
    simpleModule.addSerializer(BigDecimal.class, new BigDecimalSerializer(2));
    simpleModule.addSerializer(Long.class, new LongSerializer());
    mapper.registerModule(simpleModule);
  }

  public static <T> JavaType getListType(Class<T> clz) {
    JavaType javaType = mapper.getTypeFactory().constructParametrizedType(List.class, List.class, clz,null);
    return javaType;
  }

  public static <T> JavaType getMapType(Class<T> clz) {
    JavaType javaType =
        mapper.getTypeFactory().constructParametrizedType(HashMap.class, String.class, clz);
    return javaType;
  }

  public static <T> T readValue(String info, Class<T> t) {
    try {
      return getMapper().readValue(info, t);
    } catch (Exception e) {
      LOGGER.error("json util error:" + info + "->" + t.getName());
      return null;
    }
  }

  public static <T> T readValue(String info, JavaType type) {
    try {
      return getMapper().readValue(info, type);
    } catch (Exception e) {
      LOGGER.error("json util error:" + info + "->" + type.toString());
      return null;
    }
  }

  public static String writeValueAsString(Object o) {
    try {
      return getMapper().writeValueAsString(o);
    } catch (Exception e) {
      LOGGER.error("json util error:" + o);
      return null;
    }
  }

  /**
   * 获取通过的ObjectMapper，BigDecimal字段分别保留小数点后2位或4位
   * 
   * @return ObjectMapper
   */
  public static ObjectMapper getMapper() {
    return mapper;
  }

  private static class BigDecimalSerializer extends JsonSerializer<BigDecimal> {
    private int scale;

    public BigDecimalSerializer(int scale) {
      this.scale = scale;
    }

    @Override
    public void serialize(BigDecimal value, JsonGenerator jgen, SerializerProvider provider)
        throws IOException, JsonProcessingException {
      if (value != null) {
        if (value.scale() >= scale) {
          // 数值
          value = value.setScale(scale, RoundingMode.HALF_UP);
        }
        jgen.writeNumber(value);
      }
    }
  }
  private static class LongSerializer extends JsonSerializer<Long> {
    @Override
    public void serialize(Long value, JsonGenerator gen, SerializerProvider serializers)
        throws IOException, JsonProcessingException {
      if (value != null) {
        gen.writeString(String.valueOf(value));
      }
    }
  }

  public static <T> T json2GenericObject(String jsonString, TypeReference<T> tr) throws Exception {
    try {
      return getMapper().readValue(jsonString, tr);
    } catch (Exception e) {
      LOGGER.error(
          "json util readValue error,String:" + jsonString + " type:" + tr.getType().toString(), e);
      return null;
    }
  }
}
