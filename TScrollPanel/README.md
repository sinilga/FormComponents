# TScrollPanel

Панель с возможностью прокрутки содержимого в горизонтальном или вертикальном направлении.

![форма](demo.png)

## Свойства 
*number* **ButtonSize** -   
размер кнопок прокрутки в пикселах
	
*number* **ScrollStep** -   
шаг прокрутки
  
## Методы  
**new**(*Panel* site, *string* dir, *PictureButton* btn1, *PictureButton* btn2) -  
коструктор  
  - *Panel* site - панель для размещения элемента   
  - *string* dir - направление прокрутки: "H" - горизонтальная, "V" - вертикальная  
  - *PictureButton* btn1 - кнопка прокрутки влево/вверх  
  - *PictureButton* btn2 - кнопка прокрутки вправо/вниз  
  
**AddControl**(*Control* ctrl) -  
добавить элемент на панель прокрутки

**ScrollBack**(*TScrollPanel* control) - 
прокрутить содержимое влево/вверх

**ScrollForwar**(*TScrollPanel* control) -  
прокрутить содержимое вправо/вниз

**ScrollStart**(*TScrollPanel* control) -  
прокрутить содержимое в крайнее левое/верхнее положение 

**ScrollEnd**(*TScrollPanel* control) -  
прокрутить содержимое в крайнее правое/нижнее положение 

**Clear**(*TScrollPanel* control) -  
удалить все элементы с панели

*table* **GetVisibleArea**(*TScrollPanel* control) -  
возвращает границы видимой области прокручиваемого содержимого.  
Возвращаемое значение - таблица с полями:  
*number* Left - левая граница видимой области;   
*number* Top - верхняя граница видимой области;  
*number* Right - правая граница видимой области;  
*number* Bottom - нижняя граница видимой области;  
  
**SetButtonSize**(*TScrollPanel* control,*number* size) -  
установить ширину/высоту кнопок прокрутки

## События ##
**OnScroll**(*TScrollPanel* control) -  
событие происходит при прокрутке содержимого 

## Пример использования
```lua
local TScrollPanel = require "TScrollPanel"  

Scroller = TScrollPanel(Me.panel1,"H",Me.button1,Me.button2)
local strings = {
	"Длинная строка текста.",
	"Еще одна длинная строка.",
	"Третья длинная строка текста.",
}
local x = 10
for i=1,#strings do
	local lab = Label.new("str"..i,strings[i],x,0)
	lab:AdjustMinSize()
	Scroller:AddControl(lab)
	x = x + lab.Width + 50
end	

```
### См. также ###
- [Форма ввода для банка Primer1](https://github.com/sinilga/ScrollPanel/blob/master/Demo%20FormsCopy.cfc). 
