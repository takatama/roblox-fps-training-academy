local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")

local Localization = {}
local translator = nil
local translatorLoadAttempted = false

local STRINGS = {
	en = {
		["ui.loading"] = "Loading... Press M to open stage select.",
		["ui.stageSelectTitle"] = "M: Stage Select",
		["ui.movingToStage"] = "Moving to {stage}",
		["ui.clear"] = "Clear!",
		["ui.clearReward"] = "Clear! XP +{xp} / Coins +{coins}",
		["ui.alreadyCleared"] = "Already cleared. Moving to the next training.",
		["ui.hit"] = "Hit! {hit} / {total}",
		["ui.inputHints"] = "WASD: Move    Mouse: Look    Click: Target    Shift: Sprint    Ctrl: Crouch    M: Menu",
		["progress.checkpoint"] = "Checkpoint",
		["progress.hazardReturn"] = "Red floor! Returning",
		["progress.goToExit"] = "Go to the exit",
		["ranks.1"] = "First PC Steps",
		["ranks.2"] = "Walker",
		["ranks.3"] = "Look Around",
		["ranks.4"] = "Aimer",
		["ranks.5"] = "Mover",
		["ranks.6"] = "FPS Trainee",
		["ranks.7"] = "Mission Ready",

		["stages.walk_basic.title"] = "Stage 1: Walk Practice",
		["stages.walk_basic.short"] = "Walk",
		["stages.walk_basic.instruction"] = "Press W to move forward, turn with the mouse, and reach the yellow goal.",

		["stages.look_targets.title"] = "Stage 2: Look and Aim",
		["stages.look_targets.short"] = "Look and Aim",
		["stages.look_targets.instruction"] = "Put the crosshair on the targets and click them. Clear all 10 targets.",

		["stages.jump_basic.title"] = "Stage 3: Jump Practice",
		["stages.jump_basic.short"] = "Jump",
		["stages.jump_basic.instruction"] = "Press Space to jump over steps and gaps, then reach the yellow goal.",

		["stages.moving_targets.title"] = "Stage 4: Moving Targets",
		["stages.moving_targets.short"] = "Moving Targets",
		["stages.moving_targets.instruction"] = "Click 5 slowly moving targets. Take your time.",

		["stages.avoid_hazards.title"] = "Stage 5: Avoid Hazards",
		["stages.avoid_hazards.short"] = "Avoid Hazards",
		["stages.avoid_hazards.instruction"] = "Avoid the red floor. Green pads are checkpoints.",

		["stages.sprint_basic.title"] = "Stage 6: Sprint Practice",
		["stages.sprint_basic.short"] = "Sprint",
		["stages.sprint_basic.instruction"] = "Hold Shift and W to sprint down the long path to the yellow goal.",

		["stages.crouch_basic.title"] = "Stage 7: Crouch Practice",
		["stages.crouch_basic.short"] = "Crouch",
		["stages.crouch_basic.instruction"] = "Press Ctrl once to crouch and pass through the low tunnel. Press it again to stand.",

		["stages.sprint_stop_targets.title"] = "Stage 8: Sprint, Stop, Aim",
		["stages.sprint_stop_targets.short"] = "Sprint and Aim",
		["stages.sprint_stop_targets.instruction"] = "Sprint down the corridor, stop on the blue area, then click 3 targets.",

		["stages.jump_targets.title"] = "Stage 9: Jump and Aim",
		["stages.jump_targets.short"] = "Jump and Aim",
		["stages.jump_targets.instruction"] = "Jump across the platforms. The targets appear when you reach the final blue pad.",

		["stages.training_arena.title"] = "Stage 10: Training Arena",
		["stages.training_arena.short"] = "Arena",
		["stages.training_arena.instruction"] = "In a wide obstacle arena, click and destroy 4 autonomous training robots.",
	},

	ja = {
		["ui.loading"] = "読み込み中です... Mキーでステージ選択を開けます。",
		["ui.stageSelectTitle"] = "M: ステージ選択",
		["ui.movingToStage"] = "{stage}へ移動します",
		["ui.clear"] = "クリア！",
		["ui.clearReward"] = "クリア！ XP +{xp} / Coins +{coins}",
		["ui.alreadyCleared"] = "クリア済みです。次の練習へ進みます。",
		["ui.hit"] = "命中！ {hit} / {total}",
		["ui.inputHints"] = "WASD: 移動    マウス: 見る    クリック: 的を押す    Shift: 走る    Ctrl: しゃがむ    M: メニュー",
		["progress.checkpoint"] = "チェックポイント",
		["progress.hazardReturn"] = "赤い床！戻ります",
		["progress.goToExit"] = "出口へ向かおう",
		["ranks.1"] = "はじめてのPC操作",
		["ranks.2"] = "歩ける人",
		["ranks.3"] = "見られる人",
		["ranks.4"] = "狙える人",
		["ranks.5"] = "動ける人",
		["ranks.6"] = "FPS見習い",
		["ranks.7"] = "ミッション参加者",

		["stages.walk_basic.title"] = "Stage 1: 歩く練習",
		["stages.walk_basic.short"] = "歩く練習",
		["stages.walk_basic.instruction"] = "Wで前に進み、マウスで向きを変えて、黄色いゴールへ行こう。",

		["stages.look_targets.title"] = "Stage 2: 見る・狙う練習",
		["stages.look_targets.short"] = "見る・狙う練習",
		["stages.look_targets.instruction"] = "画面中央の照準を的に合わせてクリックしよう。10個でクリアです。",

		["stages.jump_basic.title"] = "Stage 3: ジャンプ練習",
		["stages.jump_basic.short"] = "ジャンプ練習",
		["stages.jump_basic.instruction"] = "Spaceでジャンプして、低い段差と小さな穴を越えて黄色いゴールへ行こう。",

		["stages.moving_targets.title"] = "Stage 4: 動く的の練習",
		["stages.moving_targets.short"] = "動く的の練習",
		["stages.moving_targets.instruction"] = "ゆっくり動く的を5個クリックしよう。あせらなくて大丈夫です。",

		["stages.avoid_hazards.title"] = "Stage 5: 危険を避ける練習",
		["stages.avoid_hazards.short"] = "危険を避ける練習",
		["stages.avoid_hazards.instruction"] = "赤い床を避けて進もう。緑の床に乗ると、そこからやり直せます。",

		["stages.sprint_basic.title"] = "Stage 6: ダッシュ練習",
		["stages.sprint_basic.short"] = "ダッシュ練習",
		["stages.sprint_basic.instruction"] = "Shiftを押しながらWで走ろう。長い道を進んで黄色いゴールへ行きます。",

		["stages.crouch_basic.title"] = "Stage 7: しゃがみ練習",
		["stages.crouch_basic.short"] = "しゃがみ練習",
		["stages.crouch_basic.instruction"] = "Ctrlを1回押してしゃがみ、低いトンネルを通ろう。もう1回押すと立ちます。",

		["stages.sprint_stop_targets.title"] = "Stage 8: 走って止まって狙う練習",
		["stages.sprint_stop_targets.short"] = "走って止まって狙う",
		["stages.sprint_stop_targets.instruction"] = "Shiftで長い通路を走り、青い停止エリアで止まってから的を3個クリックしよう。",

		["stages.jump_targets.title"] = "Stage 9: ジャンプして狙う練習",
		["stages.jump_targets.short"] = "ジャンプして狙う",
		["stages.jump_targets.instruction"] = "Spaceで足場をジャンプして進もう。最後の青い台に乗ると、奥の的が出ます。",

		["stages.training_arena.title"] = "Stage 10: トレーニングアリーナ",
		["stages.training_arena.short"] = "アリーナ",
		["stages.training_arena.instruction"] = "障害物のある広い部屋で、自律走行ロボットを4体クリックして破壊しよう。",
	},
}

local function getLanguage()
	local locale = string.lower(LocalizationService.RobloxLocaleId or "en-us")
	if string.sub(locale, 1, 2) == "ja" then
		return "ja"
	end
	return "en"
end

local function getTranslator()
	if translatorLoadAttempted then
		return translator
	end

	translatorLoadAttempted = true

	local localPlayer = Players.LocalPlayer
	if not localPlayer then
		return nil
	end

	local ok, result = pcall(function()
		return LocalizationService:GetTranslatorForPlayerAsync(localPlayer)
	end)

	if ok then
		translator = result
	end

	return translator
end

local function getCloudText(key, args)
	local activeTranslator = getTranslator()
	if not activeTranslator then
		return nil
	end

	local ok, result = pcall(function()
		return activeTranslator:FormatByKey(key, args or {})
	end)

	if ok and result and result ~= "" and result ~= key then
		return result
	end

	return nil
end

function Localization.t(key, args)
	local cloudText = getCloudText(key, args)
	if cloudText then
		return cloudText
	end

	local language = getLanguage()
	local text = (STRINGS[language] and STRINGS[language][key]) or STRINGS.en[key] or key

	if args then
		for name, value in pairs(args) do
			text = string.gsub(text, "{" .. name .. "}", tostring(value))
		end
	end

	return text
end

function Localization.stageTitle(stageId)
	return Localization.t("stages." .. stageId .. ".title")
end

function Localization.stageShortTitle(stageId)
	return Localization.t("stages." .. stageId .. ".short")
end

function Localization.stageInstruction(stageId)
	return Localization.t("stages." .. stageId .. ".instruction")
end

return Localization
