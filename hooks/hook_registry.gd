enum HookType {
	BERSERK,
	STALK,
	NONE
}

static func get_hook(hook_type : HookType):
	match(hook_type):
		HookType.BERSERK:
			return AbilityBerserkHook.new()
		HookType.STALK:
			return AbilityStalkHook.new()
		_:
			return null
	
