$result = get-date


$date = '20041204' #the input string
$format = 'YYYYMMDD' #the desired format, hh HH mm ss dd yyyy
[datetime]::TryParseexact(
    $date, 
    $format,
    [system.Globalization.DateTimeFormatInfo]::InvariantInfo, #info independent on the current system settings
    [system.Globalization.DateTimeStyles]::None, <#the format must be matched exactly, no whitespace or anything
        more info here: http://msdn.microsoft.com/cs-cz/library/ms131044.aspx #>
    [ref]$result #save the result here, if the operation fail the result is invalid
)
