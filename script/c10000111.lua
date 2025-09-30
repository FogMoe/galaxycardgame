--永动机：补给2的机械单位。部署时抽2张牌，每抽到1张机械单位则自身损失1HP；之后每当我方部署机械单位，自身恢复1HP。
local s,id=Import()

function s.initial(c)
    -- 部署成功：抽牌并根据抽到的机械单位承受伤害
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DRAW)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_DELAY)
    e1:SetTarget(s.drtg)
    e1:SetOperation(s.drop)
    c:RegisterEffect(e1)

    -- 我方部署机械单位时恢复1HP
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_DEFCHANGE)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetRange(GALAXY_LOCATION_UNIT_ZONE)
    e2:SetCondition(s.reccon)
    e2:SetOperation(s.recop)
    c:RegisterEffect(e2)
end

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsPlayerCanDraw(tp,2) end
    Duel.SetTargetPlayer(tp)
    Duel.SetTargetParam(2)
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
    local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
    if d<=0 then return end
    local c=e:GetHandler()
    if Duel.Draw(p,d,REASON_EFFECT)==0 then return end
    if not (c:IsRelateToEffect(e) and c:IsFaceup()) then return end
    local drawn=Duel.GetOperatedGroup()
    local ct=drawn:FilterCount(Card.IsRace,nil,RACE_MACHINE)
    if ct>0 then
        Duel.AddHp(c,-ct,REASON_EFFECT)
    end
end

function s.recfilter(c,tp)
    return c:IsFaceup() and c:IsRace(RACE_MACHINE) and c:IsType(GALAXY_TYPE_UNIT) and c:IsControler(tp)
end

function s.reccon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.recfilter,1,nil,tp)
end

function s.recop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not (c:IsFaceup() and c:IsRelateToEffect(e)) then return end
    local ct=eg:FilterCount(s.recfilter,nil,tp)
    if ct>0 then
        Duel.AddHp(c,ct,REASON_EFFECT)
    end
end
