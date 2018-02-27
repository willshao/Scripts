using System;
using System.Collections;
using System.DirectoryServices;
using System.Management;
namespace PCF2
{
    class Program
    {

        #region 需要配置三个变量
        static string ADPath { get { return "LDAP://mayday.lab/DC=mayday,DC=lab"; } }
        static string DomainName { get { return "mayday"; } }
        static bool EnableHexNumber { get { return true; } }
        #endregion 需要配置三个变量

        [STAThread]
        static void Main(string[] args)
        {
            System.Security.Principal.WindowsIdentity identity = System.Security.Principal.WindowsIdentity.GetCurrent();
            System.Security.Principal.WindowsPrincipal principal = new System.Security.Principal.WindowsPrincipal(identity);
            if (principal.IsInRole(System.Security.Principal.WindowsBuiltInRole.Administrator))
            {
                //如果是管理员，则直接运行
                DoWork(args);
                return;
            }

            System.Diagnostics.ProcessStartInfo startInfo = new System.Diagnostics.ProcessStartInfo();
            startInfo.UseShellExecute = true;
            startInfo.WorkingDirectory = Environment.CurrentDirectory;
            startInfo.FileName = System.Diagnostics.Process.GetCurrentProcess().MainModule.FileName;
            //设置启动动作,确保以管理员身份运行
            startInfo.Verb = "runas";
            try
            {
                System.Diagnostics.Process.Start(startInfo);
            }
            catch { }
            return;
        }

        /// <summary>
        /// 核心处理
        /// </summary>
        /// <param name="args">参数顺便带进来备用</param>
        static void DoWork(string[] args)
        {
            
            if (Environment.UserDomainName.ToLower() != DomainName)
                return;//当前登录的不是域账户
            string oriUserName = Environment.UserName.ToLower();
            Console.WriteLine("Environment.UserDomainName " + oriUserName);
            string fmtUserName = FormatUserName(oriUserName);
            string srcPCName = Environment.MachineName.ToLower();
            if (CheckPCName(fmtUserName, srcPCName, EnableHexNumber))//符合规范就结束
                return;

            string tgtPCName = FindName(fmtUserName, EnableHexNumber);
            Console.WriteLine("tgtPCName " + tgtPCName);
            if (tgtPCName == null)//出错了
                return;//TODO
            if (tgtPCName == string.Empty)//编号超出范围了
                return;//TODO
            F2(tgtPCName);
        }

        /// <summary>
        /// 重命名计算机
        /// </summary>
        /// <param name="tgtPCName">新的计算机名</param>
        static void F2(string tgtPCName)
        {
            ManagementScope scope = new ManagementScope(@"\\localhost\ROOT\cimv2");

            ObjectQuery query = new ObjectQuery("Select * from Win32_ComputerSystem");

            using (ManagementObjectSearcher searcher = new ManagementObjectSearcher(scope, query))
            {
                ManagementObjectCollection results = searcher.Get();
                IEnumerator enumerator = results.GetEnumerator();
                enumerator.MoveNext();
                ManagementObject result = (ManagementObject)enumerator.Current;
              
                ManagementBaseObject inputArgs = result.GetMethodParameters("Rename");
                inputArgs["Name"] = tgtPCName;
                ManagementBaseObject outParams = result.InvokeMethod("Rename", inputArgs, null);
            }
        }
        /// <summary>
        /// 根据修整后的用户名查询下一个可用计算机名
        /// </summary>
        /// <param name="fmtUserName">修整后的用户名</param>
        /// <param name="EnableHexNumber">是否启用十六进制做PC编号</param>
        /// <returns>下一个可用计算机名</returns>
        private static string FindName(string fmtUserName, bool EnableHexNumber)
        {
            using (DirectoryEntry Guardian = new DirectoryEntry(ADPath))
            {
                try
                {
                    Guid guid = Guardian.Guid;
                    using (DirectorySearcher seacher = new DirectorySearcher(Guardian))
                    {
                        seacher.Filter = "(&(objectCategory=computer)(name=C" + fmtUserName + "*))";
                        SearchResultCollection results = seacher.FindAll();
                        int crtIndex = -1;
                        foreach (SearchResult result in results)
                        {
                            using (DirectoryEntry entry = result.GetDirectoryEntry())
                            {
                                string no = entry.Name.Substring(entry.Name.Length - 2, 2);
                                int index = Convert.ToInt32(no, EnableHexNumber ? 16 : 10);
                                crtIndex = Math.Max(index, crtIndex);
                            }
                        }
                        crtIndex++;
                        if (EnableHexNumber && crtIndex == 256 || !EnableHexNumber && crtIndex == 100)//超出了
                            return string.Empty;
                        string strRet = EnableHexNumber ? string.Format("{0:X}", crtIndex) : crtIndex.ToString();
                        strRet = strRet.Length == 1 ? string.Format("0{0}", strRet) : strRet;
                        return string.Format("C{0}{1}", fmtUserName, strRet.ToUpper());
                    }
                }
                catch
                {
                    return null;
                }

            }
        }

        /// <summary>
        /// 判断当前计算机名是否合规
        /// </summary>
        /// <param name="fmtUserName">修整后的用户名</param>
        /// <param name="srcPCName">当前计算机名</param>
        /// <param name="EnableHexNumber">是否启用十六进制编号</param>
        /// <returns>合规/不合规</returns>
        static bool CheckPCName(string fmtUserName, string srcPCName, bool EnableHexNumber)
        {
            //STEP1：长度不够4位肯定不合规
            if (srcPCName.Length < 4)
                return false;

            //STEP2：判断左半部分合规
            if (!srcPCName.StartsWith("c" + fmtUserName))
                return false;

            //STEP3：判断右半部分（即后两位）合规
            string no = srcPCName.Substring(srcPCName.Length - 2, 2);
            try
            {
                Convert.ToInt32(no, EnableHexNumber ? 16 : 10);
                return true;
            }
            catch
            {
                return false;
            }
        }

        /// <summary>
        /// 如果用户名长度超过12，只保留前12位，作为修整后的用户名；否则不做调整。
        /// </summary>
        /// <param name="username">用户名</param>
        /// <returns>修整后的用户名</returns>
        static string FormatUserName(string username)
        {
            if (username.Length > 12)
                return username.Substring(0, 12);
            return username;
        }
    }
}
