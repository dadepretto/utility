with
    [Locks] as (
        select
            [TL].[resource_type],
            [TL].[resource_subtype],
            [TL].[resource_database_id],
            [TL].[resource_description],
            [TL].[resource_associated_entity_id],
            [TL].[resource_lock_partition],
            [TL].[request_mode],
            [TL].[request_type],
            [TL].[request_status],
            [TL].[request_reference_count],
            [TL].[request_lifetime],
            [TL].[request_session_id],
            [TL].[request_exec_context_id],
            [TL].[request_request_id],
            [TL].[request_owner_type],
            [TL].[request_owner_id],
            [TL].[request_owner_guid],
            [TL].[request_owner_lockspace_id],
            [TL].[lock_owner_address],
            [RN].[resource_associated_entity_name]
        from [sys].[dm_tran_locks] as [TL]
            left join [sys].[partitions] as [P]
                on [TL].[resource_associated_entity_id] = [P].[hobt_id]
            left join [sys].[indexes] as [I]
                on [I].[object_id] = [P].[object_id]
                    and [I].[index_id] = [P].[index_id]
            outer apply (
                select case [TL].[resource_type]
                    when N'OBJECT'
                        then object_name([TL].[resource_associated_entity_id])
                    when N'DATABASE'
                        then db_name([TL].[resource_database_id])
                        else object_name([P].[object_id])
                end as [resource_associated_entity_name]
            ) as [RN]
        where [TL].[resource_database_id] = db_id()
            and [TL].[request_session_id] <> @@spid
    )
select
    sysutcdatetime()                    as [timestamp],
    [resource_type]                     as [resource_type],
    [resource_associated_entity_name]   as [resource_associated_entity_name],
    count(*)                            as [locks_count],
    [request_mode]                      as [request_mode]
from [Locks]
where 1 = 1
    -- and [request_session_id] in (spid)
    -- and [resource_type] in (N'OBJECT')
    -- and [request_mode] in (N'X')
group by
    [resource_type],
    [resource_associated_entity_name],
    [request_mode],
    [request_type]
order by
    case [resource_type]
        when N'FILE'            then 1
        when N'DATABASE'        then 2
        when N'METADATA'        then 3
        when N'OBJECT'          then 4
        when N'ALLOCATION_UNIT' then 5
        when N'HOBT'            then 6
        when N'EXTENT'          then 7
        when N'PAGE'            then 8
        when N'RID'             then 9
        when N'KEY'             then 10
        when N'APPLICATION'     then 11
        else 12
    end,
    [resource_associated_entity_name],
    [request_mode],
    [request_type];