import gtk2
include ../nkb

proc quit(widget: PWidget, data: Pgpointer) =
  main_quit()

proc nkb_test_handle(keystring: cstring, data: pointer) =
  echo "Callback 1: $1 has been pressed." % $keystring

proc nkb_test_handle2(keystring: cstring, data: pointer) =
  echo "Callback 2: $1 has been pressed." % $keystring

proc nkb_test() =
  let keyStr: cstring = "<Ctrl><Shift>1"
  when defined(Windows):
    nkb_init() # Under windows, we dont need to use gtk or winapi
               # nkb will create a virtual window internaly to bind keys
    if not nkb_bind(keyStr, nkb_test_handle, nil,777):
      echo "Binding failed ! Exiting.."
      quit(QuitSuccess)
    echo "Please press $1" % $keyStr
    var message: MSG
    while(bool(GetMessage(addr message, kbWin, 0, 0))):
      discard TranslateMessage(addr message)
      discard DispatchMessage(addr message)

  else:
    nim_init() ## GTK must be initialized before nkb
    nkb_init() ## nkb must be initialized before any other call to library
    var winMain = window_new(gtk2.WINDOW_TOPLEVEL)
    winMain.set_size_request(200, 50)
    var btnQuit = button_new("Quit")
    discard OBJECT(btnQuit).signal_connect("clicked",
    SIGNAL_FUNC(multibind.quit), nil)
    winMain.add(btnQuit)
    winMain.show_all()

    if not nkb_bind(keyStr, nkb_test_handle, nil):
      echo "Binding failed ! Exiting.."
      main_quit()
    if not nkb_bind(keyStr, nkb_test_handle2, nil):
      echo "Binding 2 failed ! Exiting.."
      main_quit()
    echo "Press $1 to quite this program" % $keyStr
    main()


when isMainModule: nkb_test()
