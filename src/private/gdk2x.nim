{.deadCodeElim: on.}
import gdk2, glib2, gdk2pixbuf, pango, cairo
import x, xlib , xutil

when defined(win32):
  const
    lib = "libgdk-win32-2.0-0.dll"
elif declared(gtk_quartz):
  const
    lib = "libgdk-quartz-2.0.dylib"
elif defined(macosx):
  const
    lib = "libgdk-x11-2.0.dylib"
else:
  const
    lib = "libgdk-x11-2.0.so(|.0)"

proc is_destroyed*(window: gdk2.PWindow): gboolean {.cdecl, dynlib: lib,
    importc: "window_is_destroyed".}

const
 PARENT_RELATIVE_BG* = (cast[gdk2.PPixmap](1))
 NO_BG* = (cast[gdk2.PPixmap](2))

when not defined(COMPILATION):
  template WINDOW_TYPE*(d: expr): expr =
    (get_window_type(WINDOW(d)))

  template WINDOW_DESTROYED*(d: expr): expr =
    (is_destroyed(WINDOW(d)))

proc destroy_notify*(window: gdk2.PWindow) {.cdecl,
    dynlib: lib, importc: "window_destroy_notify".}
proc synthesize_window_state*(window: gdk2.PWindow, unset_flags: gdk2.PWindowState,
  set_flags: gdk2.PWindowState) {.cdecl, dynlib: lib, importc: "synthesize_window_state".}

template UNITS_OVERFLOWS*(x, y: expr): expr =
  (G_UNLIKELY((y) >= PIXELS(G_MAXINT - SCALE) div 2 or
      (x) >= PIXELS(G_MAXINT - SCALE) div 2 or
      (y) <= - (PIXELS(G_MAXINT - SCALE) div 2) or
      (x) <= - (PIXELS(G_MAXINT - SCALE) div 2)))


when (not defined(DISABLE_DEPRECATED) and not defined(MULTIHEAD_SAFE)) or
    defined(COMPILATION):
  var display*: gdk2.PDisplay

proc x11_drawable_get_xdisplay*(drawable: gdk2.PDrawable): xlib.PDisplay  {.cdecl,
 dynlib: lib, importc: "gdk_x11_drawable_get_xdisplay".}
proc x11_drawable_get_xid*(drawable: gdk2.PDrawable): TXID  {.cdecl,
 dynlib: lib, importc: "gdk_x11_drawable_get_xid".}
proc x11_window_get_drawable_impl*(window: gdk2.PWindow): gdk2.PDrawable {.cdecl,
 dynlib: lib, importc: "gdk_x11_window_get_drawable_impl".}
proc x11_pixmap_get_drawable_impl*(pixmap: gdk2.PPixmap): gdk2.PDrawable {.cdecl,
 dynlib: lib, importc: "gdk_x11_pixmap_get_drawable_impl".}
proc x11_image_get_xdisplay*(image: PImage): xlib.PDisplay {.cdecl,
 dynlib: lib, importc: "gdk_x11_image_get_xdisplay".}
proc x11_image_get_ximage*(image: PImage): PXImage {.cdecl,
 dynlib: lib, importc: "gdk_x11_image_get_ximage".}
proc x11_colormap_get_xdisplay*(colormap: gdk2.PColormap): xlib.PDisplay {.cdecl,
 dynlib: lib, importc: "gdk_x11_colormap_get_xdisplay".}
proc x11_colormap_get_xcolormap*(colormap: gdk2.PColormap): x.PColormap {.cdecl,
 dynlib: lib, importc: "gdk_x11_colormap_get_xcolormap".}
proc x11_cursor_get_xdisplay*(cursor: gdk2.PCursor): xlib.PDisplay {.cdecl,
 dynlib: lib, importc: "gdk_x11_cursor_get_xdisplay".}
proc x11_cursor_get_xcursor*(cursor: gdk2.PCursor): x.PCursor {.cdecl,
 dynlib: lib, importc: "gdk_x11_cursor_get_xcursor".}
proc x11_display_get_xdisplay*(display: gdk2.PDisplay): xlib.PDisplay {.cdecl,
 dynlib: lib, importc: "gdk_x11_display_get_xdisplay".}
proc x11_visual_get_xvisual*(visual: gdk2.PVisual): xlib.PVisual {.cdecl,
 dynlib: lib, importc: "gdk_x11_visual_get_xvisual".}

when not defined(DISABLE_DEPRECATED) or defined(COMPILATION):
  proc x11_gc_get_xdisplay*(gc: gdk2.PGC): gdk2.PDisplay {.cdecl,
    dynlib: lib, importc: "gdk_x11_gc_get_xdisplay".}
  proc x11_gc_get_xgc*(gc: gdk2.PGC): xlib.PGC {.cdecl,
    dynlib: lib, importc: "gdk_x11_gc_get_xgc".}

proc x11_screen_get_xscreen*(screen: gdk2.PScreen): xlib.PScreen {.cdecl,
    dynlib: lib, importc: "gdk_x11_screen_get_xscreen".}
proc x11_screen_get_screen_number*(screen: gdk2.PScreen): cint {.cdecl,
    dynlib: lib, importc: "gdk_x11_screen_get_screen_number".}
proc x11_window_set_user_time*(window: gdk2.PWindow, timestamp: guint32) {.cdecl,
    dynlib: lib, importc: "gdk_x11_window_set_user_time".}
proc x11_window_move_to_current_desktop*(window: gdk2.PWindow) {.cdecl,
    dynlib: lib, importc: "gdk_x11_window_move_to_current_desktop".}
proc x11_screen_get_window_manager_name*(screen: gdk2.PScreen): cstring {.cdecl,
    dynlib: lib, importc: "gdk_x11_screen_get_window_manager_name".}

when not defined(MULTIHEAD_SAFE):
  proc x11_get_default_root_xwindow*(): x.PWindow {.cdecl,
    dynlib: lib, importc: "gdk_".}
  proc x11_get_default_xdisplay*(): xlib.PDisplay {.cdecl,
    dynlib: lib, importc: "gdk_x11_get_default_xdisplay".}
  proc x11_get_default_screen*(): gint {.cdecl,
    dynlib: lib, importc: "gdk_x11_get_default_screen".}

proc COLORMAP_XDISPLAY*(cmap: gdk2.PColormap): xlib.PDisplay =
  result = x11_colormap_get_xdisplay(cmap)
proc COLORMAP_XCOLORMAP*(cmap: gdk2.PColormap): x.PColormap =
  result = x11_colormap_get_xcolormap(cmap)
proc CURSOR_XDISPLAY*(cursor: gdk2.PCursor): xlib.PDisplay =
  result = x11_cursor_get_xdisplay(cursor)
proc CURSOR_XCURSOR*(cursor: gdk2.PCursor): x.PCursor =
  result = x11_cursor_get_xcursor(cursor)
proc IMAGE_XDISPLAY*(image: PImage): xlib.PDisplay =
  result = x11_image_get_xdisplay(image)
proc IMAGE_XIMAGE*(image: PImage): PXImage =
  result = x11_image_get_ximage(image)

when (not defined(DISABLE_DEPRECATED) and not defined(MULTIHEAD_SAFE)) or
    defined(COMPILATION):
  proc DISPLAY*(): gdk2.PDisplay =
    result = gdk2x.display

proc x11_screen_lookup_visual*(screen: gdk2.PScreen,
   xvisualid: x.PVisualID): gdk2.PVisual {.cdecl,
    dynlib: lib, importc: "gdk_x11_screen_lookup_visual".}

when not defined(DISABLE_DEPRECATED):
  when not defined(MULTIHEAD_SAFE):
    proc gdkx_visual_get*(xvisualid: x.PVisualID): gdk2.PVisual {.cdecl,
      dynlib: lib, importc: "gdkx_visual_get".}

when defined(ENABLE_BROKEN):
  proc gdkx_colormap_get*(xcolormap: x.PColormap): gdk2.PColormap {.cdecl,
    dynlib: lib, importc: "gdkx_colormap_get".}

proc x11_colormap_foreign_new*(visual: gdk2.PVisual,
 xcolormap: x.PColormap): gdk2.PColormap {.cdecl,
    dynlib: lib, importc: "gdk_x11_colormap_foreign_new".}
when not defined(DISABLE_DEPRECATED) or defined(COMPILATION):
  proc xid_table_lookup_for_display*(display: gdk2.PDisplay; xid: PXID): gpointer {.cdecl,
    dynlib: lib, importc: "gdk_xid_table_lookup_for_display".}

proc x11_get_server_time*(window: gdk2.PWindow): guint32 {.cdecl,
    dynlib: lib, importc: "gdk_x11_get_server_time".}
proc x11_display_get_user_time*(display: gdk2.PDisplay): guint32 {.cdecl,
    dynlib: lib, importc: "gdk_x11_display_get_user_time".}
proc x11_display_get_startup_notification_id*(display: gdk2.PDisplay): PPgchar {.cdecl,
    dynlib: lib, importc: "gdk_x11_display_get_startup_notification_id".}
proc x11_display_set_cursor_theme*(display: gdk2.PDisplay, theme: PPgchar, size: gint) {.cdecl,
    dynlib: lib, importc: "gdk_x11_display_set_cursor_theme".}
proc x11_display_broadcast_startup_message*(display: gdk2.PDisplay,
    message_type: cstring) {.cdecl, varargs,
      dynlib: lib, importc: "gdk_x11_display_broadcast_startup_message".}
proc x11_screen_supports_net_wm_hint*(screen: gdk2.PScreen, property: gdk2.PAtom): gboolean {.cdecl,
    dynlib: lib, importc: "gdk_x11_screen_supports_net_wm_hint".}
proc x11_screen_get_monitor_output*(screen: gdk2.PScreen; monitor_num: gint): PXID {.cdecl,
    dynlib: lib, importc: "gdk_x11_screen_get_monitor_output".}

when not defined(MULTIHEAD_SAFE):
  when not defined(DISABLE_DEPRECATED):
    proc xid_table_lookup*(xid: PXID): gpointer {.cdecl,
      dynlib: lib, importc: "gdk_xid_table_lookup".}
    proc net_wm_supports*(property: gdk2.PAtom): gboolean {.cdecl,
      dynlib: lib, importc: "gdk_net_wm_supports".}
  proc x11_grab_server*() {.cdecl,
    dynlib: lib, importc: "gdk_x11_grab_server".}
  proc x11_ungrab_server*() {.cdecl,
    dynlib: lib, importc: "gdk_x11_ungrab_server".}

proc x11_lookup_xdisplay*(xdisplay: xlib.PDisplay): gdk2.PDisplay {.cdecl,
    dynlib: lib, importc: "gdk_x11_lookup_xdisplay".}
proc x11_atom_to_xatom_for_display*(display: gdk2.PDisplay,
    atom: gdk2.PAtom): x.PAtom {.cdecl,
      dynlib: lib, importc: "gdk_x11_atom_to_xatom_for_display".}
proc x11_xatom_to_atom_for_display*(display: gdk2.PDisplay,
    xatom: x.PAtom): gdk2.PAtom {.cdecl,
      dynlib: lib, importc: "gdk_x11_xatom_to_atom_for_display".}
proc x11_get_xatom_by_name_for_display*(display: gdk2.PDisplay,
    atom_name: PPgchar): x.PAtom {.cdecl,
      dynlib: lib, importc: "gdk_x11_get_xatom_by_name_for_display".}
proc x11_get_xatom_name_for_display*(display: gdk2.PDisplay,
    xatom: x.PAtom): PPgchar {.cdecl,
      dynlib: lib, importc: "gdk_x11_get_xatom_name_for_display".}

when not defined(MULTIHEAD_SAFE):
  proc x11_atom_to_xatom*(atom: gdk2.PAtom): x.PAtom {.cdecl,
    dynlib: lib, importc: "gdk_x11_atom_to_xatom".}
  proc x11_xatom_to_atom*(xatom: x.PAtom): gdk2.PAtom {.cdecl,
    dynlib: lib, importc: "gdk_x11_xatom_to_atom".}
  proc x11_get_xatom_by_name*(atom_name: PPgchar): x.PAtom {.cdecl,
    dynlib: lib, importc: "gdk_x11_get_xatom_by_name".}
  proc x11_get_xatom_name*(xatom: x.PAtom): PPgchar {.cdecl,
    dynlib: lib, importc: "gdk_x11_get_xatom_name".}


proc x11_display_grab*(display: gdk2.PDisplay) {.cdecl,
    dynlib: lib, importc: "gdk_x11_display_grab".}
proc x11_display_ungrab*(display: gdk2.PDisplay) {.cdecl,
    dynlib: lib, importc: "gdk_x11_display_ungrab".}
proc x11_register_standard_event_type*(display: gdk2.PDisplay,
    event_base: gint, n_events: gint) {.cdecl,
      dynlib: lib, importc: "gdk_x11_register_standard_event_type".}

when not defined(DISABLE_DEPRECATED) or defined(COMPILATION):
  proc x11_font_get_xfont*(font: gdk2.PFont): gpointer {.cdecl,
    dynlib: lib, importc: "gdk_x11_font_get_xfont".}
  proc FONT_XFONT*(font: gdk2.PFont): gpointer =
    result = x11_font_get_xfont(font)
  proc font_lookup_for_display*(display: gdk2.PDisplay, id: PXID): gdk2.PFont =
    result = cast[gdk2.PFont](xid_table_lookup_for_display(display,id))

when not defined(DISABLE_DEPRECATED):
  proc x11_font_get_xdisplay*(font: gdk2.PFont): xlib.PDisplay {.cdecl,
    dynlib: lib, importc: "gdk_x11_font_get_xdisplay".}
  proc x11_font_get_name*(font: gdk2.PFont): cstring {.cdecl,
    dynlib: lib, importc: "gdk_x11_font_get_name".}
  proc FONT_XDISPLAY*(font: gdk2.PFont): xlib.PDisplay =
    result = x11_font_get_xdisplay(font)

  when not defined(MULTIHEAD_SAFE):
    proc font_lookup*(xid: PXID): gdk2.PFont =
      result = cast[gdk2.PFont](xid_table_lookup(xid))

proc x11_set_sm_client_id*(sm_client_id: glib2.PPgchar) {.cdecl,
    dynlib: lib, importc: "gdk_x11_set_sm_client_id".}
proc x11_window_foreign_new_for_display*(display: gdk2.PDisplay,
    window: x.PWindow): gdk2.PWindow {.cdecl,
      dynlib: lib, importc: "gdk_x11_window_foreign_new_for_display".}
proc x11_window_lookup_for_display*(display: gdk2.PDisplay,
    window: x.PWindow): gdk2.PWindow {.cdecl,
      dynlib: lib, importc: "gdk_x11_window_lookup_for_display".}
proc x11_display_text_property_to_text_list*(display: gdk2.PDisplay,
    encoding: gdk2.PAtom, format: gint, text: PPguchar, length: gint,
    list: PPPgchar): gint {.cdecl,
      dynlib: lib, importc: "gdk_x11_display_text_property_to_text_list".}
proc x11_free_text_list*(list: PPgchar) {.cdecl,
    dynlib: lib, importc: "gdk_x11_free_text_list".}
proc x11_display_string_to_compound_text*(display: gdk2.PDisplay,
    str: PPgchar, encoding: gdk2.PAtom, format: gint,
    ctext: PPPgchar, length: gint): gint {.cdecl,
    dynlib: lib, importc: "gdk_x11_display_string_to_compound_text".}
proc x11_display_utf8_to_compound_text*(display: gdk2.PDisplay,
    str: PPgchar, encoding: gdk2.PAtom, format: gint,
    ctext: PPPgchar, length: gint): gboolean {.cdecl,
    dynlib: lib, importc: "gdk_x11_display_utf8_to_compound_text".}
proc x11_free_compound_text*(ctext: PPguchar) {.cdecl,
    dynlib: lib, importc: "gdk_x11_free_compound_text".}
proc window_get_display*(win: gdk2.PWindow): gdk2.PDisplay{.cdecl, dynlib: lib,
    importc: "gdk_window_get_display".}

proc TFILTER_CALLBACK*(f: pointer): TFilterFunc =
  result = cast[TFilterFunc](f)
proc DISPLAY_XDISPLAY*(display: gdk2.PDisplay): xlib.PDisplay =
  result = x11_display_get_xdisplay(display)
proc WINDOW_XDISPLAY*(win: gdk2.PWindow): xlib.PDisplay  =
  result = DISPLAY_XDISPLAY(window_get_display(win))
proc DRAWABLE_XID*(win: gdk2.PWindow): x.TXID =
  result = x11_drawable_get_xid(cast[gdk2.PDrawable](win))

proc keymap_get_default* ():PKeyMap{.cdecl, dynlib: lib,
    importc: "gdk_keymap_get_default".}
proc keymap_have_bidi_layouts* (keymap: PKeyMap):gboolean{.cdecl, dynlib: lib,
    importc: "gdk_keymap_have_bidi_layouts".}
proc window_add_filter* (window: gdk2.PWindow, function: TFilterFunc,data: gpointer): gboolean{.cdecl, dynlib: lib,
    importc: "gdk_window_add_filter".}
proc keymap_translate_keyboard_state* (keymap: gdk2.PKeyMap, hardware_keycode: cuint,
      state: gdk2.TModifierType, group: gint, keyval: Pguint, effective_group: Pgint,
      level: Pgint,consumed_modifiers: gdk2.PModifierType): gboolean{.cdecl, dynlib: lib,
    importc: "gdk_keymap_translate_keyboard_state".}
proc keymap_add_virtual_modifiers* (keymap: gdk2.PKeyMap, state: gdk2.PModifierType){.cdecl, dynlib: lib,
    importc: "gdk_keymap_add_virtual_modifiers".}
proc keymap_map_virtual_modifiers* (keymap: gdk2.PKeyMap, state: gdk2.PModifierType){.cdecl, dynlib: lib,
    importc: "gdk_keymap_map_virtual_modifiers".}
proc keymap_get_entries_for_keyval* (keymap: PKeymap, keyval: guint,
    s: ptr array[20,PKeymapKey], n_keys: Pgint): gboolean{.cdecl, dynlib: lib,
    importc: "gdk_keymap_get_entries_for_keyval".}
