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

let On =
      let pullRequestOrBranches =
            \(branches : List Text) ->
              Workflow.On::{
              , pull_request = Some Workflow.PullRequest::{=}
              , push = Some Workflow.Push::{ branches = Some branches }
              }

      let mainBranches = [ "master", "main" ]

      let pullRequestOrMain = pullRequestOrBranches mainBranches

      let pullRequestOrReleaseBranches =
            pullRequestOrBranches (mainBranches # [ "v*.x*" ])

      in  { pullRequestOrBranches
          , pullRequestOrMain
          , pullRequestOrReleaseBranches
          }

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

let Expr =
      let isPush = "github.event_name == 'push'"

      let isPullRequest = "github.event_name == 'pull_request'"

      in  { isPush
          , isPullRequest
          , isPushToMain =
              -- (or master)
              "${isPush} && (github.ref == 'refs/heads/master' || github.ref == 'refs/heads/master')"
          , isPushToVersionBranch =
              "${isPush} && startsWith(github.ref, 'refs/heads/v') && contains(github.ref, '.x')"
          , branchRef =
              -- GH expressions strangely lack a builtin for this.
              -- `github.head_ref` is the branch name, only defined for a PR
              -- But for a push, we get `github.ref` but that contains the leading 'refs/heads/'
              -- Ideally we'd return the branch name without `refs/heads`, but there's no replace operator
              -- so for consistency we always return `refs/heads/*`
              "(${isPullRequest} && format('refs/heads/{0}', github.head_ref)) || github.ref"
          }

in  { checkout
    , Checkout
    , Expr
    , On
    , CleanupAssociatedBranch
    , botCommitterEnv
    , githubTokenEnv
    , requireCleanWorkspace
    }
