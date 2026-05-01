local DataService = {}

function DataService.Init()
	-- MVPでは安全のため、まだDataStore保存は使いません。
	-- あとで保存を足してもゲームが止まらないように、この入口だけ用意しています。
end

function DataService.GetDefaultData()
	return {
		XP = 0,
		Coins = 0,
		Level = 1,
		RankTitle = "はじめてのPC操作",
		CompletedStages = {},
		BestAccuracyByStage = {},
		PracticeStreak = 0,
		Titles = {},
		StampCard = {},
	}
end

function DataService.LoadPlayer(_player)
	return DataService.GetDefaultData()
end

function DataService.SavePlayer(_player, _data)
	return true
end

return DataService
