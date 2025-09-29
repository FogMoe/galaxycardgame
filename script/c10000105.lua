--机械模块β：仅可装备于机械单位。提供+2战斗力，并在补给阶段令装备怪承受 -1 生命值。
local s,id=Import()

function s.initial(c)
    -- 启动装备
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_EQUIP)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)

    -- 装备限制：机械单位
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_EQUIP_LIMIT)
    e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e2:SetValue(s.eqlimit)
    c:RegisterEffect(e2)

    -- 攻击力 +2
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_EQUIP)
    e3:SetCode(EFFECT_UPDATE_ATTACK)
    e3:SetValue(2)
    c:RegisterEffect(e3)
end

function s.filter(c)
    return c:IsFaceup() and c:IsRace(RACE_MACHINE) and c:IsType(GALAXY_TYPE_UNIT)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(GALAXY_LOCATION_UNIT_ZONE) and chkc:IsControler(tp) and s.filter(chkc) end
    if chk==0 then return Duel.IsExistingTarget(s.filter,tp,GALAXY_LOCATION_UNIT_ZONE,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
    Duel.SelectTarget(tp,s.filter,tp,GALAXY_LOCATION_UNIT_ZONE,0,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_EQUIP,e:GetHandler(),1,0,0)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=Duel.GetFirstTarget()
    if not tc or not tc:IsRelateToEffect(e) or not tc:IsFaceup() then return end
    if Duel.Equip(tp,c,tc,false) then
        s.apply(c,tc)
    else
        Duel.SendtoGrave(c,REASON_EFFECT)
    end
end

function s.eqlimit(e,c)
    return c:IsRace(RACE_MACHINE) and c:IsType(GALAXY_TYPE_UNIT)
end

function s.apply(c,tc)
    -- 客户端提示
    local hint=Effect.CreateEffect(c)
    hint:SetDescription(aux.Stringid(id,1))
    hint:SetType(EFFECT_TYPE_SINGLE)
    hint:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CLIENT_HINT)
    hint:SetRange(GALAXY_LOCATION_UNIT_ZONE)
    hint:SetReset(RESET_EVENT+RESETS_STANDARD)
    tc:RegisterEffect(hint,true)

    -- 补给阶段扣 1 HP
    local dmg=Effect.CreateEffect(c)
    dmg:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
    dmg:SetCode(EVENT_PHASE+PHASE_DRAW)
    dmg:SetRange(GALAXY_LOCATION_UNIT_ZONE)
    dmg:SetReset(RESET_EVENT+RESETS_STANDARD)
    dmg:SetCondition(s.hpcon)
    dmg:SetOperation(s.hpoper)
    tc:RegisterEffect(dmg,true)
end

function s.hpcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetTurnPlayer()==tp
end

function s.hpoper(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsFaceup() then return end
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_UPDATE_HP)
    e1:SetValue(-1)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD)
    c:RegisterEffect(e1)
end
