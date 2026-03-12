I have found out that the tooltip is (possibly) not part of the taint issues...
After removing the tooltip, the taint still happens.
I have rolledback to having tooltip as a new independent frame.

The taint is maybe due to adding lines to a native block in the Objective tracker, and possibly caused by adding a frame to the loot roll frame, or even popping up the loot alert. When Opus is back, I need to pass the Blizzard's source code and ask these questions to find the culprit.
