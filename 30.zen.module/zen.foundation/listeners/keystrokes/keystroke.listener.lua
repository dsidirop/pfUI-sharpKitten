﻿local _assert, _setfenv, _type, _getn, _error, _print, _unpack, _pairs, _importer, _namespacer, _setmetatable = (function()
    local _g = assert(_G or getfenv(0))
    local _assert = assert
    local _setfenv = _assert(_g.setfenv)

    _setfenv(1, {})

    local _type = _assert(_g.type)
    local _getn = _assert(_g.table.getn)
    local _error = _assert(_g.error)
    local _print = _assert(_g.print)
    local _pairs = _assert(_g.pairs)
    local _unpack = _assert(_g.unpack)
    local _importer = _assert(_g.pvl_namespacer_get)
    local _namespacer = _assert(_g.pvl_namespacer_add)
    local _setmetatable = _assert(_g.setmetatable)

    return _assert, _setfenv, _type, _getn, _error, _print, _unpack, _pairs, _importer, _namespacer, _setmetatable
end)()

_setfenv(1, {})

local ManagedElementBuilder = _importer("Pavilion.Warcraft.Addons.Zen.Foundation.UI.ManagedElements.Builder")

local Class = _namespacer("Pavilion.Warcraft.Addons.Zen.Foundation.Listeners.Keystrokes.KeystrokesListener")

-- todo   make sure this gets registered as a singleton when dependency-injection comes to town 
function Class:New(managedElementBuilder)
    _setfenv(1, self)

    managedElementBuilder = managedElementBuilder or ManagedElementBuilder:New() -- todo di this

    local instance = {
        _managedSpyFrame = managedElementBuilder:WithTypeFrame()
                                                :WithPropagateKeyboardInput(true)
                                                :WithUseGlobalWowFrameAsParent(true),
    }

    _setmetatable(instance, self)
    self.__index = self

    return instance
end

function Class:EventKeyDown_Subscribe(handler, owner)
    _setfenv(1, self)

    _managedSpyFrame:EventKeyDown_Subscribe(handler, owner)

    return self
end

function Class:EventKeyDown_Unsubscribe(handler)
    _setfenv(1, self)

    _managedSpyFrame:EventKeyDown_Unsubscribe(handler)

    return self
end
