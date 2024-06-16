package vpn.service.job;
/**
 * @author gqli
 * @date 2016年6月17日 上午10:57:37
 * @version V1.0
 */
public abstract class ReloadJob extends AbstractJob{
    
    @Override
    public void executeInternal() throws Exception {
        reload();
    }
    public abstract void reload();
}

