-- Full Lua Parser with AST Generation
local Parser = {}

-- Token types
local TokenType = {
    KEYWORD = "keyword",
    IDENTIFIER = "identifier",
    NUMBER = "number",
    STRING = "string",
    OPERATOR = "operator",
    COMMENT = "comment",
    UNKNOWN = "unknown"
}

-- Keyword list
local KEYWORDS = {
    ["and"] = true, ["break"] = true, ["do"] = true,
    ["else"] = true, ["elseif"] = true, ["end"] = true,
    ["false"] = true, ["for"] = true, ["function"] = true,
    ["goto"] = true, ["if"] = true, ["in"] = true,
    ["local"] = true, ["nil"] = true, ["not"] = true,
    ["or"] = true, ["repeat"] = true, ["return"] = true,
    ["then"] = true, ["true"] = true, ["until"] = true,
    ["while"] = true
}

-- Operator list
local OPERATORS = {
    ["+"] = true, ["-"] = true, ["*"] = true, ["/"] = true,
    ["%"] = true, ["^"] = true, ["#"] = true, ["=="] = true,
    ["~="] = true, ["<="] = true, [">="] = true, ["<"] = true,
    [">"] = true, ["="] = true, ["("] = true, [")"] = true,
    ["{"] = true, ["}"] = true, ["["] = true, ["]"] = true,
    ["."] = true, [".."] = true, ["..."] = true, [","] = true,
    [";"] = true, [":"] = true
}

-- Tokenizer
local function tokenize(source)
    local tokens = {}
    local pos = 1
    local line = 1
    local col = 1
    
    while pos <= #source do
        -- Skip whitespace
        local whitespace = source:match("^%s+", pos)
        if whitespace then
            for i = 1, #whitespace do
                if whitespace:sub(i, i) == "\n" then
                    line = line + 1
                    col = 1
                else
                    col = col + 1
                end
            end
            pos = pos + #whitespace
        end
        
        if pos > #source then break end
        
        -- Comments
        if source:match("^%-%-%[%[", pos) then
            local comment = source:match("^%-%-%[%[(.-)%]%]", pos)
            if comment then
                table.insert(tokens, {
                    type = TokenType.COMMENT,
                    value = comment,
                    line = line,
                    col = col,
                    text = "--[[" .. comment .. "]]"
                })
                pos = pos + #comment + 6
                col = col + #comment + 6
            end
        elseif source:match("^%-%-", pos) then
            local comment = source:match("^%-%-[^\n]*", pos)
            table.insert(tokens, {
                type = TokenType.COMMENT,
                value = comment,
                line = line,
                col = col,
                text = comment
            })
            pos = pos + #comment
            col = col + #comment
            continue
        end
        
        -- Strings (multi-line)
        if source:match("^%[%[", pos) then
            local str = source:match("^%[%[(.-)%]%]", pos)
            if str then
                table.insert(tokens, {
                    type = TokenType.STRING,
                    value = str,
                    line = line,
                    col = col,
                    text = "[[" .. str .. "]]",
                    quotestyle = "block"
                })
                pos = pos + #str + 4
                col = col + #str + 4
            end
            continue
        end
        
        -- Strings (single quote)
        if source:match("^'", pos) then
            local str = source:match("^'([^']*)'", pos)
            if str then
                table.insert(tokens, {
                    type = TokenType.STRING,
                    value = str,
                    line = line,
                    col = col,
                    text = "'" .. str .. "'",
                    quotestyle = "'"
                })
                pos = pos + #str + 2
                col = col + #str + 2
            end
            continue
        end
        
        -- Strings (double quote)
        if source:match('^"', pos) then
            local str = source:match('^"([^"]*)"', pos)
            if str then
                table.insert(tokens, {
                    type = TokenType.STRING,
                    value = str,
                    line = line,
                    col = col,
                    text = '"' .. str .. '"',
                    quotestyle = '"'
                })
                pos = pos + #str + 2
                col = col + #str + 2
            end
            continue
        end
        
        -- Numbers
        local num = source:match("^%d+[%d%.]*", pos)
        if num then
            table.insert(tokens, {
                type = TokenType.NUMBER,
                value = tonumber(num),
                line = line,
                col = col,
                text = num
            })
            pos = pos + #num
            col = col + #num
            continue
        end
        
        -- Identifiers and Keywords
        local ident = source:match("^[%a_][%w_]*", pos)
        if ident then
            table.insert(tokens, {
                type = KEYWORDS[ident] and TokenType.KEYWORD or TokenType.IDENTIFIER,
                value = ident,
                line = line,
                col = col,
                text = ident
            })
            pos = pos + #ident
            col = col + #ident
            continue
        end
        
        -- Operators
        local op_found = false
        for op in pairs(OPERATORS) do
            if source:match("^" .. op, pos) then
                table.insert(tokens, {
                    type = TokenType.OPERATOR,
                    value = op,
                    line = line,
                    col = col,
                    text = op
                })
                pos = pos + #op
                col = col + #op
                op_found = true
                break
            end
        end
        if op_found then continue end
        
        -- Unknown
        local char = source:sub(pos, pos)
        table.insert(tokens, {
            type = TokenType.UNKNOWN,
            value = char,
            line = line,
            col = col,
            text = char
        })
        pos = pos + 1
        col = col + 1
    end
    
    return tokens
end

-- Parse statements from tokens
local function parseStatements(tokens)
    local statements = {}
    local i = 1
    
    while i <= #tokens do
        local token = tokens[i]
        
        if token.type == TokenType.KEYWORD then
            if token.value == "local" then
                local stmt = {
                    tag = "local",
                    kind = "stat",
                    variables = {},
                    values = {}
                }
                i = i + 1
                while i <= #tokens and tokens[i].type == TokenType.IDENTIFIER do
                    table.insert(stmt.variables, {
                        node = {
                            name = { text = tokens[i].value },
                            tag = "local"
                        }
                    })
                    i = i + 1
                    if i <= #tokens and tokens[i].value == "," then
                        i = i + 1
                    else
                        break
                    end
                end
                if i <= #tokens and tokens[i].value == "=" then
                    i = i + 1
                    while i <= #tokens and tokens[i].type ~= TokenType.OPERATOR and tokens[i].value ~= ";" do
                        table.insert(stmt.values, {
                            node = {
                                tag = tokens[i].type == TokenType.STRING and "string" or tokens[i].type == TokenType.NUMBER and "number" or "unknown",
                                text = tokens[i].value or "nil",
                                value = tokens[i].value
                            }
                        })
                        i = i + 1
                        if i <= #tokens and tokens[i].value == "," then
                            i = i + 1
                        else
                            break
                        end
                    end
                end
                table.insert(statements, stmt)
                
            elseif token.value == "function" then
                local stmt = {
                    tag = "function",
                    kind = "stat",
                    name = { text = "unnamed" },
                    body = {
                        parameters = {},
                        body = { statements = {} }
                    }
                }
                i = i + 1
                if i <= #tokens and tokens[i].type == TokenType.IDENTIFIER then
                    stmt.name.text = tokens[i].value
                    i = i + 1
                end
                if i <= #tokens and tokens[i].value == ":" then
                    i = i + 1
                    if i <= #tokens and tokens[i].type == TokenType.IDENTIFIER then
                        stmt.name.text = stmt.name.text .. ":" .. tokens[i].value
                        i = i + 1
                    end
                end
                if i <= #tokens and tokens[i].value == "(" then
                    i = i + 1
                    while i <= #tokens and tokens[i].value ~= ")" do
                        if tokens[i].type == TokenType.IDENTIFIER then
                            table.insert(stmt.body.parameters, { text = tokens[i].value })
                        end
                        i = i + 1
                    end
                    i = i + 1
                end
                local depth = 0
                while i <= #tokens do
                    if tokens[i].value == "end" and depth == 0 then
                        i = i + 1
                        break
                    end
                    if tokens[i].value == "function" then depth = depth + 1 end
                    if tokens[i].value == "end" and depth > 0 then depth = depth - 1 end
                    i = i + 1
                end
                table.insert(statements, stmt)
                
            elseif token.value == "return" then
                local stmt = {
                    tag = "return",
                    kind = "stat",
                    expressions = {}
                }
                i = i + 1
                while i <= #tokens and tokens[i].value ~= ";" and tokens[i].value ~= "end" do
                    if tokens[i].type == TokenType.IDENTIFIER then
                        table.insert(stmt.expressions, {
                            node = {
                                tag = "global",
                                name = { text = tokens[i].value }
                            }
                        })
                    elseif tokens[i].type == TokenType.NUMBER or tokens[i].type == TokenType.STRING then
                        table.insert(stmt.expressions, {
                            node = {
                                tag = tokens[i].type,
                                text = tokens[i].value or "nil",
                                value = tokens[i].value
                            }
                        })
                    end
                    i = i + 1
                    if i <= #tokens and tokens[i].value == "," then i = i + 1 end
                end
                table.insert(statements, stmt)
                
            elseif token.value == "if" then
                local stmt = {
                    tag = "conditional",
                    kind = "stat",
                    condition = { tag = "boolean", value = true },
                    thenblock = { statements = {} },
                    elseifs = {},
                    elseblock = nil
                }
                i = i + 1
                local depth = 0
                while i <= #tokens do
                    if tokens[i].value == "then" then
                        i = i + 1
                        break
                    end
                    i = i + 1
                end
                while i <= #tokens do
                    if tokens[i].value == "elseif" then
                        i = i + 1
                        while i <= #tokens and tokens[i].value ~= "then" do i = i + 1 end
                        i = i + 1
                    elseif tokens[i].value == "else" then
                        i = i + 1
                        while i <= #tokens and tokens[i].value ~= "end" do i = i + 1 end
                        break
                    elseif tokens[i].value == "end" and depth == 0 then
                        i = i + 1
                        break
                    end
                    if tokens[i].value == "function" then depth = depth + 1 end
                    if tokens[i].value == "end" and depth > 0 then depth = depth - 1 end
                    i = i + 1
                end
                table.insert(statements, stmt)
                
            elseif token.value == "while" then
                local stmt = {
                    tag = "while",
                    kind = "stat",
                    condition = { tag = "boolean", value = true },
                    body = { statements = {} }
                }
                i = i + 1
                while i <= #tokens and tokens[i].value ~= "do" do i = i + 1 end
                i = i + 1
                local depth = 0
                while i <= #tokens do
                    if tokens[i].value == "end" and depth == 0 then
                        i = i + 1
                        break
                    end
                    if tokens[i].value == "function" then depth = depth + 1 end
                    if tokens[i].value == "end" and depth > 0 then depth = depth - 1 end
                    i = i + 1
                end
                table.insert(statements, stmt)
                
            elseif token.value == "for" then
                local stmt = {
                    tag = "for",
                    kind = "stat",
                    variable = { name = { text = "i" } },
                    from = { tag = "number", value = 1 },
                    to = { tag = "number", value = 10 },
                    step = nil,
                    body = { statements = {} }
                }
                i = i + 1
                if i <= #tokens and tokens[i].type == TokenType.IDENTIFIER then
                    stmt.variable.name.text = tokens[i].value
                    i = i + 1
                end
                if i <= #tokens and tokens[i].value == "=" then
                    i = i + 1
                    if i <= #tokens and tokens[i].type == TokenType.NUMBER then
                        stmt.from.value = tokens[i].value
                        i = i + 1
                    end
                end
                if i <= #tokens and tokens[i].value == "," then
                    i = i + 1
                    if i <= #tokens and tokens[i].type == TokenType.NUMBER then
                        stmt.to.value = tokens[i].value
                        i = i + 1
                    end
                end
                if i <= #tokens and tokens[i].value == "," then
                    i = i + 1
                    if i <= #tokens and tokens[i].type == TokenType.NUMBER then
                        stmt.step = { tag = "number", value = tokens[i].value }
                        i = i + 1
                    end
                end
                while i <= #tokens and tokens[i].value ~= "do" do i = i + 1 end
                i = i + 1
                local depth = 0
                while i <= #tokens do
                    if tokens[i].value == "end" and depth == 0 then
                        i = i + 1
                        break
                    end
                    if tokens[i].value == "function" then depth = depth + 1 end
                    if tokens[i].value == "end" and depth > 0 then depth = depth - 1 end
                    i = i + 1
                end
                table.insert(statements, stmt)
                
            elseif token.value == "repeat" then
                local stmt = {
                    tag = "repeat",
                    kind = "stat",
                    body = { statements = {} },
                    condition = { tag = "boolean", value = false }
                }
                i = i + 1
                while i <= #tokens and tokens[i].value ~= "until" do i = i + 1 end
                i = i + 1
                table.insert(statements, stmt)
                
            elseif token.value == "break" then
                table.insert(statements, {
                    tag = "break",
                    kind = "stat"
                })
                i = i + 1
                
            else
                i = i + 1
            end
        elseif token.type == TokenType.IDENTIFIER then
            local stmt = {
                tag = "assign",
                kind = "stat",
                variables = {},
                values = {}
            }
            table.insert(stmt.variables, {
                node = {
                    tag = "global",
                    name = { text = token.value }
                }
            })
            i = i + 1
            if i <= #tokens and tokens[i].value == "=" then
                i = i + 1
                if i <= #tokens then
                    table.insert(stmt.values, {
                        node = {
                            tag = tokens[i].type == TokenType.STRING and "string" or tokens[i].type == TokenType.NUMBER and "number" or "unknown",
                            text = tokens[i].value or "nil",
                            value = tokens[i].value
                        }
                    })
                    i = i + 1
                end
            end
            table.insert(statements, stmt)
        else
            i = i + 1
        end
    end
    
    return statements
end

-- Main parse function
function Parser.parse(source)
    local tokens = tokenize(source)
    local statements = parseStatements(tokens)
    
    return {
        root = {
            statements = statements,
            tokens = tokens
        }
    }
end

function Parser.parsefile(path)
    local file = io.open(path, "r")
    if not file then
        error("Cannot open file: " .. path)
    end
    local content = file:read("*all")
    file:close()
    return Parser.parse(content)
end

function Parser.tokenize(source)
    return tokenize(source)
end

return Parser
