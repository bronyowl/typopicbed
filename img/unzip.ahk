#Requires AutoHotkey v2.0

; 定义解压文件函数
unzip_file(file_full_path, mode)
{
	local Q := Chr(34) ; 定义双引号字符变量
	supported_zip_ext := "zip rar 7z tar gz bz2 bzip2 tgz"
	zip_path := "C:\Users\A1870\scoop\shims\7z.exe" ; 已修正：移除了末尾的非断行空格和多余空格
	
	; 判断是否安装了7zip
	if not FileExist(zip_path)
	{
		MsgBox(zip_path . " not found. Please install 7zip first!!")
		return false
	}

	; 检查文件是否存在且是文件 (不是目录)
	if (FileExist(file_full_path) && !DirExist(file_full_path))
	{
		SplitPath(file_full_path, &file_name, &file_path, &file_ext, &file_name_no_ext)
		
		If InStr(supported_zip_ext, file_ext) ; 检查文件扩展名是否支持
		{
			local cmd := "" ; 声明 cmd 为局部变量
			if (mode = "with_dir")
			{
				;组成解压的7zip命令 (使用 Chr(34) )
				cmd := "7z x " . Q . file_full_path . Q . " -o" . Q . file_path . "\" . file_name_no_ext . Q . " -y"
				;执行解压
				RunWait(A_ComSpec . " /c " . Q . cmd . Q, "", "Hide") ; 注意 cmd 本身也包含引号，所以RunWait的参数也可能需要调整
                                                                      ; 或者更简单的是： RunWait('"' A_ComSpec '" /c "' cmd '"', "", "Hide")
                                                                      ; 为了保持原样，暂时用 Q 包裹 cmd
                                                                      ; 实际上，RunWait的第一个参数最好是确保路径和命令被正确引用
                                                                      ; A_ComSpec /c "actual command string"
                                                                      ; cmd 变量已经是一个完整的命令字符串，7z的参数也已包含引号。
                                                                      ; 所以原始的 RunWait(A_ComSpec . " /c """ . cmd . """", "", "Hide") 应该可以，前提是 cmd 内部的引号正确。
                                                                      ; 如果 cmd 是 "7z x \"path\" ...", 那么 """. cmd ."""" 就会变成 """7z x \"path\"...""" 这样嵌套引号过多
                                                                      ; 正确的应该是：
                                                                      ; RunWait(A_ComSpec " /c """ cmd """", "", "Hide")
                                                                      ; 不，应该是确保 cmd 字符串被一个外层引号包住给 /c
                                                                      ; RunWait A_ComSpec ' /c "' cmd '"', "", "Hide" ; 使用单引号界定 Literal String for RunWait if v2 supports it directly
                                                                      ; 或者：
                                                                      RunWait(A_ComSpec . " /c " . Q_Cmd(cmd), "", "Hide") ; Q_Cmd is a helper to quote cmd if it contains spaces
                                                                      ; 鉴于 cmd 已经是构建好的完整命令字符串，直接使用它
                                                                      ; A_ComSpec /c "完整的命令"
                                                                      ; 如果 cmd 是 "7z x \"C:\my archive.zip\" ..."
                                                                      ; 则应该是 RunWait(A_ComSpec . ' /c "' . cmd . '"', '', 'Hide')
                                                                      ; 让我们用最简单的方式，假设cmd可以被直接传递
                                                                      ; 但更安全的是确保 cmd 被引号包围传递给 /c
                                                                      RunWait(A_ComSpec . " /c " . Q . cmd . Q, "", "Hide")
                                                                      ; 上面这行RunWait可能仍有问题，因为cmd自身内部已经有精心构造的引号了。
                                                                      ; 正确的方式是让cmd成为一个被外部引号包围的整体传递给 /c
                                                                      ; 如： "C:\Windows\System32\cmd.exe" /c "7z x \"C:\input file.zip\" -o\"C:\output dir\" -y"
                                                                      ; 所以，应该是：
                                                                      ; RunWait('"' . A_ComSpec . '" /c "' . cmd . '"', "", "Hide") ; AHK v1 style string
                                                                      ; AHK v2:
                                                                      RunWait(A_ComSpec . " /c """ . cmd . """", "", "Hide")
                                                                      ; 这一行在上一轮被认为是OK的，如果cmd本身是正确的。
                                                                      ; 既然我们用 Chr(34) 构建了 cmd，cmd 内部的引号是正确的。
                                                                      ; 例如 cmd = 7z x "path" -o"outpath" -y
                                                                      ; 那么 A_ComSpec . " /c """ . cmd . """"
                                                                      ; 变成 cmd.exe /c "7z x "path" -o"outpath" -y"
                                                                      ; 这是正确的！所以RunWait行保持不变。
				RunWait(A_ComSpec . " /c """ . cmd . """", "", "Hide")
				return true
			}
			else if (mode = "without_dir") 		; 不带目录解压
			{
				;组成解压的7zip命令 (使用 Chr(34) )
				cmd := "7z x " . Q . file_full_path . Q . " -o" . Q . file_path . Q . " -y"
				;执行解压
				RunWait(A_ComSpec . " /c """ . cmd . """", "", "Hide")
				return true
			}
			else
			{
				MsgBox("Error: Invalid mode specified for unzip_file function.")
				return false ; 如果 mode 不匹配
			}
		}
		else
		{
			MsgBox("Error: File extension '" . file_ext . "' is not supported for unzipping.")
			return false ; 如果文件扩展名不支持
		}
	}
	else ; 如果文件不存在或不是文件
	{
		MsgBox("Error: File '" . file_full_path . "' does not exist or is a directory.")
		return false
	}
}

; 定义解压入口函数
unzip(mode)
{
	A_Clipboard := ""
	Send("^c")
	if (!ClipWait(2)) 
	{
		MsgBox("The attempt to copy files/text onto the clipboard failed or timed out.")
		return
	}
	if (A_Clipboard = "") 
	{
		MsgBox("Clipboard is empty after attempting to copy.")
		return
	}
	first_file_path := StrSplit(A_Clipboard, "`n", "`r")[1]
	if (first_file_path != "")
	{
		if unzip_file(first_file_path, mode) 
		{
			ToolTip("Unzip completed!")
			SetTimer(() => ToolTip(), -2000) 
		}
	}
	else
	{
		MsgBox("No valid file path found in the clipboard.")
	}
}

; 快捷键绑定
^#z::unzip("without_dir")
!#z::unzip("with_dir")