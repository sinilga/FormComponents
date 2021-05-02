--[[
	Модуль для укладки элементов формы
	(С) Sinilga, 2012-2019	
]]
TFormAlign = {}

local function SetRules(self, control, rules)
	if type(self.AlignData[control]) ~= "table" then
		self.AlignData[control] = {}
	end	
	local a = self.AlignData[control]
	if type(rules[1]) == "userdata" then
		a.LeftMargin = control.X - (rules[1].X + rules[1].Width)
	else
		a.LeftMargin = a.LeftMargin or control.X
	end	
	if type(rules[2]) == "userdata" then
		a.TopMargin = control.Y - (rules[2].Y + rules[2].Height)
	else
		a.TopMargin = a.TopMargin or control.Y
	end	
	if type(rules[3]) == "userdata" then
		a.RightMargin = rules[3].X - (control.X + control.Width)
	else
		a.RightMargin = a.RightMargin or (control.Parent.Width - (control.X + control.Width))
	end	
	if type(rules[4]) == "userdata" then
		a.BottomMargin = rules[4].Y - (control.Y + control.Height)
	else
		a.BottomMargin = a.BottomMargin or (control.Parent.Height - (control.Y + control.Height))
	end	
	a.Rules = rules
end

local function RemoveRules(self, control)
	self.AlignData[control] = nil
end

local function resize(self, cont)
	local pass = {}
	local queue = {cont or self.Form}
	while #queue > 0 do
		repeat
		local ctrl = table.remove(queue, 1)
		local a = self.AlignData[ctrl]
		local left,top,right,bottom = 0,0,ctrl.Parent and ctrl.Parent.Width or 0,ctrl.Parent and ctrl.Parent.Height or 0
		if a then
			if type(a.Rules[1]) == "userdata" then
				if not pass[a.Rules[1]] then table.insert(queue,ctrl); break end
				left = a.Rules[1].X + a.Rules[1].Width + a.LeftMargin
			else
				left = a.LeftMargin
			end
			if type(a.Rules[3]) == "userdata" then
				if not pass[a.Rules[3]] then table.insert(queue,ctrl); break end
				right = a.Rules[3].X - a.RightMargin
			else	
				right = ctrl.Parent.Width - a.RightMargin
			end
			if type(a.Rules[2]) == "userdata" then
				if not pass[a.Rules[2]] then table.insert(queue,ctrl); break end
				top = a.Rules[2].Y + a.Rules[2].Height + a.TopMargin
			else
				top = a.TopMargin
			end
			if type(a.Rules[4]) == "userdata" then
				if not pass[a.Rules[4]] then table.insert(queue,ctrl); break end
				bottom = a.Rules[4].Y - a.BottomMargin
			else	
				bottom = ctrl.Parent.Height - a.BottomMargin
			end
			if a.Rules[1] and a.Rules[3] then 
				ctrl.X = left
				ctrl.Width = right - left
			elseif a.Rules[3] then	
				ctrl.X = math.max(right  - ctrl.Width, 0)
			end
			if a.Rules[2] and a.Rules[4] then 
				ctrl.Y = top
				ctrl.Height = bottom - top
			elseif a.Rules[4] then 
				ctrl.Y = math.max(bottom - ctrl.Height, 0)
			end
		end	
		for _, c in pairs(ctrl.Controls) do
			table.insert(queue, c)
		end
		pass[ctrl] = 1
		until true
	end
	if type(self.OnResize) == "function" and cont == self.Form then
		self:OnResize()
	end
end

local function form_align(self)
	local form_module = self.Form.Module
	if self.MinWidth and form_module.Me.Width < self.MinWidth then
		form_module.Me.Width = self.MinWidth
	end
	if self.MinHeight and form_module.Me.Height < self.MinHeight then
		form_module.Me.Height = self.MinHeight
	end
	if self.MaxWidth and form_module.Me.Width > self.MaxWidth then
		form_module.Me.Width = self.MaxWidth
	end
	if self.MaxHeight and form_module.Me.Height > self.MaxHeight then
		form_module.Me.Height = self.MaxHeight
	end
	if self.CurWidth ~= form_module.Me.Width or self.CurHeight ~= form_module.Me.Height then
		self.CurWidth = form_module.Me.Width
		self.CurHeight = form_module.Me.Height
		resize(self,form_module.Me)
	end	
end

local function collect(self, cont)
	local queue = {cont or self.Form}
	while #queue > 0 do
		local ctrl = table.remove(queue, 1)
		if ctrl.Parent then
			self.AlignData[ctrl] = self.AlignData[ctrl] or {}
			local a = self.AlignData[ctrl]
			a.LeftMargin = ctrl.X
			a.RightMargin = ctrl.Parent.Width - (ctrl.X + ctrl.Width)
			a.TopMargin = ctrl.Y
			a.BottomMargin = ctrl.Parent.Height - (ctrl.Y + ctrl.Height)
			a.Rules = TFormAlign.alLeftTop
		end	
		for _, c in pairs(ctrl.Controls) do
			table.insert(queue, c)
		end
	end
	return
end

local function new(form)
	local obj = {}
	setmetatable(obj, {["__index"] = TFormAlign})
	obj.Form = form
	obj.CurWidth = form.Width or 0
	obj.CurHeight = form.Height or 0
	obj.AlignData = {}
	collect(obj,form)
	if form["Область данных"] then
		obj.AlignData[form["Область данных"]].Rules = obj.alTop
	end
	if form["Заголовок формы"] then
		obj.AlignData[form["Заголовок формы"]].Rules = obj.alTop
	end
	if form["Примечание формы"] then
		obj.AlignData[form["Примечание формы"]].Rules = obj.alTop
	end
	if form["Область данных"] then
		form["Область данных"].Move = function(event)
			form_align(obj)
		end
	else
		form.Resize = function(event)
			form_align(obj)
		end
	end
	return obj
end

local function Align2Parts(self, ctrl_1, ctrl_2, k, dir)
	if dir:upper() == "H" then
		local delta = (ctrl_1.Width - k * ctrl_2.Width) / (k + 1)
		ctrl_1.Width = ctrl_1.Width - delta
		ctrl_2.X = ctrl_2.X - delta
		ctrl_2.Width = ctrl_2.Width + delta
		self.AlignData[ctrl_1].RightMargin = ctrl_1.Parent.Width - ctrl_1.Width - ctrl_1.X
		self.AlignData[ctrl_2].LeftMargin = ctrl_2.X
	elseif dir:upper() == "V" then
		local delta = (ctrl_1.Height - k * ctrl_2.Height) / (k + 1)
		ctrl_1.Height = ctrl_1.Height - delta
		ctrl_2.Y = ctrl_2.Y - delta
		ctrl_2.Height = ctrl_2.Height + delta
		self.AlignData[ctrl_1].BottomMargin = ctrl_1.Parent.Height - ctrl_1.Height - ctrl_1.Y
		self.AlignData[ctrl_2].TopMargin = ctrl_2.Y
	end
	resize(self,ctrl_1)
	resize(self,ctrl_2)
end

local function SetPosition(ctrl,rules,left,top,right,bottom,w,h)
	if not rules then
		rules = TFormAlign.alLeftTop
	end
	if w then
		ctrl.Width = w
	end
	if h then
		ctrl.Height = h
	end	
	left, top, right, bottom = left or 0, top or 0, right or 0, bottom or 0
	if rules[1] and rules[3] then 
		ctrl.X = left
		ctrl.Width = ctrl.Parent.Width - right - ctrl.X 
	elseif rules[3] then	
		ctrl.X = math.max(ctrl.Parent.Width - right - ctrl.Width, 0)
	elseif rules[1] then	
		ctrl.X = left
	end
	if rules[2] and rules[4] then 
		ctrl.Y = top 
		ctrl.Height = ctrl.Parent.Height - bottom - ctrl.Y 
	elseif rules[4] then 
		ctrl.Y = math.max(ctrl.Parent.Height - bottom - ctrl.Height, 0)
	elseif rules[2] then	
		ctrl.Y = top 
	end
end

-----------------------------------------------------------------------------
TFormAlign = {
	alLeft =        {true,  true,  false, true  },
	alTop =         {true,  true,  true,  false },
	alRight =       {false, true,  true,  true  },
	alBottom =      {true,  false, true,  true  },
	alClient =      {true,  true,  true,  true  },
	alLeftTop =     {true,  true,  false, false },
	alTopLeft =     {true,  true,  false, false },
	alLeftBottom =  {true,  false, false, true  },
	alBottomLeft =  {true,  false, false, true  },
	alRightTop =    {false, true,  true,  false },
	alTopRight =    {false, true,  true,  false },
	alRightBottom = {false, false, true,  true  },
	alBottomRight = {false, false, true,  true  },
	SetRules = SetRules,
	RemoveRules = RemoveRules,
	Align2Parts = Align2Parts,
	resize = resize,
}
setmetatable(TFormAlign, {["__call"] = function(self,...) return new(...) end })

-----------------------------------------------------------------------------
return TFormAlign
