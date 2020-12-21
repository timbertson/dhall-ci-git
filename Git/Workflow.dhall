let CI = ../dependencies/CI.dhall

let Script = ./Script.dhall

let Workflow = CI.Workflow

let Step = Workflow.Step

let githubTokenEnv = toMap { GITHUB_TOKEN = "\${{ secrets.GITHUB_TOKEN }}" }

let requireCleanWorkspace =
          Step.bash Script.requireCleanWorkspace
      //  { name = Some "Require clean workspace" }

let botCommitterEnv = Script.committerEnv Script.githubActionsBot

let CleanupAssociatedBranch = ./CleanupAssociatedBranch.dhall

let pullRequestOrBranches =
      \(branches : List Text) ->
        Workflow.On::{
        , pull_request = Some Workflow.PullRequest::{=}
        , push = Some Workflow.Push::{ branches = Some branches }
        }

let pullRequestOrMain = pullRequestOrBranches [ "master", "main" ]

let Checkout = { Type = { fetchDepth : Natural }, default.fetchDepth = 1 }

let toParams =
      \(options : Checkout.Type) ->
        toMap { fetch-depth = Natural/show options.fetchDepth }

let checkout =
      \(options : Checkout.Type) ->
          Step::{
          , uses = Some "actions/checkout@v2"
          , `with` = Some (toParams options)
          }
        : Step.Type

let isPushToMain =
      "github.event_name == 'push' && (github.ref == 'refs/heads/master' || github.ref == 'refs/heads/master')"

in  { checkout
    , Checkout
    , CleanupAssociatedBranch
    , botCommitterEnv
    , githubTokenEnv
    , pullRequestOrBranches
    , pullRequestOrMain
    , requireCleanWorkspace
    , isPushToMain
    }
