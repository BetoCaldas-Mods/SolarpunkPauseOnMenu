import ctypes
import ctypes.wintypes as wt
import os
import sys

EXE = r"E:\SteamLibrary\steamapps\common\Solarpunk\Solarpunk\Binaries\Win64\SolarpunkSteam-Win64-Shipping.exe"
SIG_DIR = r"E:\SteamLibrary\steamapps\common\Solarpunk\Solarpunk\Binaries\Win64\ue4ss\UE4SS_Signatures"
REPORT = r"d:\AI\AI_Projects\MODS\SolarPunk\_pdb_report.txt"
BASE = 0x140000000

lines = []
def rep(s):
    s = str(s)
    lines.append(s)
    print(s, flush=True)

dbghelp = ctypes.WinDLL("dbghelp.dll")
SYMOPT_LOAD_LINES = 0x10
dbghelp.SymSetOptions(SYMOPT_LOAD_LINES)  # decorated names (no UNDNAME)

hProc = ctypes.c_void_p(0x4242)
dbghelp.SymInitializeW.argtypes = [ctypes.c_void_p, ctypes.c_wchar_p, wt.BOOL]
dbghelp.SymInitializeW.restype = wt.BOOL
rep("SymInitialize: %s" % bool(dbghelp.SymInitializeW(hProc, None, False)))

dbghelp.SymLoadModuleExW.argtypes = [ctypes.c_void_p, ctypes.c_void_p, ctypes.c_wchar_p,
                                     ctypes.c_wchar_p, ctypes.c_uint64, wt.DWORD,
                                     ctypes.c_void_p, wt.DWORD]
dbghelp.SymLoadModuleExW.restype = ctypes.c_uint64
modbase = dbghelp.SymLoadModuleExW(hProc, None, EXE, None, BASE, 0, None, 0)
rep("Module base: 0x%X" % modbase)

MAX_SYM_NAME = 2000
class SYMBOL_INFO(ctypes.Structure):
    _fields_ = [
        ("SizeOfStruct", ctypes.c_ulong),
        ("TypeIndex", ctypes.c_ulong),
        ("Reserved", ctypes.c_uint64 * 2),
        ("Index", ctypes.c_ulong),
        ("Size", ctypes.c_ulong),
        ("ModBase", ctypes.c_uint64),
        ("Flags", ctypes.c_ulong),
        ("Value", ctypes.c_uint64),
        ("Address", ctypes.c_uint64),
        ("Register", ctypes.c_ulong),
        ("Scope", ctypes.c_ulong),
        ("Tag", ctypes.c_ulong),
        ("NameLen", ctypes.c_ulong),
        ("MaxNameLen", ctypes.c_ulong),
        ("Name", ctypes.c_char * (MAX_SYM_NAME + 1)),
    ]

dbghelp.SymFromName.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.POINTER(SYMBOL_INFO)]
dbghelp.SymFromName.restype = wt.BOOL

def sym_from_name(name):
    s = SYMBOL_INFO()
    s.SizeOfStruct = 88
    s.MaxNameLen = MAX_SYM_NAME
    ok = dbghelp.SymFromName(hProc, name.encode("ascii"), ctypes.byref(s))
    if not ok:
        return None
    return s.Address - BASE

# ---- PE parsing ----
with open(EXE, "rb") as f:
    image = f.read()
e_lfanew = int.from_bytes(image[0x3C:0x40], "little")
num_sections = int.from_bytes(image[e_lfanew+6:e_lfanew+8], "little")
size_opt = int.from_bytes(image[e_lfanew+20:e_lfanew+22], "little")
sec_off = e_lfanew + 24 + size_opt
sections = []
for i in range(num_sections):
    o = sec_off + i*40
    vsize = int.from_bytes(image[o+8:o+12], "little")
    vaddr = int.from_bytes(image[o+12:o+16], "little")
    rawsize = int.from_bytes(image[o+16:o+20], "little")
    rawptr = int.from_bytes(image[o+20:o+24], "little")
    sections.append((vaddr, vsize, rawptr, rawsize))

def rva_to_off(rva):
    for vaddr, vsize, rawptr, rawsize in sections:
        if vaddr <= rva < vaddr + max(vsize, rawsize):
            return rawptr + (rva - vaddr)
    return None

def read_bytes(rva, n):
    off = rva_to_off(rva)
    if off is None:
        return None
    return image[off:off+n]

def to_aob(bs):
    return " ".join("%02X" % b for b in bs)

def count_occ(pattern):
    cnt, start = 0, 0
    while True:
        idx = image.find(pattern, start)
        if idx == -1:
            break
        cnt += 1
        start = idx + 1
    return cnt

def make_unique_aob(rva, min_len=32, max_len=120):
    n = min_len
    while n <= max_len:
        bs = read_bytes(rva, n)
        if not bs or len(bs) < n:
            return None
        if count_occ(bs) == 1:
            return to_aob(bs)
        n += 4
    return None

# Candidate decorated/undecorated names
fname_candidates = [
    "??0FName@@QEAA@PEB_WW4EFindName@@@Z",
    "??0FName@@QEAA@PEB_WW4EFindName@@H@Z",
    "??0FName@@QEAA@PEB_W@Z",
    "??0FName@@QEAA@PEB_WH@Z",
    "??0FName@@QEAA@PB_WW4EFindName@@@Z",
]
scoi_candidates = [
    "StaticConstructObject_Internal",
    "?StaticConstructObject_Internal@@YAPEAVUObject@@AEBUFStaticConstructObjectParameters@@@Z",
    "?StaticConstructObject_Internal@@YAPEAVUObject@@PEBVUClass@@PEAVUObject@@VFName@@W4EObjectFlags@@W4EInternalObjectFlags@@PEBV1@_NPEAVFObjectInstancingGraph@@PEAVUPackage@@@Z",
]
hashtables_candidates = [
    "FUObjectHashTables::Get",
    "?Get@FUObjectHashTables@@SAAEAV1@XZ",
]

def resolve(cands):
    for c in cands:
        rva = sym_from_name(c)
        rep("  try %s -> %s" % (c, ("0x%X" % rva) if rva else "no"))
        if rva:
            return rva
    return None

rep("\n=== FName::FName(wchar_t*) ===")
fname_rva = resolve(fname_candidates)
rep("\n=== StaticConstructObject_Internal ===")
scoi_rva = resolve(scoi_candidates)
rep("\n=== FUObjectHashTables::Get ===")
ht_rva = resolve(hashtables_candidates)

os.makedirs(SIG_DIR, exist_ok=True)

def write_sig(filename, rva):
    if not rva:
        rep("  SKIP %s (no rva)" % filename)
        return
    aob = make_unique_aob(rva)
    if not aob:
        rep("  FAIL %s (no unique AOB at 0x%X)" % (filename, rva))
        return
    rep("  WROTE %s | RVA 0x%X | AOB(%d): %s" % (filename, rva, len(aob.split()), aob))
    content = ('function Register()\n    return "%s"\nend\n\n'
               'function OnMatchFound(MatchAddress)\n    return MatchAddress\nend\n') % aob
    with open(os.path.join(SIG_DIR, filename), "w") as f:
        f.write(content)

rep("\n=== GENERATE ===")
write_sig("FName_Constructor.lua", fname_rva)
write_sig("StaticConstructObject.lua", scoi_rva)
write_sig("GUObjectHashTables.lua", ht_rva)

with open(REPORT, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))
rep("\nDONE")
