local merge = require('mapx.util').merge
local log = require 'mapx.log'

local dbgi = log.dbgi

local Mapper = {
  mapopts = {
    buffer = { buffer = 0 },
    nowait = { nowait = true },
    silent = { silent = true },
    script = { script = true },
    expr = { expr = true },
    unique = { unique = true },
  },
}

-- Expands string-based options like "buffer", "silent", "expr" to their
-- table-based representation. Also supports <wrapped> strings "<buffer>"
-- Returns a new opts table with this expansion applied.
local function expandStringOpts(opts)
  local res = {}
  for k, v in pairs(opts) do
    if type(k) == 'number' then
      if Mapper.mapopts[v] then
        res[v] = true
        goto continue
      end
      local vsub = type(v) == 'string' and vim.fn.substitute(v, [[^<\|>$]], '', 'g')
      if vsub and Mapper.mapopts[vsub] ~= nil then
        res[vsub] = true
        goto continue
      end
      table.insert(res, v)
    else
      res[k] = v
    end
    ::continue::
  end
  return res
end

local function extractLabel(opts)
  local _opts = merge({}, opts)
  local label
  if _opts.label ~= nil then
    label = _opts.label
    _opts.label = nil
    return label, _opts
  end
  if _opts[#_opts] ~= nil and Mapper.mapopts[_opts[#_opts]] == nil then
    label = _opts[#_opts]
    table.remove(_opts, #_opts)
    return label, _opts
  end
  return nil, _opts
end

function Mapper.new()
  local self = {
    config = {},
    luaFuncs = {},
    filetypeMaps = {},
    groupOpts = {},
    whichkey = nil,
  }
  vim.cmd [[
    augroup mapx_mapper
      autocmd!
      autocmd FileType * lua require'mapx'.mapper:filetype(vim.fn.expand('<amatch>'), vim.fn.expand('<abuf>'))
    augroup END
  ]]
  return setmetatable(self, { __index = Mapper })
end

function Mapper:setup(config)
  self.config = merge(self.config, config)
  if self.config.whichkey then
    local ok, wk = pcall(require, 'which-key')
    if not ok then
      error 'mapx.Map:setup: config.whichkey == true but module "which-key" not found'
    end
    self.whichkey = wk
  end
  dbgi('mapx.Map:setup', self)
  return self
end

function Mapper:filetypeMap(fts, fn)
  dbgi('Map.filetype', { fts = fts, fn = fn })
  if type(fts) ~= 'table' then
    fts = { fts }
  end
  for _, ft in ipairs(fts) do
    if self.filetypeMaps[ft] == nil then
      self.filetypeMaps[ft] = {}
    end
    table.insert(self.filetypeMaps[ft], fn)
  end
  dbgi('mapx.Map.filetypeMaps insert', self.filetypeMaps)
end

function Mapper:filetype(ft, buf, ...)
  local filetypeMaps = self.filetypeMaps[ft]
  dbgi('mapx.Map:handleFiletype', { ft = ft, ftMaps = filetypeMaps, rest = { ... } })
  if filetypeMaps == nil then
    return
  end
  for _, fn in ipairs(filetypeMaps) do
    fn(buf, ...)
  end
end

function Mapper:func(id, ...)
  local fn = self.luaFuncs[id]
  if fn == nil then
    return
  end
  return fn(...)
end

function Mapper:registerMap(mode, lhs, rhs, opts, wkopts, label)
  if label then
    if self.whichkey then
      local regval = { [lhs] = { rhs, label } }
      local regopts = merge({
        mode = mode ~= '' and mode or nil,
      }, wkopts)
      regopts.silent = regopts.silent ~= nil and regopts.silent or false
      dbgi('Mapper:registerMap (whichkey)', { mode = mode, regval = regval, regopts = regopts })
      self.whichkey.register(regval, regopts)
    end
  elseif opts.buffer then
    local bopts = merge({}, opts)
    bopts.buffer = nil
    dbgi('Mapper:registerMap (buffer)', { mode = mode, lhs = lhs, rhs = rhs, opts = opts, bopts = bopts })
    vim.api.nvim_buf_set_keymap(opts.buffer, mode, lhs, rhs, bopts)
  else
    dbgi('Mapper:registerMap', { mode = mode, lhs = lhs, rhs = rhs, opts = opts })
    vim.api.nvim_set_keymap(mode, lhs, rhs, opts)
  end
end

function Mapper:registerName(mode, lhs, opts)
  if opts.name == nil then
    error 'mapx.name: missing name'
  end
  if self.whichkey then
    local reg = {
      [lhs] = {
        name = opts.name,
      },
    }
    local regopts = merge {
      buffer = opts.buffer or nil,
      mode = mode ~= '' and mode or nil,
    }
    dbgi('Mapper:registerName', { mode = mode, reg = reg, regopts = regopts })
    self.whichkey.register(reg, regopts)
  end
end

function Mapper:register(config, lhss, rhs, ...)
  if type(config) ~= 'table' then
    config = { mode = config, type = 'map' }
  end
  local opts = merge(self.groupOpts, ...)
  local ft = opts.filetype or opts.ft
  if ft ~= nil then
    opts.ft = nil
    opts.filetype = nil
    self:filetypeMap(ft, function(buf)
      opts.buffer = buf
      self:register(config, lhss, rhs, opts)
    end)
    return
  end
  opts = expandStringOpts(opts)
  local label
  local wkopts
  if opts.buffer == true then
    opts.buffer = 0
  end
  if self.whichkey ~= nil then
    label, wkopts = extractLabel(opts)
  end
  if type(lhss) ~= 'table' then
    lhss = { lhss }
  end
  if type(rhs) == 'function' then
    -- TODO: rhs gets inserted multiple times if a filetype mapping is
    -- triggered multiple times
    table.insert(self.luaFuncs, rhs)
    dbgi('state.funcs insert', { luaFuncs = self.luaFuncs })
    local luaexpr = "require'mapx'.mapper:func(" .. #self.luaFuncs .. ', vim.v.count)'
    if opts.expr then
      rhs = 'luaeval("' .. luaexpr .. '")'
    else
      rhs = '<Cmd>lua ' .. luaexpr .. '<Cr>'
    end
  end
  for _, lhs in ipairs(lhss) do
    if config.type == 'map' then
      self:registerMap(config.mode, lhs, rhs, opts, wkopts, label)
    elseif config.type == 'name' then
      self:registerName(config.mode, lhs, opts)
    end
  end
end

function Mapper:group(...)
  local prevOpts = self.groupOpts
  local fn
  local args = { ... }
  for i, v in ipairs(args) do
    if i < #args then
      self.groupOpts = merge(self.groupOpts, v)
    else
      fn = v
    end
  end
  self.groupOpts = expandStringOpts(self.groupOpts)
  dbgi('group', self.groupOpts)
  local label = extractLabel(self.groupOpts)
  if label ~= nil then
    error('mapx.group: cannot set label on group: ' .. tostring(label))
  end
  fn()
  self.groupOpts = prevOpts
end

return Mapper
