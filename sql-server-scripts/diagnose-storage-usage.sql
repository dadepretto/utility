with
    [RawData] as (
        select
            [SC].[schema_id]             as [schema_id],
            [SC].[name]                  as [schema_name],
            [TB].[object_id]             as [table_id],
            [TB].[name]                  as [table_name],
            [IX].[index_id]              as [index_id],
            [IX].[name]                  as [index_name],
            [IX].[type_desc]             as [index_type],
            [PT].[partition_id]          as [partition_id],
            [PT].[partition_number]      as [partition_number],
            [PT].[rows]                  as [rowcount],
            [PT].[data_compression_desc] as [data_compression_desc],
            [IS].[user_seeks]            as [seeks_count],
            [IS].[user_scans]            as [scans_count],
            [IS].[user_lookups]          as [lookups_count],
            [IS].[user_updates]          as [updates_count],
            [IS].[last_user_seek]        as [last_seek],
            [IS].[last_user_scan]        as [last_scan],
            [IS].[last_user_lookup]      as [last_lookup],
            [IS].[last_user_update]      as [last_update],
            [PS].[reserved_page_count]   as [total_pages],
            [PS].[used_page_count]       as [used_pages]
        from [sys].[schemas] as [SC]
            inner join [sys].[tables] as [TB]
                on [SC].[schema_id] = [TB].[schema_id]
            inner join [sys].[indexes] as [IX]
                on [TB].[object_id] = [IX].[object_id]
            inner join [sys].[partitions] as [PT]
                on [TB].[object_id] = [PT].[object_id]
                    and [IX].[index_id] = [PT].[index_id]
            left join [sys].[dm_db_index_usage_stats] as [IS]
                on [TB].[object_id] = [IS].[object_id]
                    and [IX].[index_id] = [IS].[index_id]
            left join [sys].[dm_db_partition_stats] as [PS]
                on [PT].[partition_id] = [PS].[partition_id]
                    and [IX].[index_id] = [PS].[index_id]
                    and [TB].[object_id] = [PS].[object_id]
    ),
    [FormattedData] as (
        select
            [BD].[schema_id]                           as [schema_id],
            [BD].[schema_name]                         as [schema_name],
            [BD].[table_id]                            as [table_id],
            [BD].[table_name]                          as [table_name],
            [BD].[index_id]                            as [index_id],
            [BD].[index_name]                          as [index_name],
            [BD].[index_type]                          as [index_type],
            [BD].[partition_id]                        as [partition_id],
            [BD].[partition_number]                    as [partition_number],
            [BD].[rowcount]                            as [rowcount],
            [DCD].[data_compression]                   as [data_compression],
            cast([PT].[free_percent] as decimal(5, 2)) as [free_percent],
            cast([GB].[total_space] as decimal(12, 4)) as [total_space_GB],
            cast([GB].[used_space] as decimal(12, 4))  as [used_space_GB],
            cast([GB].[free_space] as decimal(12, 4))  as [free_space_GB],
            [BD].[seeks_count]                         as [seeks_count],
            [BD].[scans_count]                         as [scans_count],
            [BD].[lookups_count]                       as [lookups_count],
            [BD].[updates_count]                       as [updates_count],
            [BD].[last_seek]                           as [last_seek],
            [BD].[last_scan]                           as [last_scan],
            [BD].[last_lookup]                         as [last_lookup],
            [BD].[last_update]                         as [last_update]
        from [RawData] as [BD]
            cross apply (
                select [BD].[total_pages] - [BD].[used_pages]
            ) as [FP]([free_pages])
            cross apply (
                select [FP].[free_pages] * 100.0 / nullif([BD].[total_pages], 0)
            ) as [PT]([free_percent])
            cross apply (
                select
                    [total_pages] / 131072.0,
                    [used_pages] / 131072.0,
                    [free_pages] / 131072.0
            ) as [GB]([total_space], [used_space], [free_space])
            cross apply (
                select
                    case [BD].[data_compression_desc]
                        when N'NONE' then N'-'
                                     else [BD].[data_compression_desc]
                end
            ) as [DCD]([data_compression])
    )
select *
from [FormattedData]
order by [total_space_GB] desc;
