dashboard "workspace_report" {

  title         = "Turbot Guardrails Workspace Report"
  documentation = file("./dashboards/workspace/docs/workspace_report.md")

  tags = merge(local.workspace_common_tags, {
    type     = "Report"
    category = "Summary"
  })

  # Analysis
  container {
    text {
      value = "The workspace report gives a detailed analysis of all connected Turbot Guardrails Workspace(s) along with their Turbot Guardrails Enterprise(TE) Version."
    }

    card {
      sql   = query.workspace_count.sql
      width = 3
    }

    card {
      sql   = query.total_te_installations.sql
      width = 3
    }

    card {
      sql   = query.accounts_total.sql
      width = 3
    }

    card {
      sql   = query.alerts_total.sql
      width = 3
    }
  }

  # Analysis - Workspace stats - Accounts, Resources, Controls, Alerts
  container {
    table {
      width = 12
      sql   = query.workspace_stats.sql
    }
  }

}

query "total_te_installations" {
  sql = <<-EOQ
    select
      COUNT(DISTINCT value) as "TE Installations"
    from
      guardrails_policy_setting
    where
      policy_type_uri = 'tmod:@turbot/turbot#/policy/types/workspaceVersion'
  EOQ
}

query "accounts_total" {
  sql = <<-EOQ
  select
    sum((output -> 'accounts' -> 'metadata' -> 'stats' ->> 'total')::int) as "Accounts"
  from
    guardrails_query
  where
    query = '{
      accounts: resources(filter: "resourceTypeId:tmod:@turbot/turbot#/resource/interfaces/accountable level:self") {
        metadata {
          stats {
            total
          }
        }
      }
    }'
  EOQ
}

query "alerts_total" {
  sql = <<-EOQ
  select
    sum((output -> 'alerts' -> 'metadata' -> 'stats' ->> 'total')::int) as "Alerts - alarm, invalid, error"
  from
    guardrails_query
  where
    query = '{
      alerts: controls(filter:"state:alarm,invalid,error") {
        metadata {
          stats {
            total
          }
        }
      }
    }'
  EOQ
}

query "workspace_stats" {
  sql = <<-EOQ
  select
    workspace as "Workspace",
    output -> 'teVersion' ->> 'value' as "TE Version",
    output -> 'accounts' -> 'metadata' -> 'stats' ->> 'total' as "Accounts",
    output -> 'resources' -> 'metadata' -> 'stats' ->> 'total' as "Resources",
    output -> 'total_controls' -> 'metadata' -> 'stats' ->> 'total' as "Controls",
    output -> 'alerts' -> 'metadata' -> 'stats' ->> 'total' as "Alerts"
  from
    guardrails_query
  where
    query = '{
      teVersion: policySetting(uri: "tmod:@turbot/turbot#/policy/types/workspaceVersion" resourceId: "tmod:@turbot/turbot#/") {
        value
      }
      accounts: resources(filter: "resourceTypeId:tmod:@turbot/turbot#/resource/interfaces/accountable level:self") {
        metadata {
          stats {
            total
          }
        }
      }
      resources: resources(filter: "resourceTypeId:tmod:@turbot/aws#/resource/types/aws,tmod:@turbot/azure#/resource/types/azure,tmod:@turbot/gcp#/resource/types/gcp") {
        metadata {
          stats {
            total
          }
        }
      }
      alerts: controls(filter:"state:alarm,invalid,error") {
        metadata {
          stats {
            total
          }
        }
      }
      total_controls: controls {
        metadata {
          stats {
            total
          }
        }
      }
    }'
  order by "Workspace"
  EOQ
}
