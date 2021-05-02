local TYearCalendar = {}

DefCellWidth = 20
DefCellHeight = 16
DefCheckedBackColor = Color.new(100,255,206)

local function CreateGrid(site)
	local grid = TableControl("grid","",0,0,site.Width,site.Height)
	site:AddControl(grid)
	grid.FullGridLines = false
	grid.NumberCols = 23
	grid.NumberRows = 36
	grid:SetDefSideHdrAreaColor(Color.White)
	for i=1,grid.NumberCols do
		grid:SetColWidth(i-1,DefCellWidth)
	end
	for i=1,grid.NumberRows do
		grid:SetRowHeight(i-1,DefCellHeight)
	end
	grid.SideHdrWidth = 22
	grid.TopHdrHeight = 0
--	
	grid:JoinCells(-1,0,-1,8)
	grid:JoinCells(-1,9,-1,17)
	grid:JoinCells(-1,18,-1,26)
	grid:JoinCells(-1,27,-1,35)
	grid:SetCellBackColor(-1,0,Color.White)
	grid:SetCellBackColor(-1,9,Color.White)
	grid:SetCellBackColor(-1,18,Color.White)
	grid:SetCellBackColor(-1,27,Color.White)
	grid:SetCellBorder(-1,0,TableControl.BrdSimple,TableControl.BrdTop,1,Color.Black)
	grid:SetCellBorder(-1,9,TableControl.BrdSimple,TableControl.BrdTop,1,Color.Black)
	grid:SetCellBorder(-1,18,TableControl.BrdSimple,TableControl.BrdTop,1,Color.Black)
	grid:SetCellBorder(-1,27,TableControl.BrdSimple,TableControl.BrdTop,1,Color.Black)
	grid:SetCellText(-1,0,"I")
	grid:SetCellText(-1,9,"II")
	grid:SetCellText(-1,18,"III")
	grid:SetCellText(-1,27,"IV")
	for i=1,grid.NumberRows do
		grid:SetCellBorder(0,i,TableControl.BrdSimple,TableControl.BrdLeft,1,Color.Silver)
	end
	
--	
	grid.Height = grid.NumberRows*DefCellHeight+2
	grid.Width = grid.SideHdrWidth+grid.NumberCols*DefCellWidth+2
	site.Width = grid.Width
	site.Height = grid.Height
	return grid
end

local function DrawCell(self,col,row,mode)
	local color = self.CheckedBackColor or DefCheckedBackColor
	local grid = self.Grid
	if mode then
		grid:SetCellBackColor(col,row,color)
		local brd = Color.new(color.R*0.6,color.G*0.6,color.B*0.6)
		grid:SetCellBorder(col,row,TableControl.BrdSimple,TableControl.BrdAll,1,brd)
	else
		grid:SetCellBackColor(col,row,Color.White)
		if col > 0 then
			grid:SetCellBorder(col,row,TableControl.BrdNone)
		else
			grid:SetCellBorder(col,row,TableControl.BrdSimple,TableControl.BrdLeft,1,Color.Silver)
		end
	end	
end

local function FillMonth(self,year,month,Y,X)
	local grid = self.Grid
	WeekDays = {"пн","вт","ср","чт","пт","сб","вс"}
	NumOfDays = {31,28,31,30,31,30,31,31,30,31,30,31}
	local row = Y
	local col = X
	
	-- название месяца
	local start = DateTime(("01.%02d.%04d 00:00"):format(month,year))
	grid:JoinCells(col,row,col+6,row)
	grid:SetCellText(col,row,start:ToString("%B"))
	grid:SetCellBackColor(col,row,Color.new(220,220,255))
	grid:SetCellBorder (col,row,TableControl.BrdSimple,TableControl.BrdTop,1,Color.Black)
	grid:SetCellBorder (col+7,row,TableControl.BrdSimple,TableControl.BrdTop,1,Color.Black)
	
	-- дни недели
	for i=1,7 do
		grid:SetCellText(col+i-1,row+1,WeekDays[i])
		if i < 6 then
			grid:SetCellTextColor(col+i-1,row+1,Color(150,150,150))
		else
			grid:SetCellTextColor(col+i-1,row+1,Color(250,150,150))
		end		
	end
	
	-- даты
	local wd = (tonumber(start:ToString("%w")) + 6) % 7
	for i=1,6 do
		for j=1,7 do
			local day = (i-1)*7 + (j-1) - wd
			if day < 0 or day > NumOfDays[month]-1 then
				grid:SetCellText(col+j-1,row+1+i,"")
			else
				grid:SetCellText(col+j-1,row+1+i,day+1)
				if j > 5 then
					grid:SetCellTextColor(col+j-1,row+1+i,Color(250,100,100))
				end		
			end
			DrawCell(self,col+j-1,row+1+i,false)			
		end
	end	
end

local function FillGrid(self)
	local year = self.Year
	local grid = self.Grid
	grid:SetEnableRedraw(false)
	for i=1,4 do
		for j=1,3 do
			FillMonth(self,year,i*3+j-3,(i-1)*9,(j-1)*8)
		end
	end	
	grid:SetEnableRedraw(true)
end

local function grid_CellDoubleClick(self, event )
	local dt = event.Control:GetCellText(event.ColumnIndex,event.RowIndex)
	if tonumber(dt) then
		local month = math.floor(event.RowIndex/9)*3+math.floor(event.ColumnIndex/8)+1
		local date = ("%02d.%02d"):format(tonumber(dt),month)
		if type(self.OnDateDblClick) == "function" then
			assert(self.OnDateDblClick)(self,tonumber(dt),month)
		end
	end
end

local function grid_CellClick(self, event )
	local dt = event.Control:GetCellText(event.ColumnIndex,event.RowIndex)
	if tonumber(dt) then
		local month = math.floor(event.RowIndex/9)*3+math.floor(event.ColumnIndex/8)+1
		local date = ("%02d.%02d"):format(tonumber(dt),month)
		if type(self.OnDateClick) == "function" then
			assert(self.OnDateClick)(self,tonumber(dt),month)
		end
	end
end


local function CreateInstance(self,class)
	local obj = {}
	local m = {
		["__index"] = function(t,idx)
			-- in instance
			local val = rawget(t,idx)
			if val and type(val) == "function" then 
				return function(obj,...)
					return val(self,...)
				end
			elseif val then
				return val 
			end
			-- in self
			local val = self[idx]
			if val and type(val) == "function" then 
				return function(obj,...)
					return val(self,...)
				end
			elseif val then
				return val 
			end
			-- in class properties
			local properties = class.Properties
			if properties and properties[idx] and type(properties[idx].read) == "function" then
				return properties[idx].read(self,idx)
			elseif type(self[idx]) == "function" then
				return function(obj,...)
					return self[idx](self,...)
				end
			else
				return self[idx]
			end	
		end,
		["__newindex"] = function(t,idx,val)
			local properties = class.Properties
			if properties and properties[idx] and type(properties[idx].write) == "function" then
				properties[idx].write(self,idx,val)
			else
				self[idx] = val
			end	
		end,
		["__render"] = function(t) 
			return render(self) 
		end,
		["__call"] = function(f,...)
			self[f](self)
		end,
		["__tostring"] = function(t) 
			return tostring(self) 
		end,
		["__metatable"] = {["__render"] = function(t) return render(self) end}
	}
	
	setmetatable(obj, m)
	return obj
end

local function new(site,year)
	local obj = {}
	setmetatable(obj,{["__index"] = TYearCalendar})
	obj.Site = site
	obj.Year = year or DateTime.Now.Year
	obj.CheckedBackColor = DefCheckedBackColor
	obj.Grid = CreateGrid(site)
	obj.Grid.CellDoubleClick = function(event) grid_CellDoubleClick(obj,event) end
	obj.Grid.CellClick = function(event) grid_CellClick(obj,event) end
	FillGrid(obj)
	obj.CheckedDates = {}
	return CreateInstance(obj,TYearCalendar)
end

local function IsDateChecked(self,day,month,year)
	if not year then
		year = self.Year
	else
		year = tonumber(year)
	end
	
	if not day or not tonumber(day) then return end
	if not month or not tonumber(month) then return end
	if not year or not tonumber(year) then return end
	local dates = self.CheckedDates
	for idx, date in ipairs(dates) do
		if date.Day == tonumber(day) and date.Month == tonumber(month) and date.Year == year then
			return true,idx
		end
	end
	return false
end

local function GetPosition(self,day,month)
	local i,j = math.floor((month-1)/3),((month-1)%3)
	local base_row = i*9
	local base_col = j*8
	local start = DateTime(("01.%02d.%04d 00:00"):format(month,self.Year))
	local wd = (tonumber(start:ToString("%w")) + 6) % 7
	local row = base_row + 2 + math.floor((day + wd - 1)/7)
	local col = base_col + (day + wd - 1) % 7
	return row,col
end

local function SetDateChecked(self,day,month,year,mode)
	if type(mode) == "nil" then
		mode = true
	end
	if type(year) == "nil" then
		year = self.Year
	end
	local grid = self.Grid
	local row,col = GetPosition(self,day,month)
	if not row then return end
	local is_checked,key = self:IsDateChecked(day,month,year)
	if mode and not is_checked then
		table.insert(self.CheckedDates,{Day = day, Month = month, Year = year })
	elseif not mode and is_checked then
		table.remove(self.CheckedDates,key)
	end
	if year == self.Year then
		DrawCell(self,col,row,mode)
	end	
end

local function CheckAllSelected(self)
	self.Grid:SetEnableRedraw(false)
	local dates = self.CheckedDates
	for _, item in pairs(dates) do
		if item.Year == self.Year then
			local row, col = GetPosition(self,item.Day,item.Month)
			if row and col then
				DrawCell(self,col,row,true)
			end
		end	
	end
	self.Grid:SetEnableRedraw(true)
end

local function GetChecked(self,as_text)
	Names = {"января","февраля","марта","апреля","мая","июня","июля","августа","сентября","октября","ноября","декабря"}
	local dates = self.CheckedDates
	table.sort(dates,function(a,b) 
		return a.Year < b.Year or 
			(a.Year == b.Year and (a.Month < b.Month or 
					a.Month == b.Month and a.Day < b.Day)
			) 
	end)
		
	local list = {}
	for _, item in pairs(dates) do
		if as_text then
			table.insert(list,("%d %s %d г."):format(item.Day,Names[item.Month],item.Year))
		else
			table.insert(list,("%02d.%02d.%4d"):format(item.Day,item.Month,item.Year))
		end		
	end
	return list
end

----------------------------------------------------------------------------------------------
-- Get/Set property functions
----------------------------------------------------------------------------------------------
local function set_Year(self,idx,val)
	val = tonumber(val)
	if val and val >= 1900 and val <= 3000 then 
		self.Year = val
		FillGrid(self)
		CheckAllSelected(self)
	end	
end

local function set_Font(self,idx,val)
	local t = {"FontName","FontBold","FontItalic","FontUnderline","FontSize","FontWeight"}
	for _,prop in pairs(t) do
		self.Grid[prop] = val[prop]
	end	
end

local function set_CheckedBackColor(self,idx,val)
	self.CheckedBackColor = val
	CheckAllSelected(self)
end

local function get_CheckedBackColor(self,idx)
	return self.CheckedBackColor
end

local function set_SomeProperty(self,idx,val)
end

----------------------------------------------------------------------------------------------
-- Get/Set property functions
----------------------------------------------------------------------------------------------

local __get_site = function(t,idx) return self.Site[idx] end
local __set_site = function(t,idx, val) self.Site[idx] = val end
local __get_grid = function(t,idx) return self.Grid[idx] end
local __set_grid = function(t,idx,val) self.Grid[idx] = val end
local __no = function() end
local __private = {read = __no, write = __no }

TYearCalendar = {
	new = new,
	IsDateChecked = IsDateChecked,
	SetDateChecked = SetDateChecked,
	CheckAllSelected = CheckAllSelected,
	GetChecked = GetChecked,
	Properties = {
		-- Свойства
		Name = { read = __get_site, write = __no },
		X = { read = __get_site, write = __set_site },
		Y = { read = __get_site, write = __set_site },
		Width = { read = __get_site, write = __set_site },
		Height = { read = __get_site, write = __set_site },
		Visible = { read = __get_site, write = __set_site },
		Transparent = nil,
		Enabled = { read = __get_site, write = __set_site },
		TopForm = { read = __get_site, write = __no },
		Valid = { read = __get_site, write = __no },
		Form = { read = __get_site, write = __no },
		Parent = { read = __get_site, write = __no },
		Controls = nil,
		Focused = { read = __get_grid, write = __set_grid },
		Text = nil,
		ForeColor = nil,
		BackColor = nil,
		Font = { read = __get_grid, write = set_Font },
		FontName = { read = __get_grid, write = __set_grid },
		FontBold = { read = __get_grid, write = __set_grid },
		FontItalic = { read = __get_grid, write = __set_grid },
		FontSize = { read = __get_grid, write = __set_grid },
		FontUnderline = { read = __get_grid, write = __set_grid },
		FontWeight = { read = __get_grid, write = __set_grid },
		Cursor = { read = __get_site, write = __set_grid },
		ToolTip = { read = __get_site, write = __no },
		TabIndex = { read = __get_site, write = __set_site },
		TabStop = { read = __get_site, write = __set_site },
		
		Year = { write = set_Year},
		-- Методы
		new = nil,
		DeleteControl = nil,
		AddControl = nil,
		FindControl = nil,
		SelectNextControl = nil,
		Redraw = {},
		EnsureVisible = {},
		AdjustMinSize = {  },
		Equals = { read = __no, write = __no },
		
		-- События
		Click = nil,
		DoubleClick = nil,
		KeyDown = nil,
		KeyUp = nil,
		KeyTyped = nil,
		FocusEnter = nil,
		FocusLeave = nil,
		Move = nil,
		Resize = nil,

		CheckedBackColor	= {read = get_CheckedBackColor,			write = set_CheckedBackColor},


		Grid 				= __private,
		Site 				= __private,
		CheckedDates = {write = __no},
		SetFocused = {},
	}
}

setmetatable(TYearCalendar, { ["__call"] = function(self,...) return new(...) end } )

return TYearCalendar
