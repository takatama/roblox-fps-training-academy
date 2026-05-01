local StageDefinitions = {
	Order = {
		"walk_basic",
		"look_targets",
		"jump_basic",
		"moving_targets",
		"avoid_hazards",
		"sprint_basic",
		"crouch_basic",
		"sprint_stop_targets",
		"jump_targets",
		"training_arena",
	},

	Stages = {
		walk_basic = {
			id = "walk_basic",
			title = "Stage 1: 歩く練習",
			shortTitle = "歩く練習",
			instruction = "Wで前に進み、マウスで向きを変えて、黄色いゴールへ行こう。",
			type = "goal",
			rewardXp = 50,
			rewardCoins = 10,
			spawnPosition = Vector3.new(0, 4, 34),
			basePosition = Vector3.new(0, 0, 70),
			goalPosition = Vector3.new(0, 1.2, 104),
		},

		look_targets = {
			id = "look_targets",
			title = "Stage 2: 見る・狙う練習",
			shortTitle = "見る・狙う練習",
			instruction = "画面中央の照準を的に合わせてクリックしよう。10個でクリアです。",
			type = "targets",
			targetCount = 10,
			rewardXp = 80,
			rewardCoins = 15,
			spawnPosition = Vector3.new(80, 4, 34),
			basePosition = Vector3.new(80, 0, 70),
		},

		moving_targets = {
			id = "moving_targets",
			title = "Stage 4: 動く的の練習",
			shortTitle = "動く的の練習",
			instruction = "ゆっくり動く的を5個クリックしよう。あせらなくて大丈夫です。",
			type = "moving_targets",
			targetCount = 5,
			rewardXp = 120,
			rewardCoins = 25,
			spawnPosition = Vector3.new(160, 4, 34),
			basePosition = Vector3.new(160, 0, 70),
		},

		jump_basic = {
			id = "jump_basic",
			title = "Stage 3: ジャンプ練習",
			shortTitle = "ジャンプ練習",
			instruction = "Spaceでジャンプして、低い段差と小さな穴を越えて黄色いゴールへ行こう。",
			type = "jump_course",
			rewardXp = 90,
			rewardCoins = 15,
			spawnPosition = Vector3.new(120, 4, 26),
			basePosition = Vector3.new(120, 0, 72),
			goalPosition = Vector3.new(120, 1.2, 112),
		},

		avoid_hazards = {
			id = "avoid_hazards",
			title = "Stage 5: 危険を避ける練習",
			shortTitle = "危険を避ける練習",
			instruction = "赤い床を避けて進もう。緑の床に乗ると、そこからやり直せます。",
			type = "hazard_course",
			rewardXp = 150,
			rewardCoins = 30,
			spawnPosition = Vector3.new(240, 4, 28),
			basePosition = Vector3.new(240, 0, 70),
			goalPosition = Vector3.new(240, 1.2, 116),
		},

		sprint_basic = {
			id = "sprint_basic",
			title = "Stage 6: ダッシュ練習",
			shortTitle = "ダッシュ練習",
			instruction = "Shiftを押しながらWで走ろう。長い道を進んで黄色いゴールへ行きます。",
			type = "sprint_course",
			rewardXp = 120,
			rewardCoins = 25,
			spawnPosition = Vector3.new(320, 4, 24),
			basePosition = Vector3.new(320, 0, 82),
			goalPosition = Vector3.new(320, 1.2, 146),
		},

		crouch_basic = {
			id = "crouch_basic",
			title = "Stage 7: しゃがみ練習",
			shortTitle = "しゃがみ練習",
			instruction = "Ctrlを1回押してしゃがみ、低いトンネルを通ろう。もう1回押すと立ちます。",
			type = "crouch_course",
			rewardXp = 130,
			rewardCoins = 25,
			spawnPosition = Vector3.new(400, 4, 32),
			basePosition = Vector3.new(400, 0, 78),
			goalPosition = Vector3.new(400, 1.2, 126),
		},

		sprint_stop_targets = {
			id = "sprint_stop_targets",
			title = "Stage 8: 走って止まって狙う練習",
			shortTitle = "走って止まって狙う",
			instruction = "Shiftで長い通路を走り、青い停止エリアで止まってから的を3個クリックしよう。",
			type = "sprint_stop_targets",
			targetCount = 3,
			rewardXp = 150,
			rewardCoins = 30,
			spawnPosition = Vector3.new(480, 4, 12),
			basePosition = Vector3.new(480, 0, 92),
		},

		jump_targets = {
			id = "jump_targets",
			title = "Stage 9: ジャンプして狙う練習",
			shortTitle = "ジャンプして狙う",
			instruction = "Spaceで足場をジャンプして進もう。最後の青い台に乗ると、奥の的が出ます。",
			type = "jump_targets",
			targetCount = 3,
			rewardXp = 170,
			rewardCoins = 35,
			spawnPosition = Vector3.new(560, 4, 22),
			basePosition = Vector3.new(560, 0, 78),
		},

		training_arena = {
			id = "training_arena",
			title = "Stage 10: トレーニングアリーナ",
			shortTitle = "アリーナ",
			instruction = "障害物のある広い部屋で、自律走行ロボットを4体クリックして停止させよう。",
			type = "training_arena",
			targetCount = 4,
			rewardXp = 220,
			rewardCoins = 50,
			spawnPosition = Vector3.new(640, 4, 46),
			basePosition = Vector3.new(640, 0, 82),
			goalPosition = Vector3.new(640, 1.2, 140),
		},
	},
}

function StageDefinitions.GetStage(stageId)
	return StageDefinitions.Stages[stageId]
end

function StageDefinitions.GetFirstStage()
	return StageDefinitions.Stages[StageDefinitions.Order[1]]
end

function StageDefinitions.GetNextStage(stageId)
	for index, id in ipairs(StageDefinitions.Order) do
		if id == stageId then
			local nextId = StageDefinitions.Order[index + 1]
			if nextId then
				return StageDefinitions.Stages[nextId]
			end
		end
	end

	return nil
end

return StageDefinitions
