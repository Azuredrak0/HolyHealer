HolyHealer Addon

HolyHealer is an addon designed for Paladin players to automate healing and buff management, optimizing performance in raids and groups.

Features
Healing Automation: Casts Holy Light, Flash of Light, and Holy Shock based on health thresholds.
Melee Support: Uses Holy Strike and Crusader Strike when conditions are met.
Buff Management: Ensures Seal of Wisdom and Holy Judgement buffs are active.
Debug Mode: Toggle debug output with /hh debug on to troubleshoot issues.

Usage

Following Function can be used in macros:
```/run aHealWithHL(30)```

-- casts Holy Light if a target in range below 30% health is detected AND if Holy Judgement buff is active (you can change the number 30 to any other threshold you desire)
-- this function also includes the aMeleeBuffs function to apply Seal of Wisdom to self, and Judge target to apply Holy Judgement to target.
-- be aware that Holy Light is mana intensive, and setting the threshold too high may cause you to cast Holy Light often.

```/run aHealWithHS(90) ```

-- Holy Shock if a target in range (20yd) of Holy Shock below 90% health is detected (90 can be changed to any other threshold)

```/run aCastHolyStrike(96, 4) ```

-- Holy Strike if 4+ players below 96% health are detected within 10yd range. (96 and 4 can be changed to desired values)
   --If the parameters above are not met, and Holy Shock in on cooldown, a Crusader Strike will be performed

```/run aHealWithFoL(90) ```

-- Flash of Light if a target below 90% health is detected within range of Flash of Light (90% can be whatever you wish)

```/run aMeleeBuffs()```

--Ensures "Seal of Wisdom" and "Holy Judgement" (ID 51309) buffs are active. Casts "Seal of Wisdom" on the player if missing, then "Judgement" on an enemy target if "Holy Judgement" is missing and a valid target exists.

As part of same macro, you can stack the above to automate all the scripts in successtion.  Recommendation is not to SPAM the macro, but press it as close to GCD as possible.  Due to nampower (which is required for scripts range finding to work), you do not want to queue spell by spamming the button too fast.  The following will cast emergency Holy Light (at players below 30 or 45 HP), use Holy Shock on cooldown, and will optimize the use of Holy Strike, or Crusader strike (to reset holy shock) on cooldown.  Otherwise it will spam Flash of Light and auto-attack

```
/run aHealWithHL(30)
/run aHealWithHS(90)
/run aCastHolyStrike(96, 4)
/run if not aHealWithHL(45) then aHealWithFoL(90) end;
```

It is strongly recommended that you add the following to the end of the script to ensure that you always perform auto-attack.

```/script if not IsCurrentAction(108) then UseAction(108) end;```

108 is the number on your bar where you put the Auto-Attack ability.  If your auto-attack is in the first slot (#1 hotkey) the number will be 1 instead of 108.


Debug Mode (not currently working):
Enable: /hh debug on
Disable: /hh debug off

Debugging
Enable Debug Mode: /hh debug on to see detailed logs (e.g., spell cast attempts and targets).
Check Addon Load: Look for HH DEBUG: HolyHealer addon loaded successfully. in chat.
Report Issues: Share debug output and error messages on GitHub Issues.
