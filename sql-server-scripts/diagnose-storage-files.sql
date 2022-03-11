with
    [BaseData] as (
        select
            [DF].[type_desc]                        as [file_type],
            [DF].[name]                             as [file_name],
            [DF].[size]                             as [total_pages],
            fileproperty([DF].[name], N'spaceused') as [used_pages],
            [DF].[max_size]                         as [max_pages]
        from [sys].[database_files] as [DF]
    ),
    [FormattedData] as (
        select
            [BD].[file_type]                           as [file_type],
            [BD].[file_name]                           as [file_name],
            cast([GB].[total_space] as decimal(12, 4)) as [total_space_GB],
            cast([GB].[used_space] as decimal(12, 4))  as [used_space_GB],
            cast([GB].[free_space] as decimal(12, 4))  as [free_space_GB],
            cast([PT].[free_percent] as decimal(5, 2)) as [free_percent],
            case [BD].[max_pages]
                when -1 then N'Unrestricted'
                when 0  then N'Disabled'
                        else format(([BD].[max_pages] / 131072.0), N'N2')
            end                                        as [max_pages_GB]
        from [BaseData] as [BD]
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
    )
select *
from [FormattedData]
order by [file_type], [file_name];
