local Utils = {}

type AnimTweenInfo = TweenInfo
type AnimProperties = {[string]: any}

type TweenData = {
	tweenInfo: TweenInfo;
	tweenProperties: AnimProperties;
}

export type AnimData = {
	initProperties: AnimProperties;

	focusedTweenData: TweenData;
	defocusedTweenData: TweenData;
}

function Utils.TweenData(
	tweenInfo: AnimTweenInfo,
	tweenProperties: AnimProperties
): TweenData
	return {
		tweenInfo = tweenInfo;
		tweenProperties = tweenProperties;
	}
end

function Utils.AnimData(
	initProperties: AnimProperties,
	focusedTweenData: TweenData,
	defocusedTweenData: TweenData
): AnimData
	return {
		initProperties = initProperties;
		focusedTweenData = focusedTweenData;
		defocusedTweenData = defocusedTweenData;
	}
end

return Utils
