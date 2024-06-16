package vpn.util;

import com.timeline.vpn.model.po.IpLocalPo;
import org.springframework.util.StringUtils;

import java.net.Inet4Address;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.util.Enumeration;

/**
 * @author gqli
 * @date 2017年4月14日 下午4:00:27
 * @version V1.0
 */
public class IpLocalUtil {
    public static final String IP_HOST="http://ip.taobao.com/service/getIpInfo.php?ip=%s";
    public static String getLocal(String ip){
        String url = String.format(IP_HOST, ip);
        String json = HttpCommonUtil.sendGet(url);
        if(!StringUtils.hasText(json)){
            return null;
        }
        IpLocalPo po = JsonUtil.readValue(json, IpLocalPo.class);
        if(po.getCode()==0){
            return po.getData().getCountry()+"-"+po.getData().getRegion();
        }
        return null;
    }
    public static String getHostIp(){
      try{
          Enumeration<NetworkInterface> allNetInterfaces = NetworkInterface.getNetworkInterfaces();
          while (allNetInterfaces.hasMoreElements()){
              NetworkInterface netInterface = (NetworkInterface) allNetInterfaces.nextElement();
              Enumeration<InetAddress> addresses = netInterface.getInetAddresses();
              while (addresses.hasMoreElements()){
                  InetAddress ip = (InetAddress) addresses.nextElement();
                  if (ip != null 
                          && ip instanceof Inet4Address
                          && !ip.isLoopbackAddress() //loopback地址即本机地址，IPv4的loopback范围是127.0.0.0 ~ 127.255.255.255
                          && ip.getHostAddress().indexOf(":")==-1){
                      return ip.getHostAddress();
                  } 
              }
          }
      }catch(Exception e){
          e.printStackTrace();
      }
      return "-";
    }
}

