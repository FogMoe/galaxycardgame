--消耗2点补给，获得所有敌方真菌类单位的控制权。如果没有敌方真菌类单位，则改为先给敌方部署1个临时的1/1的孢子体10000089然后再获取它控制。
local s, id = Import()
function s.initial(c)
	--激活效果
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_CONTROL+CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--消耗2点补给
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp,2) end
	Duel.PaySupplyCost(tp,2)
end

--真菌类单位过滤器
function s.fungalfilter(c)
	return c:IsFaceup() and c:IsRace(RACE_REPTILE) and c:IsControlerCanBeChanged()
end

--目标函数
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local fungal_group=Duel.GetMatchingGroup(s.fungalfilter,tp,0,LOCATION_MZONE,nil)
	if chk==0 then
		if fungal_group:GetCount()>0 then
			return true
		else
			return Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
				and Duel.IsPlayerCanSpecialSummonMonster(tp,10000089,0,TYPES_TOKEN_MONSTER,1,1,1,RACE_REPTILE,0)
		end
	end

	if fungal_group:GetCount()>0 then
		Duel.SetOperationInfo(0,CATEGORY_CONTROL,fungal_group,fungal_group:GetCount(),0,0)
	else
		Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,0,0)
		Duel.SetOperationInfo(0,CATEGORY_CONTROL,nil,1,0,0)
	end
end

--激活操作
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local fungal_group=Duel.GetMatchingGroup(s.fungalfilter,tp,0,LOCATION_MZONE,nil)

	if fungal_group:GetCount()>0 then
		--有敌方真菌类单位，直接获得控制权
		for tc in aux.Next(fungal_group) do
			Duel.GetControl(tc,tp)
		end
	else
		--没有敌方真菌类单位，先给对手部署孢子体，再获得控制权
		if Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
			and Duel.IsPlayerCanSpecialSummonMonster(tp,10000089,0,TYPES_TOKEN_MONSTER,1,1,1,RACE_REPTILE,0) then

			--给对手部署孢子体
			local token=Duel.CreateToken(1-tp,10000089)
			if Duel.SpecialSummonStep(token,0,tp,1-tp,false,false,POS_FACEUP_ATTACK) then
				Duel.SpecialSummonComplete()
				--立即获得控制权
				Duel.GetControl(token,tp)
			end
		end
	end
end