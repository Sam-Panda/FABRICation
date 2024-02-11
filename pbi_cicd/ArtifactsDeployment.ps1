# read config.json file
$config = Get-Content -Path "pbi_cicd\scripts\config.json" | ConvertFrom-Json
$cred = Get-Content -Path "pbi_cicd\scripts\cred.json" | ConvertFrom-Json

$CLIENT_ID=$config.CLIENT_ID
$CLIENT_SECRET=$config.CLIENT_SECRET
$TENANT_ID=$config.TENANT_ID

# Parameters - fill these in before running the script!
# =====================================================

$pipelineDisplayName=$config.deployment_pipeline.pipelineDisplayName     # The display name of the new pipeline
$pipelineDescritionName=$config.deployment_pipeline.pipelineDescritionName    # The description of the new pipeline
$dev_workspaceName=$config.deployment_pipeline.dev_stage.workspaceName   # The name of an exisiting workspace which will be assigned to the Dev stage in the new pipeline
$test_workspaceName=$config.deployment_pipeline.test_stage.workspaceName   # The name of an exisiting workspace which will be assigned to the Test stage in the new pipeline
$prod_workspaceName=$config.deployment_pipeline.prod_stage.workspaceName   # The name of an exisiting workspace which will be assigned to the Prod stage in the new pipeline
$adminusersupn="sam@biatipdfmsitscus.onmicrosoft.com" 

$dataset_to_be_moved_from_dev_to_test = $config.deployment_pipeline.dev_to_test_artifacts_to_move.datasets
$reports_to_be_moved_from_dev_to_test = $config.deployment_pipeline.dev_to_test_artifacts_to_move.reports
$dashboards_to_be_moved_from_dev_to_test = $config.deployment_pipeline.dev_to_test_artifacts_to_move.dashboards

$dataset_to_be_moved_from_test_to_prod = $config.deployment_pipeline.test_to_prod_artifacts_to_move.datasets
$reports_to_be_moved_from_test_to_prod = $config.deployment_pipeline.test_to_prod_artifacts_to_move.reports
$dashboards_to_be_moved_from_test_to_prod = $config.deployment_pipeline.test_to_prod_artifacts_to_move.dashboards

function Install-PBIModules {
    if (Get-Module -Name MicrosoftPowerBIMgmt -ListAvailable) 
    {
        Import-Module MicrosoftPowerBIMgmt -ErrorAction SilentlyContinue
    }
    else {
        Install-Module MicrosoftPowerBIMgmt -Repository PSGallery  -AllowClobber -Force -SkipPublisherCheck -Scope CurrentUser
        Import-Module MicrosoftPowerBIMgmt -ErrorAction SilentlyContinue
    }

}

function Assign-PBIDeploymentUser(
    [Parameter(Mandatory=$true)][string]$adminuserupn,
    [Parameter(Mandatory=$true)][string]$pipelineName,
    [Parameter(Mandatory=$true)][string]$accessRight,
    [Parameter(Mandatory=$true)][string]$principalType

)
{
    try {
        # Get the pipeline according to pipelineName
        $pipelines=Invoke-PowerBIRestMethod -Url "pipelines" -Method Get | ConvertFrom-Json     
        
        $pipeline=$pipelines.Value | Where-Object displayName -eq $pipelineName
        if(!$pipeline) {
            Write-Host "A pipeline with the requested name was not found"
            return
        }
        $updateAccessUrl="pipelines/{0}/users" -f $pipeline.Id
        $body=@{
            identifier=$adminuserupn
            accessRight=$accessRight
            principalType=$principalType
        } | ConvertTo-Json
        Write-Host "Assigning user $adminuserupn to pipeline $pipelineID with access right $accessRight and principal type $principalType"
        Write-Host "Rest URL: $updateAccessUrl"
        Write-Host "Body: $body"
        Invoke-PowerBIRestMethod -Url $updateAccessUrl -Method Post -Body $body -Verbose
    } catch {
        $errmsg=Resolve-PowerBIError -Last
        $errmsg.Message
    }
}

function Create-Pipeline(
    [Parameter(Mandatory=$true)][string]$pipelineDisplayName,
    [Parameter(Mandatory=$true)][string]$pipelineDescription
)
    {
    try {
            $pipelines=Invoke-PowerBIRestMethod -Url "pipelines" -Method Get | ConvertFrom-Json
            $pipeline=$pipelines.Value | Where-Object displayName -eq $pipelineDisplayName
            Write-Host "Pipeline: $pipeline"
            if(!$pipeline) {
                Write-Host "A pipeline with the requested name was not found, lets create the new pipleine"
                # Create a new deployment pipeline
                    $createPipelineBody=@{ 
                        displayName=$pipelineDisplayName
                        description=$pipelineDescription
                    } | ConvertTo-Json

                $newPipeline=Invoke-PowerBIRestMethod -Url "pipelines"  -Method Post -Body $createPipelineBody | ConvertFrom-Json
                Write-Host "Created new pipeline with ID $($newPipeline.Id)"
                $pipelineID=$newPipeline.Id
            }
            else {
                Write-Host "Skipping creation of pipeline, as it already exists"
                $pipelineID=$pipeline.Id
            }
            return $pipelineID
    } 
    catch {
        $errmsg=Resolve-PowerBIError -Last
        $errmsg.Message
    }
}

function CheckIfWorkspaceHasAPipleine(
    [Parameter(Mandatory=$true)][string]$workspaceName
)
{
    $pipelines=Invoke-PowerBIRestMethod -Url "pipelines" -Method Get | ConvertFrom-Json
    $pipelines=$pipelines.Value 
    foreach($pipeline in $pipelines) {
        $getStateURL="pipelines/{0}/stages" -f $pipeline.id
        Write-Host "Getting stages for pipeline $($pipeline.displayName)"
        $stagedetails=Invoke-PowerBIRestMethod -Url $getStateURL -Method GET | ConvertFrom-Json
        $current_stage_details=$stagedetails.value | Where-Object workspaceName -eq $workspaceName
        if($current_stage_details)
        {
            Write-Host "Workspace $($workspace.Name) already exists in pipeline $($pipeline.displayName)"
            return $current_stage_details
        }
    }
}
function Assign-workspace-to-pipline(
    [Parameter(Mandatory=$true)][string]$workspaceName,
    [Parameter(Mandatory=$true)][string]$pipelineID,
    [Parameter(Mandatory=$true)][string]$stageOrder 
)
{
    # Get the workspace according to workspaceName
    $workspace=Get-PowerBIWorkspace -Filter "name eq '$workspaceName'"
    if(!$workspace) {
        Write-Host "A workspace with the requested {0} name was not found" -f $workspaceName
        return
    }
    if(!(CheckIfWorkspaceHasAPipleine -workspaceName $workspaceName)){
        $updateStageUrl="pipelines/{0}/stages/{1}/assignWorkspace" -f $pipelineID, $stageOrder
        $assignWorkspaceBody=@{ 
            workspaceId=$workspace.Id
        } | ConvertTo-Json 
        try {
            Write-Host "Adding workspace $($workspace.Name) to stage $stageOrder of pipeline $pipelineID"
            Invoke-PowerBIRestMethod -Url $updateStageUrl -Method Post -Body $assignWorkspaceBody -Verbose
        } catch {
            $errmsg=Resolve-PowerBIError -Last
            $errmsg.Message
        }
    }

}

function Deploy-PBIArtifacts(
    [Parameter(Mandatory=$true)][string]$stageOrder,
    [Parameter(Mandatory=$true)][string]$pipelineID,
    [Parameter(Mandatory=$false)][array]$stagedReports,
    [Parameter(Mandatory=$false)][array]$stagedDatasets,
    [Parameter(Mandatory=$false)][array]$stagedDashboards
    
 ) {
    

    $artifactsUrl = "pipelines/{0}/stages/{1}/artifacts" -f $pipelineID,$stageOrder
    $artifacts = Invoke-PowerBIRestMethod -Url $artifactsUrl  -Method Get | ConvertFrom-Json
    $reports_to_be_moved=New-Object System.Collections.ArrayList
    foreach($r in $stagedReports){
        $report=$artifacts.reports | Where-Object {$_.artifactDisplayName -eq $r}
        if ($report){
            $_reportjson = @{sourceId = $report.artifactId}
            $reports_to_be_moved.Add($_reportjson)
        }
        
    }

    $datasets_to_be_moved=New-Object System.Collections.ArrayList
    foreach($d in $stagedDatasets){
        $dataset=$artifacts.datasets | Where-Object {$_.artifactDisplayName -eq $d}
        if($dataset){
            $_datasetjson = @{sourceId = $dataset.artifactId}
            $datasets_to_be_moved.Add($_datasetjson)
        }
       
    }
    $dashboard_to_be_moved=New-Object System.Collections.ArrayList
    foreach($d in $stagedDashboards){
        $dashboard=$artifacts.dashboards | Where-Object {$_.artifactDisplayName -eq $d}
        if($dashboard){
            $_dashboardjson = @{sourceId = $dashboard.artifactId}
            $dashboard_to_be_moved.Add($_dashboardjson)
        }
    }
    # Construct the request url and body
    $url = "pipelines/{0}/Deploy" -f $pipelineID
    $body = @{
        sourceStageOrder = $stageOrder
        datasets = $datasets_to_be_moved
        reports = $reports_to_be_moved
        dashboards = $dashboard_to_be_moved
        options=@{
            # Allows creating new artifact if needed on the Test stage workspace
            allowCreateArtifact = $TRUE
            # Allows overwriting existing artifact if needed on the Test stage workspace
            allowOverwriteArtifact = $TRUE
        } 
    } | ConvertTo-Json
    Write-Host $body
    # Send the request
    $deployResult = Invoke-PowerBIRestMethod -Url $url  -Method Post -Body $body | ConvertFrom-Json
    return $deployResult
}

function Wait-for-deployment(
    [Parameter(Mandatory=$true)][string]$pipelineID,
    [Parameter(Mandatory=$true)][string]$operationStatus
){
        # Wait for deployment operation to complete
        $getOperationUrl =  "pipelines/{0}/Operations/{1}" -f $pipelineID, $deployResult.Id
    
        while($operationStatus -eq "NotStarted" -or $operationStatus -eq "Executing")
        {
            # Sleep for 5 seconds
            Start-Sleep -s 5
    
            # Get the deployment operation details
            $operation = Invoke-PowerBIRestMethod -Url $getOperationUrl -Method Get | ConvertFrom-Json
            $operationStatus = $operation.Status
        }
    
}
# Install the Power BI PowerShell modules. Uncomment the following line if you haven't installed the modules before.
# Install-PBIModules

# credential generation
$credentials=New-Object System.Management.Automation.PSCredential ($CLIENT_ID , (convertto-securestring $CLIENT_SECRET -asplaintext -force))
# Connect to Power BI Service using a service principal
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $credentials -Tenant $TENANT_ID

#Check the service principal is connected and get access to the PBI workspace.
$restUrlWorkspaces="https://api.powerbi.com/v1.0/myorg/groups/"; 
Invoke-PowerBIRestMethod -Url $restUrlWorkspaces -Method GET -Verbose

try {
    
    # Create a new deployment pipeline
    $pipelineID=Create-Pipeline -pipelineDisplayName $pipelineDisplayName -pipelineDescription $pipelineDescritionName  

    # provide permission to the adminuser
    Assign-PBIDeploymentUser -adminuserupn $adminusersupn -pipelineName $pipelineDisplayName -accessRight "Admin" -principalType "User"

    # Add the workspace to the dev stage of the pipeline
    $stageOrder=0 # The deployment pipeline stage order. Development (0), Test (1), Production (2).  
    Assign-workspace-to-pipline -workspaceName $dev_workspaceName -pipelineID $pipelineID -stageOrder $stageOrder  
    
    $stageOrder=1 # The deployment pipeline stage order. Development (0), Test (1), Production (2).  
    Assign-workspace-to-pipline -workspaceName $test_workspaceName -pipelineID $pipelineID -stageOrder $stageOrder 
    
    $stageOrder=2 # The deployment pipeline stage order. Development (0), Test (1), Production (2).  
    Assign-workspace-to-pipline -workspaceName $prod_workspaceName -pipelineID $pipelineID -stageOrder $stageOrder 
    #move artifacts from dev to test
    $deployResult=Deploy-PBIArtifacts -stageOrder 0 -pipelineID $pipelineID -stagedReports $reports_to_be_moved_from_dev_to_test -stagedDatasets $dataset_to_be_moved_from_dev_to_test -stagedDashboards $dashboards_to_be_moved_from_dev_to_test
    $operationStatus = $deployResult.Status
    Wait-for-deployment -pipelineID $pipelineID -operationStatus $operationStatus
    Write-Host "Deployment of artifacts from dev to test completed"
    #move artifacts from test to prod
    Deploy-PBIArtifacts -stageOrder 1 -pipelineID $pipelineID -stagedReports $reports_to_be_moved_from_test_to_prod -stagedDatasets $dataset_to_be_moved_from_test_to_prod -stagedDashboards $dashboards_to_be_moved_from_test_to_prod
    Wait-for-deployment -pipelineID $pipelineID -operationStatus $operationStatus
    Write-Host "Deployment of artifacts from test to prod completed"
    

} catch {
    $errmsg=Resolve-PowerBIError -Last
    Write-Host "Error: {0}" -f $errmsg
    # $errmsg.Message
}