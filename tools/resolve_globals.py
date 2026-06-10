import ctypes
import ctypes.wintypes as wt

EXE = r"E:\SteamLibrary\steamapps\common\Solarpunk\Solarpunk\Binaries\Win64\SolarpunkSteam-Win64-Shipping.exe"
BASE = 0x140000000
RUNTIME_BASE = 0x7FF7599E0000

PS_RESULTS = {
    "GUObjectArray": 0x7ff7610ad978,
    "GMalloc": 0x7ff76136d828,
    "FName::ToString": 0x7ff75ac0bb40,
}

dbghelp = ctypes.WinDLL("dbghelp.dll")
dbghelp.SymSetOptions(0x10)
hProc = ctypes.c_void_p(0x4343)
dbghelp.SymInitializeW.argtypes = [ctypes.c_void_p, ctypes.c_wchar_p, wt.BOOL]
dbghelp.SymInitializeW.restype = wt.BOOL
dbghelp.SymInitializeW(hProc, None, False)
dbghelp.SymLoadModuleExW.argtypes = [ctypes.c_void_p, ctypes.c_void_p, ctypes.c_wchar_p,
                                     ctypes.c_wchar_p, ctypes.c_uint64, wt.DWORD,
                                     ctypes.c_void_p, wt.DWORD]
dbghelp.SymLoadModuleExW.restype = ctypes.c_uint64
modbase = dbghelp.SymLoadModuleExW(hProc, None, EXE, None, BASE, 0, None, 0)

MAXN = 2000
class SI(ctypes.Structure):
    _fields_ = [("SizeOfStruct", ctypes.c_ulong),("TypeIndex", ctypes.c_ulong),
        ("Reserved", ctypes.c_uint64*2),("Index", ctypes.c_ulong),("Size", ctypes.c_ulong),
        ("ModBase", ctypes.c_uint64),("Flags", ctypes.c_ulong),("Value", ctypes.c_uint64),
        ("Address", ctypes.c_uint64),("Register", ctypes.c_ulong),("Scope", ctypes.c_ulong),
        ("Tag", ctypes.c_ulong),("NameLen", ctypes.c_ulong),("MaxNameLen", ctypes.c_ulong),
        ("Name", ctypes.c_char*(MAXN+1))]
dbghelp.SymFromName.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.POINTER(SI)]
dbghelp.SymFromName.restype = wt.BOOL

def rva(name):
    s = SI(); s.SizeOfStruct = 88; s.MaxNameLen = MAXN
    if dbghelp.SymFromName(hProc, name.encode(), ctypes.byref(s)):
        return s.Address - BASE
    return None

out = []
def p(x):
    out.append(str(x)); print(x, flush=True)

for name in ["GUObjectArray", "?GUObjectArray@@3VFUObjectArray@@A",
             "GMalloc", "GNatives", "GEngine", "FName::ToString",
             "FUObjectHashTables::Get", "GUObjectHashTables", "GUObjectHashTablesLock"]:
    r = rva(name)
    if r is None:
        p("%-45s -> NOT FOUND" % name)
    else:
        runtime = RUNTIME_BASE + r
        ps_key = name if name in PS_RESULTS else None
        extra = ""
        if name in PS_RESULTS:
            match = "MATCH" if PS_RESULTS[name] == runtime else "MISMATCH (PS=0x%X)" % PS_RESULTS[name]
            extra = "  [PS %s]" % match
        p("%-45s RVA=0x%-9X runtime=0x%X%s" % (name, r, runtime, extra))

with open(r"d:\AI\AI_Projects\MODS\SolarPunk\tools\globals_log.txt", "w", encoding="utf-8") as f:
    f.write("\n".join(out))
p("DONE")
