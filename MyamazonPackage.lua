
local c = game:GetService("Players").LocalPlayer.character
if not (c and c.Parent) then
    return
end
for i, v in pairs(c:GetChildren()) do
    if v:IsA("Accessory") and (v.Name == "MeshPartAccessory") then
        local handle = v:FindFirstChild("Handle")
        if handle and (handle.Size == Vector3.new(4.5, 4.5, 4.5)) then
            local mesh = handle:FindFirstChildWhichIsA("SpecialMesh")
            if mesh then
                mesh:Destroy()
                c = nil
                break
            end
        end
    end
end
if c then
    return --mesh was not removed
end

--reanimate by MyWorld#4430 discord.gg/pYVHtSJmEY
local Vector3_101 = Vector3.new(1, 0, 1)
local netless_Y = Vector3.new(0, 25.1, 0)
local function getNetlessVelocity(realPartVelocity) --edit this if you have a better netless method
    local netlessVelocity = realPartVelocity * Vector3_101
    local mag = netlessVelocity.Magnitude
    if mag > 10 then
        netlessVelocity *= 100 / mag
    end
    netlessVelocity += netless_Y
    return netlessVelocity
end
local simradius = "shp" --simulation radius (net bypass) method
--"shp" - sethiddenproperty
--"ssr" - setsimulationradius
--false - disable
local antiragdoll = true --removes hingeConstraints and ballSocketConstraints from your character
local newanimate = false --disables the animate script and enables after reanimation
local discharscripts = true --disables all localScripts parented to your character before reanimation
local R15toR6 = false --tries to convert your character to r6 if its r15
local hatcollide = false --makes hats cancollide (only method 0)
local humState16 = true --enables collisions for limbs before the humanoid dies (using hum:ChangeState)
local addtools = false --puts all tools from backpack to character and lets you hold them after reanimation
local hedafterneck = false --disable aligns for head and enable after neck is removed
local loadtime = game:GetService("Players").RespawnTime + 0.5 --anti respawn delay
local method = 2 --reanimation method
--methods:
--0 - breakJoints (takes [loadtime] seconds to laod)
--1 - limbs
--2 - limbs + anti respawn
--3 - limbs + breakJoints after [loadtime] seconds
--4 - remove humanoid + breakJoints
--5 - remove humanoid + limbs
local alignmode = 3 --AlignPosition mode
--modes:
--1 - AlignPosition rigidity enabled true
--2 - 2 AlignPositions rigidity enabled both true and false
--3 - AlignPosition rigidity enabled false

local lp = game:GetService("Players").LocalPlayer
local rs = game:GetService("RunService")
local stepped = rs.Stepped
local heartbeat = rs.Heartbeat
local renderstepped = rs.RenderStepped
local sg = game:GetService("StarterGui")
local ws = game:GetService("Workspace")
local cf = CFrame.new
local v3 = Vector3.new
local v3_0 = v3(0, 0, 0)
local inf = math.huge

local c = lp.Character

if not (c and c.Parent) then
 return
end

c.Destroying:Connect(function()
 c = nil
end)

local function gp(parent, name, className)
 if typeof(parent) == "Instance" then
  for i, v in pairs(parent:GetChildren()) do
   if (v.Name == name) and v:IsA(className) then
    return v
   end
  end
 end
 return nil
end

local function align(Part0, Part1)
 Part0.CustomPhysicalProperties = PhysicalProperties.new(0.0001, 0.0001, 0.0001, 0.0001, 0.0001)

 local att0 = Instance.new("Attachment", Part0)
 att0.Orientation = v3_0
 att0.Position = v3_0
 att0.Name = "att0_" .. Part0.Name
 local att1 = Instance.new("Attachment", Part1)
 att1.Orientation = v3_0
 att1.Position = v3_0
 att1.Name = "att1_" .. Part1.Name

 if (alignmode == 1) or (alignmode == 2) then
  local ape = Instance.new("AlignPosition", att0)
  ape.ApplyAtCenterOfMass = false
  ape.MaxForce = inf
  ape.MaxVelocity = inf
  ape.ReactionForceEnabled = false
  ape.Responsiveness = 200
  ape.Attachment1 = att1
  ape.Attachment0 = att0
  ape.Name = "AlignPositionRtrue"
  ape.RigidityEnabled = true
 end

 if (alignmode == 2) or (alignmode == 3) then
  local apd = Instance.new("AlignPosition", att0)
  apd.ApplyAtCenterOfMass = false
  apd.MaxForce = inf
  apd.MaxVelocity = inf
  apd.ReactionForceEnabled = false
  apd.Responsiveness = 200
  apd.Attachment1 = att1
  apd.Attachment0 = att0
  apd.Name = "AlignPositionRfalse"
  apd.RigidityEnabled = false
 end

 local ao = Instance.new("AlignOrientation", att0)
 ao.MaxAngularVelocity = inf
 ao.MaxTorque = inf
 ao.PrimaryAxisOnly = false
 ao.ReactionTorqueEnabled = false
 ao.Responsiveness = 200
 ao.Attachment1 = att1
 ao.Attachment0 = att0
 ao.RigidityEnabled = false

 if type(getNetlessVelocity) == "function" then
     local realVelocity = v3_0
        local steppedcon = stepped:Connect(function()
            Part0.Velocity = realVelocity
        end)
        local heartbeatcon = heartbeat:Connect(function()
            realVelocity = Part0.Velocity
            Part0.Velocity = getNetlessVelocity(realVelocity)
        end)
        Part0.Destroying:Connect(function()
            Part0 = nil
            steppedcon:Disconnect()
            heartbeatcon:Disconnect()
        end)
    end
end

local function respawnrequest()
 local ccfr = ws.CurrentCamera.CFrame
 local c = lp.Character
 lp.Character = nil
 lp.Character = c
 local con = nil
 con = ws.CurrentCamera.Changed:Connect(function(prop)
     if (prop ~= "Parent") and (prop ~= "CFrame") then
         return
     end
     ws.CurrentCamera.CFrame = ccfr
     con:Disconnect()
    end)
end

local destroyhum = (method == 4) or (method == 5)
local breakjoints = (method == 0) or (method == 4)
local antirespawn = (method == 0) or (method == 2) or (method == 3)

hatcollide = hatcollide and (method == 0)

addtools = addtools and gp(lp, "Backpack", "Backpack")

local fenv = getfenv()
local shp = fenv.sethiddenproperty or fenv.set_hidden_property or fenv.set_hidden_prop or fenv.sethiddenprop
local ssr = fenv.setsimulationradius or fenv.set_simulation_radius or fenv.set_sim_radius or fenv.setsimradius or fenv.set_simulation_rad or fenv.setsimulationrad

if shp and (simradius == "shp") then
 spawn(function()
  while c and heartbeat:Wait() do
   shp(lp, "SimulationRadius", inf)
  end
 end)
elseif ssr and (simradius == "ssr") then
 spawn(function()
  while c and heartbeat:Wait() do
   ssr(inf)
  end
 end)
end

antiragdoll = antiragdoll and function(v)
 if v:IsA("HingeConstraint") or v:IsA("BallSocketConstraint") then
  v.Parent = nil
 end
end

if antiragdoll then
 for i, v in pairs(c:GetDescendants()) do
  antiragdoll(v)
 end
 c.DescendantAdded:Connect(antiragdoll)
end

if antirespawn then
 respawnrequest()
end

if method == 0 then
 wait(loadtime)
 if not c then
  return
 end
end

if discharscripts then
 for i, v in pairs(c:GetChildren()) do
  if v:IsA("LocalScript") then
   v.Disabled = true
  end
 end
elseif newanimate then
 local animate = gp(c, "Animate", "LocalScript")
 if animate and (not animate.Disabled) then
  animate.Disabled = true
 else
  newanimate = false
 end
end

if addtools then
 for i, v in pairs(addtools:GetChildren()) do
  if v:IsA("Tool") then
   v.Parent = c
  end
 end
end

pcall(function()
 settings().Physics.AllowSleep = false
 settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled
end)

local OLDscripts = {}

for i, v in pairs(c:GetDescendants()) do
 if v.ClassName == "Script" then
  table.insert(OLDscripts, v)
 end
end

local scriptNames = {}

for i, v in pairs(c:GetDescendants()) do
 if v:IsA("BasePart") then
  local newName = tostring(i)
  local exists = true
  while exists do
   exists = false
   for i, v in pairs(OLDscripts) do
    if v.Name == newName then
     exists = true
    end
   end
   if exists then
    newName = newName .. "_"    
   end
  end
  table.insert(scriptNames, newName)
  Instance.new("Script", v).Name = newName
 end
end

c.Archivable = true
local hum = c:FindFirstChildOfClass("Humanoid")
if hum then
 for i, v in pairs(hum:GetPlayingAnimationTracks()) do
  v:Stop()
 end
end
local cl = c:Clone()
if hum and humState16 then
    hum:ChangeState(Enum.HumanoidStateType.Physics)
    if destroyhum then
        wait(1.6)
    end
end
if hum and hum.Parent and destroyhum then
    hum:Destroy()
end

if not c then
    return
end

local head = gp(c, "Head", "BasePart")
local torso = gp(c, "Torso", "BasePart") or gp(c, "UpperTorso", "BasePart")
local root = gp(c, "HumanoidRootPart", "BasePart")
if hatcollide and c:FindFirstChildOfClass("Accessory") then
    local anything = c:FindFirstChildOfClass("BodyColors") or gp(c, "Health", "Script")
    if not (torso and root and anything) then
        return
    end
    torso:Destroy()
    root:Destroy()
    if shp then
        for i,v in pairs(c:GetChildren()) do
            if v:IsA("Accessory") then
                shp(v, "BackendAccoutrementState", 0)
            end 
        end
    end
    anything:Destroy()
end

for i, v in pairs(cl:GetDescendants()) do
 if v:IsA("BasePart") then
  v.Transparency = 1
  v.Anchored = false
 end
end

local model = Instance.new("Model", c)
model.Name = model.ClassName

model.Destroying:Connect(function()
 model = nil
end)

for i, v in pairs(c:GetChildren()) do
 if v ~= model then
  if addtools and v:IsA("Tool") then
   for i1, v1 in pairs(v:GetDescendants()) do
    if v1 and v1.Parent and v1:IsA("BasePart") then
     local bv = Instance.new("BodyVelocity", v1)
     bv.Velocity = v3_0
     bv.MaxForce = v3(1000, 1000, 1000)
     bv.P = 1250
     bv.Name = "bv_" .. v.Name
    end
   end
  end
  v.Parent = model
 end
end

if breakjoints then
 model:BreakJoints()
else
 if head and torso then
  for i, v in pairs(model:GetDescendants()) do
   if v:IsA("Weld") or v:IsA("Snap") or v:IsA("Glue") or v:IsA("Motor") or v:IsA("Motor6D") then
    local save = false
    if (v.Part0 == torso) and (v.Part1 == head) then
     save = true
    end
    if (v.Part0 == head) and (v.Part1 == torso) then
     save = true
    end
    if save then
     if hedafterneck then
      hedafterneck = v
     end
    else
     v:Destroy()
    end
   end
  end
 end
 if method == 3 then
  spawn(function()
   wait(loadtime)
   if model then
    model:BreakJoints()
   end
  end)
 end
end

cl.Parent = c
for i, v in pairs(cl:GetChildren()) do
 v.Parent = c
end
cl:Destroy()

local modelDes = {}
for i, v in pairs(model:GetDescendants()) do
 if v:IsA("BasePart") then
  i = tostring(i)
  v.Destroying:Connect(function()
   modelDes[i] = nil
  end)
  modelDes[i] = v
 end
end
local modelcolcon = nil
local function modelcolf()
 if model then
  for i, v in pairs(modelDes) do
   v.CanCollide = false
  end
 else
  modelcolcon:Disconnect()
 end
end
modelcolcon = stepped:Connect(modelcolf)
modelcolf()

for i, scr in pairs(model:GetDescendants()) do
 if (scr.ClassName == "Script") and table.find(scriptNames, scr.Name) then
  local Part0 = scr.Parent
  if Part0:IsA("BasePart") then
   for i1, scr1 in pairs(c:GetDescendants()) do
    if (scr1.ClassName == "Script") and (scr1.Name == scr.Name) and (not scr1:IsDescendantOf(model)) then
     local Part1 = scr1.Parent
     if (Part1.ClassName == Part0.ClassName) and (Part1.Name == Part0.Name) then
      align(Part0, Part1)
      break
     end
    end
   end
  end
 end
end

if (typeof(hedafterneck) == "Instance") and head then
 local aligns = {}
 local con = nil
 con = hedafterneck.Changed:Connect(function(prop)
     if (prop == "Parent") and not hedafterneck.Parent then
         con:Disconnect()
      for i, v in pairs(aligns) do
       v.Enabled = true
      end
  end
 end)
 for i, v in pairs(head:GetDescendants()) do
  if v:IsA("AlignPosition") or v:IsA("AlignOrientation") then
   i = tostring(i)
   aligns[i] = v
   v.Destroying:Connect(function()
       aligns[i] = nil
   end)
   v.Enabled = false
  end
 end
end

for i, v in pairs(c:GetDescendants()) do
 if v and v.Parent then
  if v.ClassName == "Script" then
   if table.find(scriptNames, v.Name) then
    v:Destroy()
   end
  elseif not v:IsDescendantOf(model) then
   if v:IsA("Decal") then
    v.Transparency = 1
   elseif v:IsA("ForceField") then
    v.Visible = false
   elseif v:IsA("Sound") then
    v.Playing = false
   elseif v:IsA("BillboardGui") or v:IsA("SurfaceGui") or v:IsA("ParticleEmitter") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
    v.Enabled = false
   end
  end
 end
end

if newanimate then
 local animate = gp(c, "Animate", "LocalScript")
 if animate then
  animate.Disabled = false
 end
end

if addtools then
 for i, v in pairs(c:GetChildren()) do
  if v:IsA("Tool") then
   v.Parent = addtools
  end
 end
end

local hum0 = model:FindFirstChildOfClass("Humanoid")
if hum0 then
    hum0.Destroying:Connect(function()
        hum0 = nil
    end)
end

local hum1 = c:FindFirstChildOfClass("Humanoid")
if hum1 then
    hum1.Destroying:Connect(function()
        hum1 = nil
    end)
end

if hum1 then
 ws.CurrentCamera.CameraSubject = hum1
 local camSubCon = nil
 local function camSubFunc()
  camSubCon:Disconnect()
  if c and hum1 then
   ws.CurrentCamera.CameraSubject = hum1
  end
 end
 camSubCon = renderstepped:Connect(camSubFunc)
 if hum0 then
  hum0.Changed:Connect(function(prop)
   if hum1 and (prop == "Jump") then
    hum1.Jump = hum0.Jump
   end
  end)
 else
  respawnrequest()
 end
end

local rb = Instance.new("BindableEvent", c)
rb.Event:Connect(function()
 rb:Destroy()
 sg:SetCore("ResetButtonCallback", true)
 if destroyhum then
  c:BreakJoints()
  return
 end
 if hum0 and (hum0.Health > 0) then
  model:BreakJoints()
  hum0.Health = 0
 end
 if antirespawn then
     respawnrequest()
 end
end)
sg:SetCore("ResetButtonCallback", rb)

spawn(function()
 while c do
  if hum0 and hum1 then
   hum1.Jump = hum0.Jump
  end
  wait()
 end
 sg:SetCore("ResetButtonCallback", true)
end)

R15toR6 = R15toR6 and hum1 and (hum1.RigType == Enum.HumanoidRigType.R15)
if R15toR6 then
    --disabled for this script
end

for i, v in pairs({"Torso", "Head", "HumanoidRootPart"}) do
    local part = gp(c, v, "BasePart")
    local att = gp(part, "att1_" .. v, "Attachment")
    if att then
        part.Archivable = true
        local part1 = part:Clone()
        part1.Anchored = true
        part1.CanCollide = false
        part1.Name = "partholder_" .. v
        part1:ClearAllChildren()
        part1.Parent = c
        att.Parent = part1
    end
end

for i, v in pairs(c:GetChildren()) do
    if v:IsA("Accessory") and (v.Name ~= "MeshPartAccessory") then
        local handle = gp(v, "Handle", "BasePart")
        if handle and (handle.Size ~= v3(4.5, 4.5, 4.5)) then
            local att = gp(handle, "att1_Handle", "Attachment")
            if att then
                handle.Archivable = true
                local handle1 = handle:Clone()
                handle1.Anchored = true
                handle1.CanCollide = false
                handle1.Name = "hatholder_" .. v.Name
                handle1:ClearAllChildren()
                handle1.Parent = c
                att.Parent = handle1
            end
        end
    end
end

if hum1 then 
    hum1.HipHeight = 2
    hum1.WalkSpeed = 25
    hum1.JumpPower = 70
end

local hat = gp(c, "MeshPartAccessory", "Accessory")
local handle = gp(hat, "Handle", "BasePart")
local att = gp(handle, "att1_Handle", "Attachment")
att.Parent = gp(c, "Torso", "BasePart")
att.Position = v3(0, 1.25, 0)

local head = gp(c, "Head", "BasePart")
if not head then return print("head not found") end

local torso = gp(c, "Torso", "BasePart")
if not torso then return print("torso not found") end

local humanoidRootPart = gp(c, "HumanoidRootPart", "BasePart")
if not humanoidRootPart then return print("humanoid root part not found") end

local leftArm = gp(c, "Left Arm", "BasePart")
if not leftArm then return print("left arm not found") end

local rightArm = gp(c, "Right Arm", "BasePart")
if not rightArm then return print("right arm not found") end

local leftLeg = gp(c, "Left Leg", "BasePart")
if not leftLeg then return print("left leg not found") end

local rightLeg = gp(c, "Right Leg", "BasePart")
if not rightLeg then return print("right leg not found") end

--find rig joints

local neck = gp(torso, "Neck", "Motor6D")
if not neck then return print("neck not found") end

local rootJoint = gp(humanoidRootPart, "RootJoint", "Motor6D")
if not rootJoint then return print("root joint not found") end

local leftShoulder = gp(torso, "Left Shoulder", "Motor6D")
if not leftShoulder then return print("left shoulder not found") end

local rightShoulder = gp(torso, "Right Shoulder", "Motor6D")
if not rightShoulder then return print("right shoulder not found") end

local leftHip = gp(torso, "Left Hip", "Motor6D")
if not leftHip then return print("left hip not found") end

local rightHip = gp(torso, "Right Hip", "Motor6D")
if not rightHip then return print("right hip not found") end

--60 fps

local fps = 60
local event = Instance.new("BindableEvent", c)
event.Name = "60 fps"
local floor = math.floor
fps = 1 / fps
local tf = 0
local con = nil
con = game:GetService("RunService").RenderStepped:Connect(function(s)
 if not c then
  con:Disconnect()
  return
 end
 tf += s
 if tf >= fps then
  for i=1, floor(tf / fps) do
   event:Fire(c)
  end
  tf = 0
 end
end)
local event = event.Event

local function stopIfRemoved(instance)
    if not (instance and instance.Parent) then
        c = nil
        return
    end
    instance:GetPropertyChangedSignal("Parent"):Connect(function()
        if not (instance and instance.Parent) then
            c = nil
        end
    end)
end
stopIfRemoved(c)
stopIfRemoved(hum)
for i, v in pairs({head, torso, leftArm, rightArm, leftLeg, rightLeg, humanoidRootPart}) do
    stopIfRemoved(v)
end
for i, v in pairs({neck, rootJoint, leftShoulder, rightShoulder, leftHip, rightHip}) do
    stopIfRemoved(v)
end
if not c then
    return
end
local mode = false
uis = game:GetService("UserInputService")
local modes = {
 [Enum.KeyCode.T] = "emote"
}
uis.InputBegan:Connect(function(keycode)
    if uis:GetFocusedTextBox() then
        return
    end
 keycode = keycode.KeyCode
 if modes[keycode] ~= nil then
  if mode == modes[keycode] then
   mode = nil
  else
   mode = modes[keycode]
  end
 end
end)
leftShoulder.Part0 = leftLeg
rightShoulder.Part0 = rightLeg
local cf, v3, euler, sin, sine, abs = CFrame.new, Vector3.new, CFrame.fromEulerAnglesXYZ, math.sin, 0, math.abs
while event:Wait() do
    sine += 1
    local vel = humanoidRootPart.Velocity
    if abs(vel.Y) > 2 then -- jump
        neck.C0 = neck.C0:Lerp(cf(0, 1, 0) * euler(-1.5882496193148399, 0, -3.1590459461097367), 0.2) 
        rootJoint.C0 = rootJoint.C0:Lerp(cf(0, 0, 0) * euler(-1.5707963267948966 + 0.08726646259971647 * sin(sine * 0.1), 0, -3.141592653589793), 0.2) 
        leftShoulder.C0 = leftShoulder.C0:Lerp(cf(0.5, -1, 0.5) * euler(-1.5707963267948966 + -0.3490658503988659 * sin(sine * 0.2), -1.5707963267948966, 0), 0.2) 
        rightShoulder.C0 = rightShoulder.C0:Lerp(cf(-0.5, -1, 0.5) * euler(-1.7453292519943295 + 0.3490658503988659 * sin(sine * 0.2), 1.5707963267948966, 0), 0.2) 
        leftHip.C0 = leftHip.C0:Lerp(cf(-1, -1, 0) * euler(0.6981317007977318 + 0.17453292519943295 * sin(sine * 0.2), -1.5707963267948966, 0), 0.2) 
        rightHip.C0 = rightHip.C0:Lerp(cf(1, -1, 0) * euler(0.6981317007977318 + -0.17453292519943295 * sin(sine * 0.2), 1.5707963267948966, 0), 0.2) 
    elseif (vel*v3(1, 0, 1)).Magnitude > 2 then -- walk
        neck.C0 = neck.C0:Lerp(cf(0, 1, 0) * euler(-1.5882496193148399, 0, -3.1590459461097367), 0.2) 
        rootJoint.C0 = rootJoint.C0:Lerp(cf(0, 0.5 * sin(sine * 0.2), 0) * euler(-1.5707963267948966 + -0.08726646259971647 * sin(sine * 0.2), 0.03490658503988659 * sin(sine * 0.1), -3.141592653589793 + 0.17453292519943295 * sin((sine + -10) * 0.1)), 0.2) 
        leftShoulder.C0 = leftShoulder.C0:Lerp(cf(0.5, -1.5, 0) * euler(0, -1.5882496193148399, 0.6981317007977318 + 0.6981317007977318 * sin((sine + 40) * 0.1)), 0.2) 
        rightShoulder.C0 = rightShoulder.C0:Lerp(cf(-0.5, -1.5, 0) * euler(0, 1.5707963267948966, -0.6981317007977318 + -0.6981317007977318 * sin((sine + -40) * 0.1)), 0.2) 
        leftHip.C0 = leftHip.C0:Lerp(cf(-1, -1, 0) * euler(0, -1.5882496193148399, 0.8726646259971648 * sin(sine * 0.1)), 0.2) 
        rightHip.C0 = rightHip.C0:Lerp(cf(1, -1, 0) * euler(0, 1.5707963267948966, 0.8726646259971648 * sin(sine * 0.1)), 0.2) 
    else -- idle
  if not mode then
            neck.C0 = neck.C0:Lerp(cf(0, 1, 0) * euler(-1.5882496193148399, 0, -3.1590459461097367), 0.2) 
            rootJoint.C0 = rootJoint.C0:Lerp(cf(0, -4, 0) * euler(-1.5707963267948966, 0, -3.141592653589793), 0.2) 
            leftShoulder.C0 = leftShoulder.C0:Lerp(cf(0.5, -1.5, 0) * euler(0, -1.5707963267948966, 0), 0.2) 
            rightShoulder.C0 = rightShoulder.C0:Lerp(cf(-0.5, -1.5, 0) * euler(0, 1.5707963267948966, 0), 0.2) 
            leftHip.C0 = leftHip.C0:Lerp(cf(-1, -1, 0) * euler(0, -1.5707963267948966, 0), 0.2) 
            rightHip.C0 = rightHip.C0:Lerp(cf(1, -1, 0) * euler(0, 1.5707963267948966, 0), 0.2) 
  elseif mode == "emote" then
            neck.C0 = neck.C0:Lerp(cf(0, 1, 0) * euler(-1.5882496193148399, 0, -3.1590459461097367), 0.2) 
            rootJoint.C0 = rootJoint.C0:Lerp(cf(0, -2, 0) * euler(-1.5707963267948966, 0, -3.141592653589793), 0.2) 
            leftShoulder.C0 = leftShoulder.C0:Lerp(cf(0.5, 0.5, -4.5) * euler(0, -1.5707963267948966, 0), 0.2) 
            rightShoulder.C0 = rightShoulder.C0:Lerp(cf(-0.5, 0.5, -4.5) * euler(0, 1.5707963267948966, 0), 0.2) 
            leftHip.C0 = leftHip.C0:Lerp(cf(-2.75, -1, 2.25) * euler(0, -1.5707963267948966, 0), 0.2) 
            rightHip.C0 = rightHip.C0:Lerp(cf(2.75, -1, 2.25) * euler(0, 1.5707963267948966, 0), 0.2) 
  end
    end
end
