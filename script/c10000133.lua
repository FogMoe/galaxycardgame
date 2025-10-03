--单位复制器
--当己方单位特殊召唤成功时，复制一张相同的单位到场上
--复制体在战斗后会被破坏
local s,id = Import()

function s.initial(c)
    -- 监听己方单位特殊召唤成功
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetRange(GALAXY_LOCATION_UNIT_ZONE)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCountLimit(1)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
end

-- 筛选己方特殊召唤的单位（排除复制器自己）
function s.filter(c,tp,exc)
    return c:IsFaceup() and c:IsSummonPlayer(tp)
        and c:IsLocation(GALAXY_LOCATION_UNIT_ZONE)
        and c~=exc
end

-- 条件：有己方单位特殊召唤成功
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return eg:IsExists(s.filter,1,nil,tp,c)
end

-- 目标：自动选择第一个召唤成功的单位作为复制对象
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)>0
            and eg:IsExists(s.filter,1,nil,tp,e:GetHandler())
    end
    -- 自动选择第一个符合条件的单位
    local g=eg:Filter(s.filter,nil,tp,e:GetHandler())
    local tc=g:GetFirst()
    Duel.SetTargetCard(tc)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end

-- 操作：复制目标单位到场上
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)<=0 then return end

    local tc=Duel.GetFirstTarget()
    if not tc or not tc:IsRelateToEffect(e) or not tc:IsFaceup() then return end

    -- 获取目标卡的代码
    local code=tc:GetCode()

    -- 使用CreateToken创建衍生物（保留原卡效果）
    local token=Duel.CreateToken(tp,code)
    if token and Duel.SpecialSummonStep(token,0,tp,tp,false,false,POS_FACEUP_ATTACK) then
        -- 添加战斗后破坏效果
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
        e1:SetCode(EVENT_BATTLED)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        e1:SetOperation(function(e,tp,eg,ep,ev,re,r,rp)
            Duel.Destroy(e:GetHandler(),REASON_EFFECT)
        end)
        token:RegisterEffect(e1,true)

        -- 改变种族为机械
        local e2=Effect.CreateEffect(e:GetHandler())
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetCode(EFFECT_CHANGE_RACE)
        e2:SetValue(RACE_MACHINE)
        e2:SetReset(RESET_EVENT+RESETS_STANDARD)
        token:RegisterEffect(e2,true)

        -- 添加复制体标记提示
        local e3=Effect.CreateEffect(e:GetHandler())
        e3:SetType(EFFECT_TYPE_SINGLE)
        e3:SetProperty(EFFECT_FLAG_CLIENT_HINT)
        e3:SetDescription(aux.Stringid(id,1))
        e3:SetReset(RESET_EVENT+RESETS_STANDARD)
        token:RegisterEffect(e3,true)

        Duel.SpecialSummonComplete()

        -- 复制器受到等同于己方场上单位数量的伤害
        local c=e:GetHandler()
        if c:IsRelateToEffect(e) and c:IsFaceup() then
            local ct=Duel.GetMatchingGroupCount(Card.IsFaceup,tp,GALAXY_LOCATION_UNIT_ZONE,0,nil)
            if ct>0 then
                Duel.AddHp(c,-ct,REASON_EFFECT)
            end
        end
    end
end
