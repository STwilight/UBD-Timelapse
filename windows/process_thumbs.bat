@echo off
setlocal enabledelayedexpansion

	rem Defining hard-coded options
	set tools_folder=tools
	set scr_dst_folder=tmp
	set vid_dst_folder=video
	set img_ext=jpg
	set vid_ext=mp4
	set num_cnt=6
	set "base=1"
	
	rem Defining default options values
	set def_copy_flag=0
	set def_res_fps=30
	set def_res_dur=60
	set def_vid_res=1920x1080
	set def_vid_quality=23

	rem Defining some internal variables
	set dd=%date:~0,2%
	set mm=%date:~3,2%
	set yyyy=%date:~6,4%

	rem Fetching variable options values from arguments
	rem Date from (in format YYYY-MM-DD)
	set date_from=%1
	rem Date to (in format YYYY-MM-DD)
	set date_to=%2
	rem Source folder (networking (starting with '\\') or local directory (starting with drive letter 'C:\'))
	set src_folder=%3
	rem Username (for networking directory mounting)
	set username=%4
	rem Copy flag (if set to 1, than files will be copied to the temporary directory, 0 by default, see 'def_copy_flag' option value)
	set copy_flag=%5
	rem FPS of the result video (30 by default, see 'def_res_fps' option value)
	set res_fps=%6
	rem Duration in seconds of the result video (60 by default, see 'def_res_dur' option value)
	set res_dur=%7
	rem Output video resolution (1920x1080 px by default (native), half-size (960x540 px) is also acceptable)
	set vid_res=%8
	rem Output video quality (23 is fine and set by default (see 'def_vid_quality' option value), numbers from 0 to 51 is also acceptable (larger number mean poorer quality))
	set vid_quality=%9

	rem Checking variable options values
	set check_result=false
	if not defined date_from set check_result=true
	if not defined date_to set check_result=true
	if not defined src_folder set check_result=true
	if not defined username set check_result=true
	if not defined copy_flag set copy_flag=%def_copy_flag%
	if not defined res_fps set res_fps=%def_res_fps%
	if not defined res_dur set res_dur=%def_res_dur%
	if not defined vid_res set vid_res=%def_vid_res%
	if not defined vid_quality set vid_quality=%def_vid_quality%
	if %check_result%==true (
		echo.
		echo ERROR: One or more of parameters does not set properly.
		goto finish
	)

	rem Checking of an existence of tools directory
	if not exist %tools_folder% (
		echo.
		echo ERROR: Tools folder does not exist.
		goto finish
	)

	rem Checking of an existence of ffmpeg tool
	if not exist %tools_folder%\ffmpeg.exe (
		echo.
		echo ERROR: ffmpeg tool is absent.
		goto finish
	)

	rem Checking of an existence of crc32 tool
	if not exist %tools_folder%\crc32.exe (
		echo.
		echo ERROR: crc32 tool is absent.
		goto finish
	)

	rem Getting execution directory path and generating full patches for working directories
	set root_dir=%~dp0
	set scr_dst_folder=%root_dir%%scr_dst_folder%
	set scr_filelist=%scr_dst_folder%\src_files.list
	set vid_dst_folder=%root_dir%%vid_dst_folder%
	set vid_file_name=%yyyy%-%mm%-%dd%_timelapse.%vid_ext%
	set vid_file_path=%vid_dst_folder%\%vid_file_name%

	rem Checking if source folder is networking directory
	set /a net_dir=0
	if %src_folder:~0,2% equ \\ (
		set /a net_dir=1
	)

	rem Displaying options
	echo.
	if %net_dir%==1 (
		echo Network folder selected as source
	) else (
		echo Local folder selected as source
	)
	if %copy_flag%==1 (
		echo Files will be copied to temporary folder
	) else (
		echo Files will be read directly
	)
	echo.
	echo Date from: %date_from%
	echo Date to: %date_to%
	echo.
	echo Source files root folder: %src_folder%
	if %net_dir%==1 (
		echo Network share username: %username%
	)
	echo Temporary files folder: %scr_dst_folder%
	echo Image files extension: *.%img_ext%
	echo.
	echo Video files folder: %vid_dst_folder%
	echo Video files extension: *.%vid_ext%
	echo Video file resolution: %vid_res% px
	echo Video file FPS: %res_fps%
	echo Video file length: %res_dur% seconds
	echo Video file quality: %vid_quality%
	echo.

	rem Creating working directories, if they are absent
	if not exist %scr_dst_folder% mkdir %scr_dst_folder%
	if not exist %vid_dst_folder% mkdir %vid_dst_folder%

	rem Mounting networking directory with source files
	set /a net_mounted=0
	if %net_dir%==1 (
		if not exist %src_folder% (
			net use %src_folder% /user:%username% /persistent:no > nul
			set /a net_mounted=1
		)
	)

	rem Checking of an existence of mounted directory
	if not exist %src_folder% (	
		echo.
		echo ERROR: Source folder does not exist.
		goto finish
	)

	rem Fetching all available directories in the source directory
	set counter=0
	for /f "tokens=*" %%i in ('dir %src_folder% /A:D /B /O:N') do (
		set folders[!counter!]=%%i
		set /a counter+=1
	)
	set /a counter-=1

	rem Getting of an index of the first directory within specified range of dates
	set start_index=0
	for /l %%i in (0,1,%counter%) do (
		if !folders[%%i]! equ %date_from% (
			set start_index=%%i
		)
	)

	rem Getting of an index of the last directory within specified range of dates
	set end_index=0
	for /l %%i in (0,1,%counter%) do (
		if !folders[%%i]! equ %date_to% (
			set end_index=%%i
		)
	)

	rem Generating list of valid directories within specified range of dates
	set /a max_index=end_index-start_index
	for /l %%i in (0,1,%max_index%) do (
		set /a j=%%i+start_index
		call set "folders[%%i]=%%folders[!j!]%%"
	)

	rem Fetching all compatible files in the source directories list
	set counter=0
	if %copy_flag%==0 (
		copy /y nul %scr_filelist% > nul
	)
	for /l %%i in (0,1,%max_index%) do (
		call set "folders[%%i]=%src_folder%\%%folders[%%i]%%"
		for /f "tokens=*" %%j in ('dir !folders[%%i]!\*.%img_ext% /A /B /O:N') do (
			rem Checking files sizes for avoiding null-sized files
			for %%A in (!folders[%%i]!\%%j) do set file_size=%%~zA
			if not !file_size! equ 0 (
				set src_files[!counter!]=!folders[%%i]!\%%j
				if %copy_flag%==0 echo file '!folders[%%i]!\%%j' >> %scr_filelist%
				set /a counter+=1
			) else (
				echo File '!folders[%%i]!\%%j' is null-size and will be skipped
			)
		)
	)
	set /a counter-=1

	rem Displaying directories and files quantity
	set /a dir_count=%max_index%+1
	set /a files_count=%counter%+1
	echo Selected %dir_count% directories with %files_count% files inside
	echo.

	rem Generating the base mask for temporary files naming
	for /l %%i in (1,1,%num_cnt%) do (
		set "base=!base!0"
	)

	rem Copying source files to the temporary directory in case of selected option
	if %copy_flag%==1 (
		rem Generating list of full patches for temporary files
		for /l %%i in (0,1,%counter%) do (
		   set /a "num=base+%%i"
		   set dst_files[%%i]=%scr_dst_folder%\!num:~1!.%img_ext%
		)

		rem Copying source files to the temporary directory
		copy /y nul %scr_filelist% > nul
		for /l %%i in (0,1,%counter%) do (
			call copy /y !src_files[%%i]! !dst_files[%%i]! > nul
			echo file '!dst_files[%%i]!' >> %scr_filelist%
		)	
	)

	rem Unmounting networking directory with source files
	if %net_mounted%==1 (
		if exist %src_folder% (
			net use %src_folder% /delete > nul
		)
	)

	rem Calculating FPS for source files
	set /a int=files_count/res_dur
	set /a fract=(files_count-int*res_dur)*100/res_dur
	set src_fps=%int%.%fract%
	echo Source FPS is set to: %src_fps%
	echo.

	rem Converting of thumbnails to video by ffdshow
	echo Executing ffmpeg...
	echo.
	start /b /wait %tools_folder%\ffmpeg.exe -nostats -y -r %src_fps% -f concat -safe 0 -i %scr_filelist% -s %vid_res% -vcodec libx264 -crf %vid_quality% -pix_fmt yuv420p -r %res_fps% %vid_file_path%

	rem Removing source files list from the temporary directory
	if exist %scr_filelist% (
		del /q /f %scr_filelist%
	)

	rem Calculating CRC32 hash of the file
	for /f %%i in ('%tools_folder%\crc32.exe %vid_file_path% -v') do (
		set hash=%%i
	)
	set hash=%hash:~2,8%

	rem Converting hash to lowercase
	for %%i in ("A=a", "B=b" "C=c" "D=d" "E=e" "F=f") do set hash=!hash:%%~i!

	rem Renaming file
	ren %vid_file_path% %date_from%_%date_to%_%hash%.%vid_ext%

	rem Removing source files from the temporary directory
	if %copy_flag%==1 (
		for /f "tokens=*" %%i in ('dir %scr_dst_folder%\*.%img_ext% /A /B /O:N') do (
			del /q /f %scr_dst_folder%\%%i
		)
	)

:finish
echo.
pause