IE设置用户访问固定的网站方法
我们可以通过使用PAC脚本去设定哪些网站需要block直接访问， Demo 如下，主要是允许浏览器访问域名为microsoft和bing的网站，其余的均不可访问：

function isBlockedHost(host)
{
  if( dnsDomainIs(host, "microsoft.com") ||
      dnsDomainIs(host, "bing.com") )
    return false;
  return true;
}

function isBlockedURL(url, host)
{
  if( dnsDomainIs(host, "microsoft.com")||dnsDomainIs(host, "bing.com") ) {
    if ( shExpMatch(url, "*microsoft.com*") ||
         shExpMatch(url, "*bing.com*") )
      return false;
  }
  return true;
}

function FindProxyForURL(url,host)
{
                var direct      = "DIRECT";
                var stopProxy="PROXY http // 127.0.0.1:8080";           
               if (!isBlockedHost(host) ||!isBlockedURL(url, host))
      return direct;
    else
      return stopProxy;
}


设置方法如下:

1.将上述code 复制到文本文件中，并将文件后缀修改为.pac
2.将该文件放置在内部的Server上，并在IIS中将该文件类型(application/x-ns-proxy-autoconfig)加入到MIME type
3. 在域控中通过gpmc.msc打开组策略管理平台
4.导向User Configuration / Preferences / Windows Settings 
5. 创建新的注册项
 
6.将其中的值设置如下：
                Hive: HKEY_CURRENT_USER
                Key Path: Software\Microsoft\Windows\CurrentVersion\Internet Settings
                Value name: AutoConfigURL
                Value Type: REG_SZ
                Value data: http://localhost/proxy.pac(修改为您部署的位置)


 


您也可以参考这篇blog查看其他方式（https://blogs.msdn.microsoft.com/askie/2015/07/17/how-can-i-configure-proxy-autoconfigurl-setting-using-group-policy-preference-gpp/ ）。
