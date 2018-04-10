# Nim Key Binder library (nkb)
This library was made for [Pomf It !](https://github.com/Senketsu/pomfit)

## About:
Basically Nim version of keybinder library for C with added Windows support.*  
***On Windows** it uses the win32 api to register keybinds but saves you from the hasle of using win32 api at all if you choose so.  
(e.g: your application uses GTK exclusively)

Huge credits go to original developers of keybinder.  
Check [keybinder on GitHub](https://github.com/engla/keybinder).

### Usage:
------------------------
Use compiler option -d:threads along with --threads:on.
(as of now, I'm not aware of way to detect the --threads option)  
`nkb_init()`  
  Initializes the nkb library , **MUST be called before any other library calls**.


`nkb_set_use_cooked (bool)`  
  Set wether to use cooked accelerators. GTK/linux only  
  Default: OFF  

`nkb_bind(keystring: cstring, handler: PKeybindHandle, user_data: pointer, uID: cuint): bool`  
  Procedure to register a procedure to a hotkey.  
  **Keystring** must valid gtk accel string e.g `<CTRL>i`  
  **Handler** is a proc pointer of PKeybindHandle type (keystring: cstring, data: pointer)  
  **User_data** will be supplied to handler. Can be nil.  
  **uID** is unique identifier for this hotkey (used only on Windows). Can be ommited. Will be generated if not specified.  
  Returns *bool* value of true if bind was successful.

`nkb_unbind(keystring: cstring, handle: PKeybindHandle)`  
  Self descriptive.

`nkb_unbind_all()`  
  Unbinds all keybinds.  

### Requirements
------------------------
This library depends on `gtk2` & `x11` for linux / `oldwinapi` for windows  
packages from the official [Nimble](https://github.com/nim-lang/nimble) repository.

### Contact
* Feedback , thoughts , bug reports ?
* Feel free to contact me on [twitter](https://twitter.com/Senketsu_Dev) ,or visit [stormbit IRC network](https://kiwiirc.com/client/irc.stormbit.net/?nick=Guest|?#Senketsu)
* Or create [issue](https://github.com/Senketsu/nkb/issues) on this Github page.
