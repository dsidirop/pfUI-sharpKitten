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

local Scopify = _importer("System.Scopify")
local EScopes = _importer("System.EScopes")
local Classify = _importer("System.Class.Classify")

local IsAltKeyDown = _importer("Pavilion.Warcraft.Addons.Zen.Externals.WoW.IsAltKeyDown")
local IsShiftKeyDown = _importer("Pavilion.Warcraft.Addons.Zen.Externals.WoW.IsShiftKeyDown")
local IsControlKeyDown = _importer("Pavilion.Warcraft.Addons.Zen.Externals.WoW.IsControlKeyDown")

local Event = _importer("System.Event")
local Timer = _importer("Pavilion.Warcraft.Addons.Zen.Foundation.Time.Timer")
local ModifierKeysStatusesChangedEventArgs = _importer("Pavilion.Warcraft.Addons.Zen.Foundation.Listeners.ModifiersKeystrokes.EventArgs.ModifierKeysStatusesChangedEventArgs")

local Class = _namespacer("Pavilion.Warcraft.Addons.Zen.Foundation.Listeners.ModifiersKeystrokes.ModifierKeysListener")

function Class:New(timer)
    Scopify(EScopes.Function, self)

    return Classify(self, {
        _timer = timer or Timer:New(0.1), -- todo di this as a singleton when di comes to town

        _wantedActive = false,
        _mustEmitOnFreshStart = false,

        _lastEventArgs = nil,
        _eventModifierKeysStatesChanged = Event:New(),
    })
end

function Class:SetMustEmitOnFreshStart(mustEmitOnFreshStart)
    Scopify(EScopes.Function, self)

    _assert(_type(mustEmitOnFreshStart) == "boolean", "expected a boolean")

    _mustEmitOnFreshStart = mustEmitOnFreshStart

    return self
end

function Class:ChainSetPollingInterval(interval)
    Scopify(EScopes.Function, self)

    _assert(_type(interval) == "number" and interval > 0, "interval must be a positive number")

    _timer:ChainSetInterval(interval)

    return self
end

function Class:Start()
    Scopify(EScopes.Function, self)

    _wantedActive = true --       order
    self:OnSettingsChanged_() --  order

    return self
end

function Class:Stop()
    Scopify(EScopes.Function, self)

    _wantedActive = false --       order
    self:OnSettingsChanged_() --   order

    return self
end

function Class:EventModifierKeysStatesChanged_Subscribe(handler, owner)
    Scopify(EScopes.Function, self)

    _eventModifierKeysStatesChanged:Subscribe(handler, owner) --  order
    self:OnSettingsChanged_() --                                  order

    return self
end

function Class:EventModifierKeysStatesChanged_Unsubscribe(handler)
    Scopify(EScopes.Function, self)

    _eventModifierKeysStatesChanged:Unsubscribe(handler) --     order
    self:OnSettingsChanged_() --                                order

    return self
end

Class.I = Class:New() -- singleton   todo  remove this once di becomes available


-- private space

Class.ModifierKeysStatusesChangedEventArgsCache_ = (function() --@formatter:off
    local function add(cache_, alt_, shift_, control_)
        cache_[alt_]                   = cache_[alt_]                   or {}
        cache_[alt_][shift_]           = cache_[alt_][shift_]           or {}
        cache_[alt_][shift_][control_] = cache_[alt_][shift_][control_] or ModifierKeysStatusesChangedEventArgs:New(alt_, shift_, control_)
    end
    
    local cache = {}
    add( cache, false , false , false )
    add( cache, true  , false , false )
    add( cache, false , true  , false )
    add( cache, false , false , true  )
    add( cache, true  , true  , false )
    add( cache, true  , false , true  )
    add( cache, false , true  , true  )
    add( cache, true  , true  , true  )

    return cache --@formatter:on
end)()

Class.EmptyModifierKeysStatusesChangedEventArgs_ = Class.ModifierKeysStatusesChangedEventArgsCache_[false][false][false]

function Class:OnSettingsChanged_()
    Scopify(EScopes.Function, self)

    if _wantedActive and _eventModifierKeysStatesChanged:HasSubscribers() then
        if _timer:IsRunning() then
            return
        end
        
        _timer:EventElapsed_Subscribe(self.Timer_Elapsed_, self)
        _timer:Start()

        if _mustEmitOnFreshStart then
            self:Timer_Elapsed_(nil, nil)
        end        
        return
    end

    do
        -- wantedActive==false  or  wantedActive==true but noone is listening   so we need to halt the timer
        _timer:Stop()
        _lastEventArgsEmitted = Class.EmptyModifierKeysStatusesChangedEventArgs_
    end

    return self
end

function Class:Timer_Elapsed_(_, _)
    Scopify(EScopes.Function, self)

    --@formatter:off
    local isAltKeyDown     = IsAltKeyDown()
    local isShiftKeyDown   = IsShiftKeyDown()
    local isControlKeyDown = IsControlKeyDown()

    if     _lastEventArgsEmitted:HasModifierAlt()     == isAltKeyDown
       and _lastEventArgsEmitted:HasModifierShift()   == isShiftKeyDown
       and _lastEventArgsEmitted:HasModifierControl() == isControlKeyDown then
        return
    end

    _lastEventArgsEmitted = Class.ModifierKeysStatusesChangedEventArgsCache_[isAltKeyDown][isShiftKeyDown][isControlKeyDown]
    _eventModifierKeysStatesChanged:Raise(self, _lastEventArgsEmitted)

    if not _eventModifierKeysStatesChanged:HasSubscribers() then
        self:OnSettingsChanged_() --00
    end

    --@formatter:on
    --00  if the event handlers are ephimeral we might end up with no handlers in which case we have to stop the timer for the sake of efficiency 
end
