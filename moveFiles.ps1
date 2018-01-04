

param(
[string]$sorPath="C:\Work\dumps", #"c:\work\processMonitor"
[string]$desPath="C:\Work\dumps2",
[int]$num=2
)



function retrieve{
param(
[string]$sorPath, 
[string]$desPath,
[int]$num

)
    
    $folders=Get-ChildItem $sorPath -Recurse | ?{ $_.PSIsContainer } | ForEach{ $_.fullname}
    $res=$num
    foreach($folder in $folders){

        $foldername=$folder.TrimStart($sorpath)
        if ($foldername){
            $desPath1=$desPath + "\"+ $foldername
        }
        else
        {
           $desPath1=$desPath
        }
        if(!(test-path $desPath1)){
           New-Item $desPath1 -type directory
        }
        $files=(Get-ChildItem $folder | ?{ ! $_.PSIsContainer})
        $count=$files.length

        if (($count -gt $res) -or ($count -eq $res)){

           for($i=0;$i -lt $res;$i++){
              Move-Item -Path $files[$i] -Destination $desPath1
           }

           if(!(Get-ChildItem $folder))
            {
               Remove-Item -Path $folder
            }
           break
        }
        if($count -lt $res ){
            
            foreach ($file in $files){
            Move-Item -Path $file -Destination $desPath1
            }
            $res=$res-$count

        }
        
       
    }#end for folder


}

retrieve -sorPath $sorPath -desPath $desPath -num $num


function count {
param(
[string]$sorPath="C:\Work\dumps", #"c:\work\processMonitor"
[string]$desPath="C:\Work\dumps2"
)

$count=0
$count=(Get-ChildItem $sorPath -recurse | Measure-Object -property length).count

Write-host "In $sorPath, the number of files is count "
}

<#
Copy-Item -Path $sorPath -Destination $desPath –Recurse

Get-Childitem $sorPath | Select-Object -First $maxItems | Copy-Item $destinationFolder

get-childitem -path c:\work -recurse

 Get-ChildItem $sorPath -recurse | Measure-Object -property length

 Get-ChildItem $sorPath -Recurse | ?{ $_.PSIsContainer }
 #>
