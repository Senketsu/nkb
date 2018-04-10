include ../nkb
when not defined(Windows):
  import gtk2

proc nkb_test_handle(keystring: cstring, data: pointer) =
  stdout.write("Hello ")

proc nkb_test_handle2(keystring: cstring, data: pointer) =
  stdout.write("world.")
  quit(QuitSuccess)

proc nkb_test() =
  let keyStr: cstring = "<Ctrl><Shift>1"
  let keyStr2: cstring = "<Ctrl><ALT>1"
  when not defined(Windows):
    nim_init()
  nkb_init() # Under windows, we dont need to use gtk or winapi
             # nkb will create a virtual window internaly to bind keys
  if not nkb_bind(keyStr, nkb_test_handle, nil,777):
    echo "Binding '$1' failed ! Exiting.." % $keyStr
    quit(QuitSuccess)
  if not nkb_bind(keyStr2, nkb_test_handle2, nil,778):
    echo "Binding '$1' failed ! Exiting.." % $keyStr2
    quit(QuitSuccess)
  echo "Please press $1 & $2" % [$keyStr, $keyStr2]
  when not defined(Windows):
    var winMain = window_new(gtk2.WINDOW_TOPLEVEL)
    winMain.set_size_request(200, 50)
    winMain.show_all()
    main()
  else:
    var message: MSG
    while(bool(GetMessage(addr message, nkbWindow, 0, 0))):
      discard TranslateMessage(addr message)
      discard DispatchMessage(addr message)



when isMainModule: nkb_test()
