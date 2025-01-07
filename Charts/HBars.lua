HBars = {
	Title = nil,
	Data = {},
	HeaderFont = { Name = "Arial", Size = 12, Bold = true, Italic = false, Underline = false, Color = 0 },
	Labels = {},
	ShowLabels = nil, -- top/center/bottom/out/false
	Captions = nil,
	ToolTips = nil,
	Colors = Color.CornflowerBlue,

	margin = {left = 10, top = 10, right = 10, bottom = 10},
	
	gap = 0.38,
	
	Site = nil,
}
	
HBars.Create = function(self)
	local cnt = #self.Data
	local work_area = {
		X = self.margin.left, 
		Y = self.margin.top, 
		Width = self.Site.Width - self.margin.left - self.margin.right,
		Height = self.Site.Height - self.margin.top - self.margin.bottom,
	} 
	local barW = math.ceil(math.max(work_area.Height / cnt,10))
	local _max = -math.huge
	for _, point in pairs(self.Data) do
		if point.value > _max then
			_max = point.value
		end
	end
	
	local function create_point(n)
		local pnl = Panel()
		local gap = self.gap or 0.38
		pnl.Height = barW * (1-gap)
		pnl.Width = self.chart.Width * self.Data[n+1].value/_max
		pnl.Y = barW*n + (barW - pnl.Height)/2
		pnl.X = self.chart.Width - pnl.Width
		pnl.BackColor = type(self.Colors) == "table" and self.Colors[n+1] or self.Colors
		pnl.Transparent = false
		pnl.Border = 0
		self.chart:AddControl(pnl)
		pnl.DoubleClick = function(control)
			if type(self.OnDoublelClick) == "function" then
				assert(self.OnDoublelClick)(control, n+1)
			end
		end
		return pnl
	end

	local function axis()
		local H = 0
		local pnl = Panel("line")
		pnl.X = 0
		pnl.Y = 0
		pnl.Width = 2
		pnl.Height = self.Axis.Height
		pnl.BackColor = RGB(50,50,50)
		pnl.Transparent = false
		self.Axis:AddControl(pnl)
		
		for i=1, #self.Data do
			local lab = Label("lab_"..i)
			lab.Text = self.Data[i].name
			self.Axis:AddControl(lab)
			lab:AdjustMinSize()
			lab.Width = math.min(lab.Width, self.Axis.Width-2)
			lab.Height = math.min(TextHeight(lab,lab.Width),barW)
			lab.TextAlign = ContentAlignment.TopRight
			lab.X = pnl.X
			lab.Y = barW*(i-1) + (barW - lab.Height)/2
			if lab.X + lab.Width > H then
				H = lab.X + lab.Width
			end
			self.Data[i].caption = lab
		end
		self.Axis.Width = H + 5 + self.Axis.line.Width
	end
	
	local function labels()
		for i=1,#self.Data do
			local lab = Label()
			lab.Text = self.Data[i].value
			self.chart:AddControl(lab)
			lab:AdjustMinSize()
			lab.Visible = self.ShowLabels
			self.Data[i].lab = lab
			HBars.lab_pos(self.Data[i],self.ShowLabels)
		end
	end
	------------------------------------------------
	-- header
	local lab = Label()
	lab.Text = self.Title or "HBars chart"
	lab.X, lab.Y = work_area.X, work_area.Y
	self.Header = self.Site:AddControl(lab)
	HBars.SetHeaderStyle(self,self.HeaderFont)
	
	-- chart	
	local pnl = Panel()
	pnl.X, pnl.Y = self.Header.X + 50, self.Header.Y + self.Header.Height
	pnl.Width, pnl.Height = work_area.Width - pnl.X, work_area.Height - pnl.Y
	pnl.Transparent = true
	self.chart = self.Site:AddControl(pnl)

	-- axis
	self.Axis = Panel()
	self.Axis.X, self.Axis.Y = work_area.X, self.Header.Y + self.Header.Height
	self.Axis.Width, self.Axis.Height = 50, work_area.Height - self.Axis.Y
	self.Axis.Transparent = true
	self.Site:AddControl(self.Axis)
	
	for i=1,#self.Data do
		self.Data[i].ctrl = create_point(i-1)
	end
	
	labels()
	
	self.chart.Resize = function(event) HBars.chart_resize(self,event) end
	self.Header.Resize = function(event) HBars.header_resize(self,event) end
	self.Axis.Resize = function(event) HBars.axis_resize(self,event) end
	
	axis()
	HBars.chart_resize(self,{Control = self.chart})
end

HBars.chart_resize = function(self,event)
	local control = event.Control
	local barW = math.max(control.Height / #self.Data, 10)
	local gap = self.gap or 0.38
	local W = control.Width - 5
	if type(self.ShowLabels) == "string" and self.ShowLabels == "out" then
		for i=1,#self.Data do
			local item = self.Data[i]
			local k, d = item.value/(self.Sup-self.Inf),item.lab.Width + 5
			if W*k + d > control.Width then
				W = (control.Width - d)/k
			end
		end	
	end
	for i=1,#self.Data do
		local item = self.Data[i]
		item.ctrl.Height = barW * (1 - gap)
		item.ctrl.Width = W*item.value/(self.Sup - self.Inf)
		item.ctrl.X = 0
		item.ctrl.Y = barW*(i-1) + (barW - item.ctrl.Height)/2
		item.lab.Y = item.ctrl.Y + (item.ctrl.Height - item.lab.Height)/2
		item.caption.Y = item.ctrl.Y + (item.ctrl.Height - item.caption.Height)/2
		HBars.lab_pos(item,self.ShowLabels)
	end
end

HBars.header_resize = function(self,event)
	self.chart.Y = self.Header.Y + self.Header.Height + 5
	self.chart.Height = self.Site.Height - self.margin.top - self.margin.bottom - self.chart.Y
end

HBars.axis_resize = function(self,event)
	self.chart.X = self.Axis.X + self.Axis.Width
	self.chart.Height = self.Site.Width - self.margin.left - self.margin.right - self.chart.X
	self.Axis.line.X = self.Axis.Width - self.Axis.line.Width
	for i=1,#self.Data do
		local item = self.Data[i]
		item.caption.X = self.Axis.line.X - item.caption.Width - 5
		item.caption.Y = item.ctrl.Y + (item.ctrl.Height - item.caption.Height)/2
	end
end

HBars.getBounds = function(self)
	self.Inf, self.Sup = 0, -math.huge
	for i=1,#self.Data do
		if self.Data[i].value > self.Sup then
			self.Sup = self.Data[i].value
		end
	end
end
	
HBars.set_ShowLabels = function(self,val,mt)
	mt.ShowLabels = val
	local data = self.Data
	for i=1,#data do
		data[i].lab.Visible = val
		if type(val) == "string" then
			HBars.lab_pos(data[i],val)
		end
	end
	self.chart.Resize({Control = self.chart})
end
	
HBars.lab_pos = function(item,pos)
	item.lab.Y = item.ctrl.Y + (item.ctrl.Height - item.lab.Height)/2
	if pos == "bottom" then
		item.lab.X = item.ctrl.X + 5
	elseif pos == "center" then
		item.lab.X = item.ctrl.X + (item.ctrl.Width - item.lab.Width)/2
	elseif pos == "top" then
		item.lab.X = item.ctrl.X + item.ctrl.Width - item.lab.Width - 5
	elseif pos == "out" then
		item.lab.X = item.ctrl.X + item.ctrl.Width + 5
	end
end
	
HBars.set_Title = function(self,text,mt)
	mt.Title = text
	self.Header.Text = text
	self.Header:AdjustMinSize()
end
	
HBars.set_ShowHeader = function(self, show, mt)
	self.ShowTitle = show
	self.Header.Visible = show
	if show then
		self.Header:AdjustMinSize()
	else
		self.Header.Height = 0
	end
end
	
HBars.SetHeaderStyle = function(self,style)
	for key, val in pairs(style) do
		local prop = (key == "Color" and "ForeColor") or ("Font"..key)
		self.Header[prop] = val
		self.Header:AdjustMinSize()
		self.Header.Width = self.Site.Width - self.Header.X - self.margin.left
	end	
end

HBars.set_Captions = function(self,captions)
	local W = self.Site.Width - self.Header.X - self.margin.left
	local barW = math.max(self.Axis.Height / #self.Data, 10)
	local m = self.Data[1].lab.Width
	for i=1,#self.Data do
		local item = self.Data[i]
		m = math.max(m,item.lab.Width)
	end	
	W = W - m - 65
	local cap_w = 0
	for i=1,#self.Data do
		local item = self.Data[i]
		item.caption.Text = captions[i]
		item.caption:AdjustMinSize()
		if item.caption.Width >  W then
			item.caption.Width = W
		end	
		item.caption.Height = math.min(item.caption.Height,barW)
		item.caption.X = self.Axis.line.X - item.caption.Width - 5
		item.caption.Y = item.ctrl.Y + (item.ctrl.Height - item.caption.Height)/2
		cap_w = math.max(cap_w,item.caption.Width)
	end
	self.Axis.Width = cap_w + 5 + self.Axis.line.Width
end
	
HBars.set_Labels = function(self,labels)
	local W = self.Site.Width - self.Header.X - self.margin.left
	local lab_w = 0
	for i=1,#self.Data do
		local item = self.Data[i]
		item.lab.Text = labels[i]
		item.lab:AdjustMinSize()
		item.lab.Width = math.min(item.lab.Width,100)
		lab_w = math.max(lab_w,item.lab.Width)
	end	
	HBars.chart_resize(self,{Control = self.chart})
end	
	
HBars.set_Colors = function(self, colors)
	for i=1,#self.Data do
		self.Data[i].ctrl.BackColor = type(colors) == "table" and colors[1+(i-1)%#colors] or colors
	end
end
	
HBars.Redraw = function()
		
end	
	
HBars.new = function(site,data, labs)
	local obj = CreateInstance(HBars)
	obj.Site = site
	obj.Data = {}
	for i=1,#data do
		table.insert(obj.Data, { name = labs[i], value = data[i]})
	end
	obj:getBounds()
	obj:Create()
	
	return obj
end

setmetatable(HBars,{__call = function(self, ...) return HBars.new(...) end })
return HBars
