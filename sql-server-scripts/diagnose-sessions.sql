with
    [Sessions] as (
        select
            [S].[session_id],
            [T].[text],
            [S].[login_name],
            [R].[wait_time],
            [R].[wait_type],
            [S].[cpu_time],
            [S].[reads],
            [S].[writes],
            [S].[memory_usage],
            [S].[status],
            [R].[open_transaction_count],
            [S].[host_name],
            [S].[program_name],
            [S].[last_request_start_time],
            [S].[login_time],
            [P].[query_plan]
        from [sys].[dm_exec_sessions] as [S]
            left join [sys].[dm_exec_connections] as [C]
                on [S].[session_id] = [C].[session_id]
            left join [sys].[dm_exec_requests] as [R]
                on [S].[session_id] = [R].[session_id]
            outer apply [sys].[dm_exec_sql_text](
                [C].[most_recent_sql_handle]
            ) as [T]
            outer apply [sys].[dm_exec_query_plan](
                [R].[plan_handle]
            ) as [P]
        where [S].[database_id] = db_id()
            and [S].[session_id] <> @@spid
            and [S].[is_user_process] = 1
    )
select
    sysutcdatetime()            as [timestamp],
    [session_id]                as [session_id],
    [text]                      as [sql_text],
    [login_name]                as [login_name],
    [wait_time]                 as [wait_time],
    [wait_type]                 as [wait_type],
    [cpu_time]                  as [cpu_time],
    [reads]                     as [reads],
    [writes]                    as [writes],
    [memory_usage]              as [memory_usage],
    [status]                    as [status],
    [open_transaction_count]    as [open_transaction_count],
    [host_name]                 as [host_name],
    [program_name]              as [program_name],
    [last_request_start_time]   as [last_request_start_time],
    [login_time]                as [login_time],
    [query_plan]                as [plan]
from [Sessions]
order by [login_name];
