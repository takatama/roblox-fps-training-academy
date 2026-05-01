local RankDefinitions = {
	{ level = 1, minXp = 0, title = "はじめてのPC操作" },
	{ level = 2, minXp = 50, title = "歩ける人" },
	{ level = 3, minXp = 130, title = "見られる人" },
	{ level = 4, minXp = 250, title = "狙える人" },
	{ level = 5, minXp = 420, title = "動ける人" },
	{ level = 6, minXp = 650, title = "FPS見習い" },
	{ level = 7, minXp = 900, title = "ミッション参加者" },
}

function RankDefinitions.GetRankForXp(xp)
	local selected = RankDefinitions[1]

	for _, rank in ipairs(RankDefinitions) do
		if xp >= rank.minXp then
			selected = rank
		end
	end

	return selected
end

return RankDefinitions
