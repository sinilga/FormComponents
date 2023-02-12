local TScrollPanel = {}

local DefButtonSize = 20

local function GetMinSize(self)
	local cont = self.pnlContent
	local w,h = 0,0
	for _,ctrl in pairs(cont.Controls) do
		if ctrl.X + ctrl.Width > w then
			w = ctrl.X + ctrl.Width
		end
		if ctrl.Y + ctrl.Height > h then
			h = ctrl.Y + ctrl.Height
		end
	end
	return w,h
end
	
local function Adjust(self)
	local cont = self.pnlContent
	local w,h = GetMinSize(self)
	if self.Direction == "H" then
		cont.Width = w
	elseif self.Direction == "V" then
		cont.Height = h
	end
	if cont.Width < cont.Parent.Width then
		cont.Width = cont.Parent.Width
	end
	if cont.Height < cont.Parent.Height then
		cont.Height = cont.Parent.Height
	end
end

local function SetButtonsEnabled(self)
	local cont = self.pnlContent
	if self.btnBack and self.Direction == "H" then
		self.btnBack.Enabled = cont.X < 0
	elseif self.btnBack then
		self.btnBack.Enabled = cont.Y < 0
	end
	if self.btnForward and self.Direction == "H" then
		self.btnForward.Enabled = cont.X > cont.Parent.Width - cont.Width 
	elseif self.btnForward then	
		self.btnForward.Enabled = cont.Parent.Height - cont.Height
	end
end

local function AddControl(self,ctrl)
	local site = self.pnlContent
	site:AddControl(ctrl)
	Adjust(self)
	SetButtonsEnabled(self)
end

local function ScrollBack(self)
	local cont = self.pnlContent
	if self.Direction == "H" then
		local x = math.min(cont.X + self.ScrollStep,0) 
		if cont.X ~= x then
			cont.X = x
			SetButtonsEnabled(self)
			if type(self.OnScroll) == "function" then
				assert(self.OnScroll)(self)
			end
		end
	else	
		local y = math.min(cont.Y + self.ScrollStep,0)
		if cont.Y ~= y then
			cont.Y = y
			SetButtonsEnabled(self)
			if type(self.OnScroll) == "function" then
				assert(self.OnScroll)(self)
			end
		end	
	end	
end

local function ScrollForward(self)
	local cont = self.pnlContent
	if self.Direction == "H" then
		local x = math.max(cont.X - self.ScrollStep,cont.Parent.Width - cont.Width) 
		if cont.X ~= x then
			cont.X = x
			SetButtonsEnabled(self)
			if type(self.OnScroll) == "function" then
				assert(self.OnScroll)(self)
			end
		end	
	else	
		local y = math.max(cont.Y - self.ScrollStep,cont.Parent.Height - cont.Height) 
		if cont.Y ~= y then
			cont.Y = y
			SetButtonsEnabled(self)
			if type(self.OnScroll) == "function" then
				assert(self.OnScroll)(self)
			end
		end	
	end	
end

local function ScrollStart(self)
	local cont = self.pnlContent
	if self.Direction == "H" and cont.X ~= 0 then
		cont.X = 0
		SetButtonsEnabled(self)
		if type(self.OnScroll) == "function" then
			assert(self.OnScroll)(self)
		end
	elseif self.Direction == "V" and cont.Y ~= 0 then
		cont.Y = 0
		SetButtonsEnabled(self)
		if type(self.OnScroll) == "function" then
			assert(self.OnScroll)(self)
		end
	end	
end

local function ScrollEnd(self)
	local cont = self.pnlContent
	if self.Direction == "H" and cont.X ~= cont.Parent.Width - cont.Width then
		cont.X = cont.Parent.Width - cont.Width
		SetButtonsEnabled(self)
		if type(self.OnScroll) == "function" then
			assert(self.OnScroll)(self)
		end
	elseif self.Direction == "V" and cont.Y ~= cont.Parent.Height - cont.Height then
		cont.Y = cont.Parent.Height - cont.Height
		SetButtonsEnabled(self)
		if type(self.OnScroll) == "function" then
			assert(self.OnScroll)(self)
		end
	end	
end

local function Clear(self)
	local cont = self.pnlContent
	for _, ctrl in pairs(cont.Controls) do
		ctrl:DeleteControl()
	end
	self.pnlContent.Width = self.pnlContent.Parent.Width
	self.pnlContent.Height = self.pnlContent.Parent.Height
	self.pnlContent.X = 0
	self.pnlContent.Y = 0
end

local function SetBtnPosition(btn, side)
	if side == "Left" then
		btn.X = 0
		btn.Y = 0
		btn.Height = btn.Parent.Height
	elseif side == "Top" then
		btn.X = 0
		btn.Y = 0
		btn.Width = btn.Parent.Width
	elseif side == "Right" then
		btn.X = btn.Parent.Width - btn.Width
		btn.Y = 0
		btn.Height = btn.Parent.Height
	elseif side == "Bottom" then
		btn.X = 0
		btn.Y = btn.Parent.Height - btn.Height
		btn.Width = btn.Parent.Width
	end
end

local function SetControlPosition(self)
	if self.Direction == "H" then
		if self.btnBack then
			SetBtnPosition(self.btnBack,"Left")
		end
		if self.btnForward then
			SetBtnPosition(self.btnForward,"Right")
		end	
	else
		if self.btnBack then
			SetBtnPosition(self.btnBack,"Top")
		end
		if self.btnForward then
			SetBtnPosition(self.btnForward,"Bottom")
		end	
	end
	local view = self.pnlView
	if self.Direction == "H" then
		if self.btnBack then
			view.X = self.btnBack.Width
		else
			view.X = 0
		end	
		view.Y = 0
		if self.btnForward then
			view.Width = self.btnForward.X - view.X
		else
			view.Width = self.Site.Width - view.X
		end
		view.Height = self.Site.Height
	else
		view.X = 0
		if self.btnBack then
			view.Y = self.btnBack.Height
		else
			view.Y = 0
		end		
		view.Width = self.Site.Width
		if self.btnForward then
			view.Height = self.btnForward.Y - view.Y
		else
			view.Height = self.Site.Height - view.Y
		end
	end
	if self.Direction == "H" and self.pnlContent.X + self.pnlContent.Width < view.Width then
		local x = view.Width - self.pnlContent.Width
		if x > 0 then
			self.pnlContent.X = 0
			self.pnlContent.Width = view.Width
		else		
			self.pnlContent.X = x
		end
		self.pnlContent.Height = view.Height
	end
	if self.Direction == "V" and self.pnlContent.Y + self.pnlContent.Height < view.Height then
		local y = view.Height - self.pnlContent.Height
		if y > 0 then
			self.pnlContent.Y = 0
			self.pnlContent.Height = view.Height
		else		
			self.pnlContent.Y = y
		end
		self.pnlContent.Width = view.Width
	end
	SetButtonsEnabled(self)
end

local function GetVisibleArea(self)
	local left = 0 - self.pnlContent.X
	local top = 0 - self.pnlContent.Y
	local right = left + self.pnlContent.Parent.Width
	local bottom = top + self.pnlContent.Parent.Height
	return {
		Left = left,
		Top = top,
		Right = right,
		Bottom = bottom,
	}
end

local function SetButtonSize(self,size)
	if size < 0 then
		size = 0	
	end
	self.ButtonSize = size
	if self.Direction == "H" and self.btnBack then
		self.btnBack.Width = size
	elseif self.Direction == "H" and self.btnForward then
		self.btnForward.Width = size
	elseif self.Direction == "V" and self.btnBack then
		self.btnBack.Heigth = size
	elseif self.Direction == "V" and self.btnForward then
		self.btnForward.Heigth = size
	end	
	SetControlPosition(self)
end

local function new(site,dir,btn1,btn2)
	local obj = {}
	setmetatable(obj, {["__index"] = TScrollPanel})
	if render(site):match("Panel") then
		obj.Site = site
	else
		return nil
	end	
	if type(dir) == "string" and dir == "V" or dir == "H" then	
		obj.Direction = dir
	else
		obj.Direction = "H"
	end	
	if btn1 then
		obj.btnBack = btn1
	else	
		obj.btnBack = site["btnBack"]
	end
	if btn2 then
		obj.btnForward = btn2
	else	
		obj.btnForward = site["btnForward"]
	end
	if obj.btnBack then
		obj.btnBack.Click = function()
			ScrollBack(obj)
		end
	end
	if obj.btnForward then
		obj.btnForward.Click = function()
			ScrollForward(obj)
		end
	end
	local pnl = Panel.new("pnlView")
	obj.Site:AddControl(pnl)
	obj.pnlView = pnl
	local cont = Panel.new("pnlContent","",0,0,obj.pnlView.Width,obj.pnlView.Height)
	obj.pnlView:AddControl(cont)
	obj.pnlContent = cont
	SetButtonSize(obj,DefButtonSize)
	SetControlPosition(obj)
	obj.Site.Resize = function()
		SetControlPosition(obj)
		Adjust(obj)
		if obj.pnlContent.Width < obj.pnlView.Width then
			obj.pnlContent.X = 0
			obj.pnlContent.Width = obj.pnlView.Width
		elseif obj.pnlContent.X + obj.pnlContent.Width < obj.pnlView.Width then
			local x = obj.pnlView.Width - obj.pnlContent.Width
			obj.pnlContent.X = x
		end
		if obj.pnlContent.Height < obj.pnlView.Height then
			obj.pnlContent.Y = 0
			obj.pnlContent.Height = obj.pnlView.Height
		elseif obj.pnlContent.Y + obj.pnlContent.Height < obj.pnlView.Height then
			local y = obj.pnlView.Height - obj.pnlContent.Height
			obj.pnlContent.Y = y
		end
		SetButtonsEnabled(obj)
	end
	return obj
end

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
TScrollPanel = {
	ButtonSize = DefButtonSize,
	ScrollStep = 50,
	new = new,
	AddControl = AddControl,
	Adjust = Adjust,
	ScrollBack = ScrollBack,
	ScrollForward = ScrollForward,
	ScrollStart = ScrollStart,
	ScrollEnd = ScrollEnd,
	Clear = Clear,
	GetVisibleArea = GetVisibleArea,
	SetButtonPosition = SetButtonPosition,
}

setmetatable(TScrollPanel,{ ["__call"] = function(self,...) return new(...) end } )
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
return TScrollPanel
