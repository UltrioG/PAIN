# Basalt

This is the UI Manager and the first thing you want to access.
Before you can access Basalt, you need to add the following code on top of your file:

```lua
local basalt = require("basalt")
```

What this code does is it loads basalt into the basalt variable.
You are now able to access the following list of methods:

|   |   |
|---|---|
|[autoUpdate](objects/Basalt/autoUpdate.md)|Starts the event and draw listener
|[createFrame](objects/Basalt/createFrame.md)|Creates a new base frame
|[debug](objects/Basalt/debug.md)|Writes something into the debug console
|[getFrame](objects/Basalt/getFrame.md)|Returns a frame object by it's id
|[getActiveFrame](objects/Basalt/getActiveFrame.md)|Returns the currently active base frame
|[getTheme](objects/Basalt/getTheme.md)|Returns the currently active theme
|[getVariable](objects/Basalt/getVariable.md)|Returns a variable defined with setVariable
|[getVersion](objects/Basalt/getVersion.md)|Returns the Basalt version
|[isKeyDown](objects/Basalt/isKeyDown.md)|Returns if the key is held down
|[log](objects/Basalt/log.md)|Writes something into the log file
|[onEvent](objects/Basalt/onEvent.md)|Event listener
|[removeFrame](objects/Basalt/removeFrame.md)|Removes a previously created base frame
|[schedule](objects/Basalt/schedule.md)|Schedules a new task
|[setActiveFrame](objects/Basalt/setActiveFrame.md)|Sets the active frame
|[setTheme](objects/Basalt/setTheme.md)|Changes the base theme of basalt
|[setMouseDragThrottle](objects/Basalt/setMouseDragThrottle.md)|Changes the mouse drag throttle amount
|[setMouseMoveThrottle](objects/Basalt/setMouseMoveThrottle.md)|CraftOS-PC: Changes the mouse move throttle amount
|[setVariable](objects/Basalt/setVariable.md)|Sets a variable which you can access via XML
|[stopUpdate / stop](objects/Basalt/stopUpdate.md)|Stops the currently active event and draw listener
|[update](objects/Basalt/update.md)|Starts the event and draw listener once

## Examples

Here is a lua example on how to create a empty base frame and start basalt's listener.

```lua
local basalt = require("basalt") -- Loads Basalt into our project

local main = basalt.createFrame() -- Creates a base frame. On that frame we are able to add object's

-- Here we would add additional object's

basalt.autoUpdate() -- Starts listening to incoming events and draw stuff on the screen. This should nearly always be the last line.
```
