#Requires AutoHotkey v2.0
#SingleInstance ignore

; 左右 Alt キーの空打ちで IME の OFF/ON を切り替える
;
; 左 Alt キーの空打ちで IME を「英数」に切り替え
; 右 Alt キーの空打ちで IME を「かな」に切り替え
; Alt キーを押している間に他のキーを打つと通常の Alt キーとして動作
;
IME_SET(SetSts, WinTitle := "A") {
    hwnd := DllCall("FindWindow", "Str", WinTitle, "Ptr", 0, "Ptr")

    if (WinActive(WinTitle)) {
        ptrSize := !A_PtrSize ? 4 : A_PtrSize
        ; メモリ領域を確保するために GlobalAlloc を使用
        stGTI_cbSize := 4 + 4 + (ptrSize * 6) + 16
        stGTIBuffer := DllCall("GlobalAlloc", "UInt", 0x40, "UInt", stGTI_cbSize, "Ptr")  ; GMEM_FIXED = 0x40

        ; GlobalAllocで得たポインタにcbSizeを設定
        NumPut "UInt", stGTI_cbSize, stGTIBuffer, 0

        ; GUIThreadInfoを取得
        hwnd := DllCall("GetGUIThreadInfo", "UInt", 0, "UInt", stGTIBuffer)
            ? NumGet(stGTIBuffer, 8 + ptrSize, "UInt")
            : hwnd
    }

    ; IMEコントロールメッセージを送信
    DllCall("SendMessage"
          , "UInt", DllCall("imm32\ImmGetDefaultIMEWnd", "UInt", hwnd)
          , "UInt", 0x0283  ; Message : WM_IME_CONTROL
          , "Int", 0x006   ; wParam  : IMC_SETOPENSTATUS
          , "Int", SetSts)  ; lParam  : 0 or 1
}


~*LAlt::Send("{Blind}{vk07}")
~*RAlt::Send("{Blind}{vk07}")

LAlt Up::IME_SET(0)   ; LAltでIMEオフ
RAlt Up::IME_SET(1)   ; RAltでIMEオン
