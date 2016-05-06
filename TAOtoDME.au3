#AutoIt3Wrapper_icon=wrench.ico

;;;;;;;;;;;;;;;;;;;;


#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <ProgressConstants.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <Array.au3>
#include <file.au3>


;;;;;;;;;;;;;;;;;;;;


global $dirpath = ""																							; default directory path
global $zip = "C:\Program Files\7-Zip\7z.exe"																	; 7-zip executable path
global $code[15] = ["00","00","00","00","00","00","00","00","00","00","00","00","00","00","00"]					; code array
global $yesno[15] = ["No","No","No","No","No","No","No","No","No","No","No","No","No","No","No"]				; label array
global $filearray																								; xml array
global $check = 0																								; check code
global $validation = 0																							; default validation

;;;;;;;;;;;;;;;;;;;;


$winfix = GUICreate("TAO to DME 1.2", 340, 103, -1, -1,$WS_CAPTION+$WS_POPUP+$WS_SYSMENU)
$stop = GUICtrlCreateButton("Konec", 256, 72, 75, 21)
$start = GUICtrlCreateButton("Start", 176, 72, 75, 21)
$find = GUICtrlCreateButton("Procházet", 256, 8, 75, 21)
$path = GUICtrlCreateInput("", 8, 8, 241, 21)
$progress = GUICtrlCreateProgress(8, 43, 323, 16)
$label = GUICtrlCreateLabel("", 10, 77, 157, 17)

GUISetState(@SW_SHOW,$winfix)

while 1
	$msg = GUIGetMsg()
	if $msg = $GUI_EVENT_CLOSE or $msg = $stop then exitloop
	if $msg = $find Then
		visible(0)
		$dirpath = FileSelectFolder("Procházet","")
		GUICtrlSetData($path,$dirpath)
		visible(1)
	endif
	if $msg = $start then
		visible(0)
		;clear progress
		GUICtrlSetData($progress, 0)
		;test directory
		$dir = GUICtrlRead($path)
		;fix the trailing slash
		if $dir <> "" and StringRight($dir,1) <> "\" then $dir &= "\"
		;control
		if $dir = "" or not FileExists($dir) then
			GUICtrlSetData($label,"Neplatná cesta !")
		elseif not FileExists($dir & "*.zip") Then
			GUIctrlSetData($label,"Adresáø neobsahuje zip soubory !")
		elseif not FileExists($zip) Then
			GUIctrlSetData($label,"Nelze nalézt 7-Zip !")
		else
			;get file array
			$ziparray = _FileListToArray($dir,"*.zip")
			;start modification
				for $a = 1 to UBound($ziparray) - 1
					;clear code array
					global $code[15] = ["00","00","00","00","00","00","00","00","00","00","00","00","00","00","00"]
					;clear code array
					global $yesno[15] = ["No","No","No","No","No","No","No","No","No","No","No","No","No","No","No"]
					;clear control variable
					$control = 0
					;clear check variable
					$check = 0
					;display file
					GUIctrlSetData($label,$ziparray[$a])
					;get persid
					$pidarray  = StringSplit($ziparray[$a],".",2)
					;unzip Var.xml
					RunWait('"' & $zip & '"' & " x " & '"' & $ziparray[$a] & '"' & " " & '"' & $pidarray[0] & "-Var.xml" & '"', $dir, @SW_HIDE)
					;check file if we are done already
					$file = FileOpen($dir & $pidarray[0] & "-Var.xml", 0)
						while 1
							;read line by line
							$line = FileReadLine($file)
							; If end of file, exit the loop.
							if(@error = -1 or $line = "") then ExitLoop
							;else populate array
							if(StringInStr($line, '"B_Q00CZ01"')) then
								$check = 1
							endif
						wend
						;close file
						FileClose($file)
						;find validation
						$file = FileOpen($dir & $pidarray[0] & "-Var.xml", 0)
						while 1
							;read line by line
							$line = FileReadLine($file)
							; If end of file, exit the loop.
							if(@error = -1 or $line = "") then ExitLoop
							;else populate array
							if(StringInStr($line, '"B_Q00CZX"')) then
								$varray = StringRegExp($line, 'isValid=\"(\d{1})\"', 1)
								$validation = $varray[0]
							endif
						wend
						;close file
						FileClose($file)
					;START
					if $check = 0  then
						;serch for B_Q00CZX to array
						$file = FileOpen($dir & $pidarray[0] & "-Var.xml", 0)
						while 1
							;read line by line
							$line = FileReadLine($file)
							; If end of file, exit the loop.
							if(@error = -1 or $line = "") then ExitLoop
							;else populate array
							if(StringInStr($line, '"B_Q00CZX"')) then
								$next = FileReadLine($file)
								;check for resource
								if StringRegExp($next, 'resource', 0) = 1 then
									$narray = StringRegExp($next, 'code=\"(\d{2})\"', 1)
									$code[int($narray[0])] = "01"
									$yesno[int($narray[0])] = "Yes"
								endif
							endif
						wend
						;close socket
						FileClose($file)
						;write substitution template and replace
						$file = FileOpen($dir & $pidarray[0] & "-Var.xml", 0)
						;open as UTF-8 for write
						$tmp = FileOpen($dir & $pidarray[0] & "-Var.xml.tmp", 130)
						while 1
							$line = FileReadLine($file)
							; If end of file, exit the loop.
							if(@error = -1 or $line = "") then ExitLoop
							;append template
							if StringInStr($line, '"B_R01a"') then
										FileWrite($tmp,$line & @CRLF)
										filewrite($tmp,"<property label=""B_Q00CZ01"" code=""B_Q00CZ01"" isValid=""" & $validation & """>" & @CRLF)
										filewrite($tmp,"<resource label=""" & $yesno[1] & """ code=""" & $code[1] & """ />" & @CRLF)
										filewrite($tmp,"</property>" & @CRLF)
										filewrite($tmp,"<property label=""B_Q00CZ02"" code=""B_Q00CZ02"" isValid=""" & $validation & """>" & @CRLF)
										filewrite($tmp,"<resource label=""" & $yesno[2] & """ code=""" & $code[2] & """ />" & @CRLF)
										filewrite($tmp,"</property>" & @CRLF)
										filewrite($tmp,"<property label=""B_Q00CZ03"" code=""B_Q00CZ03"" isValid=""" & $validation & """>" & @CRLF)
										filewrite($tmp,"<resource label=""" & $yesno[3] & """ code=""" & $code[3] & """ />" & @CRLF)
										filewrite($tmp,"</property>" & @CRLF)
										filewrite($tmp,"<property label=""B_Q00CZ04"" code=""B_Q00CZ04"" isValid=""" & $validation & """>" & @CRLF)
										filewrite($tmp,"<resource label=""" & $yesno[4] & """ code=""" & $code[4] & """ />" & @CRLF)
										filewrite($tmp,"</property>" & @CRLF)
										filewrite($tmp,"<property label=""B_Q00CZ05"" code=""B_Q00CZ05"" isValid=""" & $validation & """>" & @CRLF)
										filewrite($tmp,"<resource label=""" & $yesno[5] & """ code=""" & $code[5] & """ />" & @CRLF)
										filewrite($tmp,"</property>" & @CRLF)
										filewrite($tmp,"<property label=""B_Q00CZ06"" code=""B_Q00CZ06"" isValid=""" & $validation & """>" & @CRLF)
										filewrite($tmp,"<resource label=""" & $yesno[6] & """ code=""" & $code[6] & """ />" & @CRLF)
										filewrite($tmp,"</property>" & @CRLF)
										filewrite($tmp,"<property label=""B_Q00CZ07"" code=""B_Q00CZ07"" isValid=""" & $validation & """>" & @CRLF)
										filewrite($tmp,"<resource label=""" & $yesno[7] & """ code=""" & $code[7] & """ />" & @CRLF)
										filewrite($tmp,"</property>" & @CRLF)
										filewrite($tmp,"<property label=""B_Q00CZ08"" code=""B_Q00CZ08"" isValid=""" & $validation & """>" & @CRLF)
										filewrite($tmp,"<resource label=""" & $yesno[8] & """ code=""" & $code[8] & """ />" & @CRLF)
										filewrite($tmp,"</property>" & @CRLF)
										filewrite($tmp,"<property label=""B_Q00CZ09"" code=""B_Q00CZ09"" isValid=""" & $validation & """>" & @CRLF)
										filewrite($tmp,"<resource label=""" & $yesno[9] & """ code=""" & $code[9] & """ />" & @CRLF)
										filewrite($tmp,"</property>" & @CRLF)
										filewrite($tmp,"<property label=""B_Q00CZ10"" code=""B_Q00CZ10"" isValid=""" & $validation & """>" & @CRLF)
										filewrite($tmp,"<resource label=""" & $yesno[10] & """ code=""" & $code[10] & """ />" & @CRLF)
										filewrite($tmp,"</property>" & @CRLF)
										filewrite($tmp,"<property label=""B_Q00CZ11"" code=""B_Q00CZ11"" isValid=""" & $validation & """>" & @CRLF)
										filewrite($tmp,"<resource label=""" & $yesno[11] & """ code=""" & $code[11] & """ />" & @CRLF)
										filewrite($tmp,"</property>" & @CRLF)
										filewrite($tmp,"<property label=""B_Q00CZ12"" code=""B_Q00CZ12"" isValid=""" & $validation & """>" & @CRLF)
										filewrite($tmp,"<resource label=""" & $yesno[12] & """ code=""" & $code[12] & """ />" & @CRLF)
										filewrite($tmp,"</property>" & @CRLF)
										filewrite($tmp,"<property label=""B_Q00CZ13"" code=""B_Q00CZ13"" isValid=""" & $validation & """>" & @CRLF)
										filewrite($tmp,"<resource label=""" & $yesno[13] & """ code=""" & $code[13] & """ />" & @CRLF)
										filewrite($tmp,"</property>" & @CRLF)
										filewrite($tmp,"<property label=""B_Q00CZ14"" code=""B_Q00CZ14"" isValid=""" & $validation & """>" & @CRLF)
										filewrite($tmp,"<resource label=""" & $yesno[14] & """ code=""" & $code[14] & """ />" & @CRLF)
										filewrite($tmp,"</property>" & @CRLF)
;									endif
							;remove the old tags
							elseif StringInStr($line, '"B_Q00CZX"') then
								;get the next tag
								$next = FileReadLine($file)
								if	StringRegExp($next, 'resource', 0) = 1 then
;									;if it's resource tag remove the rest
									$nexttoo = FileReadLine($file)
								else
									;write what we get
									filewrite($tmp,$next & @CRLF)
								endif
							else
								filewrite($tmp,$line & @CRLF)
							endif
						wend
						;close socket
						FileClose($file)
						FileClose($tmp)
						;move template to original and overwrite
						FileMove($dir & $pidarray[0] & "-Var.xml.tmp",$dir & $pidarray[0] & "-Var.xml",1)
					endif
					;zip the file back
					RunWait('"' & $zip & '"' & " a " & '"' & $ziparray[$a] & '"' & " " & '"' & $pidarray[0] & "-Var.xml" & '"' , $dir, @SW_HIDE)
					;clean after self
					FileDelete($dir & $pidarray[0] & "-Var.xml")
					;update progress bar
					GUICtrlSetData($progress, round($a / (UBound($ziparray) - 1) * 100))
				next
				;set finished
				GUIctrlSetData($label,"Hotovo !")
		endif
		visible(1)
	endif
wend


;;;;;;;;;;;;;;;;;;;;


func visible($state)
	if $state = 1 then $setstate = $GUI_ENABLE
	If $state = 0 then $setstate = $GUI_DISABLE
	GUICtrlSetState($stop, $setstate)
	GUICtrlSetState($start, $setstate)
	GUICtrlSetState($find, $setstate)
EndFunc