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
      ["@2x"] = 1.5
		}
	},
  launchPad = false,

  license = {
    google = {
      key = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAjrKoAclqoODts8Mg7upQcD1EiyT3kL/1AW2mbRplEI+BD/X4OvsZSKlKGUqpN0CP8z5BziNq+OS87R8hOJMFkxDqUTV6W0tKDvd82B1Nh+fMRa4UZpiUhwbTFgswe/Mv330jhv4biUH9rWO8eiIdtMHxNToRJJr4KVG+y9wrxmLST9vInwTAaVhJRP614isDDwApsU35Gxxnh2DwW+s0fPsCygcomdviywdexM+Dm/tHE5oKmJ/eKARmbZXe9iHLSxviazOipUW6fBbd8FKifkCvxmn3UUilGhYxfWLK/WqUWliMIWNBqJpxrvzMmkz9H5FWXFPNU9jDneBNg2s+aQIDAQAB",
      -- The "policy" key is optional. Its value can be either "serverManaged" (default) or "strict".
      -- A value of "serverManaged" will query the Google server and cache the results (this is similar to Google's "ServerManagedPolicy").
      -- A value of "strict" will not cache the results, so when there's a network failure, the licensing will fail (this is similar to Google's "StrictPolicy").
      policy = "serverManaged"
    }
  },

  -- Push notifications
  notification =
  {
    google =
    {
        projectNumber = "709462375959"
    },
    iphone =
      {
          types =
          {
              "badge", "sound", "alert", "newsstand"
          }
      }
  }
}
