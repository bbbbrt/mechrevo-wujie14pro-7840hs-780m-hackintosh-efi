DefinitionBlock ("", "SSDT", 2, "CORP", "XOSI", 0x00001000)
{
    Method (XOSI, 1, NotSerialized)
    {
        Store (Package ()
        {
            "Windows 2000",
            "Windows 2001",
            "Windows 2001 SP1",
            "Windows 2001.1",
            "Windows 2001 SP2",
            "Windows 2001.1 SP1",
            "Windows 2006",
            "Windows 2006 SP1",
            "Windows 2006.1",
            "Windows 2009",
            "Windows 2012",
            "Windows 2013",
            "Windows 2015"
        }, Local0)

        If (_OSI ("Darwin"))
        {
            Return (LNotEqual (Match (Local0, MEQ, Arg0, MTR, Zero, Zero), Ones))
        }
        Else
        {
            Return (_OSI (Arg0))
        }
    }
}
