## Those are missing from pure gdk2

proc window_get_display*(win: gdk2.PWindow): gdk2.PDisplay{.cdecl, dynlib: lib,
    importc: "gdk_window_get_display".}
proc window_add_filter* (window: gdk2.PWindow, function: TFilterFunc,data: gpointer): gboolean{.cdecl, dynlib: lib,
    importc: "gdk_window_add_filter".}

proc TFILTER_CALLBACK*(f: pointer): TFilterFunc =
  result = cast[TFilterFunc](f)
proc keymap_get_default* ():PKeyMap{.cdecl, dynlib: lib,
    importc: "gdk_keymap_get_default".}
proc keymap_have_bidi_layouts* (keymap: PKeyMap):gboolean{.cdecl, dynlib: lib,
    importc: "gdk_keymap_have_bidi_layouts".}
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
