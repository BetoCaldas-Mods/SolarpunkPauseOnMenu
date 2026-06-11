function Register()
    return "48 8D 05 33 EB 3F 06 48 C7 41 10 00 00 00 00 48"
end

function OnMatchFound(MatchAddress)
    local Offset = MatchAddress + 0x3
    local NextInstr = MatchAddress + 0x7
    return NextInstr + DerefToInt32(Offset)
end
