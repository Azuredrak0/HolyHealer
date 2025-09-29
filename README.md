HolyHealer Addon

HolyHealer is an addon designed for Paladin players to automate healing and buff management, optimizing performance in raids and groups.

Features
Healing Automation: Casts Holy Light, Flash of Light, and Holy Shock based on health thresholds.
Melee Support: Uses Holy Strike and Crusader Strike when conditions are met.
Buff Management: Ensures Seal of Wisdom and Holy Judgement buffs are active.
Debug Mode: Toggle debug output with /hh debug on to troubleshoot issues.

Usage

Following Function can be used in macros:
/run aHealWithHL(30) 
-- casts Holy Light if a target in range below 30% health is detected AND if Holy Judgement buff is active (you can change the number 30 to any other threshold you desire)

/run aHealWithHS(90) 
-- Holy Shock if a target in range (20yd) of Holy Shock below 90% health is detected (90 can be changed to any other threshold)

/run aCastHolyStrike(96, 4) 
-- Holy Strike if 4+ players below 96% health are detected within 10yd range. (96 and 4 can be changed to desired values)

/run aHealWithFoL(90) 
-- Flash of Light if a target below 90% health is detected within range of Flash of Light (90% can be whatever you wish)




Debug Mode:
Enable: /hh debug on
Disable: /hh debug off

Debugging
Enable Debug Mode: /hh debug on to see detailed logs (e.g., spell cast attempts and targets).
Check Addon Load: Look for HH DEBUG: HolyHealer addon loaded successfully. in chat.
Report Issues: Share debug output and error messages on GitHub Issues.
