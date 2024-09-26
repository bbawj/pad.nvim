local M = {}

local win_id = nil

local log_file_path = vim.fn.stdpath('log') .. "/pad.log"
local log_file = nil
local bufh = nil

local function log(...)
  if log_file == nil then
    log_file = io.open(log_file_path, "a+")
    if log_file == nil then
      print("Failed to open log file at" .. log_file)
      return
    end
  end
  if vim.fn.empty(...) == 0 then
    log_file:write(..., "\n")
  end
end

local pad_dir = vim.fn.stdpath('data') .. "/pad"
local save_path = nil

M.setup = function(opts)
  vim.keymap.set("n", "<leader><leader>", M.toggle_window)
end

local function save()
  log("save!")
  local lines = vim.api.nvim_buf_get_lines(bufh, 0, -1, false)
  if next(lines) == nil then
    return
  end

  if vim.fn.filewritable(save_path) == 1 then
    vim.fn.writefile(lines, save_path, "s")
  else
    if save_path == nil then
      log("save path was not set")
      return
    end
    local f = io.open(save_path, "w")
    if f == nil then
      log("could not create ", save_path)
      return
    end
    f:write(lines)
    f:close()
  end
end

local function close_menu()
  log("close_menu()")
  vim.api.nvim_win_close(win_id, true)

  save()
  vim.api.nvim_buf_delete(bufh, { force = true })

  bufh = nil
  win_id = nil

  log_file:close()
  log_file = nil
end

local function create_dir(path)
  if vim.fn.isdirectory(path) == 0 then
    log(path .. " dir was not found, creating...")
    if vim.fn.mkdir(path, "p") == 0 then
      log("Failed to create ", path)
      return false
    end
  end
  return true
end

local function create_window()
  log("create_window()")
  -- Find the root of a git repository
  local project_dir = vim.fs.root(0, '.git')
  if project_dir == nil then
    log("failed to find root project directory")
    return false
  end

  local save_folder = pad_dir .. vim.fn.expand(project_dir)
  if not create_dir(save_folder) then
    log("failed to create ", save_folder)
    return false
  end

  local bufnr = vim.api.nvim_create_buf(false, false)

  save_path = save_folder .. "/pad"
  if vim.fn.filereadable(save_path) == 1 then
    local lines = vim.fn.readfile(save_path)
    vim.api.nvim_buf_set_lines(bufnr, 0, #lines, false, lines)
  end

  local height = 20
  local width = 100
  local pad_win_id, win = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    row = math.floor(((vim.o.lines - height) / 2) - 1),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
    border = "single",
  })

  win_id = pad_win_id
  bufh = bufnr

  vim.api.nvim_buf_set_keymap(
    bufh,
    "n",
    "q",
    "<Cmd>lua require('pad').toggle_window()<CR>",
    { silent = true }
  )
end

local function toggle_window()
  log("toggle_window()")
  create_dir(pad_dir)

  if win_id ~= nil then
    close_menu()
    return
  end
  create_window()
end

local function open_notepad()
  M.toggle_window()
end

M.toggle_window = toggle_window

M.setup()

return M
