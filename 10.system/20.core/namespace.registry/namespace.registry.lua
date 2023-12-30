﻿local _g, _assert, _type, _gsub, _pairs, _unpack, _strsub, _strfind, _tostring, _setfenv, _setmetatable = (function()
    local _g = assert(_G or getfenv(0))
    local _assert = assert
    local _setfenv = _assert(_g.setfenv)
    _setfenv(1, {})

    local _type = _assert(_g.type)
    local _gsub = _assert(_g.string.gsub)
    local _pairs = _assert(_g.pairs)
    local _unpack = _assert(_g.unpack)
    local _strsub = _assert(_g.string.sub)
    local _strfind = _assert(_g.string.find)
    local _tostring = _assert(_g.tostring)
    local _setmetatable = _assert(_g.setmetatable)

    return _g, _assert, _type, _gsub, _pairs, _unpack, _strsub, _strfind, _tostring, _setfenv, _setmetatable
end)()

if _g.pvl_namespacer_add then
    return -- already in place
end

_setfenv(1, {})

local ESymbolType = {
    Enum = 0,
    Class = 1, --      for classes declared by this project
    Interface = 2,
    RawSymbol = 3, --  external libraries from third party devs that are given an internal namespace (think of this like C# binding to java or swift libs)
}

local function _strmatch(input, patternString, ...)
    _assert(patternString ~= nil)

    if patternString == "" then
        -- todo  test out these corner cases
        return nil
    end

    local startIndex, endIndex,
    match01,
    match02,
    match03,
    match04,
    match05,
    match06,
    match07,
    match08,
    match09,
    match10,
    match11,
    match12,
    match13,
    match14,
    match15,
    match16,
    match17,
    match18,
    match19,
    match20,
    match21,
    match22,
    match23,
    match24,
    match25 = _strfind(input, patternString, _unpack(arg))

    if startIndex == nil then
        -- no match
        return nil
    end

    if match01 == nil then
        -- matched but without using captures   ("Foo 11 bar   ping pong"):match("Foo %d+ bar")
        return _strsub(input, startIndex, endIndex)
    end

    return -- matched with captures  ("Foo 11 bar   ping pong"):match("Foo (%d+) bar")
    match01,
    match02,
    match03,
    match04,
    match05,
    match06,
    match07,
    match08,
    match09,
    match10,
    match11,
    match12,
    match13,
    match14,
    match15,
    match16,
    match17,
    match18,
    match19,
    match20,
    match21,
    match22,
    match23,
    match24,
    match25
end

local function _strtrim(input)
    return _strmatch(input, '^%s*(.*%S)') or ''
end

local Entry = {}
do
    function Entry:New(symbolType, symbol, isForPartial)
        _setfenv(1, self)

        _assert(symbol ~= nil, "symbol must not be nil\n" .. _g.debugstack(2) .. "\n")
        _assert(isForPartial == nil or _type(isForPartial) == "boolean", "isForPartial must be a boolean or nil (got '" .. _type(isForPartial) .. "')\n" .. _g.debugstack(2) .. "\n")
        _assert(symbolType == ESymbolType.Class or symbolType == ESymbolType.Enum or symbolType == ESymbolType.Interface or symbolType == ESymbolType.RawSymbol, "symbolType must be valid\n" .. _g.debugstack(2) .. "\n")

        local instance = {
            _symbol = symbol,
            _symbolType = symbolType,
            _isForPartial = isForPartial == nil and false or isForPartial,
        }

        _setmetatable(instance, self)
        self.__index = self

        return instance
    end

    function Entry:GetSymbol()
        _setfenv(1, self)

        return _assert(_symbol)
    end

    function Entry:GetSymbolType()
        _setfenv(1, self)

        return _assert(_symbolType)
    end

    function Entry:IsClassEntry()
        _setfenv(1, self)

        return _symbolType == ESymbolType.Class
    end

    function Entry:IsPartialEntry()
        _setfenv(1, self)

        return _isForPartial
    end

    function Entry:IsEnumEntry()
        _setfenv(1, self)

        return _symbolType == ESymbolType.Enum
    end

    function Entry:IsInterfaceEntry()
        _setfenv(1, self)

        return _symbolType == ESymbolType.Interface
    end

    function Entry:IsSupportingPartials()
        _setfenv(1, self)

        return self:IsClassEntry()
                or self:IsEnumEntry()
                or self:IsInterfaceEntry()
                or self:IsPartialEntry()
    end

    function Entry:UpgradeSymbolTypeFromPartialTo(newSymbolType)
        _setfenv(1, self)

        _assert(_isForPartial, "the current entry was supposed to be a partial class but it was not marked as such\n" .. _g.debugstack(3) .. "\n")

        _symbolType = newSymbolType
        return true
    end
end

local NamespaceRegistry = {}
do
    function NamespaceRegistry:New()
        _setfenv(1, self)

        local instance = {
            _namespaces_registry = {},
            _reflection_registry = {},
        }

        _setmetatable(instance, self)
        self.__index = self

        return instance
    end

    -- namespacer()
    local PatternToDetectPartialKeywordPostfix = "%s*%[[Pp]artial%]%s*$"
    function NamespaceRegistry:UpsertSymbol(namespacePath, symbolType)
        _setfenv(1, self)

        _assert(_type(namespacePath) == "string", "namespacePath must be a string\n" .. _g.debugstack(3) .. "\n")
        _assert(symbolType == ESymbolType.Class or symbolType == ESymbolType.Enum or symbolType == ESymbolType.Interface, "symbolType for namespace '" .. namespacePath .. "' must be either ESymbolType.Class or ESymbolType.Enum or ESymbolType.Interface (got '" .. _tostring(symbolType) .. "')\n" .. _g.debugstack(3) .. "\n")
        
        namespacePath = _strtrim(namespacePath)        
        _assert(namespacePath ~= "", "namespacePath must not be dud\n" .. _g.debugstack(3) .. "\n")

        local sanitizedNamespacePath, isForPartial = NamespaceRegistry.SanitizeNamespacePath_(namespacePath) -- remove the [partial] postfix from the namespace path
        
        local preExistingEntry = _namespaces_registry[sanitizedNamespacePath]
        if preExistingEntry == nil then
            local newSymbol = self.SpawnNewSymbol_(symbolType)

            local newEntry = Entry:New(symbolType, newSymbol, isForPartial)

            _namespaces_registry[sanitizedNamespacePath] = newEntry
            _reflection_registry[newSymbol] = sanitizedNamespacePath

            return newSymbol
        end

        _assert(symbolType == preExistingEntry:GetSymbolType(), "cannot register namespace '" .. sanitizedNamespacePath .. "' with type='" .. symbolType .. "' as it has already been assigned to a symbol with type='" .. preExistingEntry:GetSymbolType() .. "'.\n" .. _g.debugstack() .. "\n")
        _assert(isForPartial or preExistingEntry:IsPartialEntry(), "namespace '" .. sanitizedNamespacePath .. "' has already been assigned to a symbol marked as '" .. preExistingEntry:GetSymbolType() .. "' (did you mean to use a partial class?).\n" .. _g.debugstack() .. "\n")

        return preExistingEntry:GetSymbol()

        --00  notice that if the symbolType is to declare an extension-class then we dont care if the class already
        --    exists its also perfectly fine if the the core class gets loaded after its associated extension classes too
    end

    function NamespaceRegistry.SanitizeNamespacePath_(namespacePath)
        _setfenv(1, NamespaceRegistry)

        local sanitized = _gsub(namespacePath, PatternToDetectPartialKeywordPostfix, "") -- remove the [partial] postfix from the namespace path
        local isForPartial = sanitized ~= namespacePath

        return sanitized, isForPartial 
    end

    NamespaceRegistry._StandardClassMetatable = { -- add a shortcut to the default constructor on the class
        __call = function(classSymbol, ...)
            _assert(_type(classSymbol.New) == "function", "Cannot call class() because the default constructor method :New(...) has not been defined on this class!")

            return classSymbol:New(_unpack(arg))
        end
    }
    function NamespaceRegistry.SpawnNewSymbol_(symbolType)
        _setfenv(1, NamespaceRegistry)
        
        if symbolType == ESymbolType.Class then
            return _setmetatable({}, NamespaceRegistry._StandardClassMetatable)
        end

        return {} -- enums, interfaces
    end

    -- used for binding external libs to a local namespace
    --
    --     _namespacer_bind("Pavilion.Warcraft.Addons.Zen.Externals.MTALuaLinq.Enumerable",   _mta_lualinq_enumerable)
    --     _namespacer_bind("Pavilion.Warcraft.Addons.Zen.Externals.ServiceLocators.LibStub", _libstub_service_locator)
    --
    function NamespaceRegistry:Bind(namespacePath, symbol)
        _setfenv(1, self)

        _assert(symbol ~= nil, "symbol must not be nil")
        _assert(namespacePath ~= nil and _type(namespacePath) == "string" and _strtrim(namespacePath) ~= "", "namespacePath must not be dud")

        namespacePath = _strtrim(namespacePath)

        local possiblePreexistingEntry = _namespaces_registry[namespacePath]

        _assert(possiblePreexistingEntry == nil, "namespace '" .. namespacePath .. "' has already been assigned to another symbol.")

        _reflection_registry[symbol] = namespacePath
        _namespaces_registry[namespacePath] = Entry:New(ESymbolType.RawSymbol, symbol)
    end

    function NamespaceRegistry:TryGetSymbolProtoViaNamespace(namespacePath)
        _setfenv(1, self)
        
        if namespacePath == nil then -- we dont want to error out in this case   this is a try-method
            return nil, nil
        end

        local entry = self:GetEntry_(namespacePath)
        if entry == nil then
            return nil, nil
        end
        
        return entry:GetSymbol(), entry:GetSymbolType()
    end

    -- importer()
    function NamespaceRegistry:Get(namespacePath, suppressExceptionIfNotFound)
        _setfenv(1, self)

        local entry = self:GetEntry_(namespacePath)
        if entry == nil and suppressExceptionIfNotFound then
            return nil
        end

        _assert(entry, "namespace '" .. namespacePath .. "' has not been registered.\n" .. _g.debugstack() .. "\n")
        _assert(not entry:IsPartialEntry(), "namespace '" .. namespacePath .. "' holds a partially-registered entry (class/enum/interface) - did you forget to load its core definition?\n" .. _g.debugstack() .. "\n")
        
        return _assert(entry:GetSymbol())
    end

    function NamespaceRegistry:GetEntry_(namespacePath)
        _setfenv(1, self)

        _assert(_type(namespacePath) == "string", "namespacePath must be a string (got '" .. _type(namespacePath) .. "')\n" .. _g.debugstack() .. "\n")

        namespacePath = _strtrim(namespacePath)
        _assert(namespacePath ~= "", "namespacePath must not be dud\n" .. _g.debugstack() .. "\n")

        return _namespaces_registry[namespacePath]
    end

    -- namespace_reflect()   given a registered object it returns the namespace path that was used to register it
    function NamespaceRegistry:TryGetNamespaceOfClassProto(object)
        _setfenv(1, self)

        if object == nil then
            return nil
        end

        return _reflection_registry[object]
    end
end

local NamespaceRegistrySingleton = NamespaceRegistry:New()
do
    -- using()
    _g.pvl_namespacer_get = function(namespacePath)
        --    todo   in production builds these symbols should get obfuscated to something like  _g.ppzcn__<some_guid_here>__get
        return NamespaceRegistrySingleton:Get(namespacePath)
    end

    -- todo   remove these functions below once we migrate our codebase over to the using() scheme

    -- namespacer()
    _g.pvl_namespacer_add = function(namespacePath)
        return NamespaceRegistrySingleton:UpsertSymbol(namespacePath, ESymbolType.Class)
    end

    -- namespacer_binder()
    _g.pvl_namespacer_bind = function(namespacePath, symbol)
        return NamespaceRegistrySingleton:Bind(namespacePath, symbol)
    end

    -- importer()
    _g.pvl_namespacer_tryload = function(namespacePath)
        return NamespaceRegistrySingleton:TryGetSymbolProtoViaNamespace(namespacePath)
    end

    _g.pvl_namespacer_reflect = function(instanceType)
        return NamespaceRegistrySingleton:TryGetNamespaceOfClassProto(instanceType)
    end
end

-- @formatter:off
NamespaceRegistrySingleton:Bind("System.Importing.Using",                         function(namespacePath        ) return NamespaceRegistrySingleton:Get                           (namespacePath        ) end) -- not really being used anywhere but its nice to have
NamespaceRegistrySingleton:Bind("System.Importing.TryGetSymbolProtoViaNamespace", function(namespacePath        ) return NamespaceRegistrySingleton:TryGetSymbolProtoViaNamespace (namespacePath        ) end)

NamespaceRegistrySingleton:Bind("System.Namespacing.Binder",                      function(namespacePath, symbol) return NamespaceRegistrySingleton:Bind                          (namespacePath, symbol) end)
NamespaceRegistrySingleton:Bind("System.Namespacing.TryGetNamespaceOfClassProto", function(classProto           ) return NamespaceRegistrySingleton:TryGetNamespaceOfClassProto   (classProto           ) end)

NamespaceRegistrySingleton:Bind("[declare]",                                      function(namespacePath        ) return NamespaceRegistrySingleton:UpsertSymbol                  (namespacePath, ESymbolType.Class    ) end)
NamespaceRegistrySingleton:Bind("[declare:class]",                                function(namespacePath        ) return NamespaceRegistrySingleton:UpsertSymbol                  (namespacePath, ESymbolType.Class    ) end)

NamespaceRegistrySingleton:Bind("[declare:enum]",                                 function(namespacePath        ) return NamespaceRegistrySingleton:UpsertSymbol                  (namespacePath, ESymbolType.Enum     ) end)
NamespaceRegistrySingleton:Bind("[declare:interface]",                            function(namespacePath        ) return NamespaceRegistrySingleton:UpsertSymbol                  (namespacePath, ESymbolType.Interface) end)
-- @formatter:on

local advertisedESymbolType = NamespaceRegistrySingleton:UpsertSymbol("System.Namespacing.ESymbolType", ESymbolType.Enum)
for k, v in _pairs(ESymbolType) do -- this is the only way to get the enum values to be advertised to the outside world
    advertisedESymbolType[k] = v
end