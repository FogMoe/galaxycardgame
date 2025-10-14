--裂生荚囊
--休整阶段时，受到1点伤害。
--每当该单位受到伤害时，制造并部署1个1/1的幼小爬虫。

local s,id=Import()

function s.initial(c)
	-- 效果1：自己的休整阶段时，受到1点伤害
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DEFCHANGE)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_PHASE+GALAXY_PHASE_REST)
	e1:SetRange(GALAXY_LOCATION_UNIT_ZONE)
	e1:SetCountLimit(1)
	e1:SetCondition(s.damcon)
	e1:SetOperation(s.damop)
	c:RegisterEffect(e1)

	-- 效果2：受到伤害时，制造并部署1个幼小爬虫
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(GALAXY_EVENT_HP_DAMAGE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

-- 效果1的条件：自己的回合
function s.damcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp
end

-- 效果1的操作：受到1点伤害
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsFaceup() then
		Duel.AddHp(c,-1,REASON_EFFECT)
	end
end

-- 效果2的目标
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end

-- 效果2的操作：制造并部署幼小爬虫
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)<=0 then return end
	if not Duel.IsPlayerCanSpecialSummonMonster(tp,10000143,0,TYPES_TOKEN_MONSTER,1,1,1,0,0) then return end

	-- 创建幼小爬虫衍生物
	local token=Duel.CreateToken(tp,10000143)
	if token then
		Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP_ATTACK)
	end
end
