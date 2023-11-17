function extends(superclass, subclass)
  subclass = subclass or {}
  setmetatable(subclass, { __index = superclass })
  return subclass
end

function string.capitalize(s)
  return string.upper(string.sub(s, 1, 1)) .. string.sub(s, 2)
end
