--机械模块α：仅可装备于机械单位。提供+1生命值，并在战斗中对敌方影响力造成额外伤害。
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

    -- 生命值 +1
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_EQUIP)
    e3:SetCode(EFFECT_UPDATE_HP)
    e3:SetValue(1)
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

    -- 战斗确认时额外造成影响力伤害
    local dmg=Effect.CreateEffect(c)
    dmg:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    dmg:SetCode(EVENT_BATTLE_CONFIRM)
    dmg:SetReset(RESET_EVENT+RESETS_STANDARD)
    dmg:SetOperation(s.dmgop)
    tc:RegisterEffect(dmg,true)
end

function s.dmgop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local bc=c:GetBattleTarget()
    if not bc or not bc:IsType(GALAXY_TYPE_UNIT) or not bc:IsRelateToBattle() then return end
    local diff=c:GetAttack()-bc:GetHp()
    if diff>0 then
        Duel.Damage(1-tp,diff,REASON_EFFECT)
    end
end
