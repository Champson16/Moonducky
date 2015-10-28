application = {
    showRuntimeErrors = true,
	content = {
    audioPlayFrequency = 44100, -- Added 10/28/2015 TRS
		width = 768,
		height = 1024,
		scale = "letterBox",
		fps = 60,
        antialias = false,

        imageSuffix = {
		    ["@2x"] = 0.5,
            ["@4x"] = 3.0
		}
	},
    launchPad = false

    --[[
    -- Push notifications

    notification =
    {
        iphone =
        {
            types =
            {
                "badge", "sound", "alert", "newsstand"
            }
        }
    }
    --]]
}
