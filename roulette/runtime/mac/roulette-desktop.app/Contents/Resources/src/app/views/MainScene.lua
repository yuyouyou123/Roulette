
local MainScene = class("MainScene", cc.load("mvc").ViewBase)

local csbFilePath = 'res/RouletteMainLayer.csb'

local pScheduler = cc.Director:getInstance():getScheduler()
-- pScheduler:unscheduleScriptEntry(self.schedule_Jackpot_Player_List)
-- self.schedule_Jackpot_Player_List = pScheduler:scheduleScriptFunc(update, 3, false)

local gameOptions = {
	-- 设置旋转速度，即每一帧转动的角度
	rotationSpeed = 0.4, 
	-- 刀飞出去的时间
	throwSpeed = 0.2,
	--v1.1新增 两把刀之前的最小角度(约束角度)
	minAngle = 15,
}

local targetName = 'targetName'

local knifeId = 1

local userConf = cc.UserDefault:getInstance()

local fruitsNumber = 0

function MainScene:onCreate()
    self._csbNode = cc.CSLoader:createNode(csbFilePath)
    self._csbNode:addTo(self)
	self.scheduler = pScheduler:scheduleScriptFunc(handler(self,self.update), 1/60, false)

	self.layout = self._csbNode:getChildByName('Layout')
	self:initGamePanel()
	self:initGameOverPanel()

	self.stop = true
	self:initData()
	self:createTarget()
	self:initKnife()
	self:initMainPanel()
	self:initUnlockPanel()
    self:initConf()
    audio.playMusic("audio/BJY.mp3",true)
end
local maxKnifeCount = 6
function MainScene:initUnlockPanel()
	self.selectKnifeIndex = 1
	self.unlockPanel = self.layout:getChildByName('Panel_Unlock')
	self.unlockPanel:setVisible(false)
	self.myFruitsNumber = self.unlockPanel:getChildByName('HaveFruitsNumber')
	self.myFruitsNumber:setString('')
	self.unlockButtonKinfe = self.unlockPanel:getChildByName('Unlock_Info')
	self.unlockButtonKinfe:addClickEventListener(handler(self,self.unlockButtonListener))
	self.unlockInfoKnifeNumber = self.unlockButtonKinfe:getChildByName('Number')
	self.unlockInfoKnifeNumber:setString('')

	self.unlockInfoKnifeSprite = self.unlockPanel:getChildByName('dizuo'):getChildByName('Sprite_')

	self.unlockButtonSure = self.unlockPanel:getChildByName('Button_Sure')
	self.unlockButtonSure:addClickEventListener(handler(self,self.sureButtonKinfeListener))

	self.selectKnifeLeft = self.unlockPanel:getChildByName('dizuo'):getChildByName('Button_Left')
	self.selectKnifeLeft:addClickEventListener(function()
		self.selectKnifeIndex = self.selectKnifeIndex - 1
		if self.selectKnifeIndex == 0 then
			self.selectKnifeIndex = maxKnifeCount
		end
		self:updateUnlockData()
	end)
	self.selectKnifeRight = self.unlockPanel:getChildByName('dizuo'):getChildByName('Button_Right')
	self.selectKnifeRight:addClickEventListener(function()
		self.selectKnifeIndex = self.selectKnifeIndex + 1
		if self.selectKnifeIndex == maxKnifeCount + 1 then
			self.selectKnifeIndex = 1
		end
		self:updateUnlockData()
	end)
	
	self.unlockPanel:getChildByName('Button_backMain'):addClickEventListener(function()
		self.unlockPanel:setVisible(false)
		self.mainPanel:setVisible(true)
	end)
end

local unlockNumberConf = {
	0,100,900,2000,5000,9000
	-- 1,1,1,1,1,1,1,1
}
function MainScene:sureButtonKinfeListener()
	knifeId = self.selectKnifeIndex
	self:updateUnlockData()
end
function MainScene:updateUnlockData()
	self.myFruitsNumber:setString(fruitsNumber)
	self.unlockInfoKnifeNumber:setString(unlockNumberConf[self.selectKnifeIndex])
	local key = 'unlockKnife' .. self.selectKnifeIndex
	local isUnlock = userConf:getBoolForKey(key,false)

	local path = 'res/Image/Unlock/'

	if isUnlock then
		path = path .. self.selectKnifeIndex .. 'js.png'
		local isOkuSure = true
		if knifeId == self.selectKnifeIndex then
			isOkuSure = false
		end
		self.unlockButtonSure:setEnabled(isOkuSure)
		self.unlockButtonKinfe:setEnabled(false)
	else
		self.unlockButtonKinfe:setEnabled(fruitsNumber >= unlockNumberConf[self.selectKnifeIndex])
		path = path .. self.selectKnifeIndex .. '.png'
		self.unlockButtonSure:setEnabled(false)
	end
	self.unlockInfoKnifeSprite:setTexture(path)
end

function MainScene:unlockButtonListener()
	if fruitsNumber < unlockNumberConf[self.selectKnifeIndex] then
		return
	end
	fruitsNumber = fruitsNumber - unlockNumberConf[self.selectKnifeIndex]
	local key = 'unlockKnife' .. self.selectKnifeIndex
	userConf:setBoolForKey(key,true)
	userConf:setIntegerForKey('fruitsNumber',fruitsNumber)
	userConf:flush()
	self:updateUnlockData()
end
function MainScene:initConf()
	self.isOffAudio = not userConf:getBoolForKey('audio',false)
	print('self.isOffAudio',self.isOffAudio)
	self:audioListener()
	fruitsNumber = userConf:getIntegerForKey('fruitsNumber',0)
end

function MainScene:initGamePanel()
	self.gamePanel = self.layout:getChildByName('Panel_Game')
	self.gamePanel:setVisible(false)
	self.center_node = self.gamePanel:getChildByName('Node_Center')
	self.createKnife_node = self.gamePanel:getChildByName('Node_CreateKnife')
	self.gamePanel:addClickEventListener(handler(self,self.createKnifeToTarget))

	self.stageText = self.gamePanel:getChildByName('Stage_Text')
	self.stageText.number = 1
	self.stageText:setString(self.stageText.number)
	self.totalScore = self.gamePanel:getChildByName('TotalScore')
	self.totalScore.number = 0
	self.totalScore:setString(self.totalScore.number)
	self.fruitsScore = self.gamePanel:getChildByName('Score')
	self.fruitsScore.number = 0
	self.fruitsScore:setString(self.fruitsScore.number)
end

function MainScene:initMainPanel()
	self.mainPanel = self.layout:getChildByName('Panel_Mian')

	self.startbutton = self.mainPanel:getChildByName('Button_Start')
	self.startbutton:addClickEventListener(handler(self,self.gameStart))

	self.unlockKnifeButton = self.mainPanel:getChildByName('Button_Knife')
	self.unlockKnifeButton:addClickEventListener(handler(self,self.enterUnlockKnifeButtonListener))

	self.audioButton = self.mainPanel:getChildByName('Button_Audio')
	self.audioButton:addClickEventListener(handler(self,self.audioListener))
end

function MainScene:initGameOverPanel()
	self.overPanel = self.layout:getChildByName('Panel_GamgeOver')
	self.overPanel:setVisible(false)
	self.overNumber = self.overPanel:getChildByName('GameOverNumber')
	self.overNumber:setString('')
	self.overPanel:getChildByName('Button_Restart'):addClickEventListener(handler(self,self.gameRestart))
	self.overPanel:getChildByName('Button_backMain'):addClickEventListener(function()
		self.overPanel:setVisible(false)
		self.mainPanel:setVisible(true)
	end)
end

function MainScene:gameStart()
	self.mainPanel:setVisible(false)
	self.gamePanel:setVisible(true)
	self:initKnife()
	self:restartKnife()
	self:resetKnife()
	self:initData()
	self:createTarget()
	self.stop = false
	self.canThrow = true
end

function MainScene:enterUnlockKnifeButtonListener()
	self.unlockPanel:setVisible(true)
	self.mainPanel:setVisible(false)
	self:updateUnlockData()
end

function MainScene:audioListener()
	self.isOffAudio = not self.isOffAudio
	if self.isOffAudio then
		audio.setMusicVolume(0)
		audio.setSoundsVolume(0)
		self.audioButton:loadTextures("res/Image/MainHall/yinxiaoguan.png","","",UI_TEX_TYPE_LOCAL)
	else
		audio.setMusicVolume(1)
		audio.setSoundsVolume(1)
		self.audioButton:loadTextures("res/Image/MainHall/yinxiaokai.png","","",UI_TEX_TYPE_LOCAL)
	end

	userConf:setBoolForKey('audio',self.isOffAudio)
	userConf:flush()
end

function MainScene:createKnifeToTarget()
	-- pScheduler:unscheduleScriptEntry(self.scheduler)
	if self.canThrow then
		self.canThrow = false
		local callback = function()
			local legalHit = true
			print('count ----:',#self.knifeGroup)
			local nowAngle = math.abs(self.center_node.angle)
			for index,knife in ipairs(self.knifeGroup) do
				local anagle = math.abs(knife.impactAngle - nowAngle)
				if
				(anagle < self.minAngle)
					or 
				(anagle >= 360 and (anagle - 360) < self.minAngle)
					or 
				(math.abs(anagle - 360) < self.minAngle) 
				then
					legalHit = false
					break
				end
			end
			if legalHit then
				local actions = {}
				actions[#actions + 1] = cc.MoveBy:create(0.08,cc.p(0,10))
				actions[#actions + 1] = cc.MoveBy:create(0.08,cc.p(0,-10))
				actions[#actions + 1] = cc.CallFunc:create(function()
					self.canThrow = true
					self:isOkKnife()
					audio.playSound('audio/jizhong.mp3')
				end)

				self.center_node:runAction(cc.Sequence:create(actions))

				local radians = math.rad(self.center_node.angle - 90)

				local x = self._target.width  * 0.5 * math.cos(radians)
				local y = self._target.width  * 0.5 * math.sin(radians)
				local knife = cc.Sprite:create(self._knife.path)
					:addTo(self.center_node)
					:setRotation(-self.center_node.angle)
					:setPosition(cc.p(x,y))
				knife.impactAngle = nowAngle
				knife.index = #self.knifeGroup + 1
				table.insert(self.knifeGroup,knife)
				self:haveFruits()
				self:resetKnife()

				-- local text = ccui.Text:create(knife.index,"",30)
				-- 	:addTo(knife)
			else
				local time = math.random(10,100) * 0.01
				local rotationCount = math.random(10,200) * 0.01
				local angle = math.random(100,200) * rotationCount
				local x = math.random(-10,10)
				local y = math.random(-150,-200)
				local actions = {}
				actions[#actions + 1] = cc.Spawn:create(
						cc.RotateBy:create(time, angle),
						cc.MoveTo:create(time,cc.p(x,y))
					)
				actions[#actions + 1] = cc.DelayTime:create(time)
				actions[#actions + 1] = cc.CallFunc:create(function()
					self:gameOver()
				end)
				self._knife:runAction(cc.Sequence:create(actions))
			end
		end
		if self._knife then
			local actions = {}
			actions[#actions + 1] = cc.MoveTo:create(self.throwSpeed,self.createKnife_node.moveToPos)
			actions[#actions + 1] = cc.CallFunc:create(callback)
			self._knife:runAction(cc.Sequence:create(actions))
		end
	end
end

function MainScene:isOkKnife()
	self.totalScore.number = self.totalScore.number + 1
	self.totalScore:setString(self.totalScore.number)
	local knife = self.node_AllKnife.group[1]
	table.remove(self.node_AllKnife.group,1)

	knife:setTexture('res/Image/daozihei.png')

	if #self.node_AllKnife.group < 1 then
		self.stop = true
		self.canThrow = false
		fruitsNumber = fruitsNumber + self.fruitsScore.number
		userConf:setIntegerForKey('fruitsNumber',fruitsNumber)
		userConf:flush()

		self.fruitsScore.number = 0
		self.fruitsScore:setString(self.fruitsScore.number)
		
		print('过关')
		self:enterNextGame()
	else
	end
end

function MainScene:enterNextGame()
	self:initData()
	self.center_node:removeAllChildren()
	local spine = sp.SkeletonAnimation:create('res/spine/roll_level1/roll_level1.json','res/spine/roll_level1/roll_level1.atlas',1)
		:addTo(self.center_node)
		-- :setAnchorPoint(cc.p(0.5,0))
		:setPosition(cc.p(0,0))
        :setAnimation(1,"level" .. (self._target.id or 1),false)
	audio.playSound('audio/zhakai.mp3')
    spine:registerSpineEventHandler(function (event)
		local actions = {}
		actions[#actions + 1] = cc.DelayTime:create(0.02)
		actions[#actions + 1] = cc.RemoveSelf:create()
		actions[#actions + 1] = cc.CallFunc:create(function()
			self:createTarget()
			self:resetKnife()
			self:restartKnife()
			self.stop = false
			self.canThrow = true
		end)
    	spine:runAction(cc.Sequence:create(actions))
    end, sp.EventType.ANIMATION_COMPLETE)
end


--是否擦中了水果
function MainScene:haveFruits()
	local knifeWordPos = self._knife:convertToWorldSpace(cc.p(self._knife.size.width / 2,self._knife.size.height / 2))
	local minYFruits
	local index = 0
	for index_,fruits in ipairs(self.fruitsGroup) do
		if fruits then
			local fruitsWordPos = fruits:convertToWorldSpace(cc.p(fruits.size.width / 2,fruits.size.width / 2))
			fruits.wordPos = fruitsWordPos
			if minYFruits then
				if minYFruits.wordPos.y > fruits.wordPos.y then
					minYFruits = fruits
					index = index_
				end
			else
				minYFruits = fruits
				index = index_
			end
		end
	end

	if minYFruits and minYFruits.wordPos.y < 300 then
		local offset = 0
		local fruitsWordPos = minYFruits.wordPos
		if knifeWordPos.x > fruitsWordPos.x then
			offset = knifeWordPos.x - fruitsWordPos.x
		elseif fruitsWordPos.x > knifeWordPos.x then
			offset = fruitsWordPos.x - knifeWordPos.x
		end

		if offset <= minYFruits.size.width / 2 then
			audio.playSound('audio/shuiguo.mp3')
			local gamePanlePos = self.gamePanel:convertToNodeSpace(fruitsWordPos)
			local spine = sp.SkeletonAnimation:create('res/spine/roll_fruit/roll_fruit.json','res/spine/roll_fruit/roll_fruit.atlas',1)
				:addTo(self.gamePanel)
				:setAnchorPoint(cc.p(0.5,0))
				:setPosition(gamePanlePos)
		        :setAnimation(1,"animation",false)

		    spine:registerSpineEventHandler(function (event)
		    	spine:runAction(cc.RemoveSelf:create())
		    end, sp.EventType.ANIMATION_COMPLETE)
		    minYFruits:setVisible(false)
		    table.remove(self.fruitsGroup,index)

		    self.fruitsScore.number = self.fruitsScore.number + 1
			self.fruitsScore:setString(self.fruitsScore.number)
		end
	end
end

function MainScene:gameOver()
	self.stop = true
	print('游戏结束')
	self.overPanel:setVisible(true)
	self.gamePanel:setVisible(false)
	

	self.fruitsScore.number = 0
	self.fruitsScore:setString(self.fruitsScore.number)

	self.totalScore.number = 0
	self.totalScore:setString(self.totalScore.number)
end

function MainScene:gameRestart()
	self:initData()
	self:createTarget()
	self:resetKnife()
	self.overPanel:setVisible(false)
	self.gamePanel:setVisible(true)
	self.canThrow = true;
	self:gameStart()
end


function MainScene:initData()
	--在游戏一开始设置转动的速度与一致，即默认值
	local speedDic = (math.random(1,2) == 1) and 1 or -1

	self.currentRotationSpeed = math.random(50,600) * 0.01 * speedDic --gameOptions.rotationSpeed
    self.newRotationSpeed = gameOptions.rotationSpeed;
    self.minAngle = gameOptions.minAngle

    self.throwSpeed = gameOptions.throwSpeed
	-- 在游戏开始时设置可以扔刀
	self.knifeGroup = {}

	-- self.createKnife_node:removeAllChildren()
	self.center_node:setRotation(0)
end

function MainScene:createTarget()
	local id = math.random(5)
	self.center_node:removeAllChildren()
	local path = string.format('res/Image/yuanpan%s.png',id or 1)
	self._target = cc.Sprite:create(path)
		:addTo(self.center_node,3)
		:setName(targetName)
	self._target.width = self._target:getContentSize().width
	self._target.id = id or 1

	local wordPos = self.center_node:convertToWorldSpace(cc.p(0,-self._target.width / 2))
	self.createKnife_node.moveToPos = self.createKnife_node:convertToNodeSpace(wordPos)
	self:createFruits()
end

local function rand_tab(tab)
	math.randomseed(os.time())
	for len = #tab, 1, -1 do
		local n = math.random(len)
		tab[len], tab[n] = tab[n], tab[len]
	end
	return tab
end
local FruitsListIndex = {
	0,1,2,3,4,5,6,7,8,9,10
}
function MainScene:createFruits()
	self.fruitsGroup = {}
	local have = math.random(1,2) == 1 or false
	if have then
		local number = math.random(11)
		local indexss = rand_tab(clone(FruitsListIndex))
		for index__ = 1,number do
			local index = indexss[index__]
			local angle = 30 * index
			local radians = math.rad(angle + 90)
			local x = self._target.width / 2 + self._target.width  * 0.5 * math.sin(radians)
			local y = self._target.width / 2 + self._target.width  * 0.5 * math.cos(radians)
			local fruits = cc.Sprite:create("res/Image/fruist.png")
				:addTo(self._target)
				:setAnchorPoint(cc.p(0.5,0))
			local width = fruits:getContentSize().width
				fruits:setPosition(cc.p(x,y))
				fruits:setRotation(angle + 90)
				fruits.angle = angle + 90
				fruits.x = x
				fruits.y = y
				fruits.size = fruits:getContentSize()
			
			table.insert(self.fruitsGroup,fruits)
		end
	end
end

function MainScene:initKnife()
	self.createKnife_node:removeAllChildren()
	local path = string.format('res/Image/minKnife/daozi%sx.png',knifeId)
	self._knife = cc.Sprite:create(path)
		:addTo(self.createKnife_node)
	self._knife:setPosition(0,0)
	self._knife.path = path
	self._knife.size = self._knife:getContentSize()

	self.minAngle = self._knife.size.width
end

function MainScene:restartKnife()
	if not self.node_AllKnife then
		self.node_AllKnife = self.gamePanel:getChildByName('Node_AllKnife')
	end
	self.node_AllKnife:removeAllChildren()
	self.node_AllKnife.group = {}
	local number = math.random(3,13)
	for index = 1, number do
		local x,y = 0,-(index - 1) * 40
		local path = "res/Image/daoziliang.png"
		local kinfe = cc.Sprite:create(path)
			:addTo(self.node_AllKnife)
			:setPosition(cc.p(x,y))
		table.insert(self.node_AllKnife.group,kinfe)
	end
end

function MainScene:resetKnife()
	self._knife:setPosition(0,0)
	self._knife:setRotation(0)
	local knifeWordPos = self._knife:convertToWorldSpace(cc.p(0,0))
end

local time = 0

function MainScene:update(dt)
	if self.stop then return end
	if not self._target then return end
	local angle = (self.center_node.angle or 0) + self.currentRotationSpeed
	if angle >= 360 then
		self.center_node.angle = angle - 360
	elseif angle <= 360 then
		self.center_node.angle = angle + 360
	else
		self.center_node.angle = angle
	end
	self.center_node:setRotation(self.center_node.angle)

	-- time = time + dt
	-- if time >= 1 then
	-- 	time = time - 3
		-- local fruits = self.fruitsGroup[1]
		-- if fruits then
		-- 	local wordPos = fruits:convertToWorldSpace(cc.p(0,0))
		-- 	print('wordPos::::::',wordPos.x,wordPos.y)
		-- end
	-- end
end

return MainScene
