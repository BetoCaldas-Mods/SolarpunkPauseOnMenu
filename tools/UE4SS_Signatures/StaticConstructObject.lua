function Register()
    return "48 8B C4 48 89 58 10 48 89 70 18 48 89 78 20 55 41 54 41 55 41 56 41 57 48 8D A8 38 FE FF FF 48 81 EC A0 02 00 00 48 8B 05 77 D9 2C"
end

function OnMatchFound(MatchAddress)
    return MatchAddress
end
