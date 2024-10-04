MEMORY
	{
	ram	: ORIGIN = 0X00000000, LENGTH = 0X00001000
	}

SECTIONS
{
	.text :
	{
	*(.text)
	} > ram

	.data :
	{
	*(.data)
	} > ram

	.bss :
	{
	*(.bss)
	} > ram
}

ENTRY(_start)