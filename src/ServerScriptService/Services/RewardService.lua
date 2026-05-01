local RewardService = {}

local progressService = nil

function RewardService.Init(nextProgressService)
	progressService = nextProgressService
end

function RewardService.GrantStageReward(player, stageDefinition)
	return progressService.AwardStage(player, stageDefinition)
end

return RewardService
