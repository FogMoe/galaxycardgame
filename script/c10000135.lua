--冥骸方舟
--部署时，失去5点影响力，获得+5生命值
--死亡时以1点生命值复活，然后移除此效果
--死亡时，获得5点影响力
local s, id = Import()
function s.initial(c)
	-- 1. 部署时效果：失去5点影响力，获得+5生命值
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetOperation(s.sumop)
	c:RegisterEffect(e1)

	-- 2. 死亡时复活效果（只能使用一次）
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	-- 3. 死亡时获得5点影响力
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_RECOVER)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetCondition(s.reccon)
	e3:SetOperation(s.recop)
	c:RegisterEffect(e3)
end

-- 部署时操作：失去5点影响力，获得+5生命值
function s.sumop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 失去5点影响力
	Duel.Damage(tp, 5, REASON_EFFECT)

	-- 获得+5最大HP（持续效果）
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_HP)
	e1:SetValue(5)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e1)
end

-- 复活条件：从场上送去墓地，且未使用过复活
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(GALAXY_LOCATION_UNIT_ZONE)
		and c:IsPreviousControler(tp)
		and c:GetFlagEffect(id)==0
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP_ATTACK)>0 then
		-- 以1点HP复活
		Duel.SetHp(c, 1)

		-- 注册已复活标记，防止再次复活
		c:RegisterFlagEffect(id,0,EFFECT_FLAG_CANNOT_DISABLE,1)

		-- 添加客户端提示
		local e2=Effect.CreateEffect(c)
		e2:SetDescription(aux.Stringid(id,3))
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetProperty(EFFECT_FLAG_CLIENT_HINT)
		c:RegisterEffect(e2)
	end
end

-- 死亡时恢复影响力条件：从场上送去墓地
function s.reccon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(GALAXY_LOCATION_UNIT_ZONE)
		and c:IsPreviousControler(tp)
end

function s.recop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Recover(tp, 5, REASON_EFFECT)
end
