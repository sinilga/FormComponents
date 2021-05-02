local FormAlign = require "TFormAlign"
local ScrollPanel = require "TScrollPanel"

function Форма_Open( form )
	fa = FormAlign(Me)
	fa:SetRules(Me.picture1,fa.alTop)
	fa:SetRules(Me.panel1,fa.alTop)
	return true;
end

function Форма_Load( form )
	foto_panel = ScrollPanel(Me.panel1,"H")
	
	__LOAD__ = true
	fill()
end

function Форма_AfterRecordChange( form )
	fill()
end

function Форма_AfterInsertRecord( form, mode )
	fill()
end

function fill()
	if not __LOAD__ then return end
	foto_panel:Clear()
	local n = Me.Record:GetValuesCount(1)
	local w = 50
	for i=1,n do
		local foto = Me.Record:GetValue(1,i)
		local pic = PictureBox.new("foto"..i,"",0,5,w,w)
		pic.SizeMode = PictureBox.PictureStretch
		pic:SetPicture(foto,true)
		pic.X = 5+(i-1)*(w+5)
		foto_panel:AddControl(pic)
		pic.OnClick = function()
			Me.picture1:SetPicture(foto,true)
		end
	end	
	if n > 0 then
		Me.picture1:SetPicture(Me.Record:GetValue(1,1),true)
	end	
end
