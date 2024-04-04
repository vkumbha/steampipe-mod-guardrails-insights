dashboard "workspace_account_report" {

  title         = "Turbot Guardrails Workspace Account Report"
  documentation = file("./dashboards/workspace/docs/workspace_account_report.md")

  tags = merge(local.workspace_common_tags, {
    type     = "Report"
    category = "Summary"
  })

  # Analysis
  container {
    text {
      value = "List of accounts across workspaces. Click on the resource to navigate to the respective Turbot Guardrails Console."
    }

    card {
      sql   = query.workspace_account_count.sql
      width = 3
    }

    card {
      sql   = query.workspace_aws_count.sql
      width = 3
    }

    card {
      sql   = query.workspace_azure_count.sql
      width = 3
    }

    card {
      sql   = query.workspace_gcp_count.sql
      width = 3
    }

    table {
      column "id" {
        display = "none"
      }

      column "workspace" {
        display = "none"
      }

      column "Account ID" {
        href = <<-EOT
          {{ .'Workspace' }}/apollo/resources/{{.'id' | @uri}}/detail
        EOT
      }
      sql = query.workspace_account_detail.sql
    }

    table {
      title = "Accounts Summary (limited to 5000)"
      column "id" {
        display = "none"
      }

      column "workspace" {
        display = "none"
      }

      column "Account ID" {
        href = <<-EOT
          {{ .'Workspace' }}/apollo/resources/{{.'id' | @uri}}/detail
        EOT
      }
      sql = query.workspace_account_detail_extras.sql

    }


  }
}

query "workspace_aws_count" {
  sql = <<-EOQ
    select
      count(resource_type_uri) as "AWS"
    from
      guardrails_resource
    where
      resource_type_uri = 'tmod:@turbot/aws#/resource/types/account';
  EOQ
}

query "workspace_azure_count" {
  sql = <<-EOQ
    select
      count(resource_type_uri) as "Azure"
    from
      guardrails_resource
    where
      resource_type_uri = 'tmod:@turbot/azure#/resource/types/subscription';
  EOQ
}

query "workspace_gcp_count" {
  sql = <<-EOQ
    select
      count(resource_type_uri) as "GCP"
    from
      guardrails_resource
    where
      resource_type_uri = 'tmod:@turbot/gcp#/resource/types/project';
  EOQ
}

query "workspace_account_detail" {
  sql = <<-EOQ
    select
      id,
      workspace as "Workspace",
      case
        when resource_type_uri = 'tmod:@turbot/aws#/resource/types/account' then data ->> 'Id'
        when resource_type_uri = 'tmod:@turbot/azure#/resource/types/subscription' then data ->> 'subscriptionId'
        when resource_type_uri = 'tmod:@turbot/gcp#/resource/types/project' then data ->> 'projectId'
      end as "Account ID",
      case
        when resource_type_uri = 'tmod:@turbot/aws#/resource/types/account' then data ->> 'AccountAlias'
        when resource_type_uri = 'tmod:@turbot/azure#/resource/types/subscription' then data ->> 'displayName'
        when resource_type_uri = 'tmod:@turbot/gcp#/resource/types/project' then data ->> 'name'
      end as "Account Name",
      trunk_title as "Trunk Title"
    from
      guardrails_resource
    where
      resource_type_uri in (
        'tmod:@turbot/aws#/resource/types/account',
        'tmod:@turbot/azure#/resource/types/subscription',
        'tmod:@turbot/gcp#/resource/types/project'
      )
    order by
      "Workspace",
      "Trunk Title";
  EOQ
}

query "workspace_account_detail_extras" {
  sql = <<-EOQ
  select
    accountables -> 'turbot' ->> 'id' as "id",
    workspace as "Workspace",
      case
        when accountables -> 'type' ->> 'uri' = 'tmod:@turbot/aws#/resource/types/account' then accountables -> 'data' ->> 'Id'
        when accountables -> 'type' ->> 'uri' = 'tmod:@turbot/azure#/resource/types/subscription' then accountables -> 'data' ->> 'subscriptionId'
        when accountables -> 'type' ->> 'uri' = 'tmod:@turbot/gcp#/resource/types/project' then accountables -> 'data' ->> 'projectId'
        when accountables -> 'type' ->> 'uri' = 'tmod:@turbot/servicenow#/resource/types/instance' then accountables -> 'data' ->> 'instance_id'
      end as "Account ID",
    case
      when accountables -> 'type' ->> 'uri' = 'tmod:@turbot/aws#/resource/types/account' then accountables -> 'data' ->> 'AccountAlias'
      when accountables -> 'type' ->> 'uri' = 'tmod:@turbot/azure#/resource/types/subscription' then accountables -> 'data' ->> 'displayName'
      when accountables -> 'type' ->> 'uri' = 'tmod:@turbot/gcp#/resource/types/project' then accountables -> 'data' ->> 'name'
      when accountables -> 'type' ->> 'uri' = 'tmod:@turbot/servicenow#/resource/types/instance' then accountables -> 'data' ->> 'instance_id'
    end as "Account Name",
    accountables -> 'trunk' ->> 'title' as "Trunk",
    accountables -> 'descendants' -> 'metadata' -> 'stats' ->> 'total' as "Resources",
    accountables -> 'policySettings' -> 'metadata' -> 'stats' ->> 'total' as "Policy Settings",
    accountables -> 'alerts' -> 'metadata' -> 'stats' ->> 'total' as "Alerts",
    accountables -> 'activeControls' -> 'metadata' -> 'stats' ->> 'total' as "Active Controls",
    accountables -> 'totalControls' -> 'metadata' -> 'stats' ->> 'total' as "Total Controls"
  from
    guardrails_query,
    jsonb_array_elements(output ->  'resources' -> 'items') as accountables
  where
    query = '{
      resources(
        filter: "resourceTypeId:tmod:@turbot/turbot#/resource/interfaces/accountable level:self limit:5000"
      ) {
        metadata {
          stats {
            total
          }
        }
        items {
          data
          turbot {
            id
          }
          trunk {
            title
          }
          type {
            uri
          }
          descendants {
            metadata {
              stats {
                total
              }
            }
          }
          policySettings {
            metadata {
              stats {
                total
              }
            }
          }
          alerts: controls(filter: "state:alarm,invalid,error") {
            metadata {
              stats {
                total
              }
            }
          }
          activeControls: controls(filter: "state:active") {
            metadata {
              stats {
                total
              }
            }
          }
          totalControls: controls {
            metadata {
              stats {
                total
              }
            }
          }
        }
      }
    }'
  order by "Workspace"
  EOQ
}
