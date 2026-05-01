-- 型を書く場所です。MVPでは空に近いですが、あとで大きくするときの置き場にします。

export type PlayerProgress = {
	XP: number,
	Coins: number,
	Level: number,
	RankTitle: string,
	CompletedStages: { [string]: boolean },
}

return {}
