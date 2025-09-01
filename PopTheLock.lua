local module = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local correctImage = "rbxassetid://109655640259274"
local wrongImage   = "rbxassetid://126624962315618"

local positionLabels = {
	{ image = "rbxassetid://97481697428134",  min = 172, max = 218 },
	{ image = "rbxassetid://133541713242230", min = 206, max = 252 },
	{ image = "rbxassetid://140598471405174", min = 241, max = 286 },
	{ image = "rbxassetid://94131365953021",  min = 276, max = 322 },
	{ image = "rbxassetid://101242669456357", min = 311, max = 358 },
	{ image = "rbxassetid://121166711363586", min = 346, max = 393 },
	{ image = "rbxassetid://71182141179985",  min = 381, max = 428 },
	{ image = "rbxassetid://110432291766732", min = 416, max = 463 },
	{ image = "rbxassetid://135329757288924", min = 451, max = 498 },
	{ image = "rbxassetid://108083893418537", min = 486, max = 532 },
	{ image = "rbxassetid://118113075571052", min = 521, max = 568 },
}

local function getInputType()
	return UserInputService.TouchEnabled and "Click" or "Space"
end

function module.startGame(tapsRequired)
	local need = math.max(1, tonumber(tapsRequired) or 1)

	local player = game.Players.LocalPlayer
	local gui = script:FindFirstChild("PopTheLock"):Clone()
	gui.Parent = player:WaitForChild("PlayerGui")

	local bg = gui.Background
	local arrow = bg.Arrow
	local effectImage = bg.RingEffect
	local detailsLabel = bg.DetailsLabel
	local count = bg.Count

	local tapSound = gui:FindFirstChild("TapSound")
	local failSound = gui:FindFirstChild("Fail")
	local winSfx = gui:FindFirstChild("Win")
	local loseSfx = gui:FindFirstChild("Lose")

	effectImage.Visible = false
	detailsLabel.Text = getInputType()
	count.Text = "0/"..tostring(need)
	count.TextColor3 = Color3.fromRGB(255,255,255)

	local playing = true
	local rotating = false
	local rotationSpeed = 90
	local rotationDirection = 1
	local currentTarget = positionLabels[math.random(1, #positionLabels)]
	local clicks = 0

	local ended = false
	local resultEvent = Instance.new("BindableEvent")

	local function cloneEffect(imageId)
		local clone = effectImage:Clone()
		clone.Image = imageId
		clone.Visible = true
		clone.Size = UDim2.fromScale(1, 1)
		clone.Position = effectImage.Position
		clone.Parent = bg
		task.spawn(function()
			local t = 0
			while t < 0.3 do
				t += task.wait()
				local s = 1 + t * 2
				clone.Size = UDim2.fromScale(s, s)
				clone.ImageTransparency = t * 3.3
			end
			clone:Destroy()
		end)
	end

	local function updateBackgroundImage()
		bg.Image = currentTarget.image
	end

	local rsConn, clickConn, keyConn

	local function closeWithOutcome(outcome, pause)
		if ended then return end
		ended = true
		rotating = false
		if outcome == "Win" and winSfx then winSfx:Play() end
		if outcome == "Lose" and loseSfx then loseSfx:Play() end
		resultEvent:Fire(outcome)
		task.spawn(function()
			if pause then task.wait(2) end
			local shrink = TweenService:Create(bg, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0,0,0,0)})
			shrink:Play()
			shrink.Completed:Wait()
			if gui then gui:Destroy() end
			if rsConn then rsConn:Disconnect() end
			if clickConn then clickConn:Disconnect() end
			if keyConn then keyConn:Disconnect() end
			resultEvent:Destroy()
		end)
	end

	local function setCount()
		count.Text = tostring(clicks).."/"..tostring(need)
	end

	local function attempt()
		if not playing or ended then return end
		local rot = arrow.Rotation % 360
		local min = currentTarget.min % 360
		local max = currentTarget.max % 360
		local correct = (min < max and rot >= min and rot <= max) or (min > max and (rot >= min or rot <= max))
		if correct then
			cloneEffect(correctImage)
			rotationDirection *= -1
			rotationSpeed *= 1.15
			clicks += 1
			setCount()
			if tapSound then
				tapSound.PlaybackSpeed *= 1.10
				tapSound.Volume *= 1.05
				tapSound:Play()
			end
			if clicks >= need then
				count.TextColor3 = Color3.fromRGB(60,200,90)
				closeWithOutcome("Win", 0.5)
				return
			end
			currentTarget = positionLabels[math.random(1, #positionLabels)]
			updateBackgroundImage()
			detailsLabel.Text = getInputType()
		else
			cloneEffect(wrongImage)
			if failSound then failSound:Play() end
			closeWithOutcome("Lose", 0)
		end
	end

	bg.Visible = true
	arrow.Rotation = 0
	updateBackgroundImage()
	task.wait(1)
	detailsLabel.Text = getInputType()
	rotating = true

	clickConn = bg.MouseButton1Click:Connect(attempt)
	keyConn = UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe or ended then return end
		if input.KeyCode == Enum.KeyCode.Space then
			attempt()
		end
	end)

	rsConn = RunService.RenderStepped:Connect(function(dt)
		if ended then return end
		if rotating and playing then
			arrow.Rotation = (arrow.Rotation + rotationSpeed * dt * rotationDirection) % 360
		end
	end)

	local outcome = resultEvent.Event:Wait()
	return outcome
end

return module
