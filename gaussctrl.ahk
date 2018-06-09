; ADHD Gauss Control

;These next 2 lines make it so the script is only active within the mechlab and match window.
;#IfWinActive, ahk_class CryENGINE
;#IfWinActive MechWarrior Online
#SingleInstance off

Menu, Tray, NoStandard ;Removes the default AHK menus on the tray icon
Menu, Tray, Add, About / Instructions, AboutGC ; Adds the "About / Bindings" menu to the tray icon
Menu, Tray, Add, Exit Gauss Control, ExitGC ; Adds the "Exit Gauss Control" menu to the tray icon
Menu, Tray, Tip, Gauss Control ; Gives the tray icon a name when the user hovers over it

; Create an instance of the library
ADHD := New ADHDLib

; Ensure running as admin
ADHD.run_as_admin()

; ============================================================================================
; CONFIG SECTION - Configure ADHD

; Authors - Edit this section to configure ADHD according to your macro.
; You should not add extra things here (except add more records to hotkey_list etc)
; Also you should generally not delete things here - set them to a different value instead

; You may need to edit these depending on game
SendMode, Event
SetKeyDelay, 0, 0

; Stuff for the About box

ADHD.config_about({name: "Gauss Control", version: "2.4", author: "ThunderMax"})
; The default application to limit hotkeys to.
; Starts disabled by default, so no danger setting to whatever you want
ADHD.config_default_app("CryENGINE")
; GUI size - (Width, Height)
ADHD.config_size(435,350)

; Defines your hotkeys 
; subroutine is the label (subroutine name - like MySub: ) to be called on press of bound key
; uiname is what to refer to it as in the UI (ie Human readable, with spaces)
ADHD.config_hotkey_add({uiname: "Fire Gauss Rifle(s)", subroutine: "Fire"})
ADHD.config_hotkey_add({uiname: "Functionality Toggle", subroutine: "FunctionalityToggle"})

; Hook into ADHD events
; First parameter is name of event to hook into, second parameter is a function name to launch on that event
ADHD.config_event("option_changed", "option_changed_hook")
ADHD.config_event("program_mode_on", "program_mode_on_hook")
ADHD.config_event("program_mode_off", "program_mode_off_hook")
ADHD.config_event("app_active", "app_active_hook")
ADHD.config_event("app_inactive", "app_inactive_hook")
ADHD.config_event("disable_timers", "disable_timers_hook")

; End Setup section
; ============================================================================================

ADHD.init()
ADHD.create_gui()

; The "Main" tab is tab 1
Gui, Tab, 1
; ============================================================================================
; GUI SECTION

; Create your GUI here
; If you want a GUI item's state saved in the ini file, create it like this:
; ADHD.gui_add("ControlType", "MyControl", "MyOptions", "Param3", "Default")
; eg ADHD.gui_add("DropDownList", "MyDDL", "xp+120 yp W120", "1|2|3|4|5", "3")
; The order is Control Type,(Variable)Name, Options, Param3, Default Value
; the Format is basically the same as an AHK Gui, Add command
; DO NOT give a control the same name as one of your hotkeys (eg Fire, ChangeFireRate)

; Otherwise, for GUI items that do not need to be saved, create them as normal

; Create normal label
Gui, Add, GroupBox, x5 y35 w388 h85, Weapon Settings
Gui, Add, Text, x25 y60, Cooldown Time (ms)
; Create Edit box that has state saved in INI
ADHD.gui_add("Edit", "Cooldown_Time", "xp+110 y58 W50", "", "")
; Create tooltip by adding _TT to the end of the Variable Name of a control
Cooldown_Time_TT := "Cooldown time in between shots."

Gui, Add, Text, x25 y85, Weapon Group
ADHD.gui_add("DropDownList", "Weapon_Group", "xp+110 yp-3 W60", "1|2|3|4|5|6", "6")
Weapon_Group_TT := "Weapon group the gauss rifle is on."

Gui, Add, GroupBox, x5 y130 w388 h85, Buffer Adjustments (Adjust these for fine-tuning)
Gui, Add, Text, x25 y155, Charge Buffer (ms)
ADHD.gui_add("Edit", "Charge_Buffer", "xp+110 y153 W50", "", "90")
Gui, Add, Text, x190 y155, (Default is 90)
Charge_Buffer_TT := "A buffer in milliseconds to comepsate for lag."

Gui, Add, Text, x25 y180, Cooldown Buffer (ms)
ADHD.gui_add("Edit", "Cooldown_Buffer", "xp+110 y177 W50", "", "90")
Gui, Add, Text, x190 y180, (Default is 90)
Cooldown_Buffer_TT := "A buffer in milliseconds to comepsate for lag."

Gui, Add, GroupBox, x5 y225 w388 h63, Sound Options
Gui, Add, Text, x25 y250, Sound Mode 
ADHD.gui_add("DropDownList", "Audio_Mode", "xp+110 y248 W60", "Voice|Beeps|Off", "Voice")
Audio_Mode_TT := "Allows you to select various audio modes."

; Set up the links on the footer of the main page
h := ADHD.get_gui_h() - 40
name := ADHD.get_macro_name()
version_n := ADHD.get_version_number()
;Gui, Add, Link, x5 y%h%, %name% was made specifically for <a href="http://mwomercs.com/">MechWarrior Online</a>.

; End GUI creation section
; ============================================================================================

ADHD.finish_startup()
Return

; ============================================================================================
; CODE SECTION

; Place your hotkey definitions and associated functions here
; When writing code, DO NOT create variables or functions starting adhd_

; Hook functions. We declared these in the config phase - so make sure these names match the ones defined above

; This is fired when settings change (including on load). Use it to pre-calculate values etc.
option_changed_hook(){
	Return
}

; Gets called when the "Limited" app gets focus
app_active_hook(){
	Return
}

; Gets called when the "Limited" app loses focus
app_inactive_hook(){
	Gosub, DisableTimers
}

; Gets called if ADHD wants to stop your timers
disable_timers_hook(){
	Gosub, DisableTimers
}

; Gets called when we enter program mode
program_mode_on_hook(){
	Gosub, DisableTimers
}

; Gets called when we exit program mode
program_mode_off_hook(){
	Gosub, DisableTimers
}

; Keep all timer disables in here so various hooks and stuff can stop all your timers easily.
; DisableTimers is referened by the hooks
DisableTimers:
	;SetTimer, MyTimer, Off
	Return

; ==========================================================================================
; HOTKEYS SECTION

; This is where you define labels that the various bindings trigger
; Make sure you call them the same names as you set in the settings at the top of the file (eg Fire, FireRate)

FunctionalityToggle: ;This is what turns the script on and off.

	if (adhd_hk_m_1 != "None")
	{
		Fire_Toggle := adhd_hk_m_1
	} else {
		Fire_Toggle := adhd_hk_k_1
	}
	
	; Yoni - If theres a modifier, add it
	prefix := ""
	tmp = adhd_hk_c_1
	GuiControlGet,%tmp%
	if (adhd_hk_c_1 == 1){
		prefix := prefix "^"
	}
	if (adhd_hk_a_1 == 1){
		prefix := prefix "!"
	}
	if (adhd_hk_s_1 == 1){
		prefix := prefix "+"
	}
	
	; Yoni - If there was no modifier, then the modifier should be * (everything)
	if (prefix == "") {
		prefix := "*"
	}
	
	; ADHD.debug("before prefix: " prefix " toggle: " Fire_Toggle)
	
	; Yoni - Make sure the Fire_Toggle we toggle below has the prefix!
	Fire_Toggle := prefix Fire_Toggle
	
	; ADHD.debug("after prefix: " prefix " toggle: " Fire_Toggle)

	If Toggle := !Toggle
	{
		HotKey, %Fire_Toggle%, Off
        If (Audio_Mode = "Voice")
        {
			SoundPlay, audio/gaussoff.wav
        }
        If (Audio_Mode = "Beeps")
        {
			SoundBeep 500, 100
			Sleep 50
			SoundBeep 500, 100 ; Plays two beeps
        }
	}
	else {
		HotKey, %Fire_Toggle%, On
        If (Audio_Mode = "Voice")
        {
			SoundPlay, audio/gausson.wav
        }
        If (Audio_Mode = "Beeps")
        {
			SoundBeep 1000, 100 ; Plays a single beep
        }
	}
Return

Fire:
	
	; Checks to see if the user is using a keyboard key instead of mouse button.
	if (adhd_hk_m_1 != "None")
	{
		Fire_Toggle := adhd_hk_m_1
	} else {
		Fire_Toggle := adhd_hk_k_1
	}
	
	; Checks to see if the user left the buffers empty.
	if (Charge_Buffer <= 0)
	{
		Charge_Buffer = 0
	}
	if (Cooldown_Buffer <= 0)
	{
		Cooldown_Buffer = 0
	}

	; Many games do not work properly with autofire unless this is enabled.
	; You can try leaving it out.
	; MechWarrior Online for example will not do fast (<~500ms) chain fire with weapons all in one group without this enabled
	ADHD.send_keyup_on_press("Fire","unmodified")
	
	; Adds a buffer to the cooldown and charge times to compensate for lag and also divides the charge time by 5.
	Buffered_Charge_Time := 750 + Charge_Buffer
	Divided_Charge_Time := Buffered_Charge_Time / 7
	Buffered_Cooldown := Cooldown_Time + Cooldown_Buffer
	
;	IfWinActive MechWarrior Online ;Only works when MWO window is active.
;	{  
		while GetKeyState(Fire_Toggle,"P") ;Runs the script in a loop as long as your trigger is held.
		{
			send,{%Weapon_Group% Down}
			If GetKeyState(Fire_Toggle,"P")
			{
				sleep,%Divided_Charge_Time%
			}
			If GetKeyState(Fire_Toggle,"P")
			{
				sleep,%Divided_Charge_Time%
			}
			If GetKeyState(Fire_Toggle,"P")
			{
				sleep,%Divided_Charge_Time%
			}
			If GetKeyState(Fire_Toggle,"P")
			{
				sleep,%Divided_Charge_Time%
			}
			If GetKeyState(Fire_Toggle,"P")
			{
				sleep,%Divided_Charge_Time%
			}
			If GetKeyState(Fire_Toggle,"P")
			{
				sleep,%Divided_Charge_Time%
			}
			If GetKeyState(Fire_Toggle,"P")
			{
				sleep,%Divided_Charge_Time%
				send,{%Weapon_Group% Up}
				sleep,%Buffered_Cooldown%
			} else {
				send,{%Weapon_Group% Up}
			}
		}
;	}
Return

; ==========================================================================================
; TRAY MENU SECTION

#Include HtmlBox.ahk ;Includes the HtmlBox function to accommodate HTML & CSS

AboutGC: ;Opens up a message box when About is clicked

AboutHTML = 
(

<style>
	body {
		text-align: left;
		font-family: Helvetica, Arial, sans-serif;
		font-size: 10Pt;
	}
	a, a:link, a:active {
		color: #2E9AFE;
		font-weight: bold; 
	}
	a:visited {
		color: #2E9AFE;
	}
	a:hover {
		color: #08298A;
	}
</style>

<b>%name% v%version_n%</b> was created using AHK Dynamic Hotkeys for Dummies<br>
ADHD was created by Clive "evilC" Galway. <a href="http://evilc.com/proj/adh" target="new">HomePage</a>   <a href="https://github.com/evilC/AHK-Dynamic-Hotkeys" target="new">GitHub Page</a><br>
<br>
%name% was created by ThunderMax for <a href="http://mwomercs.com/" target="new">MechWarrior Online</a>
<br>Visit our gaming group the Golden Foxes at <a href="http://foxmwo.com/" target="new">FoxMWO.com</a>
<br><br>
<div style="font-size:12Pt"><b>Cooldown Time Instructions:</b></div><br>
To calculate a new cooldown time, locate the gauss rifle you'll be using in the<br>warehouse list and obtain the cooldown info by hovering over it's name.
<br><br><img src="%A_ScriptDir%\images\example.png">
<br><br><div style="font-size:12Pt">The formula to calcuate your cooldown is below.<br>
<b><font color="orange">[ORANGE NUMBER]</font> MINUS <font color="green">[GREEN NUMBER]</font> TIMES 1000</b></div>
)
HtmlBox(AboutHTML, "Gauss Control - About / Instructions", False, True, False, 550, 700) ; HTML code, Title, Unknown Atrib?, Put in body?, Is URL?, Width, Height
Return

ExitGC: ;Exists program when Exit is clicked
	ExitApp 
Return

; ===================================================================================================
; FOOTER SECTION

; KEEP THIS AT THE END!!
#Include ADHDLib.ahk		; If you have the library in the same folder as your macro, use this
;#Include <ADHDLib>			; If you have the library in the Lib folder (C:\Program Files\Autohotkey\Lib), use this
