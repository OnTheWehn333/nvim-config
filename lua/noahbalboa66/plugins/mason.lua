-- Mason is a searchable tool registry only; Nix owns all tool installation.
return {
	"mason-org/mason.nvim",
	cmd = "Mason",
	build = ":MasonUpdate",
	opts = {
		PATH = "skip",
	},
}
