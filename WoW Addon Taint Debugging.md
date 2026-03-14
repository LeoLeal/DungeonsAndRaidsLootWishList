# **Technical Analysis of Secure Execution Taint Propagation within the Blizzard Objective Tracker and Architectural Remediation for Loot Wishlist Integration**

The architectural integrity of the World of Warcraft user interface is predicated on a binary security model that distinguishes between "secure" code, authored and signed by Blizzard Entertainment, and "tainted" code, which originates from third-party AddOns or user scripts.1 This security architecture is not merely a classification of origin but a fundamental mechanical constraint on the execution environment. When the game engine processes Lua instructions, it initiates in a "secure" state, possessing the authoritative permission to execute protected functions—actions deemed sensitive to gameplay balance, such as unit targeting, spell casting, or the manipulation of specific UI elements during active combat.2 The introduction of taint occurs the moment a secure execution path reads data or executes a closure originating from a third-party source.1 Once a path is tainted, it remains so for the duration of that execution thread, and any global or local variables modified by that thread inherit the tainted status, effectively "spreading" the contamination through the UI's memory space.1

The Objective Tracker is a particularly vulnerable component within this ecosystem because it serves as a central hub for multiple data streams, including quest logs, achievement tracking, profession recipes, and scenario objectives.4 Because the tracker is deeply integrated with the default game UI and frequently interacts with the GameTooltip and various "protected" frames, even a minor lapse in security isolation within a custom module can propagate taint throughout the entire interface.1 This results in "Action Forbidden" errors and the failure of critical systems, such as the ability to display item tooltips or toggle the main menu during combat.6 The Loot Wishlist AddOn, by attempting to inject a custom tracking group into this complex system, has inadvertently created an insecure call path that compromises the security state of the Objective Tracker manager, leading to the global failure of tooltip rendering.5

## **The Foundations of the WoW Secure Execution Environment**

To understand the failures observed in the Loot Wishlist integration, one must first examine the specific rules governing how taint is generated and propagated. The environment utilizes an inheritance-based propagation system where any operation involving a tainted value results in a tainted outcome.1 If an AddOn defines a function that Blizzard's code later calls, the execution path becomes "sticky"—an analogy often used by developers to describe how third-party code functions like honey, contaminating any "clean" Blizzard hands that touch it.1 This "honey" is not easily removed; once a variable or a function closure is tainted, it remains tainted until the player reloads the interface (/reload) or logs out, as the engine must guarantee that no unauthorized code has influenced the state of protected systems.1

### **Taint Propagation and Inheritance Rules**

The following table illustrates the deterministic nature of taint inheritance across various Lua operations within the WoW environment. This matrix defines how the security state of an execution path is determined based on the interaction between secure and tainted values.

| Operation Type | Secure Value (S) \+ Secure Value (S) | Secure Value (S) \+ Tainted Value (T) | Tainted Value (T) \+ Tainted Value (T) |
| :---- | :---- | :---- | :---- |
| Variable Assignment | Result is Secure (S) | Result is Tainted (T) | Result is Tainted (T) |
| Table Key Access | Result is Secure (S) | Result is Tainted (T) | Result is Tainted (T) |
| Function Call | Stays Secure (S) | Becomes Tainted (T) | Stays Tainted (T) |
| Global Variable Write | Clean Global (S) | Taints Global (T) | Taints Global (T) |
| Arithmetic / Concatenation | Result is Secure (S) | Result is Tainted (T) | Result is Tainted (T) |

This model ensures that taint is highly contagious.3 For instance, if an AddOn creates a local variable local x \= 2 while the current execution is tainted, x itself becomes tainted.1 If that variable is later used in an arithmetic operation with a secure global variable, the result is tainted, and if that result is stored back into a secure global, that global itself becomes tainted for the remainder of the session.1 This persistent contamination is a critical factor in why the Loot Wishlist AddOn causes errors even after its tooltip code is removed; the very act of being part of the Blizzard update loop taints the tracker's internal state.9

### **The Role of Protected Functions and Frames**

Protected functions are the gatekeepers of the WoW API. These functions will only execute if the engine detects that the call originated from a purely secure execution path.2 In the context of the user interface, frames themselves can be "protected".2 A protected frame, once combat begins, enters a state of "lockdown" where its size, position, and visibility cannot be altered by tainted code.2 The Objective Tracker Frame is a complex hybrid; while the main frame is not inherently protected in all contexts, many of its children—such as quest item buttons—are.12

When an AddOn anchors a custom frame to a protected frame, or vice-versa, the security restrictions of the protected frame can propagate to the anchor partner.1 This propagation is often temporary but can lead to scenarios where an AddOn accidentally "locks down" a piece of the Blizzard UI, preventing it from updating during combat and triggering the ubiquitous "Action Forbidden" error dialog.1 This is especially prevalent in the Objective Tracker, which undergoes constant updates during gameplay, making any anchor-based taint propagation immediately visible as a UI failure.5

## **Architectural Complexity of the Blizzard Objective Tracker**

The Blizzard Objective Tracker is not a single entity but a modular container managed by the ObjectiveTrackerFrameMixin.15 It is arguably one of the most complex systems in the default interface due to its dynamic nature and the sheer volume of events it must handle simultaneously.4 The tracker operates through a system of "Modules" (e.g., Quest, Achievement, Campaign, Profession) that are registered to a central manager.15 Each module is responsible for its own data collection and line rendering, while the manager handles the vertical stacking, header management, and overall visibility.17

### **The ObjectiveTrackerFrameMixin and Update Logic**

The core logic resides in Blizzard\_ObjectiveTracker.lua, where the ObjectiveTrackerFrameMixin:OnLoad function initializes the system and registers for high-frequency events such as ZONE\_CHANGED, QUEST\_ACCEPTED, and QUEST\_LOG\_UPDATE.15 The system maintains a MODULES table which is iterated during the update cycle.17 The manager calls the Update method on each registered module, which in turn populates "Blocks" and "Lines" using predefined XML templates.16

The risk of taint enters this loop when an AddOn registers its own module or hooks into an existing one.9 If a third-party AddOn calls ObjectiveTrackerFrame:AddModule(customModule), it places its own update functions directly within the execution path of the Blizzard manager.15 Because the AddOn's module:Update() function is inherently tainted, the moment the Blizzard code calls it, the entire Update execution thread becomes tainted.1 This is a "Taint Trap," as the tracker often performs secure operations immediately after updating its modules, such as showing or hiding headers based on game rules.15

### **The Quest Objective Tracker Specifics**

The Blizzard\_QuestObjectiveTracker.lua provides a specialized implementation for quests, utilizing settings that define headers, events, and templates.16 A critical finding in modern UI research is the existence of the global variable OBJECTIVE\_TRACKER\_UPDATE\_REASON.9 If an AddOn interacts with the tracker such that this variable is modified or read during a tainted path, the entire tracker becomes "sticky".9 This specific taint has been linked to issues where clicking quest objectives fails to open the map or where item tooltips cease to function.5 The Loot Wishlist's integration likely touches this variable or the underlying MODULES list, thereby tainting the root of the tracker's update logic.

## **The Causal Linkage Between Taint and Tooltip Failure**

The failure of item tooltips in the presence of Objective Tracker taint is a classic example of cross-module contamination.8 The GameTooltip is a global, secure frame used by virtually every component of the game UI.11 When the Objective Tracker updates its lines—specifically lines that include quest items or clickable objectives—it frequently interacts with the tooltip to provide context to the player.5

### **The Mechanics of Tooltip Failure**

When an AddOn like a Loot Wishlist tracker integrates into the Objective Tracker, it usually does so by creating new "Lines" or "Blocks" using Blizzard's templates.16 These lines often include OnEnter and OnLeave scripts to show tooltips for the items being tracked.22 If these scripts are not implemented with extreme care, they can taint the GameTooltip object itself.

The tooltip system fails through three primary vectors:

1. **Insecure Anchoring:** If an AddOn calls GameTooltip:SetOwner(frame, anchor), and frame is a tainted AddOn frame, the tooltip's ownership state becomes tainted.1 This prevents the tooltip from being used by other secure frames until it is cleared.  
2. **Protected Path Intersection:** Blizzard's secure code (e.g., the Encounter Journal or the Quest Log) also calls GameTooltip:SetOwner. If these secure calls occur while the execution path is already tainted—perhaps because the player is in combat and the Objective Tracker is trying to update a tainted module—the call fails.1  
3. **The "Invisible" Symptom:** When a protected function like GameTooltip:Show() is called from a tainted path, the engine may silently block the action to prevent a security breach.1 To the player, this appears as tooltips simply "failing to appear" or becoming stuck with old data.6

### **Secret Values and the Evolution of UI Security**

With the release of the Dragonflight and The War Within expansions, Blizzard introduced "Secret Values"—a mechanism that further restricts how AddOns can interact with internal Lua values.23 Certain fields, such as those related to currency or group finder status (e.g., autoAccept), are now obfuscated.24 If an AddOn attempts to perform a boolean test on a secret value (e.g., if someBlizzardField then), the execution environment will trigger a security violation and crash the script thread, often leading to the total failure of the tooltip system which frequently polls these values for display.24

The following table categorizes the evolution of security changes that impact tooltip stability and tracker integration.

| WoW Version | Key Security Change | Primary Impact on Tooltips and Tracker |
| :---- | :---- | :---- |
| Pre-Dragonflight | Basic Taint Model | Taint prevented protected actions in combat; simple hooks were viable.1 |
| Dragonflight (10.0) | Edit Mode Integration | Frames anchored to the tracker inherit complex taint from the Edit Mode manager.5 |
| The War Within (11.0) | Secret Values | Boolean checks on obfuscated Blizzard data cause immediate script errors and tooltip failures.23 |
| Midnight (12.0) | Secret Obfuscation | Enhanced protection of unit health and status values complicates unit-based tracking.25 |

## **The Adventure Journal as a Taint Entry Point**

The user's AddOn specifically integrates with the Adventure Journal (Encounter Journal) to select items for the wishlist.27 The Adventure Journal is a heavily protected Blizzard AddOn (Blizzard\_EncounterJournal).28 Interaction with this journal is a common source of taint, as it relies on complex templates like EJButtonTemplate which have undergone significant architectural changes in recent patches.29

### **Interaction Risks in the Encounter Journal**

When an AddOn hooks into the journal—perhaps by adding a custom "Track this item" button to the loot tab—it risks tainting the journal's internal logic.28 If the journal becomes tainted, it can no longer safely perform protected actions, such as opening the world map to a boss location or displaying specific loot tooltips in combat.8 Furthermore, the Encounter Journal is often used as a parent or anchor for other frames. If the journal is tainted, that taint propagates to any frame anchored to it, which may include components of the Objective Tracker if the player has both windows open.1

The "Action Forbidden" errors mentioned by the user often occur when a tainted journal tries to execute a secure call, such as EncounterJournal\_OpenJournal(). This is because the execution path initiated by the player clicking a button has been contaminated by the AddOn's code, rendering the subsequent Blizzard code unable to access protected functions.6

## **Forensic Analysis: Identifying Insecure Call Paths**

To isolate the specific call path causing the failure, a developer must move beyond standard Lua error messages and utilize the internal taint.log.30 Standard error handlers (like BugGrabber) are often unable to identify the root cause of taint because the error only occurs when Blizzard's code tries to run, not when the AddOn's code runs.8

### **Diagnostic Methodologies for UI Taint**

The internal logging system can be enabled via console commands:

Lua

/console taintLog 1  \-- Logs basic taint transitions  
/console taintLog 2  \-- Detailed log including full stack traces for every taint event

After enabling the log and reproducing the error—typically by entering combat and hovering over an item—the developer must examine the Logs/taint.log file.8 A typical entry might look like this:

12/3 17:42:31.511 Global variable OBJECTIVE\_TRACKER\_UPDATE\_REASON tainted by Wholly \- Interface/AddOns/Blizzard\_ObjectiveTracker/Blizzard\_ObjectiveTracker.lua:1408 ObjectiveTracker\_Update() 9

This log indicates that the variable OBJECTIVE\_TRACKER\_UPDATE\_REASON became tainted at line 1408 of the Blizzard code because the AddOn "Wholly" was active in the call stack.9 The "taste test" performed by the engine correctly identifies the AddOn responsible for the "flavor of honey" found on the secure variable.1 In the user's case, the log would likely point to a similar line in the Objective Tracker manager where the Loot Wishlist module is being updated.

### **The Problem of Chain Contamination**

A significant challenge in taint diagnostics is that taint can chain through shared libraries or global variables.30 If the Loot Wishlist uses a library like Ace3, and that library has been tainted by another AddOn, the Wishlist will appear to be the source of the taint in the log even if it is not the original culprit.8 This is why a "Divide and Conquer" approach is necessary: disabling half of the active AddOns to see if the error persists, then narrowing it down to the minimal set of AddOns required to trigger the failure.5

## **Strategic Remediation: Secure Integration Patterns**

To maintain integration with the Objective Tracker while preventing taint, the AddOn must avoid "touching" the Blizzard execution path directly. The goal is to create a "firewall" between the AddOn's tainted logic and Blizzard's secure updates.

### **Strategy 1: The Side-Car Frame (Appender Pattern)**

Instead of registering a module using Blizzard's AddModule API, the AddOn should create its own independent frame and anchor it relative to the Objective Tracker.4 This is the most robust method used by high-end AddOns like World Quest Tracker.4

* **Mechanism:** Create a standard Lua frame for the Wishlist and register for game events independently.  
* **Anchoring:** Use a post-hook on the tracker's positioning logic to ensure the Wishlist always stays below the last Blizzard module.4  
* **Isolation:** Since the frame is not part of the MODULES table, Blizzard's ObjectiveTracker\_Update loop never calls into the AddOn's code. The AddOn manages its own updates based on events like LOOT\_READY or ENCOUNTER\_START.4  
* **Result:** The tracker remains secure, the wishlist is visible, and no "Action Forbidden" errors occur because the call paths are entirely separate.4

### **Strategy 2: Secure Call and Post-Hooking**

If the AddOn must interact with Blizzard functions, it should use hooksecurefunc instead of overwriting them.1

Lua

\-- Correct way to monitor updates without spreading taint  
hooksecurefunc("ObjectiveTracker\_Update", function(reason)  
    \-- This code runs AFTER Blizzard's secure update.  
    \-- It can check the state of the wishlist and update its own frames.  
    \-- Taint introduced here is discarded when this function ends.  
end)

The hooksecurefunc API is unique because it executes the AddOn's code after the original function has finished, and it does so with the taint that was present at the time the hook was created, effectively discarding any new taint before returning to the secure environment.3

### **Strategy 3: Safe Visibility and Scaling**

Many AddOns break the Objective Tracker by calling frame:Hide() or frame:Show() during combat.12 These are protected actions.12 Instead, AddOns should use alpha or scale manipulation, which are generally not protected.12

| Action | Security Status | Recommended Alternative for AddOns |
| :---- | :---- | :---- |
| frame:Hide() | Protected (Combat Lockdown) | frame:SetAlpha(0) 12 |
| frame:Show() | Protected (Combat Lockdown) | frame:SetAlpha(1) |
| frame:SetParent() | Protected | Setup during PLAYER\_ENTERING\_WORLD or out-of-combat |
| frame:SetPoint() | Protected | Use SetScale(0.001) to effectively "hide" the frame 18 |

Applying a scale of ![][image1] renders the frame invisible and non-interactive without triggering the secure frame's protection against visibility changes.18 This is a "kludge," but it is often necessary when dealing with frames that Blizzard's code insists on showing automatically.33

## **Implementation Guide for a Taint-Free Loot Wishlist**

Based on the research, the Loot Wishlist AddOn's current implementation likely fails because it is injecting its logic directly into the ObjectiveTrackerFrame's internal update cycle via the Module API. To fix this while keeping the "integrated" look, the following architecture is recommended.

### **Phase 1: Decoupling from the Blizzard Module Manager**

The AddOn should stop using ObjectiveTrackerFrame:AddModule. Instead, it should listen for ENCOUNTER\_LOOT\_RECEIVED or manual selection events from the Adventure Journal and manage its own data table.27 The Wishlist display should be a separate frame that anchors itself to the bottom of the ObjectiveTrackerFrame.BlocksFrame.4

### **Phase 2: Secure Tooltip Implementation**

To resolve the issue where tooltips become invisible, the AddOn must ensure it is not tainting the GameTooltip. This is achieved by:

1. **Clearing Ownership:** Always calling GameTooltip:Hide() before changing owners.  
2. **Using Default Anchors:** Utilizing GameTooltip\_SetDefaultAnchor(GameTooltip, UIParent) to ensure the tooltip is initialized in a clean state.22  
3. **Avoiding Secret Value Checks:** Auditing the code for boolean tests on Blizzard's internal fields.24 Use issecurevariable(ObjectiveTrackerFrame, "field") to verify state safely.1

### **Phase 3: Implementing the Secure Appender Pattern**

The AddOn should use the "Appender Pattern" to position its frame. This involves creating a container frame that monitors the position and height of the Blizzard tracker and adjusts its own position accordingly.4

Lua

local WishlistFrame \= CreateFrame("Frame", "MyLootWishlist", UIParent)  
WishlistFrame:SetPoint("TOPLEFT", ObjectiveTrackerFrame.BlocksFrame, "BOTTOMLEFT", 0, \-10)

\-- Re-anchor whenever the tracker updates to maintain the "integrated" look  
hooksecurefunc(ObjectiveTrackerFrame, "Update", function(self)  
    \-- This runs after Blizzard is done, preventing taint propagation  
    \-- Calculate the new bottom of the Blizzard tracker and move Wishlist there  
    local lastModule \= self:GetLastVisibleModule()  
    if lastModule then  
        WishlistFrame:SetPoint("TOPLEFT", lastModule.Header, "BOTTOMLEFT", 0, \-10)  
    end  
end)

This ensures that the Wishlist *appears* to be part of the Objective Tracker to the player, but to the game engine, it is an entirely independent entity that cannot spread taint to the tracker's secure update logic or the item tooltips.4

## **Summary of Findings and Recommendations**

The disruption of item tooltips and the generation of "Action Forbidden" errors in the Loot Wishlist AddOn are not caused by the tooltip code itself, but by the structural contamination of the Objective Tracker's execution path.8 By registering as a module, the AddOn forces Blizzard's secure manager to run tainted code, which then "sticks" to the GameTooltip and other protected frames.1

The primary recommendation for a fix that keeps the Objective Tracker integration is to move away from the AddModule API and instead adopt an "Anchored Side-Car" architecture.4 This allows the wishlist to visually align with game objectives while remaining programmatically isolated.4 Furthermore, auditing the codebase for direct manipulations of Blizzard's secure variables and replacing them with issecurevariable checks will ensure compatibility with the Secret Value protections introduced in the latest expansions.23 By implementing these changes, the AddOn will achieve a seamless integration that respects the game's security boundaries, restoring the functionality of item tooltips and providing a stable user experience.

#### **Works cited**

1. Secure Execution and Tainting \- Warcraft Wiki, accessed on March 14, 2026, [https://warcraft.wiki.gg/wiki/Secure\_Execution\_and\_Tainting](https://warcraft.wiki.gg/wiki/Secure_Execution_and_Tainting)  
2. Secure Execution and Tainting \- Wowpedia \- Your wiki guide to the World of Warcraft, accessed on March 14, 2026, [https://wowpedia.fandom.com/wiki/Secure\_Execution\_and\_Tainting](https://wowpedia.fandom.com/wiki/Secure_Execution_and_Tainting)  
3. WoW:Secure Execution and Tainting \- AddOn Studio, accessed on March 14, 2026, [https://addonstudio.org/wiki/WoW:Secure\_Execution\_and\_Tainting](https://addonstudio.org/wiki/WoW:Secure_Execution_and_Tainting)  
4. Objective Tracker Adjustment \- UI and Macro \- World of Warcraft Forums, accessed on March 14, 2026, [https://us.forums.blizzard.com/en/wow/t/objective-tracker-adjustment/1889498](https://us.forums.blizzard.com/en/wow/t/objective-tracker-adjustment/1889498)  
5. Is anybody else getting messages like this constantly? It prevents me from using abilities seemingly at random until I reload : r/wow \- Reddit, accessed on March 14, 2026, [https://www.reddit.com/r/wow/comments/znd7zl/is\_anybody\_else\_getting\_messages\_like\_this/](https://www.reddit.com/r/wow/comments/znd7zl/is_anybody_else_getting_messages_like_this/)  
6. BetterFriendlist \- v2.3.1 \- World of Warcraft Addons \- CurseForge, accessed on March 14, 2026, [https://www.curseforge.com/wow/addons/betterfriendlist/files/7603534](https://www.curseforge.com/wow/addons/betterfriendlist/files/7603534)  
7. BetterFriendlist \- v2.3.6 \- World of Warcraft Addons \- CurseForge, accessed on March 14, 2026, [https://www.curseforge.com/wow/addons/betterfriendlist/files/7624112](https://www.curseforge.com/wow/addons/betterfriendlist/files/7624112)  
8. Has anyone figured out a solution to this problem with Blizzard's UI? This $%\!+ is driving me insane : r/wow \- Reddit, accessed on March 14, 2026, [https://www.reddit.com/r/wow/comments/17b5x7n/has\_anyone\_figured\_out\_a\_solution\_to\_this\_problem/](https://www.reddit.com/r/wow/comments/17b5x7n/has_anyone_figured_out_a_solution_to_this_problem/)  
9. UI Taint I cannot figure out \- UI and Macro \- Blizzard Forums, accessed on March 14, 2026, [https://us.forums.blizzard.com/en/wow/t/ui-taint-i-cannot-figure-out/1429263](https://us.forums.blizzard.com/en/wow/t/ui-taint-i-cannot-figure-out/1429263)  
10. \[TBC\] Raid frames taint · Issue \#2936 \- GitHub, accessed on March 14, 2026, [https://github.com/Questie/Questie/issues/2936](https://github.com/Questie/Questie/issues/2936)  
11. Secure Execution and Tainting \- Wowpedia \- Your wiki guide to the ..., accessed on March 14, 2026, [https://wowpedia.fandom.com/wiki/Taint](https://wowpedia.fandom.com/wiki/Taint)  
12. API IfMouseIsOver Question \- UI and Macro \- World of Warcraft Forums, accessed on March 14, 2026, [https://us.forums.blizzard.com/en/wow/t/api-ifmouseisover-question/841367](https://us.forums.blizzard.com/en/wow/t/api-ifmouseisover-question/841367)  
13. EskaTracker : Objectives \- World of Warcraft Addons \- CurseForge, accessed on March 14, 2026, [https://www.curseforge.com/wow/addons/eskatracker-objectives](https://www.curseforge.com/wow/addons/eskatracker-objectives)  
14. Can't move objective Tracker \- Bug Report \- World of Warcraft Forums, accessed on March 14, 2026, [https://us.forums.blizzard.com/en/wow/t/cant-move-objective-tracker/2256472](https://us.forums.blizzard.com/en/wow/t/cant-move-objective-tracker/2256472)  
15. BlizzardInterfaceCode/Interface/AddOns ... \- GitHub, accessed on March 14, 2026, [https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/AddOns/Blizzard\_ObjectiveTracker/Blizzard\_ObjectiveTracker.lua](https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_ObjectiveTracker.lua)  
16. BlizzardInterfaceCode/Interface/AddOns/Blizzard\_ObjectiveTracker/Blizzard\_QuestObjectiveTracker.lua at master \- GitHub, accessed on March 14, 2026, [https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/AddOns/Blizzard\_ObjectiveTracker/Blizzard\_QuestObjectiveTracker.lua](https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_QuestObjectiveTracker.lua)  
17. Can't work out how to make an addon : r/wowaddons \- Reddit, accessed on March 14, 2026, [https://www.reddit.com/r/wowaddons/comments/18w22l1/cant\_work\_out\_how\_to\_make\_an\_addon/](https://www.reddit.com/r/wowaddons/comments/18w22l1/cant_work_out_how_to_make_an_addon/)  
18. I've made an addon to remove visual clutter from objective tracker : r/wowaddons \- Reddit, accessed on March 14, 2026, [https://www.reddit.com/r/wowaddons/comments/1pvg8qt/ive\_made\_an\_addon\_to\_remove\_visual\_clutter\_from/](https://www.reddit.com/r/wowaddons/comments/1pvg8qt/ive_made_an_addon_to_remove_visual_clutter_from/)  
19. AzeriteUI for Classic \- 3.2.554-RC \- World of Warcraft Addons \- CurseForge, accessed on March 14, 2026, [https://www.curseforge.com/wow/addons/azeriteui5/files/3972587](https://www.curseforge.com/wow/addons/azeriteui5/files/3972587)  
20. You should really disable or update those internal addons, Blizzard\! : r/wow \- Reddit, accessed on March 14, 2026, [https://www.reddit.com/r/wow/comments/1qmf4th/you\_should\_really\_disable\_or\_update\_those/](https://www.reddit.com/r/wow/comments/1qmf4th/you_should_really_disable_or_update_those/)  
21. Why do I keep getting that with a few different addons? they are preventing me from casting from the action bars? : r/wow \- Reddit, accessed on March 14, 2026, [https://www.reddit.com/r/wow/comments/18okidl/why\_do\_i\_keep\_getting\_that\_with\_a\_few\_different/](https://www.reddit.com/r/wow/comments/18okidl/why_do_i_keep_getting_that_with_a_few_different/)  
22. arena frame status text macro \- WoWInterface, accessed on March 14, 2026, [https://parcheesi4.rssing.com/chan-3778692/all\_p615.html](https://parcheesi4.rssing.com/chan-3778692/all_p615.html)  
23. Patch 12.0.0/API changes \- Warcraft Wiki \- Your wiki guide to the World of Warcraft, accessed on March 14, 2026, [https://warcraft.wiki.gg/wiki/Patch\_12.0.0/API\_changes](https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes)  
24. BetterFriendlist \- v2.3.3 \- World of Warcraft Addons \- CurseForge, accessed on March 14, 2026, [https://www.curseforge.com/wow/addons/betterfriendlist/files/7611317](https://www.curseforge.com/wow/addons/betterfriendlist/files/7611317)  
25. Development clarification: Maintaining UI accuracy vs. "Secret Value" obfuscation in Midnight \- Blizzard Forums, accessed on March 14, 2026, [https://us.forums.blizzard.com/en/wow/t/development-clarification-maintaining-ui-accuracy-vs-secret-value-obfuscation-in-midnight/2243547](https://us.forums.blizzard.com/en/wow/t/development-clarification-maintaining-ui-accuracy-vs-secret-value-obfuscation-in-midnight/2243547)  
26. BetterFriendlist \- v2.3.9 \- World of Warcraft Addons \- CurseForge, accessed on March 14, 2026, [https://www.curseforge.com/wow/addons/betterfriendlist/files/7649681](https://www.curseforge.com/wow/addons/betterfriendlist/files/7649681)  
27. Getting started with the WoW API \- Blizzard Forums, accessed on March 14, 2026, [https://us.forums.blizzard.com/en/blizzard/t/getting-started-with-the-wow-api/12097](https://us.forums.blizzard.com/en/blizzard/t/getting-started-with-the-wow-api/12097)  
28. Aurora \- 12.0.0.1 \- World of Warcraft Addons \- CurseForge, accessed on March 14, 2026, [https://www.curseforge.com/wow/addons/aurora/files/7538918](https://www.curseforge.com/wow/addons/aurora/files/7538918)  
29. Aurora \- 11.2.0.5 \- World of Warcraft Addons \- CurseForge, accessed on March 14, 2026, [https://www.curseforge.com/wow/addons/aurora/files/6880410](https://www.curseforge.com/wow/addons/aurora/files/6880410)  
30. Compactframe Error Taint Issue? \- UI and Macro \- World of Warcraft Forums, accessed on March 14, 2026, [https://us.forums.blizzard.com/en/wow/t/compactframe-error-taint-issue/1211498](https://us.forums.blizzard.com/en/wow/t/compactframe-error-taint-issue/1211498)  
31. Hide Objective Tracker \- World of Warcraft Addons \- CurseForge, accessed on March 14, 2026, [https://www.curseforge.com/wow/addons/hideobjectivetracker](https://www.curseforge.com/wow/addons/hideobjectivetracker)  
32. Script Help \- UI and Macro \- World of Warcraft Forums, accessed on March 14, 2026, [https://us.forums.blizzard.com/en/wow/t/script-help/870242](https://us.forums.blizzard.com/en/wow/t/script-help/870242)  
33. ObjectiveTrackerFrame : r/wowaddons \- Reddit, accessed on March 14, 2026, [https://www.reddit.com/r/wowaddons/comments/1f91lc0/objectivetrackerframe/](https://www.reddit.com/r/wowaddons/comments/1f91lc0/objectivetrackerframe/)  
34. Midnight Objective Tracker \- World of Warcraft Addons \- CurseForge, accessed on March 14, 2026, [https://www.curseforge.com/wow/addons/midnight-objective-tracker](https://www.curseforge.com/wow/addons/midnight-objective-tracker)

[image1]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACwAAAAXCAYAAABwOa1vAAACY0lEQVR4Xu2WTUgWQRzGn6jAqIwwkD6glCi8BVESWHTokEgRFSIVdErBS+AhIZAO4qVDkAeFiKJDVNJVETpU1CHo5MEEQfqgDwr0pEEG5fP433FnZ5tV3ksR+4Mf77uzM7vPvjM7/xcoKfl/WEfP0Vv0Ot2bPV1INb0MG9tDt2ZPL7KKNtJ+OkBb6OpMjxS1t9JdQfsSm+gT2ks30H30DT3jd4qwk47RS7SKNtNJetDro7BX6HNaR2vofdgDrk366Ac7QW/ST3SO7k/O5eimr+lmr+08naC1XlvIGnqbPk6+O/roKCyE0I2/0qalHkA9fU+PJ8fqq4c9Sq+hILBCKuy9oP0AnaUng3Yf3fQL7IF9TiN7Qz2AwvlLZSN9Qe/CZsBH14sGbqDTyAdWZw3SzWIco7+QD6yp/Q2bJS2TYeQDa+k9Q35mRWFgFywWOGz3ccFigdXugsUCh+2iMLC7eBhsJYF14eUCK4xChcEqDqyFXmngLiwfWC/tFPLBKg4cCxZr9/krS8K96WEwF/hq0O6jbeon4oG1W2i707YXBnOBtVNox/ApDOwG6k3WG+3QDjCffDpUYLYh3Ya203ew6uXTAdt5tAMJBfCPxRY6jvxYURhYXKAfYFVIKJCq3itYSFEDq2g/6KGCfqpcQ/QB0mKym36kbcmxOEy/Ib2WjwJ/h9WCP6KbDNKn9BQshJ5eJdqhmRiBlV2VY4eCqv0R7AW+Q1/SHV4foeXxlrbTi7DS34l0ttbTh3QGtpycn+mNpE8GDdxDz9IjSGv8StCfFU2fxuoz9qdGs6T1LfW9pKTkX2cBJ6aYxBCd5oIAAAAASUVORK5CYII=>