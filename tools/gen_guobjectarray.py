import ctypes, ctypes.wintypes as wt, re, os

EXE = r"E:\SteamLibrary\steamapps\common\Solarpunk\Solarpunk\Binaries\Win64\SolarpunkSteam-Win64-Shipping.exe"
SIG_DIR = r"E:\SteamLibrary\steamapps\common\Solarpunk\Solarpunk\Binaries\Win64\ue4ss\UE4SS_Signatures"
BASE = 0x140000000

out = []
def p(x):
    out.append(str(x)); print(x, flush=True)

# ---- resolve GUObjectArray RVA via PDB ----
dbghelp = ctypes.WinDLL("dbghelp.dll")
dbghelp.SymSetOptions(0x10)
hProc = ctypes.c_void_p(0x4477)
dbghelp.SymInitializeW.argtypes=[ctypes.c_void_p,ctypes.c_wchar_p,wt.BOOL]; dbghelp.SymInitializeW.restype=wt.BOOL
dbghelp.SymInitializeW(hProc, None, False)
dbghelp.SymLoadModuleExW.argtypes=[ctypes.c_void_p,ctypes.c_void_p,ctypes.c_wchar_p,ctypes.c_wchar_p,ctypes.c_uint64,wt.DWORD,ctypes.c_void_p,wt.DWORD]
dbghelp.SymLoadModuleExW.restype=ctypes.c_uint64
modbase=dbghelp.SymLoadModuleExW(hProc,None,EXE,None,BASE,0,None,0)
MAXN=2000
class SI(ctypes.Structure):
    _fields_=[("SizeOfStruct",ctypes.c_ulong),("TypeIndex",ctypes.c_ulong),("Reserved",ctypes.c_uint64*2),
    ("Index",ctypes.c_ulong),("Size",ctypes.c_ulong),("ModBase",ctypes.c_uint64),("Flags",ctypes.c_ulong),
    ("Value",ctypes.c_uint64),("Address",ctypes.c_uint64),("Register",ctypes.c_ulong),("Scope",ctypes.c_ulong),
    ("Tag",ctypes.c_ulong),("NameLen",ctypes.c_ulong),("MaxNameLen",ctypes.c_ulong),("Name",ctypes.c_char*(MAXN+1))]
dbghelp.SymFromName.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.POINTER(SI)]; dbghelp.SymFromName.restype=wt.BOOL
def rva(name):
    s=SI(); s.SizeOfStruct=88; s.MaxNameLen=MAXN
    return (s.Address-BASE) if dbghelp.SymFromName(hProc,name.encode(),ctypes.byref(s)) else None

GUOBJ = rva("GUObjectArray")
p("GUObjectArray RVA = 0x%X" % GUOBJ)

# ---- PE parse ----
with open(EXE,"rb") as f: image=f.read()
e=int.from_bytes(image[0x3C:0x40],"little")
nsec=int.from_bytes(image[e+6:e+8],"little"); sopt=int.from_bytes(image[e+20:e+22],"little")
so=e+24+sopt; secs=[]
for i in range(nsec):
    o=so+i*40
    secs.append((int.from_bytes(image[o+12:o+16],"little"),  # vaddr
                 int.from_bytes(image[o+8:o+12],"little"),    # vsize
                 int.from_bytes(image[o+20:o+24],"little"),   # rawptr
                 int.from_bytes(image[o+16:o+20],"little"),   # rawsize
                 image[o:o+8].rstrip(b"\x00").decode("ascii","replace")))
def off_to_rva(off):
    for vaddr,vsize,rawptr,rawsize,name in secs:
        if rawptr<=off<rawptr+rawsize: return vaddr+(off-rawptr)
    return None
def rva_to_off(r):
    for vaddr,vsize,rawptr,rawsize,name in secs:
        if vaddr<=r<vaddr+max(vsize,rawsize): return rawptr+(r-vaddr)
    return None

# ---- find RIP-relative references (lea/mov) to GUObjectArray ----
modrm_set = {0x05,0x0D,0x15,0x1D,0x25,0x2D,0x35,0x3D}
pat = re.compile(rb"[\x48\x4C][\x8D\x8B].", re.S)
refs = []
for m in pat.finditer(image):
    off = m.start()
    if image[off+2] not in modrm_set:
        continue
    r = off_to_rva(off)
    if r is None:
        continue
    disp = int.from_bytes(image[off+3:off+7], "little", signed=True)
    target = r + 7 + disp
    if target == GUOBJ:
        refs.append((off, r, image[off+1]))  # off, instr_rva, opcode(8D/8B)

p("Found %d RIP-relative references to GUObjectArray" % len(refs))
# Prefer LEA (0x8D)
refs.sort(key=lambda x: 0 if x[2]==0x8D else 1)

def count_occ(b):
    c=0; s=0
    while True:
        i=image.find(b,s)
        if i==-1: break
        c+=1; s=i+1
    return c

chosen=None
for off, r, op in refs[:20]:
    n=7
    while n<=40:
        bs=image[off:off+n]
        if count_occ(bs)==1:
            chosen=(off,r,op,bs); break
        n+=1
    if chosen: break

if not chosen:
    p("ERROR: could not build a unique AOB for any GUObjectArray reference")
else:
    off,r,op,bs=chosen
    aob=" ".join("%02X"%x for x in bs)
    kind = "LEA" if op==0x8D else "MOV"
    p("Chosen %s at RVA 0x%X | AOB(%d, occ=1): %s" % (kind, r, len(bs), aob))
    content = (
        'function Register()\n'
        '    return "%s"\n'
        'end\n\n'
        'function OnMatchFound(MatchAddress)\n'
        '    local Offset = MatchAddress + 0x3\n'
        '    local NextInstr = MatchAddress + 0x7\n'
        '    return NextInstr + DerefToInt32(Offset)\n'
        'end\n'
    ) % aob
    os.makedirs(SIG_DIR, exist_ok=True)
    with open(os.path.join(SIG_DIR,"GUObjectArray.lua"),"w") as f:
        f.write(content)
    p("WROTE GUObjectArray.lua")

with open(r"d:\AI\AI_Projects\MODS\SolarPunk\tools\guobj_log.txt","w",encoding="utf-8") as f:
    f.write("\n".join(out))
p("DONE")
