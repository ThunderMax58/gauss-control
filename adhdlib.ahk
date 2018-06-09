Class ADHDLib
	; ADHDLib - Autohotkey Dynamic Hotkeys for Dummies
{
	; ToDo:
	; BUGS:

	; Before next release:

	; Features:

	; Long-term:
	; Can you use "% myvar" notation in guicontrols? Objects of guicontrols would be better
	; Perform checking on hotkey_list to ensure sane values (No dupes, labels do not already exist etc)
	; Replace label names in ini with actual label names instead of 1, 2, 3 ?
	
	; Make sure the macro runs with administrator priveleges.
	; Some games etc will not see sent keys without this.
	; Run as admin code from http://www.autohotkey.com/board/topic/46526-
	run_as_admin(){
		Global 0
		IfEqual, A_IsAdmin, 1, Return 0
		Loop, %0% {
			params .= A_Space . %A_Index%
		}
		DllCall("shell32\ShellExecute" (A_IsUnicode ? "":"A"),uint,0,str,"RunAs",str,(A_IsCompiled ? A_ScriptFullPath
			: A_AhkPath),str,(A_IsCompiled ? "": """" . A_ScriptFullPath . """" . A_Space) params,str,A_WorkingDir,int,1)
		ExitApp
	}
	
	; Constructor - init default values
	__New(){
		this.instantiated := 1
		this.hotkey_list := []
		this.author_macro_name := "Gauss Control"					; Change this to your macro name
		this.author_version := "2.4"									; The version number of your script
		this.author_name := "ThunderMax"							; Your Name
		this.author_link := ""
		
		this.default_app := ""
		this.gui_w := 375
		this.gui_h := 190
		
		; Hooks
		this.events := {}
		;this.events.profile_load := ""
		this.events.option_changed := ""
		this.events.program_mode_on := ""
		this.events.program_mode_off := ""
		this.events.disable_timers := ""
		this.events.app_active := ""		; When the "Limited" app comes into focus
		this.events.app_inactive := ""		; When the "Limited" app goes out of focus
		
		; strip extension from end of script name for basis of INI name
		this.ini_name := this.build_ini_name()
	}

	; EXPOSED METHODS
	
	build_ini_name(){
		tmp := A_Scriptname
		Stringsplit, tmp, tmp,.
		ini_name := ""
		last := ""
		Loop, % tmp0
		{
			if (last != ""){
				if (ini_name != ""){
					ini_name := ini_name "."
				}
				ini_name := ini_name last
			}
			last := tmp%A_Index%
		}
		ini_name := ini_name ".ini"
		return ini_name
	}
	
	; Load settings etc
	init(){
		if (this.instantiated != 1){
			msgbox You must use an instance of this class, not the class itself.`nPut something like ADHD := New ADHDLib at the start of your script
			ExitApp
		}
		
		if (this.hotkey_list.MaxIndex() < 1){
			msgbox, No Actions defined, Exiting...
			ExitApp
		}

		Loop, % this.hotkey_list.MaxIndex()
		{
			If (IsLabel(this.hotkey_list[A_Index,"subroutine"]) == false){
				msgbox, % "The label`n`n" this.hotkey_list[A_Index,"subroutine"] ":`n`n does not appear in the script.`nExiting..."
				ExitApp
			}

		}
		this.debug_ready := 0
		
		; Indicates that we are starting up - ignore errant events, always log until we have loaded settings etc use this value
		this.starting_up := 1

		this.debug("Starting up...")
		this.app_act_curr := 0						; Whether the current app is the "Limit To" app or not

		; Start ADHD init vars and settings
		this.core_version := "1.0.3"

		; Variables to be stored in the INI file - will be populated by code later
		; [Variable Name, Control Type, Default Value]
		; eg ["MyControl","Edit","None"]
		this.ini_vars := []
		; Holds a REFERENCE copy of the hotkeys so authors can access the info (eg to quickly send a keyup after the trigger key is pressed)
		this.hotkey_mappings := {}

		#InstallKeybdHook
		#InstallMouseHook
		#MaxHotKeysPerInterval, 200

		#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
		SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

		; Make sure closing the GUI using X exits the script
		OnExit, GuiClose

		; List of mouse buttons
		this.mouse_buttons := "LButton|RButton|MButton|XButton1|XButton2|WheelUp|WheelDown|WheelLeft|WheelRight"

		ini := this.ini_name
		IniRead, x, %ini%, Settings, adhd_gui_x, unset
		IniRead, y, %ini%, Settings, adhd_gui_y, unset
		if (x == "unset"){
			msgbox, Welcome to Gauss Control.`n`nThis window is appearing because no settings file was detected, one will now be created in the same folder as the script`nIf you wish to have an icon on your desktop, it is recommended you place this file somewhere other than your desktop and create a shortcut, to avoid clutter or accidental deletion.`n`nIf you need further help, look in the About tab for links to Author(s) sites.`nYou may find help there, you may also find a Donate button...
			x := 0	; initialize
		}
		if (y == "unset"){
			y := 0
		}

		if (x == ""){
			x := 0	; in case of crash empty values can get written
		}
		if (y == ""){
			y := 0
		}
		this.gui_x := x
		this.gui_y := y
		
		; Get list of profiles
		IniRead, pl, %ini%, Settings, adhd_profile_list, %A_Space%
		this.profile_list := pl
		; Get current profile
		IniRead, cp, %ini%, Settings, adhd_current_profile, Default
		this.current_profile := cp

	}
	
	; Creates the ADHD gui
	create_gui(){
		; IMPORTANT !!
		; Declare global for gui creation routine.
		; Limitation of AHK - no dynamic creation of vars, and guicontrols need a global or static var
		; Also, gui commands do not accept objects
		; So declare temp vars as local in here
		global
		; Set up the GUI ====================================================
		local w := this.gui_w
		local h := this.gui_h - 30
		Gui, Add, Tab2, x0 w%w% h%h% gadhd_tab_changed, Main|Bindings|Profiles|About / Instructions

		local tabtop := 40
		local current_row := tabtop + 20
		
		Gui, Tab, 2
		; BINDINGS TAB
		Gui, Add, Text, x5 y40 W100 Center, Action
		Gui, Add, Text, xp+100 W70 Center, Keyboard
		Gui, Add, Text, xp+90 W70 Center, Mouse
		Gui, Add, Text, xp+82 W30 Center, Ctrl
		Gui, Add, Text, xp+30 W30 Center, Shift
		Gui, Add, Text, xp+30 W30 Center, Alt

		; Add hotkeys
		Loop, % this.hotkey_list.MaxIndex()
		{
			local name := this.hotkey_list[A_Index,"uiname"]
			Gui, Add, Text,x5 W100 y%current_row%, %name%
			Gui, Add, Hotkey, yp-5 xp+100 W70 vadhd_hk_k_%A_Index% gadhd_key_changed
			local mb := this.mouse_buttons
			Gui, Add, DropDownList, yp xp+80 W90 vadhd_hk_m_%A_Index% gadhd_mouse_changed, None||%mb%
			Gui, Add, CheckBox, xp+100 yp+5 W25 vadhd_hk_c_%A_Index% gadhd_option_changed
			Gui, Add, CheckBox, xp+30 yp W25 vadhd_hk_s_%A_Index% gadhd_option_changed
			Gui, Add, CheckBox, xp+30 yp W25 vadhd_hk_a_%A_Index% gadhd_option_changed
			current_row := current_row + 30
		}
		; Limit application toggle
		Gui, Add, CheckBox, x5 yp+25 W160 vadhd_limit_application_on gadhd_option_changed, Limit to Application: ahk_class

		; Limit application Text box
		Gui, Add, Edit, xp+170 yp+2 W120 vadhd_limit_application gadhd_option_changed,

		; Launch window spy
		Gui, Add, Button, xp+125 yp-1 W15 gadhd_show_window_spy, ?
		adhd_limit_application_TT := "Enter a value here to make hotkeys only trigger when a specific application is open.`nUse the window spy (? Button to the right) to find the ahk_class of your application.`nCaSe SenSitIve !!!"

		; Program mode toggle
		Gui, Add, Checkbox, x5 yp+30 vadhd_program_mode gadhd_program_mode_changed, Program Mode
		adhd_program_mode_TT := "Turns on program mode and lets you program keys. Turn off again to enable hotkeys"


		Gui, Tab, 3
		; PROFILES TAB
		current_row := tabtop + 20
		Gui, Add, Text,x5 W40 y%current_row%,Profile
		local pl := this.profile_list
		local cp := this.current_profile
		Gui, Add, DropDownList, xp+35 yp-5 W300 vadhd_current_profile gadhd_profile_changed, Default||%pl%
		
		Gui, Add, Button, x40 yp+25 gadhd_add_profile, Add
		Gui, Add, Button, xp+35 yp gadhd_delete_profile, Delete
		Gui, Add, Button, xp+47 yp gadhd_duplicate_profile, Copy
		Gui, Add, Button, xp+40 yp gadhd_rename_profile, Rename
		GuiControl,ChooseString, adhd_current_profile, %cp%

		Gui, Tab, 4
		; ABOUT TAB
		current_row := tabtop + 5
		local aname := this.author_name
        local versionn := this.author_version
		local mname := this.author_macro_name
		Gui, Add, Link,x5 y%current_row%, %mname% v%versionn% was created using AHK Dynamic Hotkeys for Dummies
		Gui, Add, Link,x5 yp+20,ADHD was created by Clive "evilC" Galway. <a href="http://evilc.com/proj/adh">HomePage</a> <a href="https://github.com/evilC/AHK-Dynamic-Hotkeys">GitHub Page</a>
		Gui, Add, Link,x5 yp+30, %mname% was created by %aname% for <a href="http://mwomercs.com/">MechWarrior Online</a>
		Gui, Add, Link,x5 yp+20, Visit our gaming group the Golden Foxes at <a href="http://foxmwo.com/">FoxMWO.com</a>
        Gui, font,bold
        Gui, font,s10
        Gui, Add, Link,x5 yp+30, Cooldown Time Instructions:
        Gui, font
        Gui, Add, Link,x5 yp+30, To calculate a new cooldown time, locate the gauss rifle you'll be using in the
        Gui, Add, Link,x5 yp+20, warehouse list and obtain the cooldown info by hovering over it's name.
        Gui, Add, Link,x5 yp+30, The formula to calcuate your cooldown is below.
        Gui, font,bold
        Gui, Add, Link,x5 yp+20, [ORANGE NUMBER] MINUS [GREEN NUMBER] TIMES 1000
        Gui, font
        Gui, Add, Button, x5 yp+30 h30 w150 gAboutGC, Click Here For Example
		local link := this.author_link
		;Gui, Add, Link,x5 yp+25, %link%
		Gui, Tab

		; Add a Status Bar for at-a-glance current profile readout
		Gui, Add, StatusBar,,


		; Show the GUI =====================================
		local ver := this.core_version
		local aver := this.author_version
		local name := this.author_macro_name
		local x := this.gui_x
		local y := this.gui_y
		local w := this.gui_w
		local h := this.gui_h
		Gui, Show, x%x% y%y% w%w% h%h%, %name% v%aver% (ADHD v%ver%)

		; Add Debug window controls
		Gui, Tab
		local tmp
		tmp := w - 90
		Gui, Add, CheckBox, x%tmp% y10 vadhd_debug_window gadhd_debug_window_change, Show Window
			
		tmp := w - 180
		Gui, Add, CheckBox, x%tmp% y10 vadhd_debug_mode gadhd_debug_change, Debug Mode

		; Fire GuiSubmit while starting_up is on to set all the variables
		Gui, Submit, NoHide

		; Create the debug GUI, but do not show yet
		tmp := w - 30
		Gui, 2:Add,Edit,w%tmp% h350 vadhd_log_contents ReadOnly,
		Gui, 2:Add, Button, gadhd_clear_log, clear
	}

	
	; Adds a GUI item and registers it for storage in the INI file
	; type(edit etc), name(variable name), options(eg xp+50), param3(eg dropdown list, label), default(used for ini file)
	gui_add(ctype, cname, copts, cparam3, cdef){
		; Note this function assumes global so it can create gui items
		Global
		Gui, Add, %ctype%, %copts% v%cname% gadhd_option_changed, %cparam3%
		this.ini_vars.Insert([cname,ctype,cdef])
	}

	finish_startup(){
		global	; Remove! phase out mass use of globals
		this.debug_ready := 1

		;Hook for Tooltips
		OnMessage(0x200, "this.mouse_move")
		;OnMessage(0x47, "ADHD.gui_move")


		; Finish setup =====================================
		this.profile_changed()
		this.debug_window_change()

		this.debug("Finished startup")

		; Finished startup, allow change of controls to fire events
		this.starting_up := 0

	}

	; Setup stuff
	config_hotkey_add(data){
		this.hotkey_list.Insert(data)
	}
	
	;ADHD.config_event("option_changed", "option_changed_hook")
	config_event(name, hook){
		this.events[name] := hook
	}
	
	config_size(w,h){
		this.gui_w := w
		this.gui_h := h
	}
	
	config_default_app(app){
		this.default_app := app
	}
	
	; Configure the About tab
	config_about(data){
		this.author_macro_name := data.name					; Change this to your macro name
		this.author_version := data.version									; The version number of your script
		this.author_name := data.author							; Your Name
		this.author_link := data.link
	}
	
	; Fires an event.
	; Basically executes a string as a function
	; Checks string is not empty first
	fire_event(event){
		if (event && event != ""){
			%event%()
		}
	}
	
	; Unused, just here to keep a record of the OnMessage technique
	gui_move( lParam, wParam, msg )
	{
		ToolTip, % "msg: " . msg . " | lParam: " . lParam . " | wParam: " . wParam
	}
	

	; aka load profile
	profile_changed(){
		global adhd_debug_mode

		global adhd_limit_application
		global adhd_limit_application_on
		global adhd_debug_window
		
		GuiControlGet,cp,,adhd_current_profile
		this.current_profile := cp
		;msgbox % this.current_profile
		this.debug("profile_changed - " this.current_profile)
		Gui, Submit, NoHide

		this.update_ini("adhd_current_profile", "Settings", this.current_profile,"")
		
		SB_SetText("Current profile: " this.current_profile) 
		
		this.hotkey_mappings := {}
		
		; Load hotkey bindings
		Loop, % this.hotkey_list.MaxIndex()
		{
			this.hotkey_mappings[this.hotkey_list[A_Index,"subroutine"]] := {}
			this.hotkey_mappings[this.hotkey_list[A_Index,"subroutine"]]["index"] := A_Index

			; Keyboard bindings
			tmp := this.read_ini("adhd_hk_k_" A_Index,this.current_profile,A_Space)
			GuiControl,,adhd_hk_k_%A_Index%, %tmp%
			this.hotkey_mappings[this.hotkey_list[A_Index,"subroutine"]]["unmodified"] := tmp
			
			; Mouse bindings
			tmp := this.read_ini("adhd_hk_m_" A_Index,this.current_profile,A_Space)
			GuiControl, ChooseString, adhd_hk_m_%A_Index%, %tmp%
			if (tmp != "None"){
				this.hotkey_mappings[this.hotkey_list[A_Index,"subroutine"]]["unmodified"] := tmp
			}

			; Control Modifier
			modstring := ""
			tmp := this.read_ini("adhd_hk_c_" A_Index,this.current_profile,0)
			GuiControl,, adhd_hk_c_%A_Index%, %tmp%
			if (tmp == 1){
				modstring := modstring "^"
			}
			
			; Shift Modifier
			tmp := this.read_ini("adhd_hk_s_" A_Index,this.current_profile,0)
			GuiControl,, adhd_hk_s_%A_Index%, %tmp%
			if (tmp == 1){
				modstring := modstring "+"
			}
			
			; Alt Modifier
			tmp := this.read_ini("adhd_hk_a_" A_Index,this.current_profile,0)
			GuiControl,, adhd_hk_a_%A_Index%, %tmp%
			if (tmp == 1){
				modstring := modstring "!"
			}
			this.hotkey_mappings[this.hotkey_list[A_Index,"subroutine"]]["modified"] := modstring this.hotkey_mappings[this.hotkey_list[A_Index,"subroutine"]]["unmodified"]
		}
		
		; limit application name
		this.remove_glabel("adhd_limit_application")
		if (this.default_app == "" || this.default_app == null){
			this.default_app := A_Space
		}
		tmp := this.read_ini("adhd_limit_app",this.current_profile,this.default_app)
		GuiControl,, adhd_limit_application, %tmp%
		this.add_glabel("adhd_limit_application")
		
		; limit application status
		tmp := this.read_ini("adhd_limit_app_on",this.current_profile,0)
		GuiControl,, adhd_limit_application_on, %tmp%
		
		; Get author vars from ini
		Loop, % this.ini_vars.MaxIndex()
		{
			def := this.ini_vars[A_Index,3]
			if (def == ""){
				def := A_Space
			}
			key := this.ini_vars[A_Index,1]
			sm := this.control_name_to_set_method(this.ini_vars[A_Index,2])
			
			this.remove_glabel(key)
			tmp := this.read_ini(key,this.current_profile,def)
			GuiControl,%sm%, %key%, %tmp%
			this.add_glabel(key)
		}

		; Debug settings
		adhd_debug_mode := this.read_ini("adhd_debug_mode","Settings",0)
		GuiControl,, adhd_debug_mode, %adhd_debug_mode%
		
		adhd_debug_window := this.read_ini("adhd_debug_window","Settings",0)
		GuiControl,, adhd_debug_window, %adhd_debug_window%

		this.program_mode_changed()
		
		; Fire the Author hook
		this.fire_event(this.events.option_changed)

		return
	}

	; aka save profile
	option_changed(){
		global adhd_debug_mode

		global adhd_limit_application
		global adhd_limit_application_on
		global adhd_debug_window
		
		if (this.starting_up != 1){
			this.debug("option_changed - control: " A_guicontrol)
			
			Gui, Submit, NoHide

			; Hotkey bindings
			Loop, % this.hotkey_list.MaxIndex()
			{
				this.update_ini("adhd_hk_k_" A_Index, this.current_profile, adhd_hk_k_%A_Index%, "")
				this.update_ini("adhd_hk_m_" A_Index, this.current_profile, adhd_hk_m_%A_Index%, "None")
				this.update_ini("adhd_hk_c_" A_Index, this.current_profile, adhd_hk_c_%A_Index%, 0)
				this.update_ini("adhd_hk_s_" A_Index, this.current_profile, adhd_hk_s_%A_Index%, 0)
				this.update_ini("adhd_hk_a_" A_Index, this.current_profile, adhd_hk_a_%A_Index%, 0)
			}
			this.update_ini("adhd_profile_list", "Settings", this.profile_list,"")
			
			; Limit app
			if (this.default_app == "" || this.default_app == null){
				this.default_app := A_Space
			}
			this.update_ini("adhd_limit_app", this.current_profile, adhd_limit_application, this.default_app)
			SB_SetText("Current profile: " this.current_profile)
			
			; Limit app toggle
			this.update_ini("adhd_limit_app_on", this.current_profile, adhd_limit_application_on, 0)
			
			; Add author vars to ini
			Loop, % this.ini_vars.MaxIndex()
			{
				tmp := this.ini_vars[A_Index,1]
				this.update_ini(tmp, this.current_profile, %tmp%, this.ini_vars[A_Index,3])
			}
			
			; Fire the Author hook
			this.fire_event(this.events.option_changed)
			
			; Debug settings
			this.update_ini("adhd_debug_mode", "settings", adhd_debug_mode, 0)
			this.update_ini("adhd_debug_window", "settings", adhd_debug_window, 0)
			
		} else {
			this.debug("ignoring option_changed - " A_Guicontrol)
		}
		return
	}

	; Add and remove glabel is useful because:
	; When you use GuiControl to set the contents of an edit...
	; .. it's glabel is fired.
	; So remove glabel, set editbox value, re-add glabel to solve
	add_glabel(ctrl){
		GuiControl, +gadhd_option_changed, %ctrl%
	}

	remove_glabel(ctrl){
		GuiControl, -g, %ctrl%
	}

	get_macro_name(){
		return this.author_macro_name
	}
    
	get_version_number(){
		return this.author_version
	}
	
	get_gui_h(){
		return this.gui_h
	}
	
	get_gui_w(){
		return this.gui_w
	}
	
	; Profile management - functions to manage preserving user settings
	add_profile(name){
		global adhd_current_profile
		
		if (name == ""){
			InputBox, name, Profile Name, Please enter a profile name
			if (ErrorLevel){
				return
			}
		}
		if (this.profile_list == ""){
			this.profile_list := name
		} else {
			this.profile_list := this.profile_list "|" name
		}
		pl := this.profile_list
		Sort, pl, D|
		this.profile_list := pl
		
		GuiControl,, adhd_current_profile, |Default||%pl%
		GuiControl,ChooseString, adhd_current_profile, %name%
		
		this.update_ini("adhd_profile_list", "Settings", this.profile_list, "")
	}

	delete_profile(name, gotoprofile = "Default"){
		Global adhd_current_profile
		
		if (name != "Default"){
			pl := this.profile_list
			StringSplit, tmp, pl, |
			out := ""
			Loop, %tmp0%{
				if (tmp%a_index% != name){
					if (out != ""){
						out := out "|"
					}
					out := out tmp%a_index%
				}
			}
			pl := out
			this.profile_list := pl
			
			ini := this.ini_name
			IniDelete, %ini%, %name%
			this.update_ini("adhd_profile_list", "Settings", this.profile_list, "")		
			
			; Set new contents of list
			GuiControl,, adhd_current_profile, |Default|%pl%
			
			; Select the desired new current profile
			GuiControl, ChooseString, adhd_current_profile, %gotoprofile%
			
			; Trigger save
			Gui, Submit, NoHide
			
			this.profile_changed()
		}
		return
	}

	duplicate_profile(name){
		global adhd_current_profile
		
		; Blank name specified - prompt for name
		if (name == ""){
			InputBox, name, Profile Name, Please enter a profile name
			if (ErrorLevel){
				return
			}
		}
		; ToDo: Duplicate - should just need to be able to change current name and save?
		
		; Create the new item in the profile list
		if (this.profile_list == ""){
			this.profile_list := name
		} else {
			this.profile_list := this.profile_list "|" name
		}
		pl := this.profile_list
		Sort, pl, D|
		this.profile_list := pl
		
		this.current_profile := name
		adhd_current_profile := name
		; Push the new list to the profile select box
		GuiControl,, adhd_current_profile, |Default||%pl%
		; Set the new profile to the currently selected item
		GuiControl,ChooseString, adhd_current_profile, %name%
		; Update the profile list in the INI
		this.update_ini("adhd_profile_list", "Settings", this.profile_list, "")
		
		; Firing option_changed saves the current state to the new profile name in the INI
		this.debug("duplicate_profile calling option_changed")
		this.option_changed()

		return
	}

	rename_profile(){
		if (this.current_profile != "Default"){
			old_prof := this.current_profile
			InputBox, new_prof, Profile Name, Please enter a new name
			if (!ErrorLevel){
				this.duplicate_profile(new_prof)
				this.delete_profile(old_prof,new_prof)
			}
		}
		return
	}

	; End profile management

	; For some games, they will not let you autofire if the triggering key is still held down...
	; even if the triggering key is not the key sent and does nothing in the game!
	; Often a workaround is to send a keyup of the triggering key
	; Calling send_keyup_on_press() in an action will cause this to happen
	send_keyup_on_press(sub,mod){
		; hotkey_mappings contains a handy lookup to hotkey mappings !
		; contains "modified" and "unmodified" keys
		; Note, it is REFERENCE ONLY. Changing it has no effect.
		tmp := this.hotkey_mappings[sub][mod] " up"
		Send {%tmp%}

	}

	tab_changed(){
		global adhd_program_mode
		
		; If in program mode on tab change, disable program mode
		if (adhd_program_mode == 1){
			GuiControl,,adhd_program_mode,0
			this.program_mode_changed()
		}
		return
	}

	; Converts a Control name (eg DropDownList) into the parameter passed to GuiControl to set that value (eg ChooseString)
	control_name_to_set_method(name){
		if (name == "DropDownList"){
			return "ChooseString"
		} else {
			return ""
		}
	}

	; Detects a key pressed and clears the mouse box
	key_changed(ctrl){
		; Special keys will have a value of ""
		if (%ctrl% == ""){
			ctr := 1
			max := 1
		} else {
			; Check to see if just modifiers selected IN THE HOTKEY BOX
			; We ignore modifiers in the hotkey box because we may want to bind ctrl+lbutton
			ctr := 0
			max := StrLen(ctrl)
			Loop, %max%
			{
				chr := substr(ctrl,ctr,1)
				if (chr != "^" && chr != "!" && chr != "+"){
					ctr := ctr + 1
				}
			}
			; Only modifier keys pressed?
			if (ctr == 0){
				; When you hold just modifiers in a hotkey box, they appear only so long as they are held
				; On key up, if no other keys are held, they will disappear
				; We are not interested in them, so ignore contents of hotkey box while it is just modifiers
				return
			}
		}
		
		; ToDo: We returned above - can I delete this block?
		; key pressed
		if (ctr < max){
			GuiControl,, %ctrl%, None
			this.debug("key_changed calling option_changed")
			this.option_changed()
		} else {
			; Detect actual key (Not modified) - clear mouse box
			tmp := SubStr(ctrl,11)
			; Set the mouse field to blank
			GuiControl,ChooseString, adhd_hk_m_%tmp%, None
			this.debug("key_changed calling option_changed")
			this.option_changed()
		}
		return
	}

	; Detects mouse selected from list and clears key box
	mouse_changed(){
		tmp := SubStr(A_GuiControl,11)
		; Set the keyboard field to blank
		GuiControl,, adhd_hk_k_%tmp%, None
		this.debug("mouse_changed calling option_changed")
		this.option_changed()
		return
	}

	; INI manipulation
	
	; Updates the settings file. If value is default, it deletes the setting to keep the file as tidy as possible
	update_ini(key, section, value, default){
		tmp := this.ini_name
		if (value != default){
			; Only write the value if it differs from what is already written
			if (this.read_ini(key,section,-1) != value){
				IniWrite,  %value%, %tmp%, %section%, %key%
			}
		} else {
			; Only delete the value if there is already a value to delete
			if (this.read_ini(key,section,-1) != -1){
				IniDelete, %tmp%, %section%, %key%
			}
		}
	}

	read_ini(key,section,default){
		ini := this.ini_name
		IniRead, out, %ini%, %section%, %key%, %default%
		return out
	}

	; Called on app exit
	exit_app(){	
		Gui, +Hwndgui_id
		WinGetPos, gui_x, gui_y,,, ahk_id %gui_id%
		ini := this.ini_name
		if (this.read_ini("adhd_gui_x","Settings", -1) != gui_x){
			IniWrite, %gui_x%, %ini%, Settings, adhd_gui_x
		}
		if (this.read_ini("gui_y","Settings", -1) != gui_y){
			IniWrite, %gui_y%, %ini%, Settings, adhd_gui_y
		}
		this.fire_event(this.events.on_exit) ;ThunderMax test
		ExitApp
		return
	}

	show_window_spy(){
		SplitPath, A_AhkPath,,tmp
		tmp := tmp "\AU3_Spy.exe"
		IfExist, %tmp%
			Run, %tmp%
	}

	; Debug functions
	debug_window_change(){
		global adhd_debug_window
		
		gui, submit, nohide
		if (adhd_debug_window == 1){
			Gui, +Hwndgui_id
			WinGetPos, x, y,,, ahk_id %gui_id%
			y := y - 440
			w := this.gui_w
			Gui, 2:Show, x%x% y%y% w%w% h400, ADHD Debug Window
		} else {
			gui, 2:hide
		}
		; On startup do not call option_changed, we are just setting the window open or closed
		if (!this.starting_up){
			this.option_changed()
		}
		return
	}

	debug_change(){
		gui, 2:submit, nohide
		this.option_changed()
		return
	}

	debug(msg){
		global adhd_log_contents
		global adhd_debug_mode

		; If in debug mode, or starting up...
		if (adhd_debug_mode || this.starting_up){
			adhd_log_contents := adhd_log_contents "* " msg "`n"
			if (this.debug_ready){
				guicontrol,2:,adhd_log_contents, % adhd_log_contents
				gui, 2:submit, nohide
			}
		}
	}
	
	clear_log(){
		global adhd_log_contents
		adhd_log_contents := ""
		GuiControl,,adhd_log_contents,%adhd_log_contents%
	}

	; Program mode stuff
	program_mode_changed(){
		global adhd_limit_application
		global adhd_limit_application_on
		global adhd_program_mode
		
		this.debug("program_mode_changed")
		Gui, Submit, NoHide
		
		if (adhd_program_mode == 1){
			this.debug("Entering Program Mode")
			; Enable controls, stop hotkeys, kill timers
			this.disable_hotkeys()
			this.disable_heartbeat()
			GuiControl, enable, adhd_limit_application
			GuiControl, enable, adhd_limit_application_on
			this.fire_event(this.events.program_mode_on)
		} else {
			; Disable controls, start hotkeys, start heartbeat timer
			this.debug("Exiting Program Mode")
			this.enable_hotkeys()
			this.enable_heartbeat()
			GuiControl, disable, adhd_limit_application
			GuiControl, disable, adhd_limit_application_on
			this.fire_event(this.events.program_mode_off)
		}
		return
	}

	; App detection stuff
	enable_heartbeat(){
		this.debug("Enabling Heartbeat")
		global adhd_limit_application
		global adhd_limit_application_on
		
		if (adhd_limit_application_on == 1 && adhd_limit_application != ""){
			SetTimer, adhd_heartbeat, 500
		}
		return
	}

	disable_heartbeat(){
		this.debug("Disabling Heartbeat")
		SetTimer, adhd_heartbeat, Off
		return
	}

	heartbeat(){
		global adhd_limit_application
		
		; Check current app here.
		; Not used to enable or disable hotkeys, used to start or stop author macros etc
		IfWinActive, % "ahk_class " adhd_limit_application
		{
			this.app_active(1)
		}
		else
		{
			this.app_active(0)
		}
		return
	}

	app_active(act){
		if (act){
			if (this.app_act_curr != 1){
				; Changing from inactive to active
				this.app_act_curr := 1
				this.fire_event(this.events.app_active)
			}
		} else {
			if (this.app_act_curr != 0){
				; Changing from active to inactive
				; Stop Author Timers
				this.app_act_curr := 0
				
				; Fire event hooks
				this.fire_event(this.events.disable_timers)
				this.fire_event(this.events.app_active)
				;Gosub, adhd_disable_author_timers	; Fire the Author hook
			}
		}
	}

	
	; Hotkey detection routines
	enable_hotkeys(){
		global adhd_limit_application
		global adhd_limit_application_on
		
		; ToDo: Should not submit gui here, triggering save...
		this.debug("enable_hotkeys")
		
		Gui, Submit, NoHide
		Loop, % this.hotkey_list.MaxIndex()
		{
			hotkey_prefix := this.build_prefix(A_Index)
			hotkey_keys := this.get_hotkey_string(A_Index)
			
			if (hotkey_keys != ""){
				hotkey_string := hotkey_prefix hotkey_keys
				hotkey_subroutine := this.hotkey_list[A_Index,"subroutine"]
				if (adhd_limit_application_on == 1){
					if (adhd_limit_application !=""){
						; Enable Limit Application for all subsequently declared hotkeys
						Hotkey, IfWinActive, ahk_class %adhd_limit_application%
					}
				} else {
					; Disable Limit Application for all subsequently declared hotkeys
					Hotkey, IfWinActive
				}
				
				this.debug("Adding hotkey: " hotkey_string " sub: " hotkey_subroutine)
				
				; Yoni - Use a separate variable for temporary usage
				hotkey_to_use := hotkey_string
				; Yoni - If we are using the Fire subroutine and we havent specified a prefix, then we add the * (wildcard) prefix. Notice that in either case we add the ~ prefix, which is always supposed to be there
				if (hotkey_subroutine == "Fire" && hotkey_prefix == "") {
					hotkey_to_use := "*~" hotkey_to_use
				} else {
					hotkey_to_use := "~" hotkey_to_use
				}

				; Bind down action of hotkey
				; Yoni - Use the variable we made for the hotkey
				Hotkey, %hotkey_to_use% , %hotkey_subroutine%
				
				if (IsLabel(hotkey_subroutine "Up")){
					; Bind up action of hotkey
					Hotkey, %hotkey_to_use% up , %hotkey_subroutine%Up
				}
				; ToDo: Up event does not fire for wheel "buttons" - send dupe event or something?
			}
			
			; ToDo: Disabling of GUI controls should not be in here - put them in program mode
			GuiControl, Disable, adhd_hk_k_%A_Index%
			GuiControl, Disable, adhd_hk_m_%A_Index%
			GuiControl, Disable, adhd_hk_c_%A_Index%
			GuiControl, Disable, adhd_hk_s_%A_Index%
			GuiControl, Disable, adhd_hk_a_%A_Index%
		}
		return
	}

	disable_hotkeys(){
		global adhd_limit_application
		global adhd_limit_application_on
		
		this.debug("disable_hotkeys")

		Loop, % this.hotkey_list.MaxIndex()
		{
			hotkey_prefix := this.build_prefix(A_Index)
			hotkey_keys := this.get_hotkey_string(A_Index)
			if (hotkey_keys != ""){
				hotkey_string := hotkey_prefix hotkey_keys
				; ToDo: Is there a better way to remove a hotkey?
				HotKey, ~%hotkey_string%, adhd_do_nothing
				if (IsLabel(hotkey_subroutine "Up")){
					; Bind up action of hotkey
					HotKey, ~%hotkey_string% up, adhd_do_nothing
				}
			}
			GuiControl, Enable, adhd_hk_k_%A_Index%
			GuiControl, Enable, adhd_hk_m_%A_Index%
			GuiControl, Enable, adhd_hk_c_%A_Index%
			GuiControl, Enable, adhd_hk_s_%A_Index%
			GuiControl, Enable, adhd_hk_a_%A_Index%
		}
		return
	}

	get_hotkey_string(hk){
		;Get hotkey string - could be keyboard or mouse
		tmp := adhd_hk_k_%hk%
		if (tmp == ""){
			tmp := adhd_hk_m_%hk%
			if (tmp == "None"){
				tmp := ""
			}
		}
		return tmp
	}

	
	; 3rd party functions
	; Tooltip function from http://www.autohotkey.com/board/topic/81915-solved-gui-control-tooltip-on-hover/#entry598735
	mouse_move(){
		static CurrControl, PrevControl, _TT
		CurrControl := A_GuiControl
		If (CurrControl <> PrevControl){
				SetTimer, DisplayToolTip, -750 	; shorter wait, shows the tooltip faster
				PrevControl := CurrControl
		}
		return
		
		DisplayToolTip:
		try
				ToolTip % %CurrControl%_TT
		catch
				ToolTip
		SetTimer, RemoveToolTip, -10000
		return
		
		RemoveToolTip:
		ToolTip
		return
	}

	; Special key detection routines
	special_key_pressed(ctrl){
		modifier := ""
		If GetKeyState("Shift","P")
			modifier .= "+"
		If GetKeyState("Ctrl","P")
			modifier .= "^"
		If GetKeyState("Alt","P")
			modifier .= "!"
		Gui, Submit, NoHide											;If BackSpace is the first key press, Gui has never been submitted.
		If (A_ThisHotkey == "*BackSpace" && %ctrl% && !modifier)	;If the control has text but no modifiers held,
			GuiControl,,%ctrl%                                      ;  allow BackSpace to clear that text.
		Else                                                     	;Otherwise,
			GuiControl,,%ctrl%, % modifier SubStr(A_ThisHotkey,2)	;  show the hotkey.
		this.debug("special key detect calling key_changed")
		this.key_changed(ctrl)
		return
	}

	hotkey_ctrl_has_focus() {
		GuiControlGet, ctrl, Focus       ;ClassNN
		If InStr(ctrl,"hotkey") {
			GuiControlGet, ctrl, FocusV     ;Associated variable
			Return, ctrl
		}
	}

	build_prefix(hk){
		out := ""
		tmp = adhd_hk_c_%hk%
		GuiControlGet,%tmp%
		if (adhd_hk_c_%hk% == 1){
			out := out "^"
		}
		if (adhd_hk_a_%hk% == 1){
			out := out "!"
		}
		if (adhd_hk_s_%hk% == 1){
			out := out "+"
		}
		return out
	}

}

; Label triggers

adhd_profile_changed:
	ADHD.profile_changed()
	return

adhd_option_changed:
	ADHD.option_changed()
	return

adhd_add_profile:
	ADHD.add_profile("")	; just clicking the button calls with empty param
	return

; Delete Profile pressed
adhd_delete_profile:
	ADHD.delete_profile(adhd_current_profile)	; Just clicking the button deletes the current profile
	return

adhd_duplicate_profile:
	ADHD.duplicate_profile("")
	return
	
adhd_rename_profile:
	ADHD.rename_profile()
	return

adhd_tab_changed:
	ADHD.tab_changed()
	return

adhd_key_changed:
	ADHD.key_changed(A_GuiControl)
	return

adhd_mouse_changed:
	ADHD.mouse_changed()
	return

adhd_enable_hotkeys:
	ADHD.enable_hotkeys()
	return

adhd_disable_hotkeys:
	ADHD.disable_hotkeys()
	return

adhd_show_window_spy:
	ADHD.show_window_spy()
	return

adhd_debug_window_change:
	ADHD.debug_window_change()
	return

adhd_debug_change:
	ADHD.debug_change()
	return
	
adhd_clear_log:
	ADHD.clear_log()
	return

adhd_program_mode_changed:
	ADHD.program_mode_changed()
	return

adhd_heartbeat:
	ADHD.heartbeat()
	return

; An empty stub to redirect unbound hotkeys to
adhd_do_nothing:
	return

	
; === SHOULD NOT NEED TO EDIT BELOW HERE! ===========================================================================


; Kill the macro if the GUI is closed
adhd_exit_app:
GuiClose:
	ADHD.exit_app()
	return

; ==========================================================================================================================
; Code from http://www.autohotkey.com/board/topic/47439-user-defined-dynamic-hotkeys/
; This code enables extra keys in a Hotkey GUI control
#MenuMaskKey vk07                 ;Requires AHK_L 38+
#If adhd_ctrl := ADHD.hotkey_ctrl_has_focus()
	*AppsKey::                       ;Add support for these special keys,
	*BackSpace::                     ;  which the hotkey control does not normally allow.
	*Delete::
	*Enter::
	*Escape::
	*Pause::
	*PrintScreen::
	*Space::
	*Tab::
	; Can use mouse hotkeys like this - it detects them but does not display them
	;~*WheelUp::
	; ToDo: Pass A_ThisHotkey also?
	ADHD.special_key_pressed(adhd_ctrl)
	return
#If
