-- =====================================================================
-- IME 自動オフ設定 (Mac / Windows 共通)
--   インサートモードを抜けてノーマルモードに戻ったとき、
--   IME を自動的に半角英数へ切り替える。
--
--   Mac    : macism (https://github.com/laishulu/macism)
--   Windows: zenhan (https://github.com/iuchim/zenhan)
--
--   - ターミナル Neovim / vscode-neovim のどちらでも動作する
--   - CLI ツールを非同期で呼び出すため、エディタが遅延しない
--   - <Esc> キー自体のリマップは行わないため、OS 標準の挙動を壊さない
-- =====================================================================

-- Mac で IME オフ時に切り替える入力ソース ID。
-- Google 日本語入力を使う場合は 'com.google.inputmethod.Japanese.Roman' に変更。
-- (確認コマンド: macism を IME オン状態で引数なし実行すると現在の ID が表示される)
local MAC_OFF_SOURCE = vim.g.ime_mac_off_source or 'com.apple.keylayout.ABC'

-- GUI 環境では PATH が通っていないことがあるため、絶対パスも探す
local function resolve_exe(candidates)
  for _, c in ipairs(candidates) do
    if vim.fn.executable(c) == 1 then
      return c
    end
  end
  return nil
end

local ime_off_cmd = nil
if vim.fn.has('mac') == 1 then
  local exe = resolve_exe({
    'macism',
    '/opt/homebrew/bin/macism', -- Apple Silicon
    '/usr/local/bin/macism',    -- Intel Mac
  })
  if exe then
    ime_off_cmd = { exe, MAC_OFF_SOURCE }
  end
elseif vim.fn.has('win32') == 1 then
  local exe = resolve_exe({
    'zenhan',
    vim.fn.expand('~/bin/zenhan.exe'), -- setup-windows.ps1 の配置先
  })
  if exe then
    ime_off_cmd = { exe, '0' } -- 0 = IME オフ
  end
end

if ime_off_cmd then
  local function ime_off()
    if vim.system then
      -- Neovim 0.10+: 非同期実行、出力は破棄
      vim.system(ime_off_cmd)
    else
      vim.fn.jobstart(ime_off_cmd)
    end
  end

  vim.api.nvim_create_autocmd({ 'InsertLeave', 'CmdlineLeave' }, {
    group = vim.api.nvim_create_augroup('ime-auto-off', { clear = true }),
    callback = ime_off,
    desc = 'ノーマルモード復帰時に IME をオフにする',
  })
end
