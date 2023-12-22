﻿local _assert, _setfenv, _type, _pairs, _print, _importer, _debugstack, _namespacer, _setmetatable = (function()
    local _g = assert(_G or getfenv(0))
    local _assert = assert
    local _setfenv = _assert(_g.setfenv)
    _setfenv(1, {})

    local _type = _assert(_g.type)
    local _pairs = _assert(_g.pairs)
    local _print = _assert(_g.print)
    local _importer = _assert(_g.pvl_namespacer_get)
    local _debugstack = _assert(_g.debugstack)
    local _namespacer = _assert(_g.pvl_namespacer_add)
    local _setmetatable = _assert(_g.setmetatable)
    
    return _assert, _setfenv, _type, _pairs, _print, _importer, _debugstack, _namespacer, _setmetatable
end)()

_setfenv(1, {})

local Scopify = _importer("System.Scopify")
local EScopes = _importer("System.EScopes")
local Classify = _importer("System.Classify")

local TablesHelper = _importer("System.Helpers.Tables")

local Class = _namespacer("System.Event")

function Class:New()
    Scopify(EScopes.Function, self)

    return Classify(self, {
        _handlers = {},
        _handlersJustOnce = {}
    })
end

local NoOwner = {}
function Class:Subscribe(handler, owner)
    Scopify(EScopes.Function, self)

    _assert(_type(handler) == "function")
    _assert(owner == nil or _type(owner) == "table")

    _handlers[handler] = owner or NoOwner -- we prevent double-subscriptions by using the handler itself as the key
    
    return self
end

function Class:SubscribeOnce(handler, owner)
    Scopify(EScopes.Function, self)
    _assert(_type(handler) == "function")
    _assert(owner == nil or _type(owner) == "table")

    self:Subscribe(handler, owner)
    self:SubscribeOnceImpl_(handler, owner)

    return self
end

function Class:HasSubscribers()
    Scopify(EScopes.Function, self)
    
    return TablesHelper.AnyOrNil(_handlers) 
end

function Class:SubscribeOnceImpl_(handler, owner)
    Scopify(EScopes.Function, self)

    _assert(_type(handler) == "function")
    _assert(owner == nil or _type(owner) == "table")

    _handlersJustOnce[handler] = owner or NoOwner

    return self
end

function Class:Unsubscribe(handler)
    Scopify(EScopes.Function, self)

    _assert(_type(handler) == "function", _debugstack())

    _handlers[handler] = nil
    _handlersJustOnce[handler] = nil

    return self
end

function Class:Clear()
    Scopify(EScopes.Function, self)

    _handlers = {}
    _handlersJustOnce = {}

    return self
end

function Class:Fire(sender, eventArgs)
    Scopify(EScopes.Function, self)

    _assert(sender)
    _assert(eventArgs)

    self:Raise(sender, eventArgs)

    return self -- 00
    
    -- 00  the return value is the difference between :fire() and :raise()   the :raise() flavour returns
    --     the eventArgs   while the :fire() flavour returns the event object itself for further chaining
end

function Class:Raise(sender, eventArgs)
    Scopify(EScopes.Function, self)

    _assert(sender)
    _assert(eventArgs)

    for k, v in TablesHelper.GetKeyValuePairs(_handlers) do
        if v and v ~= NoOwner then -- v is the owning class-instance of the handler
            k(v, sender, eventArgs)
        else
            k(sender, eventArgs)
        end
    end

    for _, v in TablesHelper.GetKeyValuePairs(_handlersJustOnce) do
        _handlers[v] = nil -- rip off the handler
    end

    _handlersJustOnce = {} -- and finally reset the just-once handlers

    return eventArgs
end