Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead("d:\football\log\football_platform_plan.docx")
$entry = $zip.GetEntry("word/document.xml")
$stream = $entry.Open()
$reader = New-Object System.IO.StreamReader($stream)
$xmlStr = $reader.ReadToEnd()
$reader.Close()
$stream.Close()
$zip.Dispose()
$xml = [xml]$xmlStr
$ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
$ns.AddNamespace("w", "http://schemas.openxmlformats.org/wordprocessingml/2006/main")
$nodes = $xml.SelectNodes("//w:t", $ns)
$out = [System.Collections.Generic.List[string]]::new()
foreach ($node in $nodes) { $out.Add($node.InnerText) }
Set-Content -Path "d:\football\log\plan.txt" -Value $out -Encoding UTF8
