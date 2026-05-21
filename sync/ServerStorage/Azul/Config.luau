-- Per-place Daemon configuration
-- This file is sent to the Daemon when it connects, and can be used to specify settings for this specific Place, such as push mappings.

-- More info about the format:
-- https://azul-docs.vercel.app/advanced-usage/#per-place-daemon-configuration

return {
	deleteOrphansOnConnect = true,
	pushMappings = {
		{
			source = "sync/ReplicatedStorage/SharedPackages",
			destination = { "ReplicatedStorage", "SharedPackages" },
			destructive = true,
			rojoMode = true,
		}
	}
}
			