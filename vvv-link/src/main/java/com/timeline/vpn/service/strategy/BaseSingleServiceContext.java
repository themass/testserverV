package vpn.service.strategy;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;

import javax.annotation.PostConstruct;
import java.util.ArrayList;
import java.util.List;

/**
 * @Description: 
 * @author gqli
 * @date 2017年5月23日 上午11:40:49
 * @version V1.0
 */
public abstract class BaseSingleServiceContext<O,T extends BaseSupportHandle<O>> {
    private static final Logger LOGGER = LoggerFactory.getLogger(BaseSingleServiceContext.class);
    @Autowired(required=false)
    private List<T> handles = new ArrayList<>();
    private T defaultHandle;
    @PostConstruct
    private void init(){
        for(T handle:handles){
            if(handle.isDefault()){
                defaultHandle = handle;
                break;
            }
        }
    }
    public T getService(O support) {
        for (T handle : handles) {
            if(handle.support(support)&&!handle.isDefault()){
                LOGGER.info("获取handle ：{}",handle.getClass().getName());
                return handle;
            }
        }
        LOGGER.info("获取默认 handle： {}",defaultHandle);
        return defaultHandle;
    }
}

