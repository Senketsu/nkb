# const hasThreadSupport = compileOption("threads") ## not working..
import strutils
when defined(Threads):
  import rlocks

when defined(Windows):
  import oldwinapi
else:
  import glib2, gdk2, gtk2
  export nim_init, main
  import x, xlib, xkb, xkblib
  import private/gdk2x


when defined(Windows):
  type
    PKeybindHandle = (proc (keystring: cstring , user_data: pointer))
    PKeyLibBinding = ptr TKeyLibBinding
    TKeyLibBinding = object
      handler*: PKeybindHandle
      user_data*: pointer
      keystring*: cstring
      uid*: cuint
      keyval*: cint
      modifiers*: cint

  var nkbWindow: HWND

else:
  const
    MODIFIERS_NONE = 0
    MODIFIERS_ERROR = 999999
    USE_ONE_GROUP = 0

  type

    PKeybindHandle = (proc (keystring: cstring , user_data: pointer))
    PKeyLibBinding = ptr TKeyLibBinding
    TKeyLibBinding = object
      handler*: PKeybindHandle
      user_data*: pointer
      keystring*: cstring
      uid*: cuint
      keyval*: guint
      modifiers*: gdk2.TModifierType

  var
    useXkbExtension: bool = false
    isProcessingEvent: bool = false
    detected_xkb_extension: bool = false
    lastEventTime: culong = 0

when defined(Threads):
  var
    nkbLock: RLock
    allBinds {.guard: nkbLock, threadvar.}: seq[TKeyLibBinding]
    allowMultipleCBs: bool = true
  
else:
  var
    allBinds: seq[TKeyLibBinding]
    allowMultipleCBs: bool = true
    



when defined(Windows):
  proc nkb_wnd_proc(hWnd: HWND, uMsg: WINUINT, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.} =
    case uMsg
    of WM_HOTKEY:
      when defined(Threads):
        nkbLock.withRLock:
          for keyBind in allBinds:
            if keyBind.uID == cuit(wParam):
              keyBind.handler(keyBind.keystring, keyBind.userData)
              break
      else:
        for keyBind in allBinds:
          if keyBind.uID == cuit(wParam):
            keyBind.handler(keyBind.keystring, keyBind.userData)
            break
    else:
      discard
    return DefWindowProc(hWnd, uMsg, wParam, lParam)

  proc nkb_init_windows(): HWND =
    var
      winClass: WNDCLASSEX
      nkbHWND: HWND
      msg: MSG
    result = NULL
    let hInstance = GetModuleHandle(nil)

    winClass.cbSize = WINUINT(sizeof(WNDCLASSEX))
    winClass.style = CS_HREDRAW or CS_VREDRAW
    winClass.lpfnWndProc = WNDPROC(nkb_wndproc)
    winClass.cbClsExtra = 0
    winClass.cbWndExtra = 0
    winClass.hInstance = hInstance
    winClass.hbrBackground = COLOR_WINDOW+1
    winClass.lpszMenuName = nil
    winClass.lpszClassName = "nkb_class"

    if RegisterClassEx(addr(winClass)) == 0:
      let err = GetLastError()
      stderr.writeLine("[nkb]  Windows class registration failed\n\t'$1'" % [$err])
      return
    nkbHWND = createWindowEx(0, winClass.lpszClassName, "[nkb window]",
        WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, 1, 1, NULL, NULL, hInstance, nil)
    if nkbHWND == NULL:
      let err = GetLastError()
      stderr.writeLine("[nkb]  Failed to setup subwindow\n\t'$1'" % [$err])
    result = nkbHWND

else:
  proc nkb_get_mods_for_key_code(xkb: PXkbDescPtr, key: int16, group: int8,
      level: int8): TModifierType =
    var
      nKeyGroups: int8
      effGroup: int16
      keyType: PXkbKeyTypePtr

    nKeyGroups = XkbKeyNumGroups(xkb, key)
    let isInRange = XkbKeycodeInRange(xkb, key)
    if not isInRange or nKeyGroups == 0:
      return uint32(MODIFIERS_ERROR)
    effGroup = group
    if effGroup >= nKeyGroups:
      let groupInfo = XkbKeyGroupInfo(xkb, key)
      case XkbOutOfRangeGroupAction(groupInfo)
      of XkbClampIntoRange:
        effGroup = nKeyGroups-1
      of XKbRedirectIntoRange:
        effGroup = XkbOutOfRangeGroupNumber(groupInfo)
        if effGroup >= nKeyGroups:
          effGroup = 0
      else:
        effGroup = effGroup mod nKeyGroups
    keyType = XkbKeyKeyType(xkb, key, int8(effGroup))
    for i in 0..(keyType.map_count-1):
      if keyType.map.active and keytype.map.level == level:
        if keyType.preserve != nil:
          return uint32(keyType.map.mods.mask and keyType.preserve.mask)
        else:
          return uint32(keyType.map.mods.mask)
    return MODIFIERS_NONE


  proc nkb_grab_ungrab_with_ignorable_mods(rootWin: gdk2.PWindow,
      keycode: guint, modifiers: guint, grab: bool): bool =
    var mods_masks: array[4, guint] = [guint(0),
      (gdk2.MOD2_MASK), (gdk2.LOCK_MASK), (gdk2.MOD2_MASK or gdk2.LOCK_MASK)]
    for i in 0..mods_masks.high:
      if grab:
        discard XGrabKey(WINDOW_XDISPLAY(rootWin), cint(keycode),
          cuint(modifiers or mods_masks[i]), DRAWABLE_XID(rootWin),
          TBool(false), GrabModeAsync, GrabModeAsync)
      else:
        discard XUngrabKey(WINDOW_XDISPLAY(rootWin), cint(keycode),
          cuint(modifiers or mods_masks[i]), DRAWABLE_XID(rootWin))
    result = true


  proc nkb_grab_ungrab(rootWin: gdk2.PWindow, keyval, modifiers: guint, grab: bool): bool =
    var
      xmap: PXkbDescPtr
      keymap: PKeyMap = keymap_get_default()
      n_keys: gint = 0
      keys: array[20, PKeyMapKey]
      add_modifiers: gdk2.TModifierType

    if useXkbExtension:
      xmap = XkbGetMap(WINDOW_XDISPLAY(rootWin), XkbAllClientInfoMask, XkbUseCoreKbd)
    discard keymap.keymap_get_entries_for_keyval(keyval, addr keys, addr n_keys)
    if n_keys == 0:
      return

    for i in 0..n_keys-1:
      if keys[i].group != 0:
        continue
      if useXkbExtension:
        add_modifiers = nkb_get_mods_for_key_code(xmap,
         int16(keys[i].keycode), int8(keys[i].group), int8(keys[i].level))
      elif keys[i].level > 0:
        continue
      if add_modifiers == MODIFIERS_ERROR:
        continue
      if nkb_grab_ungrab_with_ignorable_mods(rootWin, keys[i].keycode,
          (add_modifiers or modifiers), grab):
        result = true
      else:
        if grab and not result:
          break
    for k in keys:
      if k != nil:
        g_free(k)
    XkbFreeCLientMap(xmap, 0, true)


  proc nkb_ungrab_key(binding: PKeyLibBinding): bool =
    var
      keymap: PKeyMap = keymap_get_default()
      rootWin: gdk2.PWindow = get_default_root_window()
      modifiers: gdk2.TModifierType

    if keymap == nil or rootWin == nil:
      stderr.writeLine("[nkb] Couldn't get keymap and/or rootwin")
      return

    modifiers = binding.modifiers
    keymap.keymap_map_virtual_modifiers(addr modifiers)
    result = nkb_grab_ungrab(rootWin, binding.keyval, modifiers, false)
    if not result:
      stderr.writeLine("[nkb] Unbinding '$1' failed" % [$binding.keystring])


  proc nkb_grab_key(binding: PKeyLibBinding): bool =
    var
      keymap: PKeyMap = keymap_get_default()
      rootWin: gdk2.PWindow = get_default_root_window()
      modifiers: gdk2.TModifierType
      keysym: guint = 0

    if keymap == nil or rootwin == nil:
      stderr.writeLine("[nkb] Couldn't get keymap and/or rootwin")
      return
    gtk2.accelerator_parse(binding.keystring, addr keysym, addr modifiers)
    if keysym == 0:
      return

    binding.keyval = keysym
    binding.modifiers = modifiers
    keymap.keymap_map_virtual_modifiers(addr modifiers)

    if modifiers == binding.modifiers and
      (guint(SUPER_MASK or HYPER_MASK or META_MASK) and modifiers) != 0:
      stderr.writeLine("[nkb] Failed to map virtual modifiers")
      return
    result = nkb_grab_ungrab(rootWin, keysym, modifiers, true)
    if not result:
      stderr.writeLine("[nkb] Binding '$1' failed" % [$binding.keystring])


  proc nkb_modifiers_equal(mod1: gdk2.TModifierType, mod2: gdk2.TModifierType): bool =
    var ignored: gdk2.TModifierType = 0
    if (mod1 and mod2 and gdk2.MOD1_MASK) != 0:
      ignored = ignored or META_MASK
    if (mod1 and mod2 and SUPER_MASK) != 0:
      ignored = ignored or HYPER_MASK
    if (mod1 and not ignored) == (mod2 and not ignored):
      result = true


  proc nkb_filter_proc(xevent: gdk2.PXEvent, event: gdk2.PEvent, data: Pgpointer): TFilterReturn {.procvar.} =
    var
      xKeyEvent: xlib.PXKeyEvent = cast[xlib.PXKeyEvent](xevent)
      keymap: gdk2.PKeyMap = keymap_get_default()
      modMask = gtk2.accelerator_get_default_mod_mask()
      keyVal: guint
      consumed, modifiers: gdk2.TModifierType

    case xKeyEvent.theType:
    of x.KeyPress:
      modifiers = gdk2.TmodifierType(xKeyEvent.state)
      if useXkbExtension:
        discard keymap.keymap_translate_keyboard_state(xKeyEvent.keycode,
          modifiers, 0, addr keyVal, nil, nil, addr consumed)
      else:
        consumed = 0
        keyVal = guint(XLookupKeySym(xKeyEvent, 0))

      modifiers = modifiers and not consumed
      keymap.keymap_add_virtual_modifiers(addr modifiers)
      modifiers = modifiers and modMask
      isProcessingEvent = true
      lastEventTime = xKeyEvent.time
      
      when defined(Threads):
        nkbLock.withRLock:
          for i in 0..allBinds.high:
            if allBinds[i].keyval == keyval and nkb_modifiers_equal(allBinds[i].modifiers, modifiers):
              allBinds[i].handler(allBinds[i].keystring, allBinds[i].user_data)
              if not allowMultipleCBs:
                break
      else:
        for i in 0..allBinds.high:
          if allBinds[i].keyval == keyval and nkb_modifiers_equal(allBinds[i].modifiers, modifiers):
            allBinds[i].handler(allBinds[i].keystring, allBinds[i].user_data)
            if not allowMultipleCBs:
              break

      isProcessingEvent = false
    of x.KeyRelease:
      discard
    else:
      discard
    result = FILTER_CONTINUE

when defined(Threads):
  proc nkb_deinit_lock*() =
    deinitRLock(nkbLock)
  
  proc nkb_keymap_changed() =
    nkbLock.withRLock:
      for i in 0..allBinds.high:
        discard nkb_ungrab_key(addr allBinds[i])
      for i in 0..allBinds.high:
        discard nkb_grab_key(addr allBinds[i])
else:
  proc nkb_keymap_changed() =
    for i in 0..allBinds.high:
      discard nkb_ungrab_key(addr allBinds[i])
    for i in 0..allBinds.high:
      discard nkb_grab_key(addr allBinds[i])


proc nkb_init*() =
  when defined(Threads):
    initRLock(nkbLock)
    nkbLock.withRLock:
      allBinds = @[]
  else:
    allBinds = @[]
  
  when defined(Windows):
    nkbWindow = nkb_init_windows()
  else:
    var
      keymap = keymap_get_default()
      rootWin = get_default_root_window()
      opcode, eventBase, errorBase, majVer, minVer: int16

    detected_xkb_extension = XkbQueryExtension(XOpenDisplay(nil),
      addr opcode, addr eventBase, addr errorBase, addr majVer, addr minVer)
    discard keymap.keymap_have_bidi_layouts()
    rootWin.add_filter(TFILTER_CALLBACK(nkb_filter_proc), nil)
    discard keymap.g_signal_connect("keys_changed", G_CALLBACK(nkb_keymap_changed), nil)


proc nkb_parse_modmask(keystring: cstring): tuple[mask: cuint, key: cuint] =
  let noRepeatMod = 0x4000
  let splitKS = ($keystring).split('>')
  var
    modMask: cuint = 0
    key: cuchar
  for part in splitKS:
    if part.startsWith("<"):
      case part.toUpperAscii()
      of "<CTRL", "<CONTROL":
        modMask = modMask or 2
      of "<ALT":
        modMask = modMask or 1
      of "<SHIFT":
        modMask = modMask or 4
      of "<WIN":
        modMask = modMask or 8
      else:
        modMask = modMask or 0
    else:
      key = part[0]
  result.mask = modMask
  result.key = cuint(key)


proc nkb_bind*(keystring: cstring, handler: PKeybindHandle,
                user_data: pointer, uID: cuint = 0): bool =
  ## Proc to bind a function to a hotkey
  ## Keystring must valid gtk accel string e.g <CTRL>i
  ## Handler is a proc pointer of PKeybindHandle type
  ## User_data will be supplied to handler
  ## Returns bool value of true if bind was successful
  ## uID is omited for x window systems, and will be generated if not specified
  var binding: TKeyLibBinding
  binding.keystring = keystring
  binding.handler = handler
  binding.user_data = user_data

  let parMM = nkb_parse_modmask(keystring)
  if uID != 0:
    binding.uid = uID
  else:
    binding.uid = (parMM.mask * cuint(parMM.key)*17)

  when defined(Windows):
    result = nkbWindow.RegisterHotkey((binding.uid), parMM.mask, parMM.key)
  else:
    result = nkb_grab_key(addr binding)
  if result:
    when defined(Threads):
      nkbLock.withRLock:
        allBinds.add(binding)
    else:
      allBinds.add(binding)
  else:
    stderr.writeLine("[nkb] Keybind '$1' already in use" % [$binding.keystring])

when defined(Threads):
  proc nkb_unbind_all*() =
    nkbLock.withRLock:
      for i in 0..allBinds.high:
        when defined(Windows):
          discard UnRegisterHotKey(nkbWindow, allBinds[i].uid)
        else:
          discard nkb_ungrab_key(addr allBinds[i])
        allBinds.del(i)


  proc nkb_unbind*(keystring: cstring, handler: PKeybindHandle) =
    nkbLock.withRLock:
      for i in 0..allBinds.high:
        if keystring == allBinds[i].keystring and handler == allBinds[i].handler:
          when defined(Windows):
            discard UnRegisterHotKey(nkbWindow, allBinds[i].uid)
          else:
            discard nkb_ungrab_key(addr allBinds[i])
          allBinds.del(i)
else:
  proc nkb_unbind_all*() =
    for i in 0..allBinds.high:
      when defined(Windows):
        discard UnRegisterHotKey(nkbWindow, allBinds[i].uid)
      else:
        discard nkb_ungrab_key(addr allBinds[i])
      allBinds.del(i)
  
  
  proc nkb_unbind*(keystring: cstring, handler: PKeybindHandle) =
    for i in 0..allBinds.high:
      if keystring == allBinds[i].keystring and handler == allBinds[i].handler:
        when defined(Windows):
          discard UnRegisterHotKey(nkbWindow, allBinds[i].uid)
        else:
          discard nkb_ungrab_key(addr allBinds[i])
        allBinds.del(i)


proc nkb_set_use_cooked*(use: bool) =
  ## Set wether to use cooked accelerator or not. Disabled by default.
  useXkbExtension = use and detected_xkb_extension

proc nkb_set_multi_call*(use: bool) =
  ## Whether to allow registering multiple callbacks on the same key combination
  ## When false, only first registered callback will be called
  ## Default: ON
  allowMultipleCBs = use