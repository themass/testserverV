package vpn.web.common.annotation;

import javax.servlet.ServletRequest;

/**
 * 自定义参数解析接口，用于解析生成Controller方法的参数，与CustomArgument配合使用
 * 
 * @author gqli
 */

public interface ArgumentResolver<T> {
    public T resolve(ServletRequest webRequest, boolean required);
}
