﻿local _setfenv, _importer, _tryimport, _namespacer = (function()
    local _g = assert(_G or getfenv(0))
    local _assert = assert
    local _setfenv = _assert(_g.setfenv)
    _setfenv(1, {})

    local _importer = _assert(_g.pvl_namespacer_get)
    local _tryimport = _assert(_g.pvl_namespacer_tryget)
    local _namespacer = _assert(_g.pvl_namespacer_add)
    
    return _setfenv, _importer, _tryimport, _namespacer
end)()

_setfenv(1, {}) --                                                                 @formatter:off

local Scopify            = _importer("System.Scopify")
local EScopes            = _importer("System.EScopes")
local Classify           = _importer("System.Classify")
local Reflection         = _importer("System.Reflection")

local Exception          = _importer("System.Exceptions.Exception")
local StringsHelper      = _importer("System.Helpers.Strings") --                  @formatter:on

local Class = _namespacer("System.Try.ExceptionsDeserializationFactory")

function Class:New()
    return Classify(self)
end

function Class:DeserializeFromRawExceptionMessage(rawExceptionMessage)
    Scopify(EScopes.Function, self)

    if rawExceptionMessage == nil then -- shouldnt happen but just in case
        return Exception:New("(exception message not available)")
    end
    
    if not Reflection.IsString(rawExceptionMessage) then -- shouldnt happen but just in case
        return Exception:New(StringsHelper.Stringify(rawExceptionMessage))
    end

    rawExceptionMessage = StringsHelper.Trim(rawExceptionMessage)
    
    local stacktrace = self.ParseStacktraceString_(rawExceptionMessage)
    local message, exceptionType = self.ParseExceptionMessageHeader_(rawExceptionMessage)
    
    return exceptionType:New()
                        :ChainSetMessage(message)
                        :ChainSetStacktrace(stacktrace)
end

-- private space
function Class.ParseExceptionMessageHeader_(rawExceptionMessage)
    Scopify(EScopes.Function, Class)

    local firstLine = StringsHelper.Split(rawExceptionMessage, "\n", 1)[1]

    local exceptionNamespaceString = StringsHelper.Match(firstLine, ": %[([.%w%d]+)] ") -- 00

    local message = StringsHelper.Match(firstLine, ":[%s]*([%s%S]+)$") or firstLine -- 10
    message = StringsHelper.Match(message, "%[[.%w%d]+] ([%s%S]+)$") -- 20

    local exceptionType = _tryimport(exceptionNamespaceString) or Exception

    return message, exceptionType

    -- 00   foo/bar/baz.lua:123: [Some.Namespace.To.XYZException] Blah blah exception message -> Some.Namespace.To.XYZException 
    -- 10   foo/bar/baz.lua:123: [Some.Namespace.To.XYZException] Blah blah exception message -> [Some.Namespace.To.XYZException] Blah blah exception message
    -- 20   [Some.Namespace.To.XYZException] Blah blah exception message                      -> Blah blah exception message 
end

function Class.ParseStacktraceString_(rawExceptionMessage)
    Scopify(EScopes.Function, Class)

    rawExceptionMessage = StringsHelper.Trim(rawExceptionMessage)
    
    local stacktrace = StringsHelper.Match(rawExceptionMessage, "^[^\n]+\n([%s%S]+)") or rawExceptionMessage -- yank off the first line
    stacktrace = StringsHelper.Trim(stacktrace)
    
    local trimmedStacktrace = StringsHelper.Match(stacktrace, "^[^\n]*----\n([%s%S]+\n)----[%s%S]*$") or stacktrace -- 00
    trimmedStacktrace = StringsHelper.Trim(trimmedStacktrace) .. "\n"

    return trimmedStacktrace

    -- 00   \n------stacktrace------\n    the_actual_stacktrace   \n------end stacktrace------\n -> the_actual_stacktrace 
end
