方案：
1.	使用C++接口来设置shortcut的run as administrator属性
•	下载Demo.zip并解压，解压密码Microsoft
•	命令行下运行Win32Shortcut\Debug下的win32shortcut.exe，传入参数为希望设置run as administrator的shortcut的具体路径
 
                主要相关代码如下
                       // Only set SLDF_RUNAS_USER if it's not set, otherwise
       // SetFlags returns an error.
       if ((SLDF_RUNAS_USER & dwFlags) != SLDF_RUNAS_USER) {
              result = pdl->SetFlags(SLDF_RUNAS_USER | dwFlags);
              if (result != S_OK) {
                     pdl->Release();
                     file->Release();
                     link->Release();
                     CoUninitialize();
                     return -6;
              }
       }

2.	使用C#创建shortcut并设置run as administrator
路径在ConsoleApp2\ConsoleApp2\bin\Debug\ConsoleApp2.exe，需要在代码里设置要新创建的shortcut的路径，目标路径等参数
    class Program
    {
        static void Main(string[] args)
        {
            CreateShortcut("shortcutcmd", @"d:\temp", @"c:\windows\system32\cmd.exe");
            Console.WriteLine("Complete");
            Console.ReadLine();
        }

        public static void CreateShortcut(string shortcutName, string shortcutPath, string targetFileLocation)
        {
            string shortcutLocation = System.IO.Path.Combine(shortcutPath, shortcutName + ".lnk");
            WshShell shell = new WshShell();
            IWshShortcut shortcut = (IWshShortcut)shell.CreateShortcut(shortcutLocation);

            shortcut.Description = "My shortcut description";   // The description of the shortcut
            shortcut.IconLocation = @"c:\myicon.ico";           // The icon of the shortcut
            shortcut.TargetPath = targetFileLocation;                 // The path of the file that will launch when the shortcut is run
            shortcut.Save();                                    // Save the shortcut


            //Set run as administrator for shortcut
            using (FileStream fs = new FileStream(shortcutLocation, FileMode.Open, FileAccess.ReadWrite))
            {
                fs.Seek(21, SeekOrigin.Begin);
                fs.WriteByte(0x22);
            }

        }

    }
