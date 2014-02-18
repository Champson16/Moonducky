application = {
    showRuntimeErrors = true,
	content = {
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