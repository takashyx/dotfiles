-- =====================================================================
-- IME 自動オフ設定 (Mac / Windows 共通)
--   以下のタイミングで IME を自動的に半角英数へ切り替える。
--     1. インサートモードを抜けてノーマルモードに戻ったとき
--     2. エディタ(コード画面)にフォーカスが入ったとき
--     3. 別のファイル(タブ)やウィンドウに移ったとき
--        (2, 3 はインサートモード等の文字入力中なら日本語入力継続の
--         可能性があるためスキップ)
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

  vim.api.nvim_create_autocmd(
    { 'InsertLeave', 'CmdlineLeave', 'FocusGained', 'BufEnter', 'WinEnter' },
    {
      group = vim.api.nvim_create_augroup('ime-auto-off', { clear = true }),
      callback = function(ev)
        -- インサート/置換/ターミナルモード中は文字入力の最中なので、
        -- モード遷移以外のイベントでは IME を切り替えない
        if ev.event ~= 'InsertLeave' and ev.event ~= 'CmdlineLeave'
            and vim.fn.mode():find('^[iRt]') then
          return
        end
        ime_off()
      end,
      desc = 'ノーマルモード復帰時・フォーカス/バッファ/ウィンドウ移動時に IME をオフにする',
    }
  )
end

if vim.g.vscode then
    vim.cmd([[
        " Insertモード用の判定
        function! SetCursorLineNrColorInsert(mode)
            if a:mode == "i"
                call VSCodeNotify('nvim-theme.insert')
            elseif a:mode == "r"
                call VSCodeNotify('nvim-theme.replace')
            endif
        endfunction

        augroup CursorLineNrColorSwap
            autocmd!
            " Visualモード
            autocmd ModeChanged *:[vV\x16]* call VSCodeNotify('nvim-theme.visual')
            " VisualモードからNormalモードに戻る時
            autocmd ModeChanged [vV\x16]*:n call VSCodeNotify('nvim-theme.normal')
            " Replaceモード
            autocmd ModeChanged *:[R]* call VSCodeNotify('nvim-theme.replace')
            " ReplaceモードからNormalモードに戻る時
            autocmd ModeChanged [R]*:n call VSCodeNotify('nvim-theme.normal')
            " Insertモードに入る時
            autocmd InsertEnter * call SetCursorLineNrColorInsert(v:insertmode)
            " InsertモードからNormalモードに戻る時
            autocmd InsertLeave * call VSCodeNotify('nvim-theme.normal')
            " カーソルホールド時にも念のためNormalに戻す
            autocmd CursorHold * call VSCodeNotify('nvim-theme.normal')
        augroup END
    ]])
end
