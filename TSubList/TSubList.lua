local RecUtils = require("RecUtils")
local TControls = require("TControls")

local TSubList = {	 }
--[[
	Элемент управления для работы со списком связанных записей на основе таблицы.
	UTF-8
]]

local function SaveRecord(form)
--[[
	Cохранение записи без вызова ValidateFormData
]]	

-- 	блокируем проверку записи перед сохранением	
	local validate = form.Module["Форма_ValidateFormData"]
	form.Module["Форма_ValidateFormData"] = function() return true end
--	сохраняем запись	
	form:SaveRecord()
-- 	восстанавливаем функцию проверки
	form.Module["Форма_ValidateFormData"] = validate
end

local function Load(self)
	self.Grid:SetEnableRedraw(false)
	self.ReadOnly = self.Grid.Form.Locked
	local rec = self.Grid.Form.Record
	self.Grid.NumberRows = 0
	local k = 0
	for i=1,#self.Bases do
		repeat
		local rs = rec:GetValue(self.BaseField.Number, self.Bases[i])
		if not rs then break end
		local dr = rs.Count
		self.Grid.NumberRows = self.Grid.NumberRows + dr
		local row = k
		for r in rs.Records do
			self.Grid:SetCellText(-2,row,r.SN)
			self.Grid:SetCellText(-1,row,self.Bases[i])
			self.Grid:SetCellText(0,row,RecUtils.GetRecInfo(r))
			self.Grid:SetCellTextColor(0,row,Color.Black)
			if self.ReadOnly then
				self.Grid:SetCellBackColor(0,row,Color.Control)
			else
				self.Grid:SetCellBackColor(0,row,Color.White)
			end
			row = row + 1
		end
		k = k + dr
		until true
	end
	self.ValuesCount = self.Grid.NumberRows
	if not self.ReadOnly then
		local n = self.Grid:AppendRow()
		if n >= 0 then
			self.Grid:SetCellText(0,n,"Новая запись")
			self.Grid:SetCellText(-1,n,"")
			self.Grid:SetCellText(-2,n,"*")
			self.Grid:SetCellTextColor(0,n,Color.Gray)
			self.Grid:SetCellBackColor(0,n,Color.White)
			self.Grid:RowBestFit(n)
		end	
	end	
	self.Grid:SetEnableRedraw(true)
end

local function UpdateRecord(self,rec)
	local grid = self.Grid
	for i=0,grid.NumberRows-1 do
		local code = grid:GetCellText(-1,i)
		local sn = grid:GetCellText(-2,i)
		if code == rec.Base.Code and sn == tostring(rec.SN) then
			grid:SetCellText(0,i,RecUtils.GetRecInfo(rec))
			self.Grid:SetCellText(-3,i,"+")
			return
		end
	end
	-- new record
	local row = grid:InsertRow(grid.NumberRows-1)
	grid:SetCellText(-2,row,rec.SN)
	grid:SetCellText(-1,row,rec.Base.Code)
	grid:SetCellText(0,row,RecUtils.GetRecInfo(rec))
	grid:SetCellTextColor(0,row,Color.Black)
	self.Grid:SetCellText(-3,row,"+")
end

local function Update(self,base)
	self.Grid:SetEnableRedraw(false)
	local bases = {}
	if type(base) == "table" then
		bases = base
	elseif type(base) == "string" then
		bases = {base}
	else	
		bases = self.Bases
	end
	local rec = self.Grid.Form.Record
	for i=1,#bases do
		repeat
		local rs = rec:GetValue(self.BaseField.Number, bases[i])
		if not rs then break end
		for r in rs.Records do
			self:UpdateRecord(r)
		end
		until true
	end
	for i=self.Grid.NumberRows-1,0,-1 do
		local sn = self.Grid:GetCellText(-2,i)
		local code = self.Grid:GetCellText(-1,i)
		local mark = self.Grid:GetCellText(-3,i)
		if table.getkey(bases,code) and sn ~="*" and mark == "" then
		--	delete row
			self.Grid:DeleteRow(i)
		else
			self.Grid:SetCellText(-3,i,"")
		end
	end
	self.Grid:SetEnableRedraw(true)
end

local function OpenSubForm(self,code,sn)
	local form = self.SubForms[code]
	if form then
		local args = {}
		if type(self.OnBeforeSubForm) == "function" then
			args = assert(self.OnBeforeSubForm)(self,code,sn)
		end
		args.sn = tonumber(sn) or 0
		args.MasterGrid = self
		local validate = self.Grid.Form.Module["Форма_ValidateFormData"]
		self.Grid.Form.Module["Форма_ValidateFormData"] = function() return true end
		self.Grid.Form:SaveRecord()
		self.Grid.Form:OpenSubForm(form,code,self.BaseField.Number,args)
		if type(self.OnAfterSubForm) == "function" then
			self:Update(code)
			assert(self.OnAfterSubForm)(self,code,sn,args)
		end
		self.Grid.Form:SaveRecord()
		self.Grid.Form.Module["Форма_ValidateFormData"] = validate
	end
end

local function ItemClick(self, row)
	if self.ReadOnly then return end
	local grid = self.Grid
	if row <  grid.NumberRows - 1 then
	--	open subrecord
		local code = grid:GetCellText(-1,row)
		local sn = grid:GetCellText(-2,row)
		self:OpenSubForm(code,sn)
	elseif #self.Bases >= 1 then
	-- create new subrecord
		local code = self.Bases[1]
		local t = render(self.Bases)
		if #self.Bases > 1 and type(self.OnBaseList) == "function" then
			code = assert(self.OnBaseList)(self)
		end
		if code then
			self:OpenSubForm(code,0)
		end	
	end
end

local function LinkToRecord(self, code,sn)
	local grid = self.Grid
	local form = grid.Form
	if self.ReadOnly then return end
	sn = tonumber(sn)
	if not sn or sn <= 0 then return end 
	if not table.getkey(self.Bases,code) then return end
	local bank = form.Record.Base.Bank
	local base = bank:GetBase(code)
	if not base then return end
	local rec = base:GetRecord(sn)
	if not rec then return end
	if bank.Input then
--[[
	TODO: Проверка на принадлежность записи текущему входному сообщению
]]	
	end
	if type(self.OnAddLink) == "function" then
		local ok = assert(self.OnAddLink)(self,code,sn)
		if not ok then return end
	end
	SaveRecord(form)
	local ok = form.Record.Base:AddLink(form.RecordNumber,self.BaseField.Number,code,sn,Base.NoLock,Base.NoLock)
	self:Update(code)
	SaveRecord(form)
end

local function BreakLink(self, row)
	if self.ReadOnly then return end
	local grid = self.Grid
	if row <  grid.NumberRows - 1 then
		local code = grid:GetCellText(-1,row)
		local sn = grid:GetCellText(-2,row)
		if type(self.OnBreakLink) == "function" then
			local ok = assert(self.OnBreakLink)(self,code,sn)
			if not ok then return end
		end
		local form = self.Grid.Form
		SaveRecord(form)
		local ok = form.Record.Base:DeleteLink(form.RecordNumber,self.BaseField.Number,code,sn,Base.NoLock,Base.NoLock)
		self:Update(code)
		SaveRecord(form)
	end
end

local function Render(self)
	return "<SubList>: "..self.BaseField.Base.Code..self.BaseField.Number
end

local function new(site,fld,forms)
	local obj = {}
	setmetatable(obj, { ["__index"] = TSubList, ["__render"] = Render, ["__tostring"] = Render })
	local grid
	if utf8.match(render(site),"Panel") then
		grid = TableControl("Grid",nil,0,0,site.Width,site.Height)
		site:AddControl(grid)
		TControls.CopyFont(site,grid)
		site.Resize = function()
			site.Grid.Width = site.Width
		end
	elseif utf8.match(render(site),"TableControl") then
		grid = site
	else
		return nil, "Bad site type"
	end
	grid.TextAlign = ContentAlignment.TopLeft
	grid.NumberCols = 1
	grid.NumberRows = 0
	grid.SideHdrCols = 3
	grid.SideHdrWidth = obj.CodeWidth
	grid:SetColWidth(-1,obj.CodeWidth)
	grid:SetColWidth(-3,0)
	grid:SetColWidth(-2,0)
	grid:SetRowHeight(-1,0)
	grid.UniformRowHeight = true
	grid:SetColWidth(0,grid.Width - obj.CodeWidth - 23)
	grid.EditMode = TableControl.EMNoEdit
	obj.Grid = grid
	obj.BaseField = fld
	obj.ReadOnly = grid.Form.Locked
	obj.Bases = {}
	local t = obj.BaseField.LinkedBases
	for i=1,#t do
		if forms[t[i].Base.Code] then
			table.insert(obj.Bases,t[i].Base.Code)
		end	
	end
	table.sort(obj.Bases, function(a,b) return GetBank():GetBase(a).Number < GetBank():GetBase(b).Number end)
	obj.SubForms = forms
	grid.Resize = function()
		grid:SetColWidth(0,grid.Width - obj.CodeWidth - 23)
	end
	
	obj.GridCellDoubleClick = grid.CellDoubleClick
	grid.CellDoubleClick = function(event)
		if type(obj.GridCellDoubleClick) == "function" then
			assert(obj.GridCellDoubleClick)(event)
		end
		ItemClick(obj,event.RowIndex)
	end
	
	obj.GridKeyDown = grid.KeyDown
	grid.KeyDown = function(event)
		if type(grid.Form.Module["Форма_KeyPreview"]) == "function" then
			grid.Form.Module["Форма_KeyPreview"](event)
			if event.Handled then
				return
			end
		end
		
		if type(obj.GridKeyDown) == "function" then
			assert(obj.GridKeyDown)(event)
		end
		local key = event.Key
		local char = event.Char
		if type(obj.KeyDown) == "function" then
			assert(obj.KeyDown)(event)
		end
		if event.Key == Keys.Return then
			ItemClick(obj,grid.CurrentRow)
		elseif event.Key == Keys.Delete then
			BreakLink(obj,grid.CurrentRow)
		end	
	end
	
	obj.GridKeyTyped = grid.KeyTyped
	grid.KeyTyped = function(event)
		if type(obj.GridKeyTyped) == "function" then
			assert(obj.GridKeyTyped)(event)
		end
		local key = event.Key
		local char = event.Char
		if utf8.match(event.Char,"[A-Za-zА-Яа-я]") then
			event.Control:StartEdit(0,nil,utf8.byte(event.Char))
		end	
	end

	obj.GridEditStart = grid.EditStart
	grid.EditStart = function(event)
		if type(obj.GridEditStart) == "function" then
			assert(obj.GridEditStart)(event)
		end
		local row = event.RowIndex
		local col = event.ColumnIndex
		local ch = event.Control:GetCellText(-2,row)
		local kode = event.CharCode
		if obj.ReadOnly or ch ~= "*" or event.CharCode == 0x9 then
			event.AllowAction = false
		end
	end
	
	obj.GridEditContinue = grid.EditContinue
	grid.EditContinue = function(event)
		if type(obj.GridEditContinue) == "function" then
			assert(obj.GridEditContinue)(event)
		end
		event.AllowAction = false
	end
	
	obj.GridEditFinish = grid.EditFinish
	grid.EditFinish = function(event)
		if type(obj.GridEditFinish) == "function" then
			assert(obj.GridEditFinish)(event)
		end
		local txt = utf8.upper(event.String):trim()
		local row = event.RowIndex
		local col = event.ColumnIndex
		event.Control.EditMode = TableControl.EMNoEdit
		if forms[txt] then
		-- open new sub record
			open_sub = function() 
				timer:Stop() 
				timer:delete()
				grid:SetCellText(0,row,"Новая запись") 
				obj:OpenSubForm(txt,0)
			end
			timer = obj.Grid.Form:CreateTimer(open_sub,10,true)
		elseif utf8.match(txt,"%u%u%s*%d+") and forms[utf8.sub(txt,1,2)] then
			local code, sn = utf8.match(txt,"(%u%u)%s*(%d+)")
			link_sub = function() 
				timer:Stop() 
				timer:delete()
				grid:SetCellText(0,row,"Новая запись") 
				obj:LinkToRecord(code,tonumber(sn))
			end
			timer = obj.Grid.Form:CreateTimer(link_sub,10,true)
			
		else
		-- cancel	
			undo_edit = function() 
				timer:Stop() 
				timer:delete()
				grid:SetCellText(0,row,"Новая запись") 
			end
			timer = obj.Grid.Form:CreateTimer(undo_edit,10,true)
		end
	end
	
	obj.GridFocusEnter = grid.FocusEnter
	grid.FocusEnter = function( control )
		if type(obj.GridFocusEnter) == "function" then
			assert(obj.GridFocusEnter)(control)
		end
		grid.CellHighlightMode = TableControl.HLFocusRect + TableControl.HLColor  
	end
	
	obj.GridFocusLeave = grid.FocusLeave
	grid.FocusLeave = function( control )
		if type(obj.GridFocusLeave) == "function" then
			assert(obj.GridFocusLeave)(control)
		end
		grid.CellHighlightMode = TableControl.HLFocusRect
	end
	
	return obj
end

TSubList = {
	CodeWidth = 30,
	SaveRecord = SaveRecord,
	Load = Load,
	UpdateRecord = UpdateRecord,
	Update = Update,
	OpenSubForm = OpenSubForm,
	ItemClick = ItemClick,
	LinkToRecord = LinkToRecord,
	BreakLink = BreakLink,
	new = new,
}

setmetatable(TSubList, { ["__call"] = function(self,...) return new(...) end })
return TSubList
