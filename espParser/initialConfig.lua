local keyOrder = {
    "espPath",
    "preload",
    "useRequiredDataFiles",
    "requiredDataFiles",
    "files",
}

local values = {
    espPath = "custom/esps/",
    preload = true,
    useRequiredDataFiles = true,
    requiredDataFiles = "requiredDataFiles.json",
    files = {},
}

return { keyOrder = keyOrder, values = values }