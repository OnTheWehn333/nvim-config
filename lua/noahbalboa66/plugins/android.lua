return {
	"ariedov/android-nvim",
	config = function()
		-- OPTIONAL: specify android sdk directory
		vim.g.android_sdk = "~/programs"
		require("android-nvim").setup()
	end,
}
