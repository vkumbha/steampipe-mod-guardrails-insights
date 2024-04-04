dashboard "workspace_dashboard" {

  title         = "Turbot Guardrails Workspace Dashboard"
  documentation = file("./dashboards/workspace/docs/workspace_dashboard.md")

  tags = merge(local.workspace_common_tags, {
    type     = "Dashboard"
    category = "Summary"
  })

  # Analysis
  container {
    title = "Workspace Statistics"

    card {
      sql   = query.workspace_count.sql
      width = 3
      href  = dashboard.workspace_report.url_path
    }

    card {
      sql   = query.workspace_account_count.sql
      width = 3
      href  = dashboard.workspace_account_report.url_path
    }
  }

  # Analysis
  container {
    title = "Account Statistics"

    chart {
      type  = "donut"
      title = "Accounts by Workspace"
      width = 4
      sql   = query.accounts_by_workspace.sql
    }

    chart {
      type  = "donut"
      title = "Accounts by Provider"
      width = 4
      sql   = query.accounts_by_provider.sql
    }

    chart {
      type  = "line"
      title = "Cumulative Account Imports by Month"
      width = 4
      sql   = query.cumulative_account_imports_by_month.sql
    }
  }
}

query "workspace_count" {
  sql = <<-EOQ
    select
      count(workspace) as "Workspaces"
    from
      guardrails_resource
    where
      resource_type_uri = 'tmod:@turbot/turbot#/resource/types/turbot';
  EOQ
}

query "workspace_account_count" {
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

query "accounts_by_workspace" {
  sql = <<-EOQ
  select
    _ctx ->> 'connection_name' as "Connection Name",
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
  group by
    _ctx ->> 'connection_name'
  EOQ
}

query "accounts_by_provider" {
  sql = <<-EOQ
  select
    case
      when resource_type_uri = 'tmod:@turbot/aws#/resource/types/account' then 'AWS'
      when resource_type_uri = 'tmod:@turbot/azure#/resource/types/subscription' then 'Azure'
      when resource_type_uri = 'tmod:@turbot/gcp#/resource/types/project' then 'GCP'
      when resource_type_uri = 'tmod:@turbot/servicenow#/resource/types/instance' then 'ServiceNow'
    end as "Account Type",
    count(resource_type_uri)
  from
    guardrails_resource
  where
    resource_type_uri in (
      'tmod:@turbot/aws#/resource/types/account',
      'tmod:@turbot/azure#/resource/types/subscription',
      'tmod:@turbot/gcp#/resource/types/project',
      'tmod:@turbot/servicenow#/resource/types/instance'
    )
  group by
    resource_type_uri;
    EOQ
}

query "cumulative_account_imports_by_month" {
  sql = <<-EOQ
    with data as (
      with months as 
      (
        select to_char((create_timestamp)::date, 'YYYY-MM') AS month from guardrails_resource where filter ='resourceTypeId:tmod:@turbot/turbot#/resource/interfaces/accountable level:self'
      )
      select month,count(*) from months where 
        month <= (
          select
            to_char(now(), 'YYYY-MM')
        )
      group by
        month
    )
    select month,sum(count) over  (
        order by
          month asc rows between unbounded preceding
          and current row
      )
    from
      data
  EOQ
}
