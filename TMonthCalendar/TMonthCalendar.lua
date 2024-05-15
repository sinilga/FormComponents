local TMonthCalendar = {}

local DaysCount = {31,28,31,30,31,30,31,31,30,31,30,31}
local MonthNames = {"Январь","Февраль","Март","Апрель","Май","Июнь","Июль","Август","Сентябрь","Октябрь","Ноябрь","Декабрь"}
local ForeColor = Color.new(30,30,30)
local ActiveItem = Color.Highlight
local ActiveItemText = Color.HighlightText
local InactiveText = Color.Silver

local function CollapseControl(ctrl,x1,y1,x2,y2)
	x1 = x1 or 0
	y1 = y1 or 0
	if x1 < 0 then x1 = 0 end
	if y1 < 0 then y1 = 0 end
	x2 = x2 or x1
	y2 = y2 or y1
	if x2 > ctrl.Width then x2 = ctrl.Width end
	if y2 > ctrl.Height then y2 = ctrl.Height end
	
	local speed = 750
	local cnt = speed/40
	local delta = {
		left = x1/cnt,
		top = y1/cnt,
		right = (ctrl.Width - x2)/cnt,
		bottom = (ctrl.Height - y2)/cnt,
	}
	local start_pos = {
		X = ctrl.X,
		Y = ctrl.Y,
		W = ctrl.Width,
		H = ctrl.Height,
	}
	for i=1,cnt do
		local _x, _y  = ctrl.X, ctrl.Y
		ctrl.X = start_pos.X + i*delta.left
		ctrl.Y = start_pos.Y + i*delta.top
		ctrl.Width = start_pos.W - i*delta.left - i*delta.right
		ctrl.Height = start_pos.H - i*delta.top - i*delta.bottom
		for _, sub in pairs(ctrl.Controls) do
			sub.X = sub.X - ctrl.X + _x
			sub.Y = sub.Y - ctrl.Y + _y
		end
		ctrl.Parent:Redraw()
	end
end

local function ExpandControl(ctrl,x1,y1,x2,y2)
	x1 = x1 or 0
	y1 = y1 or 0
	if x1 < 0 then x1 = 0 end
	if y1 < 0 then y1 = 0 end
	x2 = x2 or ctrl.Parent.Width
	y2 = y2 or ctrl.Parent.Height
	if x2 > ctrl.Parent.Width then x2 = ctrl.Parent.Width end
	if y2 > ctrl.Parent.Height then y2 = ctrl.Parent.Height end
	
	local speed = 750
	local cnt = speed/40
	local delta = {
		left = (ctrl.X - x1)/cnt,
		top = (ctrl.Y - y1)/cnt,
		right = (x2 - ctrl.Width-ctrl.X)/cnt,
		bottom = (y2 - ctrl.Height-ctrl.Y)/cnt,
	}
	local start_pos = {
		X = ctrl.X,
		Y = ctrl.Y,
		W = ctrl.Width,
		H = ctrl.Height,
	}
	for i=1,cnt do
		local _x, _y  = ctrl.X, ctrl.Y
		ctrl.X = start_pos.X - i*delta.left
		ctrl.Y = start_pos.Y - i*delta.top
		ctrl.Width = start_pos.W + i*delta.left + i*delta.right
		ctrl.Height = start_pos.H + i*delta.top + i*delta.bottom
		for _, sub in pairs(ctrl.Controls) do
			sub.X = sub.X + _x - ctrl.X
			sub.Y = sub.Y + _y - ctrl.Y
		end
		ctrl.Parent:Redraw()
	end
	local dx = x1-ctrl.X
	local dy = y1 - ctrl.Y
	for _,sub in pairs(ctrl.Controls) do
		sub.X = sub.X - dx
		sub.Y = sub.Y - dy
	end
	ctrl.X, ctrl.Y = x1,y1
	ctrl.Width, ctrl.Height = x2-x1, y2-y1
end

local function MoveControl(ctrl,x,y)
	if x < ctrl.Parent.X then x = ctrl.Parent.X end
	if y < ctrl.Parent.Y then y = ctrl.Parent.Y end
	if x+ctrl.Width > ctrl.Parent.Width then x = ctrl.Parent.Width-ctrl.Width end
	if y+ctrl.Height > ctrl.Parent.Height then y = ctrl.Parent.Height-ctrl.Height end
	for _, sub in pairs(ctrl.Controls) do
		sub.X = sub.X + ctrl.X - x
		sub.Y = sub.Y + ctrl.Y - y
	end
	ctrl.X = x
	ctrl.Y = y
end

local function IsValidDate(date)
	if not date then return nil end
	local d,m,y = date:match("(%d+)%.(%d+)%.(%d+)")
	d = tonumber(d)
	m = tonumber(m)
	y = tonumber(y)
	if not d or not m or not y then return nil end
	if y < 1900 or y > 2899 then return nil end
	if m < 1 or m > 12 then return nil end
	local cnt = DaysCount[m]
	if m == 2 and (y % 4 == 0 and y % 100 ~= 0 or y % 400 == 0) then cnt = 29 end
	if d < 1 or d > cnt then return nil end
	return date
end

local function Redraw(self)
	local pnlHdr = self.Header
	local hdr = pnlHdr:FindControl("ym_hdr")
	if self.State == "Days" then
		hdr.Text = MonthNames[self.VisibleMonth].." "..self.VisibleYear
	elseif self.State == "Monthes" then	
		hdr.Text = self.VisibleYear
	elseif self.State == "Years" then
		local year = self.VisibleYear - (self.VisibleYear%10)
		hdr.Text = year.." - "..(year+9)
	elseif self.State == "Decs" then
		local dec = self.VisibleYear - self.VisibleYear%100
		hdr.Text = dec.." - "..(dec+99)
	end
	hdr:AdjustMinSize()
	hdr.X = (pnlHdr.Width - hdr.Width) / 2
	
	local td = self.Ctrl:FindControl("today")
	td.Text = "Сегодня: "..os.date("%d.%m.%Y")
	
	for i = 1,6 do
		for j = 1,7 do
			local lbDay = self.Ctrl:FindControl("day_"..i.."_"..j)
			lbDay.lab.Text = ""
			lbDay.Transparent = true
			lbDay.lab.ForeColor = ForeColor
			lbDay.lab.FontBold = false
		end
	end
	
	local cnt = DaysCount[self.VisibleMonth]
	if self.VisibleMonth == 2 and (self.VisibleYear % 4 == 0 and self.VisibleYear % 100 ~= 0 or self.VisibleYear % 400 == 0) then cnt = 29 end
	local wd = tonumber(os.date("%w",os.time({["year"]=self.VisibleYear,["month"]=self.VisibleMonth,["day"]=1})))
	wd = (wd+6)%7+1
	local wn = 1
	for i = 1,cnt do
		local lbDay = self.Ctrl:FindControl("day_"..wn.."_"..wd)
		if not lbDay then MsgBox("No control ".."day_"..wn.."_"..wd);return	end
		lbDay.lab.Text = i
		if self.VisibleMonth == self.Month and self.VisibleYear == self.Year and i == self.Day then
			lbDay.lab.ForeColor = ActiveItemText
			lbDay.lab.FontBold = true
			lbDay.Transparent = false
		end
		wd = wd + 1
		if wd > 7 then 
			wd = 1; wn = wn + 1
		end
	end
	
--	monthes	
	for i=1,12 do
		self.Monthes["mon_"..i].Transparent = true
		self.Monthes["mon_"..i].ForeColor = ForeColor
		self.Monthes["mon_"..i].FontBold = false
	end
	self.Monthes["mon_"..self.VisibleMonth].Transparent = false
	self.Monthes["mon_"..self.VisibleMonth].ForeColor = ActiveItemText
	self.Monthes["mon_"..self.VisibleMonth].FontBold = true

--	years	
	local year = (self.VisibleYear - self.VisibleYear%10) - 1
	for i=1,12 do
		self.Years["year_"..i].Text = year
		self.Years["year_"..i].Transparent = true
		if i==1 or i==12 then
			self.Years["year_"..i].ForeColor = InactiveText
		else
			self.Years["year_"..i].ForeColor = ForeColor
		end	
		self.Years["year_"..i].FontBold = false
		year = year + 1
	end
	local idx = 2 + self.VisibleYear%10
	self.Years["year_"..idx].Transparent = false
	self.Years["year_"..idx].ForeColor = ActiveItemText
	self.Years["year_"..idx].FontBold = true
	
--	decades	
	local dec = (self.VisibleYear - self.VisibleYear%100) - 10
	for i=1,12 do
		self.Decs["dec_"..i].Text = dec.."\r\n"..(dec+9)
		self.Decs["dec_"..i].Transparent = true
		if i==1 or i==12 then
			self.Decs["dec_"..i].ForeColor = InactiveText
		else
			self.Decs["dec_"..i].ForeColor = ForeColor
		end	
		dec = dec + 10
	end
	local idx = 2 + math.floor((self.VisibleYear%100)/10)
	self.Decs["dec_"..idx].Transparent = false
	self.Decs["dec_"..idx].ForeColor = ActiveItemText
	
end

local function PrevMonth(self)
	if self.VisibleMonth == 1 and self.VisibleYear == 1900 then return end
	self.VisibleMonth = self.VisibleMonth - 1
	if self.VisibleMonth == 0 then
		self.VisibleMonth = 12
		self.VisibleYear = self.VisibleYear - 1
	end
	Redraw(self)
end

local function NextMonth(self)
	if self.VisibleMonth == 12 and self.VisibleYear == 2899 then return end
	self.VisibleMonth = self.VisibleMonth + 1
	if self.VisibleMonth == 13 then
		self.VisibleMonth = 1
		self.VisibleYear = self.VisibleYear + 1
	end
	Redraw(self)
end

local function PrevYear(self)
	local year = tonumber(self.Years["year_2"].Text)
	if year > 1900 then
		self.VisibleYear = year - 10
	end	
	Redraw(self)
end

local function NextYear(self)
	local year = tonumber(self.Years["year_2"].Text)
	if year < 2989 then
		self.VisibleYear = year + 10
	end	
	Redraw(self)
end

local function PrevDec(self)
	local dec = self.Decs["dec_2"].Text
	local year = tonumber(dec:match("%d+"))
	if year > 1900 then
		self.VisibleYear = year - 100
	end	
	Redraw(self)
end

local function NextDec(self)
	local dec = self.Decs["dec_2"].Text
	local year = tonumber(dec:match("%d+"))
	if year < 2900 then
		self.VisibleYear = year + 100
	end	
	Redraw(self)
end

local function Show(self)
	if type(self.OnShow) == "function" then
		self.OnShow(self)
	end
	self.Ctrl.Visible = true
	self.VisibleYear = self.Year
	self.VisibleMonth = self.Month
	Redraw(self)
	self.Visible = self.Ctrl.Visible
end

local function SetHeaderText(self,text)
	local hdr = self.HeaderLabel
	hdr.Text = text
	hdr:AdjustMinSize()
	hdr.X = (hdr.Parent.Width - hdr.Width)/2
end

local function Hide(self)
	if type(self.OnHide) == "function" then
		self.OnHide(self)
	end
	self.Ctrl.Visible = false
	self.Visible = self.Ctrl.Visible
end

local function RestoreYears(self,lab)
	lab.Transparent = false
	lab.ForeColor = ForeColor
	MoveControl(self.Years,lab.X + lab.Width/2,lab.Y + lab.Height/2)
	self.Years.Visible = true
	ExpandControl(self.Years)
	self.State = "Years"
	local t = self.Years.Visible
	local t2 = self.Years.X,self.Years.Y,self.Years.Width,self.Years.Height
end

local function RestoreMonthes(self,lab)
	lab.Transparent = false
	lab.ForeColor = ForeColor
	MoveControl(self.Monthes,lab.X + lab.Width/2,lab.Y + lab.Height/2)
	self.Monthes.Visible = true
	ExpandControl(self.Monthes)
	self.State = "Monthes"
end

local function RestoreDays(self,lab)
	lab.Transparent = false
	lab.ForeColor = ForeColor
	MoveControl(self.Ctrl,lab.X + lab.Width/2,lab.Y + lab.Height/2)
	self.Ctrl.Visible = true
	ExpandControl(self.Ctrl)
	self.State = "Days"
end

local function CreateMonth(self)
	local ctrl = Panel.new("monthes","",0,0,self.Body.Width,self.Body.Height)
	self.Body:AddControl(ctrl)
	ctrl.Transparent = false
	ctrl.BackColor = self.Site.BackColor
	self.Monthes = ctrl
	ctrl.Visible = false
	local x, y = 5, 5
	local w, h = ctrl.Width - 10, ctrl.Height - 10
	local dx, dy = w/4, h/3
	local idx = 1
	for i=1,3 do
		for j=1,4 do
			local lab = Label.new("mon_"..idx,MonthNames[idx]:sub(1,3):lower(),x,y,dx,dy)
			ctrl:AddControl(lab)
			lab.BackColor = ActiveItem
			lab.Transparent = true
			lab.TextAlign = ContentAlignment.MiddleCenter
			lab.OnClick = function(control)
				-- expand
				RestoreDays(self,lab)
				local hdr = self.Header:FindControl("ym_hdr")
				local i = lab.Name:match("mon_(%d+)")
				SetHeaderText(self,MonthNames[tonumber(i)]..", "..self.VisibleYear)
				self.VisibleMonth = tonumber(i)
				Redraw(self)
			end
			idx = idx + 1
			x = x + dx
		end
		x = 5
		y = y + dy
	end	
end

local function CreateYears(self)
	local ctrl = Panel.new("years","",0,0,self.Body.Width,self.Body.Height)
	self.Body:AddControl(ctrl)
	ctrl.Transparent = false
	ctrl.BackColor = self.Site.BackColor
	self.Years = ctrl
	ctrl.Visible = false
	local x, y = 5, 5
	local w, h = ctrl.Width - 10, ctrl.Height - 10
	local dx, dy = w/4, h/3
	local year = self.VisibleYear - self.VisibleYear%10 - 1
	local idx = 1
	for i=1,3 do
		for j=1,4 do
			local lab = Label.new("year_"..idx,year,x,y,dx,dy)
			ctrl:AddControl(lab)
			lab.BackColor = ActiveItem
			lab.Transparent = true
			lab.TextAlign = ContentAlignment.MiddleCenter
			if idx == 1 or idx == 12 then
				lab.ForeColor = InactiveText
			else
				lab.OnClick = function(control)
					RestoreMonthes(self,lab)
					self.HeaderLabel.Text = lab.Text
					self.VisibleYear = tonumber(lab.Text)
					Redraw(self)
				end
			end
			x = x + dx
			year = year + 1
			idx = idx + 1
		end
		x = 5
		y = y + dy
	end	
end

local function CreateDecades(self)
	local ctrl = Panel.new("decs","",0,0,self.Body.Width,self.Body.Height)
	self.Body:AddControl(ctrl)
	ctrl.Transparent = false
	ctrl.BackColor = self.Site.BackColor
	self.Decs = ctrl
	ctrl.Visible = false
	local x, y = 5, 5
	local w, h = ctrl.Width - 10, ctrl.Height - 10
	local dx, dy = w/4, h/3
	local dec = 1900
	local idx = 1
	for i=1,3 do
		for j=1,4 do
			local lab = Label.new("dec_"..idx,dec.."\r\n"..(dec+9),x,y,dx,dy)
			ctrl:AddControl(lab)
			lab.BackColor = ActiveItem
			lab.Transparent = true
			lab.TextAlign = ContentAlignment.MiddleCenter
			if idx == 1 or idx == 12 then
				lab.ForeColor = InactiveText
			else
				lab.OnClick = function(control)
					RestoreYears(self,lab)
					self.HeaderLabel.Text = lab.Text:gsub("\r\n"," - ")
					self.VisibleYear = tonumber(lab.Text:match("%d+"))
					Redraw(self)
				end
			end	
			x = x + dx
			dec = dec + 10
			idx = idx + 1
		end
		x = 5
		y = y + dy
	end	
end

local function CollapseDays(self)
	self.Monthes.Visible = true
	for _, lab in pairs(self.Monthes.Controls) do
		lab.Transparent = true
		lab.ForeColor = ForeColor
	end
	local idx = self.VisibleMonth
	local lab = self.Monthes["mon_"..idx]
	lab.Transparent = false
	lab.ForeColor = ActiveItemText
	CollapseControl(self.Ctrl,lab.X+lab.Width/2,lab.Y+lab.Height/2)
	self.Ctrl.Visible = false
	self.State = "Monthes"
end

local function CollapseMonthes(self)
	self.Years.Visible = true
	for _, lab in pairs(self.Years.Controls) do
		lab.Transparent = true
		lab.ForeColor = ForeColor
	end
	self.Years.year_1.ForeColor = InactiveText
	self.Years.year_12.ForeColor = InactiveText
	local idx = self.VisibleYear%10 + 2
	local lab = self.Years["year_"..idx]
	lab.Transparent = false
	lab.ForeColor = ActiveItemText
	CollapseControl(self.Monthes,lab.X+lab.Width/2,lab.Y+lab.Height/2)
	self.Monthes.Visible = false
	self.State = "Years"
end

local function CollapseYears(self)
	self.Decs.Visible = true
	for _, lab in pairs(self.Decs.Controls) do
		lab.Transparent = true
		lab.ForeColor = ForeColor
	end
	self.Decs.dec_1.ForeColor = InactiveText
	self.Decs.dec_12.ForeColor = InactiveText
	local dec = (self.VisibleYear - self.VisibleYear%100) - 10
	local idx = math.floor((self.VisibleYear%100)/10) + 2
	local lab = self.Decs["dec_"..idx]
	lab.Transparent = false
	lab.ForeColor = ActiveItemText
	CollapseControl(self.Years,lab.X+lab.Width/2,lab.Y+lab.Height/2)
	self.Years.Visible = false
	self.State = "Decs"
end

local function DayClick(self,control)
	if control.lab.Text == "" then return end
	for i = 1,6 do
		for j = 1,7 do
			local lbDay = control.Parent:FindControl("day_"..i.."_"..j)
			lbDay.Transparent = true
			lbDay.lab.ForeColor = ForeColor
			lbDay.lab.FontBold = false
		end
	end
	
	control.Transparent = false
	control.lab.FontBold = true
	control.lab.ForeColor = ActiveItemText
	self.Year = self.VisibleYear
	self.Month = self.VisibleMonth
	self.Day = tonumber(control.lab.Text)
	if type(self.OnDateSelect) == "function" then
		self:OnDateSelect(self.Day,self.Month,self.Year)
	end
end

local function SetDate(self,day,month,year)
	if type(day) == "string" then
		local date = IsValidDate(day)
		if date then
			day,month,year = date:match("(%d+)%.(%d+)%.(%d+)")
		end
	elseif type(day) == "table" then
		day,month,year = unpack(day)
	elseif not day then
		local date = DateTime.Now
		day,month,year = date.Day,date.Month,date.Year
	end
	local today = DateTime.Now
	self.Year = tonumber(year) or today.Year
	self.Month = tonumber(month) or today.Month
	self.Day = tonumber(day) or today.Day
	self.VisibleYear = self.Year
	self.VisibleMonth = self.Month
	Redraw(self)
end

local function CreateHeader(self)
	local btnWidth = 18
	local W = self.Site.Width
	
	-- панель заголовка
	local pnlHdr = Panel.new("pnlHdr","HEADER",0,0,W,btnWidth)
	self.Site:AddControl(pnlHdr)
	pnlHdr.Transparent = false
	pnlHdr.BackColor = Color.ActiveCaption
	self.Header = pnlHdr
	
	-- заголовок (месяц год)
	local hdr = Label.new("ym_hdr","",btnWidth,2,10,10)
	hdr.FontBold = true
	hdr.ForeColor = Color.ActiveCaptionText
	hdr = pnlHdr:AddControl(hdr)
	self.HeaderLabel = hdr
	SetHeaderText(self,MonthNames[self.VisibleMonth].." "..self.VisibleYear)
	pnlHdr.Height = hdr.Height + 4
	hdr.TextAlign = ContentAlignment.MiddleCenter
	hdr.OnClick = function(control)
		if self.State == "Days" then
			CollapseDays(self)
			SetHeaderText(self,self.VisibleYear)
		elseif self.State == "Monthes" then
			CollapseMonthes(self)
			local dec = self.VisibleYear - self.VisibleYear%10
			SetHeaderText(self,dec.." - "..(dec+9))
		elseif self.State == "Years" then
			CollapseYears(self)
			local dec = self.VisibleYear - self.VisibleYear%100
			SetHeaderText(self,dec.." - "..(dec+99))
		end
	end
	
	-- кнопки след/пред месяц
	local btnPrevMonth = Label.new("btnPrevMonth","<<",0,0,btnWidth,hdr.Height)
	btnPrevMonth = pnlHdr:AddControl(btnPrevMonth)
	btnPrevMonth.FontBold = true
	btnPrevMonth.ForeColor = Color.ActiveCaptionText
	btnPrevMonth.OnClick = function(control)
		if self.State == "Days" then
			PrevMonth(self)
		elseif self.State == "Years" then
			PrevYear(self)
		elseif self.State == "Decs" then
			PrevDec(self)
		end
	end
	
	local btnNextMonth = Label.new("btnNextMonth",">>",pnlHdr.Width - btnWidth,0,btnWidth,hdr.Height)
	btnNextMonth = pnlHdr:AddControl(btnNextMonth)
	btnNextMonth.FontBold = true
	btnNextMonth.ForeColor = Color.ActiveCaptionText
	btnNextMonth.OnClick = function(control)
		if self.State == "Days" then
			NextMonth(self)
		elseif self.State == "Years" then
			NextYear(self)
		elseif self.State == "Decs" then
			NextDec(self)
		end
	end
end

local function Prepare(self)
	CreateHeader(self)
	
	local pnl = Panel.new("body","",0,self.Header.Height,self.Site.Width,self.Site.Height-self.Header.Height)
	self.Site:AddControl(pnl)
	pnl.Transparent = true
	self.Body = pnl
	
	CreateDecades(self)
	CreateYears(self)
	CreateMonth(self)
	
	local ctrl = Panel.new("dates","",0,0,self.Body.Width,self.Body.Height)
	self.Body:AddControl(ctrl)
	ctrl.Transparent = false
	ctrl.BackColor = self.Site.BackColor
	self.Ctrl = ctrl

	local W = self.Ctrl.Width
	local H = self.Ctrl.Height


	-- строка сегодня
	local td = Label.new("today","Сегодня: "..os.date("%d.%m.%Y"),2,0,W,10)
	td = self.Ctrl:AddControl(td)
	td.FontBold = true
	td:AdjustMinSize()
	td.Y = H - td.Height - 4
	td.Width = W

	-- дни недели
	local daysY = 1
	local daysH = td.Y - daysY
	local daysX = 10
	local daysW = W - daysX - 10

	local wdNames = {"пн","вт","ср","чт","пт","сб","вс"}
	local rowH = math.floor(daysH / 7)
	local colW = math.min(math.floor(daysW/7),math.floor(rowH*1.6))
	daysW = colW*7
	daysX = W - daysW - 10
	for i=1,7 do
		local lbWd = Label.new("wd_"..i,wdNames[i],daysX + (i-1)*colW,daysY,colW,rowH)
		lbWd.FontBold = true
		lbWd.ForeColor = Color.DarkLightBlue
		lbWd.TextAlign = ContentAlignment.TopRight
		self.Ctrl:AddControl(lbWd)
	end
	
	-- числа
	for i = 1,6 do
		for j = 1,7 do
			local lbDay = Panel.new("day_"..i.."_"..j,"",daysX + (j-1)*colW,i*rowH+2,colW,rowH)
			self.Ctrl:AddControl(lbDay)
			lbDay.Transparent = true
			lbDay.BackColor = ActiveItem
			local lab = Label.new("lab","",5,0,lbDay.Width-10,lbDay.Height)
			lab.TextAlign = ContentAlignment.MiddleRight
			lbDay:AddControl(lab)
			lbDay.OnClick = function(control)
				DayClick(self,control)
			end
			lab.OnClick = function(control)
				DayClick(self,control.Parent)
			end
			
		end
	end	
	self.State = "Days"
end

local function new(ctrl,date)
	local obj = {}
	setmetatable(obj, {["__index"] = TMonthCalendar})
	date = date and IsValidDate(date) or os.date("%d.%m.%Y")

	obj.Day,obj.Month,obj.Year = date:match("(%d+)%.(%d+)%.(%d+)")
	
	obj.Day = tonumber(obj.Day)
	obj.Month = tonumber(obj.Month)
	obj.Year = tonumber(obj.Year)
	obj.VisibleMonth = obj.Month
	obj.VisibleYear = obj.Year
	obj.Site = ctrl
	obj.Tag = {}
	obj.Visible = ctrl.Visible
	Prepare(obj)
	Redraw(obj)
	
	return obj
end

TMonthCalendar = {
	Day = 1,
	Month = 1,
	Year = 1,
	new = new,
	Show = Show,
	Hide = Hide,
	SetDate = SetDate,
}

setmetatable(TMonthCalendar, { ["__call"] = function(self,...) return new(...) end } )

return TMonthCalendar
