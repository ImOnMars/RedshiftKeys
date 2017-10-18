#NoEnv  					; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance				; Only allows one instance of the script to run.
#Warn  						; Enable warnings to assist with detecting common errors.
SendMode Input  			; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;     REDSHIFT KEYS by ImOnMars    ;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Created so that you can manually modify screen color temperature using hotkeys on Windows
;
; To make this run automatically when your PC starts, put it (or a shortcut to it) in the Startup folder (For Windows 10: C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp)
; 
; Requirements:
; - AutoHotkey
; - Redshift
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;          CONFIG OPTIONS          ;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Redshift Settings
REDSHIFT_PATH = redshift 			; The path where redshift is, if redshift is in your path environment variable, then you can leave as is

; Options File
SAVE_OPTIONS := true				; Whether or not to save options to a file after script restart or PC reboot
OPTIONS_PATH = C:\redshiftKeysOptions.ini ; Path of where to save options if SAVE_OPTIONS is true

; Shift Values
STARTING_SHIFT = 5500 				; Shift to set when starting the script (on boot or restart) and SAVE_OPTIONS is false or the ini file isn't set
DEFAULT_SHIFT = 6500				; Default Windows color temperature when shift is disabled
MIN_SHIFT = 3500					; Minimum shift that the script will decrement to
MAX_SHIFT = 7500					; Maximum shift that the script will increment to
SHIFT_INCREMENT = 250				; Amount that the shift will increment/decrement by

; Hotkeys, see here for key combinations: https://autohotkey.com/docs/Hotkeys.htm
TOGGLE_SHIFT_HOTKEY = <#y			; Default: (Left Windows Key + y)
INCREASE_SHIFT_HOTKEY = <#[			; Default: (Left Windows Key + [)
DECREASE_SHIFT_HOTKEY = <#]			; Default: (Left Windows Key + ])

; General Options
START_ON_RUN := true				; Whether to start with shift or not when starting the script (on boot or restart) and SAVE_OPTIONS is false or the ini file isn't set
SHOW_SHIFT_GUI := true  			; Whether the current shift GUI should be shown when pressing hotkeys
SHIFT_AMOUNT_GUI_RELATIVE := false 	; Whether the current shift GUI should be relative to the DEFAULT_SHIFT (ex: if DEFAULT_SHIFT = 6500 and the current shift is 5500, it will display -1000)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;           INITIAL RUN            ;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Defaults
isEnabled := START_ON_RUN
curShift := STARTING_SHIFT

; If necessary, read or write all of the options
if (SAVE_OPTIONS)
{
	if (FileExist(OPTIONS_PATH))
	{
		readAllOptionsFromFile()
	}
	else
	{
		writeAllOptionsToFile()
	}
}

; Set the initial shift values
if (isEnabled)
{
	Run, %REDSHIFT_PATH% -O %curShift%,, Hide
	shiftAmountBox(curShift, true)
}
else
{
	Run, %REDSHIFT_PATH% -x,, Hide
}


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;         HOTKEY BINDINGS          ;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Apply the hotkeys set above to their respective actions
Hotkey, %TOGGLE_SHIFT_HOTKEY%, ToggleShift
Hotkey, %INCREASE_SHIFT_HOTKEY%, IncreaseShift
Hotkey, %DECREASE_SHIFT_HOTKEY%, DecreaseShift
return

ToggleShift:
	if (isEnabled)
	{
		Run, %REDSHIFT_PATH% -x,, Hide
		isEnabled := false
		shiftAmountBox(DEFAULT_SHIFT, true)
	}
	else
	{
		Run, %REDSHIFT_PATH% -O %curShift%,, Hide
		isEnabled := true
		shiftAmountBox(curShift, true)
	}
	writeOptionToFile("startShifted", isEnabled)
	return

IncreaseShift:
	if (isEnabled)
	{
		if ((curShift + SHIFT_INCREMENT) < MAX_SHIFT)
		{
			curShift += SHIFT_INCREMENT
		}
		else
		{
			curShift := MAX_SHIFT
		}
		Run, %REDSHIFT_PATH% -O %curShift%,, Hide
		shiftAmountBox(curShift)
		writeOptionToFile("currentShift", curShift)
	}
	return

DecreaseShift:
	if (isEnabled)
	{
		if ((curShift - SHIFT_INCREMENT) > MIN_SHIFT)
		{
			curShift -= SHIFT_INCREMENT
		}
		else
		{
			curShift := MIN_SHIFT
		}
		Run, %REDSHIFT_PATH% -O %curShift%,, Hide
		shiftAmountBox(curShift)
		writeOptionToFile("currentShift", curShift)
	}
	return


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;       INI FILE MANAGEMENT        ;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

writeOptionToFile(optionName, optionValue)
{
	global SAVE_OPTIONS
	global OPTIONS_PATH

	if (NOT SAVE_OPTIONS)
	{
		return
	}

	IniWrite, %optionValue%, %OPTIONS_PATH%, General, %optionName%
}

readOptionFromFile(optionName, ByRef optionValue)
{
	global SAVE_OPTIONS
	global OPTIONS_PATH
	
	if (NOT SAVE_OPTIONS)
	{
		return
	}
	
	IniRead, optionValue, %OPTIONS_PATH%, General, %optionName%
}

writeAllOptionsToFile()
{
	global SAVE_OPTIONS
	global curShift
	global isEnabled
	
	if (NOT SAVE_OPTIONS)
	{
		return
	}

	writeOptionToFile("currentShift", curShift)
	writeOptionToFile("startShifted", isEnabled)
}

readAllOptionsFromFile()
{
	global SAVE_OPTIONS
	global curShift
	global isEnabled

	if (NOT SAVE_OPTIONS)
	{
		return
	}

	readOptionFromFile("currentShift", curShift)
	readOptionFromFile("startShifted", isEnabled)
}


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;               GUI                ;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Shift Amount GUI
shiftAmountBox(shiftValue, enabledMessage := false)
{
	global SHOW_SHIFT_GUI
	global SHIFT_AMOUNT_GUI_RELATIVE
	global DEFAULT_SHIFT
	global isEnabled

	if (NOT SHOW_SHIFT_GUI)
	{
		return
	}

	IfWinExist, shiftAmountWindow
	{
		Gui, Destroy
	}
	
	if (SHIFT_AMOUNT_GUI_RELATIVE)
	{
		shiftValue -= DEFAULT_SHIFT
	}
	
	Gui, +ToolWindow -Caption +0x400000 +AlwaysOnTop
	Gui, Color, FFFFFF,
	Gui, Font, s12, Calibri
	Gui, Add, Text, x5 y5, Current Shift:
	Gui, Font, Bold
	Gui, Add, Text, x100 y5, %shiftValue%
	if (enabledMessage)
	{
		Gui, Font, Norm
		if (isEnabled)
		{
			Gui, Add, Text, x140 y5, (Enabled)
		}
		else
		{
			Gui, Add, Text, x140 y5, (Disabled)
		}
	}
	SysGet, screenx, 0
	SysGet, screeny, 1
	xpos:=screenx-275
	ypos:=screeny-100
	Gui, Show, NoActivate x%xpos% y%ypos% h30 w260, shiftAmountWindow
	
	SetTimer, shiftAmountClose, 2250
}
shiftAmountClose:
    SetTimer, shiftAmountClose, Off
    Gui, Destroy
	return