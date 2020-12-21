let CI = ../dependencies/CI.dhall

let Workflow = CI.Workflow

let Step = Workflow.Step

let BranchTemplate = Text -> Text

let defaultTemplate = (\(branch : Text) -> "${branch}-deploy") : BranchTemplate

let initGit =
      Step.bash [ "git init" ] // { name = Some "Initialize empty repo" }

let deleteBranchFor =
      \(template : BranchTemplate) ->
        let associatedBranch = template "\${{ github.event.ref }}"

        in      Step.bash
                  [ "git push https://x-access-token:\${{ github.token }}@github.com/\${{ github.repository }} \":refs/heads/${associatedBranch}\" || true"
                  ]
            //  { name = Some "Delete generated branch" }

let jobFor =
      \(template : BranchTemplate) ->
        Workflow.Job::{
        , runs-on = Workflow.RunsOn.Type.ubuntu-latest
        , steps = [ initGit, deleteBranchFor template ]
        }

let workflowFor =
      \(template : BranchTemplate) ->
        Workflow::{
        , name = "Delete generated branches"
        , on = Workflow.On::{ delete = Some {=} }
        , jobs = toMap { cleanup = jobFor template }
        }

let workflow = workflowFor defaultTemplate

in  { workflow
    , workflowFor
    , jobFor
    , deleteBranchFor
    , defaultTemplate
    , BranchTemplate
    }
