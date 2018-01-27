package com.timeline.vpn.dao;

import java.sql.ResultSet;
import java.sql.SQLException;

import org.apache.commons.lang3.StringUtils;
import org.apache.ibatis.type.BaseTypeHandler;
import org.apache.ibatis.type.JdbcType;

/**
 * 
 * @ClassName: BlobStringTypeHandler
 * @author gqli
 * @date 2016年4月21日 上午10:45:10
 *
 */
public class ImgSourceHandler extends BaseTypeHandler<String> {
    private static final String HHH="http://imghhh.secondary.space/file/img/hhh/";
    private static final String EROTI="http://imghhh.secondary.space/file/img/eroti/";
    @Override
    public void setNonNullParameter(java.sql.PreparedStatement ps, int i, String parameter,
            JdbcType jdbcType) throws SQLException {
        ps.setString(i, parameter);

    }

    @Override
    public String getNullableResult(ResultSet rs, String columnName) throws SQLException {
        String str = rs.getString(columnName);
        return getClaszName(str);
    }

    @Override
    public String getNullableResult(ResultSet rs, int columnIndex) throws SQLException {
        String str = rs.getString(columnIndex);
        return getClaszName(str);
    }

    @Override
    public String getNullableResult(java.sql.CallableStatement cs, int columnIndex)
            throws SQLException {
        String str = cs.getString(columnIndex);
        return getClaszName(str);
    }
    private static String getClaszName(String name) {
        if(StringUtils.isEmpty(name)) {
            return name;
        }
        try {
            if(name.contains("www.singlove.com")) {
                int start = name.lastIndexOf("/");
                return HHH+name.substring(start);
            }
            if(name.contains("www.eroti-cart.com")) {
                int start = name.lastIndexOf("/");
                return EROTI+name.substring(start);
            }
        }catch(Exception e) {
            
        }
        return name;
    }

}
