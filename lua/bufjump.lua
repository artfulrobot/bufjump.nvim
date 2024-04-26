local on_success = nil
local jumpbackward = function(num)
  vim.cmd([[execute "normal! ]] .. tostring(num) .. [[\<c-o>"]])
end

local jumpforward = function(num)
  vim.cmd([[execute "normal! ]] .. tostring(num) .. [[\<c-i>"]])
end

local backward = function()
  local getjumplist = vim.fn.getjumplist()
  local jumplist = getjumplist[1]
  if #jumplist == 0 then
    return
  end

  -- plus one because of one index
  local i = getjumplist[2] + 1
  local j = i
  local curBufNum = vim.fn.bufnr()
  local targetBufNum = curBufNum

  while j > 1 and (curBufNum == targetBufNum or not vim.api.nvim_buf_is_valid(targetBufNum)) do
    j = j - 1
    targetBufNum = jumplist[j].bufnr
  end
  if targetBufNum ~= curBufNum and vim.api.nvim_buf_is_valid(targetBufNum) then
    jumpbackward(i - j)
    if on_success then
      on_success()
    end
  end
end

local backwardSameBuf = function()
  local jumplistAndPos = vim.fn.getjumplist()

  local jumplist = jumplistAndPos[1]
  if #jumplist == 0 then
    return
  end
  local lastUsedJumpPos = jumplistAndPos[2] + 1
  local curBufNum = vim.fn.bufnr()

  local j = lastUsedJumpPos
  local foundJump = false
  repeat
    j = j - 1
    if j > 0 and (curBufNum == jumplist[j].bufnr and vim.api.nvim_buf_is_valid(jumplist[j].bufnr)) then
      foundJump = true
    end
  until j == 0 or foundJump

  if foundJump then
    jumpbackward(lastUsedJumpPos - j)
    if on_success then
      on_success()
    end
  end
end

local forward = function()
  local getjumplist = vim.fn.getjumplist()
  local jumplist = getjumplist[1]
  if #jumplist == 0 then
    return
  end

  local i = getjumplist[2] + 1
  local j = i
  local curBufNum = vim.fn.bufnr()
  local targetBufNum = curBufNum

  -- find the next different buffer
  while j < #jumplist and (curBufNum == targetBufNum or vim.api.nvim_buf_is_valid(targetBufNum) == false) do
    j = j + 1
    targetBufNum = jumplist[j].bufnr
  end
  while j + 1 <= #jumplist and jumplist[j + 1].bufnr == targetBufNum and vim.api.nvim_buf_is_valid(targetBufNum) do
    j = j + 1
  end
  if j <= #jumplist and targetBufNum ~= curBufNum and vim.api.nvim_buf_is_valid(targetBufNum) then
    jumpforward(j - i)

    if on_success then
      on_success()
    end
  end
end


local forwardSameBuf = function()
  dumpjumps()
  local jumplistAndPos = vim.fn.getjumplist()
  local jumplist = jumplistAndPos[1]
  if #jumplist == 0 then
    return
  end
  local lastUsedJumpPos = jumplistAndPos[2] + 1
  local curBufNum = vim.fn.bufnr()

  local j = lastUsedJumpPos
  local foundJump = false
  repeat
    j = j + 1
    if j <= #jumplist and curBufNum == jumplist[j].bufnr and vim.api.nvim_buf_is_valid(jumplist[j].bufnr) then
      foundJump = true
    end
  until j > #jumplist or foundJump

  if foundJump then
    jumpforward(j - lastUsedJumpPos)
    if on_success then
      on_success()
    end
  end
end

local setup = function(cfg)
  local opts = { silent = true, noremap = true }
  cfg = cfg or {}
  if cfg.forwardkey ~= false then
    local forwardkey = cfg.forward or "<C-n>"
    vim.api.nvim_set_keymap("n", forwardkey, ":lua require('bufjump').forward()<cr>", opts)
  end
  if cfg.backwardkey ~= false then
    local backwardkey = cfg.backward or "<C-n>"
    vim.api.nvim_set_keymap("n", backwardkey, ":lua require('bufjump').forward()<cr>", opts)
  end
  if cfg.forwardSameBufKey then
    vim.api.nvim_set_keymap("n", cfg.forwardSameBufKey, ":lua require('bufjump').forwardSameBuf()<cr>", opts)
  end
  if cfg.backwardSameBufKey then
    vim.api.nvim_set_keymap("n", cfg.backwardSameBufKey, ":lua require('bufjump').backwardSameBuf()<cr>", opts)
  end
end

return {
  backward = backward,
  forward = forward,
  backwardSameBuf = backwardSameBuf,
  forwardSameBuf = forwardSameBuf,
  setup = setup,
}
